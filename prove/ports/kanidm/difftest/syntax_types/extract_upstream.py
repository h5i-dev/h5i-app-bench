"""Reproduce the reference from pinned upstream items; no method-body edits.
Run from any directory after fetching prove/results/upstream/kanidm.git.
"""
from pathlib import Path
import hashlib,json,subprocess,sys,re
root=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(root/'prove/ports/rustfs/difftest'))
from count_loc import item
rev='f608c4fe14dfd8d5df8edeed470bf1fb92060abd'
file='server/lib/src/value.rs'
s=subprocess.check_output(['git','-C',str(root/'prove/results/upstream/kanidm.git'),'show',f'{rev}:{file}'],text=True)
folder=Path(__file__).resolve().parent
syntax=re.sub(r'    #\[default\]\n','',item(s,r'^pub enum SyntaxType'))
index=item(s,r'^pub enum IndexType')
parse=item(s[s.index('impl TryFrom<&str> for SyntaxType'):],r'    fn try_from\(')
fmt=item(s[s.index('impl fmt::Display for SyntaxType'):],r'    fn fmt\(')
indices=item(s[s.index('impl SyntaxType {'):],r'    pub fn index_types\(')
reference='use std::fmt;\n#[derive(Clone,Copy,Debug,PartialEq,Eq)]\n'+syntax+'\n#[derive(Clone,Copy,Debug,PartialEq,Eq)]\n'+index+'\n'
reference+='impl TryFrom<&str> for SyntaxType {type Error=();\n'+parse+'}\n'
reference+='impl fmt::Display for SyntaxType {\n'+fmt+'}\nimpl SyntaxType {\n'+indices+'}\n'
(folder/'reference.rs').write_text(reference)
identity=json.loads((folder/'identity.json').read_text())
identity.update(file_sha256=hashlib.sha256(s.encode()).hexdigest(),reference_sha256=hashlib.sha256(reference.encode()).hexdigest(),selected_methods=['SyntaxType::try_from','SyntaxType::fmt','SyntaxType::index_types'])
(folder/'identity.json').write_text(json.dumps(identity,indent=2)+'\n')
