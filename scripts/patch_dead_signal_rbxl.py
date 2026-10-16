#!/usr/bin/env python3
"""Lossless-by-construction source-only RBXL patcher (staging candidates only).

Only existing Script/LocalScript/ModuleScript Source PROP chunks are recompressed.
Every other original chunk is preserved byte-for-byte, including opaque Terrain,
meshes, PBR, shared strings, tags, property values, PRNT, and unknown chunks.
Never changes source baselines or publishes to Roblox.
"""
import argparse
from collections import Counter
import ctypes
import hashlib
import json
from pathlib import Path
import struct
import sys

from audit_dead_signal_binary import ROOT, uncompress, library
from generate_dead_signal_place_configs import ROLES, read_identifiers, generate

HEADER = b"<roblox!\x89\xff\r\n\x1a\n"
CLASSES = {"ModuleScript", "Script", "LocalScript"}
PLACE_KEYS = {"dispatch": "Lobby", "blackwater": "Station", "cinderworks": "Foundry", "whiteout": "Frost"}
SOURCE_ROOT = ROOT / "games/dead-signal/dev/Source/Runtime"
CONFIG_ROOT = ROOT / "build/dead-signal-place-configs"
OUTPUT = ROOT / "build/dead-signal-lossless/staging"
LIMIT = 128 * 1024 * 1024


def read_u32(buffer, at):
    if at < 0 or at + 4 > len(buffer):
        raise ValueError("Truncated RBXL field")
    return struct.unpack_from("<I", buffer, at)[0]


def parse_string_array(data, count):
    if not 0 <= count <= 500_000:
        raise ValueError("Unsafe string array length")
    result = []
    at = 0
    for _ in range(count):
        size = read_u32(data, at)
        at += 4
        if size > LIMIT or at + size > len(data):
            raise ValueError("Truncated/oversized RBXL string")
        result.append(data[at:at+size])
        at += size
    if at != len(data):
        raise ValueError("Unexpected bytes following RBXL string array")
    return result


def encode_string_array(items):
    return b"".join(struct.pack("<I", len(v)) + v for v in items)


def decode_referents(data, count):
    if len(data) != 4*count:
        raise ValueError("Invalid referent array width")
    refs = []
    prev = 0
    for idx in range(count):
        item = int.from_bytes(bytes(data[idx+plane*count] for plane in range(4)), "big")
        delta = (item >> 1) ^ -(item & 1)
        prev += delta
        if prev < -(1 << 31) or prev >= 1 << 31:
            raise ValueError("Bad referent delta")
        refs.append(prev)
    return refs


def split_binary(data):
    if not data.startswith(HEADER) or len(data) < 48 or len(data) > 16 * 1024 * 1024:
        raise ValueError("Not an expected full binary place")
    at, parts = 32, []
    saw_end = False
    while at < len(data):
        start = at
        if at+16 > len(data):
            raise ValueError("Incomplete chunk header")
        kind, compressed, plain_len, reserved = struct.unpack_from("<4sIII",data,at)
        at += 16
        if reserved != 0 or plain_len > LIMIT:
            raise ValueError("Unsupported chunk header")
        compressed_len = compressed or plain_len
        if at+compressed_len > len(data):
            raise ValueError("Chunk beyond end")
        compressed_bytes = data[at:at+compressed_len]
        at += compressed_len
        payload = uncompress(compressed_bytes,plain_len) if compressed else compressed_bytes
        parts.append({"kind":kind,"compressed":compressed,"payload":payload,"raw":data[start:at],"codec":"zstd" if compressed_bytes.startswith(b"\x28\xb5\x2f\xfd") else "lz4" if compressed else "raw"})
        if kind == b"END\x00":
            if at != len(data):
                raise ValueError("Trailing bytes after END chunk")
            saw_end = True
    if not saw_end:
        raise ValueError("Missing END chunk")
    return parts


def compress_payload(codec,payload):
    src=ctypes.create_string_buffer(payload)
    if codec=="zstd":
        zstd=library("zstd")
        bound=zstd.ZSTD_compressBound
        bound.argtypes=[ctypes.c_size_t]
        bound.restype=ctypes.c_size_t
        size=bound(len(payload))
        target=ctypes.create_string_buffer(size)
        f=zstd.ZSTD_compress
        f.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_void_p,ctypes.c_size_t,ctypes.c_int]
        f.restype=ctypes.c_size_t
        length=f(target,size,src,len(payload),3)
        if length > size:
            raise ValueError("Zstd compression failed")
    elif codec=="lz4":
        lz=library("lz4")
        bound=lz.LZ4_compressBound
        bound.argtypes=[ctypes.c_int]
        bound.restype=ctypes.c_int
        size=bound(len(payload))
        target=ctypes.create_string_buffer(size)
        f=lz.LZ4_compress_default
        f.argtypes=[ctypes.c_void_p,ctypes.c_void_p,ctypes.c_int,ctypes.c_int]
        f.restype=ctypes.c_int
        length=f(src,target,len(payload),size)
        if length<=0:
            raise ValueError("LZ4 compression failed")
    else:
        return b"",payload
    return target.raw[:length],payload


def build_chunk(original,payload):
    if original["codec"]=="raw":
        compressed=b""
        contents=payload
    else:
        compressed,_=compress_payload(original["codec"],payload)
        contents=compressed
    return struct.pack("<4sIII",original["kind"],len(compressed),len(payload),0)+contents


def parse_headers(parts, expected_instances):
    classes={}
    class_of={}
    all_referents=set()
    name_by_ref={}
    source_chunks={}
    parents={}
    for idx,part in enumerate(parts):
        if part["kind"] != b"INST":
            continue
        payload=part["payload"]
        id_=read_u32(payload,0)
        length=read_u32(payload,4)
        if length>256 or len(payload)<13+length:
            raise ValueError("Invalid INST class")
        cls=payload[8:8+length].decode("utf-8")
        service=payload[8+length]
        count=read_u32(payload,9+length)
        offset=13+length
        ids=decode_referents(payload[offset:offset+4*count],count)
        remainder=payload[offset+4*count:]
        if service not in (0,1) or len(remainder)!=(count if service else 0):
            raise ValueError("Invalid INST service flags")
        if id_ in classes:
            raise ValueError("Duplicate class ID")
        classes[id_]=(cls,ids)
        for ref in ids:
            if ref in all_referents or ref==-1:
                raise ValueError("Duplicate/null instance referent")
            class_of[ref]=cls
            all_referents.add(ref)
    if len(all_referents)!=expected_instances:
        raise ValueError("RBXL header/INST count disagreement")
    if len(classes)==0:
        raise ValueError("Missing classes")
    for idx,part in enumerate(parts):
        if part["kind"] == b"PROP":
            payload=part["payload"]
            id_=read_u32(payload,0)
            length=read_u32(payload,4)
            if length>512 or len(payload)<9+length or id_ not in classes:
                raise ValueError("Invalid PROP metadata")
            name=payload[8:8+length].decode("utf-8")
            typ=payload[8+length]
            cls,refs=classes[id_]
            if name=="Name":
                if typ!=1:
                    raise ValueError("Names must use raw string type")
                items=parse_string_array(payload[9+length:],len(refs))
                for ref,value in zip(refs,items):
                    if ref in name_by_ref:
                        raise ValueError("Duplicate instance Name")
                    name_by_ref[ref]=value.decode("utf-8")
            if cls in CLASSES and name=="Source":
                if typ!=1:
                    raise ValueError(f"Unsafe {cls}.Source property type 0x{typ:02x}; abort")
                if cls in source_chunks:
                    raise ValueError("Duplicate Source PROP for class")
                values=parse_string_array(payload[9+length:],len(refs))
                source_chunks[cls]={"index":idx,"prefix":payload[:9+length],"refs":refs,"values":values}
        elif part["kind"]==b"PRNT":
            if parents:
                raise ValueError("Duplicate PRNT")
            payload=part["payload"]
            if not payload or payload[0]!=0:
                raise ValueError("Unsupported PRNT version")
            count=read_u32(payload,1)
            children=decode_referents(payload[5:5+count*4],count)
            parents_list=decode_referents(payload[5+count*4:],count)
            if count!=expected_instances or set(children)!=all_referents:
                raise ValueError("PRNT count/referents incomplete")
            parents=dict(zip(children,parents_list))
    if len(parents)!=expected_instances:
        raise ValueError("Missing PRNT")
    def full_name(ref):
        path=[]
        seen=set()
        while ref!=-1:
            if ref in seen or ref not in class_of:
                raise ValueError("PRNT cycle/missing referent")
            seen.add(ref)
            cls=class_of[ref]
            name=name_by_ref.get(ref,cls)
            if cls in CLASSES and ref not in name_by_ref:
                raise ValueError("Missing script Name")
            path.append(name)
            if ref not in parents:
                raise ValueError("Missing instance parent")
            ref=parents[ref]
        return "/".join(reversed(path))
    paths={}
    for cls,data in source_chunks.items():
        for i,ref in enumerate(data["refs"]):
            full=full_name(ref)
            if full in paths:
                raise ValueError("Duplicate script hierarchy path: "+full)
            paths[full]=(cls,i,data)
    return paths


def desired_scripts(place):
    expected={}
    roots={
        "shared":"ReplicatedStorage/DeadSignal",
        "server":"ServerScriptService/DeadSignalServer",
        "client":"StarterPlayer/StarterPlayerScripts/DeadSignalClient",
    }
    for group,service in roots.items():
        directory=SOURCE_ROOT/group
        for file in sorted(directory.glob("*.lua")):
            filename=file.name
            name=filename.removesuffix(".server.lua").removesuffix(".client.lua").removesuffix(".lua")
            if name=="PlaceConfig":
                continue
            cls="Script" if group=="server" and filename.endswith(".server.lua") else "LocalScript" if group=="client" and filename.endswith(".client.lua") else "ModuleScript"
            expected[f"{service}/{name}"]=(cls,file.read_bytes())
    expected["ReplicatedStorage/DeadSignal/PlaceConfig"]=(
        "ModuleScript",(CONFIG_ROOT / "staging"/ place / "PlaceConfig.lua").read_bytes())
    return expected


def patch_bytes(original, replacements):
    parts=split_binary(original)
    count=read_u32(original,20)
    resolved=parse_headers(parts,count)
    wanted=set(replacements)
    missing=wanted-set(resolved)
    if missing:
        extras=sorted(set(resolved)-wanted)
        print("BASELINE EXTRA SCRIPT PATHS (not in editable source): "+repr(extras[:60]),file=sys.stderr)
        raise ValueError("Missing script targets; would need to add INST/PRNT and cannot losslessly patch: "+", ".join(sorted(missing)[:15]))
    patches={}
    changes=[]
    for path,(cls,new_source) in replacements.items():
        found_cls,i,record=resolved[path]
        if cls!=found_cls:
            raise ValueError(f"Class mismatch for {path}: {found_cls} != {cls}")
        if not new_source or len(new_source)>2_000_000:
            raise ValueError("Empty/oversized source: "+path)
        if record["values"][i]!=new_source:
            changes.append(path)
            record["values"][i]=new_source
            patches[record["index"]]=record
    if not changes:
        raise ValueError("No runtime changes; output would equal baseline")
    assembled=[original[:32]]
    for i,part in enumerate(parts):
        if i in patches:
            record=patches[i]
            assembled.append(build_chunk(part,record["prefix"]+encode_string_array(record["values"])))
        else:
            assembled.append(part["raw"])
    output=b"".join(assembled)
    check=split_binary(output)
    if len(check)!=len(parts):
        raise ValueError("Changed chunk count")
    for a,b in zip(parts,check):
        if a["kind"]!=b["kind"] or (a["kind"] != b"PROP" and a["raw"]!=b["raw"]):
            raise ValueError("Non-PROP binary record was mutated")
    check_paths=parse_headers(check,count)
    for path,(cls,new_source) in replacements.items():
        found,i,record=check_paths[path]
        if found!=cls or record["values"][i]!=new_source:
            raise ValueError("Script changed unexpectedly in round-trip: "+path)
    for i,(a,b) in enumerate(zip(parts,check)):
        if i not in patches and a["raw"]!=b["raw"]:
            raise ValueError("Non-target PROP mutated")
    return output,{"changed_paths":sorted(changes),"changed_script_count":len(changes),
                   "patched_prop_chunk_count":len(patches),
                   "untouched_chunk_count":len(parts)-len(patches),
                   "source_sha256":hashlib.sha256(original).hexdigest(),
                   "candidate_sha256":hashlib.sha256(output).hexdigest(),
                   "all_untouched_chunks_byte_identical":True}


def run(baseline_dir):
    ids=read_identifiers()
    generate(CONFIG_ROOT)
    OUTPUT.mkdir(parents=True,exist_ok=True)
    baseline_dir=Path(baseline_dir)
    manifest_file=baseline_dir/"IMPORT-MANIFEST.json"
    if not manifest_file.is_file():
        raise ValueError("Missing vetted native Work v1.8 baseline manifest. Import the full-baseline package first.")
    manifest=json.loads(manifest_file.read_text("utf-8"))
    if manifest.get("version")!="1.8.0" or not manifest.get("safety",{}).get("contains_production_place_ids"):
        raise ValueError("Unexpected baseline release/provenance")
    entries={Path(i["path"]).name:i for i in manifest["files"]}
    if set(entries)!={f"{p}.rbxl" for p in ROLES}:
        raise ValueError("Baseline manifest must contain exactly four places")
    results={}
    for place in ROLES:
        source=baseline_dir/f"{place}.rbxl"
        if not source.is_file():
            raise ValueError("Missing validated baseline: "+place)
        original=source.read_bytes()
        expected=entries[source.name]
        if hashlib.sha256(original).hexdigest()!=expected["sha256"] or len(original)!=expected["size_bytes"]:
            raise ValueError("Baseline integrity mismatch: "+place)
        replacements=desired_scripts(place)
        built,report=patch_bytes(original,replacements)
        report.update({"place":place,"environment":"staging","expected_replacement_count":len(replacements),
                       "publish_approved":False,"studio_tested":False,
                       "warning":"Binary preservation only; Roblox engine and multiplayer tests not yet performed."})
        results[place]=report
        (OUTPUT/f"{place}.rbxl").write_bytes(built)
        print(f"LOSSLESS SCRIPT PATCH {place}: {len(replacements)} scripts expected, {report['changed_script_count']} changed, {report['untouched_chunk_count']} chunks byte-preserved")
    (OUTPUT/"LOSSLESS-REPORT.json").write_text(json.dumps(results,indent=2)+"\n")
    print("Four staging source-patched candidates created as artifacts only. NO ROBLOX PUBLISH.")


if __name__=="__main__":
    try:
        parser=argparse.ArgumentParser()
        parser.add_argument("--baseline-dir", type=Path, default=ROOT/"games/dead-signal/full-baselines/v1.8.0")
        options=parser.parse_args()
        run(options.baseline_dir)
    except Exception as exc:
        print(f"BLOCKED: {type(exc).__name__}: {exc}",file=sys.stderr)
        sys.exit(1)
