"""Compile pinned account and remaining simple entry constructors unchanged."""
from pathlib import Path
import gzip,json,re,subprocess,hashlib
folder=Path(__file__).resolve().parent;root=folder.parents[4]
revision='f608c4fe14dfd8d5df8edeed470bf1fb92060abd';repo=root/'prove/results/upstream/kanidm.git'
def show(p):return subprocess.check_output(['git','-C',str(repo),'show',revision+':'+p],text=True)
versions=['dl11','dl12','dl13','dl14','dl15','dl_1_12']
rows=[json.loads(l)for l in gzip.open(root/'prove/results/source-coverage/kernel-ceiling-items.jsonl.gz','rt')]
records={};texts={};kinds={}
for v in versions:
 text='use super::*;\n'
 for base in ['accounts','key_providers','system_config']:
  p=f'server/lib/src/migration_data/{v}/{base}.rs';ls=show(p).splitlines()
  for r in rows:
   if r['app']!='kanidm' or r['file']!=p or r['kind']not in ['static','fn'] or r['name']=='e_system_config_v1':continue
   frag='\n'.join(ls[r['start']-1:r['end']]);text+=frag+'\n';key=v+'/'+r['name'];records[key]={**r,'sha256':hashlib.sha256(frag.encode()).hexdigest()};kinds[key]='Account'if base=='accounts'else'Entry'
 (folder/(v+'.rs')).write_text(text);texts[v]=text
text='\n'.join(texts.values());attrs=sorted(set(re.findall(r'Attribute::(\w+)',text)));classes=sorted(set(re.findall(r'EntryClass::(\w+)',text)))
consts={}
for p in ['proto/src/constants.rs','server/lib/src/constants/uuids.rs']:consts.update(dict(re.findall(r'pub const (\w+): &str =\s*"([^"]*)";',show(p))))
attrmap=dict(re.findall(r'Attribute::(\w+) => (\w+),',show('proto/src/attribute.rs')));clsmap=dict(re.findall(r'EntryClass::(\w+) => (\w+),',show('server/lib/src/constants/entries.rs')))
uuidvalues={n:int(s.replace('-',''),16)for n,s in re.findall(r'pub const (UUID_\w+): Uuid =\s*uuid!\("([0-9a-f-]+)"\);',show('server/lib/src/constants/uuids.rs'))}
l='''#![allow(dead_code,non_upper_case_globals,non_snake_case)]
use std::{sync::LazyLock,collections::BTreeMap};
#[derive(Clone,Copy,Debug)]struct Uuid(u128);
#[derive(Clone,Copy,Debug,PartialEq,Eq,PartialOrd,Ord)]struct Attribute(&'static str);
impl Attribute {
'''+''.join(f'const {a}:Self=Self({json.dumps(consts[attrmap[a]])});\n'for a in attrs)+'}\n'
l+='#[derive(Clone,Copy,Debug)]struct EntryClass(&\'static str);\nimpl EntryClass{\n'+''.join(f'const {c}:Self=Self({json.dumps(consts[clsmap[c]])});\n'for c in classes)+'fn to_value(self)->Value{Value::Class(self.0)}}\n'
l+=''.join(f'const {n}:Uuid=Uuid({uuidvalues[n]});\n'for n in sorted(set(re.findall(r'\bUUID_\w+',text))))
l+='''#[derive(Clone,Copy,Debug)]enum AccountType{ServiceAccount}
#[derive(Clone,Debug)]struct BuiltinAccount{account_type:AccountType,entry_managed_by:Option<Uuid>,name:&'static str,uuid:Uuid,description:&'static str,displayname:&'static str}
#[derive(Clone,Debug)]enum Value{Class(&'static str),Uuid(Uuid),Utf8(String),Iname(String),Uint32(u32)}
impl Value{fn new_utf8s(s:&str)->Self{Self::Utf8(s.to_owned())}fn new_iname(s:&str)->Self{Self::Iname(s.to_lowercase())}}
type EntryInitNew=BTreeMap<Attribute,Vec<Value>>;
fn entry_init_fn<const N:usize>(xs:[(Attribute,Value);N])->EntryInitNew{let mut e=BTreeMap::new();for(a,v)in xs{e.entry(a).or_insert_with(Vec::new).push(v)}e}
fn string_bytes(s:&str,b:&mut Vec<u8>){b.extend_from_slice(&(s.len()as u16).to_le_bytes());b.extend_from_slice(s.as_bytes())}
fn bytes(e:&EntryInitNew)->Vec<u8>{let mut b=vec![];for(a,vs)in e{string_bytes(a.0,&mut b);let mut values=vec![];for v in vs{let mut vbytes=vec![];match v{Value::Class(s)=>{vbytes.push(0);string_bytes(s,&mut vbytes)},Value::Uuid(u)=>{vbytes.push(1);vbytes.extend_from_slice(&u.0.to_le_bytes())},Value::Utf8(s)=>{vbytes.push(2);string_bytes(s,&mut vbytes)},Value::Iname(s)=>{vbytes.push(3);string_bytes(s,&mut vbytes)},Value::Uint32(n)=>{vbytes.push(4);vbytes.extend_from_slice(&n.to_le_bytes())}}values.push(vbytes)}values.sort();values.dedup();b.extend_from_slice(&(values.len()as u16).to_le_bytes());for v in values{b.extend(v)}}b}
'''
l+=''.join(f'mod {v}{{include!("{v}.rs");}}\n'for v in versions)
fields={'Account':{'account_type':'u8','has_entry_manager':'bool','entry_manager':'u128','name':'Vec<u8>','uuid':'u128','description':'Vec<u8>','displayname':'Vec<u8>'},'Entry':{'bytes':'Vec<u8>'}}
args={'Account':['0u8','v.entry_managed_by.is_some()','v.entry_managed_by.map(|u|u.0).unwrap_or(0)','v.name.as_bytes().to_vec()','v.uuid.0','v.description.as_bytes().to_vec()','v.displayname.as_bytes().to_vec()'],'Entry':['bytes(v)']}
for k,fs in fields.items():
 ty='BuiltinAccount'if k=='Account'else'EntryInitNew';fmt='{{'+','.join('\\"'+f+'\\":'+('{:?}'if t.startswith('Vec')else'{}')for f,t in fs.items())+'}}'
 l+=f'fn render_{k}(v:&{ty})->String{{format!("'+fmt+'",'+','.join(args[k])+')}\n'
def expr(key):
 v,n=key.split('/');return f'{v}::{n}'+('()'if records[key]['kind']=='fn'else'')
l+='fn main(){\n'+''.join(f'println!("{{}}\\t{{}}","{key}",render_{k}(&{expr(key)}));\n'for key,k in kinds.items())+'}\n';(folder/'main.rs').write_text(l)
for k,fs in fields.items():
 ty='BuiltinAccount'if k=='Account'else'EntryInitNew';l+=f'fn observe_{k}(v:&{ty})->kanidm_kernel::entry_catalog::{k}Record{{kanidm_kernel::entry_catalog::{k}Record{{'+','.join(f'{f}:{a}'for f,a in zip(fs,args[k]))+ '}}\n'
 l+=f'pub fn {k.lower()}_records()->Vec<(&\'static str,kanidm_kernel::entry_catalog::{k}Record)>{{vec![\n'+''.join(f'("{key}",observe_{k}(&{expr(key)})),\n'for key in records if kinds[key]==k)+']}\n'
(folder/'reference.rs').write_text(l);(folder/'metadata.json').write_text(json.dumps({'revision':revision,'records':records,'fields':fields,'kinds':kinds,'attribute_strings':{a:consts[attrmap[a]]for a in attrs},'class_strings':{a:consts[clsmap[a]]for a in classes},'uuid_values':{n:uuidvalues[n]for n in sorted(set(re.findall(r'\bUUID_\w+',text)))}},indent=2)+'\n')
print(len(records),'pinned account/entry constructors')
