"""Validate an owner-supplied Studio audio report; never activate or publish.

Schema validation is not independent proof that a report ran in Roblox. MAIN
must review the actual owner-provided Output/native evidence and source-identity
attestation before pinning it into any future audio-active staging admission.
"""
import argparse
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT/'games/dead-signal/dev/Reviews/batch2-integration'
STAGING_PLACES = {117710269155815, 102403661108879, 125712056058975, 122269451559483}


def expected(root=ROOT):
    review = Path(root)/REVIEW.relative_to(ROOT)
    intake = json.loads((review/'AUDIO-INTAKE.json').read_text())['recordings']
    content = {r['roblox_asset_id']: r for r in json.loads(
        (review/'HOSTED-CONTENT-COMPARISON.json').read_text())['recordings']}
    physical = {r['filename'].removesuffix('.wav'): r['duration_seconds'] for r in json.loads(
        (review/'AUDIO-SOURCE-REVIEW.json').read_text())['physical_recordings']}
    return {r['event']: (r['roblox_asset_id'], physical.get(r['name'],
                           content[r['roblox_asset_id']]['source_frames_48000']/48000))
            for r in intake}


def number(value):
    return type(value) in (int, float) and math.isfinite(value)


def validate(report, root=ROOT):
    if (report.get('schema') != 1 or report.get('kind') != 'dead-signal-b2-native-audio-probe'
            or report.get('probeVersion') != '1' or report.get('studio') is not True
            or report.get('client') is not True or report.get('universeId') != 10771141095
            or report.get('placeId') not in STAGING_PLACES
            # PlaceVersion is NotReplicated server metadata. This CLIENT-only
            # probe can report 0; never substitute the live server version or
            # treat this field as attesting the installed game source.
            or type(report.get('placeVersion')) is not int or report['placeVersion'] < 0
            or report.get('probeRunning') is not False
            or not report.get('startedAtUTC') or not report.get('capturedAtUTC')
            or report.get('probeError')):
        raise ValueError('Incomplete Studio-client/private-staging context or active/erroring probe')
    if (report.get('ownerNativeIntendedClipsConfirmed') is not True
            or report.get('existingSourceListeningApprovalRetained') is not True
            or report.get('moderationVerifiedByThisProbe') is not False
            or report.get('gameplayQualityAccepted') is not False
            or report.get('productionAuthorized') is not False):
        raise ValueError('Native intended-clip attestation missing or probe overstates moderation/gameplay/production')
    for key in ('testedCount', 'nativeLoadEligibleCount', 'playbackAdvancedCount'):
        if report.get(key) != 16:
            raise ValueError('All sixteen native asset checks must complete: '+key)
    if report.get('allSixteenNativeEligible') is not True:
        raise ValueError('All sixteen native checks must pass')
    rows = report.get('records', [])
    if len(rows) != 16 or len({r.get('event') for r in rows}) != 16:
        raise ValueError('Exactly sixteen unique events required')
    expected_rows = expected(root)
    if {r.get('event') for r in rows} != set(expected_rows):
        raise ValueError('Native report differs from the exact reviewed event inventory')
    for row in rows:
        event = row['event']
        asset_id, seconds = expected_rows[event]
        duration = row.get('timeLengthSeconds')
        at = row.get('observedTimePosition')
        if (row.get('assetId') != asset_id or row.get('fetchStatus') != 'Success'
                or any(row.get(k) is not True for k in ('tested', 'preloadCompleted', 'isLoaded',
                    'durationWithinTolerance', 'nativeLoadEligible', 'playCallSucceeded', 'playbackAdvanced'))
                or not number(row.get('expectedSeconds')) or abs(row['expectedSeconds']-seconds) > 1e-6
                or not number(duration) or duration <= 0 or abs(duration-seconds) > max(.1, seconds*.03)
                or not number(at) or not .05 < at <= duration+.1
                or row.get('preloadError') or row.get('playError')):
            raise ValueError('Native loading/playback evidence failed or wrong ID/duration: '+event)
        callbacks = row.get('callbackStatuses', [])
        if (not callbacks or callbacks[-1].get('status') != 'Success'
                or callbacks[-1].get('contentId') != 'rbxassetid://'+asset_id):
            raise ValueError('No successful actual ContentProvider callback: '+event)
    return {'validated_asset_count': 16, 'shape_validated': True,
            'server_place_version_attested': False,
            'game_source_attested': False,
            'actual_native_execution_independently_established': False,
            'requires_main_review_of_owner_evidence': True,
            'runtime_changed': False, 'publication_authorized': False}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', required=True, type=Path)
    args = parser.parse_args()
    text = args.report.read_text().strip()
    prefix = 'DEAD_SIGNAL_B2_AUDIO_PROBE '
    if text.startswith(prefix):
        text = text[len(prefix):]
    print(json.dumps(validate(json.loads(text)), indent=2))
