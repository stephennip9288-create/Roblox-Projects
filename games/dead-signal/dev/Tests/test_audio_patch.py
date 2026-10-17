"""Guard the audio-only integration patch and current 61-script boundary."""
import hashlib
import importlib.util
from pathlib import Path
import unittest

DEV = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("audio_patch", DEV / "Reviews/audio-immersion/prepare_audio_patch.py")
patch = importlib.util.module_from_spec(spec)
spec.loader.exec_module(patch)


class AudioPatch(unittest.TestCase):
    def setUp(self):
        self.actual = patch.RUNTIME.read_text()
        self.source = self.actual
        self.snippet = patch.PROPOSAL.read_text()
        if "function FX:audioInit()" in self.actual:
            # The suite remains usable after the integrator installs this proposal.
            start = self.actual.index("-- AUDIO-ONLY INLINE PROPOSAL.")
            end = self.actual.index("function FX:part(")
            old = (DEV / "Tests/Fixtures/Effects-audio-before.txt").read_text()
            self.source = (self.actual[:start] + old + self.actual[end:]).replace(patch.NEW_TICK, patch.TICK, 1)

    def test_runtime_matches_reviewed_state(self):
        if "function FX:audioInit()" in self.actual:
            self.assertEqual(self.actual, patch.compose(self.source, self.snippet))
        else:
            self.assertEqual(self.actual, self.source)

    def test_compose_preserves_every_non_audio_byte(self):
        result = patch.compose(self.source, self.snippet)
        before = self.source[self.source.index("function FX:part("):]
        after = result[result.index("function FX:part("):].replace(patch.NEW_TICK, patch.TICK, 1)
        self.assertEqual(before, after)
        self.assertEqual(self.source[:self.source.index("local stock=")], result[:result.index("-- AUDIO-ONLY")])
        self.assertEqual(result.count("function FX:sound("), 1)
        self.assertEqual(result.count("function FX.new("), 1)

    def test_rejects_concurrent_audio_edits(self):
        with self.assertRaises(ValueError):
            patch.compose(self.source.replace("local stock={", "local stock={Changed=true,"), self.snippet)

    def test_rejects_duplicate_application(self):
        with self.assertRaises(ValueError):
            patch.compose(self.source.replace(patch.TICK, patch.NEW_TICK), self.snippet)

    def test_tolerates_separate_vfx_edits_without_rewriting_them(self):
        source = self.source.replace("function FX:tracer(a,b,energy)", "-- Separate approved VFX edit\nfunction FX:tracer(a,b,energy)")
        result = patch.compose(source, self.snippet)
        self.assertIn("-- Separate approved VFX edit", result)

    def test_no_added_runtime_records(self):
        self.assertEqual(len(list((DEV / "Source/Runtime").rglob("*.lua"))), 61)
        block = self.source[self.source.index("local stock="):self.source.index("function FX:part(")]
        self.assertEqual(hashlib.sha256(block.encode()).hexdigest(), patch.ORIGINAL_BLOCK_SHA256)
        self.assertNotIn("require(", self.snippet)
        self.assertNotIn("FireServer", self.snippet)


if __name__ == "__main__":
    unittest.main()
