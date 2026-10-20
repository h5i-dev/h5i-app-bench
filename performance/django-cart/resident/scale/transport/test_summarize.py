import csv
import importlib.util
import itertools
import json
from pathlib import Path
import tempfile
import unittest

spec=importlib.util.spec_from_file_location('transport_summary',Path(__file__).with_name('summarize.py'))
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class PublicationTest(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        gates={str(c):dict(decimal_cases=n,variants=17) for c,n in zip([32,128,512,2048],[166,190,214,238])}
        (self.root/'conformance.json').write_text(json.dumps(gates))
        self.rows=[]
        for (n,cap,f),rep,(v,mode),r in itertools.product(m.SHAPES,range(3),m.MODES,range(58)):
            values=dict.fromkeys(m.METRICS,0);values['total_us']=(100 if v.startswith('cpu') else 50 if v.endswith('-pageable') else 25)+rep
            if 'compact' in v or 'pinned' in v:values['encoding_us']=5
            if mode=='events':values['event_upload_us']=8;values['event_kernels_us']=10
            if mode=='events' and 'pinned' in v:values['event_download_us']=2
            self.rows.append(dict(carts=n,lines=cap,updates=n*f,repeat=rep,variant=v,mode=mode,round=r,warmup=str(r<8).lower(),checked_totals=n,
                source_bytes=(n+n*f*4)*8,command_bytes=0 if v.startswith('cpu') else (n+n*f*(1 if 'compact' in v else 4))*8,
                result_bytes=n*8,checksum=2**60+1,init_ms=1,**values))
    def write(self,rows):
        with (self.root/'rounds.csv').open('w') as f:
            w=csv.DictWriter(f,fieldnames=self.rows[0]);w.writeheader();w.writerows(rows)
    def test_complete_ratios_bytes_and_variance(self):
        self.write(self.rows);d=m.summarize(self.root)
        self.assertEqual(d['rounds'],16008)
        self.assertEqual(d['checked_totals'],803217408)
        p=d['points'][0]
        self.assertAlmostEqual(p['ratio'],101/26)
        self.assertAlmostEqual(p['speedup_vs_legacy'],51/26)
        r=next(x for x in p['modes'] if x['variant']=='gpu-delta-compact-pinned' and x['mode']=='plain')
        self.assertEqual(r['command_bytes'],557056)
        self.assertEqual(r['timings']['total_us']['stdev'],1)
    def test_rejects_incomplete_duplicate_checksum_bytes_and_timing(self):
        for rows in [self.rows[:-1],self.rows+[self.rows[0]]]:
            self.write(rows)
            with self.assertRaises(ValueError):m.summarize(self.root)
        for field,value in [('checksum',2**60+2),('command_bytes',1),('source_bytes',1),('result_bytes',1),('checked_totals',1),('warmup','false'),('total_us',float('nan')),('encoding_us',999),('init_ms',-1),('event_upload_us',1)]:
            rows=[dict(r) for r in self.rows];rows[0][field]=value;self.write(rows)
            with self.subTest(field=field),self.assertRaises(ValueError):m.summarize(self.root)
        rows=[dict(r) for r in self.rows];rows[0]['init_ms']=2;self.write(rows)
        with self.assertRaises(ValueError):m.summarize(self.root)
    def test_rejects_missing_gate(self):
        self.write(self.rows);(self.root/'conformance.json').write_text('{}')
        with self.assertRaises(ValueError):m.summarize(self.root)

if __name__=='__main__':unittest.main()
