//! Token scope grammar, access check and delegation containment.
//!
//! Ported from `backend/windmill-common/src/scopes.rs` @ 9dedc42:
//! `ScopeDefinition::{from_scope_string, includes}`, `resources_match`,
//! `resources_match_small`, `resources_match_large`, `resource_matches_pattern`,
//! `scope_contains`, `resource_set_contains`, `resource_covers`,
//! `intersect_job_token_scopes`.
//!
//! `Option<String>` / `Option<Vec<String>>` fields are a flag plus a value
//! (`has_kind`/`kind`, `has_resource`/`resource`); the value is empty when the flag is
//! false. `resources_match_large` uses a `HashSet` of the exact (no `*`) scope
//! resources; here it is the same membership test by a scan.
use crate::bytes::{
    contains_byte, ends_with_slash_star, eq, is_star, list_contains, list_has_star,
    nth_char_is_slash, prefix, split, starts_with,
};

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Scope {
    pub domain: Vec<u8>,
    pub action: Vec<u8>,
    pub has_kind: bool,
    pub kind: Vec<u8>,
    pub has_resource: bool,
    pub resource: Vec<Vec<u8>>,
}

pub const JOBS: &[u8] = b"jobs";
pub const RUN: &[u8] = b"run";
pub const READ: &[u8] = b"read";
pub const WRITE: &[u8] = b"write";
pub const CANCEL: &[u8] = b"cancel";
pub const APPS: &[u8] = b"apps";

/// `ScopeDefinition::from_scope_string`; `None` is `Err(BadRequest)`.
pub fn from_scope_string(s: &[u8]) -> Option<Scope> {
    let parts = split(s, 58);
    if parts.len() == 2 {
        return Some(Scope {
            domain: parts[0].clone(),
            action: parts[1].clone(),
            has_kind: false,
            kind: Vec::new(),
            has_resource: false,
            resource: Vec::new(),
        });
    }
    if parts.len() == 3 {
        if eq(&parts[0], JOBS) && eq(&parts[1], RUN) {
            return Some(Scope {
                domain: parts[0].clone(),
                action: parts[1].clone(),
                has_kind: true,
                kind: parts[2].clone(),
                has_resource: false,
                resource: Vec::new(),
            });
        }
        return Some(Scope {
            domain: parts[0].clone(),
            action: parts[1].clone(),
            has_kind: false,
            kind: Vec::new(),
            has_resource: true,
            resource: split(&parts[2], 44),
        });
    }
    if parts.len() == 4 {
        if eq(&parts[0], JOBS) && eq(&parts[1], RUN) {
            return Some(Scope {
                domain: parts[0].clone(),
                action: parts[1].clone(),
                has_kind: true,
                kind: parts[2].clone(),
                has_resource: true,
                resource: split(&parts[3], 44),
            });
        }
        return None;
    }
    None
}

/// The action part of `includes` (and of `scope_contains`, which has the same table).
pub fn action_covers(domain: &[u8], a: &[u8], b: &[u8]) -> bool {
    if (eq(a, WRITE) && eq(b, READ)) || eq(a, b) {
        return true;
    }
    if eq(a, WRITE) && eq(b, RUN) && eq(domain, APPS) {
        return true;
    }
    eq(a, WRITE) && eq(b, CANCEL) && eq(domain, JOBS)
}

/// The `matches_wildcard` closure of `resource_matches_pattern`. Note
/// `resource.chars().nth(prefix.len())`: a character index compared with a byte length.
pub fn matches_wildcard(pattern: &[u8], resource: &[u8]) -> bool {
    if !ends_with_slash_star(pattern) {
        return false;
    }
    let pre = prefix(pattern, pattern.len() - 2);
    if !starts_with(resource, &pre) {
        return false;
    }
    if resource.len() == pre.len() {
        return true;
    }
    nth_char_is_slash(resource, pre.len())
}

/// `resource_matches_pattern`.
pub fn resource_matches_pattern(scope_resource: &[u8], accepted_resource: &[u8]) -> bool {
    if eq(scope_resource, accepted_resource) {
        return true;
    }
    matches_wildcard(scope_resource, accepted_resource)
        || matches_wildcard(accepted_resource, scope_resource)
}

/// `resources_match_small`.
pub fn resources_match_small(scope_resources: &[Vec<u8>], accepted: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < accepted.len() {
        let mut j = 0;
        while j < scope_resources.len() {
            if resource_matches_pattern(&scope_resources[j], &accepted[i]) {
                return true;
            }
            j += 1;
        }
        i += 1;
    }
    false
}

/// `exact_matches.contains(accepted)`: some scope resource without `*` equals it.
pub fn exact_contains(scope_resources: &[Vec<u8>], accepted: &[u8]) -> bool {
    let mut j = 0;
    while j < scope_resources.len() {
        if !contains_byte(&scope_resources[j], 42) && eq(&scope_resources[j], accepted) {
            return true;
        }
        j += 1;
    }
    false
}

/// Some scope resource containing `*` matches `accepted`.
pub fn pattern_matches(scope_resources: &[Vec<u8>], accepted: &[u8]) -> bool {
    let mut j = 0;
    while j < scope_resources.len() {
        if contains_byte(&scope_resources[j], 42)
            && resource_matches_pattern(&scope_resources[j], accepted)
        {
            return true;
        }
        j += 1;
    }
    false
}

/// `resources_match_large`.
pub fn resources_match_large(scope_resources: &[Vec<u8>], accepted: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < accepted.len() {
        if exact_contains(scope_resources, &accepted[i]) {
            return true;
        }
        if pattern_matches(scope_resources, &accepted[i]) {
            return true;
        }
        i += 1;
    }
    false
}

/// `resources_match`.
pub fn resources_match(scope_resources: &[Vec<u8>], accepted: &[Vec<u8>]) -> bool {
    if list_has_star(scope_resources) || list_has_star(accepted) {
        return true;
    }
    if scope_resources.len() <= 4 && accepted.len() <= 4 {
        return resources_match_small(scope_resources, accepted);
    }
    resources_match_large(scope_resources, accepted)
}

/// `ScopeDefinition::includes`: does scope `s` grant the required scope `o`?
pub fn includes(s: &Scope, o: &Scope) -> bool {
    if !eq(&s.domain, &o.domain) {
        return false;
    }
    if !action_covers(&s.domain, &s.action, &o.action) {
        return false;
    }
    if eq(&s.domain, JOBS) && eq(&s.action, RUN) {
        if s.has_kind {
            if o.has_kind {
                if !eq(&s.kind, &o.kind) {
                    return false;
                }
            } else {
                return false;
            }
        } else {
            return true;
        }
    }
    if s.has_resource {
        if o.has_resource {
            resources_match(&s.resource, &o.resource)
        } else {
            list_has_star(&s.resource)
        }
    } else {
        true
    }
}

/// `resource_covers`: does the caller resource pattern cover `requested`?
pub fn resource_covers(caller: &[u8], requested: &[u8]) -> bool {
    if eq(caller, requested) {
        return true;
    }
    if !ends_with_slash_star(caller) {
        return false;
    }
    let pre = prefix(caller, caller.len() - 2);
    let base = if ends_with_slash_star(requested) {
        prefix(requested, requested.len() - 2)
    } else {
        requested.to_vec()
    };
    if eq(&base, &pre) {
        return true;
    }
    starts_with(&base, &pre) && base.len() > pre.len() && base[pre.len()] == 47
}

/// Some caller resource covers `req`.
pub fn some_covers(caller: &[Vec<u8>], req: &[u8]) -> bool {
    let mut j = 0;
    while j < caller.len() {
        if resource_covers(&caller[j], req) {
            return true;
        }
        j += 1;
    }
    false
}

/// `resource_set_contains`.
pub fn resource_set_contains(caller: &[Vec<u8>], requested: &[Vec<u8>]) -> bool {
    if list_has_star(caller) {
        return true;
    }
    let mut i = 0;
    while i < requested.len() {
        if is_star(&requested[i]) || !some_covers(caller, &requested[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `scope_contains`: does `caller` grant at least everything `requested` grants?
pub fn scope_contains(caller: &Scope, requested: &Scope) -> bool {
    if !eq(&caller.domain, &requested.domain) {
        return false;
    }
    if !action_covers(&caller.domain, &caller.action, &requested.action) {
        return false;
    }
    if eq(&caller.domain, JOBS) && eq(&caller.action, RUN) && caller.has_kind {
        if requested.has_kind {
            if !eq(&caller.kind, &requested.kind) {
                return false;
            }
        } else {
            return false;
        }
    }
    if !caller.has_resource {
        return true;
    }
    if !requested.has_resource {
        return list_has_star(&caller.resource);
    }
    resource_set_contains(&caller.resource, &requested.resource)
}

/// `by.iter().flatten().any(|b| scope_contains(b, p))`.
pub fn some_contains(by: &[Vec<u8>], p: &Scope) -> bool {
    let mut j = 0;
    while j < by.len() {
        match from_scope_string(&by[j]) {
            Some(b) => {
                if scope_contains(&b, p) {
                    return true;
                }
            }
            None => {}
        }
        j += 1;
    }
    false
}

/// The `keep_covered` closure of `intersect_job_token_scopes`.
pub fn keep_covered(out: &mut Vec<Vec<u8>>, raw: &[Vec<u8>], by: &[Vec<u8>]) {
    let mut i = 0;
    while i < raw.len() {
        match from_scope_string(&raw[i]) {
            Some(p) => {
                if some_contains(by, &p) && !list_contains(out, &raw[i]) {
                    out.push(raw[i].clone());
                }
            }
            None => {}
        }
        i += 1;
    }
}

/// `intersect_job_token_scopes(Some(ceiling), Some(own))` (the `None` cases return the
/// other side unchanged).
pub fn intersect_job_token_scopes(ceiling: &[Vec<u8>], own: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let mut out: Vec<Vec<u8>> = Vec::new();
    keep_covered(&mut out, own, ceiling);
    keep_covered(&mut out, ceiling, own);
    out
}
