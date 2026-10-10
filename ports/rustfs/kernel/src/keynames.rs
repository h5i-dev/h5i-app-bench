//! `function/key_name.rs` `KeyName::COMMON_KEYS`: each key's `name()` and
//! `var_name()`, as the exact strings upstream's functions return; the
//! difftest compares them entry by entry.

pub const COMMON_KEYS_LEN: usize = 42;

/// `(name(), var_name())` of `COMMON_KEYS[i]`.
pub fn common_key(i: usize) -> (Vec<u8>, Vec<u8>) {
    match i {
        0 => (b"signatureversion".to_vec(), b"${s3:s3:signatureversion}".to_vec()),
        1 => (b"authType".to_vec(), b"${s3:s3:authType}".to_vec()),
        2 => (b"signatureAge".to_vec(), b"${s3:s3:signatureAge}".to_vec()),
        3 => (b"x-amz-content-sha256".to_vec(), b"${s3:s3:x-amz-content-sha256}".to_vec()),
        4 => (b"LocationConstraint".to_vec(), b"${s3:s3:LocationConstraint}".to_vec()),
        5 => (b"versionid".to_vec(), b"${s3:s3:versionid}".to_vec()),
        6 => (b"Referer".to_vec(), b"${aws:aws:Referer}".to_vec()),
        7 => (b"SourceIp".to_vec(), b"${aws:aws:SourceIp}".to_vec()),
        8 => (b"UserAgent".to_vec(), b"${aws:aws:UserAgent}".to_vec()),
        9 => (b"SecureTransport".to_vec(), b"${aws:aws:SecureTransport}".to_vec()),
        10 => (b"CurrentTime".to_vec(), b"${aws:aws:CurrentTime}".to_vec()),
        11 => (b"EpochTime".to_vec(), b"${aws:aws:EpochTime}".to_vec()),
        12 => (b"principaltype".to_vec(), b"${aws:aws:principaltype}".to_vec()),
        13 => (b"userid".to_vec(), b"${aws:aws:userid}".to_vec()),
        14 => (b"username".to_vec(), b"${aws:aws:username}".to_vec()),
        15 => (b"groups".to_vec(), b"${aws:aws:groups}".to_vec()),
        16 => (b"user".to_vec(), b"${ldap:ldap:user}".to_vec()),
        17 => (b"username".to_vec(), b"${ldap:ldap:username}".to_vec()),
        18 => (b"groups".to_vec(), b"${ldap:ldap:groups}".to_vec()),
        19 => (b"sub".to_vec(), b"${jwt:jwt:sub}".to_vec()),
        20 => (b"iss".to_vec(), b"${jwt:jwt:iss}".to_vec()),
        21 => (b"aud".to_vec(), b"${jwt:jwt:aud}".to_vec()),
        22 => (b"jti".to_vec(), b"${jwt:jwt:jti}".to_vec()),
        23 => (b"name".to_vec(), b"${jwt:jwt:name}".to_vec()),
        24 => (b"upn".to_vec(), b"${jwt:jwt:upn}".to_vec()),
        25 => (b"groups".to_vec(), b"${jwt:jwt:groups}".to_vec()),
        26 => (b"roles".to_vec(), b"${jwt:jwt:roles}".to_vec()),
        27 => (b"given_name".to_vec(), b"${jwt:jwt:given_name}".to_vec()),
        28 => (b"family_name".to_vec(), b"${jwt:jwt:family_name}".to_vec()),
        29 => (b"middle_name".to_vec(), b"${jwt:jwt:middle_name}".to_vec()),
        30 => (b"nickname".to_vec(), b"${jwt:jwt:nickname}".to_vec()),
        31 => (b"preferred_username".to_vec(), b"${jwt:jwt:preferred_username}".to_vec()),
        32 => (b"profile".to_vec(), b"${jwt:jwt:profile}".to_vec()),
        33 => (b"picture".to_vec(), b"${jwt:jwt:picture}".to_vec()),
        34 => (b"website".to_vec(), b"${jwt:jwt:website}".to_vec()),
        35 => (b"email".to_vec(), b"${jwt:jwt:email}".to_vec()),
        36 => (b"gender".to_vec(), b"${jwt:jwt:gender}".to_vec()),
        37 => (b"birthdate".to_vec(), b"${jwt:jwt:birthdate}".to_vec()),
        38 => (b"phone_number".to_vec(), b"${jwt:jwt:phone_number}".to_vec()),
        39 => (b"address".to_vec(), b"${jwt:jwt:address}".to_vec()),
        40 => (b"scope".to_vec(), b"${jwt:jwt:scope}".to_vec()),
        41 => (b"client_id".to_vec(), b"${jwt:jwt:client_id}".to_vec()),
        _ => (Vec::new(), Vec::new()),
    }
}
