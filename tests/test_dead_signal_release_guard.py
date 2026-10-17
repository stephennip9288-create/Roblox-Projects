"""Complete-release, source isolation, recovery and no-network safety regressions."""
import copy
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import textwrap
import unittest
from unittest.mock import patch
import urllib.request
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import dead_signal_release_guard as guard
import dead_signal_staging_rollout as staging
import dead_signal_production_rollout as production


def ready(sha="a" * 40):
    return {"schema": 1, "release": "dead-signal-batch-1", "ready_for_staging": True, "source_sha": sha,
            "lanes": {lane: {"complete": True, "reviewed": True, "pr": 100 + i, "head_sha": sha} for i, lane in enumerate(guard.LANES)},
            "requirements": {key: {"lane": lane, "implementation": "complete", "evidence": ["reviewed source + regression evidence"]} for key, lane in guard.REQUIREMENTS.items()},
            "verification": {key: True for key in ("regression", "four_place_fidelity", "config_isolation", "shared_contracts", "recovery")}}


class CompletionTests(unittest.TestCase):
    def test_real_record_is_blocked_and_tracks_every_requirement(self):
        record = json.loads((guard.RECORDS / "batch-1.json").read_text())
        self.assertEqual(set(record["requirements"]), set(guard.REQUIREMENTS))
        self.assertEqual(len(record["requirements"]), 31)
        self.assertEqual(set(record["lanes"]), set(guard.LANES))
        with self.assertRaises(ValueError): guard.completion(record, "a" * 40)

    def test_only_matching_complete_candidate_passes(self):
        self.assertIsNotNone(guard.completion(ready(), "a" * 40))
        for sha in ("main", "a" * 39, "A" * 40, "a" * 40 + "\n", "b" * 40):
            with self.subTest(sha=sha), self.assertRaises(ValueError): guard.completion(ready(), sha)

    def test_each_incomplete_lane_and_duplicate_pr_blocks_release(self):
        for lane in guard.LANES:
            for field in ("complete", "reviewed"):
                record = ready();record["lanes"][lane][field] = False
                with self.subTest(lane=lane, field=field), self.assertRaises(ValueError): guard.completion(record, "a" * 40)
        record = ready();record["lanes"]["audio"]["pr"] = record["lanes"]["maps"]["pr"]
        with self.assertRaises(ValueError): guard.completion(record, "a" * 40)

    def test_every_requirement_and_verification_is_required(self):
        for key in guard.REQUIREMENTS:
            for state in ("pending", "blocked", "in_progress"):
                record = ready();record["requirements"][key]["implementation"] = state
                with self.subTest(key=key, state=state), self.assertRaises(ValueError): guard.completion(record, "a" * 40)
            record = ready();record["requirements"][key]["evidence"] = []
            with self.subTest(key=key), self.assertRaises(ValueError): guard.completion(record, "a" * 40)
        for key in ready()["verification"]:
            record = ready();record["verification"][key] = False
            with self.subTest(key=key), self.assertRaises(ValueError): guard.completion(record, "a" * 40)
        for change in ("missing", "extra"):
            record = ready()
            if change == "missing": del record["requirements"]["AUD-01"]
            else: record["requirements"]["MAP-13"] = {}
            with self.assertRaises(ValueError): guard.completion(record, "a" * 40)

    def test_incomplete_batch_cannot_reach_publisher(self):
        env = {"GITHUB_REF": "refs/heads/main", "GITHUB_REPOSITORY": guard.REPOSITORY,
               "ROBLOX_API_KEY": "synthetic-only", "RELEASE_SOURCE_SHA": "a" * 40}
        with patch.dict(os.environ, env), patch.object(staging, "publish") as upload:
            with self.assertRaises(ValueError): staging.run("deploy", "DEPLOY-PRIVATE-STAGING")
            upload.assert_not_called()


class CheckoutTests(unittest.TestCase):
    def make_repo(self, root):
        runtime = root / "games/dead-signal/dev/Source/Runtime/shared";runtime.mkdir(parents=True)
        for n in range(61): (runtime / f"M{n}.lua").write_text("return " + str(n))
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        # Git maintenance may otherwise outlive commit and race temp cleanup.
        subprocess.run(["git", "-C", str(root), "config", "gc.auto", "0"], check=True)
        subprocess.run(["git", "-C", str(root), "config", "maintenance.auto", "false"], check=True)
        subprocess.run(["git", "-C", str(root), "add", "."], check=True)
        subprocess.run(["git", "-C", str(root), "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "fixture"], check=True)
        return subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip()

    def test_real_git_checkout_and_late_tamper_or_extra_module(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp);sha = self.make_repo(root);guard.verify_source(root, ready(sha), sha)
            p = root / "games/dead-signal/dev/Source/Runtime/shared/M0.lua";p.write_text("return 'changed'")
            with self.assertRaisesRegex(ValueError, "Runtime changed"): guard.verify_checkout(root, sha)
            p.write_text("return 0")
            (p.parent / "Unexpected.lua").write_text("return true")
            with self.assertRaisesRegex(ValueError, "Unexpected"): guard.verify_checkout(root, sha)

    def test_wrong_head_or_unintegrated_lane_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp);sha = self.make_repo(root)
            with self.assertRaises(ValueError): guard.verify_checkout(root, "a" * 40)
            record = ready(sha);record["lanes"]["audio"]["head_sha"] = "f" * 40
            with self.assertRaisesRegex(ValueError, "does not contain"): guard.verify_source(root, record, sha)

    def test_trusted_controls_replace_candidate_code_without_touching_runtime_or_world(self):
        with tempfile.TemporaryDirectory() as tmp:
            control = Path(tmp) / "control";candidate = Path(tmp) / "candidate";candidate.mkdir()
            sha = self.make_repo(candidate)
            for directory in ("scripts", "tests", ".github/workflows", "games/dead-signal/releases"):
                (control / directory).mkdir(parents=True)
            (control / "scripts/publish.py").write_text("trusted")
            (control / "tests/test_guard.py").write_text("trusted tests")
            (control / "games/dead-signal/releases/batch-1.json").write_text(json.dumps(ready(sha)))
            for place in guard.ROLES:
                rel = Path("games/dead-signal/places") / place; (control / rel).mkdir(parents=True);(candidate / rel).mkdir(parents=True)
                (control / rel / "deploy.json").write_text("trusted target")
                (candidate / rel / "deploy.json").write_text("bad target")
                (candidate / rel / "production.rbxl").write_bytes(b"original native world")
            (candidate / "scripts").mkdir();(candidate / "scripts/json.py").write_text("untrusted extra")
            guard.install_controls(control, candidate, "deploy", sha)
            self.assertFalse((candidate / "scripts/json.py").exists())
            self.assertEqual((candidate / "scripts/publish.py").read_text(), "trusted")
            guard.verify_source(candidate, ready(sha), sha)
            for place in guard.ROLES:
                self.assertEqual((candidate / f"games/dead-signal/places/{place}/production.rbxl").read_bytes(), b"original native world")
            with self.assertRaises(ValueError): guard.install_controls(control, control, "deploy", sha)
            with self.assertRaises(ValueError): guard.install_controls(control, candidate, "rollback", sha)


class RecoveryTests(unittest.TestCase):
    def fixture(self):
        record = guard.recovery_record("staging");files = {};record = copy.deepcopy(record)
        for place, row in record["places"].items():
            blob = (place.encode() * 25_000)[:120_000];files[row["member"]] = blob
            row["bytes"] = len(blob);row["sha256"] = guard.digest(blob)
        out = io.BytesIO()
        with ZipFile(out, "w") as z:
            for name, blob in files.items(): z.writestr(name, blob)
        record["artifact"]["sha256"] = guard.digest(out.getvalue())
        metadata = {"id": record["artifact"]["id"], "expired": False,
                    "workflow_run": {"id": record["artifact"]["run_id"], "head_sha": record["artifact"]["head_sha"]}}
        latest = {"workflow_runs": [{"id": record["deployment"]["run_id"], "run_attempt": record["deployment"]["attempt"],
                                     "status": "completed", "conclusion": "success"}]}
        return record, metadata, latest, out.getvalue()

    def download(self, record, metadata, latest, blob, temp, operation="deploy"):
        class Opener:
            def open(self, req, timeout):
                data = blob if req.full_url.endswith("/zip") else json.dumps(latest if "/workflows/" in req.full_url else metadata).encode()
                return io.BytesIO(data)
        with patch.object(guard, "recovery_record", return_value=record), patch.object(guard, "RECOVERY", Path(temp)), \
             patch.object(guard.urllib.request, "build_opener", return_value=Opener()), patch.object(guard, "verify_recovery"):
            guard.download_recovery("staging", "synthetic-read-token", operation)

    def test_exact_artifact_extracts_only_four_pinned_recovery_files(self):
        record, metadata, latest, blob = self.fixture()
        with tempfile.TemporaryDirectory() as temp:
            self.download(record, metadata, latest, blob, temp)
            self.assertEqual(len(list((Path(temp) / "staging").glob("*.rbxl"))), 4)
            for place, row in record["places"].items():
                self.assertEqual(guard.digest((Path(temp) / "staging" / f"{place}.rbxl").read_bytes()), row["sha256"])

    def test_expired_changed_artifact_wrong_run_or_newer_failed_release_blocks(self):
        for failure in ("expired", "artifact", "source", "run", "newer", "failed", "attempt", "bytes"):
            record, metadata, latest, blob = self.fixture()
            if failure == "expired": metadata["expired"] = True
            elif failure == "artifact": metadata["id"] += 1
            elif failure == "source": metadata["workflow_run"]["head_sha"] = "a" * 40
            elif failure == "run": metadata["workflow_run"]["id"] += 1
            elif failure == "newer": latest["workflow_runs"][0]["id"] += 1
            elif failure == "failed": latest["workflow_runs"][0]["conclusion"] = "failure"
            elif failure == "attempt": latest["workflow_runs"][0]["run_attempt"] += 1
            elif failure == "bytes": blob += b"tamper"
            with tempfile.TemporaryDirectory() as temp, self.subTest(failure=failure), self.assertRaises(ValueError):
                self.download(record, metadata, latest, blob, temp)

    def test_own_running_deployment_is_ignored_for_recovery_freshness(self):
        record, metadata, latest, blob = self.fixture()
        latest["workflow_runs"].insert(0, {"id": 999999, "run_attempt": 1, "status": "in_progress", "conclusion": None})
        with tempfile.TemporaryDirectory() as temp, patch.dict(os.environ, {"GITHUB_RUN_ID": "999999"}):
            self.download(record, metadata, latest, blob, temp)

    def test_artifact_control_sha_can_differ_from_selected_game_sha(self):
        record, metadata, latest, blob = self.fixture()
        record["source_sha"] = "b" * 40
        self.assertNotEqual(record["source_sha"], record["artifact"]["head_sha"])
        with tempfile.TemporaryDirectory() as temp:
            self.download(record, metadata, latest, blob, temp)

    def test_explicit_rollback_survives_a_failed_release_but_still_checks_artifact(self):
        record, metadata, latest, blob = self.fixture()
        latest["workflow_runs"][0]["id"] += 1
        latest["workflow_runs"][0]["conclusion"] = "failure"
        with tempfile.TemporaryDirectory() as temp:
            self.download(record, metadata, latest, blob, temp, "rollback")
        with tempfile.TemporaryDirectory() as temp, self.assertRaisesRegex(ValueError, "archive hash"):
            self.download(record, metadata, latest, blob + b"tamper", temp, "rollback")
        metadata["expired"] = True
        with tempfile.TemporaryDirectory() as temp, self.assertRaisesRegex(ValueError, "expired"):
            self.download(record, metadata, latest, blob, temp, "rollback")

    def test_missing_recovery_never_uses_historical_binaries(self):
        with tempfile.TemporaryDirectory() as temp, patch.object(guard, "RECOVERY", Path(temp)):
            with self.assertRaises((ValueError, FileNotFoundError)): guard.verify_recovery("staging")
            with self.assertRaises((ValueError, FileNotFoundError)): guard.verify_recovery("production")
            self.assertEqual(len(staging.verified_baselines()), 4)  # Historical files really are present.

    def test_redirect_does_not_forward_github_token(self):
        handler = guard.PrivateRedirect();req = urllib.request.Request("https://api.github.com/a", headers={"Authorization": "Bearer synthetic"})
        redirected = handler.redirect_request(req, None, 302, "Found", {}, "https://example.invalid/artifact")
        self.assertFalse(redirected.has_header("Authorization"))
        with self.assertRaises(ValueError): handler.redirect_request(req, None, 302, "Found", {}, "http://example.invalid/artifact")

    def test_upload_checks_recovery_hash_again_before_copy(self):
        with tempfile.TemporaryDirectory() as temp:
            p = Path(temp) / "bad.rbxl";p.write_bytes(b"changed")
            row = {"rollback_file": str(p), "rollback_baseline_sha256": "0" * 64}
            with patch.object(staging, "OUTPUT", Path(temp) / "out"), self.assertRaisesRegex(ValueError, "changed after preflight"):
                staging.prepare_upload("dispatch", "rollback", {"dispatch": row})
            row = {"rollback_file": str(p), "rollback_sha256": "0" * 64}
            with patch.object(production, "ROOT_OUTPUT", Path(temp) / "out"), self.assertRaisesRegex(ValueError, "changed after preflight"):
                production.prepare("dispatch", "rollback", {"dispatch": row})


class WorkflowTests(unittest.TestCase):
    def test_staging_source_guard_executes_and_rejects_refs_and_injection(self):
        text = (ROOT / ".github/workflows/dead-signal-private-staging.yml").read_text()
        block = text.split("      - name: Validate immutable staging source\n", 1)[1].split("      - name:", 1)[0]
        script = textwrap.dedent(block.split("        run: |\n", 1)[1])
        for pin, op, accepted in [("a" * 40, "deploy", True), ("", "rollback", True), ("", "deploy", False),
                                  ("main", "deploy", False), ("A" * 40, "deploy", False), ("a" * 40, "rollback", False),
                                  ("$(echo unsafe)", "deploy", False), ("a" * 40 + "\necho unsafe", "deploy", False)]:
            result = subprocess.run(["bash", "-c", script], env=dict(os.environ, SOURCE_SHA=pin, OPERATION=op), capture_output=True)
            self.assertEqual(result.returncode == 0, accepted, (pin, op))

    def test_rollback_does_not_depend_on_candidate_test_suites(self):
        for name, step in (("dead-signal-private-staging.yml", "Validate GitHub project and staging-only configuration"),
                           ("dead-signal-production-release.yml", "Check publisher manifest and production guard tests")):
            text = (ROOT / ".github/workflows" / name).read_text()
            block = text.split("      - name: " + step + "\n", 1)[1].split("      - name:", 1)[0]
            self.assertIn("operation == 'deploy'", block)
            self.assertIn('--operation "$OPERATION"', text)

    def test_manual_main_trusted_controls_and_no_partial_staging_trigger(self):
        for name in ("dead-signal-private-staging.yml", "dead-signal-production-release.yml"):
            text = (ROOT / ".github/workflows" / name).read_text()
            self.assertNotIn("  push:", text);self.assertNotIn("  pull_request:", text)
            self.assertIn("github.ref == 'refs/heads/main'", text)
            self.assertIn("path: release-control", text);self.assertIn("path: candidate", text)
            self.assertIn("persist-credentials: false", text);self.assertIn("Reinstall trusted", text)
            self.assertIn("GH_TOKEN: ${{ github.token }}", text)
        text = (ROOT / ".github/workflows/dead-signal-private-staging.yml").read_text()
        self.assertNotIn("ROBLOX_PRODUCTION_API_KEY", text)
        self.assertIn("enforce complete Batch 1", text)


if __name__ == "__main__": unittest.main()
