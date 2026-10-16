"""Staging rollout safety tests: no production routing or unconfirmed external writes."""
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import dead_signal_staging_rollout as rollout


class StagingRolloutTests(unittest.TestCase):
    def test_staging_and_production_universes_pinned(self):
        ids = rollout.staging_manifest()
        self.assertEqual(ids["staging"]["universe_id"], rollout.STAGING_UNIVERSE)
        self.assertEqual(ids["production"]["universe_id"], rollout.PRODUCTION_UNIVERSE)
        self.assertNotEqual(ids["staging"]["universe_id"], ids["production"]["universe_id"])

    def test_place_order_prioritizes_maps_before_dispatch(self):
        self.assertEqual(rollout.ORDER, ("blackwater", "cinderworks", "whiteout", "dispatch"))

    def test_rollback_baselines_exist_and_have_expected_staging_routes(self):
        reviewed = rollout.verified_baselines()
        self.assertEqual(set(reviewed), set(rollout.ORDER))
        ids = rollout.staging_manifest()["staging"]["places"]
        for place in rollout.ORDER:
            self.assertEqual(reviewed[place]["staging_place_id"], ids[place])
            self.assertGreater(reviewed[place]["rollback_baseline_bytes"], 100_000)
            self.assertEqual(len(reviewed[place]["rollback_baseline_sha256"]), 64)

    def test_wrong_deploy_confirmation_never_calls_network(self):
        with patch.object(rollout, "publish") as network:
            with self.assertRaisesRegex(ValueError, "DEPLOY-PRIVATE-STAGING"):
                rollout.run("deploy", "RESTORE-PRIVATE-STAGING")
            network.assert_not_called()

    def test_production_repo_or_branch_cannot_publish(self):
        with patch.dict(os.environ, {"GITHUB_REF": "refs/heads/some-branch",
                                      "GITHUB_REPOSITORY": "stephennip9288-create/Roblox-Projects",
                                      "ROBLOX_API_KEY": "test-not-real"}):
            with patch.object(rollout, "publish") as network:
                with self.assertRaisesRegex(ValueError, "ONLY from main"):
                    rollout.run("rollback", "RESTORE-PRIVATE-STAGING")
                network.assert_not_called()

    def test_rollback_preflight_independent_of_candidate_directory(self):
        with patch.object(rollout, "CANDIDATES", Path("/definitely-not-present")):
            reviewed = rollout.verified_baselines()
            self.assertEqual(len(reviewed), 4)

    def test_no_production_key_name_is_used(self):
        text = (Path(__file__).resolve().parents[1] /
                "scripts/dead_signal_staging_rollout.py").read_text("utf-8")
        self.assertNotIn("ROBLOX_PRODUCTION_API_KEY", text)
        self.assertNotIn('target": "production"', text)

    def test_write_backup_manifest_contains_exact_four_and_no_production(self):
        with tempfile.TemporaryDirectory() as temp:
            with patch.object(rollout, "OUTPUT", Path(temp)):
                result = rollout.write_backup_manifest(rollout.verified_baselines())
                self.assertEqual(set(result["rollback_files"]), set(rollout.ORDER))
                self.assertEqual(result["target"], "staging")
                self.assertIs(result["production_touched"], False)
                self.assertEqual(json.loads((Path(temp)/"ROLLBACK-MANIFEST.json").read_text("utf-8")), result)


if __name__ == "__main__":
    unittest.main()
