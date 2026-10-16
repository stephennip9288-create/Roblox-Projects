import copy
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from generate_dead_signal_place_configs import (
    ENVIRONMENTS, MAP_PLACES, ROLES,
    generate, read_identifiers, render_place_config, validate_identifiers,
)


class DeadSignalConfigTests(unittest.TestCase):
    def setUp(self):
        self.ids = read_identifiers()

    def test_all_four_places_each_use_one_universe(self):
        for env in ENVIRONMENTS:
            self.assertEqual(set(self.ids[env]["places"]), set(ROLES))
            self.assertEqual(len(set(self.ids[env]["places"].values())), 4)
        self.assertNotEqual(self.ids["staging"]["universe_id"], self.ids["production"]["universe_id"])

    def test_expected_lobby_and_map_destinations(self):
        for env in ENVIRONMENTS:
            for place, (role, map_name) in ROLES.items():
                source = render_place_config(place, env, self.ids)
                self.assertIn(f'Role = "{role}"', source)
                self.assertIn(f'Map = "{map_name}"', source)
                self.assertIn(f'LobbyPlaceId = {self.ids[env]["places"]["dispatch"]}', source)
                for map_key, slug in MAP_PLACES.items():
                    self.assertIn(f"{map_key} = {self.ids[env]['places'][slug]}", source)

    def test_no_opposite_environment_place_id_leaks(self):
        for env in ENVIRONMENTS:
            other = "production" if env == "staging" else "staging"
            for place in ROLES:
                src = render_place_config(place, env, self.ids)
                for forbidden in self.ids[other]["places"].values():
                    self.assertNotIn(forbidden, src)

    def test_reject_duplicate_place_ids(self):
        data = {p: {env: {"universe_id": self.ids[env]["universe_id"],
                           "place_id": self.ids[env]["places"][p]}
                    for env in ENVIRONMENTS} for p in ROLES}
        data["blackwater"]["staging"]["place_id"] = data["dispatch"]["staging"]["place_id"]
        with self.assertRaisesRegex(ValueError, "duplicate place IDs"):
            validate_identifiers(data)

    def test_reject_mixed_staging_universes(self):
        data = {p: {env: {"universe_id": self.ids[env]["universe_id"],
                           "place_id": self.ids[env]["places"][p]}
                    for env in ENVIRONMENTS} for p in ROLES}
        data["blackwater"]["staging"]["universe_id"] = "123456789"
        with self.assertRaisesRegex(ValueError, "multiple universe IDs"):
            validate_identifiers(data)

    def test_reject_shared_place_id_between_environments(self):
        data = {p: {env: {"universe_id": self.ids[env]["universe_id"],
                           "place_id": self.ids[env]["places"][p]}
                    for env in ENVIRONMENTS} for p in ROLES}
        data["blackwater"]["production"]["place_id"] = data["blackwater"]["staging"]["place_id"]
        with self.assertRaisesRegex(ValueError, "shared Place IDs"):
            validate_identifiers(data)

    def test_generate_eight_modules_and_two_reports(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = generate(tmp)
            for env in ENVIRONMENTS:
                self.assertTrue((root / env / "PLACE-IDS.json").is_file())
                for place in ROLES:
                    self.assertTrue((root / env / place / "PlaceConfig.lua").is_file())


if __name__ == "__main__":
    unittest.main()
