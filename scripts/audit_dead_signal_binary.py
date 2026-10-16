#!/usr/bin/env python3
"""Raw RBXL class/property signature audit, independent of Lune serialization.

This is a strict *minimum* preservation check, NOT an engine-fidelity proof.
Unknown/dropped properties (especially Terrain) block candidate publishing.
No Roblox network access, deployment API keys, or changes to existing files.
"""
import argparse
from collections import Counter
import ctypes
import ctypes.util
import json
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
PLACES = ("dispatch", "blackwater", "cinderworks", "whiteout")
SCRIPT_CLASSES = frozenset(("Script", "LocalScript", "ModuleScript"))
MAX_FILE_BYTES = 16 * 1024 * 1024
MAX_CHUNK_BYTES = 128 * 1024 * 1024
_LIBRARIES = {}


def library(name):
    if name not in _LIBRARIES:
        location = ctypes.util.find_library(name)
        if not location:
            raise RuntimeError("Missing system compression codec " + name)
        _LIBRARIES[name] = ctypes.CDLL(location)
    return _LIBRARIES[name]


def uncompress(data, length):
    if not 0 <= length <= MAX_CHUNK_BYTES:
        raise ValueError("Unsafe uncompressed RBXL chunk length")
    buf = ctypes.create_string_buffer(max(length, 1))
    if data.startswith(b"\x28\xb5\x2f\xfd"):
        func = library("zstd").ZSTD_decompress
        func.argtypes = [ctypes.c_void_p, ctypes.c_size_t,
                         ctypes.c_void_p, ctypes.c_size_t]
        func.restype = ctypes.c_size_t
        written = func(buf, length, data, len(data))
    else:
        func = library("lz4").LZ4_decompress_safe
        func.argtypes = [ctypes.c_void_p, ctypes.c_void_p,
                         ctypes.c_int, ctypes.c_int]
        func.restype = ctypes.c_int
        written = func(data, buf, len(data), length)
    if written != length:
        raise ValueError("Cannot decompress RBXL chunk")
    return buf.raw[:length]


def u32(data, offset):
    if offset + 4 > len(data):
        raise ValueError("Truncated Roblox binary record")
    return struct.unpack_from("<I", data, offset)[0]


def inventory(path):
    """Parse raw INST/PROP records; do not deserialize with Lune/Rojo."""
    blob = Path(path).read_bytes()
    if len(blob) > MAX_FILE_BYTES:
        raise ValueError("Place exceeds input limit")
    if len(blob) < 48 or not blob.startswith(b"<roblox!\x89\xff\r\n\x1a\n"):
        raise ValueError("Invalid binary Roblox place header")
    declared_classes = u32(blob, 16)
    declared_instances = u32(blob, 20)
    offset = 32
    classes, class_counts, records = {}, {}, []
    chunk_types, unusual = Counter(), []
    finished = False
    while offset < len(blob):
        if offset + 16 > len(blob):
            raise ValueError("Partial RBXL chunk header")
        kind, compressed, expected, reserved = struct.unpack_from("<4sIII", blob, offset)
        offset += 16
        if reserved:
            raise ValueError("Unsupported RBXL chunk header")
        size = compressed or expected
        if offset + size > len(blob):
            raise ValueError("RBXL chunk exceeds file length")
        raw = blob[offset:offset + size]
        offset += size
        payload = uncompress(raw, expected) if compressed else raw
        kind_name = kind.decode("latin1")
        chunk_types[kind_name] += 1
        if kind == b"INST":
            class_id = u32(payload, 0)
            name_len = u32(payload, 4)
            if name_len > 256 or 13 + name_len > len(payload):
                raise ValueError("Invalid INST class name")
            class_name = payload[8:8 + name_len].decode("utf-8")
            count = u32(payload, 9 + name_len)
            if class_id in classes or class_name in class_counts:
                raise ValueError("Duplicate INST class")
            classes[class_id] = class_name
            class_counts[class_name] = count
        elif kind == b"PROP":
            class_id = u32(payload, 0)
            name_len = u32(payload, 4)
            if name_len > 512 or 9 + name_len > len(payload):
                raise ValueError("Invalid PROP name")
            name = payload[8:8 + name_len].decode("utf-8")
            record_type = payload[8 + name_len]
            records.append((class_id, name, record_type))
        elif kind == b"END\x00":
            finished = True
            if offset != len(blob):
                raise ValueError("Trailing RBXL data after END")
        elif kind not in (b"PRNT", b"SSTR", b"META", b"SIGN"):
            unusual.append(kind_name)
    if not finished:
        raise ValueError("RBXL END chunk missing")
    if len(classes) != declared_classes or sum(class_counts.values()) != declared_instances:
        raise ValueError("RBXL header disagrees with INST class/instance totals")
    signatures = Counter()
    for class_id, name, record_type in records:
        if class_id not in classes:
            raise ValueError("PROP refers to missing INST class")
        signatures[(classes[class_id], name, record_type)] += 1
    return {"instances": declared_instances, "classes": class_counts,
            "properties": signatures, "chunks": chunk_types, "unusual": unusual}


def compare(original, rebuilt):
    source, candidate = inventory(original), inventory(rebuilt)
    dropped, additional = [], []
    for cls, count in sorted(source["classes"].items()):
        if cls not in SCRIPT_CLASSES and candidate["classes"].get(cls) != count:
            dropped.append(f"INST {cls}: {count} -> {candidate['classes'].get(cls, 0)}")
    for (cls, name, typ), count in sorted(source["properties"].items()):
        present = candidate["properties"].get((cls, name, typ), 0)
        if present < count:
            dropped.append(f"PROP {cls}.{name} type=0x{typ:02x}: {count} -> {present}")
    for (cls, name, typ), count in sorted(candidate["properties"].items()):
        if (cls, name, typ) not in source["properties"]:
            additional.append(f"PROP {cls}.{name} type=0x{typ:02x}: +{count}")
    for name in source["unusual"]:
        if name not in candidate["unusual"]:
            dropped.append(f"Unknown chunk type lost: {name}")
    if candidate["instances"] < source["instances"]:
        dropped.append(f"Total instance count shrank: {source['instances']} -> {candidate['instances']}")
    return {"passed": len(dropped) == 0, "lost_or_changed": dropped,
            "new_property_signatures": additional,
            "baseline_instances": source["instances"],
            "candidate_instances": candidate["instances"],
            "baseline_properties": sum(source["properties"].values()),
            "candidate_properties": sum(candidate["properties"].values()),
            "terrain_baseline": sorted(f"{name} type=0x{kind:02x}"
                                       for (cls, name, kind) in source["properties"] if cls == "Terrain"),
            "terrain_candidate": sorted(f"{name} type=0x{kind:02x}"
                                        for (cls, name, kind) in candidate["properties"] if cls == "Terrain"),
            "limitations": "Signature/instance coverage only; DOES NOT prove property values, terrain voxels, Roblox rendering, animation, physics, networking, or asset permissions."}


def audit(root):
    output = root / "build/dead-signal-candidates/staging"
    output.mkdir(parents=True, exist_ok=True)
    places = {}
    for place in PLACES:
        baseline = root / f"games/dead-signal/places/{place}/staging.rbxl"
        candidate = output / f"{place}.rbxl"
        try:
            details = compare(baseline, candidate)
        except Exception as error:
            details = {"passed": False, "lost_or_changed": [f"Audit error: {type(error).__name__}: {error}"]}
        places[place] = details
        print(f"BINARY FIDELITY {place}: {'PASS' if details['passed'] else 'BLOCKED'}")
        for issue in details["lost_or_changed"][:20]:
            print("  " + issue)
    all_passed = all(x["passed"] for x in places.values())
    report = {"all_property_signatures_preserved": all_passed,
              "safe_to_publish": False, "engine_validated": False,
              "places": places,
              "warning": "Passing would not prove full binary/property value fidelity or engine correctness. Do not publish without independent Studio and client acceptance tests."}
    report_file = output / "BINARY-FIDELITY-REPORT.json"
    report_file.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"Fidelity report: {report_file}")
    return all_passed


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    arguments = parser.parse_args()
    sys.exit(0 if audit(arguments.root) else 1)
