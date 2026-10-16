#!/usr/bin/env python3
"""Experimental, non-deploying Rojo syncback of a Dead Signal staging place.

Creates a GitHub Actions artifact only; never modifies place files or Roblox.
"""
import argparse
import json
import shutil
import subprocess
from pathlib import Path

from common import ROOT, load_manifest, check_place

SCRIPT_SERVICES = (
    "ReplicatedFirst",
    "ReplicatedStorage",
    "ServerScriptService",
    "ServerStorage",
    "StarterGui",
    "StarterPack",
    "StarterPlayer",
)

def extract(place):
    if place not in ("dispatch", "blackwater", "cinderworks", "whiteout"):
        raise ValueError("Unknown Dead Signal place")
    mode, sources, _ = load_manifest("dead-signal", place)
    if mode != "file":
        raise ValueError("Migration source must be an existing complete place file")
    source = sources["staging"]
    check_place(source)

    out = ROOT / "build" / "source-extraction" / place
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True, exist_ok=True)
    tree = {"$className": "DataModel"}
    for service in SCRIPT_SERVICES:
        folder = out / "src" / service
        folder.mkdir(parents=True)
        tree[service] = {"$path": f"src/{service}"}

    project = out / "default.project.json"
    project.write_text(
        json.dumps({"name": f"DeadSignal-{place}-source-extraction", "tree": tree}, indent=2) + "\n",
        encoding="utf-8",
    )
    # The input remains the checked-in binary: no writes to Roblox or to the repo source.
    subprocess.run(["rojo", "syncback", str(project), "--input", str(source)], cwd=str(out), check=True)
    extracted = sorted(f for f in out.rglob("*") if f.is_file())
    source_files = [f for f in extracted if f.suffix.lower() in (".luau", ".lua")]
    summary = {
        "place": place,
        "input": str(source.relative_to(ROOT)),
        "scope": list(SCRIPT_SERVICES),
        "files_extracted": len(extracted) - 1,
        "luau_files": len(source_files),
        "warning": "Experimental source extraction only. This is NOT a complete playable rebuilt place. Preserve original full-place .rbxl files and manually review output before any migration.",
    }
    (out / "EXTRACTION_REPORT.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))
    if len(extracted) <= 1:
        raise RuntimeError("Rojo syncback produced no source files. Review project mapping.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--place", choices=("dispatch", "blackwater", "cinderworks", "whiteout"), required=True)
    args = parser.parse_args()
    extract(args.place)
