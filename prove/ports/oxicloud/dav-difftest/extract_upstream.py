"""Exact pinned persistence constructors/getters in minimal dependency carriers.
No method body is rewritten. Result alias removes the unused error dependency;
UUID/chrono and all original field types are retained. The Rust kernel uses
UTF-8 vectors, full-width UUID integers, timestamp components and day ordinals.
"""
from pathlib import Path
import subprocess,sys,re,json,hashlib
root=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(root/'prove/ports/rustfs/difftest'))
from count_loc import item
base=Path(__file__).resolve().parent
rev='8c0dd334cf065ad11f60f9be24e2aafd5dda7550'
meta=json.loads((base/'metadata.json').read_text());texts={};hashes={}
for file in {m['file'] for m in meta}:
 path='src/domain/entities/'+file+'.rs';texts[file]=subprocess.check_output(['git','-C',str(root/'prove/results/upstream/oxicloud.git'),'show',rev+':'+path],text=True);hashes[path]=hashlib.sha256(texts[file].encode()).hexdigest()
refs='use chrono::{DateTime,Utc,NaiveDate}; use uuid::Uuid; type Result<T> = std::result::Result<T,()>;\n'
for file,ty in [('contact','Email'),('contact','Phone'),('contact','Address'),('device_code','DeviceCodeStatus'),('trashed_item','TrashedItemType')]:
 refs+=('#[derive(Clone,Copy,Debug)]\n' if ty in ['DeviceCodeStatus','TrashedItemType'] else '#[derive(Clone,Debug)]\n')+item(texts[file],r'pub (?:struct|enum) '+ty+r'\b')+'\n'
for m in meta:
 text=texts[m['file']];ty=m['type'];body=next(item(text[q.start():],r'impl '+ty+r'\s*\{') for q in re.finditer(r'impl '+ty+r'\s*\{',text) if 'fn '+m['ctor']+'(' in item(text[q.start():],r'impl '+ty+r'\s*\{'))
 refs+='#[derive(Clone,Debug)]\n'+item(text,r'pub struct '+ty+r'\b')+'\nimpl '+ty+' {\n'
 for name in m['methods']:refs+=item(body,r'    pub fn '+name+r'\(')+'\n'
 refs+='}\n'
(base/'src/reference.rs').write_text(refs)
(base/'identity.json').write_text(json.dumps({'revision':rev,'source_sha256':hashes,'reference_sha256':hashlib.sha256(refs.encode()).hexdigest(),'boundary':'Exact selected constructor/getter bodies and complete product fields in minimal carriers; actual uuid/chrono semantics retained. Parser/random/clock methods excluded.'},indent=2)+'\n')
