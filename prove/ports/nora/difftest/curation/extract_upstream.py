"""Copy pinned CurationEngine methods without editing their bodies.
Run at repo root. Trait outcomes and text handles are test adapters, not reference
implementations. SHA of the complete upstream file is recorded alongside output.
"""
import sys,json,hashlib,subprocess
from pathlib import Path
sys.path.insert(0,'prove/ports/rustfs/difftest')
from count_loc import item
rev='f864a9a95e8669b00202c18b0b774ab0fc2e56cc'
f='nora-registry/src/curation.rs'
s=subprocess.check_output(['git','-C','prove/results/upstream/nora.git','show',f'{rev}:{f}'],text=True)
heads=[r'pub struct FilterRequest\b',r'pub enum Decision\b',r'pub trait ProxyFilter\b',r'pub struct EvaluationResult\b',r'pub struct CurationEngine\b',r'impl CurationEngine\b',r'pub struct CurationMetrics\b',r'impl CurationMetrics\b',r'pub fn check_download\b',r'pub fn check_namespace_isolation\b',r'pub fn is_internal_namespace\b',r'pub fn namespace_filter_active\b',r'pub fn verify_integrity\b',r'pub fn verify_integrity_by_hash\b']
# Struct/enum derive traits used by unchanged reference methods.
parts=[]
for h in heads:
    text=item(s,h)
    if 'enum Decision' in text: text='#[derive(Debug,Clone,PartialEq)]\n'+text
    parts.append(text)
header='// Verbatim pinned items; declarations/imports only adapted for the test crate.\nuse crate::config::{CurationConfig,CurationMode};\nuse crate::RegistryType;\nuse crate::{axum,sha2,hex};\nuse crate::ConstantTimeEq;\nuse crate::axum::response::{Response,IntoResponse};\nuse std::sync::atomic::{AtomicU64,Ordering};\n'
out=Path(__file__).with_name('reference.rs');out.write_text(header+'\n\n'.join(parts)+'\n'+'''
struct BlockedResponse { rule:String,reason:String,registry:String,package:String,version:Option<String> }
impl IntoResponse for BlockedResponse {fn into_response(self)->Response {(self.rule,self.reason)}}
''')
Path(__file__).with_name('identity.json').write_text(json.dumps({'upstream_revision':rev,'file':f,'file_sha256':hashlib.sha256(s.encode()).hexdigest(),'selected_headers':heads,'reference_sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'adapters':['imports and derive attributes','synthetic filters return supplied decisions and static names','test crate supplies config, registry, logging and Prometheus sink','header parsing success/failure, exact text equality, response payload rendering and deterministic hash adapter; crypto is outside this decision test']},indent=2)+'\n')
