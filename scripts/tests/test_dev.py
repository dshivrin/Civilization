import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location('civilization_dev', Path(__file__).resolve().parents[1] / 'dev.py')
dev = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(dev)


class ReusableToolsTests(unittest.TestCase):
    def test_earned_simulator_identity_cannot_target_production_or_arbitrary_bundles(self):
        identity = "99D22CAE-0EB6-4B68-9B72-CF580DA6F222"
        self.assertEqual(dev.earned_bundle_id(identity), "com.civilization.seed.qa.earned." + identity.lower())
        for invalid in ["com.civilization.seed", "../save", "", "not-a-uuid"]:
            with self.assertRaises(ValueError): dev.earned_bundle_id(invalid)


    def test_earned_preparation_refuses_an_existing_qa_identity_before_install(self):
        from argparse import Namespace
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as folder:
            fixture = Path(folder) / 'fixture'; fixture.mkdir()
            (fixture / 'qa-earned.json').write_text(json.dumps({'synthetic': True, 'grants': False, 'debugCommands': False}))
            (fixture / 'settlement-v1.json').write_text('{}')
            (fixture / 'games-index.json').write_text('{}')
            args = Namespace(qa_identity='99D22CAE-0EB6-4B68-9B72-CF580DA6F222', fixture=fixture, simulator='synthetic-simulator')
            with patch.object(dev, 'run_step', return_value={'status': 'passed'}) as steps, patch.object(dev.subprocess, 'run', return_value=Namespace(returncode=0)) as process:
                with self.assertRaisesRegex(ValueError, 'already exists'):
                    dev.prepare_earned_simulator(args, Path(folder))
            self.assertEqual(steps.call_count, 1)
            self.assertEqual(process.call_args.args[0][2], 'get_app_container')

    def test_zero_tests_and_failed_exit_never_pass(self):
        self.assertEqual(dev.test_count('✔ Test run with 189 tests in 0 suites passed after 16 seconds.'), 189)
        self.assertEqual(dev.test_count('Executed 3 tests, with 0 failures (0 unexpected) in 1 second'), 3)
        self.assertFalse(dev.test_passed(0, 'Test run with 0 tests passed'))
        self.assertFalse(dev.test_passed(1, 'Test run with 3 tests passed'))
        self.assertFalse(dev.test_passed(0, 'Executed 3 tests, with 1 failure'))
        self.assertFalse(dev.test_passed(0, 'build succeeded'))
        self.assertFalse(dev.test_passed(0, 'Test run with 3 tests failed'))
        self.assertTrue(dev.test_passed(0, '✔ Test run with 3 tests in 0 suites passed'))

    def test_artifact_directory_never_clobbers_even_empty_existing_directory(self):
        with tempfile.TemporaryDirectory(prefix='tools with spaces ') as folder:
            output = Path(folder) / 'run evidence'
            dev.reserve_output(output)
            (output / 'keep').write_text('original')
            with self.assertRaises(FileExistsError):
                dev.reserve_output(output)
            self.assertEqual((output / 'keep').read_text(), 'original')

    def test_strict_comparison_rejects_changes_and_additive_mode_retains_old_entries(self):
        with tempfile.TemporaryDirectory() as folder:
            before, after = Path(folder) / 'before', Path(folder) / 'after'
            for root in (before, after):
                root.mkdir()
                (root / 'settlement-v1.json').write_bytes(b'original normal')
                (root / 'settlement-v1.json.developer').write_bytes(b'original developer')
                (root / 'games-index.json').write_text(json.dumps({'version': 1, 'activeGameID': 'legacy', 'games': [{'id': 'legacy', 'name': 'Original', 'mapID': 'map'}]}))
            self.assertTrue(dev.compare_saves(before, after)['preserved'])
            index = json.loads((after / 'games-index.json').read_text())
            index['games'].append({'id': 'new', 'name': 'New', 'mapID': 'map'})
            index['activeGameID'] = 'new'
            (after / 'games-index.json').write_text(json.dumps(index))
            (after / 'new-file').write_bytes(b'new')
            self.assertFalse(dev.compare_saves(before, after)['preserved'])
            self.assertTrue(dev.compare_saves(before, after, allow_new_games=True)['preserved'])
            (after / 'settlement-v1.json.developer').write_bytes(b'changed')
            self.assertFalse(dev.compare_saves(before, after, allow_new_games=True)['preserved'])
            (after / 'settlement-v1.json.developer').write_bytes(b'original developer')
            index['games'][0]['name'] = 'silently changed'
            (after / 'games-index.json').write_text(json.dumps(index))
            self.assertFalse(dev.compare_saves(before, after, allow_new_games=True)['preserved'])

    def test_empty_or_symlink_source_never_proves_preservation(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            before, after = root / 'before', root / 'after'
            before.mkdir(); after.mkdir()
            with self.assertRaises(ValueError):
                dev.compare_saves(before, after)
            (before / 'alias').symlink_to(root)
            with self.assertRaises(ValueError):
                dev.manifest(before)

    def test_run_step_reports_failure_and_preserves_exact_argv(self):
        import sys
        with tempfile.TemporaryDirectory(prefix='evidence with spaces ') as folder:
            result = dev.run_step('failing step', [sys.executable, '-c', 'print("Test run with 0 tests passed"); raise SystemExit(7)'], Path(folder), require_tests=True)
            self.assertEqual(result['exitCode'], 7)
            self.assertEqual(result['status'], 'failed')
            self.assertEqual(result['tests'], 0)
            self.assertTrue(Path(result['log']).exists())

    def test_backup_dry_run_does_not_touch_device_or_create_output(self):
        from contextlib import redirect_stdout
        from io import StringIO
        from unittest.mock import patch
        with tempfile.TemporaryDirectory(prefix='backup plan ') as folder:
            output = Path(folder) / 'private copy'
            text = StringIO()
            with patch.object(dev, 'run_step', side_effect=AssertionError('Device access forbidden')), redirect_stdout(text):
                code = dev.main(['backup-device', '--device', 'device-id', '--bundle', 'com.example.game', '--output', str(output), '--dry-run'])
            self.assertEqual(code, 0)
            self.assertFalse(output.exists())
            commands = json.loads(text.getvalue())['commands']
            self.assertEqual(len(commands), 3)
            self.assertIn(str(output.resolve() / 'data' / 'Civilization'), commands[0])
            self.assertIn('com.example.game', commands[0])
            self.assertNotIn('install', commands[0])

    def test_native_selections_cannot_silently_drop_a_misspelled_case(self):
        log = "Test Case '-[CivilizationUITests.NormalEntryUITests testEntry]' started.\nExecuted 1 test, with 0 failures"
        requested = ['CivilizationUITests/NormalEntryUITests/testEntry', 'CivilizationUITests/NormalEntryUITests/testMisspelled']
        self.assertEqual(dev.missing_native_selections(log, requested), [requested[1]])
        self.assertEqual(dev.missing_native_selections(log, ['CivilizationUITests/NormalEntryUITests']), [])

    def test_interrupt_stops_matrix_instead_of_starting_another_configuration(self):
        from argparse import Namespace
        from unittest.mock import patch
        args = Namespace(command='test', suite='core', configuration='both', filter=None, simulator=[], only_testing=[], output=None)
        with tempfile.TemporaryDirectory() as folder:
            step = {'name': 'core-debug', 'command': ['swift', 'test'], 'exitCode': 130, 'status': 'failed', 'tests': 0, 'durationSeconds': 0, 'log': str(Path(folder) / 'interrupted.log')}
            with patch.object(dev, 'run_step', return_value=step) as run, patch.object(dev, 'revision', return_value={'commit': 'test', 'dirty': False}):
                code = dev.run_tests(args, Path(folder))
            self.assertEqual(code, 1)
            self.assertEqual(run.call_count, 1)
            self.assertTrue(json.loads((Path(folder) / 'report.json').read_text())['scope']['cancelled'])

    def test_dangling_output_alias_is_rejected_without_creating_its_target(self):
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as folder:
            target = Path(folder) / 'must-not-create'
            alias = Path(folder) / 'existing-alias'
            alias.symlink_to(target, target_is_directory=True)
            with patch.object(dev, 'run_tests', return_value=0) as run:
                code = dev.main(['test', '--configuration', 'debug', '--output', str(alias)])
            self.assertEqual(code, 1)
            self.assertFalse(target.exists())
            self.assertEqual(run.call_count, 0)

    def test_real_child_sigint_is_recorded_without_escaping_step(self):
        import sys
        with tempfile.TemporaryDirectory() as folder:
            step = dev.run_step('interrupted', [sys.executable, '-c', 'import os,signal,time; os.kill(os.getppid(), signal.SIGINT); time.sleep(2)'], Path(folder), require_tests=True)
            self.assertEqual(step['exitCode'], 130)
            self.assertEqual(step['status'], 'failed')


if __name__ == '__main__':
    unittest.main()
