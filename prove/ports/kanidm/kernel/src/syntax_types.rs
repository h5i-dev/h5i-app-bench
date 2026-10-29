//! Syntax type metadata at f608c4f. Input to parse_normalized is the
//! UTF-8 result of upstream Unicode to_uppercase(), computed by the caller.
//! This boundary does not replace the exact recognized-name dispatch. Display
//! exposes exact output bytes, with no Formatter failure model; index_types
//! returns the exact ordered list, including empty lists and shared branches.
use crate::bset::bytes_eq;
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum SyntaxType {
    Utf8String = 0,
    Utf8StringInsensitive = 1,
    Uuid = 2,
    Boolean = 3,
    SyntaxId = 4,
    IndexId = 5,
    ReferenceUuid = 6,
    JsonFilter = 7,
    Credential = 8,
    SecretUtf8String = 9,
    SshKey = 10,
    SecurityPrincipalName = 11,
    Uint32 = 12,
    Cid = 13,
    Utf8StringIname = 14,
    NsUniqueId = 15,
    DateTime = 16,
    EmailAddress = 17,
    Url = 18,
    OauthScope = 19,
    OauthScopeMap = 20,
    PrivateBinary = 21,
    IntentToken = 22,
    Passkey = 23,
    AttestedPasskey = 24,
    Session = 25,
    JwsKeyEs256 = 26,
    JwsKeyRs256 = 27,
    Oauth2Session = 28,
    UiHint = 29,
    TotpSecret = 30,
    ApiToken = 31,
    AuditLogString = 32,
    EcKeyPrivate = 33,
    Image = 34,
    CredentialType = 35,
    WebauthnAttestationCaList = 36,
    OauthClaimMap = 37,
    KeyInternal = 38,
    HexString = 39,
    Certificate = 40,
    ApplicationPassword = 41,
    Json = 42,
    Message = 43,
    Sha256 = 44,
    Int64 = 45,
    Uint64 = 46,
}
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum IndexType {
    Equality,
    Presence,
    SubString,
    Ordering,
}
pub fn parse_normalized(name:&[u8])->Option<SyntaxType> {
if bytes_eq(name,b"UTF8STRING") {return Some(SyntaxType::Utf8String);}
if bytes_eq(name,b"UTF8STRING_INSENSITIVE") {return Some(SyntaxType::Utf8StringInsensitive);}
if bytes_eq(name,b"UTF8STRING_INAME") {return Some(SyntaxType::Utf8StringIname);}
if bytes_eq(name,b"UUID") {return Some(SyntaxType::Uuid);}
if bytes_eq(name,b"BOOLEAN") {return Some(SyntaxType::Boolean);}
if bytes_eq(name,b"SYNTAX_ID") {return Some(SyntaxType::SyntaxId);}
if bytes_eq(name,b"INDEX_ID") {return Some(SyntaxType::IndexId);}
if bytes_eq(name,b"REFERENCE_UUID") {return Some(SyntaxType::ReferenceUuid);}
if bytes_eq(name,b"JSON_FILTER") {return Some(SyntaxType::JsonFilter);}
if bytes_eq(name,b"CREDENTIAL") {return Some(SyntaxType::Credential);}
parse_part_1(name)
}
pub fn parse_part_1(name:&[u8])->Option<SyntaxType> {
if bytes_eq(name,b"RADIUS_UTF8STRING") {return Some(SyntaxType::SecretUtf8String);}
if bytes_eq(name,b"SECRET_UTF8STRING") {return Some(SyntaxType::SecretUtf8String);}
if bytes_eq(name,b"SSHKEY") {return Some(SyntaxType::SshKey);}
if bytes_eq(name,b"SECURITY_PRINCIPAL_NAME") {return Some(SyntaxType::SecurityPrincipalName);}
if bytes_eq(name,b"UINT32") {return Some(SyntaxType::Uint32);}
if bytes_eq(name,b"CID") {return Some(SyntaxType::Cid);}
if bytes_eq(name,b"NSUNIQUEID") {return Some(SyntaxType::NsUniqueId);}
if bytes_eq(name,b"DATETIME") {return Some(SyntaxType::DateTime);}
if bytes_eq(name,b"EMAIL_ADDRESS") {return Some(SyntaxType::EmailAddress);}
if bytes_eq(name,b"URL") {return Some(SyntaxType::Url);}
parse_part_2(name)
}
pub fn parse_part_2(name:&[u8])->Option<SyntaxType> {
if bytes_eq(name,b"OAUTH_SCOPE") {return Some(SyntaxType::OauthScope);}
if bytes_eq(name,b"OAUTH_SCOPE_MAP") {return Some(SyntaxType::OauthScopeMap);}
if bytes_eq(name,b"PRIVATE_BINARY") {return Some(SyntaxType::PrivateBinary);}
if bytes_eq(name,b"INTENT_TOKEN") {return Some(SyntaxType::IntentToken);}
if bytes_eq(name,b"PASSKEY") {return Some(SyntaxType::Passkey);}
if bytes_eq(name,b"ATTESTED_PASSKEY") {return Some(SyntaxType::AttestedPasskey);}
if bytes_eq(name,b"SESSION") {return Some(SyntaxType::Session);}
if bytes_eq(name,b"JWS_KEY_ES256") {return Some(SyntaxType::JwsKeyEs256);}
if bytes_eq(name,b"JWS_KEY_RS256") {return Some(SyntaxType::JwsKeyRs256);}
if bytes_eq(name,b"OAUTH2SESSION") {return Some(SyntaxType::Oauth2Session);}
parse_part_3(name)
}
pub fn parse_part_3(name:&[u8])->Option<SyntaxType> {
if bytes_eq(name,b"UIHINT") {return Some(SyntaxType::UiHint);}
if bytes_eq(name,b"TOTPSECRET") {return Some(SyntaxType::TotpSecret);}
if bytes_eq(name,b"APITOKEN") {return Some(SyntaxType::ApiToken);}
if bytes_eq(name,b"AUDIT_LOG_STRING") {return Some(SyntaxType::AuditLogString);}
if bytes_eq(name,b"EC_KEY_PRIVATE") {return Some(SyntaxType::EcKeyPrivate);}
if bytes_eq(name,b"CREDENTIAL_TYPE") {return Some(SyntaxType::CredentialType);}
if bytes_eq(name,b"WEBAUTHN_ATTESTATION_CA_LIST") {return Some(SyntaxType::WebauthnAttestationCaList);}
if bytes_eq(name,b"OAUTH_CLAIM_MAP") {return Some(SyntaxType::OauthClaimMap);}
if bytes_eq(name,b"KEY_INTERNAL") {return Some(SyntaxType::KeyInternal);}
if bytes_eq(name,b"HEX_STRING") {return Some(SyntaxType::HexString);}
parse_part_4(name)
}
pub fn parse_part_4(name:&[u8])->Option<SyntaxType> {
if bytes_eq(name,b"CERTIFICATE") {return Some(SyntaxType::Certificate);}
if bytes_eq(name,b"APPLICATION_PASSWORD") {return Some(SyntaxType::ApplicationPassword);}
if bytes_eq(name,b"JSON") {return Some(SyntaxType::Json);}
if bytes_eq(name,b"MESSAGE") {return Some(SyntaxType::Message);}
if bytes_eq(name,b"SHA256") {return Some(SyntaxType::Sha256);}
if bytes_eq(name,b"INT64") {return Some(SyntaxType::Int64);}
if bytes_eq(name,b"UINT64") {return Some(SyntaxType::Uint64);}
None
}
pub fn display(syntax:SyntaxType)->Vec<u8> {match syntax {
SyntaxType::Utf8String=>b"UTF8STRING".to_vec(),
SyntaxType::Utf8StringInsensitive=>b"UTF8STRING_INSENSITIVE".to_vec(),
SyntaxType::Utf8StringIname=>b"UTF8STRING_INAME".to_vec(),
SyntaxType::Uuid=>b"UUID".to_vec(),
SyntaxType::Boolean=>b"BOOLEAN".to_vec(),
SyntaxType::SyntaxId=>b"SYNTAX_ID".to_vec(),
SyntaxType::IndexId=>b"INDEX_ID".to_vec(),
SyntaxType::ReferenceUuid=>b"REFERENCE_UUID".to_vec(),
SyntaxType::JsonFilter=>b"JSON_FILTER".to_vec(),
SyntaxType::Credential=>b"CREDENTIAL".to_vec(),
SyntaxType::SecretUtf8String=>b"SECRET_UTF8STRING".to_vec(),
SyntaxType::SshKey=>b"SSHKEY".to_vec(),
SyntaxType::SecurityPrincipalName=>b"SECURITY_PRINCIPAL_NAME".to_vec(),
SyntaxType::Uint32=>b"UINT32".to_vec(),
SyntaxType::Cid=>b"CID".to_vec(),
SyntaxType::NsUniqueId=>b"NSUNIQUEID".to_vec(),
SyntaxType::DateTime=>b"DATETIME".to_vec(),
SyntaxType::EmailAddress=>b"EMAIL_ADDRESS".to_vec(),
SyntaxType::Url=>b"URL".to_vec(),
SyntaxType::OauthScope=>b"OAUTH_SCOPE".to_vec(),
SyntaxType::OauthScopeMap=>b"OAUTH_SCOPE_MAP".to_vec(),
SyntaxType::PrivateBinary=>b"PRIVATE_BINARY".to_vec(),
SyntaxType::IntentToken=>b"INTENT_TOKEN".to_vec(),
SyntaxType::Passkey=>b"PASSKEY".to_vec(),
SyntaxType::AttestedPasskey=>b"ATTESTED_PASSKEY".to_vec(),
SyntaxType::Session=>b"SESSION".to_vec(),
SyntaxType::JwsKeyEs256=>b"JWS_KEY_ES256".to_vec(),
SyntaxType::JwsKeyRs256=>b"JWS_KEY_RS256".to_vec(),
SyntaxType::Oauth2Session=>b"OAUTH2SESSION".to_vec(),
SyntaxType::UiHint=>b"UIHINT".to_vec(),
SyntaxType::TotpSecret=>b"TOTPSECRET".to_vec(),
SyntaxType::ApiToken=>b"APITOKEN".to_vec(),
SyntaxType::AuditLogString=>b"AUDIT_LOG_STRING".to_vec(),
SyntaxType::EcKeyPrivate=>b"EC_KEY_PRIVATE".to_vec(),
SyntaxType::Image=>b"IMAGE".to_vec(),
SyntaxType::CredentialType=>b"CREDENTIAL_TYPE".to_vec(),
SyntaxType::WebauthnAttestationCaList=>b"WEBAUTHN_ATTESTATION_CA_LIST".to_vec(),
SyntaxType::OauthClaimMap=>b"OAUTH_CLAIM_MAP".to_vec(),
SyntaxType::KeyInternal=>b"KEY_INTERNAL".to_vec(),
SyntaxType::HexString=>b"HEX_STRING".to_vec(),
SyntaxType::Certificate=>b"CERTIFICATE".to_vec(),
SyntaxType::ApplicationPassword=>b"APPLICATION_PASSWORD".to_vec(),
SyntaxType::Json=>b"JSON".to_vec(),
SyntaxType::Message=>b"MESSAGE".to_vec(),
SyntaxType::Sha256=>b"SHA256".to_vec(),
SyntaxType::Int64=>b"INT64".to_vec(),
SyntaxType::Uint64=>b"UINT64".to_vec(),
}}
    pub fn index_types(syntax:SyntaxType) -> Vec<IndexType> {
        match syntax {
            SyntaxType::Utf8String => { let mut out = Vec::new(); out.push(IndexType::Equality); out.push(IndexType::Presence); out },
            // Used by classes, needs to change ...
            // Probably need an attrname syntax too
            SyntaxType::Utf8StringInsensitive => { let mut out = Vec::new(); out.push(IndexType::Equality); out.push(IndexType::Presence); out },
            SyntaxType::Utf8StringIname => { let mut out = Vec::new(); out.push(IndexType::Equality); out.push(IndexType::Presence); out.push(IndexType::SubString); out },
            SyntaxType::Uuid => { let mut out = Vec::new(); out.push(IndexType::Equality); out.push(IndexType::Presence); out },
            SyntaxType::Boolean => { let mut out = Vec::new(); out.push(IndexType::Equality); out },
            SyntaxType::ReferenceUuid => { let mut out = Vec::new(); out.push(IndexType::Equality); out.push(IndexType::Presence); out },
            SyntaxType::Credential => { let mut out = Vec::new(); out.push(IndexType::Equality); out },
            SyntaxType::SshKey => { let mut out = Vec::new(); out.push(IndexType::Equality); out.push(IndexType::Presence); out },
            SyntaxType::SecurityPrincipalName => { let mut out = Vec::new(); out.push(IndexType::Equality); out.push(IndexType::Presence); out.push(IndexType::SubString); out },
            SyntaxType::Uint32 | SyntaxType::Int64 | SyntaxType::Uint64 => { let mut out = Vec::new(); out.push(IndexType::Equality); out.push(IndexType::Presence); out.push(IndexType::Ordering); out },
            SyntaxType::Cid => { let mut out = Vec::new(); out.push(IndexType::Equality); out.push(IndexType::Presence); out.push(IndexType::Ordering); out },
            SyntaxType::NsUniqueId => { let mut out = Vec::new(); out.push(IndexType::Equality); out.push(IndexType::Presence); out },
            SyntaxType::DateTime => { let mut out = Vec::new(); out.push(IndexType::Equality); out.push(IndexType::Presence); out.push(IndexType::Ordering); out },
            SyntaxType::EmailAddress => { let mut out = Vec::new(); out.push(IndexType::Equality); out.push(IndexType::SubString); out },
            SyntaxType::OauthScopeMap => { let mut out = Vec::new(); out.push(IndexType::Equality); out },
            SyntaxType::IntentToken => { let mut out = Vec::new(); out.push(IndexType::Equality); out },
            SyntaxType::Passkey => { let mut out = Vec::new(); out.push(IndexType::Equality); out },
            SyntaxType::AttestedPasskey => { let mut out = Vec::new(); out.push(IndexType::Equality); out },
            SyntaxType::Session => { let mut out = Vec::new(); out.push(IndexType::Equality); out },
            SyntaxType::Oauth2Session => { let mut out = Vec::new(); out.push(IndexType::Equality); out },
            SyntaxType::ApiToken => { let mut out = Vec::new(); out.push(IndexType::Equality); out },
            SyntaxType::OauthClaimMap => { let mut out = Vec::new(); out.push(IndexType::Equality); out },
            SyntaxType::ApplicationPassword => { let mut out = Vec::new(); out.push(IndexType::Equality); out },
            SyntaxType::SecretUtf8String => Vec::new(),
            SyntaxType::Url => Vec::new(),
            SyntaxType::OauthScope => Vec::new(),
            SyntaxType::PrivateBinary => Vec::new(),
            SyntaxType::JwsKeyEs256 => Vec::new(),
            SyntaxType::JwsKeyRs256 => Vec::new(),
            SyntaxType::UiHint => Vec::new(),
            SyntaxType::TotpSecret => Vec::new(),
            SyntaxType::AuditLogString => Vec::new(),
            SyntaxType::EcKeyPrivate => Vec::new(),
            SyntaxType::Image => Vec::new(),
            SyntaxType::CredentialType => Vec::new(),
            SyntaxType::WebauthnAttestationCaList => Vec::new(),
            SyntaxType::KeyInternal => Vec::new(),
            SyntaxType::HexString => Vec::new(),
            SyntaxType::Certificate => Vec::new(),
            SyntaxType::SyntaxId => Vec::new(),
            SyntaxType::IndexId => Vec::new(),
            SyntaxType::JsonFilter => Vec::new(),
            SyntaxType::Json => Vec::new(),
            SyntaxType::Message => Vec::new(),
            SyntaxType::Sha256 => { let mut out = Vec::new(); out.push(IndexType::Equality); out },
        }
    }