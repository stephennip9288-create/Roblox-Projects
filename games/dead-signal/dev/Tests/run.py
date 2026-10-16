"""Run from anywhere: python Tests/run.py --lune /absolute/path/to/lune [--luau-compile PATH]."""
from pathlib import Path
import argparse, json, re, shutil, subprocess, time
root=Path(__file__).resolve().parent.parent
parser=argparse.ArgumentParser()
parser.add_argument('--lune',default='lune')
parser.add_argument('--luau-compile')
args=parser.parse_args()
def binary(value):
    return str(Path(shutil.which(value) or value).resolve())
lune=binary(args.lune)
results=[]
for name in ['evolution','events','presentation','director','server','navigation','pursuit','rigs','weapons','arrival','extraction']:
    started=time.monotonic()
    run=subprocess.run([lune,'run',f'Tests/{name}.luau'],cwd=root,capture_output=True,text=True)
    print(run.stdout,end='')
    if run.stderr:print(run.stderr,end='')
    counts=re.findall(r'(?:passed:|assertions:)\s*(\d+)',run.stdout)
    results.append({'suite':name,'passed':run.returncode==0,'assertions':int(counts[-1]) if counts else None,'seconds':round(time.monotonic()-started,3),'output':run.stdout,'errors':run.stderr})
compile_result={'run':False}
if args.luau_compile:
    compiler=binary(args.luau_compile);errors=[];files=sorted((root/'Source/Runtime').rglob('*.lua'))
    for file in files:
        run=subprocess.run([compiler,'--binary',str(file)],capture_output=True)
        if run.returncode:errors.append({'file':str(file.relative_to(root)),'error':run.stderr.decode()})
    compile_result={'run':True,'scripts':len(files),'passed':not errors,'errors':errors}
    print('Runtime scripts compiled:',len(files),'errors:',len(errors))
report={'suites':results,'unit_assertions':sum(x['assertions'] or 0 for x in results),'compile':compile_result,'roblox_engine_playtest':False,'physical_phone_playtest':False,'published_multiplayer_playtest':False,'asset_permissions_verified':False,'mobile_testing_deferred':True}
(root/'Validation').mkdir(exist_ok=True)
(root/'Validation/Tests-Report.json').write_text(json.dumps(report,indent=2))
assert all(x['passed'] for x in results) and compile_result.get('passed',True),'Offline validation failed'
print('All offline suites passed. Assertions:',report['unit_assertions'])
