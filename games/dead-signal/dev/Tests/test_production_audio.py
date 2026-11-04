import json,re,unittest
from pathlib import Path
from production_audio import DEV,blob,staged_config,PRODUCTION_BLOB,BLOCK_BLOB
class ProductionAudio(unittest.TestCase):
 def test_exact_additive_production_only_source(self):
  current=(DEV/'Source/Runtime/shared/Config.lua').read_bytes();staged=staged_config(current)
  self.assertEqual(staged,(DEV/'Reviews/production-batch1/STAGED-CONFIG.lua.txt').read_bytes())
  self.assertEqual(blob(current),PRODUCTION_BLOB)
  block=(DEV/'Reviews/production-batch1/PRODUCTION-BINDINGS.luau.txt').read_bytes();self.assertEqual(blob(block),BLOCK_BLOB)
  self.assertIn(b'if game.GameId==10770732078 then',block)
  self.assertNotIn(b'117834744541770',block);self.assertNotIn(b'117522141638495',block)
 def test_tampered_source_and_duplicate_production_block_rejected(self):
  current=(DEV/'Source/Runtime/shared/Config.lua').read_bytes()
  for bad in [current+b'\n',current.replace(b'10770732078 then',b'1 then'),current+(DEV/'Reviews/production-batch1/PRODUCTION-BINDINGS.luau.txt').read_bytes()]:
   with self.assertRaises(ValueError):staged_config(bad)
 def test_owner_acceptance_is_not_invented_production_permission(self):
  data=json.loads((DEV/'Reviews/production-batch1/SOURCE-DELTA.json').read_text())
  self.assertTrue(data['owner_production_request']);self.assertTrue(data['production_audio_permission_verified']);self.assertFalse(data['production_published'])
  evidence=json.loads((DEV/'Reviews/production-batch1/AUDIO-PERMISSIONS.json').read_text())
  self.assertEqual(evidence['universe_id'],10770732078);self.assertFalse(evidence['native_production_playback_verified'])
  ids=set(re.findall(r'rbxassetid://(\d+)',(DEV/'Reviews/production-batch1/PRODUCTION-BINDINGS.luau.txt').read_text()))
  self.assertEqual(len(evidence['grants']),88);self.assertEqual(ids,{row['asset_id'] for row in evidence['grants']})
  self.assertTrue(all(row['result']=='Already added' for row in evidence['grants']))
if __name__=='__main__':unittest.main()
