//! Nora f864a9a import/permissions.rs: inert permission proposal decisions.
//! Identifiers are order-preserving interned strings. Audit strings are typed
//! events; OIDC scope ids render as the original repository name plus `/**`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Verb { Read, Write, Admin }
#[derive(Clone, Debug)]
pub struct Principal {
    pub name: u64,
    pub is_group: bool,
    pub members: Vec<u64>,
    pub repos: Vec<u64>,
    pub verb: Verb,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Acc {
    pub user: u64,
    pub verb: Verb,
    pub repo_scoped: bool,
    pub from_group: bool,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct TokenProposal { pub user: u64, pub role: Verb, pub from_group: bool }
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct OidcSuggestion { pub identity: u64, pub repos: Vec<u64>, pub role: Verb }
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Audit {
    GroupFlattened { group: u64, verb: Verb, members: usize },
    AdminNarrowed { user: u64 },
    ScopeWidened { user: u64, role: Verb },
    WriteWithheld { user: u64, role: Verb },
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Report {
    pub proposed_tokens: Vec<TokenProposal>,
    pub oidc: Vec<OidcSuggestion>,
    pub narrowed: Vec<Audit>,
    pub widened: Vec<Audit>,
    pub warn_oidc: bool,
    pub warn_global_write: bool,
}
pub fn stronger(a: Verb, b: Verb) -> Verb {
    match (a, b) {
        (Verb::Admin, _) | (_, Verb::Admin) => Verb::Admin,
        (Verb::Write, _) | (_, Verb::Write) => Verb::Write,
        _ => Verb::Read,
    }
}
pub fn narrow_admin(v: Verb) -> Verb {
    match v { Verb::Admin => Verb::Write, other => other }
}
pub fn token_role(v: Verb, grant_write: bool) -> Verb {
    let mapped = narrow_admin(v);
    if mapped == Verb::Read || grant_write { mapped } else { Verb::Read }
}
pub fn contribute(users: &[Acc], user: u64, verb: Verb, repo_scoped: bool, from_group: bool) -> Vec<Acc> {
    let mut out = Vec::new();
    let mut added = false;
    let mut i = 0;
    while i < users.len() {
        let e = users[i];
        if !added && user < e.user {
            out.push(Acc { user, verb, repo_scoped, from_group });
            added = true;
        }
        if user == e.user {
            out.push(Acc { user, verb: stronger(e.verb, verb),
                repo_scoped: e.repo_scoped || repo_scoped,
                from_group: e.from_group || from_group });
            added = true;
        } else { out.push(e); }
        i += 1;
    }
    if !added { out.push(Acc { user, verb, repo_scoped, from_group }); }
    out
}
#[derive(Clone, Debug)]
pub struct Collected { pub users: Vec<Acc>, pub narrowed: Vec<Audit>, pub oidc: Vec<OidcSuggestion> }
pub fn contribute_group(users: &[Acc], p: &Principal) -> Vec<Acc> {
    let mut out = users.to_vec();
    let mut j = 0;
    while j < p.members.len() {
        out = contribute(&out, p.members[j], p.verb, p.repos.len() != 0, true);
        j += 1;
    }
    out
}
pub fn add_oidc(mut oidc: Vec<OidcSuggestion>, identity: u64, repos: &[u64], verb: Verb) -> Vec<OidcSuggestion> {
    if repos.len() != 0 {
        oidc.push(OidcSuggestion { identity, repos: repos.to_vec(), role: narrow_admin(verb) });
    }
    oidc
}
pub fn collect(principals: &[Principal]) -> Collected {
    let mut users = Vec::new();
    let mut narrowed = Vec::new();
    let mut oidc = Vec::new();
    let mut i = 0;
    while i < principals.len() {
        let p = &principals[i];
        let repo_scoped = p.repos.len() != 0;
        if p.is_group {
            narrowed.push(Audit::GroupFlattened { group: p.name, verb: p.verb, members: p.members.len() });
            users = contribute_group(&users, p);
            oidc = add_oidc(oidc, p.name, &p.repos, p.verb);
        } else {
            users = contribute(&users, p.name, p.verb, repo_scoped, false);
        }
        i += 1;
    }
    Collected { users, narrowed, oidc }
}
pub fn record_admin(mut events: Vec<Audit>, acc: Acc) -> Vec<Audit> {
    if acc.verb == Verb::Admin { events.push(Audit::AdminNarrowed { user: acc.user }); }
    events
}
pub fn record_scope(mut events: Vec<Audit>, acc: Acc, mapped: Verb) -> Vec<Audit> {
    if acc.repo_scoped { events.push(Audit::ScopeWidened { user: acc.user, role: mapped }); }
    events
}
pub fn record_withheld(mut events: Vec<Audit>, acc: Acc, mapped: Verb, grant_write: bool) -> Vec<Audit> {
    if mapped != Verb::Read && !grant_write {
        events.push(Audit::WriteWithheld { user: acc.user, role: mapped });
    }
    events
}
pub fn emit(collected: Collected, grant_write: bool) -> Report {
    let users = collected.users;
    let mut narrowed = collected.narrowed;
    let oidc = collected.oidc;
    let mut widened = Vec::new();
    let mut proposed_tokens = Vec::new();
    let mut warn_global_write = false;
    let mut k = 0;
    while k < users.len() {
        let acc = users[k];
        let mapped = narrow_admin(acc.verb);
        narrowed = record_admin(narrowed, acc);
        widened = record_scope(widened, acc, mapped);
        widened = record_withheld(widened, acc, mapped, grant_write);
        let role = token_role(acc.verb, grant_write);
        warn_global_write = warn_global_write || role != Verb::Read;
        proposed_tokens.push(TokenProposal { user: acc.user, role, from_group: acc.from_group });
        k += 1;
    }
    let warn_oidc = oidc.len() != 0;
    Report { proposed_tokens, oidc, narrowed, widened, warn_oidc, warn_global_write }
}

pub fn map_to_proposal(principals: &[Principal], grant_write: bool) -> Report {
    emit(collect(principals), grant_write)
}
