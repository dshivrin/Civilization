import base64
import contextlib
import importlib.util
import io
import json
import shutil
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[2]
SPEC=importlib.util.spec_from_file_location('native_gallery',ROOT/'scripts/build-native-visual-gallery.py')
gallery=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(gallery)


class VillagerCaptureProvenanceTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='native gallery provenance ');self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name).resolve();self.output=self.root/'gallery/captures/run'
        self.sources={};self.ids=[]
        self.names={'phone':'iPhone 17 Pro Max','mini':'iPad mini (A17 Pro)','pro':'iPad Pro 13-inch (M4)'}
        # A valid tiny fixture PNG is unit-test data, never native review evidence.
        png=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6nEIAAAAASUVORK5CYII=')
        for profile,name in self.names.items():
            folder=self.root/profile;folder.mkdir();self.sources[profile]=folder;self.ids.append('sim-'+profile)
            attachments=[]
            for state in gallery.VILLAGER_STATES:
                file=state+'.png';(folder/file).write_bytes(png)
                attachments.append(dict(exportedFileName=file,suggestedHumanReadableName=state+'_0_test.png',
                    deviceId='sim-'+profile,deviceName=name,isAssociatedWithFailure=False,timestamp=1))
            (folder/'manifest.json').write_text(json.dumps([dict(testIdentifier='RelocationUITests/testVillagerMotionReviewStatesAndStaticFallback()',attachments=attachments)]))
            shutil.copytree(folder,self.root/('passed-'+profile+'.xcresult'))
        self.report=self.root/'qa-report.json'
        self.report.write_text(json.dumps(dict(status='passed',scope=dict(suite='ui',configuration='debug',simulator=self.ids,
            only_testing=['CivilizationUITests/RelocationUITests/testVillagerMotionReviewStatesAndStaticFallback']),
            steps=[dict(name='ui-debug-'+str(i+1),status='passed',exitCode=0,tests=1,
                command=['xcodebuild','-resultBundlePath',str(self.root/('passed-'+profile+'.xcresult'))])
                for i,profile in enumerate(self.names)])))

    def fake_export(self,command,**kwargs):
        shutil.copytree(Path(command[command.index('--path')+1]),Path(command[command.index('--output-path')+1]))

    def run_builder(self,sources=None,with_report=False,render_only=False,profile_reports=None):
        args=['build-native-visual-gallery.py','--villagers','--output',str(self.output)]
        if render_only:args+=['--render-only']
        else:
            for profile,folder in (sources or self.sources).items():args+=['--capture',profile+'='+str(folder)]
        if with_report:args+=['--qa-report',str(self.report)]
        for profile,report in (profile_reports or {}).items():args+=['--profile-report',profile+'='+str(report)]
        with patch.object(gallery,'GALLERY',self.root/'gallery'),patch.object(sys,'argv',args),contextlib.redirect_stdout(io.StringIO()),patch.object(gallery.subprocess,'run',self.fake_export):
            gallery.main()

    def test_one_phone_cannot_be_relabelled_as_three_profiles(self):
        with self.assertRaises((ValueError,SystemExit)):
            self.run_builder({p:self.sources['phone'] for p in self.sources},with_report=True)
        self.assertFalse(self.output.exists())

    def test_distinct_folders_cannot_relabel_phone_metadata_as_mini(self):
        p=self.sources['mini']/'manifest.json';records=json.loads(p.read_text())
        for a in records[0]['attachments']:a['deviceName']=self.names['phone'];a['deviceId']='sim-phone'
        p.write_text(json.dumps(records))
        with self.assertRaises((ValueError,SystemExit)):self.run_builder(with_report=True)
        self.assertFalse(self.output.exists())

    def test_passed_product_report_and_distinct_devices_are_preserved(self):
        self.run_builder(with_report=True)
        records=json.loads((self.output/'manifest.json').read_text())
        self.assertEqual(len(records),24)
        self.assertEqual({r['deviceID'] for r in records},set(self.ids))
        self.assertTrue(all(r['qaReportSHA256']==gallery.digest(self.report) for r in records))
        self.run_builder(render_only=True)

    def test_failed_report_or_missing_motion_case_cannot_publish(self):
        original=json.loads(self.report.read_text())
        for change in ['failed','missing-case']:
            with self.subTest(change=change):
                r=json.loads(json.dumps(original))
                if change=='failed':r['status']='failed';r['steps'][0]['status']='failed';r['steps'][0]['exitCode']=65
                else:r['scope']['only_testing']=['CivilizationUITests/NormalEntryUITests']
                self.report.write_text(json.dumps(r))
                with self.assertRaises((ValueError,SystemExit)):self.run_builder(with_report=True)
                self.assertFalse(self.output.exists())

    def test_images_from_another_run_cannot_borrow_a_passed_report(self):
        p=self.sources['phone']/(gallery.VILLAGER_STATES[0]+'.png')
        p.write_bytes(p.read_bytes()+b'other-run')
        with self.assertRaises(ValueError):self.run_builder(with_report=True)
        self.assertFalse(self.output.exists())

    def test_passed_device_steps_keep_failed_aggregate_and_genuine_retry_reports(self):
        r=json.loads(self.report.read_text());r['status']='failed';r['steps'][1].update(status='failed',tests=0)
        self.report.write_text(json.dumps(r))
        retry=self.root/'mini-retry.json'
        fixed=json.loads(json.dumps(r));fixed['status']='passed';fixed['scope']['simulator']=['sim-mini']
        fixed['steps']=[dict(r['steps'][1],name='ui-debug-1',status='passed',tests=1)]
        retry.write_text(json.dumps(fixed))
        self.run_builder(profile_reports={'phone':self.report,'mini':retry,'pro':self.report})
        records=json.loads((self.output/'manifest.json').read_text())
        self.assertEqual(len(records),24)
        self.assertEqual({x['qaReportOverallStatus'] for x in records},{'failed','passed'})
        self.assertTrue(all(x['qaEvidenceScope']=='passed-device-step' for x in records))
        self.assertEqual((self.output/'qa-reports'/(gallery.digest(self.report)+'.json')).read_bytes(),self.report.read_bytes())
        self.run_builder(render_only=True)

    def test_zero_device_step_cannot_borrow_a_different_devices_pass(self):
        r=json.loads(self.report.read_text());r['status']='failed';r['steps'][1].update(status='failed',tests=0)
        self.report.write_text(json.dumps(r))
        with self.assertRaises((ValueError,SystemExit)):
            self.run_builder(profile_reports={p:self.report for p in self.sources})
        self.assertFalse(self.output.exists())
