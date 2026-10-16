"""Synthetic RBXL tests: property-targeted edits must not mutate any other chunk."""
import struct
import sys
import unittest
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"scripts"))
from patch_dead_signal_rbxl import HEADER, patch_bytes, parse_headers, split_binary, encode_string_array, compress_payload, uncompress


def frame(kind,payload):
    return struct.pack("<4sIII",kind,0,len(payload),0)+payload


def refs(items):
    out=[]
    previous=0
    for i in items:
        delta=i-previous
        previous=i
        value=(delta<<1)^(delta>>31)
        out.append(value.to_bytes(4,"big"))
    return b"".join(bytes(x[p] for x in out) for p in range(4))


def inst(class_id,name,ref):
    data=name.encode()
    return frame(b"INST",struct.pack("<II",class_id,len(data))+data+b"\x00"+struct.pack("<I",1)+refs([ref]))


def prop(class_id,name,value):
    encoded=name.encode()
    return frame(b"PROP",struct.pack("<II",class_id,len(encoded))+encoded+b"\x01"+encode_string_array([value.encode()]))


def model(old="print('before')"):
    """A tiny binary world with a complete module hierarchy and opaque region."""
    header=HEADER+b"\x00\x00"+struct.pack("<II",3,3)+b"\x00"*8
    data=header
    data+=inst(0,"ReplicatedStorage",100)
    data+=inst(1,"Folder",101)
    data+=inst(2,"ModuleScript",102)
    data+=prop(0,"Name","ReplicatedStorage")
    data+=prop(1,"Name","DeadSignal")
    data+=prop(2,"Name","MyModule")
    data+=prop(2,"Source",old)
    data+=frame(b"TERR",b"opaque TERRAIN protected bytes")
    data+=frame(b"PRNT",b"\x00"+struct.pack("<I",3)+refs([100,101,102])+refs([-1,100,101]))
    data+=frame(b"END\x00",b"</roblox>")
    return data


class PatchTests(unittest.TestCase):
    def test_only_source_prop_chunk_mutates(self):
        original=model()
        newer, report=patch_bytes(original,{"ReplicatedStorage/DeadSignal/MyModule":("ModuleScript",b"return { value = 42 }")})
        self.assertEqual(report["changed_script_count"],1)
        before=split_binary(original)
        after=split_binary(newer)
        self.assertEqual(len(before),len(after))
        self.assertEqual(sum(1 for x,y in zip(before,after) if x["raw"]!=y["raw"]),1)
        self.assertEqual(before[-3]["raw"],after[-3]["raw"])
        self.assertIn(b"opaque TERRAIN protected bytes",newer)

    def test_unknown_target_fails_closed(self):
        with self.assertRaisesRegex(ValueError,"Missing script targets"):
            patch_bytes(model(),{"ReplicatedStorage/DeadSignal/Unknown":("ModuleScript",b"return 1")})

    def test_wrong_class_fails_closed(self):
        with self.assertRaisesRegex(ValueError,"Class mismatch"):
            patch_bytes(model(),{"ReplicatedStorage/DeadSignal/MyModule":("Script",b"return 1")})

    def test_no_op_change_fails_closed(self):
        with self.assertRaisesRegex(ValueError,"No runtime changes"):
            patch_bytes(model(),{"ReplicatedStorage/DeadSignal/MyModule":("ModuleScript",b"print('before')")})

    def test_invalid_binary_rejected(self):
        with self.assertRaises(ValueError):
            split_binary(b"<roblox!" + bytes(60))

    def test_compressed_source_chunk_roundtrip(self):
        payload=b"print('updated')"*100
        for codec in ("lz4","zstd"):
            compressed,_=compress_payload(codec,payload)
            self.assertEqual(uncompress(compressed,len(payload)),payload)


if __name__=="__main__":
    unittest.main()
