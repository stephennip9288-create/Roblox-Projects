"""Strict additive audio-lane scope for owner-approved Issue62; historical ledgers stay immutable."""
import hashlib
import json
from pathlib import Path

DEV=Path(__file__).resolve().parents[1]
REVIEW=DEV/'Reviews/audio-atmosphere-b2'
LEDGER='15d04e68587523b90410d6d2b324af542cd5a3fe'
POLICY='bdcdd11095a9c663e113560c4fee4b43b05dfb09'
PINNED={'Source/Runtime/client/Effects.lua':('Effects-before.txt','eba3364383e7bef7fc7fbe831287b257bdd0d43a'),
        'Source/Runtime/client/Controller.lua':('Controller-before.txt','8302f9416ed2f0025b3aeed4c78c794020b42af5'),
        'Source/Runtime/shared/Config.lua':('Config-before.txt','8a314e4cec13a3d1f3e231628be203c36a493412')}

def blob(data):return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()

def runtime_baseline(name,data):
    if (DEV/'Reviews/batch2-integration/REVIEWED-RUNTIME.json').is_file():
        from batch2_scope import runtime_baseline as combined_baseline
        return combined_baseline(name,data)
    if name not in PINNED:return data
    filename,sha=PINNED[name];base=(REVIEW/filename).read_bytes()
    assert blob(base)==sha,'Pinned Batch1 source changed: '+name
    ledger=(REVIEW/'BASELINE-RUNTIME.json').read_bytes()
    assert blob(ledger)==LEDGER and json.loads(ledger)[name]==sha,'Pinned main7aaf runtime inventory changed'
    if data==base:return base
    if name.endswith('/Config.lua'):
        block=(REVIEW/'CONFIG-POLICY.luau.txt').read_bytes()
        assert blob(block)==POLICY and data.count(block)==1,'Exact additive audio policy required'
        assert data.replace(block,b'',1)==base,'Existing approved Config/banks changed'
    elif name.endswith('/Effects.lua'):
        start,end=b'-- AUDIO-ONLY INLINE IMPLEMENTATION.',b'function FX:part('
        assert data[:data.index(start)]==base[:base.index(start)],'Effects preamble changed'
        assert data[data.index(end):]==base[base.index(end):],'Effects VFX changed'
        for forbidden in [b'FireServer',b'InvokeServer',b'DataStore',b'LoadAsset',b'InsertService']:
            assert forbidden not in data[data.index(start):data.index(end)],'Audio authority violation'
    else:
        start,end=b'function Controller.audioBindings(',b'function Controller.start('
        assert data[:data.index(start)]==base[:base.index(start)],'Controller preamble changed'
        tail=data[data.index(end):]
        old=b'if audioBindings then audioBindings:set(s.state,true) end'
        new=b'if audioBindings then audioBindings:results(s.state) end'
        assert tail.count(new)==1,'Only the existing Results audio call may change outside binding'
        assert tail.replace(new,old,1)==base[base.index(end):],'Non-audio Controller code changed'
        body=data[data.index(start):data.index(end)]
        assert b'FireServer' not in body and b'SetAttribute(' not in body,'Audio cannot invent detection or gameplay state'
    return base

def config_before(data):return runtime_baseline('Source/Runtime/shared/Config.lua',data)
