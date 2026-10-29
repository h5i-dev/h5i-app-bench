from pathlib import Path
import subprocess,gzip,json,re,hashlib
root=Path(__file__).resolve().parents[5];pin='f608c4fe14dfd8d5df8edeed470bf1fb92060abd';repo=root/'prove/results/upstream/kanidm.git';b=Path(__file__).resolve().parent;b.mkdir(exist_ok=True)
def show(p):return subprocess.check_output(['git','-C',str(repo),'show',pin+':'+p],text=True)
vers=['dl11','dl12','dl13','dl14','dl15','dl_1_12']
names=['IDM_ACP_OAUTH2_MANAGE','IDM_ACP_ACP_MANAGE_V1','IDM_ACP_APPLICATION_MANAGE_DL8','IDM_ACP_DOMAIN_ADMIN_DL9','IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1','IDM_ACP_SCHEMA_WRITE_ATTRS_V1','IDM_ACP_GROUP_MANAGE_DL9','IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8','IDM_ACP_SCHEMA_WRITE_CLASSES_V1','IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8','IDM_ACP_SYNC_ACCOUNT_MANAGE_V1']
with gzip.open(root/'prove/results/source-coverage/kernel-ceiling-items.jsonl.gz','rt')as f:rs=[json.loads(l)for l in f]
items={v:{r['name']:r for r in rs if r['app']=='kanidm'and r['file']==f'server/lib/src/migration_data/{v}/access.rs'and r['kind']=='static'}for v in vers}
records={};texts={}
for v in vers:
 p=f'server/lib/src/migration_data/{v}/access.rs';s=show(p);ls=s.splitlines();texts[v]='use super::*;\n'
 for n in ['FILTER_RECYCLED_OR_TOMBSTONE','FILTER_ANDNOT_TOMBSTONE_OR_RECYCLED','FILTER_HP','FILTER_HP_OR_RECYCLED_OR_TOMBSTONE','FILTER_ANDNOT_HP_OR_RECYCLED_OR_TOMBSTONE']+names:
  row=items[v][n];frag='\n'.join(ls[row['start']-1:row['end']]);texts[v]+=frag+'\n';records[v+'/'+n]={**row,'sha256':hashlib.sha256(frag.encode()).hexdigest()}
 (b/(v+'.rs')).write_text(texts[v])
alltext='\n'.join(texts.values());attrs=sorted(set(re.findall(r'Attribute::(\w+)',alltext)));classes=sorted(set(re.findall(r'EntryClass::(\w+)',alltext)));uids=sorted(set(re.findall(r'\bUUID_\w+',alltext)))
uuidtext=show('server/lib/src/constants/uuids.rs');uuidvalues={n:int(s.replace('-',''),16)for n,s in re.findall(r'pub const (UUID_\w+): Uuid =\s*uuid!\("([0-9a-f-]+)"\);',uuidtext)}
consts=show('proto/src/constants.rs');stringconsts=dict(re.findall(r'pub const (\w+): &str =\s*"([^"]*)";',consts));stringconsts.update(dict(re.findall(r'pub const (\w+): &str =\s*"([^"]*)";',uuidtext)))
attrtext=show('proto/src/attribute.rs');attrmap=dict(re.findall(r'Attribute::(\w+) => (\w+),',attrtext));clstext=show('server/lib/src/constants/entries.rs');clsmap=dict(re.findall(r'EntryClass::(\w+) => (\w+),',clstext))
attrmap.update(dict(re.findall(r'Attribute::(\w+) => \{\s*(\w+)\s*\}',attrtext)))
clsmap.update(dict(re.findall(r'EntryClass::(\w+) => \{\s*(\w+)\s*\}',clstext)))
# All filter operands use the actual pinned canonical strings, not Rust variant names.
astrings={a:stringconsts[attrmap[a]]for a in attrs};cstrings={a:stringconsts[clsmap[a]]for a in classes}
fields=['search_attrs','modify_present_attrs','modify_removed_attrs','modify_classes','modify_present_classes','modify_remove_classes','create_classes','create_attrs']
l='''#![allow(dead_code,non_upper_case_globals,non_snake_case)]
use std::sync::LazyLock;
use std::fmt;
#[derive(Clone,Copy,Debug)] struct Uuid(u128);
impl fmt::Display for Uuid { fn fmt(&self,f:&mut fmt::Formatter)->fmt::Result {let n=self.0;write!(f,"{:08x}-{:04x}-{:04x}-{:04x}-{:012x}",n>>96,(n>>80)&65535,(n>>64)&65535,(n>>48)&65535,n&0xffffffffffff)}}
#[derive(Clone,Copy,Debug)] struct Attribute(u16);
impl Attribute {
'''
for i,a in enumerate(attrs):l+=f' const {a}:Self=Self({i});\n'
l+='}\nimpl fmt::Display for Attribute {fn fmt(&self,f:&mut fmt::Formatter)->fmt::Result{let names='+str(list(astrings.values())).replace("'",'"')+';f.write_str(names[self.0 as usize])}}\n'
l+='#[derive(Clone,Copy,Debug)] struct EntryClass(u16);\nimpl EntryClass {\n'
for i,a in enumerate(classes):l+=f' const {a}:Self=Self({i});\n'
l+='}\nimpl fmt::Display for EntryClass {fn fmt(&self,f:&mut fmt::Formatter)->fmt::Result{let names='+json.dumps(list(cstrings.values()))+';f.write_str(names[self.0 as usize])}}\n'
for n in uids:l+=f'const {n}:Uuid=Uuid({uuidvalues[n]});\n'
for n in sorted(set(re.findall(r'\bSTR_UUID_\w+',alltext))):l+=f'const {n}:&str={json.dumps(stringconsts[n])};\n'
l+='''#[derive(Clone,Debug)] enum ProtoFilter {Eq(String,String),And(Vec<Self>),Or(Vec<Self>),AndNot(Box<Self>),SelfUuid}
macro_rules! match_class_filter {($c:expr)=>{ProtoFilter::Eq(Attribute::Class.to_string(),$c.to_string())}}
#[derive(Clone,Debug,Default)] enum BuiltinAcpReceiver {#[default] None,Group(Vec<Uuid>),EntryManager}
#[derive(Clone,Debug,Default)] enum BuiltinAcpTarget {#[default] None,Filter(ProtoFilter)}
#[derive(Clone,Debug,Default)] struct BuiltinAcp {
 classes:Vec<EntryClass>, name:&'static str, uuid:Uuid, description:&'static str,
 receiver:BuiltinAcpReceiver,target:BuiltinAcpTarget,
'''
# Uuid defaults only carrier requirement.
l+=''.join(f' {f}:Vec<'+('EntryClass'if f.endswith('classes')else'Attribute')+'>,\n'for f in fields)+'}\nimpl Default for Uuid {fn default()->Self{Self(0)}}\n'
l+=''.join(f'mod {v} {{include!("{v}.rs");}}\n'for v in vers)
l+='''fn len_bytes(n:usize,b:&mut Vec<u8>){assert!(n<=65535);b.extend_from_slice(&(n as u16).to_le_bytes());}
fn filter_bytes(f:&ProtoFilter,b:&mut Vec<u8>){match f {
 ProtoFilter::Eq(a,v)=>{b.push(0);len_bytes(a.len(),b);b.extend_from_slice(a.as_bytes());len_bytes(v.len(),b);b.extend_from_slice(v.as_bytes());},
 ProtoFilter::And(xs)|ProtoFilter::Or(xs)=>{b.push(if matches!(f,ProtoFilter::And(_)){1}else{2});len_bytes(xs.len(),b);for x in xs{filter_bytes(x,b)}},
 ProtoFilter::AndNot(x)=>{b.push(3);filter_bytes(x,b)},ProtoFilter::SelfUuid=>b.push(4)}}
fn render(v:&BuiltinAcp)->String {
 let (receiver,groups)=match &v.receiver {BuiltinAcpReceiver::None=>(0,vec![]),BuiltinAcpReceiver::Group(xs)=>(1,xs.iter().map(|x|x.0).collect::<Vec<_>>()),BuiltinAcpReceiver::EntryManager=>(2,vec![])};
 let mut target=vec![];if let BuiltinAcpTarget::Filter(f)=&v.target{filter_bytes(f,&mut target)};
 format!("{{\\\"classes\\\":{:?},\\\"name\\\":{:?},\\\"uuid\\\":{},\\\"description\\\":{:?},\\\"receiver\\\":{},\\\"groups\\\":{:?},\\\"target\\\":{:?}'''
# Correct Rust format string escape generation in direct string below.
l=l[:l.index('fn render')]+'''fn render(v:&BuiltinAcp)->String {
 let (receiver,groups)=match &v.receiver {BuiltinAcpReceiver::None=>(0,vec![]),BuiltinAcpReceiver::Group(xs)=>(1,xs.iter().map(|x|x.0).collect::<Vec<_>>()),BuiltinAcpReceiver::EntryManager=>(2,vec![])};
 let mut target=vec![];if let BuiltinAcpTarget::Filter(f)=&v.target{filter_bytes(f,&mut target)};
'''
keys=['classes','name','uuid','description','receiver','groups','target']+fields
args=['v.classes.iter().map(|x|x.0).collect::<Vec<_>>()','v.name.as_bytes()','v.uuid.0','v.description.as_bytes()','receiver','groups','target']+[f'v.{f}.iter().map(|x|x.0).collect::<Vec<_>>()'for f in fields]
fmt='{{'+','.join('\\"'+k+'\\":'+('{}'if k in ['uuid','receiver']else'{:?}')for k in keys)+'}}'
l+=' format!("'+fmt+'",'+','.join(args)+')\n}\nfn main(){\n'
for v in vers:
 for n in names:l+=f' println!("{{}}\\t{{}}", "{v}/{n}", render(&{v}::{n}));\n'
l+='}\n';(b/'main.rs').write_text(l);(b/'metadata.json').write_text(json.dumps({'revision':pin,'records':records,'attributes':attrs,'attribute_strings':astrings,'classes':classes,'class_strings':cstrings,'uuid_values':{n:uuidvalues[n]for n in uids},'profiles':names,'versions':vers,'fields':fields},indent=2)+'\n')
print(b,len(records),len(attrs),len(classes))

def project_reference(b, fields, names, vers):
 l=(b/'main.rs').read_text()
 l+='\nfn observe(v:&BuiltinAcp)->kanidm_kernel::acp_defaults::Profile {\n let (receiver,groups)=match &v.receiver {BuiltinAcpReceiver::None=>(0,vec![]),BuiltinAcpReceiver::Group(xs)=>(1,xs.iter().map(|x|x.0).collect()),BuiltinAcpReceiver::EntryManager=>(2,vec![])};\n let mut target=vec![];if let BuiltinAcpTarget::Filter(f)=&v.target{filter_bytes(f,&mut target)};\n kanidm_kernel::acp_defaults::Profile {classes:v.classes.iter().map(|x|x.0).collect(),name:v.name.as_bytes().to_vec(),uuid:v.uuid.0,description:v.description.as_bytes().to_vec(),receiver,groups,target,\n'
 for f in fields:l+=f'{f}:v.{f}.iter().map(|x|x.0).collect(),\n'
 l+='}\n}\npub fn profiles()->Vec<(&\'static str,kanidm_kernel::acp_defaults::Profile)>{vec![\n'
 for v in vers:
  for n in names:l+=f'("{v}/{n}",observe(&{v}::{n})),\n'
 l+=']}\n';(b/'reference.rs').write_text(l)
project_reference(b,fields,names,vers)
