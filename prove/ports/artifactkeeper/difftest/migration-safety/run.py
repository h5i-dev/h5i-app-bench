"""Verbatim pinned SQL masking/search against staged byte scanner."""
import hashlib,json,subprocess,tempfile,sys,io,tarfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
REV='7c42891cd64f144df6197b8801c9cca4f0e0f5a7'
REPO=ROOT/'results/upstream/artifactkeeper.git'
SOURCE='backend/src/migration_safety.rs'
sys.path.insert(0,str(ROOT/'ports/rustfs/difftest'))
from count_loc import item
text=subprocess.check_output(['git','-C',REPO,'show',f'{REV}:{SOURCE}'],text=True)
upstream='\n'.join(item(text,header) for header in [r'fn mask_sql\(',r'fn find_phrase\(',r'fn is_word_byte\(',r'fn identifier_after\(',r'fn skip_ws\(',r'fn alter_target\(',r'fn classify\('])
upstream += '\n'+'\n'.join(line for line in text.splitlines() if line.startswith('const KIND_'))
print(json.dumps({'revision':REV,'path':SOURCE,'source_sha256':hashlib.sha256(text.encode()).hexdigest(),'selected_sha256':hashlib.sha256(upstream.encode()).hexdigest()}),flush=True)
with tempfile.TemporaryDirectory() as tmp:
 w=Path(tmp);(w/'upstream.rs').write_text(upstream)
 harness=Path(__file__).with_name('compare.rs').read_text().replace('"UPSTREAM"',json.dumps(str(w/'upstream.rs'))).replace('"PORT"',json.dumps(str(ROOT/'ports/artifactkeeper/kernel/src/migration_safety.rs')))
 (w/'compare.rs').write_text(harness)
 subprocess.run(['rustc','--edition=2024','-O',str(w/'compare.rs'),'-o',str(w/'compare')],check=True)
 archive=subprocess.check_output(['git','-C',REPO,'archive',REV,'backend/migrations'])
 with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
  corpus=[tar.extractfile(m).read() for m in tar.getmembers() if m.isfile() and m.name.endswith('.sql')]
 (w/'corpus').write_bytes(b'\0'.join(corpus))
 print(json.dumps({'pinned_sql_files':len(corpus),'corpus_sha256':hashlib.sha256(b'\0'.join(corpus)).hexdigest()}),flush=True)
 subprocess.run([str(w/'compare'),str(w/'corpus')],check=True)
