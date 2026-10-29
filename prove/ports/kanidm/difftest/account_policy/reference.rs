#![allow(dead_code)]
use kanidm_kernel::account_policy::{Policy,Resolved};
const MAXIMUM_AUTH_PRIVILEGE_EXPIRY:u32=3600;
const MAXIMUM_AUTH_SESSION_EXPIRY:u32=u32::MAX;
const PW_MFA_MIN_LENGTH:u32=10;
const PW_MAX_LENGTH_NIST:u32=128;
const PW_SFA_MIN_LENGTH_NIST:u32=15;
struct CredentialType;
#[allow(non_upper_case_globals)]
impl CredentialType {const Any:u16=0;const Mfa:u16=10;}
#[derive(Clone)]
struct AttestationCaList(u64);
impl AttestationCaList {fn intersection(&mut self,b:&Self){self.0 &= b.0}}
pub struct AccountPolicy {
 privilege_expiry:u32,authsession_expiry:u32,pw_min_length:u32,credential_policy:u16,
 webauthn_att_ca_list:Option<AttestationCaList>,limit_search_max_filter_test:Option<u64>,
 limit_search_max_results:Option<u64>,allow_primary_cred_fallback:Option<bool>}
pub struct ResolvedAccountPolicy {
 privilege_expiry:u32,authsession_expiry:u32,pw_min_length:u32,pw_max_length:u32,credential_policy:u16,
 webauthn_att_ca_list:Option<AttestationCaList>,limit_search_max_filter_test:Option<u64>,
 limit_search_max_results:Option<u64>,allow_primary_cred_fallback:Option<bool>}
impl ResolvedAccountPolicy {
    pub(crate) fn fold_from<I>(iter: I) -> Self
    where
        I: Iterator<Item = AccountPolicy>,
    {
        // Start with our maximums
        let mut accumulate = ResolvedAccountPolicy {
            privilege_expiry: MAXIMUM_AUTH_PRIVILEGE_EXPIRY,
            authsession_expiry: MAXIMUM_AUTH_SESSION_EXPIRY,
            pw_min_length: PW_MFA_MIN_LENGTH,
            pw_max_length: PW_MAX_LENGTH_NIST,
            credential_policy: CredentialType::Any,
            webauthn_att_ca_list: None,
            limit_search_max_filter_test: None,
            limit_search_max_results: None,
            allow_primary_cred_fallback: None,
        };

        iter.for_each(|acc_pol| {
            // Take the smaller expiry
            if acc_pol.privilege_expiry < accumulate.privilege_expiry {
                accumulate.privilege_expiry = acc_pol.privilege_expiry
            }

            // Take the smaller expiry
            if acc_pol.authsession_expiry < accumulate.authsession_expiry {
                accumulate.authsession_expiry = acc_pol.authsession_expiry
            }

            // Take larger pw min len
            if acc_pol.pw_min_length > accumulate.pw_min_length {
                accumulate.pw_min_length = acc_pol.pw_min_length
            }

            // Take the greater credential type policy
            if acc_pol.credential_policy > accumulate.credential_policy {
                accumulate.credential_policy = acc_pol.credential_policy
            }

            if let Some(pol_lim) = acc_pol.limit_search_max_results {
                if let Some(acc_lim) = accumulate.limit_search_max_results {
                    if pol_lim > acc_lim {
                        accumulate.limit_search_max_results = Some(pol_lim);
                    }
                } else {
                    accumulate.limit_search_max_results = Some(pol_lim);
                }
            }

            if let Some(pol_lim) = acc_pol.limit_search_max_filter_test {
                if let Some(acc_lim) = accumulate.limit_search_max_filter_test {
                    if pol_lim > acc_lim {
                        accumulate.limit_search_max_filter_test = Some(pol_lim);
                    }
                } else {
                    accumulate.limit_search_max_filter_test = Some(pol_lim);
                }
            }

            if let Some(acc_pol_w_att_ca) = acc_pol.webauthn_att_ca_list {
                if let Some(res_w_att_ca) = accumulate.webauthn_att_ca_list.as_mut() {
                    res_w_att_ca.intersection(&acc_pol_w_att_ca);
                } else {
                    accumulate.webauthn_att_ca_list = Some(acc_pol_w_att_ca);
                }
            }

            if let Some(allow_primary_cred_fallback) = acc_pol.allow_primary_cred_fallback {
                accumulate.allow_primary_cred_fallback =
                    match accumulate.allow_primary_cred_fallback {
                        Some(acc_fallback) => Some(allow_primary_cred_fallback && acc_fallback),
                        None => Some(allow_primary_cred_fallback),
                    };
            }
        });

        // Per NIST, if a password can be used as a single factor authenticator,
        // then we need to set the minimum length to a greater value.
        if accumulate.credential_policy < CredentialType::Mfa
            && accumulate.pw_min_length < PW_SFA_MIN_LENGTH_NIST
        {
            accumulate.pw_min_length = PW_SFA_MIN_LENGTH_NIST;
        }

        accumulate
    }

}
pub fn fold(policies:&[Policy], masks:&[Option<u64>])->Resolved {
 let r=ResolvedAccountPolicy::fold_from(policies.iter().enumerate().map(|(i,p)| AccountPolicy {
 privilege_expiry:p.privilege_expiry,authsession_expiry:p.authsession_expiry,
 pw_min_length:p.pw_min_length,credential_policy:p.credential_policy,
 webauthn_att_ca_list:masks[i].map(AttestationCaList),
 limit_search_max_filter_test:p.limit_search_max_filter_test,limit_search_max_results:p.limit_search_max_results,
 allow_primary_cred_fallback:p.allow_primary_cred_fallback}));
 Resolved {policy: Policy {privilege_expiry:r.privilege_expiry,authsession_expiry:r.authsession_expiry,
 pw_min_length:r.pw_min_length,credential_policy:r.credential_policy,
 limit_search_max_filter_test:r.limit_search_max_filter_test,limit_search_max_results:r.limit_search_max_results,
 allow_primary_cred_fallback:r.allow_primary_cred_fallback},pw_max_length:r.pw_max_length}
}
