import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import common

class PipelineTests(unittest.TestCase):
    def test_invalid_slug(self):
        for value in ("../oops", "MyGame", "a/b", "", "bad_name"):
            with self.assertRaises(ValueError):
                common.safe_slug(value)

    def test_external_path(self):
        with self.assertRaises(ValueError):
            common.safe_path("../other.rbxl")

    def test_placeholder_id(self):
        for value in ("REPLACE_ME", "0", None, "123x", -2):
            with self.assertRaises(ValueError):
                common.numeric_id(value)

    def test_invalid_xml(self):
        with tempfile.TemporaryDirectory() as tmp:
            f = Path(tmp) / "bad.rbxlx"
            f.write_text("<notroblox>" + "x"*100 + "</notroblox>")
            with self.assertRaises(ValueError):
                common.check_place(f)

    def test_too_large(self):
        with tempfile.TemporaryDirectory() as tmp:
            f = Path(tmp) / "large.rbxl"
            with f.open("wb") as out:
                out.write(b"<roblox!")
                out.truncate(common.MAX_OPEN_CLOUD_BYTES + 1)
            with self.assertRaises(ValueError):
                common.check_place(f)

    def test_staging_different_from_production(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            cfg = root / "games/test/places/lobby/deploy.json"
            cfg.parent.mkdir(parents=True)
            (root / "place.rbxlx").write_text('<roblox version="4">' + " " * 100 + '</roblox>')
            cfg.write_text('{"mode":"file","file_path":"place.rbxlx","staging":{"universe_id":123,"place_id":234},"production":{"universe_id":123,"place_id":456}}')
            with patch.object(common, "ROOT", root):
                with self.assertRaises(ValueError):
                    common.load_manifest("test", "lobby")

if __name__ == "__main__":
    unittest.main()
