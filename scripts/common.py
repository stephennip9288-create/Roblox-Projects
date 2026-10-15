import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SLUG = re.compile(r"^[a-z0-9][a-z0-9-]{0,50}$")
MAX_OPEN_CLOUD_BYTES = 10 * 1024 * 1024

def safe_slug(s):
    if not isinstance(s, str) or not SLUG.fullmatch(s):
        raise ValueError("Use lowercase slugs: a-z, 0-9, hyphens (max 51 chars)")
    return s

def safe_path(text):
    if not isinstance(text, str) or not text:
        raise ValueError("Missing repository-relative source path")
    p = (ROOT / text).resolve()
    if not p.is_relative_to(ROOT) or not p.is_file():
        raise ValueError("Invalid or missing source path: " + text)
    return p

def numeric_id(value):
    if isinstance(value, bool) or not str(value).isdigit() or int(value) <= 0:
        raise ValueError("Invalid/placeholder universe or place ID")
    return str(value)

def load_manifest(game, place):
    path = ROOT / "games" / safe_slug(game) / "places" / safe_slug(place) / "deploy.json"
    if not path.is_file():
        raise ValueError("Missing deployment manifest: " + str(path))
    data = json.loads(path.read_text(encoding="utf-8"))
    mode = data.get("mode")
    if mode not in ("file", "rojo"):
        raise ValueError("mode must be file or rojo")
    path_field = "file_path" if mode == "file" else "project_path"
    sources = {}
    ids = {}
    for env in ("staging", "production"):
        entry = data.get(env)
        if not isinstance(entry, dict):
            raise ValueError("Missing environment: " + env)
        ids[env] = {"universe_id": numeric_id(entry.get("universe_id")), "place_id": numeric_id(entry.get("place_id"))}
        source = safe_path(entry.get(path_field))
        if mode == "file" and source.suffix.lower() not in (".rbxl", ".rbxlx"):
            raise ValueError("file mode expects .rbxl or .rbxlx")
        if mode == "rojo" and not source.name.endswith(".project.json"):
            raise ValueError("rojo mode expects .project.json")
        sources[env] = source
    if ids["staging"]["universe_id"] == ids["production"]["universe_id"]:
        raise ValueError("Staging and production universe IDs must differ")
    if sources["staging"] == sources["production"]:
        raise ValueError("Staging and production require distinct source files/projects to prevent live teleport IDs in staging")
    return mode, sources, ids

def check_place(path):
    size = path.stat().st_size
    if size < 64 or size > MAX_OPEN_CLOUD_BYTES:
        raise ValueError("Place must be at least 64 bytes and at most 10 MiB (conservative pipeline limit)")
    if path.suffix.lower() == ".rbxlx":
        import xml.etree.ElementTree as ET
        with path.open("rb") as handle:
            root = ET.parse(handle).getroot()
        if root.tag != "roblox":
            raise ValueError("Invalid Roblox place XML root")
    elif path.suffix.lower() == ".rbxl":
        with path.open("rb") as handle:
            if not handle.read(8).startswith(b"<roblox!"):
                raise ValueError("Invalid binary Roblox place header")
    else:
        raise ValueError("Unsupported place format")
    return size
