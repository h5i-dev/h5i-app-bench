//! Differential coverage of live-account reconciliation and account restrictions.
use oxicloud::domain::{entities::user::{UserFlags,UserRole}, errors::{DomainError,ErrorKind}};
use oxicloud::interfaces::middleware::user::LiveRole;
use oxicloud_kernel::{liveauth as port,userrole};
use crate::tests::Rng;
mod oracle { include!(concat!(env!("OUT_DIR"), "/liveauth_oracle.rs")); }
fn role(r:userrole::UserRole)->UserRole { match r {userrole::UserRole::Owner=>UserRole::Owner,userrole::UserRole::Admin=>UserRole::Admin,userrole::UserRole::User=>UserRole::User,userrole::UserRole::Anonymous=>UserRole::Anonymous} }
fn flags(f:port::FlagsLookup, trial:usize)->Result<UserFlags,DomainError> { match f {
 port::FlagsLookup::Found(f)=>Ok(UserFlags{role:role(f.role),is_external:f.is_external,active:f.active,force_password_change:f.force_password_change}),
 port::FlagsLookup::NotFound=>Err(DomainError::new(ErrorKind::NotFound,"User","lookup")),
 port::FlagsLookup::Unavailable=>Err(DomainError::new(match trial%5 {0=>ErrorKind::DatabaseError,1=>ErrorKind::AccessDenied,2=>ErrorKind::InvalidInput,3=>ErrorKind::Timeout,_=>ErrorKind::InternalError},"User","lookup")),
} }
fn assert_role(p:port::LiveRole,u:LiveRole) { match(p,u) {
 (port::LiveRole::Revoked,LiveRole::Revoked)=>(),
 (port::LiveRole::Active(p),LiveRole::Active(u))=>assert_eq!(p,u.as_bytes()),
 _=>panic!("role decision differs"),
} }
#[test]
fn live_account_differential() {
 let mut rng=Rng(0x1f3a_77cb_e123_5678);
 let claims=["owner","admin","user","anonymous","","Admin","anonymous\0","外部","admiñ"," owner","ANONYMOUS"];
 for trial in 0..10_000 {
  let id=(u128::from(rng.next())<<64)|u128::from(rng.next());
  let r=[userrole::UserRole::Owner,userrole::UserRole::Admin,userrole::UserRole::User,userrole::UserRole::Anonymous][(trial/3)%4];
  let f=match trial%3 {0=>port::FlagsLookup::Found(port::UserFlags{role:r,is_external:(trial/12)%2==0,active:(trial/24)%2==0,force_password_change:(trial/48)%2==0}),1=>port::FlagsLookup::NotFound,_=>port::FlagsLookup::Unavailable};
  let mut claim=claims[trial%claims.len()].to_owned();
  if trial%13==0 {claim=(0..(rng.next()%80)).map(|_|char::from_u32(32+(rng.next()%90) as u32).unwrap()).collect();}
  let u=oracle::internal(flags(f,trial),uuid::Uuid::from_u128(id));
  match port::decide_internal_user(f,id) {
   Ok(())=>assert!(u.is_ok()),
   Err(reason)=> {let e=u.unwrap_err();assert_eq!(e.status_code.as_u16(),403);assert_eq!(e.error_type,"Forbidden");assert_eq!(e.message,match reason {port::InternalDenial::External=>"External users cannot access this endpoint",port::InternalDenial::NoAccount=>"This endpoint requires a user account"});},
  }
  assert_role(port::decide_live_role(f,id,claim.as_bytes()),oracle::live(flags(f,trial),uuid::Uuid::from_u128(id),&claim));
  match(port::anonymous_live_role(claim.as_bytes()),oracle::anonymous(&claim)) { (None,None)=>(),(Some(p),Some(u))=>assert_role(p,u),_=>panic!("anonymous decision differs") }
 }
}
