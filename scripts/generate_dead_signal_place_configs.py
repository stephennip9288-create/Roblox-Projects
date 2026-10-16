#!/usr/bin/env python3
"""Generate per-environment Dead Signal PlaceConfig Lua from *validated* manifests.

This script only writes text files under build/. It never edits the shipped Work
snapshot, full-place .rbxl files, GitHub deployments, or Roblox experiences.
The output is NOT a deployable game and must be wired into a parity-tested
complete-place builder before use.
"""
import argparse
import json
from pathlib import Path

from common import ROOT, load_manifest

ROLES = {
    "dispatch": ("Lobby", "Station"),
    "blackwater": ("Match", "Station"),
    "cinderworks": ("Match", "Foundry"),
    "whiteout": ("Match", "Frost"),
}
MAP_PLACES = {"Station": "blackwater", "Foundry": "cinderworks", "Frost": "whiteout"}
ENVIRONMENTS = ("staging", "production")


def read_identifiers():
    """Gather only IDs from fully validated place manifests."""
    result = {}
    for place in ROLES:
        mode, sources, ids = load_manifest("dead-signal", place)
        if mode != "file":
            raise ValueError("Baseline requires complete-place file mode: " + place)
        for env in ENVIRONMENTS:
            if not sources[env].is_file():
                raise ValueError("Missing place source: " + str(sources[env]))
        result[place] = ids
    return validate_identifiers(result)


def validate_identifiers(configs):
    """Reject mixed-universe, duplicate-place and cross-environment IDs."""
    if set(configs) != set(ROLES):
        raise ValueError("Expected exactly four Dead Signal place configurations")
    normalized = {}
    for env in ENVIRONMENTS:
        places = {p: configs[p][env]["place_id"] for p in ROLES}
        universe_set = {configs[p][env]["universe_id"] for p in ROLES}
        if len(universe_set) != 1:
            raise ValueError(f"{env} uses multiple universe IDs")
        if len(set(places.values())) != len(ROLES):
            raise ValueError(f"{env} has duplicate place IDs")
        normalized[env] = {"universe_id": next(iter(universe_set)), "places": places}
    if normalized["staging"]["universe_id"] == normalized["production"]["universe_id"]:
        raise ValueError("Staging and production universe IDs are identical")
    for env in ENVIRONMENTS:
        other = "production" if env == "staging" else "staging"
        if set(normalized[env]["places"].values()) & set(normalized[other]["places"].values()):
            raise ValueError("Staging and production contain shared Place IDs")
    return normalized


def render_place_config(place, environment, identifiers):
    if place not in ROLES or environment not in ENVIRONMENTS:
        raise ValueError("Unknown place or environment")
    ids = identifiers[environment]
    role, map_name = ROLES[place]
    dests = ids["places"]
    return (
        "-- GENERATED FROM deploy.json; NEVER EDIT BY HAND.\n"
        f"-- Environment: {environment}; Place: {place}.\n"
        "-- For a FUTURE complete-place builder; do not deploy standalone.\n"
        "return {\n"
        f'    Role = "{role}",\n'
        f'    Map = "{map_name}",\n'
        f'    LobbyPlaceId = {dests["dispatch"]},\n'
        "    MapPlaceIds = {\n"
        + "".join(f"        {name} = {dests[slug]},\n" for name, slug in MAP_PLACES.items())
        + "    },\n"
        "    StudioPreview = true,\n"
        "}\n"
    )


def generate(destination):
    identifiers = read_identifiers()
    destination = Path(destination)
    for env in ENVIRONMENTS:
        for place in ROLES:
            path = destination / env / place / "PlaceConfig.lua"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(render_place_config(place, env, identifiers), encoding="utf-8")
        report = destination / env / "PLACE-IDS.json"
        report.write_text(json.dumps(identifiers[env], indent=2) + "\n", encoding="utf-8")
    # Fail closed if any opposite-environment ID appears in a generated module.
    for env in ENVIRONMENTS:
        other = "production" if env == "staging" else "staging"
        forbidden = set(identifiers[other]["places"].values())
        for place in ROLES:
            source = (destination / env / place / "PlaceConfig.lua").read_text(encoding="utf-8")
            if any(needle in source for needle in forbidden):
                raise ValueError(f"Cross-environment destination found in {env}/{place}")
    print("Generated 8 isolated PlaceConfig modules (staging and production). No games published.")
    return destination


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", default=str(ROOT / "build" / "dead-signal-place-configs"))
    options = parser.parse_args()
    generate(options.output_dir)
