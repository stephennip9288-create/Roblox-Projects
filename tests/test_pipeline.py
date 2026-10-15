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

    def make_manifest(self, root, staging_universe=123, production_universe=456, staging_path="staging.rbxlx", production_path="production.rbxlx"):
        import json
        cfg = root / "games/test/places/lobby/deploy.json"
        cfg.parent.mkdir(parents=True)
        for filename in set((staging_path, production_path)):
            (root / filename).write_text('<roblox version="4">' + " " * 100 + '</roblox>')
        data = {
            "mode": "file",
            "staging": {"file_path": staging_path, "universe_id": staging_universe, "place_id": 234},
            "production": {"file_path": production_path, "universe_id": production_universe, "place_id": 567}
        }
        cfg.write_text(json.dumps(data))
        return cfg

    def test_staging_different_from_production_universe(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_manifest(root, production_universe=123)
            with patch.object(common, "ROOT", root):
                with self.assertRaisesRegex(ValueError, "universe IDs must differ"):
                    common.load_manifest("test", "lobby")

    def test_staging_different_from_production_source(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_manifest(root, production_path="staging.rbxlx")
            with patch.object(common, "ROOT", root):
                with self.assertRaisesRegex(ValueError, "distinct source"):
                    common.load_manifest("test", "lobby")

    def test_valid_separate_staging_and_production(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_manifest(root)
            with patch.object(common, "ROOT", root):
                mode, sources, ids = common.load_manifest("test", "lobby")
            self.assertEqual(mode, "file")
            self.assertEqual(sources["staging"].name, "staging.rbxlx")
            self.assertEqual(sources["production"].name, "production.rbxlx")
            self.assertEqual(ids["staging"]["universe_id"], "123")

if __name__ == "__main__":
    unittest.main()
