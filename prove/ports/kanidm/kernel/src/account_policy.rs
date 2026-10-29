//! Scalar projection of ResolvedAccountPolicy::fold_from at f608c4f.
//! CA-list intersection is a separate cryptographic payload boundary.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Policy {
    pub privilege_expiry: u32,
    pub authsession_expiry: u32,
    pub pw_min_length: u32,
    pub credential_policy: u16,
    pub limit_search_max_filter_test: Option<u64>,
    pub limit_search_max_results: Option<u64>,
    pub allow_primary_cred_fallback: Option<bool>,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Resolved {
    pub policy: Policy,
    pub pw_max_length: u32,
}
pub fn initial() -> Policy {
    Policy { privilege_expiry: 3600, authsession_expiry: u32::MAX,
      pw_min_length: 10, credential_policy: 0,
      limit_search_max_filter_test: None, limit_search_max_results: None,
      allow_primary_cred_fallback: None }
}
pub fn option_max(acc: Option<u64>, pol: Option<u64>) -> Option<u64> {
    match pol { None => acc, Some(p) => match acc { None => Some(p),
      Some(a) => if p > a { Some(p) } else { Some(a) } } }
}
pub fn combine(acc: Policy, pol: Policy) -> Policy {
    Policy {
      privilege_expiry: if pol.privilege_expiry < acc.privilege_expiry { pol.privilege_expiry } else { acc.privilege_expiry },
      authsession_expiry: if pol.authsession_expiry < acc.authsession_expiry { pol.authsession_expiry } else { acc.authsession_expiry },
      pw_min_length: if pol.pw_min_length > acc.pw_min_length { pol.pw_min_length } else { acc.pw_min_length },
      credential_policy: if pol.credential_policy > acc.credential_policy { pol.credential_policy } else { acc.credential_policy },
      limit_search_max_filter_test: option_max(acc.limit_search_max_filter_test, pol.limit_search_max_filter_test),
      limit_search_max_results: option_max(acc.limit_search_max_results, pol.limit_search_max_results),
      allow_primary_cred_fallback: match pol.allow_primary_cred_fallback {
        None => acc.allow_primary_cred_fallback,
        Some(p) => match acc.allow_primary_cred_fallback { None => Some(p), Some(a) => Some(p && a) }
      }
    }
}
pub fn finalize(acc: Policy) -> Resolved {
    let mut policy = acc;
    if policy.credential_policy < 10 && policy.pw_min_length < 15 {
        policy.pw_min_length = 15;
    }
    Resolved { policy, pw_max_length: 128 }
}
pub fn fold_from(policies: &[Policy]) -> Resolved {
    let mut acc = initial();
    let mut i = 0;
    while i < policies.len() {
        acc = combine(acc, policies[i]);
        i += 1;
    }
    finalize(acc)
}
