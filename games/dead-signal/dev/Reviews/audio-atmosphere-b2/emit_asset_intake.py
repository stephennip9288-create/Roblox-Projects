"""Print reviewed new-bank assignments; never modify source or perform upload."""
import argparse
import csv
import json
from pathlib import Path
import re

ALLOWED={'Music.'+m+'.'+r for m in ['Station','Foundry','Frost'] for r in ['Calm','Pressure']}
ALLOWED.update(['Music.Lobby.Calm','Music.Warden','Music.Extraction','Atmosphere.Stinger','Atmosphere.Station.Creak',
                'Atmosphere.Foundry.Steam','Atmosphere.Foundry.Impact','Atmosphere.Cry','Zombie.Breath','Zombie.Drag'])


def proposal(rows,universe):
    if str(universe) not in ['10771141095','10770732078']:raise ValueError('Unknown target universe')
    result=[];seen=set();seen_ids=set()
    for row in rows:
        key=row['event'];id=str(row.get('roblox_asset_id') or '')
        if key not in ALLOWED or key in seen:raise ValueError('Unknown/duplicate event '+key)
        seen.add(key)
        flags=['rightsCleared','creatorReviewed','listeningApproved','robloxApproved']
        if (not re.fullmatch(r'[0-9]{1,20}',id) or int(id)<1 or id in seen_ids or not all(row.get(k) is True for k in flags)
            or row.get('permissions',{}).get(str(universe)) is not True):
            raise ValueError('Unapproved/missing-ID/permission entry: '+key)
        seen_ids.add(id)
        value={'id':'rbxassetid://'+id,**{k:True for k in flags},'permissions':{str(universe):True},'gain':1}
        # Emit JSON for MAIN intake. No automatic source rewrite or deployment.
        result.append({'event':key,'bank':value})
    return result


def read_rows(path):
    path=Path(path)
    if path.suffix.lower()!='.csv':
        return json.loads(path.read_text())['recordings']
    with path.open(newline='',encoding='utf-8-sig') as stream:
        rows=[]
        for row in csv.DictReader(stream):
            for flag in ['rightsCleared','creatorReviewed','listeningApproved','robloxApproved']:
                row[flag]=row.get(flag,'').strip().lower()=='true'
            row['permissions']={'10771141095':row.get('stagingAccess','').strip().lower()=='true',
                                '10770732078':row.get('productionAccess','').strip().lower()=='true'}
            row['roblox_asset_id']=row.get('roblox_asset_id','').strip()
            rows.append(row)
        return rows


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('manifest',type=Path);p.add_argument('--universe',required=True)
    a=p.parse_args();print(json.dumps(proposal(read_rows(a.manifest),a.universe),indent=2))
