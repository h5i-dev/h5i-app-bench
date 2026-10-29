"""Compile unchanged pinned policy function bodies and compare the port.

No upstream service dependencies are replaced: only pure item bodies are
selected, serde/schema derives omitted and formatted errors normalized.
"""
import hashlib
import json
import re
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
PORT = ROOT / 'ports/artifactkeeper'
REPO = ROOT / 'results/upstream/artifactkeeper.git'
REVISION = '7c42891cd64f144df6197b8801c9cca4f0e0f5a7'
SOURCE = 'backend/src/services/token_expiry_policy.rs'
text = subprocess.check_output(['git', '-C', REPO, 'show', f'{REVISION}:{SOURCE}'], text=True)
# The existing balanced-item extractor reads verbatim source fragments.
import sys
sys.path.insert(0, str(ROOT / 'ports/rustfs/difftest'))
from count_loc import item

def cut(header):
    return item(text, header)

def data(header):
    fragment = cut(header)
    return '#[derive(Debug, Clone, Copy)]\n' + re.sub(r'^\s*#\[[^\n]*\]\n', '', fragment, flags=re.M)

upstream = '\n'.join([
    'const ABSOLUTE_MAX_EXPIRY_DAYS: i64 = 3650;',
    data(r'pub struct ApiTokenExpiryPolicy'),
    data(r'pub struct ResolvedExpiry'),
    'impl Default for ApiTokenExpiryPolicy {' + cut(r'fn default\(') + '}',
    'impl ApiTokenExpiryPolicy {' + cut(r'pub fn validate\(') + '}',
    cut(r'pub fn resolve_expiry\('),
])
print(json.dumps({'upstream_revision': REVISION, 'path': SOURCE,
                  'source_sha256': hashlib.sha256(text.encode()).hexdigest(),
                  'selected_source_sha256': hashlib.sha256(upstream.encode()).hexdigest()}), flush=True)
with tempfile.TemporaryDirectory() as directory:
    work = Path(directory)
    (work / 'upstream.rs').write_text(upstream)
    template = (Path(__file__).with_name('compare.rs')).read_text()
    # Absolute paths are inserted as Rust string literals, never shell text.
    template = template.replace('"UPSTREAM"', json.dumps(str(work / 'upstream.rs')))
    template = template.replace('"PORT"', json.dumps(str(PORT / 'kernel/src/token_expiry.rs')))
    (work / 'compare.rs').write_text(template)
    subprocess.run(['rustc', '--edition=2024', '-O', '-D', 'warnings', str(work / 'compare.rs'), '-o', str(work / 'compare')], check=True)
    subprocess.run([str(work / 'compare')], check=True)
