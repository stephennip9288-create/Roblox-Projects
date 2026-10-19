"""Source-level audits for DS-B1-001 owner-requested private staging audio audition.

This is not remote Roblox moderation or audio playback verification.
"""
import json
from pathlib import Path
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]
AUDIO=ROOT/"games/dead-signal/dev/Reviews/audio-quality-b11"
CONFIG=ROOT/"games/dead-signal/dev/Source/Runtime/shared/Config.lua"
START="-- START DS-B1-001 84-ASSET PRIVATE STAGING AUDITION"
END="-- END DS-B1-001 84-ASSET PRIVATE STAGING AUDITION"
PRODUCTION="10770732078"
STAGING="10771141095"

def expected_banks():
    recordings=json.loads((AUDIO/"RECORDINGS.json").read_text())["recordings"]
    uploaded=json.loads((AUDIO/"OWNER-UPLOADS-UNVERIFIED.json").read_text())
    assert len(recordings)==len(uploaded)==84
    assert set(uploaded)=={r["name"] for r in recordings}
    banks={}
    for r in recordings:
        row=uploaded[r["name"]]
        assert re.fullmatch(r"[0-9]{11,20}",row["asset_id"])
        assert r["wav_sha256"]==row["wav_sha256"]
        assert all(row[key] is False for key in ("creator_reviewed","moderation_approved","sample_listening_approved","experience_permission_verified"))
        for slot in r["slots"]:
            base,side=(slot.rsplit(".",1) if slot.endswith((".near",".far")) else (slot,"variants"))
            bank=banks.setdefault(base,{"variants":[],"near":[],"far":[],"gain":1})
            bank[side].append("rbxassetid://"+row["asset_id"])
            if r.get("interval"):
                bank["interval"]=r["interval"]
                bank["duration"]=r["seconds"]
    return banks

class AudioStagingAuditionTests(unittest.TestCase):
    def test_84_records_58_slots_and_immutable_creator_ids(self):
        banks=expected_banks()
        self.assertEqual(len(banks), 52) # Anchored to canonical review manifest
        self.assertEqual(sum(len(b[k][side]) for k in b for side in ("variants","near","far")), 108)
        self.assertEqual(len(set(id for bank in banks.values() for side in ("variants","near","far") for id in bank[side])),84)

    def test_exact_banks_inside_staging_only_guard(self):
        text=CONFIG.read_text()
        self.assertEqual(text.count(START),1)
        self.assertEqual(text.count(END),1)
        content=text.split(START,1)[1].split(END,1)[0]
        self.assertIn("if game.GameId=="+STAGING+" then",content)
        self.assertNotIn(PRODUCTION,content)
        self.assertIn("scope=\"private-staging-only\"",content)
        self.assertTrue(content.rstrip().endswith("end"))
        line_re=re.compile(r'^\s*C\.SoundIds\["([^"]+)"\]=\{(.*)\}\s*$',re.M)
        actual=dict(line_re.findall(content))
        expected=expected_banks()
        self.assertEqual(set(actual),set(expected))
        for key,fields in expected.items():
            with self.subTest(key=key):
                line=actual[key]
                self.assertIn("gain=1",line)
                for side in ("variants","near","far"):
                    values=fields[side]
                    if values:
                        encoded=side+"={"+",".join(json.dumps(v) for v in values)+"}"
                        self.assertIn(encoded,line)
                    else:
                        self.assertNotIn(side+"={",line)
                if "interval" in fields:
                    self.assertIn("interval="+str(fields["interval"]),line)
        # Never select previews before C.SoundIds legacy defaults/empty overrides.
        self.assertGreater(text.index(START),text.index('C.SoundIds["Attack"]=""'))

    def test_audition_does_not_alter_existing_universe_or_release_gates(self):
        content=CONFIG.read_text()
        snippet=content.split(START,1)[1].split(END,1)[0]
        self.assertNotIn("publish",snippet.lower())
        record=json.loads((ROOT/"games/dead-signal/releases/batch-1-1.json").read_text())
        self.assertIs(record["ready_for_staging"],False)
        self.assertIs(record["production_authorization"],False)
        self.assertIs(record["gameplay_acceptance_complete"],False)

if __name__=="__main__":
    unittest.main()
