"""Run pinned import validation with tiny synthetic fixtures; no Roblox upload."""
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from zipfile import ZipFile, ZIP_DEFLATED

import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"scripts"))
import import_dead_signal_native_baselines as importer


class ImportTests(unittest.TestCase):
    def make_archive(self, root, corrupt=False):
        files={}
        checks={}
        for name in importer.EXPECTED_SHA256:
            payload=b"<roblox!\x89\xff\r\n\x1a\n"+name.encode()+bytes(40)
            files[str(importer.TARGET/name)]=payload
            checks[name]=hashlib.sha256(payload).hexdigest()
        manifest={"version":"1.8.0","source_kit_sha256":"synthetic-source",
                  "safety":{"contains_production_place_ids":True},
                  "files":[{"path":str(importer.TARGET/name),"sha256":checks[name],
                            "size_bytes":len(files[str(importer.TARGET/name)])}
                           for name in checks]}
        files[str(importer.TARGET/"IMPORT-MANIFEST.json")]=json.dumps(manifest).encode()
        files[str(importer.TARGET/"README.md")]=b"Synthetic test fixture only"
        if corrupt:
            files["unexpected-path"]=b"bad"
        dest=Path(root)/"input.zip"
        with ZipFile(dest,"w",ZIP_DEFLATED) as z:
            for name,value in files.items():
                z.writestr(name,value)
        return dest,checks

    def test_valid_exact_synthetic_archive(self):
        with tempfile.TemporaryDirectory() as d:
            z,checks=self.make_archive(d)
            digest=hashlib.sha256(z.read_bytes()).hexdigest()
            with patch.object(importer,"EXPECTED_ARCHIVE_SHA256",digest), \
                 patch.object(importer,"EXPECTED_UPSTREAM_SHA256","synthetic-source"), \
                 patch.object(importer,"EXPECTED_SHA256",checks):
                paths=importer.extract(z,Path(d))
            self.assertEqual(len(paths),6)
            self.assertTrue(all(x.is_file() for x in paths))

    def test_reject_corrupt_extra_zip_member(self):
        with tempfile.TemporaryDirectory() as d:
            z,checks=self.make_archive(d,corrupt=True)
            digest=hashlib.sha256(z.read_bytes()).hexdigest()
            with patch.object(importer,"EXPECTED_ARCHIVE_SHA256",digest), \
                 patch.object(importer,"EXPECTED_UPSTREAM_SHA256","synthetic-source"), \
                 patch.object(importer,"EXPECTED_SHA256",checks):
                with self.assertRaisesRegex(ValueError,"only the exact"):
                    importer.extract(z,Path(d))
            self.assertFalse((Path(d)/importer.TARGET).exists())

    def test_reject_wrong_archive_hash_without_touching_workspace(self):
        with tempfile.TemporaryDirectory() as d:
            z,_=self.make_archive(d)
            with self.assertRaisesRegex(ValueError,"ZIP hash mismatch"):
                importer.extract(z,Path(d))
            self.assertFalse((Path(d)/importer.TARGET).exists())

    def test_reject_preexisting_baseline(self):
        with tempfile.TemporaryDirectory() as d:
            z,checks=self.make_archive(d)
            dest=Path(d)/importer.TARGET/"dispatch.rbxl"
            dest.parent.mkdir(parents=True)
            dest.write_bytes(b"do not replace")
            digest=hashlib.sha256(z.read_bytes()).hexdigest()
            with patch.object(importer,"EXPECTED_ARCHIVE_SHA256",digest), \
                 patch.object(importer,"EXPECTED_UPSTREAM_SHA256","synthetic-source"), \
                 patch.object(importer,"EXPECTED_SHA256",checks):
                with self.assertRaisesRegex(ValueError,"Refusing overwrite"):
                    importer.extract(z,Path(d))
            self.assertEqual(dest.read_bytes(),b"do not replace")


if __name__=="__main__":
    unittest.main()
