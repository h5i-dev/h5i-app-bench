"""HTTP/SQL/CPU/CUDA line-count sweep, with a fixed cart population."""
import argparse
import concurrent.futures
import csv
import hashlib
import http.client
import importlib.util
import json
import os
from pathlib import Path
import random
import subprocess
import time
import urllib.request

HERE=Path(__file__).resolve().parent
APP=HERE.parents[1]
spec=importlib.util.spec_from_file_location('cart_http',HERE.parent/'run.py')
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
VARIANTS={
 'go-sql':('go','sql',1,0),'javascript-sql':('node','sql',1,0),'rust-sql':('rust','sql',1,0),
 'go-batch':('go','batch',256,1000),'javascript-batch':('node','batch',256,1000),
 'rust-cpu-batch':('rust','batch',256,1000),'rust-cpu-parallel':('rust','parallel',256,1000),
 'rust-gpu-batch':('rust','gpu',256,1000),'rust-gpu-cooperative':('rust','gpu-cooperative',256,1000),
}
FIELDS=['impl','scenario','lines','carts','concurrency','repeat','rps','p50_ms','p90_ms','p99_ms','errors','checks_failed','http_requests','server_requests','batches','sql_queries','gpu_launches','cart_rows','mean_batch','mean_queue_wait_ms','max_batch_since_start','rss_peak_mb','cpu_peak_pct','sql_fetch_ms_per_batch','pack_ms_per_batch','compute_ms_per_batch']

class Bench(base.Bench):
 def __init__(self,args):
  super().__init__(args);self.cap=args.line_counts[0]
 def start_db(self):
  super().start_db()
  self.sql('ALTER TABLE cart_bench_item DROP CONSTRAINT cart_bench_item_slot_check; ALTER TABLE cart_bench_item ADD CHECK(slot BETWEEN 0 AND 2047);')
  metadata=json.loads((self.out/'environment.json').read_text())
  metadata['oracle_sha256']=base.digest(self.args.oracle)
  metadata['experiment']='line-count sweep; fixed carts, fresh inputs per batch'
  metadata['source_sha256'].update({str(p.relative_to(APP)):base.digest(p) for p in [HERE/'run.py',HERE/'oracle.py',HERE/'load.js',APP/'go/server_lines.go',APP/'javascript/server_lines.mjs',APP/'rust-h5i-gpu/src/wide.rs',APP/'rust-h5i-gpu/src/lib.rs',APP/'rust-h5i-gpu/backend-nvvm/examples/serve_lines.rs']})
  metadata['note']='Nine read-only adapters, fixed cart count, one SQL batch worker. Rust parallel CPU uses four Rayon workers; cooperative CUDA uses a 32-thread warp/block per cart. Fresh allocation and transfer each batch; no resident input cache. Rust batch phase times cover fetch/decode, packing and CPU or complete CUDA stage, excluding HTTP/queue.'
  (self.out/'environment.json').write_text(json.dumps(metadata,indent=2)+'\n')
 def start(self,name,label):
  language,mode,limit,wait=VARIANTS[name]
  cmd={'go':[self.args.go,'serve'],'node':[self.args.node,str(APP/'javascript/server_lines.mjs')],'rust':[self.args.rust]}[language]
  env={**os.environ,'DATABASE_URL':self.url,'PORT':str(self.http_port),'MODE':mode,'BATCH_MAX':str(limit),'BATCH_WAIT_US':str(wait),'PTX':self.args.ptx,'CUDA_VISIBLE_DEVICES':'0','LD_LIBRARY_PATH':'/usr/local/cuda-12.6/lib64','GOMAXPROCS':'4','CART_LINES':str(self.cap)}
  self.log=(self.work/f'{label}-{name}-server.log').open('w')
  self.server=subprocess.Popen(['taskset','-c',self.args.server_cpus,*cmd],env=env,stdout=self.log,stderr=subprocess.STDOUT)
  for _ in range(200):
   if self.server.poll() is not None:raise RuntimeError(f'{name} failed: {self.log.name}')
   try:
    with urllib.request.urlopen(self.base+'/health',timeout=.3) as r:
     if r.status==200:return
   except OSError:pass
   time.sleep(.05)
  raise RuntimeError(f'{name} startup timeout')
 def oracle(self):
  fixtures=json.loads(Path(self.args.oracle).read_text());report={}
  for cap in self.args.line_counts:
   self.cap=cap;corpus=fixtures[str(cap)];cases=corpus['cases']
   carts=[];items=[]
   for i,c in enumerate(cases,1000001):
    carts.append(f"{i}\t{c['kind']}\t{c['value']}\n")
    for j,(p,q) in enumerate(zip(c['prices'],c['quantities'])):items.append(f'{i}\t{j}\t{p}\t{q}\n')
   self.sql('TRUNCATE cart_bench_item,cart_bench_cart; COPY cart_bench_cart FROM STDIN;\n'+''.join(carts)+'\\.\nCOPY cart_bench_item FROM STDIN;\n'+''.join(items)+'\\.\nANALYZE cart_bench_item;ANALYZE cart_bench_cart;')
   for name in self.args.variants:
    self.start(name,f'oracle-{cap}')
    def fetch(pair):
     i,c=pair;got=base.get(self.base,f'/carts/{i}/total')
     assert got=={'id':i,'total_cents':c['total_cents']},(cap,name,i,got,c['total_cents'])
    with concurrent.futures.ThreadPoolExecutor(max_workers=64) as pool:list(pool.map(fetch,enumerate(cases,1000001)))
    # First fixture is an empty, undiscounted cart. A sparse last slot must pack densely.
    self.sql(f'INSERT INTO cart_bench_item VALUES(1000001,{cap-1},123,2);')
    assert base.get(self.base,'/carts/1000001/total')['total_cents']==246
    self.sql('DELETE FROM cart_bench_item WHERE cart_id=1000001;')
    assert base.get(self.base,'/carts/1000001/total')['total_cents']==0
    for path,code in [('/carts/2000000000/total',404),('/carts/0/total',400),('/carts/invalid/total',400)]:
     conn=http.client.HTTPConnection('127.0.0.1',self.http_port,timeout=20);conn.request('GET',path);r=conn.getresponse();r.read();assert r.status==code,(cap,name,path,r.status);conn.close()
    stats=base.get(self.base,'/metrics')
    if VARIANTS[name][2]>1:assert stats['max_batch']>1,(cap,name,stats)
    if 'gpu' in name:assert stats['gpu_launches']>0
    report[f'{cap}:{name}']={'decimal_cases':corpus['decimal_cases'],'orm_cases':corpus['orm_cases'],'freshness_updates':2,'error_status_cases':3,'metrics':stats}
    print('CONFORMANCE',cap,name,len(cases),flush=True);self.stop()
  (self.out/'conformance.json').write_text(json.dumps(report,indent=2)+'\n')
 def k6(self,name,clients,cap,rep,warm=False):
  label=f'{cap}-{clients}-{rep}-{name}'+('-warm' if warm else '')
  dest=self.work/f'{label}.json'
  env={**os.environ,'BASE_URL':self.base,'CLIENTS':str(clients),'CARTS':str(self.args.dataset_carts),'LINES':str(cap),'DURATION':f'{self.args.warmup if warm else self.args.duration}s','K6_NO_USAGE_REPORT':'true'}
  with (self.work/f'{label}.log').open('w') as log:base.run('taskset','-c',self.args.client_cpus,self.args.k6,'run','--quiet','--summary-export',str(dest),str(HERE/'load.js'),env=env,stdout=log,stderr=subprocess.STDOUT)
  return json.loads(dest.read_text())
 def measure(self):
  with (self.out/'points.csv').open('w') as f:
   w=csv.DictWriter(f,fieldnames=FIELDS);w.writeheader()
   for cap in self.args.line_counts:
    self.cap=cap
    self.sql((HERE.parent/'seed.sql').read_text().replace(':carts',str(self.args.dataset_carts)).replace(':lines',str(cap)))
    print('SEEDED',self.args.dataset_carts,cap,'rows',self.args.dataset_carts*cap,flush=True)
    for clients in self.args.concurrency:
     for rep in range(self.args.repeats):
      names=list(self.args.variants);random.Random(cap+clients*31+rep*104729).shuffle(names)
      for name in names:
       self.start(name,f'{cap}-{clients}-{rep}');self.k6(name,clients,cap,rep,True)
       before=base.get(self.base,'/metrics')
       with base.Resources(self.server.pid) as resources:data=self.k6(name,clients,cap,rep)['metrics']
       after=base.get(self.base,'/metrics');d={k:after[k]-before[k] for k in before if k!='max_batch'}
       count=int(data['http_reqs']['count']);assert d['requests']==count,(name,d,count)
       if 'gpu' in name:assert d['gpu_launches']==d['batches']
       row=dict(impl=name,scenario=f'lines_{cap}',lines=cap,carts=self.args.dataset_carts,concurrency=clients,repeat=rep,rps=data['http_reqs']['rate'],p50_ms=data['http_req_duration']['p(50)'],p90_ms=data['http_req_duration']['p(90)'],p99_ms=data['http_req_duration']['p(99)'],errors=data['http_req_failed']['passes'],checks_failed=data['checks']['fails'],http_requests=count,server_requests=d['requests'],batches=d['batches'],sql_queries=d['sql_queries'],gpu_launches=d['gpu_launches'],cart_rows=d['cart_rows'],mean_batch=d['requests']/d['batches'],mean_queue_wait_ms=d['queue_wait_ns']/d['requests']/1e6,max_batch_since_start=after['max_batch'],rss_peak_mb=resources.rss,cpu_peak_pct=resources.cpu)
       for metric in ['sql_fetch','pack','compute']:row[metric+'_ms_per_batch']=d.get(metric+'_ns',0)/d['batches']/1e6 if name.startswith('rust-') and not name.endswith('sql') else ''
       w.writerow(row);f.flush();print('POINT',cap,clients,rep,name,round(row['rps']),f"batch={row['mean_batch']:.2f}",flush=True);self.stop()

def main():
 p=argparse.ArgumentParser(__doc__)
 p.add_argument('--out',default=str(HERE/'results/2026-10-19'));p.add_argument('--work',default='/var/tmp/cart-lines-evaluation')
 p.add_argument('--go',default='/var/tmp/django-cart-go-lines');p.add_argument('--go-bin',default='/var/tmp/go/bin/go');p.add_argument('--node',default='node');p.add_argument('--rust',default='/var/tmp/h5i-gpu-target/release/examples/serve_lines');p.add_argument('--ptx',default='/var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/django_cart_gpu_device.ptx')
 p.add_argument('--k6',default='/var/tmp/k6-extract/k6-v2.3.0-linux-amd64/k6');p.add_argument('--oracle',default='/var/tmp/cart-lines-oracle.json')
 p.add_argument('--server-cpus',default='64-67');p.add_argument('--pg-cpus',default='68-71');p.add_argument('--client-cpus',default='72-75')
 p.add_argument('--dataset-carts',type=int,default=4096);p.add_argument('--line-counts',type=int,nargs='+',default=[32,128,512,2048]);p.add_argument('--concurrency',type=int,nargs='+',default=[16,256]);p.add_argument('--duration',type=int,default=5);p.add_argument('--warmup',type=int,default=1);p.add_argument('--repeats',type=int,default=3)
 p.add_argument('--variants',nargs='+',choices=list(VARIANTS),default=list(VARIANTS));p.add_argument('--conformance-only',action='store_true');args=p.parse_args()
 if any(n not in [32,128,512,2048] for n in args.line_counts):p.error('supported counts: 32 128 512 2048')
 if args.dataset_carts<1 or args.dataset_carts>=1000001:p.error('cart count must be 1..1000000')
 bench=Bench(args)
 try:
  bench.start_db();bench.oracle()
  if not args.conformance_only:bench.measure()
 finally:bench.cleanup()

if __name__=='__main__':main()
