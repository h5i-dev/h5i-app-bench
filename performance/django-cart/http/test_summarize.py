"""Publishing must fail closed on missing, duplicate, failed or unaccounted work."""
import csv
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec=importlib.util.spec_from_file_location('cart_http_summary',Path(__file__).with_name('summarize.py'))
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)

class PublicationTests(unittest.TestCase):
    def fixture(self,root):
        config=dict(variants=['rust-gpu-batch'],carts=[4096],concurrency=[16],repeats=2,duration=5,warmup=1,lines=32)
        (root/'environment.json').write_text(json.dumps({'config':config}))
        (root/'conformance.json').write_text(json.dumps({'rust-gpu-batch':dict(decimal_cases=4146,freshness_updates=2,error_status_cases=3)}))
        rows=[]
        for rep in range(2):
            rows.append(dict(impl='rust-gpu-batch',scenario='total_4096',concurrency=16,repeat=rep,**dict.fromkeys(module.METRICS,1),checks_failed=0,server_requests=100,max_batch_since_start=16))
            rows[-1].update(errors=0,http_requests=100,batches=10,sql_queries=10,gpu_launches=10,mean_batch=10,rps=100+rep*20)
        return rows
    def write(self,root,rows):
        with (root/'points.csv').open('w') as f:
            writer=csv.DictWriter(f,fieldnames=rows[0]);writer.writeheader();writer.writerows(rows)
    def test_complete_means_and_reject_corruption(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);rows=self.fixture(root);self.write(root,rows)
            self.assertEqual(module.summarize(root)[0]['rps'],110)
            for key,value in [('errors',1),('checks_failed',1),('server_requests',99),('gpu_launches',9),('sql_queries',9),('mean_batch',9),('rps',float('nan')),('max_batch_since_start',257)]:
                broken=[dict(r) for r in rows];broken[0][key]=value;self.write(root,broken)
                with self.subTest(key=key),self.assertRaises(ValueError):module.summarize(root)
            self.write(root,rows[:1])
            with self.assertRaisesRegex(ValueError,'incomplete'):module.summarize(root)
            self.write(root,[*rows,rows[0]])
            with self.assertRaisesRegex(ValueError,'duplicate'):module.summarize(root)

if __name__=='__main__':unittest.main()
