#!/usr/bin/env python3
"""Publish control point summaries only, keeping all raw run files local."""
import argparse
import csv
import json
from pathlib import Path

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('runs', nargs='+', type=Path)
p.add_argument('--out', type=Path, required=True)
a = p.parse_args()
rows = []
for run in a.runs:
    meta = json.loads((run / 'run.json').read_text())
    with (run / 'points.csv').open() as f:
        for point in csv.DictReader(f):
            rows.append(dict(run=run.name, app=meta['app'], mode=meta['mode'],
                             started_utc=meta['started_utc'], **point))
a.out.parent.mkdir(parents=True, exist_ok=True)
with a.out.open('w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0]), lineterminator='\n')
    w.writeheader()
    w.writerows(rows)
