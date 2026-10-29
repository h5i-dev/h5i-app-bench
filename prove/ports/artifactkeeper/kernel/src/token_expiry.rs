//! Mint-time API-token expiration policy, Artifact Keeper 7c42891.
//! Formatted errors are represented by stable error categories.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Policy {
    pub require_expiration: bool,
    pub min_days: i64,
    pub max_days: i64,
    pub default_days: Option<i64>,
    pub apply_to_service_accounts: bool,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PolicyError {
    Minimum,
    ReversedRange,
    Maximum,
    DefaultRange,
    Required,
    RequestedRange,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct ResolvedExpiry {
    pub expires_in_days: Option<i64>,
    pub policy_applied: bool,
}
pub fn default_policy() -> Policy {
    Policy {
        require_expiration: false,
        min_days: 1,
        max_days: 90,
        default_days: Some(90),
        apply_to_service_accounts: false,
    }
}
pub fn validate(policy: &Policy) -> Result<(), PolicyError> {
    if policy.min_days < 1 {
        return Err(PolicyError::Minimum);
    }
    if policy.max_days < policy.min_days {
        return Err(PolicyError::ReversedRange);
    }
    if policy.max_days > 3650 {
        return Err(PolicyError::Maximum);
    }
    if let Some(days) = policy.default_days {
        if days < policy.min_days || days > policy.max_days {
            return Err(PolicyError::DefaultRange);
        }
    }
    Ok(())
}
/// Validation is a separate configuration operation upstream. Invalid stored
/// defaults therefore pass through here, preserving upstream's exact behavior.
pub fn resolve_expiry(
    policy: &Policy,
    requested_days: Option<i64>,
    is_service_account: bool,
) -> Result<ResolvedExpiry, PolicyError> {
    if !policy.require_expiration || (is_service_account && !policy.apply_to_service_accounts) {
        return Ok(ResolvedExpiry {
            expires_in_days: requested_days,
            policy_applied: false,
        });
    }
    match requested_days {
        None => match policy.default_days {
            Some(days) => Ok(ResolvedExpiry {
                expires_in_days: Some(days),
                policy_applied: true,
            }),
            None => Err(PolicyError::Required),
        },
        Some(days) if days < policy.min_days || days > policy.max_days => {
            Err(PolicyError::RequestedRange)
        }
        Some(days) => Ok(ResolvedExpiry {
            expires_in_days: Some(days),
            policy_applied: true,
        }),
    }
}
