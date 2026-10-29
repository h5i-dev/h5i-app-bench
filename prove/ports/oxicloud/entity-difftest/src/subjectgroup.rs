//! Namespace decisions and diagnostic precedence against the pinned implementation.
use oxicloud::domain::entities::subject_group as upstream;
use oxicloud_kernel::{subjectgroup as port, session::Timestamp};
use crate::tests::Rng;
fn check(raw: &str) {
    let p = port::validate_name(raw.as_bytes()).map_err(|e| match e {
        port::NameError::Empty => "empty".to_owned(),
        port::NameError::TooLong => "exceeds 64 chars".to_owned(),
        port::NameError::InvalidStart => format!("must start with letter or digit: {}", raw),
        port::NameError::InvalidCharacter => {
            let c = raw.chars().skip(1).find(|c| !(c.is_ascii_alphanumeric() || matches!(c, '.' | '-' | '_'))).unwrap();
            format!("invalid character {:?} in {}", c, raw)
        }
    });
    let u = upstream::SubjectGroup::validate_name(raw).map_err(|e| match e {
        upstream::SubjectGroupError::InvalidName(s) => s,
        other => panic!("unexpected error: {other:?}"),
    });
    assert_eq!(p, u, "{raw:?}");
}
#[test]
fn subject_group_validation_differential() {
    assert_eq!(port::INTERNAL_GROUP_ID, upstream::INTERNAL_GROUP_ID.as_u128());
    assert_eq!(port::MAX_GROUP_DEPTH, upstream::MAX_GROUP_DEPTH);
    for len in [0, 1, 2, 63, 64, 65, 128] {
        for byte in 0..=127 { check(&String::from_utf8(vec![byte; len]).unwrap()); }
    }
    let mut rng = Rng(0xaf70_5268_49e1_c520);
    for _ in 0..10_000 {
        let alphabet = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-";
        let mut raw = (0..rng.below(70)).map(|_| rng.pick(alphabet) as char).collect::<String>();
        check(&raw);
        let c = char::from_u32(rng.below(0x11_0000) as u32).unwrap_or(' ');
        raw.insert(rng.below(raw.len() as u64 + 1) as usize, c);
        check(&raw);
    }
    for is_virtual in [false, true] {
        let id = uuid::Uuid::new_v4();
        let t = chrono::DateTime::from_timestamp(-10, 999_999_999).unwrap();
        let p = port::SubjectGroup { id: id.as_u128(), name: b"group".to_vec(), description: None,
            is_virtual, created_at: Timestamp { seconds: t.timestamp(), nanoseconds: t.timestamp_subsec_nanos() },
            updated_at: Timestamp { seconds: t.timestamp(), nanoseconds: t.timestamp_subsec_nanos() } };
        let u = upstream::SubjectGroup { id, name: "group".into(), description: None, is_virtual, created_at: t, updated_at: t };
        assert_eq!(port::is_immutable(&p), u.is_immutable());
    }
}
