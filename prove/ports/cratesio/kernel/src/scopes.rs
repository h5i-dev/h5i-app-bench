//! `crates/crates_io_database/src/models/token/scopes.rs`: `EndpointScope`
//! and `CrateScope` (RFC 2947).

use crate::bytes::{eq, starts_with, sub};
use crate::validation::validate_crate_name;

/// `EndpointScope`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum EndpointScope {
    PublishNew,
    PublishUpdate,
    TrustedPublishing,
    Yank,
    ChangeOwners,
}

/// `EndpointScope == EndpointScope`.
pub fn scope_eq(a: EndpointScope, b: EndpointScope) -> bool {
    match (a, b) {
        (EndpointScope::PublishNew, EndpointScope::PublishNew) => true,
        (EndpointScope::PublishUpdate, EndpointScope::PublishUpdate) => true,
        (EndpointScope::TrustedPublishing, EndpointScope::TrustedPublishing) => true,
        (EndpointScope::Yank, EndpointScope::Yank) => true,
        (EndpointScope::ChangeOwners, EndpointScope::ChangeOwners) => true,
        _ => false,
    }
}

/// `token_scopes.contains(endpoint_scope)`.
pub fn contains_scope(scopes: &[EndpointScope], s: EndpointScope) -> bool {
    let mut i = 0;
    while i < scopes.len() {
        if scope_eq(scopes[i], s) {
            return true;
        }
        i += 1;
    }
    false
}

/// The pattern ends with `*`.
pub fn ends_with_star(p: &[u8]) -> bool {
    p.len() > 0 && p[p.len() - 1] == b'*'
}

/// The pattern is exactly `*`.
pub fn is_star(p: &[u8]) -> bool {
    p.len() == 1 && p[0] == b'*'
}

/// `CrateScope::is_valid_pattern`: `*`, or a crate name optionally followed
/// by one `*`.
pub fn is_valid_pattern(p: &[u8]) -> bool {
    if p.len() == 0 {
        return false;
    }
    if is_star(p) {
        return true;
    }
    let name = if ends_with_star(p) { sub(p, 0, p.len() - 1) } else { sub(p, 0, p.len()) };
    match validate_crate_name(&name) {
        Ok(()) => true,
        Err(_) => false,
    }
}

/// `CrateScope::matches`: `*` matches every name, `prefix*` names starting
/// with `prefix`, anything else exactly that name.
pub fn scope_matches(p: &[u8], crate_name: &[u8]) -> bool {
    if is_star(p) {
        return true;
    }
    if ends_with_star(p) {
        let prefix = sub(p, 0, p.len() - 1);
        starts_with(crate_name, &prefix)
    } else {
        eq(crate_name, p)
    }
}

/// `token_scopes.iter().any(|token_scope| token_scope.matches(crate_name))`.
pub fn any_scope_matches(scopes: &Vec<Vec<u8>>, crate_name: &[u8]) -> bool {
    let mut i = 0;
    while i < scopes.len() {
        if scope_matches(&scopes[i], crate_name) {
            return true;
        }
        i += 1;
    }
    false
}
