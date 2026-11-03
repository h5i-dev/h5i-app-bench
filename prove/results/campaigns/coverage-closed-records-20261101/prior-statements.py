"""Verify that every baseline canonical theorem type remains unchanged."""
import subprocess
import sys
import tomllib
from pathlib import Path

REPO = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(REPO / 'prove/harness'))
from project_reach import theorem_type

count = 0
for app in ['nora', 'artifactkeeper', 'kanidm', 'rustfs', 'tuwunel', 'oxicloud']:
    base = 'prove/ports/' + app + '/'
    def baseline(path):
        return subprocess.check_output(['git', 'show', '2731f10:' + base + path], cwd=REPO, text=True)
    manifest = tomllib.loads(baseline('h5i-app.toml'))
    old = baseline('proofs/Properties.lean')
    current = (REPO / base / 'proofs/Properties.lean').read_text()
    for name in manifest['check']['theorems']:
        assert theorem_type(old, name) == theorem_type(current, name), name
    amount = len(manifest['check']['theorems'])
    count += amount
    print(app, amount, 'prior canonical theorem statements unchanged')
assert count == 1174, count
print('All', count, 'baseline theorem statements are unchanged.')
