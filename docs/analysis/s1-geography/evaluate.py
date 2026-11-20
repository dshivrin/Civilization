"""Offline design study, not game configuration or a migration implementation.

Run from the repository root. Standard library only; emits review artifacts here.
Terrain annexes and footprints are proposals. No private save files are read.
"""
import collections
import hashlib
import json
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
SOURCE = ROOT / 'Packages/GameCore/Sources/GameCore/Resources/seed.json'
C = json.loads(SOURCE.read_text())
SIZES = [(48, 36), (64, 48), (80, 60)]
FOOTPRINTS = dict(zip([b['kind'] for b in C['buildings']],
    [(1,1),(2,2),(2,1),(2,2),(2,1),(3,2),(3,2),(4,3),(3,3),(3,2),
     (2,2),(3,2),(3,2),(3,3),(2,2),(2,2),(3,3),(3,2),(1,1),(1,1)]))

def rect(x,y,w,h):
    return {(a,b) for b in range(y,y+h) for a in range(x,x+w)}

def neighbors(p):
    x,y=p
    return [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]

def flood(cells, start):
    seen={start}; todo=[start]
    for p in todo:
        for q in neighbors(p):
            if q in cells and q not in seen:
                seen.add(q); todo.append(q)
    return seen

def terrain(w,h):
    """Keep all 768 old cells. Extend river from its exact south-edge outlet.

    Annex river turns east along two added rows then south, with a wooded west edge, east-bank hills and
    forest. Same relative terrain recipe for all three candidates.
    """
    result={}
    for y in range(h):
        river=24 if y<26 else w-12
        for x in range(w):
            if x<32 and y<24: t=C['map']['rows'][y][x]
            elif (24<=y<26 and 24<=x<w-10) or (y>=26 and river<=x<river+2): t='w'
            elif x<3 or (x>=river+6 and y<h//3): t='f'
            elif x>=w-6 and y>=h//3: t='h'
            else: t='.'
            result[x,y]=t
    return result

def housing(variant):
    # Three 10x10 neighborhoods, eight actual 2x2 homes each.
    if variant=='pairs':
        origins=[(x,y) for y in (2,6) for x in (1,3,6,8)]
    elif variant=='square':
        origins=[(x,y) for y in (1,3,6,8) for x in (1,3)]
    else:
        origins=[(x,y) for y in (1,4,7) for x in (1,4,7) if (x,y)!=(4,4)]
    return [('hut',x,y,2,2) for x,y in origins]

def workshop(items, width):
    # Shelf rows with a one-tile road above each row and a western spine.
    result=[]; x=1; y=1; row_height=0
    for kind in items:
        w,h=FOOTPRINTS[kind]
        if x+w>=width:
            x=1; y+=row_height+1; row_height=0
        result.append((kind,x,y,w,h)); x+=w+1; row_height=max(row_height,h)
    return result, y+row_height+1

def blocks():
    result=[]
    for variant in ('pairs','square','courtyard'):
        result.append((variant,10,10,housing(variant)))
    groups=[('food',['gatheringShelter']*2+['huntingLodge']*2+['fishingShelter']*2+
             ['farm']*4+['animalPen']*2,16),
            ('industry',['woodcutter']*3+['stoneGatherer']*2+['toolmaker']*2+
             ['tannery','potteryWorkshop'],14),
            ('civic',['storytellingCircle','healersHut','shrine','burialGround'],12),
            ('logistics',['storehouse']*3+['scoutCamp','watchtower','watchtower']+
             ['palisade']*8,12)]
    for name,items,width in groups:
        buildings,height=workshop(items,width)
        result.append((name,width,height,buildings))
    result += [('rearrange-A',12,6,[]),('rearrange-B',8,8,[])]
    return result

def evaluate(w,h):
    land=terrain(w,h); buildable={p for p,t in land.items() if t in '.c'}
    component=flood(buildable,(17,12))
    occupied={(17,12)}; buildings=[dict(kind='campfire',x=17,y=12,w=1,h=1)]
    zones=[]; used={(17,12)}; failed=[]; reserves=set(); local_roads=set(); decor=set()
    # Authored common layout for 64/80; deterministic greedy attempt for 48.
    # Search all integer origins as a basic diagnostic, not a packing proof.
    # Failure is a feasibility warning for this plan, not an impossibility proof.
    authored = {'food':(3,26),'industry':(19,26),'logistics':(33,26),
        'civic':(19,36),'pairs':(10,14),'square':(31,37),'courtyard':(41,37),
        'rearrange-A':(3,42),'rearrange-B':(12,0)}
    for name,bw,bh,contents in sorted(blocks(),key=lambda b:(b[0].startswith('rearrange'),-b[1]*b[2])):
        candidates=[]
        for y in range(h-bh+1):
            for x in range(w-bw+1):
                cells=rect(x,y,bw,bh)
                if cells<=component and not cells&used:
                    candidates.append((y,x,y,x))
        if not candidates:
            failed.append(name); continue
        if w>=64:
            x,y=authored[name]
            assert rect(x,y,bw,bh)<=component and not rect(x,y,bw,bh)&used, (name, sorted(rect(x,y,bw,bh)-component), sorted(rect(x,y,bw,bh)&used))
        else:
            _,_,y,x=min(candidates)
        cells=rect(x,y,bw,bh); used|=cells
        zones.append(dict(name=name,x=x,y=y,w=bw,h=bh))
        if name.startswith('rearrange'):
            reserves|=cells; continue
        block_occupied=set()
        fishing_index=0; stone_index=0; wood_index=0
        for kind,dx,dy,fw,fh in contents:
            bx,by=x+dx,y+dy
            if w>=64 and kind=='fishingShelter':
                bx,by=21,24+fishing_index; fishing_index+=1
            if w>=64 and kind=='stoneGatherer' and stone_index==0:
                bx,by=7,24
            if kind=='stoneGatherer': stone_index+=1
            if w>=64 and kind=='woodcutter' and wood_index==2:
                bx,by=4,24
            if kind=='woodcutter': wood_index+=1
            b=dict(kind=kind,x=bx,y=by,w=fw,h=fh)
            buildings.append(b); block_occupied|=rect(b['x'],b['y'],fw,fh)
        occupied|=block_occupied
        # Border roads + all horizontal/vertical one-tile gaps that run across
        # the district. Remaining spaces become decoration/courtyard land.
        gaps=cells-block_occupied
        roads={p for p in gaps if p[0] in (x,x+bw-1) or p[1] in (y,y+bh-1)}
        for xx in range(x,x+bw):
            col={(xx,yy) for yy in range(y,y+bh)}
            if col<=gaps: roads|=col
        for yy in range(y,y+bh):
            row={(xx,yy) for xx in range(x,x+bw)}
            if row<=gaps: roads|=row
        local_roads|=roads; decor|=gaps-roads
    # An accessible near-side quarry is a visual/worksite design, not a new
    # deposit or resource grant. Route to this flat annex apron, never hills.
    quarry=(10,24)
    # A 6x6 public plaza has its own road approach, excluded from road area.
    plaza=None
    for py in range(h-5):
        for px in range(w-5):
            cells=rect(px,py,6,6)
            if cells<=component and not cells&(occupied|local_roads|reserves|decor):
                plaza=(px,py); decor|=cells; break
        if plaza: break
    plaza_access=(plaza[0]+6,plaza[1]+2) if plaza else None
    walkable=component-occupied-reserves-decor
    targets=set(local_roads)|{quarry}
    if plaza_access: targets.add(plaza_access)
    for b in buildings:
        perimeter={q for p in rect(b['x'],b['y'],b['w'],b['h']) for q in neighbors(p)} & walkable
        if perimeter:
            targets.add(min(perimeter,key=lambda p:(abs(p[0]-17)+abs(p[1]-12),p)))
    connected=set(); roads=set(local_roads); route_failures=[]
    start=(17,13)
    if start not in walkable: start=next(p for p in neighbors((17,12)) if p in walkable)
    connected={start}; roads.add(start)
    while targets-connected:
        queue=collections.deque(sorted(connected)); parent={p:None for p in connected}; found=None
        while queue and found is None:
            p=queue.popleft()
            for q in neighbors(p):
                if q in walkable and q not in parent:
                    parent[q]=p; queue.append(q)
                    if q in targets-connected: found=q; break
        if found is None:
            route_failures=sorted(targets-connected); break
        path=set(); p=found
        while p is not None and p not in connected:
            path.add(p); p=parent[p]
        roads|=path; connected=flood(roads,start)
    # Count a building accessible if at least one perimeter cell touches the
    # campfire-connected pedestrian network; no gameplay access gate implied.
    accessible=[]
    for b in buildings:
        cells=rect(b['x'],b['y'],b['w'],b['h'])
        if any(q in connected for p in cells for q in neighbors(p)):
            accessible.append(b)
    distances={start:0}; queue=[start]
    for p in queue:
        for q in neighbors(p):
            if q in connected and q not in distances:
                distances[q]=distances[p]+1; queue.append(q)
    # Permanent discovery territory = all cells outside legacy rectangle;
    # it overlaps terrain categories, never added to their disjoint area sum.
    counts=collections.Counter(b['kind'] for b in buildings)
    max_radius=max(max(abs(x-17),abs(y-12)) for x,y in land)
    result=dict(size=[w,h],total=w*h,terrain=dict(collections.Counter(land.values())),
        buildable=len(buildable),contiguous=len(component),other_land=len(buildable-component),
        district_area=sum(z['w']*z['h'] for z in zones if not z['name'].startswith('rearrange')),
        footprints=len(occupied),roads=len(roads),decorations=len(decor),reserve=len(reserves),
        unassigned=len(component-occupied-roads-decor-reserves),buildings=len(buildings),
        counts=dict(counts),all_types=len(counts)==20,accessible=len(accessible),
        failed_blocks=failed,unconnected_road_tiles=len(route_failures),plaza=plaza,
        quarry=quarry,quarry_connected=quarry in connected,max_road_distance=max(distances.values()),
        max_discovery_radius=max_radius,expeditions=(max_radius-7+1)//2,
        zones=zones,placements=buildings,road_tiles=sorted(roads,key=lambda p:(p[1],p[0])),legacy_exact=all(land[x,y]==C['map']['rows'][y][x]
            for y in range(24) for x in range(32)))
    assert result['footprints']+result['roads']+result['decorations']+result['reserve']+result['unassigned']==result['contiguous']
    assert not occupied&roads and not reserves&(occupied|roads|decor)
    assert sum(b['w']*b['h'] for b in buildings)==len(occupied)
    assert occupied<=component and roads<=component
    if w>=64:
        for b in buildings:
            definition=next(d for d in C['buildings'] if d['kind']==b['kind'])
            required=definition.get('requiredNearbyTerrain')
            if required:
                radius=definition['nearbyTerrainRadius']
                assert any(t==required and max(abs(p[0]-b['x']),abs(p[1]-b['y']))<=radius
                    for p,t in land.items()), (b,required)
            for recipe in definition.get('recipes',[]):
                resource=recipe.get('depositResource')
                if resource:
                    assert any(d.get('resource')==resource and
                        abs(d['origin']['x']-b['x'])+abs(d['origin']['y']-b['y'])<=d['radius']
                        for d in C['naturalDeposits']), (b,recipe['id'])
    assert result['legacy_exact']
    result['layout_pass']=not failed and result['all_types'] and len(accessible)==len(buildings) and not route_failures and plaza is not None and quarry in connected
    colors={'.':'#e4ebc7','c':'#ede2b5','w':'#7fb7d1','f':'#72966a','h':'#a4a59b'}
    s=12; svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-12 -45 {w*s+24} {h*s+115}">',
        '<rect x="-12" y="-45" width="100%" height="100%" fill="#fffdf6"/>',
        f'<text y="-20" font-family="sans-serif" font-size="18">{w} × {h} — planning layout; not activated</text>']
    for (x,y),t in land.items():
        color='#d3bb78' if (x,y) in roads else '#bca2ce' if (x,y) in decor else '#f6f2e8' if (x,y) in reserves else colors[t]
        svg.append(f'<rect x="{x*s}" y="{y*s}" width="{s}" height="{s}" fill="{color}" stroke="#ffffff33" stroke-width=".5"/>')
    for b in buildings:
        color='#b5684b' if b['kind']=='hut' else '#745b47'
        svg.append(f'<rect x="{b["x"]*s}" y="{b["y"]*s}" width="{b["w"]*s}" height="{b["h"]*s}" fill="{color}" stroke="#fffdf6"><title>{escape(b["kind"])} ({b["x"]},{b["y"]})</title></rect>')
    for z in zones:
        svg.append(f'<rect x="{z["x"]*s}" y="{z["y"]*s}" width="{z["w"]*s}" height="{z["h"]*s}" fill="none" stroke="#51483b" stroke-dasharray="3 3"/>')
        svg.append(f'<text x="{z["x"]*s+2}" y="{z["y"]*s+9}" font-family="sans-serif" font-size="8" fill="#111">{z["name"]}</text>')
    svg += [f'<rect width="{32*s}" height="{24*s}" fill="none" stroke="#d23b36" stroke-width="2"/>',
        f'<circle cx="{quarry[0]*s+s/2}" cy="{quarry[1]*s+s/2}" r="5" fill="#111"/>',
        f'<text y="{h*s+22}" font-family="sans-serif" font-size="11">Red: unchanged legacy 32×24 · tan: roads · purple: communal/decor · white: rearrangement</text>',
        f'<text y="{h*s+40}" font-family="sans-serif" font-size="11">Terracotta: homes · brown: catalog buildings · black dot: proposed quarry apron · cells: 1 tile</text>','</svg>']
    (OUT/f'layout-{w}x{h}.svg').write_text('\n'.join(svg)+'\n')
    return result

if __name__=='__main__':
    results=[evaluate(*size) for size in SIZES]
    assert not results[0]['layout_pass'] and results[1]['layout_pass'] and results[2]['layout_pass']
    (OUT/'results.json').write_text(json.dumps(dict(source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        footprints=FOOTPRINTS,results=results),indent=2)+'\n')
    for r in results:
        print(json.dumps({k:v for k,v in r.items() if k not in ('placements','zones')}))
