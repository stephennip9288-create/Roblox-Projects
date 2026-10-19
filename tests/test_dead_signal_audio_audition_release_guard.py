"""Fail-closed safeguards for the owner's 84-sound, staging-only audition release."""
import copy
import json
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"scripts"))
import dead_signal_release_guard as guard

class AudioAuditionAdmissionTests(unittest.TestCase):
    def test_real_proposal_is_narrow_private_staging_and_pinned(self):
        record=json.loads((guard.RECORDS/"batch-1-1-audio-audition-qa.json").read_text())
        source=record["source_sha"]
        self.assertIsNotNone(guard.staging_audio_qa_completion(record,source))
        self.assertEqual(record["audition_asset_count"],84)
        self.assertFalse(record["scope_complete"])
        self.assertFalse(record["bugs_verified"])
        self.assertFalse(record["production_authorization"])
        self.assertTrue(record["moderation_approval_unverified"])
        self.assertTrue(record["listening_acceptance_unverified"])
        self.assertEqual(record["staging_universe_id"],guard.IDS["staging"])
        for fail in ("wrong_sha","wrong_universe","missing_owner","fake_verified",
                     "fake_production","fake_scope","asset_count","moderation",
                     "audition_approved","rollback","binary","bytes","not_qa"):
            with self.subTest(fail=fail):
                bad=copy.deepcopy(record)
                if fail=="wrong_sha":bad["source_sha"]="0"*40
                elif fail=="wrong_universe":bad["staging_universe_id"]=guard.IDS["production"]
                elif fail=="missing_owner":bad["owner_staging_authorization"]=False
                elif fail=="fake_verified":bad["bug_status"]["DS-B1-001"]="Verified"
                elif fail=="fake_production":bad["production_authorization"]=True
                elif fail=="fake_scope":bad["scope_complete"]=True
                elif fail=="asset_count":bad["audition_asset_count"]=83
                elif fail=="moderation":bad["moderation_approval_unverified"]=False
                elif fail=="audition_approved":bad["listening_acceptance_unverified"]=False
                elif fail=="rollback":bad["rollback_deployment_run"]=39056526660
                elif fail=="binary":bad["staging_binary_sha256"].pop("whiteout")
                elif fail=="bytes":bad["staging_binary_bytes"]["dispatch"]=0
                else:bad["approval_scope"]="PRIVATE_STAGING_QA_ONLY"
                with self.assertRaises(ValueError):
                    guard.staging_audio_qa_completion(bad,source)

if __name__=="__main__":
    unittest.main()
