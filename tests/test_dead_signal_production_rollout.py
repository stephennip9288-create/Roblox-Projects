"""Dedicated production promotion tests — never execute Open Cloud uploads."""
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import dead_signal_production_rollout as production


class ProductionRolloutTests(unittest.TestCase):
    def test_production_destinations_and_rollback_sources_are_isolated(self):
        places = production.verified_rollback_files()
        self.assertEqual(set(places), set(production.ORDER))
        for slug, entry in places.items():
            self.assertEqual(entry["universe_id"], "10770732078")
            self.assertEqual(len(entry["rollback_sha256"]), 64)
            self.assertGreater(entry["rollback_bytes"], 100_000)
            self.assertTrue(entry["rollback_file"].endswith("/" + slug + "/production.rbxl"))

    def test_no_candidate_dependency_for_rollback(self):
        with patch.object(production, "CANDIDATES", Path("/not/a/candidate")):
            self.assertEqual(len(production.verified_rollback_files()), 4)

    def test_wrong_production_confirmation_cannot_publish(self):
        with patch.object(production, "publish") as upload:
            with self.assertRaisesRegex(ValueError, "Invalid production action"):
                production.deploy("deploy", "PUBLISH")
            upload.assert_not_called()

    def test_branch_and_repo_safety_guard(self):
        with patch.dict(os.environ, {
            "GITHUB_REF": "refs/heads/feature-branch",
            "GITHUB_REPOSITORY": "stephennip9288-create/Roblox-Projects",
            "ROBLOX_API_KEY": "synthetic-only",
            "PRODUCTION_CONFIRMED": "PUBLISH"
        }):
            with patch.object(production, "publish") as uploader:
                with self.assertRaisesRegex(ValueError, "main branch"):
                    production.deploy("rollback", "RESTORE-PREVIOUS-PRODUCTION")
                uploader.assert_not_called()

    def test_missing_publisher_production_guard_blocks_publish(self):
        with patch.dict(os.environ, {
            "GITHUB_REF": "refs/heads/main",
            "GITHUB_REPOSITORY": "stephennip9288-create/Roblox-Projects",
            "ROBLOX_API_KEY": "synthetic-only"
        }, clear=True):
            with patch.object(production, "publish") as uploader:
                with self.assertRaisesRegex(ValueError, "backend confirmation"):
                    production.deploy("deploy", "PUBLISH-V18-PRODUCTION")
                uploader.assert_not_called()

    def test_manual_rollback_works_without_current_candidate(self):
        with tempfile.TemporaryDirectory() as temporary:
            actions = []
            def prepare(place, op, approved):
                actions.append((place, op))
                return Path(temporary)
            with patch.dict(os.environ, {
                "GITHUB_REF": "refs/heads/main",
                "GITHUB_REPOSITORY": "stephennip9288-create/Roblox-Projects",
                "ROBLOX_API_KEY": "synthetic-only",
                "PRODUCTION_CONFIRMED": "PUBLISH"
            }), patch.object(production, "ROOT_OUTPUT", Path(temporary)), \
                 patch.object(production, "current_rollback_files", return_value=production.verified_rollback_files()), \
                 patch.object(production, "prepare", side_effect=prepare), \
                 patch.object(production, "publish") as uploader:
                production.deploy("rollback", "RESTORE-PREVIOUS-PRODUCTION")
            self.assertEqual(uploader.call_count, 4)
            self.assertEqual(actions, [(p,"rollback") for p in production.ORDER])
            self.assertTrue((Path(temporary)/"PUBLISH-RESULT.json").exists())

    def test_failed_release_restores_all_four_even_if_request_times_out(self):
        with tempfile.TemporaryDirectory() as temporary:
            actions = []
            def prepare(place, op, approved):
                actions.append((place, op))
                return Path(temporary)
            outcomes = [None, RuntimeError("simulated timeout")] + [None] * 4
            with patch.dict(os.environ, {
                "GITHUB_REF": "refs/heads/main",
                "GITHUB_REPOSITORY": "stephennip9288-create/Roblox-Projects",
                "ROBLOX_API_KEY": "synthetic-only",
                "PRODUCTION_CONFIRMED": "PUBLISH"
            }), patch.object(production, "ROOT_OUTPUT", Path(temporary)), \
                 patch.object(production, "preflight", return_value=production.verified_rollback_files()), \
                 patch.object(production, "approved_release_source"), \
                 patch.object(production, "prepare", side_effect=prepare), \
                 patch.object(production, "publish", side_effect=outcomes) as uploader:
                with self.assertRaisesRegex(RuntimeError, "four production baselines restored"):
                    production.deploy("deploy", "PUBLISH-V18-PRODUCTION")
            self.assertEqual(uploader.call_count, 6)
            self.assertEqual(actions[:2], [(production.ORDER[0],"deploy"),(production.ORDER[1],"deploy")])
            self.assertEqual(actions[2:], [(p,"rollback") for p in production.ORDER])
            outcome = json.loads((Path(temporary)/"PUBLISH-RESULT.json").read_text("utf-8"))
            self.assertEqual(outcome["updated_before_error"], [production.ORDER[0]])
            self.assertFalse(outcome["failed_rollbacks"])


if __name__ == "__main__":
    unittest.main()
