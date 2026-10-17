#!/usr/bin/env python3
"""Offline-only Dead Signal v1.8 production candidate admission checks.

Never connects to Roblox. Generates a report, but is not production authorization.
"""
import hashlib
import json
from pathlib import Path
import sys

from audit_dead_signal_binary import compare, ROOT
from common import load_manifest, check_place
from dead_signal_staging_rollout import source_texts, validate_candidate, ORDER
from generate_dead_signal_place_configs import ROLES, read_identifiers
from patch_dead_signal_rbxl import PINNED_ORIGINAL_SHA256

NATIVE = ROOT / "games/dead-signal/full-baselines/v1.8.0"
BUILDS = ROOT / "build/dead-signal-lossless"
PROD = BUILDS / "production"
STAGING = BUILDS / "staging"
REPORT = PROD / "PRODUCTION-READINESS.json"
EXPECTED = set(ROLES)


def sha(b):
    return hashlib.sha256(b).hexdigest()


def inspect(emit=True):
    ids = read_identifiers()
    production_universe = ids["production"]["universe_id"]
    staging_universe = ids["staging"]["universe_id"]
    if production_universe != "10770732078" or staging_universe != "10771141095":
        raise ValueError("Universe identity pins disagree with manifests")
    prod_report = json.loads((PROD / "LOSSLESS-REPORT.json").read_text("utf-8"))
    stage_report = json.loads((STAGING / "LOSSLESS-REPORT.json").read_text("utf-8"))
    if set(prod_report) != EXPECTED or set(stage_report) != EXPECTED:
        raise ValueError("One or more environment source reports are missing")
    result = {}
    for place in ORDER:
        _, sources, configured = load_manifest("dead-signal", place)
        if configured["production"]["universe_id"] != production_universe or configured["production"]["place_id"] != ids["production"]["places"][place]:
            raise ValueError("Incorrect production target for " + place)
        baseline = sources["production"]
        baseline_size = check_place(baseline)
        native = NATIVE / f"{place}.rbxl"
        check_place(native)
        native_bytes = native.read_bytes()
        if sha(native_bytes) != PINNED_ORIGINAL_SHA256[place]:
            raise ValueError("Native Work source baseline mismatch for " + place)
        candidate = PROD / f"{place}.rbxl"
        stage_candidate = STAGING / f"{place}.rbxl"
        check_place(candidate)
        check_place(stage_candidate)
        built = candidate.read_bytes()
        stage_built = stage_candidate.read_bytes()
        p = prod_report[place]
        s = stage_report[place]
        if p.get("environment") != "production" or s.get("environment") != "staging":
            raise ValueError("Incorrect artifact target label for " + place)
        for entry, blob in ((p, built), (s, stage_built)):
            if not entry.get("all_untouched_chunks_byte_identical") or entry.get("expected_replacement_count") != 61:
                raise ValueError("Untrusted patch report for " + place)
            if entry["source_sha256"] != sha(native_bytes) or entry["candidate_sha256"] != sha(blob):
                raise ValueError("Patched candidate checksum mismatch: " + place)
        raw = compare(native, candidate)
        if not raw["passed"]:
            raise ValueError("Production raw-property preservation failed for " + place + ": " + repr(raw["lost_or_changed"][:4]))
        prod_scripts = source_texts(built)
        stage_scripts = source_texts(stage_built)
        validate_candidate(place, native_bytes, stage_built, ids)
        path = "ReplicatedStorage/DeadSignal/PlaceConfig"
        production_conf = prod_scripts.pop(path, None)
        staging_conf = stage_scripts.pop(path, None)
        if production_conf is None or staging_conf is None:
            raise ValueError("Environment PlaceConfig missing in " + place)
        expected_prod = (BUILDS.parent / "dead-signal-place-configs" / "production" / place / "PlaceConfig.lua").read_bytes()
        expected_stage = (BUILDS.parent / "dead-signal-place-configs" / "staging" / place / "PlaceConfig.lua").read_bytes()
        if production_conf != expected_prod or staging_conf != expected_stage:
            raise ValueError("Generated environment config source mismatch for " + place)
        if prod_scripts != stage_scripts:
            raise ValueError("Non-PlaceConfig scripts differ between staging and production: " + place)
        for other_id in ids["staging"]["places"].values():
            token = other_id.encode("ascii")
            if token in production_conf or any(token in src for src in prod_scripts.values()):
                raise ValueError("Staging Place ID detected inside production source: " + place)
        for name, slug in (("Station", "blackwater"), ("Foundry", "cinderworks"), ("Frost", "whiteout")):
            if (name + " = " + ids["production"]["places"][slug]).encode() not in production_conf:
                raise ValueError("Production map destination missing: " + place + "/" + name)
        role, map_name = ROLES[place]
        if f'Role = "{role}"'.encode() not in production_conf or f'Map = "{map_name}"'.encode() not in production_conf:
            raise ValueError("Wrong role or map in production " + place)
        if b'DeadSignal_Profile_v1' not in prod_scripts.get("ReplicatedStorage/DeadSignal/Config", b""):
            raise ValueError("Expected save-data profile namespace missing: " + place)
        result[place] = {
            "universe_id": production_universe,
            "place_id": ids["production"]["places"][place],
            "candidate_sha256": sha(built),
            "candidate_bytes": len(built),
            "rollback_production_path": str(baseline.relative_to(ROOT)),
            "rollback_sha256": sha(baseline.read_bytes()),
            "rollback_bytes": baseline_size,
            "source_instances": len(prod_scripts)+1,
            "exactly_matching_non_config_scripts": True,
            "production_ids_verified": True,
            "staging_ids_absent": True,
            "raw_binary_schema_preserved": True,
        }
        if emit:
            print(f"PRODUCTION READINESS (offline): {place}: {result[place]['place_id']}; {len(prod_scripts)+1} source modules; rollback SHA recorded.")
    report = {
        "release": "dead-signal-v1.8.0",
        "environment": "production",
        "approval_to_publish": False,
        "roblox_runtime_verified": False,
        "production_touched": False,
        "production_rollbacks": result,
        "warning": "Offline gate only. Requires owner approval, a separate deliberately dispatched production workflow, and in-game checks."
    }
    PROD.mkdir(parents=True,exist_ok=True)
    REPORT.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    if emit:
        print("Four production candidates passed offline source/teleport/rollback checks. NO PRODUCTION PUBLISH.")
    return report


if __name__ == "__main__":
    try:
        inspect()
    except Exception as e:
        print(f"PRODUCTION BLOCKED: {type(e).__name__}: {e}",file=sys.stderr)
        sys.exit(1)
