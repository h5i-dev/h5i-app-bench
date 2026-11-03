"""Extract all pinned migration schema initializers verbatim into typed carriers."""
from pathlib import Path
import subprocess,gzip,json,re,hashlib
folder=Path(__file__).resolve().parent
root=folder.parents[4]
revision='f608c4fe14dfd8d5df8edeed470bf1fb92060abd'
repo=root/'prove/results/upstream/kanidm.git'
def show(p):return subprocess.check_output(['git','-C',str(repo),'show',revision+':'+p],text=True)
versions=['system','dl11','dl12','dl13','dl14','dl15','dl_1_12']
with gzip.open(root/'prove/results/source-coverage/kernel-ceiling-items.jsonl.gz','rt')as f:rows=[json.loads(l)for l in f]
records={};texts={}
for v in versions:
 p=f'server/lib/src/migration_data/{v}/schema.rs';ls=show(p).splitlines();texts[v]='use super::*;\n'
 for r in rows:
  if r['app']=='kanidm'and r['file']==p and r['kind']=='static':
   frag='\n'.join(ls[r['start']-1:r['end']]);texts[v]+=frag+'\n';records[v+'/'+r['name']]={**r,'sha256':hashlib.sha256(frag.encode()).hexdigest()}
 (folder/(v+'.rs')).write_text(texts[v])
text='\n'.join(texts.values())
attrs=sorted(set(re.findall(r'Attribute::(\w+)',text)));classes=sorted(set(re.findall(r'EntryClass::(\w+)',text)));syntaxes=sorted(set(re.findall(r'SyntaxType::(\w+)',text))|{'Utf8String'})
uuids=sorted(set(re.findall(r'\bUUID_\w+',text)))
uuidtext=show('server/lib/src/constants/uuids.rs');uuidvalues={n:int(s.replace('-',''),16)for n,s in re.findall(r'pub const (UUID_\w+): Uuid =\s*uuid!\("([0-9a-f-]+)"\);',uuidtext)}
consts=dict(re.findall(r'pub const (\w+): &str =\s*"([^"]*)";',show('proto/src/constants.rs')))
clsmap=dict(re.findall(r'EntryClass::(\w+) => (\w+),',show('server/lib/src/constants/entries.rs')))
clsmap.update(dict(re.findall(r'EntryClass::(\w+) => \{\s*(\w+)\s*\}',show('server/lib/src/constants/entries.rs'))))
attrmap=dict(re.findall(r'Attribute::(\w+) => (\w+),',show('proto/src/attribute.rs')))
attrmap.update(dict(re.findall(r'Attribute::(\w+) => \{\s*(\w+)\s*\}',show('proto/src/attribute.rs'))))
syntaxvals={n:int(v)for n,v in re.findall(r'^    (\w+) = (\d+),',show('server/lib/src/value.rs'),re.M)}
l='''#![allow(dead_code,non_upper_case_globals,non_snake_case)]
use std::sync::LazyLock;
#[derive(Clone,Copy,Debug,Default)]struct Uuid(u128);
#[derive(Clone,Copy,Debug,Default)]struct Attribute(u16);
impl Attribute {
'''+''.join(f'const {a}:Self=Self({i});\n'for i,a in enumerate(attrs))+'}\n'
l+='impl From<Attribute> for String {fn from(v:Attribute)->Self{let names='+json.dumps([consts[attrmap[a]]for a in attrs])+';names[v.0 as usize].to_owned()}}\n'
l+='#[derive(Clone,Copy,Debug)]struct EntryClass(&\'static str);\nimpl EntryClass{\n'+''.join(f'const {c}:Self=Self({json.dumps(consts[clsmap[c]])});\n'for c in classes)+'}\n'
l+='impl From<EntryClass> for String {fn from(v:EntryClass)->Self{v.0.to_owned()}}\n'
l+='#[derive(Clone,Copy,Debug)]struct SyntaxType(u16);\nimpl SyntaxType{\n'+''.join(f'const {s}:Self=Self({syntaxvals[s]});\n'for s in syntaxes)+'}\nimpl Default for SyntaxType {fn default()->Self{Self::Utf8String}}\n'
l+='#[derive(Clone,Copy,Debug,Default)]enum Replicated {#[default]True,False}\n'
l+=''.join(f'const {n}:Uuid=Uuid({uuidvalues[n]});\n'for n in uuids)
attr_fields={'name':'u16','uuid':'u128','description':'Vec<u8>','multivalue':'bool','unique':'bool','phantom':'bool','sync_allowed':'bool','replicated':'bool','indexed':'bool','syntax':'u16'}
class_fields={'name':'Vec<u8>','uuid':'u128','description':'Vec<u8>','sync_allowed':'bool',**{f:'Vec<u16>'for f in ['systemmay','may','systemmust','must']},**{f:'Vec<u8>'for f in ['systemsupplements','supplements','systemexcludes','excludes']}}
l+='#[derive(Clone,Debug,Default)]struct SchemaAttribute {name:Attribute,uuid:Uuid,description:String,multivalue:bool,unique:bool,phantom:bool,sync_allowed:bool,replicated:Replicated,indexed:bool,syntax:SyntaxType}\n'
l+='#[derive(Clone,Debug,Default)]struct SchemaClass {name:String,uuid:Uuid,description:String,sync_allowed:bool,systemmay:Vec<Attribute>,may:Vec<Attribute>,systemmust:Vec<Attribute>,must:Vec<Attribute>,systemsupplements:Vec<String>,supplements:Vec<String>,systemexcludes:Vec<String>,excludes:Vec<String>}\n'
l+=''.join(f'mod {v}{{include!("{v}.rs");}}\n'for v in versions)
l+='fn strings(xs:&[String])->Vec<u8>{let mut b=vec![];for s in xs{assert!(s.len()<=65535);b.extend_from_slice(&(s.len()as u16).to_le_bytes());b.extend_from_slice(s.as_bytes());}b}\n'
projections={}
for kind,fields in [('Attribute',attr_fields),('Class',class_fields)]:
 args=[]
 for f,ty in fields.items():
  expr='v.'+f
  if f=='uuid':expr+='.0'
  elif f in ['name','syntax']and kind=='Attribute':expr+='.0'
  elif f=='replicated':expr='matches!(v.replicated,Replicated::True)'
  elif ty=='Vec<u8>':expr=('strings(&v.'+f+')'if f in ['systemsupplements','supplements','systemexcludes','excludes']else expr+'.as_bytes().to_vec()')
  elif ty=='Vec<u16>':expr+='.iter().map(|x|x.0).collect::<Vec<_>>()'
  args.append(expr)
 projections[kind]=args
 fmt='{{'+','.join('\\"'+f+'\\":'+('{:?}'if ty.startswith('Vec')else'{}')for f,ty in fields.items())+'}}'
 l+=f'fn render_{kind.lower()}(v:&Schema{kind})->String{{format!("{fmt}",'+','.join(args)+')}\n'
l+='fn main(){\n'
for key in records:
 v,n=key.split('/');kind='attribute'if n.startswith('SCHEMA_ATTR_')else'class'
 l+=f'println!("{{}}\\t{{}}","{key}",render_{kind}(&{v}::{n}));\n'
l+='}\n';(folder/'main.rs').write_text(l)
for kind,fields in [('Attribute',attr_fields),('Class',class_fields)]:
 l+=f'fn observe_{kind.lower()}(v:&Schema{kind})->kanidm_kernel::schema_catalog::{kind}Record {{kanidm_kernel::schema_catalog::{kind}Record {{'+','.join(f'{f}:{expr}'for f,expr in zip(fields,projections[kind]))+'}}\n'
 l+=f'pub fn {kind.lower()}_records()->Vec<(&\'static str,kanidm_kernel::schema_catalog::{kind}Record)>{{vec![\n'
 for key in records:
  v,n=key.split('/')
  if (n.startswith('SCHEMA_ATTR_'))==(kind=='Attribute'):l+=f'("{key}",observe_{kind.lower()}(&{v}::{n})),\n'
 l+=']}\n'
(folder/'reference.rs').write_text(l)
(folder/'metadata.json').write_text(json.dumps({'revision':revision,'records':records,'attributes':attrs,'attribute_strings':{a:consts[attrmap[a]]for a in attrs},'class_strings':{c:consts[clsmap[c]]for c in classes},'syntax_values':{s:syntaxvals[s]for s in syntaxes},'fields':{'Attribute':attr_fields,'Class':class_fields}},indent=2)+'\n')
print(len(records),'pinned schema initializers')
