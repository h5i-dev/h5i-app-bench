"""Rebuild every finite catalog in isolation and compare all retained files."""
from pathlib import Path
import tempfile
import sys

REPO = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(REPO / 'prove/harness'))
import finite_catalog as finite

original = finite.ROOT
with tempfile.TemporaryDirectory(prefix='finite-reproduce-') as tmp:
    root = Path(tmp)
    for name in ['harness/source-mappings', 'results/upstream', 'results/source-coverage']:
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.symlink_to(original / name, target_is_directory=True)
    finite.ROOT = root
    for app in ['nora', 'artifactkeeper', 'kanidm', 'rustfs', 'tuwunel', 'oxicloud']:
        for name in ['proofs/Verified', 'kernel/src']:
            (root / 'ports' / app / name).mkdir(parents=True)
        finite.generate(app)
        finite.audit(app)
        for path in (root / 'ports' / app).rglob('*'):
            if path.is_file():
                relative = path.relative_to(root)
                assert path.read_bytes() == (original / relative).read_bytes(), str(relative)
        print(app, 'all generated files reproduce byte for byte', flush=True)
