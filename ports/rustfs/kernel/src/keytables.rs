//! All condition-key name tables and server-derived membership from function/key_name.rs.
use crate::{bytes, keynames};
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum KeyFamily {
    S3,
    Jwt,
    Svc,
    Ldap,
    Sts,
    Aws,
}
/// Enum variant counts.
pub fn key_count(family: KeyFamily) -> usize {
    match family {
        KeyFamily::S3 => 26,
        KeyFamily::Jwt => 23,
        KeyFamily::Svc => 1,
        KeyFamily::Ldap => 3,
        KeyFamily::Sts => 1,
        KeyFamily::Aws => 12,
    }
}

/// Canonical IntoStaticStr names, in enum declaration order.
pub fn key_name(family: KeyFamily, index: usize) -> Vec<u8> {
    match family {
        KeyFamily::S3 => s3_name(index),
        KeyFamily::Jwt => jwt_name(index),
        KeyFamily::Svc => svc_name(index),
        KeyFamily::Ldap => ldap_name(index),
        KeyFamily::Sts => sts_name(index),
        KeyFamily::Aws => aws_name(index),
    }
}
fn s3_name(index: usize) -> Vec<u8> {
    match index / 16 {
        0 => s3_name_0(index),
        1 => s3_name_1(index),
        _ => Vec::new(),
    }
}
fn s3_name_0(index: usize) -> Vec<u8> {
    match index {
        0 => b"s3:x-amz-copy-source".to_vec(),
        1 => b"s3:x-amz-server-side-encryption".to_vec(),
        2 => b"s3:x-amz-server-side-encryption-customer-algorithm".to_vec(),
        3 => b"s3:signatureversion".to_vec(),
        4 => b"s3:authType".to_vec(),
        5 => b"s3:signatureAge".to_vec(),
        6 => b"s3:x-amz-content-sha256".to_vec(),
        7 => b"s3:x-amz-acl".to_vec(),
        8 => b"s3:LocationConstraint".to_vec(),
        9 => b"s3:versionid".to_vec(),
        10 => b"s3:object-lock-retain-until-date".to_vec(),
        11 => b"s3:object-lock-legal-hold".to_vec(),
        12 => b"s3:object-lock-mode".to_vec(),
        13 => b"s3:max-keys".to_vec(),
        14 => b"s3:x-amz-metadata-directive".to_vec(),
        15 => b"s3:x-amz-storage-class".to_vec(),
        _ => Vec::new(),
    }
}
fn s3_name_1(index: usize) -> Vec<u8> {
    match index {
        16 => b"s3:prefix".to_vec(),
        17 => b"s3:delimiter".to_vec(),
        18 => b"s3:x-amz-grant-full-control".to_vec(),
        19 => b"s3:x-amz-grant-read".to_vec(),
        20 => b"s3:x-amz-grant-write".to_vec(),
        21 => b"s3:x-amz-grant-read-acp".to_vec(),
        22 => b"s3:x-amz-grant-write-acp".to_vec(),
        23 => b"s3:ExistingObjectTag".to_vec(),
        24 => b"s3:RequestObjectTagKeys".to_vec(),
        25 => b"s3:RequestObjectTag".to_vec(),
        _ => Vec::new(),
    }
}
fn jwt_name(index: usize) -> Vec<u8> {
    match index / 16 {
        0 => jwt_name_0(index),
        1 => jwt_name_1(index),
        _ => Vec::new(),
    }
}
fn jwt_name_0(index: usize) -> Vec<u8> {
    match index {
        0 => b"jwt:sub".to_vec(),
        1 => b"jwt:iss".to_vec(),
        2 => b"jwt:aud".to_vec(),
        3 => b"jwt:jti".to_vec(),
        4 => b"jwt:name".to_vec(),
        5 => b"jwt:upn".to_vec(),
        6 => b"jwt:groups".to_vec(),
        7 => b"jwt:roles".to_vec(),
        8 => b"jwt:given_name".to_vec(),
        9 => b"jwt:family_name".to_vec(),
        10 => b"jwt:middle_name".to_vec(),
        11 => b"jwt:nickname".to_vec(),
        12 => b"jwt:preferred_username".to_vec(),
        13 => b"jwt:profile".to_vec(),
        14 => b"jwt:picture".to_vec(),
        15 => b"jwt:website".to_vec(),
        _ => Vec::new(),
    }
}
fn jwt_name_1(index: usize) -> Vec<u8> {
    match index {
        16 => b"jwt:email".to_vec(),
        17 => b"jwt:gender".to_vec(),
        18 => b"jwt:birthdate".to_vec(),
        19 => b"jwt:phone_number".to_vec(),
        20 => b"jwt:address".to_vec(),
        21 => b"jwt:scope".to_vec(),
        22 => b"jwt:client_id".to_vec(),
        _ => Vec::new(),
    }
}
fn svc_name(index: usize) -> Vec<u8> {
    match index {
        0 => b"svc:DurationSeconds".to_vec(),
        _ => Vec::new(),
    }
}
fn ldap_name(index: usize) -> Vec<u8> {
    match index {
        0 => b"ldap:user".to_vec(),
        1 => b"ldap:username".to_vec(),
        2 => b"ldap:groups".to_vec(),
        _ => Vec::new(),
    }
}
fn sts_name(index: usize) -> Vec<u8> {
    match index {
        0 => b"sts:DurationSeconds".to_vec(),
        _ => Vec::new(),
    }
}
fn aws_name(index: usize) -> Vec<u8> {
    match index {
        0 => b"aws:Referer".to_vec(),
        1 => b"aws:SourceIp".to_vec(),
        2 => b"aws:UserAgent".to_vec(),
        3 => b"aws:SecureTransport".to_vec(),
        4 => b"aws:CurrentTime".to_vec(),
        5 => b"aws:EpochTime".to_vec(),
        6 => b"aws:principaltype".to_vec(),
        7 => b"aws:userid".to_vec(),
        8 => b"aws:username".to_vec(),
        9 => b"aws:groups".to_vec(),
        10 => b"aws:SourceArn".to_vec(),
        11 => b"aws:SourceAccount".to_vec(),
        _ => Vec::new(),
    }
}
/// Canonical-name membership (decoded enum representation).
pub fn contains_name(family: KeyFamily, name: &[u8]) -> bool {
    let mut i = 0;
    while i < key_count(family) {
        if bytes::eq(&key_name(family, i), name) {
            return true;
        }
        i += 1;
    }
    false
}
/// `KeyName::is_server_derived` over canonical names.
pub fn is_server_derived(family: KeyFamily, name: &[u8]) -> bool {
    if !contains_name(family, name) {
        return false;
    }
    family != KeyFamily::S3 || !bytes::starts_with(name, b"s3:x-amz-")
}
/// `KeyName::server_derived_key_names`: retain COMMON_KEYS order and duplicates.
pub fn server_derived_key_names() -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < keynames::COMMON_KEYS_LEN {
        let (name, _) = keynames::common_key(i);
        if !bytes::starts_with(&name, b"x-amz-") {
            out.push(name);
        }
        i += 1;
    }
    out
}
/// `is_server_derived_condition_key`: ASCII case-insensitive lookup of prefix-stripped names.
pub fn is_server_derived_condition_key(name: &[u8]) -> bool {
    let names = server_derived_key_names();
    let lower = bytes::lower(name);
    let mut i = 0;
    while i < names.len() {
        if bytes::eq(&bytes::lower(&names[i]), &lower) {
            return true;
        }
        i += 1;
    }
    false
}
