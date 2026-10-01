//! `policy/resource.rs`.
use crate::awsvars::{resolve_aws_variables, VarContext};
use crate::condfuncs::{get_value, CondValues};
use crate::keynames::{common_key, COMMON_KEYS_LEN};
use crate::{bytes, pathclean, wildmatch};

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Resource {
    S3(Vec<u8>),
    Kms(Vec<u8>),
}

pub fn is_kms(r: &Resource) -> bool {
    match r {
        Resource::Kms(_) => true,
        Resource::S3(_) => false,
    }
}

/// The `for key in KeyName::COMMON_KEYS` substitution of `${..}` names whose
/// condition value is present.
fn substitute_common(pattern: &[u8], conditions: &CondValues) -> Vec<u8> {
    let mut out = pattern.to_vec();
    let mut k = 0;
    while k < COMMON_KEYS_LEN {
        let (name, var_name) = common_key(k);
        match get_value(conditions, &name) {
            Some(vs) => {
                if vs.len() > 0 && vs[0].len() > 0 {
                    out = bytes::replace(&out, &var_name, &vs[0]);
                }
            }
            None => {}
        }
        k += 1;
    }
    out
}

/// One resolved pattern against the cleaned resource.
fn pattern_matches(pattern: &[u8], resource: &[u8], conditions: &CondValues) -> bool {
    let resolved = if conditions.len() > 0 { substitute_common(pattern, conditions) } else { pattern.to_vec() };
    let cp = pathclean::clean(resource);
    let dot = bytes::eq(&cp, b".");
    if !dot && bytes::eq(&cp, &resolved) {
        return true;
    }
    !dot && wildmatch::is_match(&resolved, &cp)
}

/// `Resource::is_match_with_resolver`.
pub fn resource_is_match(r: &Resource, resource: &[u8], conditions: &CondValues, ctx: &Option<VarContext>) -> bool {
    let pattern = match r {
        Resource::S3(s) => s.clone(),
        Resource::Kms(s) => s.clone(),
    };
    let patterns = match ctx {
        Some(c) => resolve_aws_variables(c, &pattern),
        None => {
            let mut v = Vec::new();
            v.push(pattern);
            v
        }
    };
    let mut i = 0;
    while i < patterns.len() {
        if pattern_matches(&patterns[i], resource, conditions) {
            return true;
        }
        i += 1;
    }
    false
}

/// `ResourceSet::is_match_with_resolver`.
pub fn set_is_match(set: &[Resource], resource: &[u8], conditions: &CondValues, ctx: &Option<VarContext>) -> bool {
    let mut i = 0;
    while i < set.len() {
        if resource_is_match(&set[i], resource, conditions, ctx) {
            return true;
        }
        i += 1;
    }
    false
}
