#!/usr/bin/env python3
"""Fail-closed validation for offline-only Dead Signal candidate place artifacts."""
import json
import sys
from pathlib import Path
from common import ROOT, check_place
from generate_dead_signal_place_configs import ROLES, read_identifiers

def main():
    directory = ROOT / "build" / "dead-signal-candidates" / "staging"
    report = json.loads((directory / "CANDIDATE-REPORT.json").read_text("utf-8"))
    ids = read_identifiers()["staging"]["places"]
    if not isinstance(report, list) or len(report) != len(ROLES):
        raise ValueError("Expected one candidate report for each of four places")
    found = set()
    for row in report:
        if not isinstance(row, dict):
            raise ValueError("Malformed candidate report")
        place = row.get("place")
        if place not in ROLES or place in found or place not in ids:
            raise ValueError(f"Unexpected/duplicate place in report: {place!r}")
        found.add(place)
        if row.get("environment") != "staging" or row.get("result") != "offline_inventory_pass":
            raise ValueError(f"Candidate validation failed: {place}")
        if row.get("engineValidated") is not False or row.get("playable") is not False or row.get("safeToPublish") is not False:
            raise ValueError(f"Unverified candidate misrepresented as tested: {place}")
        original, candidate = row.get("baseline", {}), row.get("candidate", {})
        for key in ("nonScripts", "parts", "meshes", "appearances", "terrain"):
            if original.get(key) != candidate.get(key):
                raise ValueError(f"World inventory differs for {place}: {key}")
        if not isinstance(row.get("updatedScripts"), int) or row["updatedScripts"] < 60:
            raise ValueError(f"Runtime script overlay not proven for {place}")
        path = directory / f"{place}.rbxl"
        size = check_place(path)
        if size != row.get("candidateBytes"):
            raise ValueError(f"Candidate size differs from report for {place}")
        print(f"OFFLINE OK: {place}: {size:,} bytes; {row['updatedScripts']} updated scripts; world counts preserved")
    actual = {p.name for p in directory.iterdir() if p.is_file()}
    expected = {"CANDIDATE-REPORT.json"} | {f"{p}.rbxl" for p in ROLES}
    if actual != expected:
        raise ValueError(f"Unexpected artifact files: {actual ^ expected}")
    print("All four candidate files validated as OFFLINE ARTIFACTS ONLY. NOT PUBLISHED.")

if __name__ == "__main__":
    try:
        main()
    except (ValueError, FileNotFoundError, KeyError, TypeError) as exc:
        print(f"Candidate artifact validation failed: {exc}", file=sys.stderr)
        sys.exit(1)
