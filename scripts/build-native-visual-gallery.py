#!/usr/bin/env python3
"""Archive unmodified XCTest PNGs into a NEW review directory and build a local gallery."""
import argparse, hashlib, html, json, os, shutil, struct
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
GALLERY = ROOT / 'docs/testing/native-visual-program'
STATES = ['native-visual-review-day', 'native-visual-review-night', 'native-loading-founding',
          'native-loading-river', 'native-loading-mountain', 'onboarding-continuous-fog-initial',
          'onboarding-continuous-fog-forest']

WALKTHROUGH_STATES = ['walkthrough-01-hut-guide', 'walkthrough-02-expedition-guide',
                      'walkthrough-03-forest-woodcutter-guide', 'walkthrough-04-goals-handoff']

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture', action='append', default=[], help='phone|mini|pro=xcresulttool attachment directory')
    parser.add_argument('--output', type=Path, required=True, help='New directory inside gallery/captures')
    parser.add_argument('--render-only', action='store_true', help='Validate an existing archive and regenerate HTML only')
    parser.add_argument('--walkthrough', action='store_true', help='Archive the four interactive guide steps and build walkthrough.html')
    parser.add_argument('--include-placement', action='store_true', help='Include actual candidate drag screenshot in a walkthrough archive')
    args = parser.parse_args()
    if args.include_placement and not args.walkthrough:
        parser.error('Placement captures require --walkthrough')
    states = WALKTHROUGH_STATES + (['walkthrough-placement-drag-suggest'] if args.include_placement else []) if args.walkthrough else STATES
    target = args.output.resolve()
    if not target.is_relative_to(GALLERY / 'captures') or args.output.is_symlink():
        parser.error('Output must be a new gallery/captures directory without aliases')
    pending = []
    if not args.render_only:
        sources = {}
        for item in args.capture:
            profile, raw = item.split('=', 1)
            if profile not in ('phone', 'mini', 'pro') or profile in sources:
                parser.error('Use each phone/mini/pro profile exactly once')
            sources[profile] = Path(raw)
        if set(sources) != {'phone', 'mini', 'pro'}:
            parser.error('All three actual profiles are required')
        # Validate all inputs before publishing output. Never infer success from zero captures.
        pending = []
        for profile, source in sources.items():
            found = {}
            for test in json.loads((source / 'manifest.json').read_text()):
                for attachment in test['attachments']:
                    suggested = attachment.get('suggestedHumanReadableName', '')
                    for state in states:
                        if suggested.startswith(state + '_') and not attachment.get('isAssociatedWithFailure', False):
                            name = attachment['exportedFileName']
                            if Path(name).name != name or state in found:
                                raise ValueError('Aliased/duplicate capture')
                            path = source / name
                            if path.is_symlink() or not path.is_file():
                                raise ValueError('Missing/aliased capture')
                            data = path.read_bytes()
                            if not data.startswith(b'\x89PNG\r\n\x1a\n'):
                                raise ValueError('Capture is not PNG')
                            found[state] = (path, struct.unpack('>II', data[16:24]), attachment)
            if set(found) != set(states):
                raise ValueError(f'{profile}: missing actual captures {set(states)-set(found)}')
            for state in states:
                path, size, attachment = found[state]
                pending.append((profile, state, path, size, attachment))
    receipts = json.loads((ROOT / 'docs/art/living-world-candidates/generation-receipts.json').read_text())
    references = {Path(a['workspacePath']).name: ROOT / a['workspacePath'] for a in receipts['assets']}
    for asset in receipts['assets']:
        if digest(ROOT / asset['workspacePath']) != asset['sha256'] or digest(ROOT / asset['promptPath']) != asset['promptSha256']:
            raise ValueError('Concept asset/prompt hash mismatch')
        if asset.get('referencedImagePaths') and digest(references[Path(asset['referencedImagePaths'][0]).name]) != asset['referenceSha256']:
            raise ValueError('Concept edit reference hash mismatch')
    if args.render_only:
        if args.capture:
            parser.error('Render-only reads its pinned archive, not new captures')
        records = json.loads((target / 'manifest.json').read_text())
        if {(r['profile'], r['state']) for r in records} != {(p, s) for p in ('phone','mini','pro') for s in states} or len(records) != 3 * len(states):
            raise ValueError('Existing archive must contain all unique required captures')
        for record in records:
            path = (GALLERY / record['file']).resolve()
            if not path.is_relative_to(target) or digest(path) != record['sha256']:
                raise ValueError('Existing capture path/hash mismatch')
    else:
        target.mkdir(parents=True, exist_ok=False)
        records = []
        for profile, state, path, size, attachment in pending:
            folder = target / profile; folder.mkdir(exist_ok=True)
            copied = folder / (state + '.png'); shutil.copyfile(path, copied)
            assert digest(path) == digest(copied)
            records.append({'profile':profile, 'state':state, 'file':str(copied.relative_to(GALLERY)),
                            'width':size[0], 'height':size[1], 'sha256':digest(copied),
                            'source':str(path), 'device':attachment.get('deviceName'),
                            'timestamp':attachment.get('timestamp')})
        (target / 'manifest.json').write_text(json.dumps(records, indent=2)+'\n')
    body = ['<h1>Native visual and onboarding review</h1>',
            '<p>Review prototypes, not final art acceptance. Original saves and normal expedition rules are unchanged; R2-07 is disabled.</p>',
            '<p>Three procedural loading scenes; disposable village roads, shared-yard joins, day/night and provisional people. Onboarding compares continuous fog with a whole-forest reveal and validated woodcutter preview. Native card/reveal is demonstrated; out-of-order/skip tutorial behavior is model-tested.</p>',
            '<p>Grouped village uses the existing geometry-study fixture, not a production footprint migration. No physical performance certification, bridge/gate gameplay, final directional sprites or complete animation atlas is claimed.</p>',
            '<p><a href="../../ui/themes-review/index.html">Theme and notification workbench</a> · <a href="../../art/building-gate-2/index.html">Building Gate 2</a> · <a href="progress.md">Verification ledger</a></p>']
    if args.walkthrough:
        body = ['<h1>Interactive onboarding walkthrough</h1>',
                '<p>Open Developer tools → Onboarding walkthrough — start here. This is a fresh in-memory rehearsal; normal New Game has not changed. The guide runs real Hut construction, one paid expedition countdown and Woodcutter construction. Whole-forest discovery is a review proposal applied only to this disposable copy.</p>',
                '<p>Drag the building or tap an open tile, then confirm. Next suggested site chooses another authoritative-valid site. Skip/reopen preserves this temporary progress. Explicit time advance is labeled; existing saves and R2-07 remain unchanged. Owner requested refinement before normal integration; no approval is inferred.</p>',
                '<p><a href="index.html">Earlier visual/fog comparison</a> · <a href="progress.md">Verification ledger</a></p>']
    clip_manifest = GALLERY / 'clips/provenance.json'
    if clip_manifest.exists() and not args.walkthrough:
        clips = json.loads(clip_manifest.read_text())
        for clip in clips['records']:
            if digest(GALLERY / clip['file']) != clip['sha256']:
                raise ValueError('Recorded clip hash mismatch')
        watch = next(c for c in clips['records'] if c['role'] == 'upright')
        body.append('<h2>Recorded loading review</h2><video style="width:100%" controls preload="metadata" src="'+html.escape(watch['file'])+'"></video><p>Simulator loading scenes and decorative Skip; upright watch-copy. No living-agent/weather motion or hardware performance claim. <a href="clips/provenance.json">Recording provenance</a></p>')
    for profile in ('phone','mini','pro'):
        body.append('<h2>'+profile.capitalize()+'</h2>')
        for record in records:
            if record['profile'] == profile:
                label = html.escape(record['state'].replace('-', ' ')); file = html.escape(record['file'])
                body.append(f'<figure><a href="{file}"><img loading="lazy" src="{file}" alt="{label}"></a><figcaption>{label}</figcaption></figure>')
    body.append('<details><summary>Character and wildlife concepts — unregistered frames, no runtime export</summary>')
    for asset in receipts['assets']:
        file = html.escape(os.path.relpath(ROOT / asset['workspacePath'], GALLERY))
        body.append(f'<figure class="concept"><img loading="lazy" src="{file}" alt="Concept {html.escape(asset["id"])}"><figcaption>{html.escape(asset["id"])}</figcaption></figure>')
    body.append('</details>')
    style = 'body{max-width:1200px;margin:32px auto;padding:0 20px;background:#142322;color:#f0e8cf;font:17px/1.6 system-ui}a{color:#a9dddb}img{display:block;width:100%;height:auto}figure{margin:20px 0 36px}figcaption{padding:8px}.concept{background:#ddd;color:#111}summary{cursor:pointer;padding:18px}'
    (GALLERY / ('walkthrough.html' if args.walkthrough else 'index.html')).write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Native visual review</title><style>'+style+'</style><main>'+''.join(body)+'</main></html>')
    print(f'PASS:{len(records)} unchanged native captures,4 concept/prompt hashes; validated archive and local gallery')

if __name__ == '__main__':
    main()
