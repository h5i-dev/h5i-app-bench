import csv
import importlib.util
import itertools
import json
from pathlib import Path
import tempfile
import unittest

spec=importlib.util.spec_from_file_location('scale_summary',Path(__file__).with_name('summarize.py'))
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class ScalePublicationTest(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.gates={str(cap):dict(decimal_cases=count,variants=7) for cap,count in zip([32,128,512,2048],[166,190,214,238])}
        (self.root/'conformance.json').write_text(json.dumps(self.gates))
        self.rows=[]
        for impl,cap,n,factor,rep in itertools.product(m.IMPLS,m.CAPS,m.POPULATIONS,m.FACTORS,range(3)):
            u=n*factor
            self.rows.append(dict(impl=impl,lines=cap,carts=n,queries=n,updates=u,repeat=rep,iterations=50,checked_totals=n*58,mean_us=10+rep,p50_us=9+rep,p99_us=15+rep,init_ms=1,input_bytes=n*(2*cap+3)*8,command_bytes=(n+u*4)*8,result_bytes=n*8,checksum=2**60))
    def write(self,rows):
        with (self.root/'points.csv').open('w') as f:
            w=csv.DictWriter(f,fieldnames=self.rows[0]);w.writeheader();w.writerows(rows)
    def test_complete(self):
        for r in self.rows:
            if r['impl']=='cpu-delta-4':r['mean_us']=5+r['repeat'];r['p50_us']=4+r['repeat']
            if r['impl']=='gpu-delta':r['mean_us']=2+r['repeat'];r['p50_us']=1+r['repeat']
        self.write(self.rows);data=m.summarize(self.root)
        self.assertEqual(data['measurement_points'],378);self.assertEqual(len(data['points']),18)
        self.assertEqual(data['points'][0]['timings']['cpu-delta-4']['stdev_us'],1)
        self.assertEqual(data['checked_totals'],sum(r['checked_totals'] for r in self.rows))
        self.assertEqual(data['points'][0]['ratio'],2)
        self.assertEqual(data['points'][0]['best_cpu'],'cpu-delta-4')
        self.assertEqual(data['points'][0]['best_gpu'],'gpu-delta')
    def test_invalid(self):
        for field,value in [('checksum',2**60+1),('carts',1),('updates',4097),('queries',1),('iterations',100),('command_bytes',1),('input_bytes',1),('result_bytes',1),('checked_totals',1),('mean_us',float('nan')),('p99_us',0)]:
            with self.subTest(field=field):
                rows=[dict(r) for r in self.rows];rows[0][field]=value;self.write(rows)
                with self.assertRaises(ValueError):m.summarize(self.root)
        for rows in [self.rows[:-1],self.rows+[self.rows[0]]]:
            self.write(rows)
            with self.assertRaises(ValueError):m.summarize(self.root)
    def test_upstream_gate(self):
        self.write(self.rows);self.gates['2048']['variants']=5
        (self.root/'conformance.json').write_text(json.dumps(self.gates))
        with self.assertRaises(ValueError):m.summarize(self.root)

if __name__=='__main__':unittest.main()
