//! Explicit-time PolicyDoc constructors and revision updates from policy/doc.rs.
use crate::manage::Policy;
/// Retain the instant and original offset for the shell's RFC3339 serialization.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Timestamp {
    pub unix_nanos: i128,
    pub offset_seconds: i32,
}
pub struct PolicyDoc {
    pub version: i64,
    pub policy: Policy,
    pub create_date: Option<Timestamp>,
    pub update_date: Option<Timestamp>,
}
pub fn new_at(policy: Policy, at: Timestamp) -> PolicyDoc {
    PolicyDoc {
        version: 1,
        policy,
        create_date: Some(at),
        update_date: Some(at),
    }
}
pub fn update_at(doc: &mut PolicyDoc, policy: Policy, at: Timestamp) {
    doc.version += 1;
    doc.policy = policy;
    doc.update_date = Some(at);
    if doc.create_date.is_none() {
        doc.create_date = doc.update_date;
    }
}
pub fn default_policy(policy: Policy) -> PolicyDoc {
    PolicyDoc {
        version: 1,
        policy,
        create_date: None,
        update_date: None,
    }
}
/// Derived Default on the decoded document, including its default empty policy.
pub fn default_doc() -> PolicyDoc {
    PolicyDoc {
        version: 0,
        policy: Policy {
            id: Vec::new(),
            version: Vec::new(),
            statements: Vec::new(),
        },
        create_date: None,
        update_date: None,
    }
}
