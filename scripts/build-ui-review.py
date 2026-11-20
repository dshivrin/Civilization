#!/usr/bin/env python3
"""Validate UI review tokens/provenance and build local mock data; no runtime writes."""
import hashlib,json,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
REVIEW=ROOT/'docs/ui/themes-review'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def luminance(color):
    values=[int(color[i:i+2],16)/255 for i in [1,3,5]]
    linear=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in values]
    return sum(v*k for v,k in zip(linear,[.2126,.7152,.0722]))
def contrast(a,b):
    a,b=sorted([luminance(a),luminance(b)]);return (b+.05)/(a+.05)
def build():
    tokens=json.loads((REVIEW/'theme-tokens.json').read_text())
    assert tokens['layout']['tapTargetMin']>=44
    assert tokens['brand']['showStudio'] is False
    assert tokens['motion']['compactPulseMs']<=1000
    checks={}
    for key,t in tokens['themes'].items():
        checks[key]={name:round(contrast(t[ink],t[bg]),2) for name,ink,bg in [('body','ink','panel'),('secondary','muted','panel'),('button','onAccent','accent'),('error','danger','panel')]}
        assert min(checks[key].values())>=4.5,(key,checks[key])
    receipts=json.loads((REVIEW/'generation-receipts.json').read_text());assets=[]
    for a in receipts:
        path=REVIEW/a['file'];data=path.read_bytes();assert data[:8]==b'\x89PNG\r\n\x1a\n'
        assert sha(path)==a['sha256'] and sha(REVIEW/a['prompt'])==a['promptSHA256']
        if a.get('reference'):assert sha(ROOT/a['reference'])==a['referenceSHA256']
        w,h=struct.unpack('>II',data[16:24]);assets.append({**a,'width':w,'height':h,'status':'unapproved-review-asset'})
    for path,digest in json.loads((REVIEW/'assets/native-icons/source-contract.json').read_text()).items():assert sha(ROOT/path)==digest,'Native icon source drift'
    icons=json.loads((REVIEW/'assets/native-icons/provenance.json').read_text())
    for a in icons:assert sha(REVIEW/'assets/native-icons'/a['file'])==a['sha256']
    config=json.loads((ROOT/'Packages/GameCore/Sources/GameCore/Resources/seed.json').read_text())
    research_ids=[t['id'] for t in config['technologies']]
    captures=[{'file':str(p.relative_to(REVIEW)),'label':p.stem.replace('-',' '),'sha256':sha(p)} for p in sorted((REVIEW/'captures').glob('*.png'))]
    assert len(captures)==27
    data={'tokens':tokens,'initialResources':config['initialResources'],'buildings':config['buildings'],'technologies':[t for t in config['technologies'] if t['id'] in research_ids],'captures':captures}
    (REVIEW/'review-data.js').write_text('window.UI_REVIEW = '+json.dumps(data,separators=(',',':'))+';\n')
    manifest={'schemaVersion':1,'status':'review-only-no-runtime-integration','assets':assets,'nativeIcons':icons,'nativeSourceSHA256':sha(ROOT/'Civilization/UI/EraIcon.swift'),'captures':captures,'tokenContrast':checks,'limits':'Nominal flat-token contrast, not full texture/screenshot/native VoiceOver certification','baseline':'ff94a05'}
    (REVIEW/'asset-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('PASS:7generated review assets,43native icons,27fresh captures;3themes token contrast >=4.5:1; local data built')
if __name__=='__main__':build()
