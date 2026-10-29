//! Administrator gate agreement, including subject type and denial precedence.
use oxicloud::application::ports::authorization_ports::{AuthorizationEngine, AuthzDenialVisibility};
use oxicloud::domain::{services::authorization::Subject, entities::user::UserRole, errors::ErrorKind};
use oxicloud_kernel::{admin as port,userrole};
use crate::tests::{Rng,engine};
mod oracle { include!(concat!(env!("CARGO_MANIFEST_DIR"), "/reference/admin_oracle.rs")); }
fn role(r: userrole::UserRole) -> UserRole { match r { userrole::UserRole::Owner=>UserRole::Owner,userrole::UserRole::Admin=>UserRole::Admin,userrole::UserRole::User=>UserRole::User,userrole::UserRole::Anonymous=>UserRole::Anonymous } }
fn subject(s: port::Principal) -> Subject { match s { port::Principal::User(id)=>Subject::User(uuid::Uuid::from_u128(id)),port::Principal::Group(id)=>Subject::Group(uuid::Uuid::from_u128(id)),port::Principal::Token(id)=>Subject::Token(uuid::Uuid::from_u128(id)) } }
#[test]
fn system_admin_differential() {
    assert_eq!(port::visibility_bytes(port::AuthzDenialVisibility::Visible),AuthzDenialVisibility::Visible.as_str().as_bytes());
    assert_eq!(port::visibility_bytes(port::AuthzDenialVisibility::Hidden),AuthzDenialVisibility::Hidden.as_str().as_bytes());
    let engine=engine();
    let mut rng=Rng(0xc338_f5bc_d084_e12e);
    for trial in 0..10_000 {
        let id=(u128::from(rng.next())<<64)|u128::from(rng.next());
        let s=match trial%3 {0=>port::Principal::User(id),1=>port::Principal::Group(id),_=>port::Principal::Token(id)};
        let r=[userrole::UserRole::Owner,userrole::UserRole::Admin,userrole::UserRole::User,userrole::UserRole::Anonymous][(trial/3)%4];
        let external=(trial/12)%2==0; let active=(trial/24)%2==0;
        let expected=oracle::reason(subject(s),role(r),external,active);
        assert_eq!(port::system_admin_denial_reason(s,r,external,active).map(port::denial_bytes),expected.map(|s|s.as_bytes().to_vec()));
        let u=engine.require_system_admin(subject(s),role(r),external,active);
        match port::require_system_admin(s,r,external,active) {
            port::AdminDecision::Allowed=> { assert!(u.is_ok());assert!(expected.is_none()); },
            port::AdminDecision::Denied(reason)=> {
                assert_eq!(Some(port::denial_bytes(reason)),expected.map(|s|s.as_bytes().to_vec()));
                let e=u.unwrap_err();assert!(matches!(e.kind,ErrorKind::AccessDenied));
                assert_eq!(e.entity_type,"System");assert_eq!(e.message,"Admin access required");
                assert!(e.entity_id.is_none());assert!(e.source.is_none());
            },
        }
    }
}
