#!/usr/bin/env python3
"""Aggregate per-request wall times from quiescent before/after counters.

Parent stages are inclusive. sql_query is a sum over pipelined futures and
MUST NOT be added to, or subtracted from, load; these timers overlap.
"""
import argparse
import csv
import json
from pathlib import Path
import re
from statistics import mean, stdev

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('runs', nargs='+', type=Path)
p.add_argument('--out', type=Path, required=True)
p.add_argument('--replace-duplicates', action='store_true',
               help='For resumed experiments, later runs replace the same app/scenario/concurrency/rep')
a=p.parse_args()
a.out.mkdir(parents=True,exist_ok=True)
points=[]
for run in a.runs:
    meta=json.loads((run/'run.json').read_text())
    for after in sorted(run.glob('*.profile.after.csv')):
        before=Path(str(after).replace('.after.csv','.before.csv'))
        def read(path):
            return {r['stage']:{k:int(r[k]) for k in ['count','ns','units']} for r in csv.DictReader(path.open())}
        old,new=read(before),read(after)
        diff={s:{k:new[s][k]-old[s][k] for k in old[s]} for s in old}
        m=re.fullmatch(r'rust-h5i_(.+)_c(\d+)_r(\d+).profile.after.csv',after.name)
        scenario,conc,rep=m.groups()
        n=diff['http']['count']
        row={'app':meta['app'],'scenario':scenario,'concurrency':int(conc),'rep':int(rep),'requests':n}
        for stage,v in diff.items():
            row[stage+'_ms']=v['ns']/n/1e6 if n else 0
        row.update(rows_per_request=diff['pg_decode']['units']/n if n else 0,
                   queries_per_request=diff['sql_query']['count']/n if n else 0,
                   retries=diff['backoff']['count'])
        summary=json.loads((run/after.name.replace('.profile.after.csv','.summary.json')).read_text())['metrics']
        row['k6_requests']=int(summary['http_reqs']['count'])
        row['rps']=summary['http_reqs']['rate']
        row['p99_ms']=summary['http_req_duration']['p(99)']
        row['error_rate']=summary['http_req_failed']['value']
        row['failed_requests']=round(row['k6_requests']*row['error_rate'])
        if row['k6_requests']!=n or diff['engine']['count']!=n:
            raise ValueError(f'Incomplete or extra requests: {after}: http={n}, k6={row["k6_requests"]}, engine={diff["engine"]["count"]}')
        points.append(row)
if not points:
    raise SystemExit('No profile captures')
unique={}
for row in points:
    key=tuple(row[k] for k in ['app','scenario','concurrency','rep'])
    if key in unique and not a.replace_duplicates:
        raise ValueError(f'Duplicate point {key}; use --replace-duplicates for a resumed run')
    unique[key]=row
points=list(unique.values())
def write(name, rows):
    with (a.out/name).open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');w.writeheader();w.writerows(rows)
write('profile-points.csv',points)
groups={}
for row in points:
    groups.setdefault(tuple(row[k] for k in ['app','scenario','concurrency']),[]).append(row)
rows=[]
for key,group in sorted(groups.items()):
    row=dict(zip(['app','scenario','concurrency'],key));row['reps']=len(group)
    for k in group[0]:
        if k not in ['app','scenario','concurrency','rep']:
            row[k]=sum(g[k] for g in group) if k in ['requests','k6_requests','retries','failed_requests'] else mean(g[k] for g in group)
    row['rps_stdev']=stdev(g['rps'] for g in group) if len(group)>1 else 0
    rows.append(row)
write('profile-summary.csv',rows)
for r in rows:
    print(r['app'],r['scenario'],r['concurrency'],f"http={r['http_ms']:.2f}ms engine={r['engine_ms']:.2f}ms load={r['load_ms']:.2f}ms lock={r['lock_ms']:.2f}ms pool={r['pool_ms']:.2f}ms rows={r['rows_per_request']:.0f}")
