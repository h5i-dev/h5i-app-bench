//! Complete Value/PartialValue variant observers at f608c4f.
//! Strings, byte buffers, sets and external payloads use stable opaque u64
//! handles. UUIDs retain u128 and scalar bool/u32/i64/u64 are exact. The sole
//! inspected external payload, OAuth2Session, retains its rs_uuid separately.
//! Borrowed getters return the same payload handle; ownership/lifetimes are a
//! boundary. Parsers, normalization, cryptography and external type operations
//! are not ported here. This module is separate from access's restricted Value.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Oauth2Session { pub rs_uuid:u128, pub payload:u64 }
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Value {
    Utf8(u64),
    /// Case insensitive string
    Iutf8(u64),
    /// Case insensitive Name for a thing
    Iname(u64),
    Uuid(u128),
    Boolean(bool),
    Syntax(u64),
    Index(u64),
    Refer(u128),
    JsonFilt(u64),
    Cred(u64, u64),
    SshKey(u64, u64),
    SecretValue(u64),
    Spn(u64, u64),
    Uint32(u32),
    Int64(i64),
    Uint64(u64),
    Cid(u64),
    Nsuniqueid(u64),
    DateTime(u64),
    EmailAddress(u64, bool),
    PhoneNumber(u64, bool),
    Address(u64),
    Url(u64),
    OauthScope(u64),
    OauthScopeMap(u128, u64),
    PrivateBinary(u64),
    PublicBinary(u64, u64),
    RestrictedString(u64),
    IntentToken(u64, u64),
    Passkey(u128, u64, u64),
    AttestedPasskey(u128, u64, u64),

    Session(u128, u64),
    ApiToken(u128, u64),
    Oauth2Session(u128, Oauth2Session),

    JwsKeyEs256(u64),
    JwsKeyRs256(u64),
    UiHint(u64),

    TotpSecret(u64, u64),
    AuditLogString(u64, u64),

    Image(u64),
    CredentialType(u64),
    WebauthnAttestationCaList(u64),

    OauthClaimValue(u64, u128, u64),
    OauthClaimMap(u64, u64),

    KeyInternal {
        id: u64,
        usage: u64,
        valid_from: u64,
        status: u64,
        status_cid: u64,
        der: u64,
    },

    HexString(u64),

    Certificate(u64),
    ApplicationPassword(u64),
    Json(u64),
    Sha256(u64),
}
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum PartialValue {
    Utf8(u64),
    Iutf8(u64),
    Iname(u64),
    Uuid(u128),
    Boolean(bool),
    Syntax(u64),
    Index(u64),
    Refer(u128),
    // Does this make sense?
    // TODO: We'll probably add tagging to this type for the partial matching
    JsonFilt(u64),
    // Tag, matches to a DataValue.
    Cred(u64),
    SshKey(u64),
    SecretValue,
    Spn(u64, u64),
    Uint32(u32),
    Cid(u64),
    Nsuniqueid(u64),
    DateTime(u64),
    EmailAddress(u64),
    PhoneNumber(u64),
    Address(u64),
    // Can add other selectors later.
    Url(u64),
    OauthScope(u64),
    // OauthScopeMap(u128),
    PrivateBinary,
    PublicBinary(u64),
    // Enumeration(u64),
    // Float64(f64),
    RestrictedString(u64),
    IntentToken(u64),
    UiHint(u64),
    Passkey(u128),
    AttestedPasskey(u128),
    /// We compare on the value hash
    Image(u64),
    CredentialType(u64),

    OauthClaim(u64, u128),
    OauthClaimValue(u64, u128, u64),

    HexString(u64),
    Json,
    Sha256(u64),
    Int64(i64),
    Uint64(u64),
}
impl Value {
    pub fn is_utf8(self) -> bool {
        matches!(self, Value::Utf8(_))
    }
    pub fn is_iutf8(self) -> bool {
        matches!(self, Value::Iutf8(_))
    }
    pub fn is_insensitive_utf8(self) -> bool {
        matches!(self, Value::Iutf8(_))
    }
    pub fn is_iname(self) -> bool {
        matches!(self, Value::Iname(_))
    }
    pub fn is_uuid(self) -> bool {
        matches!(self, Value::Uuid(_))
    }
    pub fn is_bool(self) -> bool {
        matches!(self, Value::Boolean(_))
    }
    pub fn is_syntax(self) -> bool {
        matches!(self, Value::Syntax(_))
    }
    pub fn is_index(self) -> bool {
        matches!(self, Value::Index(_))
    }
    pub fn is_refer(self) -> bool {
        matches!(self, Value::Refer(_))
    }
    pub fn is_json_filter(self) -> bool {
        matches!(self, Value::JsonFilt(_))
    }
    pub fn is_credential(self) -> bool {
        matches!(self, Value::Cred(_, _))
    }
    pub fn is_secret_string(self) -> bool {
        matches!(self, Value::SecretValue(_))
    }
    pub fn is_sshkey(self) -> bool {
        matches!(self, Value::SshKey(_, _))
    }
    pub fn is_spn(self) -> bool {
        matches!(self, Value::Spn(_, _))
    }
    pub fn is_uint32(self) -> bool {
        matches!(self, Value::Uint32(_))
    }
    pub fn is_cid(self) -> bool {
        matches!(self, Value::Cid(_))
    }
    pub fn is_nsuniqueid(self) -> bool {
        matches!(self, Value::Nsuniqueid(_))
    }
    pub fn is_datetime(self) -> bool {
        matches!(self, Value::DateTime(_))
    }
    pub fn is_email_address(self) -> bool {
        matches!(self, Value::EmailAddress(_, _))
    }
    pub fn is_url(self) -> bool {
        matches!(self, Value::Url(_))
    }
    pub fn is_oauthscope(self) -> bool {
        matches!(self, Value::OauthScope(_))
    }
    pub fn is_oauthscopemap(self) -> bool {
        matches!(self, Value::OauthScopeMap(_, _))
    }
    pub fn is_privatebinary(self) -> bool {
        matches!(self, Value::PrivateBinary(_))
    }
    pub fn as_json_filter(self) -> Option<u64> {
        match self {
            Value::JsonFilt(f) => Some(f),
            _ => None,
        }
    }
    pub fn to_credential(self) -> Option<u64> {
        match self {
            Value::Cred(_, cred) => Some(cred),
            _ => None,
        }
    }
    pub fn get_secret_str(self) -> Option<u64> {
        match self {
            Value::SecretValue(c) => Some(c),
            _ => None,
        }
    }
    pub fn to_privatebinary(self) -> Option<u64> {
        match self {
            Value::PrivateBinary(c) => Some(c),
            _ => None,
        }
    }
    pub fn to_str(self) -> Option<u64> {
        match self {
            Value::Utf8(s) => Some(s),
            Value::Iutf8(s) => Some(s),
            Value::Iname(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_url(self) -> Option<u64> {
        match self {
            Value::Url(u) => Some(u),
            _ => None,
        }
    }
    pub fn as_string(self) -> Option<u64> {
        match self {
            Value::Utf8(s) => Some(s),
            Value::Iutf8(s) => Some(s),
            Value::Iname(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_ref_uuid(self) -> Option<u128> {
        match self {
            Value::Refer(u) => Some(u),
            Value::OauthScopeMap(u, _) => Some(u),
            
            Value::Oauth2Session(_, m) => Some(m.rs_uuid),
            _ => None,
        }
    }
    pub fn to_uuid(self) -> Option<u128> {
        match self {
            Value::Uuid(u) => Some(u),
            _ => None,
        }
    }
    pub fn to_indextype(self) -> Option<u64> {
        match self {
            Value::Index(i) => Some(i),
            _ => None,
        }
    }
    pub fn to_syntaxtype(self) -> Option<u64> {
        match self {
            Value::Syntax(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_bool(self) -> Option<bool> {
        match self {
            
            Value::Boolean(v) => Some(v),
            _ => None,
        }
    }
    pub fn to_uint32(self) -> Option<u32> {
        match self {
            Value::Uint32(v) => Some(v),
            _ => None,
        }
    }
    pub fn to_utf8(self) -> Option<u64> {
        match self {
            Value::Utf8(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_iutf8(self) -> Option<u64> {
        match self {
            Value::Iutf8(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_iname(self) -> Option<u64> {
        match self {
            Value::Iname(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_jsonfilt(self) -> Option<u64> {
        match self {
            Value::JsonFilt(f) => Some(f),
            _ => None,
        }
    }
    pub fn to_cred(self) -> Option<(u64, u64)> {
        match self {
            Value::Cred(tag, c) => Some((tag, c)),
            _ => None,
        }
    }
    pub fn to_spn(self) -> Option<(u64, u64)> {
        match self {
            Value::Spn(n, d) => Some((n, d)),
            _ => None,
        }
    }
    pub fn to_cid(self) -> Option<u64> {
        match self {
            Value::Cid(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_nsuniqueid(self) -> Option<u64> {
        match self {
            Value::Nsuniqueid(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_emailaddress(self) -> Option<u64> {
        match self {
            Value::EmailAddress(s, _) => Some(s),
            _ => None,
        }
    }
    pub fn to_oauthscope(self) -> Option<u64> {
        match self {
            Value::OauthScope(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_oauthscopemap(self) -> Option<(u128, u64)> {
        match self {
            Value::OauthScopeMap(u, m) => Some((u, m)),
            _ => None,
        }
    }
    pub fn to_restrictedstring(self) -> Option<u64> {
        match self {
            Value::RestrictedString(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_phonenumber(self) -> Option<u64> {
        match self {
            Value::PhoneNumber(p, _b) => Some(p),
            _ => None,
        }
    }
    pub fn to_publicbinary(self) -> Option<(u64, u64)> {
        match self {
            Value::PublicBinary(t, d) => Some((t, d)),
            _ => None,
        }
    }
    pub fn to_address(self) -> Option<u64> {
        match self {
            Value::Address(a) => Some(a),
            _ => None,
        }
    }
    pub fn to_intenttoken(self) -> Option<(u64, u64)> {
        match self {
            Value::IntentToken(u, s) => Some((u, s)),
            _ => None,
        }
    }
    pub fn to_session(self) -> Option<(u128, u64)> {
        match self {
            Value::Session(u, s) => Some((u, s)),
            _ => None,
        }
    }
    pub fn migrate_iutf8_iname(self) -> Option<Self> {
        match self {
            Value::Iutf8(v) => Some(Value::Iname(v)),
            _ => None,
        }
    }
}
impl PartialValue {
    pub fn is_utf8(self) -> bool {
        matches!(self, PartialValue::Utf8(_))
    }
    pub fn is_iutf8(self) -> bool {
        matches!(self, PartialValue::Iutf8(_))
    }
    pub fn is_iname(self) -> bool {
        matches!(self, PartialValue::Iname(_))
    }
    pub fn is_bool(self) -> bool {
        matches!(self, PartialValue::Boolean(_))
    }
    pub fn is_uuid(self) -> bool {
        matches!(self, PartialValue::Uuid(_))
    }
    pub fn is_refer(self) -> bool {
        matches!(self, PartialValue::Refer(_))
    }
    pub fn is_index(self) -> bool {
        matches!(self, PartialValue::Index(_))
    }
    pub fn is_syntax(self) -> bool {
        matches!(self, PartialValue::Syntax(_))
    }
    pub fn is_json_filter(self) -> bool {
        matches!(self, PartialValue::JsonFilt(_))
    }
    pub fn is_credential(self) -> bool {
        matches!(self, PartialValue::Cred(_))
    }
    pub fn is_secret_string(self) -> bool {
        matches!(self, PartialValue::SecretValue)
    }
    pub fn is_sshkey(self) -> bool {
        matches!(self, PartialValue::SshKey(_))
    }
    pub fn is_spn(self) -> bool {
        matches!(self, PartialValue::Spn(_, _))
    }
    pub fn is_uint32(self) -> bool {
        matches!(self, PartialValue::Uint32(_))
    }
    pub fn is_cid(self) -> bool {
        matches!(self, PartialValue::Cid(_))
    }
    pub fn is_nsuniqueid(self) -> bool {
        matches!(self, PartialValue::Nsuniqueid(_))
    }
    pub fn is_datetime(self) -> bool {
        matches!(self, PartialValue::DateTime(_))
    }
    pub fn is_email_address(self) -> bool {
        matches!(self, PartialValue::EmailAddress(_))
    }
    pub fn is_url(self) -> bool {
        matches!(self, PartialValue::Url(_))
    }
    pub fn is_oauthscope(self) -> bool {
        matches!(self, PartialValue::OauthScope(_))
    }
    pub fn is_privatebinary(self) -> bool {
        matches!(self, PartialValue::PrivateBinary)
    }
    pub fn to_str(self) -> Option<u64> {
        match self {
            PartialValue::Utf8(s) => Some(s),
            PartialValue::Iutf8(s) => Some(s),
            PartialValue::Iname(s) => Some(s),
            _ => None,
        }
    }
}
