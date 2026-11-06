//! `src/controllers/helpers/authorization.rs`: `Rights::get`, the strongest
//! rights a user has on a crate given its owners.
//!
//! The GitHub team-membership API is an input: one answer per team. The
//! user's GitHub token is decrypted first; a decryption failure is an error.

/// A crate owner (`Owner`).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Owner {
    User(i32),
    /// A GitHub team, by its `(org_id, github_id)` key.
    Team(i64),
}

/// GitHub's answer to `team_membership` for this user.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Membership {
    Active,
    /// A membership that is not active (pending invitation).
    Inactive,
    NotMember,
    /// `GitHubError::Forbidden`: the org restricts OAuth access.
    Forbidden,
    /// Any other GitHub error.
    Failed,
}

/// `Rights`, ordered `None < Publish < Full`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Rights {
    None,
    Publish,
    Full,
}

/// `Rights::get`'s errors.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RightsError {
    /// The stored GitHub token does not decrypt.
    Decrypt,
    /// `403`: the organization restricts OAuth access.
    OrgRestricted,
    /// Another GitHub API error.
    GitHub,
}

/// The user asking.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Actor {
    pub id: i32,
    /// `gh_encrypted_token`: `None` without one, `Some(ok)` with one, `ok`
    /// telling whether it decrypts.
    pub gh_token: Option<bool>,
    /// `gh_login.is_some()`.
    pub gh_login: bool,
}

/// The membership answer for a team (no answer: not a member).
pub fn membership_of(answers: &[(i64, Membership)], team: i64) -> Membership {
    let mut i = 0;
    while i < answers.len() {
        if answers[i].0 == team {
            return answers[i].1;
        }
        i += 1;
    }
    Membership::NotMember
}

/// `Rights::rank`: `None < Publish < Full`.
pub fn rank(r: Rights) -> u8 {
    match r {
        Rights::None => 0,
        Rights::Publish => 1,
        Rights::Full => 2,
    }
}

/// What one owner entry contributes: `0` nothing, `1` publish rights, `2`
/// full rights (stop), `3` org-restricted error (stop), `4` GitHub error
/// (stop). (A code, because the loop below cannot match on an enum with an
/// early return in the subset.)
pub fn owner_step(user: &Actor, has_auth: bool, owner: Owner, answers: &[(i64, Membership)]) -> u8 {
    match owner {
        Owner::User(id) => {
            if id == user.id { 2 } else { 0 }
        }
        Owner::Team(team) => {
            if has_auth && user.gh_login {
                match membership_of(answers, team) {
                    Membership::Active => 1,
                    Membership::Inactive => 0,
                    Membership::NotMember => 0,
                    Membership::Forbidden => 3,
                    Membership::Failed => 4,
                }
            } else {
                0
            }
        }
    }
}

/// The owner loop of `Rights::get`.
pub fn rights_loop(user: &Actor, has_auth: bool, owners: &[Owner], answers: &[(i64, Membership)]) -> Result<Rights, RightsError> {
    let mut best = Rights::None;
    let mut i = 0;
    while i < owners.len() {
        let c = owner_step(user, has_auth, owners[i], answers);
        if c == 2 {
            return Ok(Rights::Full);
        }
        if c == 3 {
            return Err(RightsError::OrgRestricted);
        }
        if c == 4 {
            return Err(RightsError::GitHub);
        }
        if c == 1 {
            best = Rights::Publish;
        }
        i += 1;
    }
    Ok(best)
}

/// `Rights::get`.
pub fn rights(user: &Actor, owners: &[Owner], answers: &[(i64, Membership)]) -> Result<Rights, RightsError> {
    match user.gh_token {
        None => rights_loop(user, false, owners, answers),
        Some(ok) => {
            if ok {
                rights_loop(user, true, owners, answers)
            } else {
                Err(RightsError::Decrypt)
            }
        }
    }
}
