#!/usr/bin/env python3
"""Trusted release preparation; no Roblox requests or publishing.

Keep this control code and its records on reviewed main. Candidate game code is
selected by immutable SHA and is never allowed to select its own release policy.
"""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request
from zipfile import ZipFile

from common import ROOT, check_place
from generate_dead_signal_place_configs import ROLES, read_identifiers, generate
from patch_dead_signal_rbxl import split_binary, parse_headers

REPOSITORY = "stephennip9288-create/Roblox-Projects"
RECORDS = ROOT / "games/dead-signal/releases"
RECOVERY = ROOT / "build/dead-signal-recovery"
IDS = {"staging": "10771141095", "production": "10770732078"}
LANES = ("maps", "enemies", "combat_ui", "audio")
REQUIREMENTS = {**{f"MAP-{n:02}": "maps" for n in range(1, 13)},
                **{f"EN-{n:02}": "enemies" for n in range(1, 10)},
                **{f"WPN-{n:02}": "combat_ui" for n in range(1, 10)}, "AUD-01": "audio"}


def digest(blob):
    return hashlib.sha256(blob).hexdigest()


def full_sha(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{40}", value) is not None


def completion(record, source_sha):
    """A proposal/partial parent build cannot pass the complete Batch 1 gate."""
    if not full_sha(source_sha):
        raise ValueError("A full immutable candidate source SHA is required")
    if record.get("schema") != 1 or record.get("release") != "dead-signal-batch-1":
        raise ValueError("Unknown Batch 1 release record")
    if record.get("ready_for_staging") is not True or record.get("source_sha") != source_sha:
        raise ValueError("Complete Batch 1 is not reviewed/ready for this source SHA")
    lanes = record.get("lanes", {})
    if set(lanes) != set(LANES):
        raise ValueError("All four specialist lanes are required")
    for lane, row in lanes.items():
        if (row.get("complete") is not True or row.get("reviewed") is not True
                or type(row.get("pr")) is not int or row["pr"] <= 0 or not full_sha(row.get("head_sha"))):
            raise ValueError("Specialist assignment is not complete/reviewed: " + lane)
    if len({row["pr"] for row in lanes.values()}) != 4:
        raise ValueError("Four distinct specialist PRs must be reviewed")
    rows = record.get("requirements", {})
    if set(rows) != set(REQUIREMENTS):
        raise ValueError("Exactly all 31 approved requirement IDs must be accounted for")
    for key, lane in REQUIREMENTS.items():
        row = rows[key]
        if (row.get("lane") != lane or row.get("implementation") != "complete"
                or not isinstance(row.get("evidence"), list) or not row["evidence"]
                or any(not isinstance(v, str) or not v.strip() for v in row["evidence"])):
            raise ValueError("Requirement implementation/evidence incomplete: " + key)
    checks = record.get("verification", {})
    for key in ("regression", "four_place_fidelity", "config_isolation", "shared_contracts", "recovery"):
        if checks.get(key) is not True:
            raise ValueError("Combined verification gate not passed: " + key)
    return record



def staging_qa_completion(record, source_sha):
    """Independently scoped four-fix staging QA exception; NEVER full release."""
    retest = {"DS-B1-002", "DS-B1-003", "DS-B1-004", "DS-B1-005"}
    deferred = {"DS-B1-001", "DS-B1-006"}
    if (not full_sha(source_sha) or record.get("schema") != 1
            or record.get("release") != "dead-signal-batch-1-1-private-staging-qa"
            or record.get("source_sha") != source_sha
            or record.get("owner_staging_authorization") is not True
            or record.get("approval_scope") != "PRIVATE_STAGING_QA_ONLY"
            or record.get("ready_for_staging_qa") is not True
            or record.get("scope_complete") is not False
            or record.get("production_authorization") is not False
            or record.get("bugs_verified") is not False
            or record.get("staging_universe_id") != IDS["staging"]):
        raise ValueError("Unapproved or incorrectly scoped Batch 1.1 private staging QA")
    if (record.get("approved_retest_bugs") != dict.fromkeys(sorted(retest), "Ready for Retest")
            or record.get("deferred_bugs") != dict.fromkeys(sorted(deferred), "In Progress")):
        raise ValueError("Four-fix scope or unfinished statuses were changed")
    heads = record.get("integrated_heads", {})
    if (set(heads) != {"maps", "enemies", "adapter", "audio"}
            or len(set(heads.values())) != 4 or not all(full_sha(v) for v in heads.values())):
        raise ValueError("Reviewed specialist ancestry is incomplete")
    hashes = record.get("staging_binary_sha256", {})
    if (set(hashes) != set(ROLES)
            or not all(isinstance(v, str) and re.fullmatch(r"[0-9a-f]{64}", v) for v in hashes.values())
            or record.get("source_ci_checks_passed") != 10):
        raise ValueError("Exact four-place reviewed binary hashes/checks are required")
    rollback = recovery_record("staging")
    if (record.get("rollback_source_sha") != rollback["source_sha"]
            or record.get("rollback_deployment_run") != rollback["deployment"]["run_id"]):
        raise ValueError("QA rollback is not the currently recorded staging release")
    return record


def verify_staging_deploy_source(candidate, source_sha, records=RECORDS):
    """Select an exact main-trusted completed Batch 1 or separately approved staging-only QA source."""
    original = json.loads((Path(records) / "batch-1.json").read_text())
    if source_sha == original.get("source_sha"):
        verify_source(candidate, original, source_sha)
        return original
    qa = json.loads((Path(records) / "batch-1-1-staging-qa.json").read_text())
    staging_qa_completion(qa, source_sha)
    verify_checkout(candidate, source_sha)
    for name, ancestor in {**qa["integrated_heads"], "baseline": qa["rollback_source_sha"]}.items():
        result = subprocess.run(["git", "-C", str(candidate), "merge-base", "--is-ancestor", ancestor, source_sha], capture_output=True)
        if result.returncode:
            raise ValueError("QA source omits reviewed ancestor: " + name)
    return qa


def verify_checkout(candidate, source_sha):
    """Verify every runtime byte again after candidate tests."""
    candidate = Path(candidate).resolve()
    if not full_sha(source_sha):
        raise ValueError("An immutable source SHA is required")
    def git(*args):
        return subprocess.check_output(["git", "-C", str(candidate), *args], text=True).strip()
    if git("rev-parse", "HEAD") != source_sha:
        raise ValueError("Candidate checkout does not match the reviewed SHA")
    prefix = "games/dead-signal/dev/Source/Runtime/"
    paths = git("ls-tree", "-r", "--name-only", source_sha, "--", prefix).splitlines()
    if len(paths) != 61 or any(not p.endswith(".lua") for p in paths):
        raise ValueError("The fixed 61-script candidate contract changed")
    actual = {str(p.relative_to(candidate)) for p in (candidate / prefix).rglob("*.lua")}
    if actual != set(paths):
        raise ValueError("Unexpected/missing runtime source files")
    for path in paths:
        p = candidate / path
        if p.is_symlink() or not p.resolve().is_relative_to(candidate):
            raise ValueError("Unsafe runtime source path")
        expected = subprocess.check_output(["git", "-C", str(candidate), "show", source_sha + ":" + path])
        if p.read_bytes() != expected:
            raise ValueError("Runtime changed after source selection: " + path)


def verify_source(candidate, record, source_sha):
    completion(record, source_sha)
    verify_checkout(candidate, source_sha)
    for lane, row in record["lanes"].items():
        result = subprocess.run(["git", "-C", str(candidate), "merge-base", "--is-ancestor", row["head_sha"], source_sha], capture_output=True)
        if result.returncode:
            raise ValueError("Candidate does not contain the reviewed lane: " + lane)


def install_controls(control, candidate, operation, source_sha, environment="staging"):
    control, candidate = Path(control).resolve(), Path(candidate).resolve()
    if control == candidate or control.is_relative_to(candidate) or candidate.is_relative_to(control):
        raise ValueError("Use separate trusted-control and candidate checkouts")
    if operation not in ("deploy", "rollback") or environment not in IDS:
        raise ValueError("Unsupported staging operation")
    if operation == "deploy":
        if environment == "staging":
            verify_staging_deploy_source(candidate, source_sha, control / "games/dead-signal/releases")
        else:
            verify_checkout(candidate, source_sha)
    elif source_sha:
        raise ValueError("Rollback must not select new candidate code")
    # Only ephemeral pipeline controls/target manifests are replaced. Runtime,
    # worlds and historical native/backup binaries are never copied or changed.
    scripts = candidate / "scripts"
    if scripts.is_symlink():
        raise ValueError("Unsafe candidate scripts directory")
    if scripts.exists():
        shutil.rmtree(scripts)
    shutil.copytree(control / "scripts", scripts, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
    for relative in ("tests", ".github/workflows"):
        target_controls = candidate / relative
        if target_controls.is_symlink():
            raise ValueError("Unsafe candidate pipeline-control directory")
        if target_controls.exists():
            shutil.rmtree(target_controls)
        shutil.copytree(control / relative, target_controls, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
    for place in ROLES:
        rel = Path("games/dead-signal/places") / place / "deploy.json"
        (candidate / rel).write_bytes((control / rel).read_bytes())
    target = candidate / "games/dead-signal/releases"
    if target.is_symlink():
        raise ValueError("Unsafe candidate release record directory")
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(control / "games/dead-signal/releases", target)


def recovery_record(environment):
    if environment not in IDS:
        raise ValueError("Unknown recovery environment")
    record = json.loads((RECORDS / f"recovery-{environment}.json").read_text())
    ids = read_identifiers()[environment]
    if (record.get("schema") != 1 or record.get("environment") != environment
            or record.get("universe_id") != IDS[environment] or ids["universe_id"] != IDS[environment]
            or not full_sha(record.get("source_sha")) or set(record.get("places", {})) != set(ROLES)):
        raise ValueError("Recovery provenance/environment does not match")
    artifact = record.get("artifact", {})
    if (type(artifact.get("id")) is not int or type(artifact.get("run_id")) is not int
            or not full_sha(artifact.get("head_sha"))
            or not re.fullmatch(r"[0-9a-f]{64}", artifact.get("sha256", ""))):
        raise ValueError("Recovery artifact is not pinned")
    deployment = record.get("deployment", {})
    if (type(deployment.get("run_id")) is not int or type(deployment.get("workflow_id")) is not int
            or type(deployment.get("attempt")) is not int or set(deployment.get("versions", {})) != set(ROLES)):
        raise ValueError("Recovery deployment evidence is incomplete")
    for place, row in record["places"].items():
        if (row.get("place_id") != ids["places"][place] or not re.fullmatch(r"[0-9a-f]{64}", row.get("sha256", ""))
                or type(row.get("bytes")) is not int or not 100_000 < row["bytes"] < 10 * 1024 * 1024
                or not isinstance(row.get("member"), str) or ".." in row["member"].split("/")):
            raise ValueError("Recovery place/size/hash is invalid: " + place)
    return record


def source_texts(blob):
    parts = split_binary(blob)
    return {path: row["values"][i] for path, (_, i, row) in parse_headers(parts, int.from_bytes(blob[20:24], "little")).items()}


def verify_recovery(environment):
    """Never silently fall back to historical v1.7 committed backups."""
    record = recovery_record(environment)
    generate(ROOT / "build/dead-signal-place-configs")
    result = {}
    for place, spec in record["places"].items():
        path = RECOVERY / environment / f"{place}.rbxl"
        check_place(path)
        blob = path.read_bytes()
        if len(blob) != spec["bytes"] or digest(blob) != spec["sha256"]:
            raise ValueError("Current-release recovery hash mismatch: " + place)
        texts = source_texts(blob)
        config = (ROOT / f"build/dead-signal-place-configs/{environment}/{place}/PlaceConfig.lua").read_bytes()
        if len(texts) != 61 or texts.get("ReplicatedStorage/DeadSignal/PlaceConfig") != config:
            raise ValueError("Recovery sources/config do not match the intended environment")
        if b"DeadSignal_Profile_v1" not in texts.get("ReplicatedStorage/DeadSignal/Config", b""):
            raise ValueError("Recovery profile namespace changed")
        result[place] = {"path": str(path.relative_to(ROOT)), "sha256": spec["sha256"], "bytes": spec["bytes"],
                         "place_id": spec["place_id"], "universe_id": record["universe_id"],
                         "source_sha": record["source_sha"], "deployment_run": record["deployment"]["run_id"],
                         "version": record["deployment"]["versions"][place]}
    return result


class PrivateRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        result = super().redirect_request(req, fp, code, msg, headers, newurl)
        if urllib.parse.urlsplit(newurl).scheme != "https":
            raise ValueError("Non-HTTPS artifact redirect rejected")
        if urllib.parse.urlsplit(req.full_url).netloc != urllib.parse.urlsplit(newurl).netloc:
            result.remove_header("Authorization")
        return result


def download_recovery(environment, token, operation="deploy"):
    if operation not in ("deploy", "rollback"):
        raise ValueError("Unknown recovery operation")
    record = recovery_record(environment)
    if not token:
        raise ValueError("Read-only GitHub artifact token is required")
    artifact = record["artifact"]
    endpoint = f"https://api.github.com/repos/{REPOSITORY}/actions/artifacts/{artifact['id']}"
    opener = urllib.request.build_opener(PrivateRedirect())
    def get(url):
        request = urllib.request.Request(url, headers={"Authorization": "Bearer " + token,
            "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"})
        with opener.open(request, timeout=60) as response:
            return response.read(64 * 1024 * 1024 + 1)
    metadata = json.loads(get(endpoint))
    run = metadata.get("workflow_run", {})
    if (metadata.get("expired") is not False or metadata.get("id") != artifact["id"]
            or run.get("id") != artifact["run_id"] or run.get("head_sha") != artifact["head_sha"]):
        raise ValueError("Recovery artifact expired or its source/run changed; review a replacement")
    # A new deployment needs proof that its recovery pointer is current. An
    # explicitly authorized rollback restores the named known-good release even
    # after a failed upload; it must not depend on candidate CI or latest status.
    if operation == "deploy":
        deployment = record["deployment"]
        latest = json.loads(get(f"https://api.github.com/repos/{REPOSITORY}/actions/workflows/{deployment['workflow_id']}/runs?branch=main&per_page=10"))
        current = os.getenv("GITHUB_RUN_ID", "")
        runs = [row for row in latest.get("workflow_runs", []) if str(row.get("id")) != current]
        if (not runs or runs[0].get("id") != deployment["run_id"] or runs[0].get("run_attempt") != deployment["attempt"]
                or runs[0].get("status") != "completed" or runs[0].get("conclusion") != "success"):
            raise ValueError("A newer/failed release exists; reconcile the recovery pointer before publishing")
    blob = get(endpoint + "/zip")
    if len(blob) > 64 * 1024 * 1024 or digest(blob) != artifact["sha256"]:
        raise ValueError("Recovery archive hash mismatch")
    directory = RECOVERY / environment
    directory.mkdir(parents=True, exist_ok=True)
    with ZipFile(io.BytesIO(blob)) as archive:
        names = archive.namelist()
        for place, row in record["places"].items():
            if names.count(row["member"]) != 1 or archive.getinfo(row["member"]).file_size != row["bytes"]:
                raise ValueError("Missing/ambiguous/oversized recovery archive member")
            data = archive.read(row["member"])
            if digest(data) != row["sha256"]:
                raise ValueError("Recovery member hash mismatch")
            (directory / f"{place}.rbxl").write_bytes(data)
    verify_recovery(environment)
    print("Verified four current-release recovery files for " + environment + "; no Roblox requests")


if __name__ == "__main__":
    cli = argparse.ArgumentParser()
    sub = cli.add_subparsers(dest="command", required=True)
    p = sub.add_parser("controls")
    p.add_argument("--control", type=Path, required=True)
    p.add_argument("--candidate", type=Path, required=True)
    p.add_argument("--operation", choices=("deploy", "rollback"), required=True)
    p.add_argument("--source-sha", default="")
    p.add_argument("--environment", choices=tuple(IDS), default="staging")
    p = sub.add_parser("recovery")
    p.add_argument("--environment", choices=tuple(IDS), required=True)
    p.add_argument("--operation", choices=("deploy", "rollback"), default="deploy")
    args = cli.parse_args()
    if args.command == "controls":
        install_controls(args.control, args.candidate, args.operation, args.source_sha, args.environment)
    else:
        download_recovery(args.environment, os.getenv("GH_TOKEN", ""), args.operation)
