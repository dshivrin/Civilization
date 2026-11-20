#!/usr/bin/env python3
"""Build Gate 2 review data from preserved imagegen outputs and actual-map fixtures."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / 'docs/art/building-gate-2'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def crossing(rows, fixture):
    """Terrain-only straight visual spans. No placement/pathfinding rule is introduced."""
    options = []
    for edge in fixture['bankEdges']:
        water, land = edge['water'], edge['land']
        dx, dy = water[0]-land[0], water[1]-land[1]
        x, y = water
        count = 0
        while 0 <= y < len(rows) and 0 <= x < len(rows[0]) and rows[y][x] == 'w':
            count += 1
            x, y = x+dx, y+dy
        if count and count <= 8 and 0 <= y < len(rows) and 0 <= x < len(rows[0]) and rows[y][x] in '.c':
            axis = 'x' if dx else 'y'
            ends = sorted([land, [x,y]], key=lambda t: t[0] if dx else t[1])
            options.append({'axis':axis, 'landEnds':ends, 'waterTiles':count, 'lengthInTiles':count+1})
    if not options:
        raise ValueError('No bounded straight visual crossing: '+fixture['id'])
    return sorted(options, key=lambda x: (abs(x['waterTiles']-2),x['landEnds']))[0]


def build():
    config_path = ROOT / 'Packages/GameCore/Sources/GameCore/Resources/seed.json'
    config = json.loads(config_path.read_text())
    fixtures = json.loads((ROOT/'docs/art/building-gate-1/evidence/river-fixtures.json').read_text())
    assert fixtures['configSHA256'] == digest(config_path), 'Map changed: regenerate/reconcile Gate 1 fixtures'
    measured = [json.loads(line) for line in (REVIEW/'measurements.jsonl').read_text().splitlines() if line]
    receipts = {r['id']:r for r in json.loads((REVIEW/'generation-receipts.json').read_text())}
    assets = {}
    for m in measured:
        path = ROOT / m['file']
        key = path.stem
        assert key not in assets and key in receipts
        assert digest(path) == m['sha256'] == receipts[key]['outputSHA256'] and m['transparentFraction'] > .1 and m['coveredEdgePixels'] == 0, key
        x0,y0,x1,y1 = m['silhouetteBoundsTopLeftInclusive']
        scale = 116/(x1-x0+1)
        reference = receipts[key].get('reference')
        assert digest(REVIEW/'prompts'/f'{key}.txt') == receipts[key]['promptSHA256'], 'Prompt drift: '+key
        assert (digest(ROOT/reference) if reference else None) == receipts[key]['referenceSHA256'], 'Reference drift: '+key
        assets[key] = {'id':key,'file':'assets/'+path.name,'measurements':m,
            'prompt':'prompts/'+key+'.txt','promptSHA256':digest(REVIEW/'prompts'/f'{key}.txt'),
            'sourceGeneratedFile':Path(receipts[key]['sourcePath']).name,'reference':reference,
            'referenceSHA256':digest(ROOT/reference) if reference else None,
            'logicalFootprint':None if key.startswith('bridge') else [2,2],
            'proposedImageRect':[-(x0+x1+1)/2*scale, -(y1+1)*scale+16, m['width']*scale, m['height']*scale],
            'status':'unapproved-review-concept','contactStatus':'semantic mask absent; scale/anchor proposal only',
            'tool':'built-in image_gen','runtimeIntegrated':False}
    assert len(assets)==len(receipts)==13
    # Explicit hand-estimated deck endpoints, normalized to source raster. Never warp art to hide error.
    assets['bridge-x']['deckEndpointsNormalized']=[[.09,.23],[.91,.87]]
    assets['bridge-y']['deckEndpointsNormalized']=[[.91,.20],[.08,.90]]
    original = json.loads((ROOT/'docs/art/building-gate-1/evidence/inventory.json').read_text())
    originals = {x['id']:x for x in original['buildings']}
    for item in originals.values():
        assert digest(ROOT/'Civilization/Art'/item['art']['file']) == item['sprite']['sha256'], 'Shipped original drift: '+item['id']
    for fixture in fixtures['fixtures']:
        fixture['visualCrossing'] = crossing(config['map']['rows'],fixture)
        sides=sorted({('+' if e['water'][0]-e['land'][0]>0 else '-')+'X' if e['water'][0]!=e['land'][0] else ('+' if e['water'][1]-e['land'][1]>0 else '-')+'Y' for e in fixture['bankEdges']})
        fixture['fishingPoseStudy']={}
        for pose in ['1','2','3','opposite']:
            nominal='-X' if pose=='opposite' else '+X'
            if len(sides)>1:
                status,label='edge-choice-required','Orientation study — bend needs an explicit edge and more views'
            elif sides[0].endswith('Y'):
                status,label='unsupported-quarter-turn','Orientation study — no authored quarter-turn view for this bank'
            elif sides[0]!=nominal:
                status,label='unsupported-facing','Orientation study — selected view faces the wrong nominal side'
            else:
                status,label='uncertified-nominal-match','Orientation study — nominal side matches; contact/facing uncertified'
            fixture['fishingPoseStudy'][pose]={'status':status,'label':label,'waterwardSides':sides,'nominalView':nominal+' proposal (hand-assigned, no authored socket)'}
        fixture['status']='visual fixture only; not gameplay placement, traversability or geometry acceptance'
    data = {'schemaVersion':1,'status':'Gate2 review only; no accepted geometry or runtime export',
        'configSHA256':digest(config_path),'gameBaseline':'8e1c6fc','assets':assets,'originals':originals,
        'map':config['map'],'fixtures':fixtures['fixtures'],'r2_07':'disabled','mediaPromotion':'not performed; original media repository read-only'}
    (REVIEW/'manifest.json').write_text(json.dumps(data,indent=2)+'\n')
    (REVIEW/'gallery-data.js').write_text('window.GATE2 = '+json.dumps(data,separators=(',',':'))+';\n')
    print(f'PASS: {len(assets)} alpha/hash/prompt-verified assets; {len(fixtures["fixtures"])} real river crossings; review-only manifest/gallery data')


if __name__ == '__main__':
    build()
