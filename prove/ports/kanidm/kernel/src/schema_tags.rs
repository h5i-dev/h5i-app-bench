//! Schema syntax/tag discrimination from Kanidm f608c4f.
//! Complex payload validity and ValueSet validity are supplied by the caller;
//! these functions prove the schema dispatch, not those validators.
#[derive(Clone, Copy, Debug)]
pub enum Syntax {
    Utf8String,
    Utf8StringInsensitive,
    Uuid,
    Boolean,
    SyntaxId,
    IndexId,
    ReferenceUuid,
    JsonFilter,
    Credential,
    SecretUtf8String,
    SshKey,
    SecurityPrincipalName,
    Uint32,
    Cid,
    Utf8StringIname,
    NsUniqueId,
    DateTime,
    EmailAddress,
    Url,
    OauthScope,
    OauthScopeMap,
    PrivateBinary,
    IntentToken,
    Passkey,
    AttestedPasskey,
    Session,
    JwsKeyEs256,
    JwsKeyRs256,
    Oauth2Session,
    UiHint,
    TotpSecret,
    ApiToken,
    AuditLogString,
    EcKeyPrivate,
    Image,
    CredentialType,
    WebauthnAttestationCaList,
    OauthClaimMap,
    KeyInternal,
    HexString,
    Certificate,
    ApplicationPassword,
    Json,
    Message,
    Sha256,
    Int64,
    Uint64,
}
pub fn partial_accepts(syntax: Syntax, tag: u16) -> bool {
    match syntax {
            Syntax::Boolean => tag == 0,
            Syntax::SyntaxId => tag == 1,
            Syntax::IndexId => tag == 2,
            Syntax::Uuid => tag == 3,
            Syntax::ReferenceUuid => tag == 4,
            Syntax::Utf8StringInsensitive => tag == 5,
            Syntax::Utf8StringIname => tag == 6,
            Syntax::Utf8String => tag == 7,
            Syntax::JsonFilter => tag == 8,
            Syntax::Credential => tag == 9,
            Syntax::SecretUtf8String => tag == 10,
            Syntax::SshKey => tag == 11,
            Syntax::SecurityPrincipalName => tag == 12,
            Syntax::Uint32 => tag == 13,
            Syntax::Int64 => tag == 14,
            Syntax::Uint64 => tag == 15,
            Syntax::Cid => tag == 16,
            Syntax::NsUniqueId => tag == 17,
            Syntax::DateTime => tag == 18,
            Syntax::EmailAddress => tag == 19,
            Syntax::Url => tag == 20,
            Syntax::OauthScope => tag == 21,
            Syntax::OauthScopeMap => tag == 4,
            Syntax::OauthClaimMap => {
                tag == 5
                    || tag == 4
                    || tag == 22
                    || tag == 23
            }
            Syntax::PrivateBinary => tag == 24,
            Syntax::IntentToken => tag == 25,
            Syntax::Passkey => tag == 26,
            Syntax::AttestedPasskey => tag == 27,
            // Allow refer types.
            Syntax::Session => tag == 4,
            Syntax::ApiToken => tag == 4,
            Syntax::Oauth2Session => tag == 4,
            // These are just insensitive string lookups on the hex-ified kid.
            Syntax::JwsKeyEs256 => tag == 5,
            Syntax::JwsKeyRs256 => tag == 5,
            Syntax::UiHint => tag == 28,
            Syntax::EcKeyPrivate => tag == 10,
            // Comparing on the label.
            Syntax::TotpSecret => tag == 7,
            Syntax::AuditLogString => tag == 7,
            Syntax::Image => tag == 7,
            Syntax::CredentialType => tag == 29,

            Syntax::HexString | Syntax::Certificate | Syntax::KeyInternal => {
                tag == 30
            }

            Syntax::WebauthnAttestationCaList => false,
            Syntax::ApplicationPassword => {
                tag == 3 || tag == 4
            }
            Syntax::Sha256 => tag == 31,
            // Syntax::Json => tag == 32,
            // Should not be queried
            Syntax::Json | Syntax::Message => false,
    }
}
pub fn value_accepts(syntax: Syntax, tag: u16, valid: bool) -> bool {
    valid && match syntax {
                Syntax::Boolean => tag == 0,
                Syntax::SyntaxId => tag == 1,
                Syntax::IndexId => tag == 2,
                Syntax::Uuid => tag == 3,
                Syntax::ReferenceUuid => tag == 4,
                Syntax::Utf8StringInsensitive => tag == 5,
                Syntax::Utf8StringIname => tag == 6,
                Syntax::Utf8String => tag == 7,
                Syntax::JsonFilter => tag == 8,
                Syntax::Credential => tag == 9,
                Syntax::SecretUtf8String => tag == 10,
                Syntax::SshKey => tag == 11,
                Syntax::SecurityPrincipalName => tag == 12,
                Syntax::Uint32 => tag == 13,
                Syntax::Int64 => tag == 14,
                Syntax::Uint64 => tag == 15,
                Syntax::Cid => tag == 16,
                Syntax::NsUniqueId => tag == 17,
                Syntax::DateTime => tag == 18,
                Syntax::EmailAddress => tag == 19,
                Syntax::Url => tag == 20,
                Syntax::OauthScope => tag == 21,
                Syntax::OauthScopeMap => tag == 22,
                Syntax::OauthClaimMap => {
                    tag == 23
                        || tag == 24
                }
                Syntax::PrivateBinary => tag == 25,
                Syntax::IntentToken => tag == 26,
                Syntax::Passkey => tag == 27,
                Syntax::AttestedPasskey => tag == 28,
                Syntax::Session => tag == 29,
                Syntax::ApiToken => tag == 30,
                Syntax::Oauth2Session => tag == 31,
                Syntax::JwsKeyEs256 => tag == 32,
                Syntax::JwsKeyRs256 => tag == 33,
                Syntax::UiHint => tag == 34,
                Syntax::TotpSecret => tag == 35,
                Syntax::AuditLogString => tag == 7,
                Syntax::Image => tag == 36,
                Syntax::CredentialType => tag == 37,
                Syntax::WebauthnAttestationCaList => {
                    tag == 38
                }
                Syntax::KeyInternal => tag == 39,
                Syntax::HexString => tag == 40,
                Syntax::Certificate => tag == 41,
                Syntax::ApplicationPassword => tag == 42,
                Syntax::Json => tag == 43,
                Syntax::Sha256 => tag == 44,
                Syntax::EcKeyPrivate => tag == 10,
                Syntax::Message => false,
    }
}
pub fn ava_accepts(multivalue: bool, count: usize, expected_syntax: u16, actual_syntax: u16, valid: bool) -> bool {
    if !multivalue && count > 1 { return false; }
    expected_syntax == actual_syntax && valid
}
