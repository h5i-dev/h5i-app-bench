//! Pure validators and family classification from policy/{statement,resource,effect,id,principal}.rs.
use crate::{acts::{Family, Action}, bytes, rsrc::Resource, stmts::{Statement, BPStatement, Principal, Effect}};

pub enum ActionFamily { S3, Admin, Sts, Kms, Mixed }
pub enum ErrorKind {
    InvalidVersion, NonAction, BothActionAndNotAction, MixedActionFamilies,
    NonResource, BothResourceAndNotResource, KmsResourceWithNonKmsAction,
    KmsUnsupportedInBucketPolicy, InvalidResource, EmptyPrincipal,
}
pub struct ValidationError { pub kind: ErrorKind, pub family: Vec<u8>, pub value: Vec<u8> }
fn error(kind: ErrorKind) -> ValidationError { ValidationError { kind, family: Vec::new(), value: Vec::new() } }

/// `Validator::is_valid` default implementation.
pub fn default_is_valid() -> bool { true }
/// `ID::is_empty` (ID remains a byte string).
pub fn id_is_empty(id: &[u8]) -> bool { id.len() == 0 }
/// `ID::deref`.
pub fn id_as_slice(id: &[u8]) -> &[u8] { id }
/// `ID::is_valid`: every decoded string is valid.
pub fn id_is_valid(_id: &[u8]) -> bool { true }
/// `Effect::is_valid`: both enum variants are valid.
pub fn effect_is_valid(_effect: Effect) -> bool { true }
/// `Principal::is_valid`.
pub fn principal_is_valid(p: &Principal) -> Result<(), ValidationError> {
    if p.aws.len() == 0 && p.service.len() == 0 { return Err(error(ErrorKind::EmptyPrincipal)); }
    Ok(())
}
/// `Statement::is_admin`.
pub fn is_admin(st: &Statement) -> bool {
    let mut i = 0;
    while i < st.actions.len() { if st.actions[i].family == Family::Admin { return true; } i += 1; }
    false
}
/// `Statement::is_sts`.
pub fn is_sts(st: &Statement) -> bool {
    let mut i = 0;
    while i < st.actions.len() { if st.actions[i].family == Family::Sts { return true; } i += 1; }
    false
}
/// `Statement::action_family`: None entries are ignored; an all-None nonempty list is Mixed.
pub fn action_family(st: &Statement) -> Option<ActionFamily> {
    if st.actions.len() == 0 { return None; }
    let mut saw_s3 = false; let mut saw_admin = false; let mut saw_sts = false; let mut saw_kms = false;
    let mut i = 0;
    while i < st.actions.len() {
        match st.actions[i].family { Family::S3 => saw_s3 = true, Family::Admin => saw_admin = true,
            Family::Sts => saw_sts = true, Family::Kms => saw_kms = true, Family::None => {} }
        i += 1;
    }
    let count = saw_s3 as u8 + saw_admin as u8 + saw_sts as u8 + saw_kms as u8;
    if count != 1 { return Some(ActionFamily::Mixed); }
    if saw_s3 { return Some(ActionFamily::S3); }
    if saw_admin { return Some(ActionFamily::Admin); }
    if saw_sts { return Some(ActionFamily::Sts); }
    if saw_kms { return Some(ActionFamily::Kms); }
    Some(ActionFamily::Mixed)
}
fn kms_key_valid(p:&[u8])->bool {bytes::starts_with(p,b"key/") && p.len()>4 && !bytes::contains(&bytes::slice(p,4,p.len()),b"/") && !bytes::contains(p,b"\\")}
fn kms_alias_valid(p:&[u8])->bool {bytes::starts_with(p,b"alias/") && p.len()>6 && !bytes::contains(p,b"\\")}
fn resource_pattern_valid(r:&Resource)->bool {match r {Resource::S3(p)=>p.len()>0 && p[0]!=b'/',Resource::Kms(p)=>bytes::eq(p,b"*") || kms_key_valid(p) || kms_alias_valid(p)}}
/// `Resource::is_valid`: separate predicate from error payload construction for Aeneas.
pub fn resource_is_valid(r:&Resource)->Result<(),ValidationError>{if resource_pattern_valid(r){return Ok(());}let (family,value)=match r {Resource::S3(p)=>(b"s3".to_vec(),p.clone()),Resource::Kms(p)=>(b"kms".to_vec(),p.clone())};Err(ValidationError{kind:ErrorKind::InvalidResource,family,value})}
/// `ResourceSet::is_valid`, preserving first error order.
pub fn resources_is_valid(set: &[Resource]) -> Result<(), ValidationError> {
    let mut i = 0;
    while i < set.len() { resource_is_valid(&set[i])?; i += 1; }
    Ok(())
}
fn has_kms_resource(rs: &[Resource]) -> bool {
    let mut i = 0;
    while i < rs.len() { if crate::rsrc::is_kms(&rs[i]) { return true; } i += 1; }
    false
}
fn has_kms_action(actions: &[Action]) -> bool {
    let mut i = 0;
    while i < actions.len() { if actions[i].family == Family::Kms { return true; } i += 1; }
    false
}
fn action_selection_valid(actions:&[Action],not_actions:&[Action])->Result<(),ValidationError>{
 if actions.len()==0 && not_actions.len()==0{return Err(error(ErrorKind::NonAction));}
 if actions.len()!=0 && not_actions.len()!=0{return Err(error(ErrorKind::BothActionAndNotAction));}Ok(())
}
fn family_is_mixed(family:&Option<ActionFamily>)->bool {matches!(family,Some(ActionFamily::Mixed))}
fn family_is_kms(family:&Option<ActionFamily>)->bool {matches!(family,Some(ActionFamily::Kms))}
fn family_allows_empty_resource(family:&Option<ActionFamily>)->bool {matches!(family,Some(ActionFamily::Admin)|Some(ActionFamily::Sts)|Some(ActionFamily::Kms))}
fn checked_action_family(st:&Statement)->Result<Option<ActionFamily>,ValidationError>{
 if st.not_actions.len()!=0{return Ok(None);}let family=action_family(st);if family_is_mixed(&family){return Err(error(ErrorKind::MixedActionFamilies));}Ok(family)
}
fn statement_resource_rules(st:&Statement,family:&Option<ActionFamily>)->Result<(),ValidationError>{
 if st.resources.len()==0 && st.not_resources.len()==0 && !family_allows_empty_resource(family){return Err(error(ErrorKind::NonResource));}
 if st.resources.len()!=0 && st.not_resources.len()!=0{return Err(error(ErrorKind::BothResourceAndNotResource));}
 if (has_kms_resource(&st.resources)||has_kms_resource(&st.not_resources)) && !family_is_kms(family){return Err(error(ErrorKind::KmsResourceWithNonKmsAction));}Ok(())
}
/// `Statement::is_valid`, with phase helpers to avoid duplicating the continuation after enum matches.
pub fn statement_is_valid(st:&Statement,sid:&[u8])->Result<(),ValidationError>{
 let _=effect_is_valid(st.effect);let _=id_is_valid(sid);action_selection_valid(&st.actions,&st.not_actions)?;
 let family=checked_action_family(st)?;statement_resource_rules(st,&family)?;
 let _=crate::actsets::is_valid(&st.actions);let _=crate::actsets::is_valid(&st.not_actions);
 resources_is_valid(&st.resources)?;resources_is_valid(&st.not_resources)?;Ok(())
}
/// `BPStatement::is_valid`.
pub fn bp_statement_is_valid(st: &BPStatement, sid: &[u8]) -> Result<(), ValidationError> {
    let _ = effect_is_valid(st.effect); let _ = id_is_valid(sid);
    principal_is_valid(&st.principal)?;
    if st.actions.len() == 0 && st.not_actions.len() == 0 { return Err(error(ErrorKind::NonAction)); }
    if st.actions.len() != 0 && st.not_actions.len() != 0 { return Err(error(ErrorKind::BothActionAndNotAction)); }
    if has_kms_action(&st.actions) || has_kms_action(&st.not_actions)
        || has_kms_resource(&st.resources) || has_kms_resource(&st.not_resources) {
        return Err(error(ErrorKind::KmsUnsupportedInBucketPolicy));
    }
    if st.resources.len() == 0 && st.not_resources.len() == 0 { return Err(error(ErrorKind::NonResource)); }
    if st.resources.len() != 0 && st.not_resources.len() != 0 { return Err(error(ErrorKind::BothResourceAndNotResource)); }
    let _ = crate::actsets::is_valid(&st.actions); let _ = crate::actsets::is_valid(&st.not_actions);
    resources_is_valid(&st.resources)?; resources_is_valid(&st.not_resources)?;
    Ok(())
}
