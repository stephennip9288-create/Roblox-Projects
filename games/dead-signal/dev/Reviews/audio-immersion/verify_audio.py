"""Reproduce audio proposal tests; optionally run full regression/fidelity checks.

All proposed runtime changes are applied to a temporary copy. Checked-in runtime,
native baselines, workflows and manifests are never edited. No publishing APIs.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

from prepare_audio_patch import DEV, RUNTIME, PROPOSAL, compose


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lune", default="lune")
    parser.add_argument("--full", action="store_true")
    parser.add_argument("--lossless", action="store_true")
    parser.add_argument("--report", type=Path, default=DEV / "Validation/Audio-Report.json")
    args = parser.parse_args()
    lune = str(Path(shutil.which(args.lune) or args.lune).resolve())
    repo = DEV.parents[2]
    original = RUNTIME.read_text()
    installed = "function FX:audioInit()" in original
    proposed = original if installed else compose(original, PROPOSAL.read_text())
    before = sha(RUNTIME)
    report = {"mode": "installed runtime" if installed else "uninstalled audio proposal", "runtime_applied": installed,
              "runtime_sha256": before, "proposal_sha256": sha(PROPOSAL),
              "candidate_effects_sha256": hashlib.sha256(proposed.encode()).hexdigest(),
              "roblox_engine_playtest": False, "physical_device_listening": False,
              "asset_permissions_verified": False, "published": False, "checks": {}}

    def run(name: str, command: list[str], cwd: Path) -> str:
        result = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
        report["checks"][name] = {"passed": result.returncode == 0,
                                 "output": result.stdout + result.stderr}
        print(name + ": " + ("PASS" if result.returncode == 0 else "FAIL"), flush=True)
        if result.returncode:
            raise RuntimeError(name + "\n" + result.stdout + result.stderr)
        return result.stdout + result.stderr

    try:
        run("patch_guard", [sys.executable, "-m", "unittest", "discover", "-s", "Tests", "-p", "test_audio_patch.py", "-v"], DEV)
        output = run("audio", [lune, "run", "Tests/audio.luau"], DEV)
        report["audio_assertions"] = int(re.search(r"assertions passed:\s*(\d+)", output)[1])
        with tempfile.TemporaryDirectory(prefix="dead-signal-audio-") as directory:
            candidate = Path(directory) / "dev"
            shutil.copytree(DEV, candidate, ignore=shutil.ignore_patterns("Places", "Reviews", "Validation", "__pycache__"))
            effects = candidate / "Source/Runtime/client/Effects.lua"
            effects.write_text(proposed)
            run("candidate_syntax", [lune, "run", "Tests/syntax.luau"], candidate)
            report["runtime_scripts"] = len(list((candidate / "Source/Runtime").rglob("*.lua")))
            if args.full:
                run("pipeline", [sys.executable, "-m", "unittest", "discover", "-s", "tests"], repo)
                run("manifests", [sys.executable, "scripts/validate.py"], repo)
                fixtures = candidate / "Places"
                fixtures.mkdir()
                report["fixtures_sha256"] = {}
                for place, key in {"dispatch": "Lobby", "blackwater": "Station", "cinderworks": "Foundry", "whiteout": "Frost"}.items():
                    source = repo / f"games/dead-signal/places/{place}/staging.rbxl"
                    target = fixtures / f"DeadSignal-v1.8.0-{key}.rbxl"
                    shutil.copyfile(source, target)
                    assert sha(source) == sha(target)
                    report["fixtures_sha256"][place] = sha(source)
                run("candidate_regressions", [sys.executable, "Tests/run.py", "--lune", lune], candidate)
                report["candidate_regressions"] = json.loads((candidate / "Validation/Tests-Report.json").read_text())
            if args.lossless:
                sys.path.insert(0, str(repo / "scripts"))
                import patch_dead_signal_rbxl as patcher
                import audit_dead_signal_binary as auditor
                patcher.SOURCE_ROOT = candidate / "Source/Runtime"
                patcher.OUTPUT_ROOT = Path(directory) / "lossless"
                baseline = repo / "games/dead-signal/full-baselines/v1.8.0"
                patcher.run(baseline, "staging")
                output_dir = patcher.OUTPUT_ROOT / "staging"
                assert auditor.audit(repo, output_dir, baseline)
                report["lossless"] = json.loads((output_dir / "LOSSLESS-REPORT.json").read_text())
                report["binary_fidelity"] = json.loads((output_dir / "BINARY-FIDELITY-REPORT.json").read_text())
                assert all(row["expected_replacement_count"] == 61 and row["all_untouched_chunks_byte_identical"] for row in report["lossless"].values())
        report["passed"] = True
    finally:
        report["runtime_unchanged"] = sha(RUNTIME) == before
        report["passed"] = report.get("passed", False) and report["runtime_unchanged"]
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n")
        print("Audio report:", args.report)
        assert report["runtime_unchanged"], "Runtime Effects.lua changed while verification was running"


if __name__ == "__main__":
    main()
