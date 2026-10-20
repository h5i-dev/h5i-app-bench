"""Real HTTP -> bounded request queue -> PostgreSQL -> CPU/CUDA -> HTTP.

Owns an isolated temporary DB; checks all endpoints before collecting timings.
Raw k6/logs stay in --work; publish only joined points and reproducible metadata.
"""
import argparse
import concurrent.futures
import csv
import hashlib
import http.client
import json
import os
from pathlib import Path
import random
import socket
import statistics
import struct
import subprocess
import threading
import time
import urllib.request

HERE=Path(__file__).resolve().parent
APP=HERE.parent
VARIANTS={
    'go-sql':('go','sql',1,0),
    'javascript-sql':('node','sql',1,0),
    'rust-sql':('rust','sql',1,0),
    'go-batch':('go','batch',256,1000),
    'javascript-batch':('node','batch',256,1000),
    'rust-cpu-batch':('rust','batch',256,1000),
    'rust-gpu-single':('rust','gpu',1,0),
    'rust-gpu-batch':('rust','gpu',256,1000),
}


def run(*cmd,**kwargs):
    return subprocess.run(list(map(str,cmd)),check=True,**kwargs)


def free_port():
    with socket.socket() as s:
        s.bind(('127.0.0.1',0))
        return s.getsockname()[1]


def get(base,path):
    with urllib.request.urlopen(base+path,timeout=20) as r:
        return json.load(r)


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


class Resources:
    """Peak server RSS and aggregate process CPU over 100 ms samples."""
    def __init__(self,pid):
        self.pid=pid;self.rss=0;self.cpu=0;self.done=threading.Event()
    def sample(self):
        ticks=os.sysconf('SC_CLK_TCK');previous=None
        while not self.done.is_set():
            try:
                fields=Path(f'/proc/{self.pid}/stat').read_text().rsplit(')',1)[1].split()
                current=(time.monotonic(),(int(fields[11])+int(fields[12]))/ticks)
                status=Path(f'/proc/{self.pid}/status').read_text()
                self.rss=max(self.rss,float(next(x.split()[1] for x in status.splitlines() if x.startswith('VmRSS:')))/1024)
                if previous:self.cpu=max(self.cpu,(current[1]-previous[1])/(current[0]-previous[0])*100)
                previous=current
            except FileNotFoundError:break
            self.done.wait(.1)
    def __enter__(self):
        self.thread=threading.Thread(target=self.sample);self.thread.start();return self
    def __exit__(self,*args):
        self.done.set();self.thread.join()


class Bench:
    def __init__(self,args):
        self.args=args
        self.work=Path(args.work).resolve();self.work.mkdir(parents=True,exist_ok=True)
        self.out=Path(args.out).resolve();self.out.mkdir(parents=True,exist_ok=True)
        self.container=f'django-cart-http-{os.getpid()}'
        self.port=free_port();self.http_port=free_port();self.base=f'http://127.0.0.1:{self.http_port}'
        self.url=f'postgres://cart:cart-bench@127.0.0.1:{self.port}/cart'
        self.server=None;self.log=None

    def sql(self,text):
        result=run('docker','exec','-i',self.container,'psql','-v','ON_ERROR_STOP=1','-U','cart','-d','cart',input=text.encode(),capture_output=True)
        return result.stdout.decode()

    def start_db(self):
        # cgroup cpuset is unavailable on this host: inherit taskset from PID 1.
        run('docker','run','-d','--name',self.container,'-e','POSTGRES_USER=cart','-e','POSTGRES_PASSWORD=cart-bench','-e','POSTGRES_DB=cart','-p',f'127.0.0.1:{self.port}:5432','--shm-size=1g','--entrypoint','/usr/bin/taskset','postgres:16','-c',self.args.pg_cpus,'/usr/local/bin/docker-entrypoint.sh','postgres','-c','shared_buffers=512MB',capture_output=True)
        for _ in range(100):
            p=subprocess.run(['docker','exec',self.container,'pg_isready','-h','127.0.0.1','-U','cart','-d','cart'],capture_output=True)
            if p.returncode==0:break
            time.sleep(.1)
        else:raise RuntimeError('database did not start')
        self.sql((HERE/'schema.sql').read_text())
        sources=[APP/'go/main.go',APP/'go/server.go',APP/'go/go.mod',APP/'go/go.sum',APP/'javascript/main.mjs',APP/'javascript/server.mjs',APP/'javascript/package-lock.json',APP/'rust-h5i-gpu/src/pricing.rs',APP/'rust-h5i-gpu/backend-nvvm/examples/serve.rs',APP/'rust-h5i-gpu/backend-nvvm/src/lib.rs',APP/'rust-h5i-gpu/backend-nvvm/device/src/lib.rs',APP/'rust-h5i-gpu/backend-nvvm/Cargo.lock',HERE/'load.js',HERE/'run.py',HERE/'queries.sql',HERE/'schema.sql',HERE/'seed.sql']
        metadata={'utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'config':vars(self.args),
                  'postgres_image':run('docker','image','inspect','postgres:16','--format','{{.Id}}',capture_output=True,text=True).stdout.strip(),
                  'postgres_affinity':run('docker','exec',self.container,'taskset','-pc','1',capture_output=True,text=True).stdout.strip(),
                  'upstream_commit':(APP/'upstream/COMMIT').read_text().strip(),
                  'source_sha256':{str(p.relative_to(APP)):digest(p) for p in sources},
                  'artifact_sha256':{p:digest(p) for p in [self.args.go,self.args.rust,self.args.ptx]},
                  'versions':{name:run(*cmd,capture_output=True,text=True).stdout.strip() for name,cmd in {'go':[self.args.go_bin,'version'],'node':[self.args.node,'--version'],'k6':[self.args.k6,'version'],'gpu':['nvidia-smi'],'cpu':['lscpu']}.items()},
                  'note':'Dedicated temporary PostgreSQL, sequential variants, one batch worker; SQL baselines use up to 16 DB connections. No auth, sessions or HTTP mutations. Every batch rereads SQL and uploads fresh GPU inputs.'}
        (self.out/'environment.json').write_text(json.dumps(metadata,indent=2)+'\n')

    def start(self,name,label):
        language,mode,limit,wait=VARIANTS[name]
        cmd={'go':[self.args.go,'serve'],'node':[self.args.node,str(APP/'javascript/server.mjs')],'rust':[self.args.rust]}[language]
        env={**os.environ,'DATABASE_URL':self.url,'PORT':str(self.http_port),'MODE':mode,'BATCH_MAX':str(limit),'BATCH_WAIT_US':str(wait),'PTX':self.args.ptx,'CUDA_VISIBLE_DEVICES':'0','LD_LIBRARY_PATH':'/usr/local/cuda-12.6/lib64','GOMAXPROCS':'4'}
        self.log=(self.work/f'{label}-{name}-server.log').open('w')
        self.server=subprocess.Popen(['taskset','-c',self.args.server_cpus,*cmd],env=env,stdout=self.log,stderr=subprocess.STDOUT)
        for _ in range(200):
            if self.server.poll() is not None:
                raise RuntimeError(f'{name} failed to start; {self.log.name}')
            try:
                with urllib.request.urlopen(self.base+'/health',timeout=.3) as r:
                    if r.status==200:return
            except OSError:pass
            time.sleep(.05)
        raise RuntimeError(f'{name} startup timeout')

    def stop(self):
        if self.server:
            self.server.terminate()
            try:self.server.wait(timeout=10)
            except subprocess.TimeoutExpired:self.server.kill();self.server.wait()
            self.server=None
        if self.log:self.log.close();self.log=None

    def oracle(self):
        data=Path(self.args.fixtures).read_bytes()
        all_rows=list(struct.iter_unpack('<67Q',data))
        expected=run(self.args.checker,input=data,capture_output=True).stdout
        totals=list(struct.unpack(f'<{len(all_rows)}Q',expected))
        cases=[(r,t) for r,t in zip(all_rows,totals) if t!=2**64-1]
        assert len(cases)==4146
        carts=[];items=[]
        for i,(r,_) in enumerate(cases,1000001):
            carts.append(f'{i}\t{r[65]}\t{r[66]}\n')
            for j in range(r[0]):items.append(f'{i}\t{j}\t{r[1+j]}\t{r[33+j]}\n')
        self.sql('COPY cart_bench_cart FROM STDIN;\n'+''.join(carts)+'\\.\nCOPY cart_bench_item FROM STDIN;\n'+''.join(items)+'\\.\nANALYZE cart_bench_cart;ANALYZE cart_bench_item;')
        report={}
        for name in self.args.variants:
            self.start(name,'conformance')
            local=threading.local()
            def fetch(case):
                i,(_,value)=case
                if not hasattr(local,'conn'):local.conn=http.client.HTTPConnection('127.0.0.1',self.http_port,timeout=20)
                local.conn.request('GET',f'/carts/{i}/total')
                response=local.conn.getresponse();body=response.read()
                assert response.status==200,(name,i,response.status,body)
                assert json.loads(body)=={'id':i,'total_cents':value},(name,i,body,value)
            with concurrent.futures.ThreadPoolExecutor(max_workers=64) as pool:
                list(pool.map(fetch,enumerate(cases,1000001)))
            # No stale resident totals: a committed item change must affect the next query.
            self.sql('INSERT INTO cart_bench_item VALUES(1000001,7,123,2);')
            assert get(self.base,'/carts/1000001/total')['total_cents']==246
            self.sql('DELETE FROM cart_bench_item WHERE cart_id=1000001;')
            assert get(self.base,'/carts/1000001/total')['total_cents']==0
            for path,code in [('/carts/2000000000/total',404),('/carts/0/total',400),('/carts/invalid/total',400)]:
                conn=http.client.HTTPConnection('127.0.0.1',self.http_port,timeout=20);conn.request('GET',path);response=conn.getresponse();response.read();assert response.status==code,(name,path,response.status);conn.close()
            stats=get(self.base,'/metrics')
            if VARIANTS[name][2]>1:assert stats['max_batch']>1,(name,stats)
            if 'gpu' in name:assert stats['gpu_launches']>0,(name,stats)
            report[name]={'decimal_cases':len(cases),'freshness_updates':2,'error_status_cases':3,'metrics':stats}
            self.stop();print('CONFORMANCE',name,stats,flush=True)
        (self.out/'conformance.json').write_text(json.dumps(report,indent=2)+'\n')

    def seed(self,carts):
        sql=(HERE/'seed.sql').read_text().replace(':carts',str(carts)).replace(':lines',str(self.args.lines))
        self.sql(sql)

    def k6(self,name,clients,carts,repeat,warm=False):
        label=f'{carts}-{clients}-{repeat}-{name}'+('-warm' if warm else '')
        dest=self.work/f'{label}.json'
        cmd=['taskset','-c',self.args.client_cpus,self.args.k6,'run','--quiet','--summary-export',str(dest),str(HERE/'load.js')]
        env={**os.environ,'BASE_URL':self.base,'CLIENTS':str(clients),'CARTS':str(carts),'LINES':str(self.args.lines),'DURATION':f'{self.args.warmup if warm else self.args.duration}s','K6_NO_USAGE_REPORT':'true'}
        with (self.work/f'{label}.log').open('w') as log:run(*cmd,env=env,stdout=log,stderr=subprocess.STDOUT)
        return json.loads(dest.read_text())

    def measure(self):
        fields=['impl','scenario','concurrency','repeat','rps','p50_ms','p90_ms','p99_ms','errors','checks_failed','http_requests','server_requests','batches','sql_queries','gpu_launches','cart_rows','mean_batch','mean_queue_wait_ms','max_batch_since_start','rss_peak_mb','cpu_peak_pct']
        with (self.out/'points.csv').open('w') as f:
            writer=csv.DictWriter(f,fieldnames=fields);writer.writeheader()
            for carts in self.args.carts:
                self.seed(carts)
                for clients in self.args.concurrency:
                    for rep in range(self.args.repeats):
                        names=list(self.args.variants);random.Random(carts+clients*31+rep*104729).shuffle(names)
                        for name in names:
                            self.start(name,f'{carts}-{clients}-{rep}')
                            self.k6(name,clients,carts,rep,warm=True)
                            before=get(self.base,'/metrics')
                            with Resources(self.server.pid) as resources:
                                data=self.k6(name,clients,carts,rep)['metrics']
                            after=get(self.base,'/metrics');delta={k:after[k]-before[k] for k in before if k!='max_batch'}
                            # Each successful HTTP response must correspond to a serviced request.
                            count=int(data['http_reqs']['count'])
                            if delta['requests']!=count:raise ValueError(f'request accounting mismatch: {name} {delta} {count}')
                            if VARIANTS[name][1]=='gpu' and delta['gpu_launches']!=delta['batches']:raise ValueError('GPU launch accounting mismatch')
                            row=dict(impl=name,scenario=f'total_{carts}',concurrency=clients,repeat=rep,rps=data['http_reqs']['rate'],p50_ms=data['http_req_duration']['p(50)'],p90_ms=data['http_req_duration']['p(90)'],p99_ms=data['http_req_duration']['p(99)'],errors=data['http_req_failed']['passes'],checks_failed=data['checks']['fails'],http_requests=count,server_requests=delta['requests'],batches=delta['batches'],sql_queries=delta['sql_queries'],gpu_launches=delta['gpu_launches'],cart_rows=delta['cart_rows'],mean_batch=delta['requests']/delta['batches'],mean_queue_wait_ms=delta['queue_wait_ns']/delta['requests']/1e6,max_batch_since_start=after['max_batch'])
                            row.update(rss_peak_mb=resources.rss,cpu_peak_pct=resources.cpu)
                            writer.writerow(row);f.flush();print('POINT',carts,clients,rep,name,round(row['rps']),f"batch={row['mean_batch']:.2f}",flush=True)
                            self.stop()

    def cleanup(self):
        self.stop()
        subprocess.run(['docker','rm','-f',self.container],capture_output=True)


def main():
    p=argparse.ArgumentParser(__doc__)
    p.add_argument('--out',default=str(HERE/'results/2026-10-19'))
    p.add_argument('--work',default='/var/tmp/django-cart-http-evaluation')
    p.add_argument('--go',default='/var/tmp/django-cart-go')
    p.add_argument('--go-bin',default='/var/tmp/go/bin/go')
    p.add_argument('--node',default='node')
    p.add_argument('--rust',default='/var/tmp/h5i-gpu-target/release/examples/serve')
    p.add_argument('--ptx',default='/var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/django_cart_gpu_device.ptx')
    p.add_argument('--fixtures',default='/var/tmp/django-cart-fixtures.bin')
    p.add_argument('--checker',default='/var/tmp/django-cart-target/release/cart-check')
    p.add_argument('--k6',default='/var/tmp/k6-extract/k6-v2.3.0-linux-amd64/k6')
    p.add_argument('--server-cpus',default='64-67');p.add_argument('--pg-cpus',default='68-71');p.add_argument('--client-cpus',default='72-75')
    p.add_argument('--carts',type=int,nargs='+',default=[4096,65536]);p.add_argument('--lines',type=int,default=32)
    p.add_argument('--concurrency',type=int,nargs='+',default=[1,16,64,256])
    p.add_argument('--duration',type=int,default=5);p.add_argument('--warmup',type=int,default=1);p.add_argument('--repeats',type=int,default=3)
    p.add_argument('--variants',nargs='+',choices=list(VARIANTS),default=list(VARIANTS))
    p.add_argument('--conformance-only',action='store_true')
    args=p.parse_args();bench=Bench(args)
    try:
        bench.start_db();bench.oracle()
        if not args.conformance_only:bench.measure()
    finally:bench.cleanup()


if __name__=='__main__':main()
