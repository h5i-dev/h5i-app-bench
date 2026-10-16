//! What the kernel does not compute: credential verification by
//! `AuthService`, base64 decoding and `IpAddr` parsing. Each is a table the
//! shell fills from the real functions; the theorems hold for every table.
use crate::strs::bytes_eq;
use crate::net::IpAddr;
use crate::{AccessScope, Claims, User};

/// How an `AuthService` call failed, as far as the callers distinguish:
/// `AppError::ServiceUnavailable`, a pool timeout (`is_pool_timeout`), or
/// anything else.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AuthErr {
    ServiceUnavailable,
    PoolTimeout,
    Other,
}

/// `auth_service.rs` `ApiTokenValidation`, the fields read here.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ApiTokenValidation {
    pub user: User,
    pub scopes: Vec<Vec<u8>>,
    pub allowed_repo_ids: AccessScope,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Oracle {
    /// `validate_access_token_async(token)` succeeds with these claims;
    /// any other token fails.
    pub jwt: Vec<(Vec<u8>, Claims)>,
    /// `validate_api_token(token)`; an absent token fails with `Other`.
    pub api_tokens: Vec<(Vec<u8>, Result<ApiTokenValidation, AuthErr>)>,
    /// `authenticate(username, password)`; an absent pair fails with `Other`.
    pub passwords: Vec<(Vec<u8>, Vec<u8>, Result<User, AuthErr>)>,
    /// `STANDARD.decode(input)`, `None` on a decoding error or when absent.
    pub base64: Vec<(Vec<u8>, Option<Vec<u8>>)>,
    /// `s.parse::<IpAddr>()` succeeds; absent strings do not parse.
    pub ip: Vec<(Vec<u8>, IpAddr)>,
}

impl Oracle {
    pub fn validate_access_token(&self, token: &[u8]) -> Option<Claims> {
        let mut i = 0;
        while i < self.jwt.len() {
            if bytes_eq(&self.jwt[i].0, token) {
                return Some(self.jwt[i].1.duplicate());
            }
            i += 1;
        }
        None
    }

    pub fn validate_api_token(&self, token: &[u8]) -> Result<ApiTokenValidation, AuthErr> {
        let mut i = 0;
        while i < self.api_tokens.len() {
            if bytes_eq(&self.api_tokens[i].0, token) {
                return match &self.api_tokens[i].1 {
                    Ok(v) => Ok(v.clone()),
                    Err(e) => Err(*e),
                };
            }
            i += 1;
        }
        Err(AuthErr::Other)
    }

    pub fn authenticate(&self, username: &[u8], password: &[u8]) -> Result<User, AuthErr> {
        let mut i = 0;
        while i < self.passwords.len() {
            if bytes_eq(&self.passwords[i].0, username) && bytes_eq(&self.passwords[i].1, password) {
                return match &self.passwords[i].2 {
                    Ok(u) => Ok(u.clone()),
                    Err(e) => Err(*e),
                };
            }
            i += 1;
        }
        Err(AuthErr::Other)
    }

    pub fn base64_decode(&self, input: &[u8]) -> Option<Vec<u8>> {
        let mut i = 0;
        while i < self.base64.len() {
            if bytes_eq(&self.base64[i].0, input) {
                return match &self.base64[i].1 {
                    Some(d) => Some(d.clone()),
                    None => None,
                };
            }
            i += 1;
        }
        None
    }

    pub fn parse_ip(&self, s: &[u8]) -> Option<IpAddr> {
        let mut i = 0;
        while i < self.ip.len() {
            if bytes_eq(&self.ip[i].0, s) {
                return Some(self.ip[i].1);
            }
            i += 1;
        }
        None
    }
}
