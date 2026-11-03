"""Compile staged generated Rust extraction and sidebar proofs with pinned dependencies."""
import argparse
import os
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--stage', type=Path, default=Path('/tmp/h5i-sidebar-stage'))
args = parser.parse_args()
repo = Path(__file__).resolve().parents[4]
proofs = args.stage.resolve() / 'proofs'
working = repo / 'prove/ports/nora/proofs'
def lake(*args):
    return subprocess.check_output(['lake', 'env', *args], cwd=working, text=True).strip()
# Set search precedence after Lake resolves its pinned dependency environment.
env = {**os.environ, 'LEAN_PATH': str(proofs / 'generated') + ':' + lake('printenv', 'LEAN_PATH')}
lean = lake('which', 'lean')
for module in ['generated/NoraKernel', 'Verified/Sidebar']:
    root = proofs / 'generated' if module.startswith('generated/') else proofs
    subprocess.run([lean, '-j', '8', '-R', str(root), '-o', str(proofs / (module + '.olean')),
                    str(proofs / (module + '.lean'))], cwd=working, env=env, check=True)
print('Staged extraction and complete sidebar proofs compile.')
