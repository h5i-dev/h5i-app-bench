//! Complete account restoration, ownership decomposition, and credential flags.
use oxicloud::domain::entities::user as upstream;
use oxicloud_kernel::{userstate as port, userrole, session::Timestamp};
use crate::tests::Rng;
use chrono::{DateTime, Utc};
fn stamp(t: DateTime<Utc>) -> Timestamp { Timestamp { seconds: t.timestamp(), nanoseconds: t.timestamp_subsec_nanos() } }
fn datetime(r: &mut Rng) -> DateTime<Utc> { DateTime::from_timestamp((r.next() as i64) % 4_000_000_000_000, r.below(1_000_000_000) as u32).unwrap() }
fn text(r: &mut Rng) -> String { let a = ['a','Z','\0','é','世','🦀',' ','.','@']; (0..r.below(24)).map(|_| r.pick(&a)).collect() }
fn optional(r: &mut Rng) -> Option<String> { if r.below(2)==0 { None } else { Some(text(r)) } }
fn kind(k: port::FederationKind) -> upstream::FederationKind { match k { port::FederationKind::MagicLink => upstream::FederationKind::MagicLink, port::FederationKind::Ocm => upstream::FederationKind::Ocm, port::FederationKind::Oidc => upstream::FederationKind::Oidc } }
fn upstream_role(k: userrole::UserRole) -> upstream::UserRole { match k { userrole::UserRole::Owner => upstream::UserRole::Owner, userrole::UserRole::Admin => upstream::UserRole::Admin, userrole::UserRole::User => upstream::UserRole::User, userrole::UserRole::Anonymous => upstream::UserRole::Anonymous } }
fn compare(p: port::User, u: upstream::User) {
    assert_eq!(port::id(&p), u.id().as_u128());
    assert_eq!(port::username(&p).as_deref(), u.username().map(str::as_bytes));
    assert_eq!(port::email(&p) .as_slice(), u.email().as_bytes());
    assert_eq!(port::password_hash(&p).as_deref(), u.password_hash().map(str::as_bytes));
    assert_eq!(upstream_role(port::role(&p)), u.role());
    assert_eq!(port::storage_quota_bytes(&p), u.storage_quota_bytes());
    assert_eq!(port::storage_used_bytes(&p), u.storage_used_bytes());
    assert_eq!((port::created_at(&p).seconds, port::created_at(&p).nanoseconds), (u.created_at().timestamp(), u.created_at().timestamp_subsec_nanos()));
    assert_eq!((port::updated_at(&p).seconds, port::updated_at(&p).nanoseconds), (u.updated_at().timestamp(), u.updated_at().timestamp_subsec_nanos()));
    assert_eq!(port::last_login_at(&p).map(|t| (t.seconds,t.nanoseconds)), u.last_login_at().map(|t| (t.timestamp(),t.timestamp_subsec_nanos())));
    assert_eq!(port::is_active(&p), u.is_active());
    assert_eq!(port::federation_kind(&p).map(kind), u.federation_kind());
    assert_eq!(port::federation_issuer(&p).as_deref(), u.federation_issuer().map(str::as_bytes));
    assert_eq!(port::federation_subject(&p).as_deref(), u.federation_subject().map(str::as_bytes));
    assert_eq!(port::image(&p).as_deref(), u.image().map(str::as_bytes));
    assert_eq!(port::is_external(&p), u.is_external());
    assert_eq!(port::given_name(&p).as_deref(), u.given_name().map(str::as_bytes));
    assert_eq!(port::family_name(&p).as_deref(), u.family_name().map(str::as_bytes));
    assert_eq!(port::email_verified_at(&p).map(|t| (t.seconds,t.nanoseconds)), u.email_verified_at().map(|t| (t.timestamp(),t.timestamp_subsec_nanos())));
    assert_eq!(port::preferred_locale(&p).as_deref(), u.preferred_locale().map(str::as_bytes));
    assert_eq!(port::notify_on_share(&p), u.notify_on_share());
    assert_eq!(port::ui_preferences(&p) .as_slice(), serde_json::to_vec(u.ui_preferences()).unwrap() .as_slice());
    assert_eq!(port::has_password(&p),u.has_password());
    assert_eq!(port::is_oidc_user(&p),u.is_oidc_user());
    assert_eq!(port::has_login_credential(&p),u.has_login_credential());
    assert_eq!(port::is_email_verified(&p),u.is_email_verified());
    let p = port::into_parts(p); let u = u.into_parts();
    assert_eq!(p.id,u.id.as_u128());
    assert_eq!(p.username,u.username.map(String::into_bytes));
    assert_eq!(p.email,u.email.into_bytes());
    assert_eq!(p.password_hash,u.password_hash.map(String::into_bytes));
    assert_eq!(upstream_role(p.role),u.role);
    assert_eq!(p.storage_quota_bytes,u.storage_quota_bytes);
    assert_eq!(p.storage_used_bytes,u.storage_used_bytes);
    assert_eq!((p.created_at.seconds,p.created_at.nanoseconds),(u.created_at.timestamp(),u.created_at.timestamp_subsec_nanos()));
    assert_eq!((p.updated_at.seconds,p.updated_at.nanoseconds),(u.updated_at.timestamp(),u.updated_at.timestamp_subsec_nanos()));
    assert_eq!(p.last_login_at.map(|t|(t.seconds,t.nanoseconds)),u.last_login_at.map(|t|(t.timestamp(),t.timestamp_subsec_nanos())));
    assert_eq!(p.active,u.active);
    assert_eq!(p.federation_kind.map(kind),u.federation_kind);
    assert_eq!(p.federation_issuer,u.federation_issuer.map(String::into_bytes));
    assert_eq!(p.federation_subject,u.federation_subject.map(String::into_bytes));
    assert_eq!(p.image,u.image.map(String::into_bytes));
    assert_eq!(p.is_external,u.is_external);
    assert_eq!(p.given_name,u.given_name.map(String::into_bytes));
    assert_eq!(p.family_name,u.family_name.map(String::into_bytes));
    assert_eq!(p.email_verified_at.map(|t|(t.seconds,t.nanoseconds)),u.email_verified_at.map(|t|(t.timestamp(),t.timestamp_subsec_nanos())));
    assert_eq!(p.preferred_locale,u.preferred_locale.map(String::into_bytes));
    assert_eq!(p.notify_on_share,u.notify_on_share);
    assert_eq!(p.ui_preferences,serde_json::to_vec(&u.ui_preferences).unwrap());
}
#[test]
fn account_state_differential() {
    for k in [port::FederationKind::MagicLink, port::FederationKind::Ocm, port::FederationKind::Oidc] { assert_eq!(port::federation_bytes(k),kind(k).as_str().as_bytes()); }
    let mut r=Rng(0xf031_fcc3_861c_0209);
    for trial in 0..10_000 {
        for raw in [text(&mut r), ["magic_link","ocm","oidc","OIDC","","oidc\0"," oidc"][trial % 7].to_owned()] { assert_eq!(port::federation_parse(raw.as_bytes()).map(kind),upstream::FederationKind::parse(&raw)); }
        let id = (u128::from(r.next())<<64)|u128::from(r.next());
        let username = optional(&mut r);
        let email = text(&mut r);
        let password_hash = optional(&mut r);
        let role = [userrole::UserRole::Owner,userrole::UserRole::Admin,userrole::UserRole::User,userrole::UserRole::Anonymous][trial % 4];
        let storage_quota_bytes = r.next() as i64;
        let storage_used_bytes = r.next() as i64;
        let created_at = datetime(&mut r);
        let updated_at = datetime(&mut r);
        let last_login_at = if r.below(2)==0 {None} else {Some(datetime(&mut r))};
        let active = r.below(2)==0;
        let federation_kind = match trial % 4 {0=>None,1=>Some(port::FederationKind::MagicLink),2=>Some(port::FederationKind::Ocm),_=>Some(port::FederationKind::Oidc)};
        let federation_issuer = optional(&mut r);
        let federation_subject = optional(&mut r);
        let image = optional(&mut r);
        let is_external = r.below(2)==0;
        let given_name = optional(&mut r);
        let family_name = optional(&mut r);
        let email_verified_at = if r.below(2)==0 {None} else {Some(datetime(&mut r))};
        let preferred_locale = optional(&mut r);
        let notify_on_share = r.below(2)==0;
        let ui_preferences = match trial % 4 { 0=>serde_json::json!({}),1=>serde_json::json!({"theme": text(&mut r), "visible": r.below(2)==0}),2=>serde_json::Value::Null,_=>serde_json::json!([text(&mut r), r.next()]) };
        compare(port::from_data(id, username.as_ref().map(|s| s.as_bytes().to_vec()), email.as_bytes().to_vec(), password_hash.as_ref().map(|s| s.as_bytes().to_vec()), role, storage_quota_bytes, storage_used_bytes, stamp(created_at), stamp(updated_at), last_login_at.map(stamp), active), upstream::User::from_data(uuid::Uuid::from_u128(id), username.clone(), email.clone(), password_hash.clone(), upstream_role(role), storage_quota_bytes, storage_used_bytes, created_at, updated_at, last_login_at, active));
        compare(port::from_data_full(id, username.as_ref().map(|s| s.as_bytes().to_vec()), email.as_bytes().to_vec(), password_hash.as_ref().map(|s| s.as_bytes().to_vec()), role, storage_quota_bytes, storage_used_bytes, stamp(created_at), stamp(updated_at), last_login_at.map(stamp), active, federation_kind, federation_issuer.as_ref().map(|s| s.as_bytes().to_vec()), federation_subject.as_ref().map(|s| s.as_bytes().to_vec()), image.as_ref().map(|s| s.as_bytes().to_vec()), is_external, given_name.as_ref().map(|s| s.as_bytes().to_vec()), family_name.as_ref().map(|s| s.as_bytes().to_vec()), email_verified_at.map(stamp), preferred_locale.as_ref().map(|s| s.as_bytes().to_vec()), notify_on_share, serde_json::to_vec(&ui_preferences).unwrap()), upstream::User::from_data_full(uuid::Uuid::from_u128(id), username.clone(), email.clone(), password_hash.clone(), upstream_role(role), storage_quota_bytes, storage_used_bytes, created_at, updated_at, last_login_at, active, federation_kind.map(kind), federation_issuer.clone(), federation_subject.clone(), image.clone(), is_external, given_name.clone(), family_name.clone(), email_verified_at, preferred_locale.clone(), notify_on_share, ui_preferences.clone()));
    }
}
