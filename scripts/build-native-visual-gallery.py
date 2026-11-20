#!/usr/bin/env python3
"""Archive unmodified XCTest PNGs into a NEW review directory and build a local gallery."""
import argparse, hashlib, html, json, os, shutil, struct, subprocess, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
GALLERY = ROOT / 'docs/testing/native-visual-program'
STATES = ['native-visual-review-day', 'native-visual-review-night', 'native-loading-founding',
          'native-loading-river', 'native-loading-mountain', 'onboarding-continuous-fog-initial',
          'onboarding-continuous-fog-forest']

WALKTHROUGH_STATES = ['walkthrough-01-hut-guide', 'walkthrough-02-expedition-guide',
                      'walkthrough-03-forest-woodcutter-guide', 'walkthrough-04-goals-handoff']

ATMOSPHERE_STATES = ['atmosphere-day', 'atmosphere-dusk', 'atmosphere-night', 'atmosphere-dawn',
                     'atmosphere-rain-static', 'atmosphere-fog-static']
CONSTRUCTION_STATES = ['construction-01-foundation', 'construction-02-frame', 'construction-03-walls',
                       'construction-04-roof', 'construction-05-finished']
VILLAGER_STATES = ['villager-pose-' + state for state in ['idle','walk','carry','gather','work','rest','socialize','turn']]
PROFILES = ('phone', 'mini', 'pro')
MOTION_CASE = 'CivilizationUITests/RelocationUITests/testVillagerMotionReviewStatesAndStaticFallback'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def motion_devices(report):
    scope = report.get('scope', {})
    devices = scope.get('simulator', [])
    if (report.get('status') != 'passed' or scope.get('suite') != 'ui' or scope.get('configuration') != 'debug'
            or MOTION_CASE not in scope.get('only_testing', []) or len(devices) != 3 or len(set(devices)) != 3):
        raise ValueError('Villager captures require a passed three-destination motion QA report')
    for i in range(3):
        steps = [s for s in report.get('steps', []) if s.get('name') == f'ui-debug-{i+1}']
        if len(steps) != 1 or steps[0].get('status') != 'passed' or steps[0].get('exitCode') != 0 or steps[0].get('tests', 0) <= 0:
            raise ValueError('Every reported destination must execute and pass native tests')
    return dict(zip(PROFILES, devices))

def verify_motion_device(profile, device_id, name, devices):
    prefix = {'phone': 'iPhone', 'mini': 'iPad mini', 'pro': 'iPad Pro'}[profile]
    if device_id != devices[profile] or not isinstance(name, str) or not name.startswith(prefix):
        raise ValueError('Capture device does not match its profile and passed QA destination')

def motion_device_step(report, device):
    scope = report.get('scope', {})
    devices = scope.get('simulator', [])
    if (report.get('status') not in ('passed', 'failed') or scope.get('suite') != 'ui'
            or scope.get('configuration') != 'debug' or MOTION_CASE not in scope.get('only_testing', [])
            or devices.count(device) != 1):
        raise ValueError('Device evidence requires its actual scoped motion report')
    name = f'ui-debug-{devices.index(device)+1}'
    steps = [s for s in report.get('steps', []) if s.get('name') == name]
    if len(steps) != 1 or steps[0].get('status') != 'passed' or steps[0].get('exitCode') != 0 or steps[0].get('tests', 0) <= 0:
        raise ValueError('The selected device step did not execute and pass')
    return name

def verify_motion_export(report, profile, found, name=None):
    """Bind supplied images to the passed result bundle, rather than trusting a folder label."""
    name = name or f'ui-debug-{PROFILES.index(profile)+1}'
    command = next(s for s in report['steps'] if s['name'] == name).get('command', [])
    if '-resultBundlePath' not in command:
        raise ValueError('Passed QA step must identify its result bundle')
    bundle = Path(command[command.index('-resultBundlePath')+1])
    if not bundle.is_dir():
        raise ValueError('Passed result bundle is unavailable for capture verification')
    with tempfile.TemporaryDirectory(prefix='civilization-motion-export-') as raw:
        output = Path(raw) / 'attachments'
        subprocess.run(['xcrun', 'xcresulttool', 'export', 'attachments', '--path', str(bundle),
                        '--output-path', str(output)], check=True, capture_output=True, timeout=60)
        expected = {}
        for test in json.loads((output / 'manifest.json').read_text()):
            for a in test['attachments']:
                for state in VILLAGER_STATES:
                    if a.get('suggestedHumanReadableName', '').startswith(state+'_') and not a.get('isAssociatedWithFailure', False):
                        if state in expected or Path(a['exportedFileName']).name != a['exportedFileName']:
                            raise ValueError('Ambiguous passed-bundle capture')
                        expected[state] = (digest(output / a['exportedFileName']), a.get('deviceId'), a.get('deviceName'), a.get('timestamp'))
        supplied = {state: (digest(path), a.get('deviceId'), a.get('deviceName'), a.get('timestamp'))
                    for state, (path, _, a) in found.items()}
        if expected != supplied:
            raise ValueError('Supplied captures do not match the passed result bundle')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture', action='append', default=[], help='phone|mini|pro=xcresulttool attachment directory')
    parser.add_argument('--output', type=Path, required=True, help='New directory inside gallery/captures')
    parser.add_argument('--render-only', action='store_true', help='Validate an existing archive and regenerate HTML only')
    parser.add_argument('--walkthrough', action='store_true', help='Archive the four interactive guide steps and build walkthrough.html')
    parser.add_argument('--include-placement', action='store_true', help='Include actual candidate drag screenshot in a walkthrough archive')
    parser.add_argument('--atmosphere', action='store_true', help='Archive six lighting/weather comparisons and build atmosphere.html')
    parser.add_argument('--construction', action='store_true', help='Archive five actual-work stages and build construction.html')
    parser.add_argument('--villagers', action='store_true', help='Archive eight provisional pose comparisons and build villagers.html')
    parser.add_argument('--qa-report', type=Path, help='Passed three-profile UI report; required for a new villagers archive')
    parser.add_argument('--profile-report', action='append', default=[], help='phone|mini|pro=actual report with a passed device step; keeps other-device failures unchanged')
    args = parser.parse_args()
    if args.include_placement and not args.walkthrough:
        parser.error('Placement captures require --walkthrough')
    if sum([args.atmosphere, args.walkthrough, args.construction, args.villagers]) > 1:
        parser.error('Atmosphere, construction, villagers and walkthrough archives are separate')
    states = VILLAGER_STATES if args.villagers else CONSTRUCTION_STATES if args.construction else ATMOSPHERE_STATES if args.atmosphere else WALKTHROUGH_STATES + (['walkthrough-placement-drag-suggest'] if args.include_placement else []) if args.walkthrough else STATES
    target = args.output.resolve()
    if not target.is_relative_to((GALLERY / 'captures').resolve()) or args.output.is_symlink():
        parser.error('Output must be a new gallery/captures directory without aliases')
    pending = []
    proofs = {}
    if not args.render_only:
        per_device = {}
        for item in args.profile_report:
            profile, raw = item.split('=', 1)
            if profile not in PROFILES or profile in per_device:
                parser.error('Use each profile report exactly once')
            per_device[profile] = Path(raw)
        if per_device and (not args.villagers or args.qa_report or set(per_device) != set(PROFILES)):
            parser.error('Per-device evidence requires all three villagers profiles and no matrix report')
        sources = {}
        for item in args.capture:
            profile, raw = item.split('=', 1)
            if profile not in ('phone', 'mini', 'pro') or profile in sources:
                parser.error('Use each phone/mini/pro profile exactly once')
            sources[profile] = Path(raw)
        if set(sources) != {'phone', 'mini', 'pro'}:
            parser.error('All three actual profiles are required')
        if args.villagers:
            if (not args.qa_report and not per_device) or len({p.resolve() for p in sources.values()}) != 3:
                raise ValueError('Distinct source directories and a passed QA report are required')
            if not per_device:
                motion_report = json.loads(args.qa_report.read_text())
                devices = motion_devices(motion_report)
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
            if args.villagers:
                report_path = per_device.get(profile, args.qa_report)
                report = json.loads(report_path.read_text())
                device = found[states[0]][2].get('deviceId')
                step = motion_device_step(report, device)
                if per_device:
                    devices = {profile: device}
                for _, _, a in found.values():
                    verify_motion_device(profile, a.get('deviceId'), a.get('deviceName'), devices)
                verify_motion_export(report, profile, found, step)
                report_hash = digest(report_path)
                proofs[profile] = dict(path=report_path, sha=report_hash, report=report,
                    file=target / ('qa-reports/'+report_hash+'.json' if per_device else 'qa-report.json'),
                    step=step, scope='passed-device-step' if per_device else 'passed-matrix')
            for state in states:
                path, size, attachment = found[state]
                pending.append((profile, state, path, size, attachment))
        if args.villagers and len({a.get('deviceId') for _, _, _, _, a in pending}) != 3:
            raise ValueError('Three distinct capture devices are required')
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
        if args.villagers:
            for record in records:
                report_path = (GALLERY / record['qaReportFile']).resolve()
                if not report_path.is_relative_to(target) or record.get('qaReportSHA256') != digest(report_path):
                    raise ValueError('Archived QA report hash mismatch')
                report = json.loads(report_path.read_text())
                step = motion_device_step(report, record.get('deviceID'))
                scope = record.get('qaEvidenceScope')
                if scope == 'passed-matrix': devices = motion_devices(report)
                elif scope == 'passed-device-step': devices = {record['profile']: record.get('deviceID')}
                else: raise ValueError('Unknown QA evidence scope')
                verify_motion_device(record['profile'], record.get('deviceID'), record.get('device'), devices)
                if record.get('qaStep') != step or record.get('qaReportOverallStatus') != report['status']:
                    raise ValueError('Archived QA status/step mismatch')
    else:
        target.mkdir(parents=True, exist_ok=False)
        if args.villagers:
            for proof in proofs.values():
                proof['file'].parent.mkdir(exist_ok=True)
                if not proof['file'].exists(): shutil.copyfile(proof['path'], proof['file'])
                if digest(proof['file']) != proof['sha']:
                    raise ValueError('QA report changed during publication')
        records = []
        for profile, state, path, size, attachment in pending:
            folder = target / profile; folder.mkdir(exist_ok=True)
            copied = folder / (state + '.png'); shutil.copyfile(path, copied)
            if digest(path) != digest(copied):
                raise ValueError('Capture changed during publication')
            records.append({'profile':profile, 'state':state, 'file':str(copied.relative_to(GALLERY)),
                            'width':size[0], 'height':size[1], 'sha256':digest(copied),
                            'source':str(path), 'device':attachment.get('deviceName'),
                            'timestamp':attachment.get('timestamp')})
            if args.villagers:
                proof = proofs[profile]
                records[-1].update(deviceID=attachment['deviceId'], qaReportSHA256=proof['sha'],
                    qaReportFile=str(proof['file'].relative_to(GALLERY)), qaStep=proof['step'],
                    qaEvidenceScope=proof['scope'], qaReportOverallStatus=proof['report']['status'])
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
    if args.atmosphere:
        body = ['<h1>Continuous atmosphere review</h1>',
                '<p>Simulator review only; the physical phone retains placement build33073e9. Normal rendering, saves, economy and R2-07 are unchanged. The same disposable grouped fixture is shown in day/dusk/night/dawn and static rain/fog.</p>',
                '<p>The visual-only cycle defaults to120seconds, with an explicit24second preview. Static/power modes stop the clock, people, weather and existing fire/smoke. Eight or fewer warm ground-light pools are proposals, not accepted window/contact art. No hardware FPS, battery or human acceptance is claimed.</p>',
                '<p><a href="walkthrough.html">Onboarding placement review</a> · <a href="index.html">Earlier visual review</a> · <a href="progress.md">Verification ledger</a></p>']
    if args.construction:
        body = ['<h1>Construction through actual work</h1>',
                '<p>Five native stages in the disposable onboarding walkthrough. A real Hut costs20wood and takes15seconds of engine construction work. Pause review time holds that temporary engine; labeled3second advances produce the frame, walls, roof and actual completion. No normal game or save changes.</p>',
                '<p>Foundation, timber, walls and roof are procedural visual proposals within the existing logical footprint. The temporary geometry disappears at completion and the original building asset returns. No final contact/anchor, directional art or appearance acceptance is inferred. The phone still runs33073e9.</p>',
                '<p><a href="walkthrough.html">Placement walkthrough</a> · <a href="atmosphere.html">Atmosphere</a> · <a href="construction-verification.json">Software evidence</a> · <a href="progress.md">Ledger</a></p>']
    if args.villagers:
        body = ['<h1>Villager motion comparison</h1>',
                '<p>Every image matches an actual passed device execution. Pinned original reports preserve other-device failures and retries; a failed aggregate report is never relabeled passed. Zero-test steps do not qualify.</p>',
                '<p>Eight magnified source-native poses: idle, walk, carry, gather, work, rest, socialize and turn. Open the disposable visual lab → People motion. The shared retained figure also follows planner-validated exterior routes; active production gates work and outward wood props, with an empty return.</p>',
                '<p>These are provisional procedural figures, not registered realistic sprite atlases or accepted character art. The magnified pose examples are independent of economy/workers; ordinary rendering, saves and R2-07 are unchanged. No gate/bridge routes or physical FPS/battery certificate is claimed. Phone remains33073e9.</p>',
                '<p><a href="walkthrough.html">Onboarding</a> · <a href="atmosphere.html">Atmosphere</a> · <a href="villager-verification.json">Software evidence</a> · <a href="progress.md">Ledger</a></p>']
    provenance = 'clips/villager-provenance.json' if args.villagers else 'clips/atmosphere-provenance.json' if args.atmosphere else 'clips/provenance.json'
    clip_manifest = GALLERY / provenance
    if clip_manifest.exists() and not args.walkthrough and not args.construction:
        clips = json.loads(clip_manifest.read_text())
        for clip in clips['records']:
            if digest(GALLERY / clip['file']) != clip['sha256']:
                raise ValueError('Recorded clip hash mismatch')
        watch = next(c for c in clips['records'] if c['role'] == 'upright')
        heading = 'Recorded provisional people motion' if args.villagers else 'Recorded full visual cycle' if args.atmosphere else 'Recorded loading review'
        note = 'Untrimmed simulator QA entry, walking/carrying/gathering/work and a static hold. Upright orientation-only watch-copy; no physical performance or realistic-atlas acceptance.' if args.villagers else 'Untrimmed simulator QA entry and an actual accelerated24second visual cycle; this does not measure startup or hardware performance.' if args.atmosphere else 'Simulator loading scenes and decorative Skip; upright watch-copy. No living-agent/weather motion or hardware performance claim.'
        body.append('<h2>'+heading+'</h2><video style="width:100%" controls preload="metadata" src="'+html.escape(watch['file'])+'"></video><p>'+note+' <a href="'+provenance+'">Recording provenance</a></p>')
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
    (GALLERY / ('villagers.html' if args.villagers else 'construction.html' if args.construction else 'atmosphere.html' if args.atmosphere else 'walkthrough.html' if args.walkthrough else 'index.html')).write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Native visual review</title><style>'+style+'</style><main>'+''.join(body)+'</main></html>')
    print(f'PASS:{len(records)} unchanged native captures,4 concept/prompt hashes; validated archive and local gallery')

if __name__ == '__main__':
    main()
