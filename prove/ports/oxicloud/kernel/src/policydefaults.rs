//! Pure validation of decoded policy-default object keys.
use crate::{model::DriveKind, policycompare::{self, Knob}};
#[derive(Clone, Copy)]
pub enum KeyRejection { NotDefaultable, Unknown, NotApplicable }
pub enum Validation { Valid, NotObject, Rejected(usize, KeyRejection) }
/// Validate one classified name in the upstream rejection order.
pub fn reject_knob(knob: Knob, kind: DriveKind) -> Option<KeyRejection> {
    match knob {
        Knob::ReadOnly => return Some(KeyRejection::NotDefaultable),
        _ => (),
    }
    match knob {
        Knob::Other => return Some(KeyRejection::Unknown),
        _ => (),
    }
    if !policycompare::knob_applies_to_kind(knob, kind) {
        return Some(KeyRejection::NotApplicable);
    }
    None
}
pub fn reject_key(raw: &[u8], kind: DriveKind) -> Option<KeyRejection> {
    reject_knob(policycompare::knob_from_bytes(raw), kind)
}
/// Upstream `DrivePolicyDefaultsService::validate`; values are unobserved.
/// The shell supplies object keys in the pinned JSON map's iteration order.
pub fn validate(kind: DriveKind, is_object: bool, keys: &[Vec<u8>]) -> Validation {
    if !is_object { return Validation::NotObject; }
    let mut i = 0;
    while i < keys.len() {
        match reject_key(&keys[i], kind) {
            Some(reason) => return Validation::Rejected(i, reason),
            None => (),
        }
        i += 1;
    }
    Validation::Valid
}
