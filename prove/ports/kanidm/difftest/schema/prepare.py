"""Extract schema tag dispatch unchanged from Kanidm's pinned git object.
Payload validators are an explicit supplied Boolean at this boundary.
"""
import pathlib,re,subprocess,sys,hashlib,json
PIN='f608c4fe14dfd8d5df8edeed470bf1fb92060abd'
repo=sys.argv[1]
def source(p):return subprocess.check_output(['git','--git-dir='+repo,'show',PIN+':server/lib/src/'+p]).decode()
value=source('value.rs');schema=source('schema.rs')
syntax=re.search(r'pub enum SyntaxType \{([\s\S]*?)\n\}',value).group(1)
variants=re.findall(r'^    (\w+) = (\d+),',syntax,re.M)
# Copy just the complete methods, including their unchanged result/error branches.
a=schema.index('    pub fn validate_partialvalue(');b=schema.index('\n}\n',a)
methods=schema[a:b]
partial={};full={}
for name,dst in [('PartialValue',partial),('Value',full)]:
 for m in re.finditer(r'\b'+name+r'::(\w+)(\([^\n]*?\)| \{ \.\. \})?',methods):
  var,args=m.groups();arity=0 if args is None else (1+args.count(',') if args.startswith('(') else -1)
  dst[var]=arity
# Include variants rejected by wildcard branches. Preserve existing tag IDs.
for name, dst in [('PartialValue', partial), ('Value', full)]:
 body = re.search(r'pub enum '+name+r' \{([\s\S]*?)\n\}', value).group(1)
 for variant in re.findall(r'^    (\w+)(?:\(| \{|,)', body, re.M):
  if variant not in dst: dst[variant] = 1
# Source methods use references to ValueSet with independently supplied inner validation.
header='''// Generated pinned reference. Regenerate with schema/prepare.py; do not edit.
#![allow(dead_code,unused_variables)]
use std::fmt;
macro_rules! error { ($($t:tt)*) => {} }
macro_rules! trace { ($($t:tt)*) => {} }
macro_rules! admin_error { ($($t:tt)*) => {} }
type Attribute = String;
#[derive(Debug, PartialEq, Eq)]
pub enum SchemaError { InvalidAttributeSyntax(String) }
'''
out=header+'#[derive(Clone,Copy,Debug,PartialEq,Eq)]\npub enum SyntaxType {\n'+''.join('    '+n+' = '+i+',\n' for n,i in variants)+'}\n'
for name,table in [('PartialValue',partial),('Value',full)]:
 out+='#[derive(Debug)]\npub enum '+name+' {\n'
 for n,arity in table.items():
  args='' if arity==0 else (' { valid: bool }' if arity==-1 else '('+','.join(['bool']+['u8']*(arity-1))+')')
  out+='    '+n+args+',\n'
 out+='}\n'
out+='pub const PARTIAL_TAG_COUNT: usize = '+str(len(partial))+';\n'
out+='pub const VALUE_TAG_COUNT: usize = '+str(len(full))+';\n'
out+='impl Value { fn validate(&self)->bool { match self {\n'
for n,arity in full.items():
 args=' { valid }' if arity==-1 else '(valid'+',_'*(arity-1)+')'
 out+='    Self::'+n+args+' => *valid,\n'
out+='}}}\n'
out+='''pub struct ValueSet { pub syntax: SyntaxType, pub count: usize, pub valid: bool }
impl ValueSet { fn len(&self)->usize {self.count} fn syntax(&self)->SyntaxType {self.syntax}
fn validate(&self,_:&SchemaAttribute)->bool {self.valid} }
#[derive(Debug)]
pub struct SchemaAttribute {pub syntax: SyntaxType,pub multivalue: bool,pub name: String}
impl SchemaAttribute {
'''+methods+'\n}\n'
# Conversions are test seams only, outside copied bodies.
out+='pub fn syntax(n: usize)->SyntaxType { match n {\n'+''.join(i+' => SyntaxType::'+n+',\n' for n,i in variants)+'_=>panic!() }}\n'
for name,table in [('PartialValue',partial),('Value',full)]:
 out+='pub fn '+('partial' if name=='PartialValue' else 'value')+'(n:usize,valid:bool)->'+name+' { match n {\n'
 for i,(n,arity) in enumerate(table.items()):
  args='' if arity==0 else (' { valid }' if arity==-1 else '('+','.join(['valid' if name=='Value' else 'true']+['0']*(arity-1))+')')
  out+=str(i)+'=>'+name+'::'+n+args+',\n'
 out+='_=>panic!() }}\n'
p=pathlib.Path(__file__).with_name('reference.rs');p.write_text(out)
meta={'pin':PIN,'schema_sha256':hashlib.sha256(schema.encode()).hexdigest(),'value_sha256':hashlib.sha256(value.encode()).hexdigest(),'syntaxes':variants,'partial_tags':partial,'value_tags':full}
p.with_name('tags.json').write_text(json.dumps(meta,indent=2)+'\n')
print('reference sha256='+hashlib.sha256(out.encode()).hexdigest());print(len(variants),'syntaxes',len(partial),'partial tags',len(full),'value tags')
