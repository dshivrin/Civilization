#!/usr/bin/env python3
"""Reusable local QA and read-only save tools. Run --help; no third-party Python packages."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import time
import uuid

REPO = Path(__file__).resolve().parents[1]
INSPECTOR = REPO / 'Tools' / 'SaveInspector'


def reserve_output(path):
    path = Path(path)
    path.mkdir(parents=True, exist_ok=False)
    return path


def manifest(root):
    root = Path(root)
    if root.is_symlink() or not root.is_dir():
        raise ValueError('Source must be an existing directory, not an alias')
    result = {}
    for path in sorted(root.rglob('*')):
        if path.is_symlink():
            raise ValueError('Source contains a symbolic link: ' + str(path.relative_to(root)))
        if path.is_file():
            result[str(path.relative_to(root))] = hashlib.sha256(path.read_bytes()).hexdigest()
    return result


def compare_saves(before, after, allow_new_games=False):
    before, after = Path(before), Path(after)
    old, new = manifest(before), manifest(after)
    if not old or not any(Path(p).name == 'settlement-v1.json' for p in old):
        raise ValueError('No original normal saves found; an empty comparison is not evidence')
    removed = sorted(set(old) - set(new))
    added = sorted(set(new) - set(old))
    changed = sorted(p for p in old.keys() & new.keys() if old[p] != new[p])
    preserved = not (removed or added or changed)
    if allow_new_games:
        # Selection and additive slots may change, but every prior entry and other byte must remain.
        preserved = not removed and not any(p != 'games-index.json' for p in changed)
        if 'games-index.json' in old:
            a = json.loads((before / 'games-index.json').read_text())
            b = json.loads((after / 'games-index.json').read_text())
            ids = [g['id'] for g in b['games']]
            preserved = preserved and a['version'] == b['version'] == 1
            preserved = preserved and len(ids) == len(set(ids)) and b['activeGameID'] in ids
            preserved = preserved and all(g in b['games'] for g in a['games'])
        elif 'games-index.json' in new:
            b = json.loads((after / 'games-index.json').read_text())
            preserved = preserved and b.get('version') == 1 and any(g.get('id') == 'legacy' for g in b.get('games', []))
    return {'preserved': bool(preserved), 'mode': 'allow-new-games' if allow_new_games else 'strict',
            'originalFiles': len(old), 'removed': removed, 'added': added, 'changed': changed,
            'beforeSHA256': old, 'afterSHA256': new,
            'note': 'Byte/index comparison only; use validate-saves for production state validation.'}


def test_count(output):
    counts = re.findall(r'Test run with (\d+) tests?', output)
    counts += re.findall(r'Executed (\d+) tests?', output)
    return max(map(int, counts), default=0)


def test_passed(exit_code, output):
    failure = re.search(r'(?:with|recorded)\s+[1-9]\d*\s+(?:failures?|issues?)', output)
    success = re.search(r'Test run with \d+ tests?[^\n]*\bpassed\b|Executed \d+ tests?, with 0 failures', output)
    return exit_code == 0 and test_count(output) > 0 and bool(success) and not failure and '✘ Test run' not in output


def missing_native_selections(output, selections):
    observed = re.findall(r"Test Case '-\[(\S+) (\S+)\]' started", output)
    missing = []
    for selection in selections:
        parts = selection.split('/')
        matched = False
        for full_class, method in observed:
            if parts[0] != full_class.split('.')[0]: continue
            if len(parts) > 1 and full_class != parts[0] + '.' + parts[1]: continue
            if len(parts) > 2 and method.removesuffix('()') != parts[2].removesuffix('()'): continue
            matched = True
        if not matched: missing.append(selection)
    return missing


def run_step(name, argv, output, require_tests=False):
    log = Path(output) / (re.sub(r'[^a-zA-Z0-9_-]', '-', name) + '.log')
    started = time.monotonic()
    print('Running ' + name + '…', flush=True)
    with log.open('x') as stream:
        try:
            completed = subprocess.run([str(a) for a in argv], cwd=REPO, stdout=stream, stderr=subprocess.STDOUT, check=False)
            code = completed.returncode
        except OSError as error:
            stream.write(str(error) + '\n'); code = 127
        except KeyboardInterrupt:
            stream.write('Interrupted by user\n'); code = 130
    text = log.read_text(errors='replace')
    passed = test_passed(code, text) if require_tests else code == 0
    result = {'name': name, 'command': [str(a) for a in argv], 'exitCode': code,
              'status': 'passed' if passed else 'failed', 'tests': test_count(text) if require_tests else None,
              'durationSeconds': round(time.monotonic() - started, 3), 'log': str(log)}
    if code == 0 and require_tests and not passed:
        result['reason'] = 'No executed tests or failure reported despite a successful process exit'
    print(name + ': ' + result['status'] + ' → ' + str(log), flush=True)
    return result


def revision():
    def git(*args):
        return subprocess.run(['git', *args], cwd=REPO, capture_output=True, text=True, check=False).stdout.strip()
    return {'commit': git('rev-parse', 'HEAD'), 'dirty': bool(git('status', '--porcelain'))}


def write_report(output, report):
    report['schemaVersion'] = 1
    report['generatedAtUTC'] = datetime.now(timezone.utc).isoformat()
    report['revision'] = revision()
    report['status'] = 'passed' if all(s['status'] == 'passed' for s in report['steps']) else 'failed'
    (output / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    lines = ['# Civilization local QA report', '', '**Status:** ' + report['status'],
             '**Revision:** ' + report['revision']['commit'] + (' (working tree modified)' if report['revision']['dirty'] else ''),
             '', '| Step | Result | Tests | Seconds | Log |', '|---|---|---:|---:|---|']
    for step in report['steps']:
        lines.append('| ' + ' | '.join([step['name'], step['status'], str(step['tests'] if step['tests'] is not None else '—'),
                                       str(step['durationSeconds']), '[' + Path(step['log']).name + '](' + Path(step['log']).name + ')']) + ' |')
    for step in report['steps']:
        if step['status'] == 'failed':
            lines += ['', '**' + step['name'] + ':** ' + step.get('reason', 'Command exited ' + str(step['exitCode']) + '; see raw log.')]
    lines += ['', '## Scope', '', '```json', json.dumps(report['scope'], indent=2), '```', '',
              'Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. '
              'No human acceptance or sustained physical performance is inferred.', '', '## Commands', '']
    for step in report['steps']:
        lines += ['```sh', shlex.join(step['command']), '```', '']
    (output / 'report.md').write_text('\n'.join(lines))
    print('Report: ' + str(output / 'report.md'), flush=True)
    return 0 if report['status'] == 'passed' else 1


def inspector_command(root):
    return ['swift', 'run', '--package-path', str(INSPECTOR), 'SaveInspector', str(Path(root).resolve())]


def run_tests(args, output):
    report = {'scope': vars_for_report(args), 'steps': []}
    configs = ['Debug', 'Release'] if args.configuration == 'both' else [args.configuration.title()]
    if args.suite == 'core':
        for config in configs:
            cmd = ['swift', 'test', '--package-path', str(REPO / 'Packages/GameCore')]
            if config == 'Release': cmd += ['-c', 'release']
            if args.filter: cmd += ['--filter', args.filter]
            report['steps'].append(run_step('core-' + config.lower(), cmd, output, require_tests=True))
            if report['steps'][-1]['exitCode'] == 130:
                report['scope']['cancelled'] = True
                return write_report(output, report)
        if args.configuration == 'both' and all(s['status'] == 'passed' for s in report['steps']):
            report['steps'].append(run_step('release-api-exclusions', [sys.executable, str(REPO / 'scripts/verify-developer-release.py')], output))
        else:
            report['scope']['releaseAPIExclusions'] = 'Not run: both configurations must pass in this invocation'
    else:
        cases = args.only_testing or ['CivilizationUITests/NormalEntryUITests']
        for config in configs:
            for i, simulator in enumerate(args.simulator):
                name = 'ui-' + config.lower() + '-' + str(i + 1)
                cmd = ['xcodebuild', 'test', '-project', str(REPO / 'Civilization.xcodeproj'), '-scheme', 'Civilization',
                       '-configuration', config, '-destination', 'platform=iOS Simulator,id=' + simulator,
                       '-derivedDataPath', str(args.derived_data.resolve() / config.lower() / re.sub(r'[^a-zA-Z0-9_-]', '-', simulator)), '-resultBundlePath', str(output / (name + '.xcresult')),
                       'CODE_SIGNING_ALLOWED=NO', 'PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa']
                cmd += ['-only-testing:' + case for case in cases]
                step = run_step(name, cmd, output, require_tests=True)
                if step['status'] == 'passed':
                    missing = missing_native_selections(Path(step['log']).read_text(errors='replace'), cases)
                    if missing:
                        step['status'] = 'failed'
                        step['reason'] = 'Selected tests were not executed: ' + ', '.join(missing)
                report['steps'].append(step)
                if step['exitCode'] == 130:
                    report['scope']['cancelled'] = True
                    return write_report(output, report)
    return write_report(output, report)


def vars_for_report(args):
    return {k: str(v) if isinstance(v, Path) else v for k, v in vars(args).items()}


def validate_saves(root, output):
    if output.resolve().is_relative_to(root.resolve()):
        raise ValueError('Reports must be outside the source save directory')
    before = manifest(root)
    if not before: raise ValueError('Source contains no files')
    step = run_step('validate-saves', inspector_command(root), output)
    if manifest(root) != before:
        step['status'] = 'failed'; step['reason'] = 'Validation changed source bytes'
    return write_report(output, {'scope': {'command': 'validate-saves', 'root': str(root), 'sourceByteIdentical': manifest(root) == before}, 'steps': [step]})


def backup_commands(args, output):
    commands = []
    for directory in ['data', 'verification']:
        commands.append(['xcrun', 'devicectl', 'device', 'copy', 'from', '--device', args.device,
                         '--domain-type', 'appDataContainer', '--domain-identifier', args.bundle,
                         '--source', 'Library/Application Support/Civilization',
                         '--destination', str(output / directory / 'Civilization'), '--quiet'])
    commands.append(inspector_command(output / 'data' / 'Civilization'))
    return commands


def backup_device(args, output):
    # Device IDs are explicit; this command never discovers/selects a device or launches/stops an app.
    data = output / 'data' / 'Civilization'
    check = output / 'verification' / 'Civilization'
    report = {'scope': {'command': 'backup-device', 'device': args.device, 'bundle': args.bundle,
                        'source': 'Library/Application Support/Civilization', 'stableDoubleCopy': False}, 'steps': []}
    for name, cmd in zip(['copy-device', 'verify-device-copy'], backup_commands(args, output)[:2]):
        step = run_step(name, cmd, output); report['steps'].append(step)
        if step['status'] != 'passed': return write_report(output, report)
    comparison = compare_saves(data, check)
    (output / 'preservation.json').write_text(json.dumps(comparison, indent=2) + '\n')
    report['scope']['stableDoubleCopy'] = comparison['preserved']
    if not comparison['preserved']:
        report['steps'][-1]['status'] = 'failed'
        report['steps'][-1]['reason'] = 'Device changed between copies; close the app and retry in a new output directory'
        return write_report(output, report)
    report['steps'].append(run_step('validate-saves', inspector_command(data), output))
    return write_report(output, report)


def doctor():
    result = {'tools': {name: shutil.which(name) for name in ['python3', 'swift', 'xcodebuild', 'xcrun', 'git']},
              'optional': {name: shutil.which(name) for name in ['xcbeautify', 'swiftlint']},
              'notes': ['Optional tools are not required.', 'No device/account/signing access is attempted.',
                        'Run native inventory explicitly with xcrun simctl list devices available; XcodeBuildMCP can also supply it.']}
    for name, cmd in [('swiftVersion', ['swift', '--version']), ('xcodeVersion', ['xcodebuild', '-version'])]:
        try:
            p = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True, timeout=30, check=False)
            result[name] = {'exitCode': p.returncode, 'output': (p.stdout + p.stderr).strip()}
        except (OSError, subprocess.TimeoutExpired) as error:
            result[name] = {'exitCode': 127, 'output': str(error)}
    print(json.dumps(result, indent=2))
    return 0 if all(result['tools'].values()) and all(result[k]['exitCode'] == 0 for k in ['swiftVersion', 'xcodeVersion']) else 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('doctor', help='Read tool availability; no installs or device actions')
    test = sub.add_parser('test', help='Run existing core or native suites and retain a report')
    test.add_argument('--suite', choices=['core', 'ui'], default='core')
    test.add_argument('--configuration', choices=['debug', 'release', 'both'], default='both')
    test.add_argument('--derived-data', type=Path, default=Path('/tmp/civilization-qa-builds'), help='Reusable native build cache root, separated by configuration and simulator')
    test.add_argument('--filter', help='Swift Testing name filter; report explicitly remains scoped')
    test.add_argument('--simulator', action='append', default=[], help='Explicit simulator UDID; repeat for a matrix')
    test.add_argument('--only-testing', action='append', default=[], help='XCTest suite/case ID; repeat as needed')
    validate = sub.add_parser('validate-saves', help='Production-validate a local backup without mutation')
    validate.add_argument('root', type=Path)
    backup = sub.add_parser('backup-device', help='Explicit read-only stable double-copy and production validation')
    backup.add_argument('--device', required=True)
    backup.add_argument('--bundle', required=True)
    backup.add_argument('--dry-run', action='store_true', help='Print argv without reading the device or creating files')
    compare = sub.add_parser('compare-saves', help='Compare original bytes; nonzero exit on lost/changed data')
    compare.add_argument('before', type=Path); compare.add_argument('after', type=Path)
    compare.add_argument('--allow-new-games', action='store_true', help='Allow additive files/index selection; preserve every old file/entry')
    for command in [test, validate, backup, compare]:
        command.add_argument('--output', type=Path, help='New local artifact directory; existing paths are never overwritten')
    args = parser.parse_args(argv)
    if args.command == 'doctor': return doctor()
    if args.command == 'test':
        if args.suite == 'ui' and not args.simulator: parser.error('UI tests require --simulator; no device is selected implicitly')
        if args.suite == 'core' and (args.simulator or args.only_testing): parser.error('Native options require --suite ui')
        if args.suite == 'ui' and args.filter: parser.error('--filter is for core; use --only-testing for UI')
        if any('NormalCompletionUITests' in case for case in args.only_testing):
            parser.error('NormalCompletionUITests needs a separately prepared earned-save container; use the milestone procedure')
    if args.command == 'backup-device' and args.output is None:
        parser.error('backup-device requires --output outside the repository for private data')
    output = args.output or Path('/tmp') / ('civilization-qa-' + uuid.uuid4().hex)
    try:
        if output.is_symlink():
            raise ValueError('Existing output aliases cannot be reused')
        output = output.resolve()
        if args.command == 'backup-device' and output.resolve().is_relative_to(REPO):
            raise ValueError('Private device backups must stay outside the repository')
        if args.command == 'validate-saves' and output.resolve().is_relative_to(args.root.resolve()):
            raise ValueError('Reports must be outside the source save directory')
        if args.command == 'compare-saves' and any(output.resolve().is_relative_to(p.resolve()) for p in [args.before, args.after]):
            raise ValueError('Comparison output must be outside both source directories')
        if args.command == 'backup-device' and args.dry_run:
            print(json.dumps({'commands': backup_commands(args, output), 'readOnly': True, 'createsNoFiles': True}, indent=2))
            return 0
        reserve_output(output)
        if args.command == 'test': return run_tests(args, output)
        if args.command == 'validate-saves': return validate_saves(args.root, output)
        if args.command == 'backup-device': return backup_device(args, output)
        result = compare_saves(args.before, args.after, args.allow_new_games)
        (output / 'comparison.json').write_text(json.dumps(result, indent=2) + '\n')
        print('Preserved: ' + str(result['preserved']) + ' → ' + str(output / 'comparison.json'))
        return 0 if result['preserved'] else 1
    except (OSError, ValueError, KeyError, TypeError) as error:
        print('Error: ' + str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
