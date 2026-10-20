import csv
import importlib.util
import itertools
import json
from pathlib import Path
import tempfile
import unittest

spec=importlib.util.spec_from_file_location('phase_summary',Path(__file__).with_name('summarize.py'))
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class PublicationTest(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        gates={str(c):dict(decimal_cases=n,variants=7) for c,n in zip([32,128,512,2048],[166,190,214,238])}
        (self.root/'conformance.json').write_text(json.dumps(gates))
        self.rows=[]
        for (n,cap,f),rep,(v,mode),r in itertools.product(m.SHAPES,range(3),m.MODES,range(58)):
            values=dict.fromkeys(m.METRICS,0)
            values['total_us']=60+rep
            if mode!='plain':
                for key in m.HOST:values[key]=10
                values['upload_us']+=rep
            if mode=='events':values['device_update_or_fused_us']=8
            self.rows.append(dict(carts=n,lines=cap,updates=n*f,repeat=rep,variant=v,mode=mode,round=r,warmup=str(r<8).lower(),checked_totals=n,command_bytes=(n+n*f*4)*8,result_bytes=n*8,checksum=2**60+1,**values))
    def write(self,rows):
        with (self.root/'rounds.csv').open('w') as f:
            w=csv.DictWriter(f,fieldnames=self.rows[0]);w.writeheader();w.writerows(rows)
    def test_complete_and_repetition_variance(self):
        self.write(self.rows);d=m.summarize(self.root)
        self.assertEqual(d['rounds'],4872)
        self.assertEqual(d['checked_totals'],244457472)
        self.assertEqual(d['points'][0]['modes'][0]['timings']['total_us'],dict(mean=61,stdev=1))
    def test_rejects_incomplete_duplicate_wrong_checksum_or_phase(self):
        for rows in [self.rows[:-1],self.rows+[self.rows[0]]]:
            self.write(rows)
            with self.assertRaises(ValueError):m.summarize(self.root)
        for field,value in [('checksum',2**60+2),('command_bytes',1),('checked_totals',1),('warmup','false'),('total_us',float('nan')),('device_scan_us',1)]:
            rows=[dict(r) for r in self.rows];rows[0][field]=value;self.write(rows)
            with self.subTest(field=field),self.assertRaises(ValueError):m.summarize(self.root)
        rows=[dict(r) for r in self.rows];next(r for r in rows if r['mode']=='host')['upload_us']=20
        self.write(rows)
        with self.assertRaises(ValueError):m.summarize(self.root)
    def test_rejects_missing_upstream_gate(self):
        self.write(self.rows);(self.root/'conformance.json').write_text('{}')
        with self.assertRaises(ValueError):m.summarize(self.root)

if __name__=='__main__':unittest.main()
