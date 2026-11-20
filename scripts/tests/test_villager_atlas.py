import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest
import zlib

ROOT=Path(__file__).resolve().parents[2]


def fixture_png(width,height,points):
    """Tiny authored RGBA unit data, never a generated artwork transform."""
    def chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    pixels=bytearray(width*height*4)
    for x,y,alpha in points:pixels[(y*width+x)*4:(y*width+x)*4+4]=bytes([160,120,70,alpha])
    rows=b''.join(b'\0'+pixels[y*width*4:(y+1)*width*4] for y in range(height))
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',width,height,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(rows))+chunk(b'IEND',b'')


class NativeAtlasInspectionTests(unittest.TestCase):
    def inspect(self,width,height,points,columns=2,rows=2):
        with tempfile.TemporaryDirectory(prefix='atlas pixel fixture ') as raw:
            p=Path(raw)/'fixture.png';data=fixture_png(width,height,points);p.write_bytes(data)
            result=subprocess.run(['swift',str(ROOT/'scripts/verify-art.swift'),'--inspect-atlas',str(p),str(columns),str(rows)],cwd=ROOT,capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr[-2000:])
            self.assertEqual(p.read_bytes(),data)
            value=json.loads(result.stdout);self.assertEqual(value['sha256'],hashlib.sha256(data).hexdigest())
            return value

    def test_top_left_cells_threshold_and_gutters_use_actual_rgba(self):
        r=self.inspect(6,6,[(1,1,255),(4,1,33),(1,4,255),(4,4,255),(0,0,32)])
        self.assertEqual((r['columns'],r['rows'],r['alphaThreshold']),(2,2,32))
        self.assertEqual([c['rect'] for c in r['cells']],[[0,0,3,3],[3,0,3,3],[0,3,3,3],[3,3,3,3]])
        self.assertEqual([c['bounds'] for c in r['cells']],[[1,1,1,1]]*4)
        self.assertTrue(all(c['coveredPixels']==1 and c['gutterPixels']==0 and c['coveredEdgePixels']==0 for c in r['cells']))
        self.assertTrue(r['gridSafetyPassed'])

    def test_empty_and_opaque_cells_are_diagnostics_not_success(self):
        empty=self.inspect(6,6,[(1,1,255)])
        self.assertEqual([c['bounds'] for c in empty['cells']],[ [1,1,1,1],None,None,None])
        self.assertFalse(empty['gridSafetyPassed'])
        opaque=self.inspect(6,6,[(x,y,255) for y in range(6) for x in range(6)])
        self.assertEqual(opaque['transparentFraction'],0)
        self.assertTrue(all(c['gutterPixels']>0 and c['coveredEdgePixels']>0 for c in opaque['cells']))
        self.assertFalse(opaque['gridSafetyPassed'])

    def test_odd_dimensions_partition_every_pixel_without_overlap(self):
        r=self.inspect(7,5,[(1,1,255),(4,1,255),(1,3,255),(4,3,255)])
        self.assertEqual([c['rect'] for c in r['cells']],[[0,0,3,2],[3,0,4,2],[0,2,3,3],[3,2,4,3]])
        self.assertEqual(sum(c['rect'][2]*c['rect'][3] for c in r['cells']),35)

import importlib.util
import os
import shutil
import sys
from unittest.mock import patch
SPEC=importlib.util.spec_from_file_location('atlas_gallery',ROOT/'scripts/build-art-gallery.py')
gallery=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(gallery)


class AtlasGalleryIntegrityTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='villager atlas review ');self.addCleanup(self.temp.cleanup)
        self.review=Path(self.temp.name).resolve()/'review'
        shutil.copytree(ROOT/'docs/art/villager-atlas-review',self.review)
        self.output=self.review/'gallery-data.js';self.output.write_bytes(b'previous gallery bytes')

    def receipt(self):return json.loads((self.review/'generation-receipts.json').read_text())
    def write_receipt(self,r): (self.review/'generation-receipts.json').write_text(json.dumps(r))

    def test_all_raw_cells_and_eight_loops_per_candidate_keep_failed_margin_status(self):
        data=gallery.build_villager_atlas(self.review)
        self.assertEqual(len(data['assets']),2)
        for asset in data['assets']:
            self.assertEqual(len(asset['cells']),32)
            self.assertEqual(len(asset['loops']),8)
            self.assertTrue(all(len(loop['frames'])==4 for loop in asset['loops']))
            self.assertEqual(asset['loops'][0]['frames'],[0,1,2,3])
            self.assertEqual(asset['loops'][1]['frames'],[4,5,6,7])
            self.assertFalse(asset['gridSafetyPassed'])
        self.assertEqual(data['proposedRootNormalized'],[.5,.84])
        self.assertFalse(data['registrationCertified']);self.assertFalse(data['perFrameAlignmentApplied'])
        self.assertFalse(data['runtimeIntegrated'])

    def test_asset_prompt_reference_and_measurement_drift_never_publish(self):
        for kind in ['asset','prompt','reference','measurement','concept']:
            with self.subTest(kind=kind):
                r=self.receipt();a=r['records'][0]
                p=self.review/('assets/concept-reference.png' if kind=='concept' else a['file'] if kind=='asset' else a['prompt'] if kind=='prompt' else a['measurement'])
                before=p.read_bytes();original=(self.review/'generation-receipts.json').read_bytes()
                try:
                    if kind=='reference':r['records'][0]['references'][0]['sha256']='0'*64;self.write_receipt(r)
                    else:p.write_bytes(before+b' drift')
                    with self.assertRaises(ValueError):gallery.build_villager_atlas(self.review)
                    self.assertEqual(self.output.read_bytes(),b'previous gallery bytes')
                finally:p.write_bytes(before);(self.review/'generation-receipts.json').write_bytes(original)

    def test_duplicate_native_cell_cannot_hide_behind_updated_report_hash(self):
        r=self.receipt();p=self.review/r['records'][0]['measurement'];m=json.loads(p.read_text())
        m['cells'][-1]=m['cells'][0];p.write_text(json.dumps(m))
        r['records'][0]['measurementSHA256']=gallery.digest(p);self.write_receipt(r)
        with self.assertRaises(ValueError):gallery.build_villager_atlas(self.review)
        self.assertEqual(self.output.read_bytes(),b'previous gallery bytes')

    def test_correction_reference_must_match_original_in_selected_review(self):
        r=self.receipt();first,second=r['records']
        shutil.copyfile(self.review/second['file'],self.review/first['file'])
        shutil.copyfile(self.review/second['measurement'],self.review/first['measurement'])
        first['outputSHA256']=gallery.digest(self.review/first['file'])
        first['measurementSHA256']=gallery.digest(self.review/first['measurement'])
        self.write_receipt(r)
        with self.assertRaises(ValueError):gallery.build_villager_atlas(self.review)
        self.assertEqual(self.output.read_bytes(),b'previous gallery bytes')

    def test_output_alias_and_replace_failure_preserve_previous_bytes(self):
        self.output.unlink();target=self.review/'assets/atlas-v1.png';before=target.read_bytes();self.output.symlink_to(target)
        with self.assertRaises(ValueError):gallery.build_villager_atlas(self.review)
        self.assertEqual(target.read_bytes(),before)
        self.output.unlink();self.output.write_bytes(b'previous gallery bytes')
        with patch.object(gallery.os,'replace',side_effect=OSError('injected atomic replace failure')):
            with self.assertRaises(OSError):gallery.build_villager_atlas(self.review)
        self.assertEqual(self.output.read_bytes(),b'previous gallery bytes')
        self.assertEqual(list(self.review.glob('.atlas-gallery-*')),[])

    def test_optimized_python_fails_closed(self):
        code="import importlib.util;from pathlib import Path;s=importlib.util.spec_from_file_location('g',"+repr(str(ROOT/'scripts/build-art-gallery.py'))+");g=importlib.util.module_from_spec(s);s.loader.exec_module(g);g.build_villager_atlas(Path("+repr(str(self.review))+"))"
        result=subprocess.run([sys.executable,'-O','-c',code],cwd=ROOT,capture_output=True,text=True)
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(self.output.read_bytes(),b'previous gallery bytes')

    def test_hardlinked_input_or_output_is_rejected_without_publication(self):
        target=self.review/'assets/atlas-v1.png';before=target.read_bytes()
        self.output.unlink();gallery.os.link(target,self.output)
        with self.assertRaises(ValueError):gallery.build_villager_atlas(self.review)
        self.assertTrue(self.output.samefile(target));self.assertEqual(target.read_bytes(),before)
        self.output.unlink();self.output.write_bytes(b'previous gallery bytes')
        alias=self.review/'linked-original.png';gallery.os.link(target,alias)
        with self.assertRaises(ValueError):gallery.build_villager_atlas(self.review)
        self.assertEqual(self.output.read_bytes(),b'previous gallery bytes')
        self.assertTrue(alias.samefile(target));self.assertEqual(target.read_bytes(),before)
