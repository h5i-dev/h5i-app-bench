#![allow(dead_code,non_upper_case_globals,non_snake_case)]
use std::{sync::LazyLock,collections::BTreeMap};
#[derive(Clone,Copy,Debug)]struct Uuid(u128);
#[derive(Clone,Copy,Debug,PartialEq,Eq,PartialOrd,Ord)]struct Attribute(&'static str);
impl Attribute {
const Class:Self=Self("class");
const Description:Self=Self("description");
const Name:Self=Self("name");
const Uuid:Self=Self("uuid");
const Version:Self=Self("version");
}
#[derive(Clone,Copy,Debug)]struct EntryClass(&'static str);
impl EntryClass{
const DomainInfo:Self=Self("domain_info");
const Feature:Self=Self("feature");
const KeyObject:Self=Self("key_object");
const KeyObjectHkdfS256:Self=Self("key_object_hkdf_s256");
const KeyObjectJweA128GCM:Self=Self("key_object_jwe_a128gcm");
const KeyObjectJweA256GCM:Self=Self("key_object_jwe_a256gcm");
const KeyObjectJwtEs256:Self=Self("key_object_jwt_es256");
const KeyObjectJwtHs256:Self=Self("key_object_jwt_hs256");
const KeyProvider:Self=Self("key_provider");
const KeyProviderInternal:Self=Self("key_provider_internal");
const Object:Self=Self("object");
const System:Self=Self("system");
const SystemInfo:Self=Self("system_info");
fn to_value(self)->Value{Value::Class(self.0)}}
const UUID_ACCOUNT_SIGNUP_FEATURE:Uuid=Uuid(89);
const UUID_ADMIN:Uuid=Uuid(0);
const UUID_ANONYMOUS:Uuid=Uuid(281474976710655);
const UUID_DOMAIN_ID_VERIFICATION_KEY:Uuid=Uuid(281474959933558);
const UUID_DOMAIN_INFO:Uuid=Uuid(281474959933477);
const UUID_HMAC_NAME_FEATURE:Uuid=Uuid(88);
const UUID_IDM_ADMIN:Uuid=Uuid(24);
const UUID_IDM_ADMINS:Uuid=Uuid(1);
const UUID_KEY_PROVIDER_INTERNAL:Uuid=Uuid(281474959933552);
const UUID_SYSTEM_INFO:Uuid=Uuid(281474959933441);
#[derive(Clone,Copy,Debug)]enum AccountType{ServiceAccount}
#[derive(Clone,Debug)]struct BuiltinAccount{account_type:AccountType,entry_managed_by:Option<Uuid>,name:&'static str,uuid:Uuid,description:&'static str,displayname:&'static str}
#[derive(Clone,Debug)]enum Value{Class(&'static str),Uuid(Uuid),Utf8(String),Iname(String),Uint32(u32)}
impl Value{fn new_utf8s(s:&str)->Self{Self::Utf8(s.to_owned())}fn new_iname(s:&str)->Self{Self::Iname(s.to_lowercase())}}
type EntryInitNew=BTreeMap<Attribute,Vec<Value>>;
fn entry_init_fn<const N:usize>(xs:[(Attribute,Value);N])->EntryInitNew{let mut e=BTreeMap::new();for(a,v)in xs{e.entry(a).or_insert_with(Vec::new).push(v)}e}
fn string_bytes(s:&str,b:&mut Vec<u8>){b.extend_from_slice(&(s.len()as u16).to_le_bytes());b.extend_from_slice(s.as_bytes())}
fn bytes(e:&EntryInitNew)->Vec<u8>{let mut b=vec![];for(a,vs)in e{string_bytes(a.0,&mut b);let mut values=vec![];for v in vs{let mut vbytes=vec![];match v{Value::Class(s)=>{vbytes.push(0);string_bytes(s,&mut vbytes)},Value::Uuid(u)=>{vbytes.push(1);vbytes.extend_from_slice(&u.0.to_le_bytes())},Value::Utf8(s)=>{vbytes.push(2);string_bytes(s,&mut vbytes)},Value::Iname(s)=>{vbytes.push(3);string_bytes(s,&mut vbytes)},Value::Uint32(n)=>{vbytes.push(4);vbytes.extend_from_slice(&n.to_le_bytes())}}values.push(vbytes)}values.sort();values.dedup();b.extend_from_slice(&(values.len()as u16).to_le_bytes());for v in values{b.extend(v)}}b}
mod dl11{include!("dl11.rs");}
mod dl12{include!("dl12.rs");}
mod dl13{include!("dl13.rs");}
mod dl14{include!("dl14.rs");}
mod dl15{include!("dl15.rs");}
mod dl_1_12{include!("dl_1_12.rs");}
fn render_Account(v:&BuiltinAccount)->String{format!("{{\"account_type\":{},\"has_entry_manager\":{},\"entry_manager\":{},\"name\":{:?},\"uuid\":{},\"description\":{:?},\"displayname\":{:?}}}",0u8,v.entry_managed_by.is_some(),v.entry_managed_by.map(|u|u.0).unwrap_or(0),v.name.as_bytes().to_vec(),v.uuid.0,v.description.as_bytes().to_vec(),v.displayname.as_bytes().to_vec())}
fn render_Entry(v:&EntryInitNew)->String{format!("{{\"bytes\":{:?}}}",bytes(v))}
fn main(){
println!("{}\t{}","dl11/BUILTIN_ACCOUNT_IDM_ADMIN",render_Account(&dl11::BUILTIN_ACCOUNT_IDM_ADMIN));
println!("{}\t{}","dl11/BUILTIN_ACCOUNT_ADMIN",render_Account(&dl11::BUILTIN_ACCOUNT_ADMIN));
println!("{}\t{}","dl11/BUILTIN_ACCOUNT_ANONYMOUS_DL6",render_Account(&dl11::BUILTIN_ACCOUNT_ANONYMOUS_DL6));
println!("{}\t{}","dl11/E_KEY_PROVIDER_INTERNAL_DL6",render_Entry(&dl11::E_KEY_PROVIDER_INTERNAL_DL6));
println!("{}\t{}","dl11/E_SYSTEM_INFO_V1",render_Entry(&dl11::E_SYSTEM_INFO_V1));
println!("{}\t{}","dl11/E_DOMAIN_INFO_DL6",render_Entry(&dl11::E_DOMAIN_INFO_DL6));
println!("{}\t{}","dl12/BUILTIN_ACCOUNT_IDM_ADMIN",render_Account(&dl12::BUILTIN_ACCOUNT_IDM_ADMIN));
println!("{}\t{}","dl12/BUILTIN_ACCOUNT_ADMIN",render_Account(&dl12::BUILTIN_ACCOUNT_ADMIN));
println!("{}\t{}","dl12/BUILTIN_ACCOUNT_ANONYMOUS_DL6",render_Account(&dl12::BUILTIN_ACCOUNT_ANONYMOUS_DL6));
println!("{}\t{}","dl12/E_KEY_PROVIDER_INTERNAL_DL6",render_Entry(&dl12::E_KEY_PROVIDER_INTERNAL_DL6));
println!("{}\t{}","dl12/E_SYSTEM_INFO_V1",render_Entry(&dl12::E_SYSTEM_INFO_V1));
println!("{}\t{}","dl12/E_DOMAIN_INFO_DL6",render_Entry(&dl12::E_DOMAIN_INFO_DL6));
println!("{}\t{}","dl12/E_UUID_DOMAIN_ID_VERIFICATION_KEY_V1",render_Entry(&dl12::E_UUID_DOMAIN_ID_VERIFICATION_KEY_V1));
println!("{}\t{}","dl12/E_HMAC_NAME_HISTORY_FEATURE",render_Entry(&dl12::E_HMAC_NAME_HISTORY_FEATURE));
println!("{}\t{}","dl13/BUILTIN_ACCOUNT_IDM_ADMIN",render_Account(&dl13::BUILTIN_ACCOUNT_IDM_ADMIN));
println!("{}\t{}","dl13/BUILTIN_ACCOUNT_ADMIN",render_Account(&dl13::BUILTIN_ACCOUNT_ADMIN));
println!("{}\t{}","dl13/BUILTIN_ACCOUNT_ANONYMOUS_DL6",render_Account(&dl13::BUILTIN_ACCOUNT_ANONYMOUS_DL6));
println!("{}\t{}","dl13/E_KEY_PROVIDER_INTERNAL_DL6",render_Entry(&dl13::E_KEY_PROVIDER_INTERNAL_DL6));
println!("{}\t{}","dl13/E_SYSTEM_INFO_V1",render_Entry(&dl13::E_SYSTEM_INFO_V1));
println!("{}\t{}","dl13/E_DOMAIN_INFO_DL6",render_Entry(&dl13::E_DOMAIN_INFO_DL6));
println!("{}\t{}","dl13/E_UUID_DOMAIN_ID_VERIFICATION_KEY_V1",render_Entry(&dl13::E_UUID_DOMAIN_ID_VERIFICATION_KEY_V1));
println!("{}\t{}","dl13/E_HMAC_NAME_HISTORY_FEATURE",render_Entry(&dl13::E_HMAC_NAME_HISTORY_FEATURE));
println!("{}\t{}","dl14/BUILTIN_ACCOUNT_IDM_ADMIN",render_Account(&dl14::BUILTIN_ACCOUNT_IDM_ADMIN));
println!("{}\t{}","dl14/BUILTIN_ACCOUNT_ADMIN",render_Account(&dl14::BUILTIN_ACCOUNT_ADMIN));
println!("{}\t{}","dl14/BUILTIN_ACCOUNT_ANONYMOUS_DL6",render_Account(&dl14::BUILTIN_ACCOUNT_ANONYMOUS_DL6));
println!("{}\t{}","dl14/e_key_provider_internal_dl6",render_Entry(&dl14::e_key_provider_internal_dl6()));
println!("{}\t{}","dl14/e_system_info_v1",render_Entry(&dl14::e_system_info_v1()));
println!("{}\t{}","dl14/e_domain_info_dl6",render_Entry(&dl14::e_domain_info_dl6()));
println!("{}\t{}","dl14/e_uuid_domain_id_verification_key_v1",render_Entry(&dl14::e_uuid_domain_id_verification_key_v1()));
println!("{}\t{}","dl14/e_hmac_name_history_feature",render_Entry(&dl14::e_hmac_name_history_feature()));
println!("{}\t{}","dl15/BUILTIN_ACCOUNT_IDM_ADMIN",render_Account(&dl15::BUILTIN_ACCOUNT_IDM_ADMIN));
println!("{}\t{}","dl15/BUILTIN_ACCOUNT_ADMIN",render_Account(&dl15::BUILTIN_ACCOUNT_ADMIN));
println!("{}\t{}","dl15/BUILTIN_ACCOUNT_ANONYMOUS_DL6",render_Account(&dl15::BUILTIN_ACCOUNT_ANONYMOUS_DL6));
println!("{}\t{}","dl15/e_key_provider_internal_dl6",render_Entry(&dl15::e_key_provider_internal_dl6()));
println!("{}\t{}","dl15/e_system_info_v1",render_Entry(&dl15::e_system_info_v1()));
println!("{}\t{}","dl15/e_domain_info_dl6",render_Entry(&dl15::e_domain_info_dl6()));
println!("{}\t{}","dl15/e_uuid_domain_id_verification_key_v1",render_Entry(&dl15::e_uuid_domain_id_verification_key_v1()));
println!("{}\t{}","dl15/e_hmac_name_history_feature",render_Entry(&dl15::e_hmac_name_history_feature()));
println!("{}\t{}","dl_1_12/BUILTIN_ACCOUNT_IDM_ADMIN",render_Account(&dl_1_12::BUILTIN_ACCOUNT_IDM_ADMIN));
println!("{}\t{}","dl_1_12/BUILTIN_ACCOUNT_ADMIN",render_Account(&dl_1_12::BUILTIN_ACCOUNT_ADMIN));
println!("{}\t{}","dl_1_12/BUILTIN_ACCOUNT_ANONYMOUS_DL6",render_Account(&dl_1_12::BUILTIN_ACCOUNT_ANONYMOUS_DL6));
println!("{}\t{}","dl_1_12/e_key_provider_internal_dl6",render_Entry(&dl_1_12::e_key_provider_internal_dl6()));
println!("{}\t{}","dl_1_12/e_system_info_v1",render_Entry(&dl_1_12::e_system_info_v1()));
println!("{}\t{}","dl_1_12/e_domain_info_dl6",render_Entry(&dl_1_12::e_domain_info_dl6()));
println!("{}\t{}","dl_1_12/e_uuid_domain_id_verification_key_v1",render_Entry(&dl_1_12::e_uuid_domain_id_verification_key_v1()));
println!("{}\t{}","dl_1_12/e_hmac_name_history_feature",render_Entry(&dl_1_12::e_hmac_name_history_feature()));
println!("{}\t{}","dl_1_12/e_account_signup_feature",render_Entry(&dl_1_12::e_account_signup_feature()));
}
