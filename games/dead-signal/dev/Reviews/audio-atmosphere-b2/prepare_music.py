"""Original algorithmic musical textures; no third-party samples or runtime synthesis.

Generates owner-review WAVs/OGGs and metadata only. Never uploads, activates,
edits Config or claims native listening/Roblox permission acceptance.
Requires Python standard library plus ffmpeg. Reproduce PCM deterministically.
"""
import argparse
import array
import csv
import hashlib
import json
import math
from pathlib import Path
import random
import subprocess
import sys
import wave

RATE=48000
TRACKS=[
    ('blackwater_calm','Music.Station.Calm',55,[0,7,10],1),
    ('blackwater_pressure','Music.Station.Pressure',55,[0,1,7],8),
    ('cinderworks_calm','Music.Foundry.Calm',46.25,[0,6,12],2),
    ('cinderworks_pressure','Music.Foundry.Pressure',46.25,[0,1,6,12],16),
    ('whiteout_calm','Music.Frost.Calm',65.406,[0,7,19],1),
    ('whiteout_pressure','Music.Frost.Pressure',65.406,[0,1,19],4),
    ('dispatch_calm','Music.Lobby.Calm',130.812,[0,7,16],1),
    ('warden_pressure','Music.Warden',41.203,[0,1,6,12],8),
    ('extraction_pressure','Music.Extraction',73.416,[0,7,13,19],24),
    ('rare_score_stinger','Atmosphere.Stinger',110,[0,1,6,13],2),
]


def pcm_for(track,index):
    name,key,root,notes,pulses=track
    seconds=3 if key=='Atmosphere.Stinger' else 32
    frames=RATE*seconds;randomizer=random.Random(620205+index)
    tones=[]
    for note in notes:
        for harmonic,gain in [(1,1),(2,.30),(4,.12),(8,.05)]:
            frequency=round(root*2**(note/12)*harmonic*seconds)/seconds
            tones.append((2*math.pi*frequency/RATE,randomizer.random()*2*math.pi,gain/len(notes)))
    data=array.array('f')
    for n in range(frames):
        u=n/frames
        value=sum(gain*math.sin(step*n+phase) for step,phase,gain in tones)
        envelope=.65+.17*math.sin(2*math.pi*u)+.12*math.cos(2*math.pi*pulses*u)
        if key=='Atmosphere.Stinger':
            t=n/RATE;envelope*=min(1,t/.16)*math.exp(-t*2.2)*min(1,(seconds-t)/.18)
        data.append(value*envelope)
    scale=.22/max(max(abs(x) for x in data),1e-9)
    pcm=array.array('h',(round(max(-.99,min(.99,x*scale))*32767) for x in data))
    if sys.byteorder!='little':pcm.byteswap()
    return pcm.tobytes(),seconds


def prepare(output):
    output=Path(output);(output/'WAV').mkdir(parents=True,exist_ok=True);(output/'Audio').mkdir(exist_ok=True)
    rows=[]
    for index,track in enumerate(TRACKS):
        name,key,*_=track;raw,seconds=pcm_for(track,index);wav=output/'WAV'/(name+'.wav');ogg=output/'Audio'/(name+'.ogg')
        with wave.open(str(wav),'wb') as f:
            f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(raw)
        subprocess.run(['ffmpeg','-v','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','5',str(ogg)],check=True)
        decoded=subprocess.check_output(['ffmpeg','-v','error','-i',str(ogg),'-af','aresample=192000','-f','f32le','-'])
        peak=array.array('f',decoded)
        if sys.byteorder!='little':peak.byteswap()
        highest=max(abs(x) for x in peak);assert highest<.35
        values=array.array('h',raw)
        if sys.byteorder!='little':values.byteswap()
        rows.append({'name':name,'event':key,'kind':'original synthesized musical composition, not a physical recording',
                     'seconds':seconds,'loop':key!='Atmosphere.Stinger','channels':1,'sample_rate':RATE,'pcm_bits':16,
                     'wav_sha256':hashlib.sha256(wav.read_bytes()).hexdigest(),'ogg_sha256':hashlib.sha256(ogg.read_bytes()).hexdigest(),
                     'pcm_sha256':hashlib.sha256(raw).hexdigest(),'wav_bytes':wav.stat().st_size,'ogg_bytes':ogg.stat().st_size,
                     'decoded_true_peak_dbfs_4x':round(20*math.log10(highest),4),'clipped_pcm_samples':sum(abs(x)>=32767 for x in values),
                     'pcm_seam_delta':abs(values[-1]-values[0])/32768,'roblox_asset_id':None,
                     'rightsCleared':False,'creatorReviewed':False,'listeningApproved':False,'robloxApproved':False,
                     'permissions':{'10771141095':False,'10770732078':False},'activated':False})
        print('Prepared',name,flush=True)
    report={'scope':'Issue62 B2-02/05/07 music audition package','source':'original deterministic additive synthesis; no external audio inputs',
            'license_status':'Owner creator/rights review required; not a third-party sample pack','native_listening':False,'uploaded':False,'recordings':rows}
    (output/'MUSIC-RECORDINGS.json').write_text(json.dumps(report,indent=2)+'\n')
    with (output/'UPLOAD-RETURN.csv').open('w',newline='',encoding='utf-8-sig') as f:
        w=csv.writer(f);w.writerow(['filename','event','roblox_asset_id','rightsCleared','creatorReviewed','listeningApproved','robloxApproved','stagingAccess','productionAccess','notes'])
        for row in rows:w.writerow([row['name']+'.ogg',row['event'],'','false','false','false','false','false','false',''])
    return report


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();prepare(args.output)
