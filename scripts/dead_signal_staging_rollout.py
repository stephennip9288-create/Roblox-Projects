#!/usr/bin/env python3
"""Controlled staging-only four-place rollout and rollback for Dead Signal.

No production key, production IDs, or production files can be used.
This tool is invoked only after all offline and binary-fidelity checks pass.
Recovery uses exact hash-pinned artifacts from the recorded staging release.
Historical checked-in binaries are retained for offline diagnostics only.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys

from common import ROOT, check_place, load_manifest
from generate_dead_signal_place_configs import ROLES, read_identifiers
from patch_dead_signal_rbxl import split_binary, parse_headers, desired_scripts
from publish import publish
import dead_signal_release_guard as release_guard

SOURCE_BASELINE = ROOT / "games/dead-signal/places"
CANDIDATES = ROOT / "build/dead-signal-lossless/staging"
OUTPUT = ROOT / "build/dead-signal-staging-rollout"
# Maps first; lobby last, so the lobby is never upgraded before all maps.
ORDER = ("blackwater", "cinderworks", "whiteout", "dispatch")
STAGING_UNIVERSE = "10771141095"
PRODUCTION_UNIVERSE = "10770732078"
REQUIRED_ROLLOUT = "dead-signal-v1.8.0-private-staging"
ALLOWED_MODES = ("deploy", "rollback")


def sha256(blob):
    return hashlib.sha256(blob).hexdigest()


def staging_manifest():
    configured = read_identifiers()
    if (configured["staging"]["universe_id"] != STAGING_UNIVERSE
            or configured["production"]["universe_id"] != PRODUCTION_UNIVERSE):
        raise ValueError("Hard-coded universe safety pins disagree with deploy manifests")
    return configured


def source_texts(binary):
    parts = split_binary(binary)
    paths = parse_headers(parts, int.from_bytes(binary[20:24], "little"))
    return {path: record["values"][idx] for path, (_, idx, record) in paths.items()}


def validate_candidate(place, original, modified, configs):
    # The reviewed lossless patcher changes Source PROP chunks only.
    old_chunks = split_binary(original)
    new_chunks = split_binary(modified)
    if len(old_chunks) != len(new_chunks):
        raise ValueError("RBXL chunk count changed")
    changes = 0
    for original_chunk, candidate_chunk in zip(old_chunks, new_chunks):
        if original_chunk["kind"] != candidate_chunk["kind"]:
            raise ValueError("RBXL chunk type/order changed")
        if original_chunk["raw"] != candidate_chunk["raw"]:
            changes += 1
            if original_chunk["kind"] != b"PROP":
                raise ValueError("Non-PROP binary content mutated")
            if original_chunk["payload"][:4] != candidate_chunk["payload"][:4]:
                raise ValueError("Changed PROP class")
            if original_chunk["payload"][4:9] != candidate_chunk["payload"][4:9]:
                raise ValueError("Changed PROP header metadata")
            if b"Source" not in original_chunk["payload"][:100]:
                raise ValueError("Changed a property other than script Source")
    if changes < 1:
        raise ValueError("No staging config changed")
    desired = configs["staging"]["places"]
    banned = set(configs["production"]["places"].values())
    sources = source_texts(modified)
    expected_sources = {path: content for path, (_, content) in desired_scripts(place, "staging").items()}
    if sources != expected_sources:
        raise ValueError("Staging binary sources differ from the reviewed checkout")
    config = sources.get("ReplicatedStorage/DeadSignal/PlaceConfig")
    if not config:
        raise ValueError("Missing final staging PlaceConfig")
    for forbidden in banned:
        if forbidden.encode("ascii") in config:
            raise ValueError("Production ID leaked into staging PlaceConfig")
    if str(desired["dispatch"]).encode() not in config:
        raise ValueError("Missing staging lobby ID")
    for map_name, target in {"Station": "blackwater", "Foundry": "cinderworks", "Frost": "whiteout"}.items():
        if (map_name + " = " + desired[target]).encode("ascii") not in config:
            raise ValueError("Missing staging destination: " + map_name)
    role, map_name = ROLES[place]
    for required in (f'Role = "{role}"', f'Map = "{map_name}"'):
        if required.encode("ascii") not in config:
            raise ValueError("Wrong PlaceConfig role/map: " + required)
    # Production place IDs must not be hard-coded in any source script.
    for path, content in sources.items():
        for forbidden in banned:
            if forbidden.encode("ascii") in content:
                raise ValueError("Production teleport ID in candidate source: " + path)
    return {"patched_prop_chunks": changes, "script_paths": len(sources)}


def verified_baselines():
    """Historical-file diagnostic only; never selected by an actual rollout."""
    ids = staging_manifest()
    if set(ROLES) != set(ORDER):
        raise ValueError("Unexpected number of staging places")
    reviewed = {}
    for place in ORDER:
        mode, sources, targets = load_manifest("dead-signal", place)
        if (mode != "file" or targets["staging"]["universe_id"] != STAGING_UNIVERSE
                or targets["staging"]["place_id"] != ids["staging"]["places"][place]):
            raise ValueError("Unexpected rollback place/universe: " + place)
        baseline = sources["staging"]
        if baseline != SOURCE_BASELINE / place / "staging.rbxl":
            raise ValueError("Rollback file path changed: " + place)
        nbytes = check_place(baseline)
        texts = source_texts(baseline.read_bytes())
        config = texts.get("ReplicatedStorage/DeadSignal/PlaceConfig")
        if config is None:
            raise ValueError("Rollback baseline missing PlaceConfig: " + place)
        for live_id in ids["production"]["places"].values():
            if live_id.encode("ascii") in config:
                raise ValueError("Rollback baseline points to production: " + place)
        reviewed[place] = {
            "staging_place_id": targets["staging"]["place_id"],
            "staging_universe_id": targets["staging"]["universe_id"],
            "rollback_baseline_sha256": sha256(baseline.read_bytes()),
            "rollback_baseline_bytes": nbytes,
        }
    return reviewed


def current_baselines():
    """The exact artifacts of the last recorded successful staging release."""
    return {place: {"staging_place_id": row["place_id"], "staging_universe_id": row["universe_id"],
                    "rollback_baseline_sha256": row["sha256"], "rollback_baseline_bytes": row["bytes"],
                    "rollback_file": row["path"], "recovery_source_sha": row["source_sha"],
                    "recovery_deployment_run": row["deployment_run"], "recovery_version": row["version"]}
            for place, row in release_guard.verify_recovery("staging").items()}


def approved_release_source():
    return release_guard.verify_staging_deploy_source(ROOT, os.getenv("RELEASE_SOURCE_SHA", ""))


def preflight(current=False):
    ids = staging_manifest()
    reviewed = current_baselines() if current else verified_baselines()
    expected = set(ORDER)
    report = json.loads((CANDIDATES / "LOSSLESS-REPORT.json").read_text("utf-8"))
    fidelity = json.loads((CANDIDATES / "BINARY-FIDELITY-REPORT.json").read_text("utf-8"))
    if set(report) != expected or set(fidelity.get("places", {})) != expected:
        raise ValueError("Missing full four-place patch/fidelity reports")
    if not fidelity.get("all_property_signatures_preserved"):
        raise ValueError("Binary fidelity report was blocked")
    for place in ORDER:
        candidate = CANDIDATES / f"{place}.rbxl"
        check_place(candidate)
        native = ROOT / "games/dead-signal/full-baselines/v1.8.0" / f"{place}.rbxl"
        check_place(native)
        candidate_bytes = candidate.read_bytes()
        native_bytes = native.read_bytes()
        entry = report[place]
        if not entry.get("all_untouched_chunks_byte_identical") or entry.get("expected_replacement_count") != 61 or entry.get("changed_script_count") < 1:
            raise ValueError("Source patch validation missing: " + place)
        if entry["source_sha256"] != sha256(native_bytes) or entry["candidate_sha256"] != sha256(candidate_bytes):
            raise ValueError("Source hash mismatch: " + place)
        if not fidelity["places"][place]["passed"]:
            raise ValueError("Raw-property check failed: " + place)
        inspect = validate_candidate(place, native_bytes, candidate_bytes, ids)
        reviewed[place].update({
            "candidate_sha256": sha256(candidate_bytes),
            "candidate_bytes": candidate.stat().st_size,
            **inspect,
        })
    return reviewed


def prepare_upload(place, operation, approved):
    if operation not in ALLOWED_MODES or place not in ORDER:
        raise ValueError("Unsupported rollout mode or place")
    entry = approved[place]
    source = (CANDIDATES / f"{place}.rbxl") if operation == "deploy" else (ROOT / entry["rollback_file"])
    expected = entry["candidate_sha256"] if operation == "deploy" else entry["rollback_baseline_sha256"]
    if sha256(source.read_bytes()) != expected:
        raise ValueError("Publish/recovery bytes changed after preflight: " + place)
    directory = OUTPUT / "publish"
    if directory.exists():
        shutil.rmtree(directory)
    directory.mkdir(parents=True)
    shutil.copy2(source, directory / "place.rbxl")
    check_place(directory / "place.rbxl")
    metadata = {
        "game": "dead-signal", "place": place, "target": "staging", "mode": "file",
        "universe_id": entry["staging_universe_id"], "place_id": entry["staging_place_id"],
        "file_name": "place.rbxl", "byte_count": (directory / "place.rbxl").stat().st_size
    }
    (directory / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    return directory


def write_backup_manifest(approved):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    backup = {
        "game": "dead-signal", "target": "staging",
        "source": "Verified published-release artifacts" if all("rollback_file" in v for v in approved.values()) else "Historical committed files (offline audit only; not selected for deployment)",
        "rollback_files": {k: {"place_id": v["staging_place_id"], "sha256": v["rollback_baseline_sha256"],
                                  "byte_count": v["rollback_baseline_bytes"], "file": v.get("rollback_file"),
                                  "source_sha": v.get("recovery_source_sha"), "deployment_run": v.get("recovery_deployment_run"),
                                  "version": v.get("recovery_version")} for k, v in approved.items()},
        "production_touched": False,
    }
    (OUTPUT / "ROLLBACK-MANIFEST.json").write_text(json.dumps(backup, indent=2) + "\n", encoding="utf-8")
    return backup


def run(operation, confirmation):
    if operation not in ALLOWED_MODES:
        raise ValueError("Unsupported operation")
    required = "DEPLOY-PRIVATE-STAGING" if operation == "deploy" else "RESTORE-PRIVATE-STAGING"
    if confirmation != required:
        raise ValueError(f"Explicit {required} confirmation required")
    if os.environ.get("GITHUB_REF") != "refs/heads/main":
        raise ValueError("Private staging rollout can run ONLY from main")
    if os.environ.get("GITHUB_REPOSITORY") != "stephennip9288-create/Roblox-Projects":
        raise ValueError("Wrong GitHub repository")
    if not os.environ.get("ROBLOX_API_KEY"):
        raise ValueError("Missing staging-only Roblox API key")
    # Every publish is staged-only. Rollback works even when candidate CI is broken.
    release_record = approved_release_source() if operation == "deploy" else None
    approved = preflight(current=True) if operation == "deploy" else current_baselines()
    if isinstance(release_record, dict) and release_record.get("release") in (
            "dead-signal-batch-1-1-private-staging-qa",
            "dead-signal-batch-1-1-audio-audition-private-staging"):
        for place in ORDER:
            if approved[place]["candidate_sha256"] != release_record["staging_binary_sha256"][place]:
                raise ValueError("Pinned private-staging QA binary SHA256 mismatch: " + place)
            size = release_record.get("staging_binary_bytes", {}).get(place)
            if size is not None and approved[place]["candidate_bytes"] != size:
                raise ValueError("Pinned private-staging QA binary byte-count mismatch: " + place)
    write_backup_manifest(approved)
    print("STAGING preflight complete: 4 rollback baselines recorded; operation=" + operation, flush=True)
    uploaded = []
    results = {}
    try:
        for place in ORDER:
            directory = prepare_upload(place, operation, approved)
            print(f"Publishing {operation} -> staging / {place} / place {approved[place]['staging_place_id']}", flush=True)
            publish(directory)
            uploaded.append(place)
            results[place] = "published"
        (OUTPUT / "PUBLISH-RESULT.json").write_text(json.dumps(
            {"operation": operation, "places": results, "production_touched": False}, indent=2) + "\n", encoding="utf-8")
        print("All four STAGING places published; complete actual-device acceptance testing next.", flush=True)
    except Exception as first_error:
        print("STAGING PUBLISH FAILED. Attempting rollback of all four places using verified release artifacts.", file=sys.stderr, flush=True)
        rollback_failures = []
        # When a network timeout occurs Roblox might have accepted the in-flight upload:
        # always restore all four, regardless of prior published count.
        for place in ORDER:
            try:
                publish(prepare_upload(place, "rollback", approved))
                print("Rolled back staging "+place, flush=True)
            except Exception as rollback_error:
                rollback_failures.append({"place": place, "error": str(rollback_error)})
                print("ROLLBACK FAILED for "+place+": "+str(rollback_error), file=sys.stderr, flush=True)
        (OUTPUT / "PUBLISH-RESULT.json").write_text(json.dumps(
            {"operation": operation, "first_error": str(first_error),
             "updated_before_failure": uploaded, "rollback_failures": rollback_failures,
             "production_touched": False}, indent=2) + "\n", encoding="utf-8")
        if rollback_failures:
            raise RuntimeError("STAGING PARTIAL FAILURE; manual rollback required: " + str(rollback_failures)) from first_error
        raise RuntimeError("Deployment failed, but four staging baselines were re-published for rollback") from first_error


if __name__ == "__main__":
    cli = argparse.ArgumentParser()
    cli.add_argument("--operation", choices=ALLOWED_MODES, required=True)
    cli.add_argument("--confirmation", required=True)
    args = cli.parse_args()
    run(args.operation, args.confirmation)
