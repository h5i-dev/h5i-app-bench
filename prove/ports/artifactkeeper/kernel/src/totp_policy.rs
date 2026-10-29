//! Artifact Keeper 7c42891: pure TOTP enrollment and activation policy.
//! Text parsing, presentation, and database/environment effects stay outside.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TotpPolicy { Disabled, RequiredForAdmins, RequiredForAll }
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AuthProvider { Local, Ldap, Saml, Oidc, Ci }
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TotpLoginRequirement { NotRequired, ChallengeExisting, EnrollmentRequired }
#[derive(Clone, Copy, Debug)]
pub struct TotpSubject {
    pub auth_provider: AuthProvider,
    pub is_admin: bool,
    pub is_service_account: bool,
    pub totp_enabled: bool,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PolicyActivationRefusal { PinnedByEnvironment, ActorNotEnrolled }

pub fn is_enforcing(policy: TotpPolicy) -> bool {
    !matches!(policy, TotpPolicy::Disabled)
}
pub fn totp_login_requirement(policy: TotpPolicy, subject: TotpSubject) -> TotpLoginRequirement {
    if subject.totp_enabled {
        return TotpLoginRequirement::ChallengeExisting;
    }
    if subject.is_service_account {
        return TotpLoginRequirement::NotRequired;
    }
    if subject.auth_provider != AuthProvider::Local {
        return TotpLoginRequirement::NotRequired;
    }
    match policy {
        TotpPolicy::Disabled => TotpLoginRequirement::NotRequired,
        TotpPolicy::RequiredForAdmins if !subject.is_admin => TotpLoginRequirement::NotRequired,
        TotpPolicy::RequiredForAdmins | TotpPolicy::RequiredForAll => {
            TotpLoginRequirement::EnrollmentRequired
        }
    }
}
pub fn policy_requires_totp(policy: TotpPolicy, subject: TotpSubject) -> bool {
    matches!(
        totp_login_requirement(policy, TotpSubject { totp_enabled: false, ..subject }),
        TotpLoginRequirement::EnrollmentRequired
    )
}
pub fn strictness(policy: TotpPolicy) -> u8 {
    match policy {
        TotpPolicy::Disabled => 0,
        TotpPolicy::RequiredForAdmins => 1,
        TotpPolicy::RequiredForAll => 2,
    }
}
pub fn is_tightening(current: TotpPolicy, requested: TotpPolicy) -> bool {
    strictness(requested) > strictness(current)
}
pub fn check_policy_activation(
    current: TotpPolicy,
    requested: TotpPolicy,
    pinned_by_env: bool,
    actor_totp_enabled: bool,
) -> Result<(), PolicyActivationRefusal> {
    if pinned_by_env {
        return Err(PolicyActivationRefusal::PinnedByEnvironment);
    }
    if !is_tightening(current, requested) {
        return Ok(());
    }
    if actor_totp_enabled { Ok(()) } else { Err(PolicyActivationRefusal::ActorNotEnrolled) }
}
