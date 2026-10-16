"""Static regression checks for authored, assetless Dead Signal loading scenes.

These checks establish code intent, not Roblox client image rendering.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "games/dead-signal/dev/Source/Runtime"
LOADING = (RUNTIME/"shared/LoadingScreen.lua").read_text("utf-8")
UI = (RUNTIME/"client/UI.lua").read_text("utf-8")


class LoadingBackgroundTests(unittest.TestCase):
    def test_all_four_scenes_built_locally(self):
        self.assertIn('Name="BuiltInMapBackdrop"', LOADING)
        for map_id in ("Lobby", "Station", "Foundry", "Frost"):
            self.assertIn(f'local root=scene("{map_id}")', LOADING)
            self.assertIn(map_id+"={top=Color3.fromRGB", LOADING)

    def test_asset_error_does_not_hide_local_scene(self):
        self.assertIn('self.image.Visible=validId~=""', LOADING)
        self.assertNotIn('self.image.Visible=self.image.IsLoaded', LOADING)
        self.assertIn('for name,root in pairs(self.scenes) do root.Visible=name==map end', LOADING)
        self.assertNotIn("self.backdrop.Visible=false", LOADING)

    def test_dark_overlay_wont_suppress_background(self):
        # On Roblox UIGradient, transparency near zero means nearly opaque.
        self.assertIn('NumberSequenceKeypoint.new(0,.60)', LOADING)
        self.assertNotIn('NumberSequenceKeypoint.new(0,.08)', LOADING)
        self.assertIn('NumberSequenceKeypoint.new(1,.92)', LOADING)

    def test_dispatch_initial_loading_shows(self):
        self.assertIn('self.loading:set(PC.Role=="Match" and PC.Map or "Lobby","Establishing uplink",true)', UI)

    def test_screen_stays_briefly_visible_after_scene_ready(self):
        self.assertIn("1.0-(os.clock()-(self.shownAt or os.clock()))", LOADING)
        self.assertIn('if generation~=self.generation then return end', LOADING)

    def test_original_artwork_overlay_remains_optional(self):
        self.assertIn('Content:PreloadAsync({self.image})', LOADING)
        self.assertNotIn('GetPropertyChangedSignal("IsLoaded")', LOADING)
        self.assertIn('if validId~="" then', LOADING)


if __name__ == "__main__":
    unittest.main()
