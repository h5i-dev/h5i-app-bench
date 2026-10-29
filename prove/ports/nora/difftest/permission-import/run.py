"""Compare the complete normalized report against pinned original mapper."""
import hashlib,json,re,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
REV='f864a9a95e8669b00202c18b0b774ab0fc2e56cc'
PATH='nora-registry/src/import/permissions.rs'
text=subprocess.check_output(['git','-C',ROOT/'results/upstream/nora.git','show',f'{REV}:{PATH}'],text=True)
selected=text[text.index('#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]'):text.index('/// Write the inert proposal')]
selected=selected.replace(', Serialize','')
print(json.dumps({'revision':REV,'path':PATH,'source_sha256':hashlib.sha256(text.encode()).hexdigest(),'selected_sha256':hashlib.sha256(selected.encode()).hexdigest()}),flush=True)
with tempfile.TemporaryDirectory(prefix='nora-permissions-') as directory:
 d=Path(directory);(d/'upstream.rs').write_text(selected)
 template=(Path(__file__).parent/'compare.rs').read_text()
 (d/'compare.rs').write_text(template.replace('UPSTREAM_PATH',json.dumps(str(d/'upstream.rs'))).replace('PORT_PATH',json.dumps(str(ROOT/'ports/nora/kernel/src/permission_import.rs'))))
 subprocess.run(['rustc','--edition=2024','-O','-D','warnings',str(d/'compare.rs'),'-o',str(d/'compare')],check=True)
 subprocess.run([str(d/'compare')],check=True)
