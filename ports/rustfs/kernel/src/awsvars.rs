//! `policy/variables.rs`: `VariableResolver` and `resolve_aws_variables`.
//! The resolution functions call each other recursively, so their loops are
//! written as recursion; helpers that do not recurse keep their loops.
use crate::bytes;

/// The claims the resolver reads, already turned into strings
/// (`get_claim_as_strings`; JSON decoding is trusted).
#[derive(Debug, PartialEq, Eq)]
pub struct ClaimStrings {
    pub sub: Option<Vec<Vec<u8>>>,
    pub parent: Option<Vec<Vec<u8>>>,
    /// `claims.get("parent").and_then(as_str)`.
    pub parent_str: Option<Vec<u8>>,
    pub has_parent: bool,
    pub has_role_arn: bool,
    pub has_sa_policy: bool,
}

fn clone_opt_list(v: &Option<Vec<Vec<u8>>>) -> Option<Vec<Vec<u8>>> {
    match v {
        Some(l) => Some(clone_list(l)),
        None => None,
    }
}

// By hand: Aeneas has no `Option::clone`.
impl Clone for ClaimStrings {
    fn clone(&self) -> ClaimStrings {
        ClaimStrings {
            sub: clone_opt_list(&self.sub),
            parent: clone_opt_list(&self.parent),
            parent_str: match &self.parent_str {
                Some(p) => Some(p.clone()),
                None => None,
            },
            has_parent: self.has_parent,
            has_role_arn: self.has_role_arn,
            has_sa_policy: self.has_sa_policy,
        }
    }
}

/// `VariableContext` as `variable_resolver_for_policy_args` builds it.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct VarContext {
    pub username: Vec<u8>,
    pub account: Vec<u8>,
    pub claims: ClaimStrings,
    /// The clock, as RFC 3339 and as Unix seconds.
    pub now_rfc3339: Vec<u8>,
    pub now_epoch: Vec<u8>,
}

fn clone_list(v: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < v.len() {
        out.push(v[i].clone());
        i += 1;
    }
    out
}

/// `get_claim_as_strings("sub").or_else(|| get_claim_as_strings("parent"))`.
fn userid_strings(c: &ClaimStrings) -> Option<Vec<Vec<u8>>> {
    match &c.sub {
        Some(v) => Some(clone_list(v)),
        None => match &c.parent {
            Some(v) => Some(clone_list(v)),
            None => None,
        },
    }
}

/// `VariableResolver::resolve`.
pub fn resolve(ctx: &VarContext, name: &[u8]) -> Option<Vec<u8>> {
    if bytes::eq(name, b"aws:username") {
        return Some(ctx.username.clone());
    }
    if bytes::eq(name, b"aws:userid") {
        return match userid_strings(&ctx.claims) {
            Some(v) => {
                if v.len() == 0 {
                    None
                } else {
                    Some(v[v.len() - 1].clone())
                }
            }
            None => None,
        };
    }
    if bytes::eq(name, b"aws:PrincipalType") {
        if ctx.claims.has_role_arn {
            return Some(b"AssumedRole".to_vec());
        }
        if ctx.claims.has_parent && ctx.claims.has_sa_policy {
            return Some(b"ServiceAccount".to_vec());
        }
        return Some(b"User".to_vec());
    }
    if bytes::eq(name, b"aws:SecureTransport") {
        return Some(b"false".to_vec());
    }
    if bytes::eq(name, b"aws:CurrentTime") {
        return Some(ctx.now_rfc3339.clone());
    }
    if bytes::eq(name, b"aws:EpochTime") {
        return Some(ctx.now_epoch.clone());
    }
    if bytes::eq(name, b"aws:AccountId") {
        return Some(ctx.account.clone());
    }
    // `aws:Region`, `aws:SourceIp`: unset in this context; `custom:*`: none defined.
    None
}

/// `VariableResolver::resolve_multiple`.
pub fn resolve_multiple(ctx: &VarContext, name: &[u8]) -> Option<Vec<Vec<u8>>> {
    if bytes::eq(name, b"aws:username") {
        let mut v = Vec::new();
        v.push(ctx.username.clone());
        return Some(v);
    }
    if bytes::eq(name, b"aws:userid") {
        return userid_strings(&ctx.claims);
    }
    match resolve(ctx, name) {
        Some(s) => {
            let mut v = Vec::new();
            v.push(s);
            Some(v)
        }
        None => None,
    }
}

/// The matching `}` for a `${` whose body starts at `from`: the index and the
/// open-brace count left (0 when found).
fn closing(s: &[u8], from: usize) -> (usize, usize) {
    let mut brace: usize = 1;
    let mut end = from;
    while end < s.len() && brace > 0 {
        if s[end] == b'{' {
            brace += 1;
        } else if s[end] == b'}' {
            brace -= 1;
        }
        if brace > 0 {
            end += 1;
        }
    }
    (end, brace)
}

/// `format!("{prefix}{value}{suffix}")` for each value.
fn wrap_all(prefix: &[u8], values: &[Vec<u8>], suffix: &[u8]) -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < values.len() {
        out.push(bytes::concat(&bytes::concat(prefix, &values[i]), suffix));
        i += 1;
    }
    out
}

/// `results.splice(i..i + 1, new)`.
fn splice(results: &[Vec<u8>], i: usize, new: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    let mut k = 0;
    while k < i {
        out.push(results[k].clone());
        k += 1;
    }
    let mut j = 0;
    while j < new.len() {
        out.push(new[j].clone());
        j += 1;
    }
    let mut k2 = i + 1;
    while k2 < results.len() {
        out.push(results[k2].clone());
        k2 += 1;
    }
    out
}

/// One step of the inner `while let Some(pos) = results[i][start..].find("${")`
/// loop of `resolve_single_pass`: the new results and whether they changed.
fn scan(ctx: &VarContext, results: Vec<Vec<u8>>, i: usize, start: usize) -> (Vec<Vec<u8>>, bool) {
    let s = results[i].clone();
    let actual = match bytes::find_from(&s, start, b"${") {
        Some(p) => p,
        None => return (results, false),
    };
    let (end, brace) = closing(&s, actual + 2);
    if brace != 0 {
        return (results, false);
    }
    let var = bytes::slice(&s, actual + 2, end);
    let prefix = bytes::slice(&s, 0, actual);
    let suffix = bytes::slice(&s, end + 1, s.len());
    if bytes::contains(&var, b"${") {
        let inner = resolve_aws_variables(ctx, &var);
        let new = wrap_all(&prefix, &inner, &suffix);
        if new.len() > 0 {
            return (splice(&results, i, &new), true);
        }
        return scan(ctx, results, i, end + 1);
    }
    match resolve_multiple(ctx, &var) {
        Some(values) => {
            if values.len() > 0 {
                let new = wrap_all(&prefix, &values, &suffix);
                (splice(&results, i, &new), true)
            } else {
                let mut new = Vec::new();
                new.push(bytes::concat(&prefix, &suffix));
                (splice(&results, i, &new), true)
            }
        }
        None => scan(ctx, results, i, end + 1),
    }
}

/// The outer `while i < results.len()` loop of `resolve_single_pass`.
fn pass_from(ctx: &VarContext, results: Vec<Vec<u8>>, i: usize) -> Vec<Vec<u8>> {
    if i >= results.len() {
        return results;
    }
    let (results, modified) = scan(ctx, results, i, 0);
    if modified { pass_from(ctx, results, i) } else { pass_from(ctx, results, i + 1) }
}

/// `resolve_single_pass`.
pub fn resolve_single_pass(ctx: &VarContext, pattern: &[u8]) -> Vec<Vec<u8>> {
    let mut results = Vec::new();
    results.push(pattern.to_vec());
    pass_from(ctx, results, 0)
}

/// The `for result in &results` loop of one iteration: the new results and
/// whether any changed.
fn pass_all(ctx: &VarContext, results: &[Vec<u8>], k: usize, acc: Vec<Vec<u8>>, changed: bool)
    -> (Vec<Vec<u8>>, bool) {
    if k >= results.len() {
        return (acc, changed);
    }
    let resolved = resolve_single_pass(ctx, &results[k]);
    let differs = resolved.len() > 1 || (resolved.len() == 1 && !bytes::eq(&resolved[0], &results[k]));
    let acc = extend(acc, &resolved);
    pass_all(ctx, results, k + 1, acc, changed || differs)
}

fn extend(mut acc: Vec<Vec<u8>>, more: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let mut j = 0;
    while j < more.len() {
        acc.push(more[j].clone());
        j += 1;
    }
    acc
}

/// "Remove duplicates while preserving order".
fn dedup(v: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let mut out: Vec<Vec<u8>> = Vec::new();
    let mut i = 0;
    while i < v.len() {
        let x = v[i].clone();
        if !bytes::member(&out, &x) {
            out.push(x);
        }
        i += 1;
    }
    out
}

/// The `while changed && iteration < max_iterations` loop.
fn fixpoint(ctx: &VarContext, results: Vec<Vec<u8>>, iteration: usize) -> Vec<Vec<u8>> {
    if iteration >= 10 {
        return results;
    }
    let (new, changed) = pass_all(ctx, &results, 0, Vec::new(), false);
    let results = dedup(&new);
    if changed { fixpoint(ctx, results, iteration + 1) } else { results }
}

/// `resolve_aws_variables`.
pub fn resolve_aws_variables(ctx: &VarContext, pattern: &[u8]) -> Vec<Vec<u8>> {
    let mut results = Vec::new();
    results.push(pattern.to_vec());
    fixpoint(ctx, results, 0)
}
