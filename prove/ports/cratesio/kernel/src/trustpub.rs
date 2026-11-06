//! `src/controllers/trustpub/tokens/exchange/mod.rs`
//! `handle_github_token_inner`: which crates a GitHub Actions OIDC token may
//! publish, and `crates/crates_io_trustpub/src/github/workflows.rs`
//! `extract_workflow_filename`.
//!
//! The JWT signature, issuer, audience and expiry checks
//! (`GitHubClaims::decode`) are trusted: the kernel receives the claims they
//! accepted. Postgres `lower()` and Rust `to_lowercase()` are taken as ASCII
//! lowercasing (GitHub owner and repository names are ASCII; DEVIATIONS.md).

use crate::bytes::{eq, lower, sub};

/// The claims the exchange reads.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct GitHubClaims {
    pub jti: Vec<u8>,
    pub event_name: Vec<u8>,
    pub repository: Vec<u8>,
    pub workflow_ref: Vec<u8>,
    pub repository_owner_id: Vec<u8>,
    pub environment: Option<Vec<u8>>,
}

/// A `trustpub_configs_github` row.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct GitHubConfig {
    pub crate_id: i32,
    pub repository_owner: Vec<u8>,
    pub repository_name: Vec<u8>,
    pub repository_owner_id: i32,
    pub workflow_filename: Vec<u8>,
    pub environment: Option<Vec<u8>>,
}

/// The exchange's refusals (`400` each).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ExchangeError {
    /// The `jti` was used before.
    JtiReused,
    /// `pull_request_target` or `workflow_run`.
    ForbiddenEvent,
    BadRepository,
    BadWorkflowRef,
    BadOwnerId,
    NoConfig,
    OwnerIdMismatch,
    WorkflowMismatch,
    EnvironmentMismatch,
}

/// ASCII-case-insensitive equality (`lower(a) = lower(b)`).
pub fn eq_lower(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if lower(a[i]) != lower(b[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `"pull_request_target"`.
pub const PULL_REQUEST_TARGET: [u8; 19] = [
    b'p', b'u', b'l', b'l', b'_', b'r', b'e', b'q', b'u', b'e', b's', b't', b'_', b't', b'a', b'r',
    b'g', b'e', b't',
];
/// `"workflow_run"`.
pub const WORKFLOW_RUN: [u8; 12] = [b'w', b'o', b'r', b'k', b'f', b'l', b'o', b'w', b'_', b'r', b'u', b'n'];

/// `s[k-4..k] == ".yml"` or `s[k-5..k] == ".yaml"`, with at least one byte
/// before the dot after `seg` (`[^/]+\.(yml|yaml)` from `seg` to `k`).
pub fn yml_end(s: &[u8], seg: usize, k: usize) -> bool {
    if k >= seg + 5
        && s[k - 4] == b'.'
        && s[k - 3] == b'y'
        && s[k - 2] == b'm'
        && s[k - 1] == b'l'
    {
        return true;
    }
    k >= seg + 6 && s[k - 5] == b'.' && s[k - 4] == b'y' && s[k - 3] == b'a' && s[k - 2] == b'm' && s[k - 1] == b'l'
}

/// The end of the slash-free segment starting at `seg`.
pub fn seg_end(s: &[u8], seg: usize) -> usize {
    let mut e = seg;
    while e < s.len() && s[e] != b'/' {
        e += 1;
    }
    e
}

/// The end of a match in the segment `seg..e`: the last `@` (greedy
/// `[^/]+`) preceded by `.yml`/`.yaml` and followed by a non-newline byte.
pub fn match_in_segment(s: &[u8], seg: usize, e: usize) -> Option<usize> {
    let mut k = e;
    while k > seg {
        let at = k - 1;
        if s[at] == b'@' && at + 1 < s.len() && s[at + 1] != b'\n' && yml_end(s, seg, at) {
            return Some(at);
        }
        k -= 1;
    }
    None
}

/// The first segment, from `seg` on, with a match: its start and the match end.
pub fn first_match(s: &[u8], seg: usize) -> Option<(usize, usize)> {
    let mut seg = seg;
    while seg < s.len() {
        let e = seg_end(s, seg);
        match match_in_segment(s, seg, e) {
            Some(at) => return Some((seg, at)),
            None => {}
        }
        seg = e + 1;
    }
    None
}

/// `extract_workflow_filename`: the regex `([^/]+\.(yml|yaml))(@.+)`, first
/// match, group 1. The leftmost match starts at the first slash-free segment
/// that contains a `.yml@` / `.yaml@` end followed by a non-newline
/// character; greedy `[^/]+` takes the last such end in that segment.
pub fn workflow_filename(s: &[u8]) -> Option<Vec<u8>> {
    match first_match(s, 0) {
        None => None,
        Some((seg, at)) => Some(sub(s, seg, at)),
    }
}

/// The value of the decimal digits `s[start..]`, if all are digits and it
/// stays at most `2^31`.
pub fn digits_value(s: &[u8], start: usize) -> Option<i64> {
    let mut acc: i64 = 0;
    let mut i = start;
    while i < s.len() {
        let b = s[i];
        if !(b >= b'0' && b <= b'9') {
            return None;
        }
        acc = acc * 10 + ((b - b'0') as i64);
        if acc > 2147483648 {
            return None;
        }
        i += 1;
    }
    Some(acc)
}

/// `str::parse::<i32>`: an optional sign, then decimal digits, in range.
pub fn parse_i32(s: &[u8]) -> Option<i32> {
    if s.len() == 0 {
        return None;
    }
    let neg = s[0] == b'-';
    let start = if s[0] == b'-' || s[0] == b'+' { 1 } else { 0 };
    if start == s.len() {
        return None;
    }
    match digits_value(s, start) {
        None => None,
        Some(acc) => {
            if neg {
                Some((-acc) as i32)
            } else if acc > 2147483647 {
                None
            } else {
                Some(acc as i32)
            }
        }
    }
}

/// The position of the first `/`.
pub fn first_slash(s: &[u8]) -> Option<usize> {
    let mut i = 0;
    while i < s.len() {
        if s[i] == b'/' {
            return Some(i);
        }
        i += 1;
    }
    None
}

/// `used.contains(jti)`.
pub fn jti_used(used: &Vec<Vec<u8>>, jti: &[u8]) -> bool {
    let mut i = 0;
    while i < used.len() {
        if eq(&used[i], jti) {
            return true;
        }
        i += 1;
    }
    false
}

/// The environment rule: a config without an environment accepts any; one
/// with an environment needs the claim to carry the same (case-insensitive).
pub fn env_ok(config_env: &Option<Vec<u8>>, claim_env: &Option<Vec<u8>>) -> bool {
    match config_env {
        None => true,
        Some(c) => match claim_env {
            None => false,
            Some(s) => eq_lower(c, s),
        },
    }
}

/// How far a config matches the token: `0` other repository, `1` same
/// repository (owner and name, ignoring case), `2` and same owner id, `3` and
/// same workflow file, `4` and an accepted environment.
pub fn config_level(c: &GitHubConfig, owner: &[u8], name: &[u8], owner_id: i32, workflow: &[u8], env: &Option<Vec<u8>>) -> u8 {
    if !(eq_lower(&c.repository_owner, owner) && eq_lower(&c.repository_name, name)) {
        return 0;
    }
    if c.repository_owner_id != owner_id {
        return 1;
    }
    if !eq(&c.workflow_filename, workflow) {
        return 2;
    }
    if !env_ok(&c.environment, env) {
        return 3;
    }
    4
}

/// Some config reaches level `k` (upstream: the list left after the
/// `k`-th `extract_if` is non-empty).
pub fn any_level(configs: &Vec<GitHubConfig>, owner: &[u8], name: &[u8], owner_id: i32, workflow: &[u8], env: &Option<Vec<u8>>, k: u8) -> bool {
    let mut i = 0;
    while i < configs.len() {
        if config_level(&configs[i], owner, name, owner_id, workflow, env) >= k {
            return true;
        }
        i += 1;
    }
    false
}

/// The crate ids of the configs that match fully, in order.
pub fn matching_ids(configs: &Vec<GitHubConfig>, owner: &[u8], name: &[u8], owner_id: i32, workflow: &[u8], env: &Option<Vec<u8>>) -> Vec<i32> {
    let mut ids = Vec::new();
    let mut i = 0;
    while i < configs.len() {
        if config_level(&configs[i], owner, name, owner_id, workflow, env) >= 4 {
            ids.push(configs[i].crate_id);
        }
        i += 1;
    }
    ids
}

/// `handle_github_token_inner`: on success the crate ids the new access
/// token is valid for, and the `jti` table with the claim's `jti` added.
/// On failure the transaction rolls back and the `jti` table is unchanged.
pub fn exchange_github(
    used: &Vec<Vec<u8>>,
    configs: &Vec<GitHubConfig>,
    claims: &GitHubClaims,
) -> Result<(Vec<i32>, Vec<Vec<u8>>), ExchangeError> {
    if jti_used(used, &claims.jti) {
        return Err(ExchangeError::JtiReused);
    }
    if eq(&claims.event_name, &PULL_REQUEST_TARGET) || eq(&claims.event_name, &WORKFLOW_RUN) {
        return Err(ExchangeError::ForbiddenEvent);
    }
    let slash = match first_slash(&claims.repository) {
        None => return Err(ExchangeError::BadRepository),
        Some(i) => i,
    };
    let owner = sub(&claims.repository, 0, slash);
    let name = sub(&claims.repository, slash + 1, claims.repository.len());
    let workflow = match workflow_filename(&claims.workflow_ref) {
        None => return Err(ExchangeError::BadWorkflowRef),
        Some(w) => w,
    };
    let owner_id = match parse_i32(&claims.repository_owner_id) {
        None => return Err(ExchangeError::BadOwnerId),
        Some(v) => v,
    };
    let env = &claims.environment;
    if !any_level(configs, &owner, &name, owner_id, &workflow, env, 1) {
        return Err(ExchangeError::NoConfig);
    }
    if !any_level(configs, &owner, &name, owner_id, &workflow, env, 2) {
        return Err(ExchangeError::OwnerIdMismatch);
    }
    if !any_level(configs, &owner, &name, owner_id, &workflow, env, 3) {
        return Err(ExchangeError::WorkflowMismatch);
    }
    let ids = matching_ids(configs, &owner, &name, owner_id, &workflow, env);
    if ids.len() == 0 {
        return Err(ExchangeError::EnvironmentMismatch);
    }
    let mut out = used.clone();
    out.push(sub(&claims.jti, 0, claims.jti.len()));
    Ok((ids, out))
}
