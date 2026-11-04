"""Owner intake/provenance and independently applied review patch; no Runtime edits."""
import hashlib
from production_audio import staged_config
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

DEV=Path(__file__).resolve().parents[1]
REVIEW=DEV/'Reviews/audio-supplement-intake-b1'
spec=importlib.util.spec_from_file_location('supplemental_bindings',REVIEW/'prepare_bindings.py')
bindings=importlib.util.module_from_spec(spec);spec.loader.exec_module(bindings)


class AudioSupplementIntake(unittest.TestCase):
    def test_six_owner_confirmations_and_exact_prepared_files(self):
        intake=json.loads((REVIEW/'OWNER-APPROVALS.json').read_text())
        expected={'board_fracture_1':'121376790132442','frame_scrape_2':'126280091004313','window_contact_1':'128395906553592','wood_break_1':'91133693743569','wood_debris_1':'117834744541770','wood_stress_3':'117522141638495'}
        self.assertEqual({r['name']:r['roblox_asset_id'] for r in intake['recordings']},expected)
        self.assertEqual(intake['staging_universe_id'],'10771141095')
        canonical=json.loads((DEV/'Reviews/audio-corrections-b1/SUPPLEMENTAL-RECORDINGS.json').read_text())['recordings']
        canonical={r['name']:r for r in canonical}
        for row in intake['recordings']:
            self.assertTrue(row['owner_sample_listening_approved']);self.assertTrue(row['owner_reported_staging_access_granted'])
            for flag in ['experience_permission_verified','moderation_approved','native_gameplay_listening_passed','physical_mobile_verified','activated']:
                self.assertFalse(row[flag],flag)
            for ext,sub,key in [('wav','WAV','wav_sha256'),('ogg','Auditions','ogg_sha256')]:
                data=(DEV/'Reviews/audio-corrections-b1'/sub/(row['name']+'.'+ext)).read_bytes()
                self.assertEqual(hashlib.sha256(data).hexdigest(),canonical[row['name']][key])
                self.assertEqual(row[key],canonical[row['name']][key])

    def test_stored_patch_applies_independently_and_exactly(self):
        source=bindings.baseline(staged_config((DEV/'Source/Runtime/shared/Config.lua').read_bytes()))
        stored=(REVIEW/'STAGING-CONFIG.patch').read_text()
        self.assertEqual(stored,bindings.patch(source))
        with tempfile.TemporaryDirectory() as tmp:
            target=Path(tmp)/bindings.CONFIG_PATH;target.parent.mkdir(parents=True);target.write_bytes(source)
            result=subprocess.run(['git','apply','--check',str(REVIEW/'STAGING-CONFIG.patch')],cwd=tmp,capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)
            subprocess.run(['git','apply',str(REVIEW/'STAGING-CONFIG.patch')],cwd=tmp,check=True)
            self.assertEqual(target.read_bytes(),bindings.render(source))
            self.assertEqual(bindings.baseline(target.read_bytes()),source)

    def test_modified_base_is_rejected(self):
        source=bindings.baseline(staged_config((DEV/'Source/Runtime/shared/Config.lua').read_bytes()))
        with self.assertRaisesRegex(ValueError,'Config changed'):
            bindings.render(source+b'\n')
        with self.assertRaisesRegex(ValueError,'Config changed'):
            bindings.baseline(bindings.render(source)+b'\n')

    def test_runtime_inputs_are_exact_reviewed_versions(self):
        expected={'shared/Config.lua':'1c7a4dffde21e4cfd3d383d9a0304d06ceb585b2','client/Effects.lua':'eba3364383e7bef7fc7fbe831287b257bdd0d43a','shared/ControlSettings.lua':'9a5b6776f258c1c824d2b5b5c2cf5a19a7f70996'}
        for name,sha in expected.items():
            source=(DEV/'Source/Runtime'/name).read_bytes()
            if name=='shared/Config.lua':source=bindings.baseline(staged_config(source))
            self.assertEqual(bindings.blob(source),sha)


if __name__=='__main__':unittest.main()
