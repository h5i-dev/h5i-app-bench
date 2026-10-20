"""Run placement diagnostics AFTER the HTTP sweep, on the same CUDA kernels."""
import argparse
import csv
import hashlib
import itertools
import json
import math
import os
from pathlib import Path
import statistics
import subprocess
import time

HERE=Path(__file__).resolve().parent
APP=HERE.parents[1]
METRICS=['cpu1_ms','cpu4_ms','resident_ms','reuse_upload_ms','fresh_ms','device_event_ms']

def summarize(out):
 rows=list(csv.DictReader((out/'placement.csv').open()))
 expected=set(itertools.product([32,128,512,2048],[8,128,256],['scalar','cooperative'],range(3)))
 seen=set();checksums={}
 for r in rows:
  key=(int(r['lines']),int(r['carts']),r['layout'],int(r['repeat']))
  if key in seen:raise ValueError('duplicate placement point')
  seen.add(key)
  if int(r['iterations'])!=100 or int(r['input_bytes'])!=rbytes(key):raise ValueError('placement shape mismatch')
  if any(not math.isfinite(float(r[k])) or float(r[k])<=0 for k in METRICS):raise ValueError('invalid placement timing')
  shape=key[:2];checksums.setdefault(shape,r['checksum'])
  if checksums[shape]!=r['checksum']:raise ValueError('placement output mismatch')
 if seen!=expected:raise ValueError('incomplete placement grid')
 report=['# CUDA placement diagnostic','','This is a calculation diagnostic, separate from HTTP rankings. It uses the same two kernels and pricing code as the line-count HTTP run, with already-packed snapshots. Each measured method recomputes totals; CPU/GPU output vectors are checked exactly. Three repetitions average 100 iterations after eight warmup passes; CPU has one or four persistent workers on four logical CPUs. CUDA context initialization and input generation are excluded.','','- **Fresh** uses the actual HTTP GPU helper: host transpose for scalar, device allocation, input/output initialization copies, launch, synchronization, full download, validation and deallocation.','- **Reuse + upload** keeps device buffers but uploads fresh input each call. Scalar still transposes each call. Cooperative input needs no transpose.','- **Resident** uses the actual helper with unchanged input already uploaded. Includes launch, synchronization, result allocation, full download and validation. A CPU could cache unchanged totals too; this is not an application speedup.','- **Device event** records CUDA events around one kernel launch on resident input, synchronizing each iteration. Excludes transfer, allocation and download; event/host submission gaps can affect short intervals. It is not a profiler measurement of active kernel cycles.','','## Mean microseconds per complete batch','','CPU means use six repetition means (three alongside each GPU layout); GPU columns each use three. All CPU implementations recalculate the same total, including input validation and output allocation.','','| Lines | Carts/batch | CPU 1T µs | CPU 4T µs | Scalar fresh µs | Cooperative fresh µs | Cooperative reuse + upload µs | Cooperative resident µs | Cooperative device event µs |','| --- | --- | --- | --- | --- | --- | --- | --- | --- |']
 for cap,n in itertools.product([32,128,512,2048],[8,128,256]):
  a=[r for r in rows if int(r['lines'])==cap and int(r['carts'])==n]
  coop=[r for r in a if r['layout']=='cooperative'];scalar=[r for r in a if r['layout']=='scalar']
  def mean(rs,k):return statistics.mean(float(r[k])*1000 for r in rs)
  values=[mean(a,'cpu1_ms'),mean(a,'cpu4_ms'),mean(scalar,'fresh_ms'),mean(coop,'fresh_ms'),mean(coop,'reuse_upload_ms'),mean(coop,'resident_ms'),mean(coop,'device_event_ms')]
  report.append(f"| {cap} | {n} | "+' | '.join(f'{v:.3f}' for v in values)+' |')
 report+=['','These batches cover low-load batches (~8 carts), the larger observed batches (~128), and the configured 256-request maximum. They are synthetic full carts, not a replay of the precise HTTP batch membership. Frozen, repeatedly accessed host input has different cache conditions from decoded SQL rows. Layout and method order are fixed; clocks, NUMA and shared-host activity are uncontrolled. Buffer reuse is measured as a diagnostic and has not been integrated into the HTTP implementation. The resident case does not measure update propagation or residency maintenance.','','[Per-repetition CSV](placement.csv) · [Environment and hashes](placement-environment.json) · [HTTP results](summary.md) · [Method](../../README.md)','']
 (out/'placement.md').write_text('\n'.join(report))
 print(f'{len(rows)} verified placement points -> {out}/placement.md')

def rbytes(key):return (2*key[0]+3)*key[1]*8

def main():
 p=argparse.ArgumentParser(__doc__)
 p.add_argument('--out',type=Path,default=HERE/'results/2026-10-19')
 p.add_argument('--binary',default='/var/tmp/h5i-gpu-target/release/examples/profile_lines')
 p.add_argument('--ptx',default='/var/tmp/h5i-gpu-target/nvptx64-nvidia-cuda/release/django_cart_gpu_device.ptx')
 p.add_argument('--cpus',default='64-67');p.add_argument('--summarize-only',action='store_true');args=p.parse_args()
 if not args.summarize_only:
  args.out.mkdir(parents=True,exist_ok=True)
  digest=lambda path:hashlib.sha256(Path(path).read_bytes()).hexdigest()
  sources=['rust-h5i-gpu/backend-nvvm/examples/profile_lines.rs','rust-h5i-gpu/backend-nvvm/src/lib.rs','rust-h5i-gpu/backend-nvvm/device/src/lib.rs','rust-h5i-gpu/src/wide.rs','rust-h5i-gpu/src/pricing.rs','http/lines/profile.py']
  metadata=dict(utc=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),command=['taskset','-c',args.cpus,args.binary,args.ptx],cpu_affinity=json.loads(subprocess.check_output(['taskset','-c',args.cpus,'python3','-c','import os,json;print(json.dumps(sorted(os.sched_getaffinity(0))))'],text=True)),source_sha256={s:digest(APP/s) for s in sources},artifact_sha256={s:digest(s) for s in [args.binary,args.ptx]},host_and_toolchain='environment.json',note='Run after HTTP load; GPU device 0, same PTX, unchanged kernels. Separate timing diagnostic with no HTTP or database.')
  (args.out/'placement-environment.json').write_text(json.dumps(metadata,indent=2)+'\n')
  with (args.out/'placement.csv').open('w') as f:
   subprocess.run(metadata['command'],env={**os.environ,'CUDA_VISIBLE_DEVICES':'0','LD_LIBRARY_PATH':'/usr/local/cuda-12.6/lib64'},stdout=f,check=True)
 summarize(args.out)

if __name__=='__main__':main()
