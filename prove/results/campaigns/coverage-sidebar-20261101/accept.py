"""Record actual accepted progress toward 100k after every canonical gate."""
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

FOLDER = Path(__file__).resolve().parent
REPO = FOLDER.parents[3]
sys.path.insert(0, str(REPO / 'prove/harness'))
from nora_sidebar import audit as sidebar_audit
from project_reach import fresh_extraction, fresh_gate

index = json.loads((REPO / 'docs/prove/data/index.json').read_text())
stats = index['stats']
assert stats['whole_project_verified']
assert stats['accepted'] == stats['properties'] == 1174
assert stats['upstream_reached'] == stats['current_source_matched_lines']
apps = {}
for app, info in index['apps'].items():
    gate, extraction = fresh_gate(app), fresh_extraction(app)
    assert gate and extraction, app
    if app == "nora":
        sidebar_audit(REPO / "prove/ports/nora")
    apps[app] = {
        'lines': info['current_source_matched_lines'],
        'properties': info['project_properties']['count'],
        'gate_log': gate['log'],
        'extraction_log': extraction['log'],
        'gate_finished_at': gate['finished_at'],
        'extraction_finished_at': extraction['finished_at'],
    }
lines = stats['current_source_matched_lines']
record = {
    'recorded_at': datetime.now(timezone.utc).isoformat(),
    'branch': subprocess.check_output(['git', 'branch', '--show-current'], cwd=REPO, text=True).strip(),
    'baseline_commit': '563c532',
    'baseline': {'lines': 42502, 'properties': 1173},
    'accepted': {'lines': lines, 'properties': stats['properties']},
    'new_deduplicated_lines': lines - 42502,
    'target_lines': 100000,
    'target_reached': lines >= 100000,
    'remaining_lines': max(0, 100000 - lines),
    'apps': apps,
    'meaning': 'Deduplicated pinned executable source reached from theorem types and extracted dependencies. The complete sidebar has a byte-output and termination proof over arbitrary active-page bytes, translations, registry membership, authentication state, and version bytes. Helper fragments and icon constants receive no independent source credit.',
    'published': False,
}
(FOLDER / 'accepted-checkpoint.json').write_text(json.dumps(record, indent=2) + '\n')
print('Accepted:', record['accepted'], '; remaining to 100k:', record['remaining_lines'])
