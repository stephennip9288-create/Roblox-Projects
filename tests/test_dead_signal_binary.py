"""Unit checks for the independent Roblox binary property preservation gate."""
import struct
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from audit_dead_signal_binary import inventory, compare


def chunk(kind, payload):
    return struct.pack("<4sIII", kind, 0, len(payload), 0) + payload


def sample(props=("Color3uint8",), kind=26, instance_count=1):
    """Minimal records exercising raw RBXL class/PROP metadata parsing."""
    header = b"<roblox!\x89\xff\r\n\x1a\n" + b"\x00\x00"
    header += struct.pack("<II", 1, instance_count) + bytes(8)
    class_name = b"Part"
    inst = struct.pack("<I", 0)
    inst += struct.pack("<I", len(class_name)) + class_name
    inst += b"\x00" + struct.pack("<I", instance_count) + bytes(4 * instance_count)
    data = header + chunk(b"INST", inst)
    for name in props:
        raw = name.encode("utf-8")
        prop = struct.pack("<II", 0, len(raw)) + raw + bytes([kind]) + b"fakevalue"
        data += chunk(b"PROP", prop)
    return data + chunk(b"END\x00", b"")


class BinaryFidelityTests(unittest.TestCase):
    def examine(self, first, second):
        with tempfile.TemporaryDirectory() as directory:
            old = Path(directory) / "before.rbxl"
            new = Path(directory) / "after.rbxl"
            old.write_bytes(first)
            new.write_bytes(second)
            return compare(old, new)

    def test_valid_minimal_rbxl(self):
        with tempfile.TemporaryDirectory() as directory:
            p = Path(directory) / "test.rbxl"
            p.write_bytes(sample())
            data = inventory(p)
            self.assertEqual(data["classes"]["Part"], 1)
            self.assertEqual(data["properties"][("Part", "Color3uint8", 26)], 1)

    def test_identical_property_signatures(self):
        result = self.examine(sample(), sample())
        self.assertTrue(result["passed"])

    def test_missing_property_must_block(self):
        result = self.examine(sample(), sample(props=()))
        self.assertFalse(result["passed"])
        self.assertTrue(any("PROP Part.Color3uint8" in v for v in result["lost_or_changed"]))

    def test_changed_property_type_must_block(self):
        result = self.examine(sample(kind=26), sample(kind=35))
        self.assertFalse(result["passed"])
        self.assertTrue(result["new_property_signatures"])

    def test_reduced_non_script_count_must_block(self):
        result = self.examine(sample(instance_count=2), sample(instance_count=1))
        self.assertFalse(result["passed"])
        self.assertTrue(any("INST Part" in v for v in result["lost_or_changed"]))

    def test_truncated_rbxl_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            p = Path(directory) / "bad.rbxl"
            p.write_bytes(sample()[:-10])
            with self.assertRaises(ValueError):
                inventory(p)


if __name__ == "__main__":
    unittest.main()
