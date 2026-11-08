"""Source ownership, original asset bytes and fail-closed owner intake."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

from audio_b2_scope import DEV, PINNED, REVIEW, blob, runtime_baseline


def module(name):
    spec=importlib.util.spec_from_file_location(name,REVIEW/(name+'.py'))
    result=importlib.util.module_from_spec(spec);spec.loader.exec_module(result)
    return result


class AudioAtmosphereB2(unittest.TestCase):
    def test_only_reviewed_runtime_deltas(self):
        baseline=json.loads((REVIEW/'BASELINE-RUNTIME.json').read_text())
        current={str(p.relative_to(DEV)):p.read_bytes() for p in (DEV/'Source/Runtime').rglob('*.lua')}
        self.assertEqual(set(current),set(baseline));self.assertEqual(len(current),61)
        from batch2_scope import reviewed_paths
        self.assertEqual({k for k,v in current.items() if blob(v)!=baseline[k]},reviewed_paths())
        for name,data in current.items():
            self.assertEqual(blob(runtime_baseline(name,data)),baseline[name],name)

    def test_non_audio_mutations_are_rejected(self):
        cases={
            'Source/Runtime/client/Effects.lua':lambda b:b.replace(b'function FX:part(',b'function FX:tampered(',1),
            'Source/Runtime/client/Controller.lua':lambda b:b.replace(b'function Controller.start(',b'function Controller.tampered(',1),
            'Source/Runtime/shared/Config.lua':lambda b:b+b'\nC.SoundIds.Reload="rbxassetid://1"\n',
        }
        for name,mutate in cases.items():
            with self.subTest(name=name),self.assertRaises((AssertionError,ValueError)):
                runtime_baseline(name,mutate((DEV/name).read_bytes()))

    def test_generated_music_snapshot_has_no_live_ids_or_approvals(self):
        doc=json.loads((REVIEW/'MUSIC-RECORDINGS.json').read_text());rows=doc['recordings']
        self.assertEqual(len(rows),10);self.assertFalse(doc['uploaded']);self.assertFalse(doc['native_listening'])
        self.assertEqual(len({r['event'] for r in rows}),10)
        self.assertEqual(len({r['pcm_sha256'] for r in rows}),10)
        for row in rows:
            with self.subTest(event=row['event']):
                data=(REVIEW/'Audio'/(row['name']+'.ogg')).read_bytes()
                self.assertTrue(data.startswith(b'OggS'));self.assertIn(b'\x01vorbis',data[:100])
                self.assertEqual(len(data),row['ogg_bytes'])
                self.assertEqual(hashlib.sha256(data).hexdigest(),row['ogg_sha256'])
                self.assertEqual(row['channels'],1);self.assertEqual(row['sample_rate'],48000)
                self.assertEqual(row['clipped_pcm_samples'],0)
                self.assertLess(row['decoded_true_peak_dbfs_4x'],-12)
                self.assertLess(row['pcm_seam_delta'],.003)
                self.assertIsNone(row['roblox_asset_id']);self.assertFalse(row['activated'])
                for flag in ['rightsCleared','creatorReviewed','listeningApproved','robloxApproved']:
                    self.assertIs(row[flag],False)
                self.assertEqual(row['permissions'],{'10771141095':False,'10770732078':False})

    def test_original_stinger_pcm_is_reproducible_without_external_samples(self):
        generator=module('prepare_music');row=json.loads((REVIEW/'MUSIC-RECORDINGS.json').read_text())['recordings'][-1]
        pcm,seconds=generator.pcm_for(generator.TRACKS[-1],len(generator.TRACKS)-1)
        self.assertEqual(seconds,3);self.assertEqual(hashlib.sha256(pcm).hexdigest(),row['pcm_sha256'])

    def test_manifest_separates_existing_banks_candidates_and_recording_gaps(self):
        m=json.loads((REVIEW/'MANIFEST.json').read_text())
        self.assertEqual(m['event_count'],125);self.assertEqual(m['new_event_count'],22)
        self.assertEqual(m['active_default_new_banks'],{});self.assertFalse(m['new_assets_activated'])
        self.assertEqual(len(m['new_music_candidates']),10);self.assertEqual(len(m['new_physical_recording_requests']),6)
        self.assertEqual(len(m['reused_approved_banks']),6)
        events=[r['event'] for group in ['new_music_candidates','new_physical_recording_requests','reused_approved_banks'] for r in m[group]]
        self.assertEqual(len(set(events)),22)
        for row in m['new_music_candidates']+m['new_physical_recording_requests']:
            self.assertIsNone(row['roblox_asset_id']);self.assertIs(row['activated'],False)
            for flag in m['required_gate_flags']:self.assertIs(row[flag],False)
        self.assertTrue(all(not row['included'] for row in m['new_physical_recording_requests']))

    def test_intake_requires_each_review_and_exact_universe(self):
        intake=module('emit_asset_intake')
        # Offline test ID only: never installed in Config or the upload return.
        good={'event':'Music.Station.Calm','roblox_asset_id':'800001','rightsCleared':True,'creatorReviewed':True,
              'listeningApproved':True,'robloxApproved':True,'permissions':{'10771141095':True}}
        self.assertEqual(intake.proposal([good],10771141095)[0]['bank']['id'],'rbxassetid://800001')
        for flag in ['rightsCleared','creatorReviewed','listeningApproved','robloxApproved']:
            bad=copy.deepcopy(good);bad[flag]=False
            with self.subTest(flag=flag),self.assertRaises(ValueError):intake.proposal([bad],10771141095)
        for value in ['',0,'0000','-1','1.0','rbxassetid://800001','1'*21,'８００００１']:
            bad=copy.deepcopy(good);bad['roblox_asset_id']=value
            with self.subTest(id=value),self.assertRaises(ValueError):intake.proposal([bad],10771141095)
        with self.assertRaises(ValueError):intake.proposal([good],10770732078)
        with self.assertRaises(ValueError):intake.proposal([good],123)
        with self.assertRaises(ValueError):intake.proposal([good,good],10771141095)
        bad=copy.deepcopy(good);bad['event']='Music.Frost.Calm'
        with self.assertRaises(ValueError):intake.proposal([good,bad],10771141095)
        bad['event']='Reload'
        with self.assertRaises(ValueError):intake.proposal([bad],10771141095)

    def test_owner_csv_is_supported_but_blank_template_cannot_activate(self):
        intake=module('emit_asset_intake');rows=intake.read_rows(REVIEW/'UPLOAD-RETURN.csv')
        self.assertEqual(len(rows),10)
        with self.assertRaises(ValueError):intake.proposal(rows,10771141095)
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'returned.csv'
            path.write_text('event,roblox_asset_id,rightsCleared,creatorReviewed,listeningApproved,robloxApproved,stagingAccess,productionAccess\nMusic.Frost.Calm,800002,true,true,true,true,true,false\n')
            returned=intake.read_rows(path)
            self.assertEqual(intake.proposal(returned,10771141095)[0]['event'],'Music.Frost.Calm')
            with self.assertRaises(ValueError):intake.proposal(returned,10770732078)


if __name__=='__main__':unittest.main()
