import argparse
import json
import shutil
import subprocess
from pathlib import Path
from common import ROOT, load_manifest, check_place

def prepare(game, place, target, output_dir):
    mode, sources, ids = load_manifest(game, place)
    if target not in ids:
        raise ValueError("Unsupported target")
    source = sources[target]
    output = Path(output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    artifact = output / ("place" + (source.suffix if mode == "file" else ".rbxlx"))
    if mode == "file":
        shutil.copy2(source, artifact)
    else:
        subprocess.run(["rojo", "build", str(source), "-o", str(artifact)], cwd=str(ROOT), check=True)
    size = check_place(artifact)
    meta = dict(ids[target], game=game, place=place, target=target, mode=mode, file_name=artifact.name, byte_count=size)
    (output / "metadata.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
    print(f"Prepared {game}/{place} for {target}: {size:,} bytes")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--game", required=True)
    p.add_argument("--place", required=True)
    p.add_argument("--target", choices=["staging", "production"], required=True)
    p.add_argument("--output-dir", default="build")
    a = p.parse_args()
    prepare(a.game, a.place, a.target, a.output_dir)
