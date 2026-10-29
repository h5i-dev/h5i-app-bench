#![allow(dead_code,non_camel_case_types,unused_imports)]
use kanidm_kernel::migration_defaults as port;
mod reference {
 use std::collections::{BTreeMap,BTreeSet};
 #[derive(Debug,Clone,Copy,PartialEq,Eq,PartialOrd,Ord)]
 pub enum Attribute {Class,Uuid,Description,BadlistPassword}
 #[derive(Debug,Clone,PartialEq,Eq,PartialOrd,Ord)]
 pub enum Value {Uuid(u128),Utf8(String),Iutf8(String)}
 impl Value {
  pub fn new_utf8s(s:&str)->Self{Value::Utf8(s.to_string())}
  pub fn new_iutf8(s:&str)->Self{Value::Iutf8(s.to_lowercase())}
 }
 pub enum EntryClass {Object,SystemConfig,System}
 impl EntryClass {fn to_value(&self)->Value {Value::new_iutf8(match self{Self::Object=>"object",Self::SystemConfig=>"system_config",Self::System=>"system"})}}
 pub const UUID_SYSTEM_CONFIG:u128=0xffffff000027;
 pub type EntryInitNew=BTreeMap<Attribute,BTreeSet<Value>>;
 pub trait AddAva {fn add_ava(&mut self,a:Attribute,v:Value);}
 impl AddAva for EntryInitNew {fn add_ava(&mut self,a:Attribute,v:Value){self.entry(a).or_default().insert(v);}}
 fn entry_init_fn<const N:usize>(pairs:[(Attribute,Value);N])->EntryInitNew {let mut out=EntryInitNew::new();for(a,v)in pairs{out.add_ava(a,v)}out}
 pub mod dl11 {include!("../../difftest/migration_defaults/dl11.rs");}
 pub mod dl12 {include!("../../difftest/migration_defaults/dl12.rs");}
 pub mod dl13 {include!("../../difftest/migration_defaults/dl13.rs");}
 pub mod dl14 {include!("../../difftest/migration_defaults/dl14.rs");}
 pub mod dl15 {include!("../../difftest/migration_defaults/dl15.rs");}
 pub mod dl_1_12 {include!("../../difftest/migration_defaults/dl_1_12.rs");}
}
fn check(p:port::SystemConfig,r:reference::EntryInitNew){
 use reference::{Attribute as A,Value as V};use std::collections::BTreeSet;
 assert_eq!(r.len(),4);assert!(p.object&&p.system_config&&p.system);
 assert_eq!(r[&A::Class],BTreeSet::from([V::new_iutf8("object"),V::new_iutf8("system_config"),V::new_iutf8("system")]));
 assert_eq!(r[&A::Uuid],BTreeSet::from([V::Uuid(p.uuid)]));
 assert_eq!(r[&A::Description],BTreeSet::from([V::Utf8(String::from_utf8(p.description).unwrap())]));
 let passwords=p.badlist_password.iter().map(|b|V::Iutf8(String::from_utf8(b.clone()).unwrap())).collect::<BTreeSet<_>>();
 assert_eq!(passwords.len(),637);assert_eq!(p.badlist_password.len(),637);assert_eq!(passwords,r[&A::BadlistPassword]);
 for candidate in ["TEQUIEROMUCHO","tequieromucho","muñequita","teextraño","not-a-listed-secret"] {assert_eq!(passwords.contains(&V::new_iutf8(candidate)),r[&A::BadlistPassword].contains(&V::new_iutf8(candidate)));}
}
#[test] fn dl11_exact_security_defaults() {check(port::dl11(),reference::dl11::e_system_config_v1());}
#[test] fn dl12_exact_security_defaults() {check(port::dl12(),reference::dl12::e_system_config_v1());}
#[test] fn dl13_exact_security_defaults() {check(port::dl13(),reference::dl13::e_system_config_v1());}
#[test] fn dl14_exact_security_defaults() {check(port::dl14(),reference::dl14::e_system_config_v1());}
#[test] fn dl15_exact_security_defaults() {check(port::dl15(),reference::dl15::e_system_config_v1());}
#[test] fn dl_1_12_exact_security_defaults() {check(port::dl_1_12(),reference::dl_1_12::e_system_config_v1());}
#[test] fn sentinel_version_distinction(){let a=port::dl14();let b=port::dl15();assert_ne!(a.badlist_password,b.badlist_password);let a=port::dl11();let b=port::dl12();assert_eq!(a,b);}
