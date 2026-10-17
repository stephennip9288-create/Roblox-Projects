"""Enemy lane follow-up suites; leaves the integrator-owned run.py unchanged.

Run after the standard offline fixture setup documented in Tests/README.md:
python Tests/run-infected.py --lune /absolute/path/to/lune
"""
from pathlib import Path
import argparse
import json
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--lune', default='lune')
args = parser.parse_args()
lune = str(Path(shutil.which(args.lune) or args.lune).resolve())
results = []
for name in ('infected-batch1', 'infected-entrances', 'infected-geometry'):
    started = time.monotonic()
    run = subprocess.run([lune, 'run', f'Tests/{name}.luau'], cwd=ROOT,
                         capture_output=True, text=True)
    print(run.stdout, end='', flush=True)
    print(run.stderr, end='', flush=True)
    counts = re.findall(r'assertions passed:\s*(\d+)', run.stdout)
    results.append({'suite': name, 'passed': run.returncode == 0,
                    'assertions': int(counts[-1]) if counts else 0,
                    'seconds': round(time.monotonic() - started, 3),
                    'output': run.stdout, 'errors': run.stderr})
report = {'suites': results, 'assertions': sum(x['assertions'] for x in results),
          'roblox_engine_playtest': False, 'multiplayer_playtest': False,
          'physical_phone_playtest': False, 'asset_permissions_verified': False}
output = ROOT / 'Validation/InfectedBatch1'
output.mkdir(parents=True, exist_ok=True)
(output / 'Tests-Report.json').write_text(json.dumps(report, indent=2) + '\n')
if not all(x['passed'] for x in results):
    raise SystemExit('Enemy Batch 1 offline validation failed')
print('All enemy Batch 1 suites passed. Assertions:', report['assertions'])
