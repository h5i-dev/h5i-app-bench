"""Compile verbatim pinned group initializers with lossless field projections."""
from pathlib import Path
import gzip,json,re,subprocess,hashlib
folder=Path(__file__).resolve().parent;root=folder.parents[4]
revision='f608c4fe14dfd8d5df8edeed470bf1fb92060abd';repo=root/'prove/results/upstream/kanidm.git'
def show(p):return subprocess.check_output(['git','-C',str(repo),'show',revision+':'+p],text=True)
versions=['dl11','dl12','dl13','dl14','dl15','dl_1_12']
with gzip.open(root/'prove/results/source-coverage/kernel-ceiling-items.jsonl.gz','rt')as f:rows=[json.loads(l)for l in f]
records={};texts={}
for v in versions:
 p=f'server/lib/src/migration_data/{v}/groups.rs';ls=show(p).splitlines();texts[v]='use super::*;\n'
 for r in rows:
  if r['app']=='kanidm'and r['file']==p and r['kind']=='static':
   frag='\n'.join(ls[r['start']-1:r['end']]);texts[v]+=frag+'\n';records[v+'/'+r['name']]={**r,'sha256':hashlib.sha256(frag.encode()).hexdigest()}
 (folder/(v+'.rs')).write_text(texts[v])
text='\n'.join(texts.values());attrs=sorted(set(re.findall(r'Attribute::(\w+)',text)));classes=sorted(set(re.findall(r'EntryClass::(\w+)',text)))
uuids=sorted(set(re.findall(r'\bUUID_\w+',text)));uuidtext=show('server/lib/src/constants/uuids.rs')
uuidvalues={n:int(s.replace('-',''),16)for n,s in re.findall(r'pub const (UUID_\w+): Uuid =\s*uuid!\("([0-9a-f-]+)"\);',uuidtext)}
consts={}
for p in ['proto/src/constants.rs','server/lib/src/constants/uuids.rs']:
 consts.update(dict(re.findall(r'pub const (\w+): &str =\s*"([^"]*)";',show(p))))
attrmap=dict(re.findall(r'Attribute::(\w+) => (\w+),',show('proto/src/attribute.rs')))
clsmap=dict(re.findall(r'EntryClass::(\w+) => (\w+),',show('server/lib/src/constants/entries.rs')))
l='''#![allow(dead_code,non_upper_case_globals,non_snake_case)]
use std::sync::LazyLock;
#[derive(Clone,Copy,Debug,Default)]struct Uuid(u128);
#[derive(Clone,Copy,Debug)]struct Attribute(&'static str);
impl Attribute {
'''+''.join(f'const {a}:Self=Self({json.dumps(consts[attrmap[a]])});\n'for a in attrs)+'}\n'
l+='impl std::fmt::Display for Attribute{fn fmt(&self,f:&mut std::fmt::Formatter)->std::fmt::Result{f.write_str(self.0)}}\n'
l+='#[derive(Clone,Copy,Debug)]struct EntryClass(&\'static str);\nimpl EntryClass{\n'+''.join(f'const {c}:Self=Self({json.dumps(consts[clsmap[c]])});\n'for c in classes)+'fn to_value(self)->Value{Value::Class(self.0.to_owned())}}\n'
l+='impl std::fmt::Display for EntryClass{fn fmt(&self,f:&mut std::fmt::Formatter)->std::fmt::Result{f.write_str(self.0)}}\n'
l+=''.join(f'const {n}:Uuid=Uuid({uuidvalues[n]});\n'for n in uuids)
l+=''.join(f'const {n}:&str={json.dumps(consts[n])};\n'for n in sorted(set(re.findall(r'\bNAME_\w+',text))))
l+='''#[derive(Clone,Debug)]enum Filter{Eq(String,String),And(Vec<Self>)}
#[derive(Clone,Copy,Debug)]enum UiHint{ExperimentalFeatures}
#[derive(Clone,Copy,Debug)]enum CredentialType{Mfa}
#[derive(Clone,Debug)]enum Value{Class(String),CredentialType(CredentialType),UiHint(UiHint)}
impl From<CredentialType> for Value{fn from(v:CredentialType)->Self{Self::CredentialType(v)}}
#[derive(Clone,Debug,Default)]struct BuiltinGroup{
 name:&'static str,description:&'static str,uuid:Uuid,members:Vec<Uuid>,member_create_once:Vec<Uuid>,entry_managed_by:Option<Uuid>,dyngroup:bool,dyngroup_filter:Option<Filter>,extra_attributes:Vec<(Attribute,Value)>}
fn string_bytes(s:&str,b:&mut Vec<u8>){assert!(s.len()<=65535);b.extend_from_slice(&(s.len()as u16).to_le_bytes());b.extend_from_slice(s.as_bytes())}
fn filter_bytes(f:&Filter,b:&mut Vec<u8>){match f {Filter::Eq(a,v)=>{b.push(0);string_bytes(a,b);string_bytes(v,b)},Filter::And(xs)=>{b.push(1);b.extend_from_slice(&(xs.len()as u16).to_le_bytes());for x in xs{filter_bytes(x,b)}}}}
fn extras(xs:&[(Attribute,Value)])->Vec<u8>{let mut b=vec![];for (a,v) in xs{string_bytes(a.0,&mut b);match v{Value::Class(c)=>{b.push(0);string_bytes(c,&mut b)},Value::CredentialType(CredentialType::Mfa)=>{b.push(1);b.extend_from_slice(&10u16.to_le_bytes())},Value::UiHint(UiHint::ExperimentalFeatures)=>b.push(2)}}b}
'''
l+=''.join(f'mod {v}{{include!("{v}.rs");}}\n'for v in versions)
fields={'name':'Vec<u8>','description':'Vec<u8>','uuid':'u128','members':'Vec<u128>','member_create_once':'Vec<u128>','has_entry_manager':'bool','entry_manager':'u128','dyngroup':'bool','filter':'Vec<u8>','extra_attributes':'Vec<u8>'}
args=['v.name.as_bytes().to_vec()','v.description.as_bytes().to_vec()','v.uuid.0','v.members.iter().map(|x|x.0).collect::<Vec<_>>()','v.member_create_once.iter().map(|x|x.0).collect::<Vec<_>>()','v.entry_managed_by.is_some()','v.entry_managed_by.map(|u|u.0).unwrap_or(0)','v.dyngroup','filter','extras(&v.extra_attributes)']
preamble='let mut filter=vec![];if let Some(f)=&v.dyngroup_filter{filter_bytes(f,&mut filter);}'
fmt='{{'+','.join('\\"'+f+'\\":'+('{:?}'if ty.startswith('Vec')else'{}')for f,ty in fields.items())+'}}'
l+='fn render(v:&BuiltinGroup)->String{'+preamble+'format!("'+fmt+'",'+','.join(args)+')}\nfn main(){\n'
for key in records:
 v,n=key.split('/');l+=f'println!("{{}}\\t{{}}","{key}",render(&{v}::{n}));\n'
l+='}\n';(folder/'main.rs').write_text(l)
l+='fn observe(v:&BuiltinGroup)->kanidm_kernel::group_catalog::GroupRecord{'+preamble+'kanidm_kernel::group_catalog::GroupRecord{'+','.join(f'{f}:{a}'for f,a in zip(fields,args))+'}}\npub fn records()->Vec<(&\'static str,kanidm_kernel::group_catalog::GroupRecord)>{vec![\n'
for key in records:
 v,n=key.split('/');l+=f'("{key}",observe(&{v}::{n})),\n'
l+=']}\n';(folder/'reference.rs').write_text(l)
(folder/'metadata.json').write_text(json.dumps({'revision':revision,'records':records,'fields':fields,'attribute_strings':{a:consts[attrmap[a]]for a in attrs},'class_strings':{c:consts[clsmap[c]]for c in classes},'uuid_values':{n:uuidvalues[n]for n in uuids}},indent=2)+'\n')
print(len(records),'pinned group initializers')
