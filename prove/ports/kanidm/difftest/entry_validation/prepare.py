"""Verbatim Entry::validate from the pinned git object, with representation wrappers."""
import pathlib,sys,subprocess,hashlib,json
pin='f608c4fe14dfd8d5df8edeed470bf1fb92060abd'
s=subprocess.check_output(['git','--git-dir='+sys.argv[1],'show',pin+':server/lib/src/entry.rs']).decode()
a=s.index('    fn validate(&self, schema: &dyn SchemaTransaction)');b=s.index('\n    pub fn seal(',a)
method=s[a:b]
pre='''#![allow(dead_code,unused_variables,non_upper_case_globals)]
use std::{collections::{BTreeMap,BTreeSet},borrow::Borrow,fmt};
use super::candidate::{self,Error};
type Map<K,V> = BTreeMap<K,V>;
macro_rules! trace {($($x:tt)*)=>{}}
macro_rules! admin_debug {($($x:tt)*)=>{}}
macro_rules! admin_warn {($($x:tt)*)=>{}}
macro_rules! admin_error {($($x:tt)*)=>{}}
macro_rules! warn {($($x:tt)*)=>{}}
#[derive(Clone,Debug,PartialEq,Eq,PartialOrd,Ord)]
struct Attribute(u16);
impl Attribute {const Class:Self=Self(0);}
impl fmt::Display for Attribute {fn fmt(&self,f:&mut fmt::Formatter<'_>)->fmt::Result{write!(f,"z{:05}",self.0)}}
enum EntryClass {Conflict,Recycled,ExtensibleObject}
impl From<EntryClass> for String {fn from(c:EntryClass)->String{match c{EntryClass::Conflict=>"conflict",EntryClass::Recycled=>"recycled",EntryClass::ExtensibleObject=>"extensibleobject"}.into()}}
#[derive(Debug)]
enum SchemaError {NoClassFound,InvalidClass(Vec<String>),SupplementsNotSatisfied(Vec<String>),ExcludesNotSatisfied(Vec<String>),Corrupted,MissingMustAttribute(Vec<Attribute>),PhantomAttribute(String),InvalidAttribute(String),InvalidAttributeSyntax(String),AttributeNotValidForClass(String)}
struct ValueSet {classes:Option<BTreeSet<String>>,count:usize,syntax:u16,valid:bool}
impl ValueSet {fn len(&self)->usize{self.count} fn as_iutf8_set(&self)->Option<&BTreeSet<String>>{self.classes.as_ref()}}
struct SchemaAttribute {name:Attribute,phantom:bool,multi:bool,syntax:u16}
impl SchemaAttribute {
 fn validate_ava(&self,name:&Attribute,v:&ValueSet)->Result<(),SchemaError>{
 if (!self.multi && v.count>1) || self.syntax!=v.syntax || !v.valid {Err(SchemaError::InvalidAttributeSyntax(name.to_string()))}else{Ok(())}}
}
struct SchemaClass {systemmust:Vec<Attribute>,must:Vec<Attribute>,systemmay:Vec<Attribute>,may:Vec<Attribute>,systemsupplements:Vec<String>,supplements:Vec<String>,systemexcludes:Vec<String>,excludes:Vec<String>}
trait SchemaTransaction {fn get_classes(&self)->&BTreeMap<String,SchemaClass>;fn get_attributes(&self)->&BTreeMap<Attribute,SchemaAttribute>;}
struct Schema {classes:BTreeMap<String,SchemaClass>,attrs:BTreeMap<Attribute,SchemaAttribute>}
impl SchemaTransaction for Schema {fn get_classes(&self)->&BTreeMap<String,SchemaClass>{&self.classes}fn get_attributes(&self)->&BTreeMap<Attribute,SchemaAttribute>{&self.attrs}}
struct Entry {attrs:BTreeMap<Attribute,ValueSet>,class_present:bool}
impl Entry {
 fn attribute_pres(&self,_:Attribute)->bool{self.class_present}
 fn attribute_equality(&self,_:Attribute,pv:&String)->bool{self.attrs.get(&Attribute::Class).and_then(|v|v.classes.as_ref()).is_some_and(|s|s.contains(pv))}
 fn get_ava_set(&self,a:impl Borrow<Attribute>)->Option<&ValueSet>{self.attrs.get(a.borrow())}
'''
post='''}
fn class_name(n:u16)->String{match n{0=>"conflict".into(),1=>"extensibleobject".into(),2=>"recycled".into(),_=>format!("z{n:05}")}}
fn class_id(s:String)->u16{match s.as_str(){"conflict"=>0,"extensibleobject"=>1,"recycled"=>2,_=>s[1..].parse().unwrap()}}
fn attr_id(s:String)->u16{s[1..].parse().unwrap()}
fn error(e:SchemaError)->Error {match e{
 SchemaError::NoClassFound=>Error::NoClassFound,SchemaError::Corrupted=>Error::Corrupted,
 SchemaError::InvalidClass(v)=>Error::InvalidClass(v.into_iter().map(class_id).collect()),
 SchemaError::SupplementsNotSatisfied(v)=>Error::SupplementsNotSatisfied(v.into_iter().map(class_id).collect()),
 SchemaError::ExcludesNotSatisfied(v)=>Error::ExcludesNotSatisfied(v.into_iter().map(class_id).collect()),
 SchemaError::MissingMustAttribute(v)=>Error::MissingMustAttribute(v.into_iter().map(|a|a.0).collect()),
 SchemaError::PhantomAttribute(s)=>Error::PhantomAttribute(attr_id(s)),
 SchemaError::InvalidAttribute(s)=>Error::InvalidAttribute(attr_id(s)),
 SchemaError::InvalidAttributeSyntax(s)=>Error::InvalidAttributeSyntax(attr_id(s)),
 SchemaError::AttributeNotValidForClass(s)=>Error::AttributeNotValidForClass(attr_id(s))}}
pub fn validate(e:&candidate::Entry,classes:&[candidate::ClassSchema],attrs:&[candidate::AttributeSchema])->Result<(),Error>{
 let schema=Schema {classes:classes.iter().map(|c|(class_name(c.key),SchemaClass {
 systemmust:c.systemmust.iter().copied().map(Attribute).collect(),must:c.must.iter().copied().map(Attribute).collect(),
 systemmay:c.systemmay.iter().copied().map(Attribute).collect(),may:c.may.iter().copied().map(Attribute).collect(),
 systemsupplements:c.systemsupplements.iter().copied().map(class_name).collect(),supplements:c.supplements.iter().copied().map(class_name).collect(),
 systemexcludes:c.systemexcludes.iter().copied().map(class_name).collect(),excludes:c.excludes.iter().copied().map(class_name).collect()})).collect(),
 attrs:attrs.iter().map(|a|(Attribute(a.key),SchemaAttribute{name:Attribute(a.name),phantom:a.phantom,multi:a.multi,syntax:a.syntax})).collect()};
 let entry=Entry {class_present:e.class_present,attrs:e.attrs.iter().map(|a|(Attribute(a.key),ValueSet {
 classes:if a.key==0{e.classes.as_ref().map(|v|v.iter().copied().map(class_name).collect())}else{None},count:a.count,syntax:a.syntax,valid:a.valid})).collect()};
 entry.validate(&schema).map_err(error)
}
'''
p=pathlib.Path(__file__).with_name('reference.rs');p.write_text(pre+method+post)
p.with_name('identity.json').write_text(json.dumps({'pin':pin,'entry_sha256':hashlib.sha256(s.encode()).hexdigest(),'method_sha256':hashlib.sha256(method.encode()).hexdigest()},indent=2)+'\n')
