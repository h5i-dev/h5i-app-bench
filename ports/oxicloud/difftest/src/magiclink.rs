//! Lossless token snapshots and deterministic redemption-time boundaries.
use oxicloud::domain::entities::magic_link_token as upstream;
use oxicloud_kernel::{magiclink as port, session::Timestamp};
use crate::tests::Rng;
use chrono::{DateTime, Utc, Duration};
mod oracle { include!(concat!(env!("OUT_DIR"), "/magic_oracle.rs")); }
fn stamp(t: DateTime<Utc>) -> Timestamp { Timestamp { seconds: t.timestamp(), nanoseconds: t.timestamp_subsec_nanos() } }
fn datetime(rng: &mut Rng) -> DateTime<Utc> {
    let s = (rng.next() as i64) % 4_000_000_000_000;
    let n = if s.rem_euclid(60) == 59 && rng.below(2) == 0 { 1_500_000_000 } else { rng.below(1_000_000_000) as u32 };
    DateTime::from_timestamp(s, n).unwrap()
}
fn status(p: port::MagicLinkStatus) -> upstream::MagicLinkStatus {
    match p { port::MagicLinkStatus::Pending => upstream::MagicLinkStatus::Pending,
        port::MagicLinkStatus::Used => upstream::MagicLinkStatus::Used,
        port::MagicLinkStatus::Expired => upstream::MagicLinkStatus::Expired }
}
fn resource(p: port::MagicLinkResourceKind) -> upstream::MagicLinkResourceKind {
    match p { port::MagicLinkResourceKind::File => upstream::MagicLinkResourceKind::File,
        port::MagicLinkResourceKind::Folder => upstream::MagicLinkResourceKind::Folder }
}
fn text(rng: &mut Rng) -> String {
    let alphabet = ['a', 'Z', '\0', 'é', '世', '🦀', '-', '_', ' '];
    (0..rng.below(24)).map(|_| rng.pick(&alphabet)).collect()
}
fn wire(raw: &str) {
    assert_eq!(port::status_parse(raw.as_bytes()).map(status), upstream::MagicLinkStatus::parse(raw));
    assert_eq!(port::resource_parse(raw.as_bytes()).map(resource), upstream::MagicLinkResourceKind::parse(raw));
}
#[test]
fn magic_link_state_and_expiry_differential() {
    for raw in ["pending", "used", "expired", "file", "folder", "Pending", "", "pending\0", " pending", "used "] { wire(raw); }
    for s in [port::MagicLinkStatus::Pending, port::MagicLinkStatus::Used, port::MagicLinkStatus::Expired] {
        assert_eq!(port::status_bytes(s), status(s).as_str().as_bytes());
    }
    for k in [port::MagicLinkResourceKind::File, port::MagicLinkResourceKind::Folder] {
        assert_eq!(port::resource_bytes(k), resource(k).as_str().as_bytes());
    }
    let mut rng = Rng(0x0a70_af44_2e04_f163);
    for trial in 0..10_000 {
        let id = (u128::from(rng.next()) << 64) | u128::from(rng.next());
        let user_id = (u128::from(rng.next()) << 64) | u128::from(rng.next());
        let token = text(&mut rng); wire(&token);
        let challenge = if rng.below(2) == 0 { None } else { Some(text(&mut rng)) };
        let kind = match trial % 3 { 0 => None, 1 => Some(port::MagicLinkResourceKind::File), _ => Some(port::MagicLinkResourceKind::Folder) };
        let target = if rng.below(2) == 0 { None } else { Some((u128::from(rng.next()) << 64) | u128::from(rng.next())) };
        let s = match trial % 3 { 0 => port::MagicLinkStatus::Pending, 1 => port::MagicLinkStatus::Used, _ => port::MagicLinkStatus::Expired };
        let issued = datetime(&mut rng); let expiry = datetime(&mut rng);
        let used = if rng.below(2) == 0 { None } else { Some(datetime(&mut rng)) };
        let p = port::from_raw(id, token.as_bytes().to_vec(), user_id, s, stamp(issued), stamp(expiry), used.map(stamp), kind, target, challenge.as_ref().map(|s| s.as_bytes().to_vec()));
        let u = upstream::MagicLinkToken::from_raw(uuid::Uuid::from_u128(id), token, uuid::Uuid::from_u128(user_id), status(s), issued, expiry, used, kind.map(resource), target.map(uuid::Uuid::from_u128), challenge);
        assert_eq!(port::id(&p), u.id().as_u128());
        assert_eq!(port::user_id(&p), u.user_id().as_u128());
        assert_eq!(port::token(&p), u.token().as_bytes());
        assert_eq!(status(port::status(&p)), u.status());
        assert_eq!((port::issued_at(&p).seconds, port::issued_at(&p).nanoseconds), (u.issued_at().timestamp(), u.issued_at().timestamp_subsec_nanos()));
        assert_eq!((port::expires_at(&p).seconds, port::expires_at(&p).nanoseconds), (u.expires_at().timestamp(), u.expires_at().timestamp_subsec_nanos()));
        assert_eq!(port::used_at(&p).map(|t| (t.seconds, t.nanoseconds)), u.used_at().map(|t| (t.timestamp(), t.timestamp_subsec_nanos())));
        assert_eq!(port::resource_kind(&p).map(resource), u.resource_kind());
        assert_eq!(port::resource_id(&p), u.resource_id().map(|id| id.as_u128()));
        assert_eq!(port::request_challenge(&p).as_deref(), u.request_challenge().map(str::as_bytes));
        let o = oracle::Snapshot { expires_at: expiry, status: status(s) };
        for now in [expiry, expiry - Duration::nanoseconds(1), expiry + Duration::nanoseconds(1), issued, datetime(&mut rng)] {
            assert_eq!(port::is_expired(&p, stamp(now)), o.is_expired(now));
            assert_eq!(port::is_redeemable(&p, stamp(now)), o.is_redeemable(now));
        }
        let before = Utc::now(); let expired = u.is_expired(); let after = Utc::now();
        assert!(!expired || after > expiry); assert!(expired || before <= expiry);
        let before = Utc::now(); let redeemable = u.is_redeemable(); let after = Utc::now();
        assert!(!redeemable || (status(s) == upstream::MagicLinkStatus::Pending && before <= expiry));
        assert!(redeemable || status(s) != upstream::MagicLinkStatus::Pending || after > expiry);
    }
}
