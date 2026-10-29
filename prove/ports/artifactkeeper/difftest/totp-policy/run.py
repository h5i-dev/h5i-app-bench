"""Exhaust every pure TOTP login/activation input against pinned upstream bodies."""
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[4]
REPO = ROOT / 'results/upstream/artifactkeeper.git'
REV = '7c42891cd64f144df6197b8801c9cca4f0e0f5a7'
SOURCE = 'backend/src/services/totp_policy.rs'
def source(path):
    return subprocess.check_output(['git', '-C', REPO, 'show', f'{REV}:{path}'], text=True)
sys.path.insert(0, str(ROOT / 'ports/rustfs/difftest'))
from count_loc import item
text = source(SOURCE)
def cut(header):
    return item(text, header)
def data(header, text=text):
    frag = item(text, header)
    return '#[derive(Debug, Clone, Copy, PartialEq, Eq)]\n' + re.sub(r'^\s*#\[[^\n]*\]\n', '', frag, flags=re.M)
selected = '\n'.join([
    data('pub enum AuthProvider', source('backend/src/models/user.rs')),
    *(data(h) for h in ['pub enum TotpPolicy', 'pub enum TotpLoginRequirement',
                        'pub struct TotpSubject', 'pub enum PolicyActivationRefusal']),
    'impl TotpPolicy {' + cut(r'pub fn is_enforcing\(') + '}',
    *(cut(h) for h in [r'pub fn totp_login_requirement\(', r'pub fn policy_requires_totp\(',
                       r'pub fn check_policy_activation\(', r'fn is_tightening\(', r'fn strictness\('])
])
print(json.dumps({'revision': REV, 'source': SOURCE,
    'source_sha256': hashlib.sha256(text.encode()).hexdigest(),
    'selected_sha256': hashlib.sha256(selected.encode()).hexdigest()}), flush=True)
template = (Path(__file__).parent / 'compare.rs').read_text()
with tempfile.TemporaryDirectory(prefix='h5i-totp-') as directory:
    d = Path(directory)
    (d / 'upstream.rs').write_text(selected)
    (d / 'compare.rs').write_text(template.replace('UPSTREAM_PATH', json.dumps(str(d / 'upstream.rs')))
        .replace('PORT_PATH', json.dumps(str(ROOT / 'ports/artifactkeeper/kernel/src/totp_policy.rs'))))
    subprocess.run(['rustc', '--edition=2024', '-O', '-D', 'warnings', str(d / 'compare.rs'), '-o', str(d / 'compare')], check=True)
    subprocess.run([str(d / 'compare')], check=True)
