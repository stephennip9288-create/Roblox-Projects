"""Rehost exact currently recorded live-production recovery bytes; never publish."""
import json,os,shutil
from pathlib import Path
import dead_signal_release_guard as guard

EXPECTED_SOURCE='1a5b9f3b811137b6881090ad634a13624d33dd71'
EXPECTED_ARTIFACT=12081841244
EXPECTED_ARCHIVE='e0b7d00fb64641afa33cbd68fb34b8282c92079adf811b6661897d82785c7910'

def refresh():
    old=guard.recovery_record('production')
    if (old['source_sha']!=EXPECTED_SOURCE or old['artifact']['id']!=EXPECTED_ARTIFACT
            or old['artifact']['sha256']!=EXPECTED_ARCHIVE):
        raise ValueError('Current production recovery changed; review the new live source before refreshing')
    guard.download_recovery('production',os.getenv('GH_TOKEN',''),'deploy')
    verified=guard.verify_recovery('production')
    output=guard.ROOT/'build/dead-signal-production-recovery-refresh'
    (output/'production').mkdir(parents=True,exist_ok=True)
    for place,row in verified.items():
        source=guard.ROOT/row['path'];data=source.read_bytes();spec=old['places'][place]
        if len(data)!=spec['bytes'] or guard.digest(data)!=spec['sha256']:
            raise ValueError('Production recovery changed before preservation: '+place)
        shutil.copyfile(source,output/'production'/f'{place}.rbxl')
    report={'schema':1,'environment':'production','kind':'exact-existing-recovery-preservation',
        'original_recovery_record':old,'refresh_workflow_run':os.getenv('GITHUB_RUN_ID'),
        'refresh_head_sha':os.getenv('GITHUB_SHA'),'recreated_or_rebuilt':False,
        'production_touched':False,'roblox_requests':False,'all_four_bytes_unchanged':True}
    (output/'PRESERVATION.json').write_text(json.dumps(report,indent=2)+chr(10))
    print('Preserved exact four current production rollback files; no Roblox requests or publishing')

if __name__=='__main__':refresh()
