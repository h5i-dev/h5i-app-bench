use crate::tests::{Rng, b};
use rustfs_kernel::{docdata as k, manage::Policy};
use rustfs_private_oracle::{
    policy::{self as u, doc::PolicyDoc},
    time::{OffsetDateTime, UtcOffset},
};
fn policy(id: &str) -> (u::Policy, Policy) {
    (
        u::Policy {
            id: id.into(),
            version: "2012-10-17".into(),
            statements: vec![],
        },
        Policy {
            id: b(id),
            version: b("2012-10-17"),
            statements: vec![],
        },
    )
}
fn stamp(t: Option<OffsetDateTime>) -> Option<k::Timestamp> {
    t.map(|t| k::Timestamp {
        unix_nanos: t.unix_timestamp_nanos(),
        offset_seconds: t.offset().whole_seconds(),
    })
}
fn compare(up: &PolicyDoc, port: &k::PolicyDoc) {
    assert_eq!(port.version, up.version);
    assert_eq!(port.policy.id, b(&up.policy.id));
    assert_eq!(port.policy.version, b(&up.policy.version));
    assert_eq!(port.create_date, stamp(up.create_date));
    assert_eq!(port.update_date, stamp(up.update_date));
}
#[test]
fn documents_agree() {
    let mut rng = Rng(1014);
    for _ in 0..5000 {
        let (up, port) = policy("before");
        let time = OffsetDateTime::from_unix_timestamp_nanos(
            rng.below(4000000000) as i128 * 1000000000 + rng.below(1000000000) as i128,
        )
        .unwrap()
        .to_offset(UtcOffset::from_whole_seconds(rng.below(172799) as i32 - 86399).unwrap());
        let at = stamp(Some(time)).unwrap();
        let mut ud = PolicyDoc::new_at(up.clone(), time);
        let mut kd = k::new_at(port, at);
        compare(&ud, &kd);
        let (up, port) = policy("default");
        compare(&PolicyDoc::default_policy(up), &k::default_policy(port));
        if rng.chance(50) {
            ud.create_date = None;
            kd.create_date = None;
        }
        ud.version = rng.below(100000) as i64 - 50000;
        kd.version = ud.version;
        let (up, port) = policy("updated");
        let time =
            time + rustfs_private_oracle::time::Duration::seconds(rng.below(20000) as i64 - 10000);
        ud.update_at(up, time);
        k::update_at(&mut kd, port, stamp(Some(time)).unwrap());
        compare(&ud, &kd);
    }
    let d = k::default_doc();
    compare(&PolicyDoc::default(), &d);
}

#[test]
fn documents_preserve_generated_policies() {
    let mut rng = Rng(1015);
    for _ in 0..1000 {
        let (up, port) = crate::management::policy(&mut rng);
        let originals = up
            .statements
            .iter()
            .cloned()
            .zip(port.statements.iter().cloned())
            .collect::<Vec<_>>();
        let time = OffsetDateTime::from_unix_timestamp_nanos(
            (rng.below(8000000000) as i128 - 4000000000) * 1000000000
                + rng.below(1000000000) as i128,
        )
        .unwrap();
        let at = stamp(Some(time)).unwrap();
        let mut ud = PolicyDoc::new_at(up.clone(), time);
        let mut kd = k::new_at(port.clone(), at);
        compare(&ud, &kd);
        crate::management::assert_policy(&ud.policy, &kd.policy, &originals);
        let ud0 = PolicyDoc::default_policy(up.clone());
        let kd0 = k::default_policy(port.clone());
        compare(&ud0, &kd0);
        crate::management::assert_policy(&ud0.policy, &kd0.policy, &originals);
        ud.update_at(up, time);
        k::update_at(&mut kd, port, at);
        compare(&ud, &kd);
        crate::management::assert_policy(&ud.policy, &kd.policy, &originals);
    }
}
