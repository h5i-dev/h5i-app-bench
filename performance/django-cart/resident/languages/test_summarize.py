import csv
import json
from pathlib import Path
import tempfile
import unittest
from summarize import summarize, SMOKE, VARIANTS

class ValidationTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.root=Path(self.tmp.name);(self.root/'raw').mkdir()
        counts={'32':166,'128':190,'512':214,'2048':238}
        (self.root/'conformance.json').write_text(json.dumps({v:counts for v in VARIANTS}))
        for cap,n in counts.items():
            for v in VARIANTS:(self.root/'raw'/f'gate-{cap}-{v}.csv').write_text(f'{v},0,0,1,2,{n},123\n')
        self.check=(1<<60)+1
        (self.root/'expected_checksums.json').write_text(json.dumps({f'{n}-{c}-{f}':[self.check]*58 for n,c,f in SMOKE}))
        self.rows=[]
        for n,c,f in SMOKE:
            for vi,v in enumerate(VARIANTS):
                for rep in range(3):
                    for r in range(58):self.rows.append([n,c,f,v,rep,r,100+vi+rep,2,n,self.check])
        self.write()
    def write(self):
        with (self.root/'rounds.csv').open('w') as f:
            w=csv.writer(f);w.writerow(['carts','lines','factor','variant','repeat','round','total_us','init_ms','checked_totals','checksum']);w.writerows(self.rows)
    def test_complete_and_integer_checksums(self):
        data=summarize(self.root,smoke=True)
        self.assertEqual(data['rounds'],6786);self.assertEqual(data['checked_totals'],434304)
        t=data['points'][0]['timings'][0];self.assertEqual(t['mean_us'],101);self.assertEqual(t['stdev_us'],1)
    def test_missing_duplicate_and_wrong_exact_values(self):
        original=list(self.rows)
        for rows in [original[:-1],original+[original[0]],[[*original[0][:-1],self.check-1],*original[1:]]]:
            self.rows=rows;self.write()
            with self.assertRaises(ValueError):summarize(self.root,smoke=True)
    def test_invalid_timing_and_gate(self):
        self.rows[0][6]=float('nan');self.write()
        with self.assertRaises(ValueError):summarize(self.root,smoke=True)
        self.rows[0][6]=100;self.write()
        (self.root/'raw'/f'gate-32-{VARIANTS[0]}.csv').write_text(f'{VARIANTS[0]},0,0,1,2,166,124\n')
        with self.assertRaises(ValueError):summarize(self.root,smoke=True)

if __name__=='__main__':unittest.main()
