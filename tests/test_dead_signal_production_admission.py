"""Production gating regressions; all network/publish behavior stays synthetic."""
import copy
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
import dead_signal_production_admission as gate
import dead_signal_release_guard as guard
import dead_signal_production_rollout as rollout
ROOT=Path(__file__).resolve().parents[1]
RECORDS=ROOT/'games/dead-signal/releases'
NOW=datetime(2026,10,25,tzinfo=timezone.utc)


def fixtures():
    record=json.loads((RECORDS/gate.RECORD).read_text())
    permissions=json.loads((RECORDS/'batch-1-production-audio-permissions.json').read_text())
    recovery=json.loads((RECORDS/'recovery-production.json').read_text())
    recovery['artifact']['id']=99000000000
    recovery['artifact']['expires_at']='2027-01-22T00:00:00Z'
    record['ready_for_production']=True
    record['rollback']={'refreshed':True,**{k:copy.deepcopy(recovery[k]) for k in ['source_sha','artifact','deployment','places']}}
    record['ci']={name:{'source_sha':record['source_sha'],'conclusion':'success','run_id':i+1} for i,name in enumerate(sorted(gate.FAMILIES))}
    return record,recovery,permissions


class Admission(unittest.TestCase):
    def test_real_preparation_is_blocked_without_touching_publisher(self):
        record=json.loads((RECORDS/gate.RECORD).read_text())
        record['ready_for_production']=False
        with patch.object(rollout,'publish') as publish:
            with self.assertRaises(ValueError):
                gate.completion(record,record['source_sha'],{}, {})
            publish.assert_not_called()

    def test_complete_independent_production_evidence_passes(self):
        record,recovery,permissions=fixtures()
        self.assertIs(gate.completion(record,record['source_sha'],recovery,permissions,NOW),record)

    def test_each_missing_approval_permission_source_check_or_rollback_blocks(self):
        record,recovery,permissions=fixtures()
        mutations=[lambda r,p:r.update(owner_production_authorization=False),
          lambda r,p:r.update(production_universe_id='10771141095'),
          lambda r,p:r.update(source_sha='a'*40),
          lambda r,p:r['staging_acceptance'].update(owner_gameplay_accepted=False),
          lambda r,p:r['staging_acceptance'].update(independent_exhaustive_device_testing_claimed=True),
          lambda r,p:r.update(reload_gap_disposition='fallback'),
          lambda r,p:r['ci'].pop(next(iter(r['ci']))),
          lambda r,p:next(iter(r['ci'].values())).update(conclusion='failure'),
          lambda r,p:r['rollback'].update(refreshed=False),
          lambda r,p:r['rollback']['artifact'].update(id=1),
          lambda r,p:r['builds']['production'].pop('dispatch'),
          lambda r,p:p.update(universe_id=10771141095),
          lambda r,p:p['grants'].pop(),
          lambda r,p:p['grants'][0].update(result='Pending'),
          lambda r,p:p.update(native_production_playback_verified=True)]
        for mutate in mutations:
            r,p=copy.deepcopy(record),copy.deepcopy(permissions);mutate(r,p)
            with self.subTest(mutation=mutate):
                with self.assertRaises(ValueError):gate.completion(r,record['source_sha'],recovery,p,NOW)
        recovery['artifact']['expires_at']='2026-10-30T23:45:10Z'
        record['rollback']['artifact']=copy.deepcopy(recovery['artifact'])
        with self.assertRaisesRegex(ValueError,'14 days'):gate.completion(record,record['source_sha'],recovery,permissions,NOW)

    def test_current_ci_api_rejects_wrong_source_workflow_status_or_repository(self):
        record,_,_=fixtures()
        def get(url):
            i=int(url.rsplit('/',1)[1]);family=sorted(gate.FAMILIES)[i-1]
            return {'id':i,'head_sha':record['source_sha'],'path':'.github/workflows/'+family,'status':'completed','conclusion':'success','repository':{'full_name':gate.REPOSITORY}}
        gate.verify_ci(record,'synthetic',get)
        for change in [{'head_sha':'b'*40},{'path':'.github/workflows/publish.yml'},{'conclusion':'failure'},{'repository':{'full_name':'other/repo'}}]:
            with self.assertRaises(ValueError):gate.verify_ci(record,'synthetic',lambda url:{**get(url),**change})
        with self.assertRaises(ValueError):gate.verify_ci(record,'',get)

    def test_reviewed_build_pin_rejects_late_binary_change(self):
        with tempfile.TemporaryDirectory() as tmp:
            record={'builds':{}}
            for env in ['staging','production']:
                record['builds'][env]={}
                path=Path(tmp)/'build/dead-signal-lossless'/env;path.mkdir(parents=True)
                for role in sorted(gate.ROLES):
                    data=(env+role).encode();(path/(role+'.rbxl')).write_bytes(data)
                    record['builds'][env][role]={'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
            gate.verify_builds(record,tmp)
            (Path(tmp)/'build/dead-signal-lossless/production/dispatch.rbxl').write_bytes(b'tampered')
            with self.assertRaises(ValueError):gate.verify_builds(record,tmp)

    def test_production_install_and_publisher_both_use_trusted_admission(self):
        with tempfile.TemporaryDirectory() as tmp,patch.object(gate,'verify_source',side_effect=ValueError('blocked')) as admission:
            with self.assertRaisesRegex(ValueError,'blocked'):
                guard.install_controls(Path(tmp)/'control',Path(tmp)/'candidate','deploy','a'*40,'production')
            admission.assert_called_once()
            with self.assertRaisesRegex(ValueError,'blocked'):rollout.approved_release_source()
        text=(ROOT/'.github/workflows/dead-signal-production-release.yml').read_text()
        self.assertIn('environment: dead-signal-production',text)
        self.assertIn('ROBLOX_PRODUCTION_API_KEY',text)
        self.assertIn('--verify-builds',text)
        self.assertNotIn('pull_request:',text)
        self.assertNotIn('push:',text)

if __name__=='__main__':unittest.main()
