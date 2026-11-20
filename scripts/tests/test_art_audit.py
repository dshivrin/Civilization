"""Integration regressions for read-only art evidence and per-kind provenance."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'scripts/verify-art.swift'
MEDIA = ROOT.parent / 'Civilization-Media'


@unittest.skipUnless(shutil.which('swift') and MEDIA.is_dir(), 'requires macOS Swift and local source media')
class ArtAuditTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='art audit regression ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.game = self.root / 'game'
        self.game.mkdir()
        for folder in ['Packages/GameCore/Sources/GameCore/Resources', 'Packages/GameCore/Sources/GameApplication/Resources', 'docs/art', 'Civilization']:
            (self.game / folder).mkdir(parents=True, exist_ok=True)
        for file in ['Packages/GameCore/Sources/GameCore/Resources/seed.json', 'Packages/GameCore/Sources/GameApplication/Resources/art-catalog.json']:
            shutil.copyfile(ROOT / file, self.game / file)
        (self.game / 'Civilization/Art').symlink_to(ROOT / 'Civilization/Art', target_is_directory=True)
        (self.game / 'docs/art/sources').symlink_to(ROOT / 'docs/art/sources', target_is_directory=True)
        self.media = self.root / 'media'
        (self.media / 'registry').mkdir(parents=True)
        shutil.copyfile(MEDIA / 'registry/asset-registry.json', self.media / 'registry/asset-registry.json')
        for folder in ['buildings', 'runtime-exports']:
            (self.media / folder).symlink_to(MEDIA / folder, target_is_directory=True)

    def command(self, output):
        return ['swift', str(SCRIPT), '--audit-output', str(output), '--media-root', str(self.media)]

    def run_audit(self, output):
        return subprocess.run(self.command(output), cwd=self.game, capture_output=True, text=True, timeout=120)

    def test_rejects_media_output_through_symlinked_parent(self):
        alias = self.root / 'media alias'
        alias.symlink_to(self.media, target_is_directory=True)
        output = alias / 'must not write'
        result = self.run_audit(output)
        self.assertNotEqual(result.returncode, 0, 'audit wrote evidence into media source root')
        self.assertFalse(output.exists())

    def test_rejects_wrong_building_export_even_if_both_files_match(self):
        path = self.game / 'Packages/GameCore/Sources/GameApplication/Resources/art-catalog.json'
        catalog = json.loads(path.read_text())
        hut = next(x for x in catalog['buildings'] if x['id'] == 'hut')
        hut['file'] = 'buildings/woodcutter.png'
        path.write_text(json.dumps(catalog))
        result = self.run_audit(self.root / 'wrong-kind output')
        self.assertNotEqual(result.returncode, 0, 'wrong-kind export accepted as hut derivation')

    def test_concurrent_audits_publish_only_one_evidence_directory(self):
        output = self.root / 'shared evidence'
        first = subprocess.Popen(self.command(output), cwd=self.game, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        second = subprocess.Popen(self.command(output), cwd=self.game, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            first.communicate(timeout=120)
            second.communicate(timeout=120)
        finally:
            for child in [first, second]:
                if child.poll() is None:
                    child.kill()
                    child.communicate()
        self.assertEqual(sum(x.returncode == 0 for x in [first, second]), 1, 'concurrent writers both published or both failed')
        self.assertEqual(len(json.loads((output / 'inventory.json').read_text())['buildings']), 20)
