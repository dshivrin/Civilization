#!/usr/bin/env python3
"""Build Gate 2 review data from preserved imagegen outputs and actual-map fixtures."""
import hashlib
import json
import argparse
import struct
import os
import tempfile
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


def build_directions(review=None):
    """A bounded alternate-view study; validates every input before publishing data."""
    if not __debug__:
        raise RuntimeError('Direction integrity validation requires Python without -O/PYTHONOPTIMIZE')
    review = review or ROOT / 'docs/art/building-direction-review'
    receipts = json.loads((review / 'generation-receipts.json').read_text())
    expected = ['view-a', 'view-b', 'view-c', 'view-d']
    records = receipts['records']
    assert [r['id'] for r in records] == expected, 'Exactly four ordered source views required'
    assert receipts['logicalFootprint'] == [2, 2] and receipts['runtimePromoted'] is False
    source = 'docs/art/sources/buildings/gatheringShelter.png'
    inventory = json.loads((ROOT / 'docs/art/building-gate-1/evidence/inventory.json').read_text())
    originals = {b['id']: b for b in inventory['buildings']}
    for original in originals.values():
        assert digest(ROOT / 'Civilization/Art' / original['art']['file']) == original['sprite']['sha256'], 'Shipped art drift'
    assert digest(ROOT / source) == originals['gatheringShelter']['master']['sha256'], 'Reference master drift'
    config_path = ROOT / 'Packages/GameCore/Sources/GameCore/Resources/seed.json'
    fixtures = json.loads((ROOT / 'docs/art/building-gate-1/evidence/river-fixtures.json').read_text())
    assert digest(config_path) == fixtures['configSHA256'], 'Seed drift requires reconciliation'
    building = next(b for b in json.loads(config_path.read_text())['buildings'] if b['kind'] == 'gatheringShelter')
    assert [building['width'], building['height']] == [2, 2]
    measurement_path = review / 'measurements.jsonl'
    assert digest(measurement_path) == receipts['measurementsSHA256'], 'Native measurement report drift'
    measured = [json.loads(line) for line in measurement_path.read_text().splitlines() if line]
    assert len(measured) == 4 and len({Path(m['file']).stem for m in measured}) == 4
    measurements = {Path(m['file']).stem: m for m in measured}
    views = []
    art = originals['gatheringShelter']['art']
    raw_rect = [-art['anchorX'] * art['worldWidth'], -(1-art['anchorY']) * art['worldHeight'], art['worldWidth'], art['worldHeight']]
    for index, r in enumerate(records):
        key = r['id']; m = measurements[key]
        assert r['file'] == f'assets/{key}.png' and r['nominalQuarterTurn'] == index
        path = review / r['file']
        assert not path.is_symlink() and path.is_file(), 'Missing/aliased view'
        payload = path.read_bytes()
        assert payload.startswith(b'\x89PNG\r\n\x1a\n') and struct.unpack('>II', payload[16:24]) == (m['width'], m['height'])
        assert digest(path) == m['sha256'] == r['outputSHA256'], 'Output drift: '+key
        assert m['alphaThreshold'] == 32 and m['transparentFraction'] > .1 and m['coveredEdgePixels'] == 0, 'Alpha/padding inspection failed'
        assert r['reference'] == source and digest(ROOT / source) == r['referenceSHA256'], 'Reference drift'
        assert r['certifiedCardinalMapping'] is False and r['copyUnchanged'] is True
        if index:
            assert r['prompt'] == f'prompts/{key}.txt' and digest(review / r['prompt']) == r['promptSHA256'], 'Prompt drift'
            assert r['tool'] == 'built-in image_gen.imagegen edit'
        else:
            assert r['prompt'] is None and digest(path) == digest(ROOT / source), 'Reference copy changed'
        x0, y0, x1, y1 = m['silhouetteBoundsTopLeftInclusive']
        assert 0 <= x0 <= x1 < m['width'] and 0 <= y0 <= y1 < m['height']
        scale = 116 / (x1-x0+1)
        views.append({**r, 'measurements':m, 'rawImageRect':raw_rect,
            'proposedImageRect':[-(x0+x1+1)/2*scale, 16-(y1+1)*scale, m['width']*scale, m['height']*scale],
            'contactStatus':'No semantic ground mask; silhouette framing is a proposal only'})
    data = {'schemaVersion':1,'assetFamily':'gatheringShelter','logicalFootprint':[2,2],
        'status':'Single-family alternate views; uncertified cardinal/geometry/lighting registration',
        'runtimeIntegrated':False,'r207Enabled':False,'configSHA256':digest(config_path),
        'generationCalls':receipts['generationCalls'],'targetedCorrectionCalls':receipts['targetedCorrectionCalls'],
        'nativeMeasurementsSHA256':digest(measurement_path),
        'sourceReferenceSHA256':digest(ROOT/source),'views':views}
    outputs = {'manifest.json':json.dumps(data,indent=2)+'\n',
        'gallery-data.js':'window.DIRECTION_REVIEW = '+json.dumps(data,separators=(',',':'))+';\n'}
    for name in outputs:
        target = review / name
        if target.is_symlink() or (target.exists() and not target.is_file()):
            raise ValueError('Refusing aliased/non-file gallery output: '+name)
    # Stage both independent files before replacing either. Keep previous bytes for rollback.
    with tempfile.TemporaryDirectory(prefix='.direction-gallery-',dir=review) as staging:
        staged = Path(staging); previous = {}
        for name, text in outputs.items():
            (staged/name).write_text(text,encoding='utf-8')
            previous[name] = (review/name).read_bytes() if (review/name).exists() else None
            if previous[name] is not None:
                (staged/('previous-'+name)).write_bytes(previous[name])
        published = []
        try:
            for name in outputs:
                os.replace(staged/name,review/name); published.append(name)
        except OSError:
            for name in reversed(published):
                if previous[name] is None:
                    (review/name).unlink()
                else:
                    os.replace(staged/('previous-'+name),review/name)
            raise
    print('PASS: four immutable source views, three prompt/reference digests, actual alpha inspection and fixed2x2footprint')
    return data


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directions', action='store_true', help='Validate the separate gathering-shelter rotation study')
    args = parser.parse_args()
    if args.directions:
        build_directions()
    else:
        build()
