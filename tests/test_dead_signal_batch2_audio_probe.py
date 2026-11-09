"""Synthetic report validation only, never native/audio acceptance evidence."""
from copy import deepcopy
import importlib
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts'))
probe = importlib.import_module('check_dead_signal_batch2_audio_probe')


def fixture():
    rows = []
    for event, (asset_id, seconds) in probe.expected().items():
        rows.append({'event': event, 'assetId': asset_id, 'expectedSeconds': seconds,
            'tested': True, 'preloadCompleted': True, 'isLoaded': True, 'fetchStatus': 'Success',
            'timeLengthSeconds': seconds, 'durationWithinTolerance': True, 'nativeLoadEligible': True,
            'playCallSucceeded': True, 'playbackAdvanced': True, 'observedTimePosition': min(.5, seconds/2),
            'callbackStatuses': [{'contentId': 'rbxassetid://'+asset_id, 'status': 'Success'}]})
    return {'schema': 1, 'kind': 'dead-signal-b2-native-audio-probe', 'probeVersion': '1',
        'studio': True, 'client': True, 'universeId': 10771141095, 'placeId': 117710269155815,
        'placeVersion': 20, 'startedAtUTC': '2026-11-09T00:00:00Z', 'capturedAtUTC': '2026-11-09T00:01:00Z',
        'probeRunning': False, 'ownerNativeIntendedClipsConfirmed': True,
        'existingSourceListeningApprovalRetained': True, 'moderationVerifiedByThisProbe': False,
        'gameplayQualityAccepted': False, 'productionAuthorized': False,
        'testedCount': 16, 'nativeLoadEligibleCount': 16, 'playbackAdvancedCount': 16,
        'allSixteenNativeEligible': True, 'records': rows}


class AudioProbe(unittest.TestCase):
    def test_all_sixteen_can_validate_without_claiming_real_execution_or_authority(self):
        result = probe.validate(fixture())
        self.assertEqual(result['validated_asset_count'], 16)
        self.assertFalse(result['actual_native_execution_independently_established'])
        self.assertFalse(result['publication_authorized'])

    def test_wrong_context_overclaim_and_unconfirmed_native_identity_rejected(self):
        changes = {'studio': False, 'client': False, 'universeId': 10770732078, 'placeId': 0,
            'placeVersion': -1, 'probeRunning': True, 'ownerNativeIntendedClipsConfirmed': False,
            'moderationVerifiedByThisProbe': True, 'gameplayQualityAccepted': True,
            'productionAuthorized': True, 'playbackAdvancedCount': 15}
        for key, value in changes.items():
            with self.subTest(field=key), self.assertRaises(ValueError):
                probe.validate({**fixture(), key: value})

    def test_client_zero_version_is_preserved_without_attesting_server_or_game_source(self):
        report = {**fixture(), 'placeVersion': 0}
        result = probe.validate(report)
        self.assertFalse(result['server_place_version_attested'])
        self.assertFalse(result['game_source_attested'])
        self.assertEqual(report['placeVersion'], 0)
        for value in (None, True, 0.0, '20', -1):
            with self.subTest(version=value), self.assertRaises(ValueError):
                probe.validate({**fixture(), 'placeVersion': value})
        for key, value in (('universeId', 10770732078), ('placeId', 0), ('client', False)):
            with self.subTest(field=key), self.assertRaises(ValueError):
                probe.validate({**report, key: value})

    def test_each_asset_identity_failure_timeout_or_nonfinite_observation_rejected(self):
        changes = {'assetId': '1', 'fetchStatus': 'ProbeTimedOut', 'isLoaded': False,
            'nativeLoadEligible': False, 'playbackAdvanced': False, 'timeLengthSeconds': float('nan'),
            'observedTimePosition': float('inf'), 'callbackStatuses': []}
        for index in range(16):
            for key, value in changes.items():
                row = deepcopy(fixture());row['records'][index][key] = value
                with self.subTest(asset=index, field=key), self.assertRaises(ValueError):
                    probe.validate(row)
            row = deepcopy(fixture())
            row['records'][index]['callbackStatuses'] = [{'contentId': 'rbxassetid://1', 'status': 'Success'}]
            with self.subTest(asset=index, wrong_callback_id=True), self.assertRaises(ValueError):
                probe.validate(row)

    def test_duplicate_or_missing_event_rejected(self):
        row = fixture();row['records'][0] = row['records'][1]
        with self.assertRaises(ValueError):probe.validate(row)
        row = fixture();row['records'].pop()
        with self.assertRaises(ValueError):probe.validate(row)

    def test_pasteable_tool_uses_the_exact_independently_reviewed_sixteen_ids(self):
        source = (ROOT/'games/dead-signal/dev/Tools/probe-batch2-audio-studio.lua').read_text()
        rows = re.findall(r"\{'([^']+)','(\d+)',([\d.]+)\}", source)
        self.assertEqual(len(rows), 16)
        self.assertEqual({event: asset for event, asset, _ in rows},
                         {event: asset for event, (asset, _) in probe.expected().items()})
        for event, _, seconds in rows:
            self.assertAlmostEqual(float(seconds), probe.expected()[event][1], places=6)


if __name__ == '__main__':unittest.main()
