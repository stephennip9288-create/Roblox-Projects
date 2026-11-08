"""Package exact reviewed-source candidates; verify masters before creating a ZIP."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

ROOT=Path(__file__).resolve().parent


def package(masters,output):
    rows=json.loads((ROOT/'MUSIC-RECORDINGS.json').read_text())['recordings']
    files=[]
    for row in rows:
        for folder,directory,field in [('Audio',ROOT/'Audio','ogg_sha256'),('WAV',Path(masters),'wav_sha256')]:
            ext='.ogg' if folder=='Audio' else '.wav';path=directory/(row['name']+ext)
            if hashlib.sha256(path.read_bytes()).hexdigest()!=row[field]:raise ValueError('Unexpected candidate bytes: '+str(path))
            files.append((path,folder+'/'+path.name))
    names=['UPLOAD-INSTRUCTIONS.md','UPLOAD-RETURN.csv','RECORDING-REQUESTS.csv','RIGHTS-AND-PROVENANCE.md',
           'MUSIC-RECORDINGS.json','CODEC-QA.json','LISTEN.html','NATIVE-LISTENING.md','prepare_music.py','emit_asset_intake.py']
    files.extend((ROOT/name,name) for name in names);files.append((ROOT/'OWNER-README.md','README.md'))
    output=Path(output);output.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(output,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for path,name in files:
            info=zipfile.ZipInfo(name,date_time=(2026,11,8,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED
            info.external_attr=0o644<<16;archive.writestr(info,path.read_bytes())
    with zipfile.ZipFile(output) as archive:assert archive.testzip() is None
    return {'file':str(output.resolve()),'files':len(files),'bytes':output.stat().st_size,
            'sha256':hashlib.sha256(output.read_bytes()).hexdigest()}


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--masters',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True);args=parser.parse_args()
    print(json.dumps(package(args.masters,args.output),indent=2))
