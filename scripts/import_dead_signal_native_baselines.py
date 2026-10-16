#!/usr/bin/env python3
"""Validate exactly one owner-provided v1.8 Work ZIP and extract six immutable files.

CI has no Roblox publishing credentials. Never touches active games/dead-signal/places.
"""
from pathlib import Path
import hashlib
import json
import stat
import sys
import zipfile

REPO=Path(__file__).resolve().parents[1]
ARCHIVE=REPO/"games/dead-signal/imports/DeadSignal-v1.8.0-Full-Baselines-Import.zip"
TARGET=Path("games/dead-signal/full-baselines/v1.8.0")
EXPECTED_ARCHIVE_SHA256="1b07299faa8a022c13ba26f0b8ba3be7caf2cb5c0fc2db387a18e0971ec52fe7"
EXPECTED_UPSTREAM_SHA256="ea9179dd9df9c68dba1d995f3ccbf0b199190eee8eac24573abdcfd2e09bfb10"
EXPECTED_SHA256={
    "dispatch.rbxl":"a3fc4cab05e07d9a2901757007a6b52b7cf3e9acf2cbb49858a52d0a961f596c",
    "blackwater.rbxl":"b7181f8204d43dcccb37aa79797ff2a7408f4c9bc9751f3d2baf07ebd4d4d515",
    "cinderworks.rbxl":"b1b89378c2ed8cc54d5aa3b95ec6419eb4a6e23b687046ef36915d320a02127f",
    "whiteout.rbxl":"445bd3403794f65214822161b14e287363f21d7ff3713ee4079573228d78d168",
}
EXPECTED_PATHS={str(TARGET/name) for name in EXPECTED_SHA256}|{
    str(TARGET/"IMPORT-MANIFEST.json"),str(TARGET/"README.md")
}


def extract(path=ARCHIVE, root=REPO):
    path=Path(path)
    root=Path(root)
    if not path.is_file() or path.stat().st_size>13_000_000:
        raise ValueError("Exact owner-provided Work ZIP missing or unexpectedly large")
    original=path.read_bytes()
    if hashlib.sha256(original).hexdigest()!=EXPECTED_ARCHIVE_SHA256:
        raise ValueError("Work ZIP hash mismatch; refusing arbitrary input")
    files={}
    with zipfile.ZipFile(path) as z:
        if z.testzip() is not None:
            raise ValueError("Corrupted Work ZIP")
        names=[x.filename for x in z.infolist()]
        if len(names)!=6 or len(names)!=len(set(names)) or set(names)!=EXPECTED_PATHS:
            raise ValueError("ZIP must contain only the exact four original places, manifest and README")
        for entry in z.infolist():
            if entry.flag_bits & 1 or entry.is_dir():
                raise ValueError("Invalid encrypted/directory entry")
            mode=entry.external_attr>>16
            if stat.S_ISLNK(mode):
                raise ValueError("ZIP contains a symlink")
            if entry.file_size>3_500_000:
                raise ValueError("Oversized ZIP member")
            files[entry.filename]=z.read(entry)
    manifest=json.loads(files[str(TARGET/"IMPORT-MANIFEST.json")])
    if manifest.get("version")!="1.8.0" or manifest.get("source_kit_sha256")!=EXPECTED_UPSTREAM_SHA256:
        raise ValueError("Unrecognized upstream Work release")
    if not manifest.get("safety",{}).get("contains_production_place_ids"):
        raise ValueError("Unsafe/inconsistent production ID warning")
    entries=manifest.get("files")
    if not isinstance(entries,list) or len(entries)!=4:
        raise ValueError("Missing source entries")
    for item in entries:
        name=Path(item["path"]).name
        if name not in EXPECTED_SHA256 or item["path"]!=str(TARGET/name):
            raise ValueError("Unexpected manifest path")
        b=files[str(TARGET/name)]
        if (hashlib.sha256(b).hexdigest()!=EXPECTED_SHA256[name]
                or item["sha256"]!=EXPECTED_SHA256[name]
                or item["size_bytes"]!=len(b)
                or not b.startswith(b"<roblox!\x89\xff\r\n\x1a\n")):
            raise ValueError("RBXL baseline hash/content mismatch")
    expected_outputs=[root/Path(name) for name in EXPECTED_PATHS]
    if any(dst.exists() for dst in expected_outputs):
        raise ValueError("Refusing overwrite of any previously imported baseline file")
    for name in sorted(files):
        dst=root/Path(name)
        dst.parent.mkdir(parents=True,exist_ok=True)
        dst.write_bytes(files[name])
        print("IMPORTED EXACT KNOWN-GOOD ARCHIVE MEMBER:",name,len(files[name]))
    print("Validated owner v1.8 native places; contains PRODUCTION IDs; DO NOT PUBLISH.")
    return expected_outputs


if __name__=="__main__":
    try:
        extract()
    except Exception as e:
        print(f"BASELINE IMPORT REFUSED: {type(e).__name__}: {e}",file=sys.stderr)
        sys.exit(1)
