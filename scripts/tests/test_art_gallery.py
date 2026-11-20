import importlib.util
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[2]
SPEC=importlib.util.spec_from_file_location('art_gallery',ROOT/'scripts/build-art-gallery.py')
gallery=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gallery)


class RiverVisualFixtureTests(unittest.TestCase):
    def test_all_seven_crossings_have_real_land_and_contiguous_water(self):
        config=json.loads((ROOT/'Packages/GameCore/Sources/GameCore/Resources/seed.json').read_text())
        rows=config['map']['rows']
        fixtures=json.loads((ROOT/'docs/art/building-gate-1/evidence/river-fixtures.json').read_text())['fixtures']
        self.assertEqual(len(fixtures),7)
        axes=set()
        for fixture in fixtures:
            c=gallery.crossing(rows,fixture)
            a,b=c['landEnds']; axes.add(c['axis'])
            self.assertIn(rows[a[1]][a[0]],'.c'); self.assertIn(rows[b[1]][b[0]],'.c')
            dx=1 if c['axis']=='x' else 0; dy=1-dx
            self.assertEqual(c['waterTiles'],2)
            for step in range(1,c['waterTiles']+1): self.assertEqual(rows[a[1]+dy*step][a[0]+dx*step],'w')
            self.assertEqual([a[0]+dx*c['lengthInTiles'],a[1]+dy*c['lengthInTiles']],b)
        self.assertEqual(axes,{'x','y'})

    def test_visual_crossing_rejects_far_bank_forest(self):
        fixture={'id':'blocked-bank','bankEdges':[{'water':[2,0],'land':[1,0]}]}
        with self.assertRaises(ValueError): gallery.crossing(['..wff'],fixture)

    def test_visual_crossing_rejects_open_map_edge(self):
        fixture={'id':'open-water','bankEdges':[{'water':[2,0],'land':[1,0]}]}
        with self.assertRaises(ValueError): gallery.crossing(['..www'],fixture)


class GalleryProvenanceTests(unittest.TestCase):
    def setUp(self):
        import tempfile, shutil
        self.temp=tempfile.TemporaryDirectory(prefix='gallery provenance ')
        self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name)
        self.old_root,self.old_review=gallery.ROOT,gallery.REVIEW
        self.addCleanup(self.restore)
        gallery.ROOT=self.root; gallery.REVIEW=self.root/'docs/art/building-gate-2'
        for relative in ['Packages/GameCore/Sources/GameCore/Resources/seed.json',
                         'docs/art/building-gate-1/evidence/inventory.json',
                         'docs/art/building-gate-1/evidence/river-fixtures.json',
                         'docs/art/building-gate-2/measurements.jsonl',
                         'docs/art/building-gate-2/generation-receipts.json']:
            target=self.root/relative; target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/relative,target)
        shutil.copytree(ROOT/'docs/art/building-gate-2/prompts',gallery.REVIEW/'prompts')
        (gallery.REVIEW/'assets').symlink_to(ROOT/'docs/art/building-gate-2/assets',target_is_directory=True)
        for relative in ['docs/art/sources/buildings','Civilization/Art/buildings']:
            folder=self.root/relative;folder.mkdir(parents=True,exist_ok=True)
            for path in (ROOT/relative).glob('*.png'): (folder/path.name).symlink_to(path)

    def restore(self):
        gallery.ROOT,self.old_root=self.old_root,gallery.ROOT
        gallery.REVIEW,self.old_review=self.old_review,gallery.REVIEW

    def test_prompt_tamper_is_rejected(self):
        path=gallery.REVIEW/'prompts/hut-l1.txt';path.write_text(path.read_text()+' changed')
        with self.assertRaises(AssertionError):gallery.build()

    def test_reference_tamper_is_rejected(self):
        path=self.root/'docs/art/sources/buildings/hut.png';path.unlink();path.write_bytes(b'changed reference')
        with self.assertRaises(AssertionError):gallery.build()

    def test_shipped_original_tamper_is_rejected(self):
        path=self.root/'Civilization/Art/buildings/hut.png';path.unlink();path.write_bytes(b'changed shipped sprite')
        with self.assertRaises(AssertionError):gallery.build()


class FishingFacingDisclosureTests(unittest.TestCase):
    def test_every_fixture_declares_selected_pose_support(self):
        data=json.loads((ROOT/'docs/art/building-gate-2/manifest.json').read_text())
        by_id={f['id']:f for f in data['fixtures']}
        self.assertIn('fishingPoseStudy',by_id['west-bank'])
        self.assertEqual(by_id['west-bank']['fishingPoseStudy']['1']['status'],'uncertified-nominal-match')
        self.assertEqual(by_id['east-bank']['fishingPoseStudy']['1']['status'],'unsupported-facing')
        self.assertEqual(by_id['east-bank']['fishingPoseStudy']['opposite']['status'],'uncertified-nominal-match')
        self.assertEqual(by_id['horizontal-north']['fishingPoseStudy']['1']['status'],'unsupported-quarter-turn')
        self.assertEqual(by_id['bend']['fishingPoseStudy']['1']['status'],'edge-choice-required')
