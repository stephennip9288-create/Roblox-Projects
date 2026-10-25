#!/usr/bin/env python3
"""Explicitly authorized four-place production deployment/rollback.

NEVER part of push/PR CI; manually dispatched on main only.
Exact hash-pinned artifacts of the recorded production release are recovery.
Historical committed binaries are retained for offline diagnostics only.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys

from common import ROOT, check_place, load_manifest
from dead_signal_staging_rollout import source_texts, ORDER
from generate_dead_signal_place_configs import ROLES, read_identifiers
from publish import publish
from check_dead_signal_production import inspect
import dead_signal_release_guard as release_guard

PRODUCTION_UNIVERSE = "10770732078"
STAGING_UNIVERSE = "10771141095"
ROOT_OUTPUT = ROOT / "build/dead-signal-production-release"
CANDIDATES = ROOT / "build/dead-signal-lossless/production"
OPERATIONS = ("deploy", "rollback")
CONFIRM = {"deploy": "PUBLISH-V18-PRODUCTION", "rollback": "RESTORE-PREVIOUS-PRODUCTION"}


def digest(blob):
    return hashlib.sha256(blob).hexdigest()


def verified_rollback_files():
    """Historical-file diagnostic only; never selected by an actual rollout."""
    ids = read_identifiers()
    if (ids["production"]["universe_id"] != PRODUCTION_UNIVERSE or
            ids["staging"]["universe_id"] != STAGING_UNIVERSE or set(ORDER) != set(ROLES)):
        raise ValueError("Universe or place-set mismatch")
    approved = {}
    for place in ORDER:
        mode, sources, configured = load_manifest("dead-signal", place)
        if (mode != "file" or configured["production"]["universe_id"] != PRODUCTION_UNIVERSE or
                configured["production"]["place_id"] != ids["production"]["places"][place]):
            raise ValueError("Production deployment manifest differs: " + place)
        path = sources["production"]
        expected = ROOT / "games" / "dead-signal" / "places" / place / "production.rbxl"
        if path != expected:
            raise ValueError("Unexpected production rollback path: " + str(path))
        size = check_place(path)
        contents = path.read_bytes()
        config = source_texts(contents).get("ReplicatedStorage/DeadSignal/PlaceConfig")
        if config is None:
            raise ValueError("Rollback configuration missing in " + place)
        for staged_id in ids["staging"]["places"].values():
            if staged_id.encode("ascii") in config:
                raise ValueError("Rollback binary contains staging destination: " + place)
        approved[place] = {
            "place_id": configured["production"]["place_id"],
            "universe_id": PRODUCTION_UNIVERSE,
            "rollback_file": str(path.relative_to(ROOT)),
            "rollback_sha256": digest(contents),
            "rollback_bytes": size,
        }
    return approved


def current_rollback_files():
    return {place: {"place_id": row["place_id"], "universe_id": row["universe_id"],
                    "rollback_file": row["path"], "rollback_sha256": row["sha256"], "rollback_bytes": row["bytes"],
                    "recovery_source_sha": row["source_sha"], "recovery_deployment_run": row["deployment_run"],
                    "recovery_version": row["version"]}
            for place, row in release_guard.verify_recovery("production").items()}


def approved_release_source():
    from dead_signal_production_admission import verify_source, verify_builds
    record = verify_source(ROOT, os.getenv("RELEASE_SOURCE_SHA", ""))
    verify_builds(record, ROOT)


def preflight(current=False):
    baseline = current_rollback_files() if current else verified_rollback_files()
    reviewed = inspect()
    if reviewed.get("approval_to_publish") is not False or reviewed.get("production_touched") is not False:
        raise ValueError("Unexpected non-offline readiness report")
    for place in ORDER:
        entry = reviewed["production_rollbacks"][place]
        if not current and entry["rollback_sha256"] != baseline[place]["rollback_sha256"]:
            raise ValueError("Production rollback baseline unexpectedly changed: " + place)
        if entry["place_id"] != baseline[place]["place_id"]:
            raise ValueError("Production deployment target mismatch: " + place)
        check_place(CANDIDATES / f"{place}.rbxl")
        baseline[place]["candidate_sha256"] = entry["candidate_sha256"]
    return baseline


def manifest(approved):
    ROOT_OUTPUT.mkdir(parents=True,exist_ok=True)
    result = {
        "environment": "production",
        "universe_id": PRODUCTION_UNIVERSE,
        "existing_production_files": approved,
        "warning": "Recovery uses verified recorded-release artifacts, not a live Roblox download. Check for out-of-pipeline changes before authorizing deployment.",
    }
    (ROOT_OUTPUT / "ROLLBACK-MANIFEST.json").write_text(json.dumps(result,indent=2) + "\n",encoding="utf-8")
    return result


def prepare(place,operation,approved):
    directory = ROOT_OUTPUT / "publish"
    if directory.exists():
        shutil.rmtree(directory)
    directory.mkdir(parents=True)
    if operation=="deploy":
        source = CANDIDATES / f"{place}.rbxl"
    else:
        source = ROOT / approved[place]["rollback_file"]
    expected = approved[place]["candidate_sha256"] if operation == "deploy" else approved[place]["rollback_sha256"]
    if digest(source.read_bytes()) != expected:
        raise ValueError("Publish/recovery bytes changed after preflight: " + place)
    shutil.copy2(source,directory/"place.rbxl")
    size=check_place(directory/"place.rbxl")
    metadata={
        "game":"dead-signal", "place":place, "target":"production", "mode":"file",
        "universe_id":PRODUCTION_UNIVERSE, "place_id":approved[place]["place_id"],
        "file_name":"place.rbxl", "byte_count":size,
    }
    (directory/"metadata.json").write_text(json.dumps(metadata,indent=2)+"\n",encoding="utf-8")
    return directory


def deploy(operation,confirmation):
    if operation not in OPERATIONS or confirmation!=CONFIRM.get(operation):
        raise ValueError("Invalid production action / authorization")
    if os.getenv("GITHUB_REPOSITORY")!="stephennip9288-create/Roblox-Projects" or os.getenv("GITHUB_REF")!="refs/heads/main":
        raise ValueError("Production deployment requires the original repo and main branch")
    if os.getenv("PRODUCTION_CONFIRMED")!="PUBLISH":
        raise ValueError("Production backend confirmation missing")
    if not os.getenv("ROBLOX_API_KEY"):
        raise ValueError("Production Open Cloud secret unavailable")
    if operation == "deploy":
        approved_release_source()
    approved=preflight(current=True) if operation=="deploy" else current_rollback_files()
    manifest(approved)
    updated=[]
    try:
        for place in ORDER:
            print("PRODUCTION "+operation+" / "+place+" / "+approved[place]["place_id"],flush=True)
            publish(prepare(place,operation,approved))
            updated.append(place)
        (ROOT_OUTPUT/"PUBLISH-RESULT.json").write_text(json.dumps({
            "operation":operation,"target":"production","places":updated,
            "completed":True},indent=2)+"\n",encoding="utf-8")
        print("All four production uploads accepted. Live player acceptance testing required.",flush=True)
    except Exception as error:
        # Includes ambiguous HTTP timeouts: restore all four even when uncertain
        # which prior uploads Roblox accepted.
        failures=[]
        print("Production publish failed; trying to restore all four baseline production files.",file=sys.stderr,flush=True)
        for place in ORDER:
            try:
                publish(prepare(place,"rollback",approved))
            except Exception as backup_error:
                failures.append({"place":place,"error":str(backup_error)})
                print("CRITICAL rollback failure: "+place+": "+str(backup_error),file=sys.stderr,flush=True)
        (ROOT_OUTPUT/"PUBLISH-RESULT.json").write_text(json.dumps({
            "operation":operation,"target":"production","completed":False,
            "updated_before_error":updated,"failure":str(error),"failed_rollbacks":failures
        },indent=2)+"\n",encoding="utf-8")
        if failures:
            raise RuntimeError("PRODUCTION PARTIAL FAILURE; MANUAL REPAIR REQUIRED: "+repr(failures)) from error
        raise RuntimeError("Production operation failed; original four production baselines restored") from error


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--operation",choices=OPERATIONS,required=True)
    parser.add_argument("--confirmation",required=True)
    cli=parser.parse_args()
    deploy(cli.operation,cli.confirmation)
