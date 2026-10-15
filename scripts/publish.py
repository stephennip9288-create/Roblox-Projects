import argparse
import json
import os
import urllib.request
import urllib.error
from pathlib import Path
from common import check_place, numeric_id

def publish(build_dir):
    directory = Path(build_dir).resolve()
    metadata = json.loads((directory / "metadata.json").read_text(encoding="utf-8"))
    target = metadata.get("target")
    if target not in ("staging", "production"):
        raise ValueError("Unknown deployment target")
    if target == "production" and os.getenv("PRODUCTION_CONFIRMED") != "PUBLISH":
        raise ValueError("Production deployment needs explicit confirmation")
    key = os.getenv("ROBLOX_API_KEY", "")
    if not key:
        raise ValueError("ROBLOX_API_KEY missing from GitHub Actions secrets")
    universe_id = numeric_id(metadata["universe_id"])
    place_id = numeric_id(metadata["place_id"])
    filename = metadata["file_name"]
    if filename not in ("place.rbxl", "place.rbxlx"):
        raise ValueError("Unexpected build file")
    file = directory / filename
    check_place(file)
    if file.stat().st_size != metadata["byte_count"]:
        raise ValueError("Place changed since build")
    url = f"https://apis.roblox.com/universes/v1/{universe_id}/places/{place_id}/versions?versionType=Published"
    mime = "application/xml" if file.suffix == ".rbxlx" else "application/octet-stream"
    req = urllib.request.Request(url, data=file.read_bytes(), method="POST", headers={
        "x-api-key": key, "Content-Type": mime, "Accept": "application/json"
    })
    try:
        with urllib.request.urlopen(req, timeout=180) as response:
            data = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"Roblox upload failed (HTTP {exc.code}): {exc.read(400).decode('utf-8', errors='replace')}") from None
    version = data.get("versionNumber")
    if version is None:
        raise RuntimeError("Roblox did not return a versionNumber")
    print(f"Published {metadata['game']}/{metadata['place']} to {target}; version {version}")
    summary = os.getenv("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as f:
            f.write(f"### Roblox publish success\n\n- Target: {target}\n- Place: {metadata['game']}/{metadata['place']}\n- Version: {version}\n")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--build-dir", default="build")
    a = p.parse_args()
    publish(a.build_dir)
