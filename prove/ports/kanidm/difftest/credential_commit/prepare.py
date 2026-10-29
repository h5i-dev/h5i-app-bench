#!/usr/bin/env python3
"""Refresh the reference method from the pinned bare Git repository.
Keep the small object-projection prelude; only overwrite the upstream method.
"""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
HERE = Path(__file__).resolve().parent
PIN = 'f608c4fe14dfd8d5df8edeed470bf1fb92060abd'
PATH = 'server/lib/src/idm/credupdatesession.rs'
raw = subprocess.check_output(['git', '--git-dir=' + sys.argv[1], 'show', PIN + ':' + PATH]).decode()
a = raw.index('    fn can_commit(&self)')
b = raw.index('\n    }\n}', a) + 6
method = raw[a:b]
p = HERE / 'reference.rs'
prelude = p.read_text().split('impl CredentialUpdateSession {')[0] + 'impl CredentialUpdateSession {\n'
p.write_text(prelude + method.replace('    fn can_commit', '    pub fn can_commit', 1) + '\n}\n')
(HERE / 'identity.json').write_text(json.dumps({'pin': PIN, 'path': PATH, 'sha256': hashlib.sha256(raw.encode()).hexdigest(), 'method_sha256': hashlib.sha256(method.encode()).hexdigest()}, indent=2) + '\n')
