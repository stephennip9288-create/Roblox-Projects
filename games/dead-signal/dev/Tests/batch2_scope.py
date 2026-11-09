"""Use MAIN's frozen combined intake, retaining the original Batch 1 assertions."""
from pathlib import Path
import sys

DEV = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(DEV.parents[2] / 'scripts'))
from dead_signal_batch2_candidate import baseline, manifest


def runtime_baseline(name, data):
    try:
        return baseline(name, data)
    except ValueError as error:
        raise AssertionError(str(error)) from error


def reviewed_paths():
    return {name for name, row in manifest()['records'].items() if row['base_blob'] != row['blob_sha']}
