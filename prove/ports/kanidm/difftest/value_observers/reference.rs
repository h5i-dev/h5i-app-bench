use super::{Norm,Payload,Text};
pub type String=Text;
pub type str=Text;
pub type Vec<T>=Payload<T>;
pub type BTreeSet<T>=Payload<T>;
pub type Zeroizing<T>=Payload<T>;
pub type Box<T>=Payload<T>;
pub type Uuid=u128;
#[derive(Clone,Copy,Debug)] pub struct Oauth2Session {pub rs_uuid:u128,pub payload:u64}
pub type SyntaxType=u64;
pub type IndexType=u64;
pub type ProtoFilter=u64;
pub type Credential=u64;
pub type SshPublicKey=u64;
pub type Cid=u64;
pub type OffsetDateTime=u64;
pub type Address=u64;
pub type Url=u64;
pub type IntentTokenState=u64;
pub type PasskeyV4=u64;
pub type AttestedPasskeyV4=u64;
pub type Session=u64;
pub type ApiToken=u64;
pub type JwsEs256Signer=u64;
pub type JwsRs256Signer=u64;
pub type UiHint=u64;
pub type Totp=u64;
pub type ImageValue=u64;
pub type CredentialType=u64;
pub type AttestationCaList=u64;
pub type OauthClaimMapJoin=u64;
pub type KeyId=u64;
pub type KeyUsage=u64;
pub type KeyStatus=u64;
pub type JsonValue=u64;
pub type Sha256Output=u64;
pub type ApplicationPassword=u64;
pub type Certificate=u64;
#[derive(Clone,Debug)]
pub enum Value {
    Utf8(String),
    /// Case insensitive string
    Iutf8(String),
    /// Case insensitive Name for a thing
    Iname(String),
    Uuid(Uuid),
    Bool(bool),
    Syntax(SyntaxType),
    Index(IndexType),
    Refer(Uuid),
    JsonFilt(ProtoFilter),
    Cred(String, Credential),
    SshKey(String, SshPublicKey),
    SecretValue(String),
    Spn(String, String),
    Uint32(u32),
    Int64(i64),
    Uint64(u64),
    Cid(Cid),
    Nsuniqueid(String),
    DateTime(OffsetDateTime),
    EmailAddress(String, bool),
    PhoneNumber(String, bool),
    Address(Address),
    Url(Url),
    OauthScope(String),
    OauthScopeMap(Uuid, BTreeSet<String>),
    PrivateBinary(Vec<u8>),
    PublicBinary(String, Vec<u8>),
    RestrictedString(String),
    IntentToken(String, IntentTokenState),
    Passkey(Uuid, String, PasskeyV4),
    AttestedPasskey(Uuid, String, AttestedPasskeyV4),

    Session(Uuid, Session),
    ApiToken(Uuid, ApiToken),
    Oauth2Session(Uuid, Oauth2Session),

    JwsKeyEs256(JwsEs256Signer),
    JwsKeyRs256(JwsRs256Signer),
    UiHint(UiHint),

    TotpSecret(String, Totp),
    AuditLogString(Cid, String),

    Image(ImageValue),
    CredentialType(CredentialType),
    WebauthnAttestationCaList(AttestationCaList),

    OauthClaimValue(String, Uuid, BTreeSet<String>),
    OauthClaimMap(String, OauthClaimMapJoin),

    KeyInternal {
        id: KeyId,
        usage: KeyUsage,
        valid_from: u64,
        status: KeyStatus,
        status_cid: Cid,
        der: Zeroizing<Vec<u8>>,
    },

    HexString(String),

    Certificate(Box<Certificate>),
    ApplicationPassword(ApplicationPassword),
    Json(JsonValue),
    Sha256(Sha256Output),
}
#[derive(Clone,Debug)]
pub enum PartialValue {
    Utf8(String),
    Iutf8(String),
    Iname(String),
    Uuid(Uuid),
    Bool(bool),
    Syntax(SyntaxType),
    Index(IndexType),
    Refer(Uuid),
    // Does this make sense?
    // TODO: We'll probably add tagging to this type for the partial matching
    JsonFilt(ProtoFilter),
    // Tag, matches to a DataValue.
    Cred(String),
    SshKey(String),
    SecretValue,
    Spn(String, String),
    Uint32(u32),
    Cid(Cid),
    Nsuniqueid(String),
    DateTime(OffsetDateTime),
    EmailAddress(String),
    PhoneNumber(String),
    Address(String),
    // Can add other selectors later.
    Url(Url),
    OauthScope(String),
    // OauthScopeMap(Uuid),
    PrivateBinary,
    PublicBinary(String),
    // Enumeration(String),
    // Float64(f64),
    RestrictedString(String),
    IntentToken(String),
    UiHint(UiHint),
    Passkey(Uuid),
    AttestedPasskey(Uuid),
    /// We compare on the value hash
    Image(String),
    CredentialType(CredentialType),

    OauthClaim(String, Uuid),
    OauthClaimValue(String, Uuid, String),

    HexString(String),
    Json,
    Sha256(Sha256Output),
    Int64(i64),
    Uint64(u64),
}
impl Value {
    pub fn is_utf8(&self) -> bool {
        matches!(self, Value::Utf8(_))
    }
    pub fn is_iutf8(&self) -> bool {
        matches!(self, Value::Iutf8(_))
    }
    pub fn is_insensitive_utf8(&self) -> bool {
        matches!(self, Value::Iutf8(_))
    }
    pub fn is_iname(&self) -> bool {
        matches!(self, Value::Iname(_))
    }
    pub fn is_uuid(&self) -> bool {
        matches!(self, Value::Uuid(_))
    }
    pub fn is_bool(&self) -> bool {
        matches!(self, Value::Bool(_))
    }
    pub fn is_syntax(&self) -> bool {
        matches!(self, Value::Syntax(_))
    }
    pub fn is_index(&self) -> bool {
        matches!(self, Value::Index(_))
    }
    pub fn is_refer(&self) -> bool {
        matches!(self, Value::Refer(_))
    }
    pub fn is_json_filter(&self) -> bool {
        matches!(self, Value::JsonFilt(_))
    }
    pub fn is_credential(&self) -> bool {
        matches!(&self, Value::Cred(_, _))
    }
    pub fn is_secret_string(&self) -> bool {
        matches!(&self, Value::SecretValue(_))
    }
    pub fn is_sshkey(&self) -> bool {
        matches!(&self, Value::SshKey(_, _))
    }
    pub fn is_spn(&self) -> bool {
        matches!(&self, Value::Spn(_, _))
    }
    pub fn is_uint32(&self) -> bool {
        matches!(&self, Value::Uint32(_))
    }
    pub fn is_cid(&self) -> bool {
        matches!(&self, Value::Cid(_))
    }
    pub fn is_nsuniqueid(&self) -> bool {
        matches!(&self, Value::Nsuniqueid(_))
    }
    pub fn is_datetime(&self) -> bool {
        matches!(&self, Value::DateTime(_))
    }
    pub fn is_email_address(&self) -> bool {
        matches!(&self, Value::EmailAddress(_, _))
    }
    pub fn is_url(&self) -> bool {
        matches!(&self, Value::Url(_))
    }
    pub fn is_oauthscope(&self) -> bool {
        matches!(&self, Value::OauthScope(_))
    }
    pub fn is_oauthscopemap(&self) -> bool {
        matches!(&self, Value::OauthScopeMap(_, _))
    }
    pub fn is_privatebinary(&self) -> bool {
        matches!(&self, Value::PrivateBinary(_))
    }
    pub fn as_json_filter(&self) -> Option<&ProtoFilter> {
        match &self {
            Value::JsonFilt(f) => Some(f),
            _ => None,
        }
    }
    pub fn to_credential(&self) -> Option<&Credential> {
        match &self {
            Value::Cred(_, cred) => Some(cred),
            _ => None,
        }
    }
    pub fn get_secret_str(&self) -> Option<&str> {
        match &self {
            Value::SecretValue(c) => Some(c.as_str()),
            _ => None,
        }
    }
    pub fn to_privatebinary(&self) -> Option<&Vec<u8>> {
        match &self {
            Value::PrivateBinary(c) => Some(c),
            _ => None,
        }
    }
    pub fn to_str(&self) -> Option<&str> {
        match &self {
            Value::Utf8(s) => Some(s.as_str()),
            Value::Iutf8(s) => Some(s.as_str()),
            Value::Iname(s) => Some(s.as_str()),
            _ => None,
        }
    }
    pub fn to_url(&self) -> Option<&Url> {
        match &self {
            Value::Url(u) => Some(u),
            _ => None,
        }
    }
    pub fn as_string(&self) -> Option<&String> {
        match &self {
            Value::Utf8(s) => Some(s),
            Value::Iutf8(s) => Some(s),
            Value::Iname(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_ref_uuid(&self) -> Option<Uuid> {
        match &self {
            Value::Refer(u) => Some(*u),
            Value::OauthScopeMap(u, _) => Some(*u),
            // We need to assert that our reference to our rs exists.
            Value::Oauth2Session(_, m) => Some(m.rs_uuid),
            _ => None,
        }
    }
    pub fn to_uuid(&self) -> Option<&Uuid> {
        match &self {
            Value::Uuid(u) => Some(u),
            _ => None,
        }
    }
    pub fn to_indextype(&self) -> Option<&IndexType> {
        match &self {
            Value::Index(i) => Some(i),
            _ => None,
        }
    }
    pub fn to_syntaxtype(&self) -> Option<&SyntaxType> {
        match &self {
            Value::Syntax(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_bool(&self) -> Option<bool> {
        match self {
            // *v is to invoke a copy, but this is cheap af
            Value::Bool(v) => Some(*v),
            _ => None,
        }
    }
    pub fn to_uint32(&self) -> Option<u32> {
        match &self {
            Value::Uint32(v) => Some(*v),
            _ => None,
        }
    }
    pub fn to_utf8(self) -> Option<String> {
        match self {
            Value::Utf8(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_iutf8(self) -> Option<String> {
        match self {
            Value::Iutf8(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_iname(self) -> Option<String> {
        match self {
            Value::Iname(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_jsonfilt(self) -> Option<ProtoFilter> {
        match self {
            Value::JsonFilt(f) => Some(f),
            _ => None,
        }
    }
    pub fn to_cred(self) -> Option<(String, Credential)> {
        match self {
            Value::Cred(tag, c) => Some((tag, c)),
            _ => None,
        }
    }
    pub fn to_spn(self) -> Option<(String, String)> {
        match self {
            Value::Spn(n, d) => Some((n, d)),
            _ => None,
        }
    }
    pub fn to_cid(self) -> Option<Cid> {
        match self {
            Value::Cid(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_nsuniqueid(self) -> Option<String> {
        match self {
            Value::Nsuniqueid(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_emailaddress(self) -> Option<String> {
        match self {
            Value::EmailAddress(s, _) => Some(s),
            _ => None,
        }
    }
    pub fn to_oauthscope(self) -> Option<String> {
        match self {
            Value::OauthScope(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_oauthscopemap(self) -> Option<(Uuid, BTreeSet<String>)> {
        match self {
            Value::OauthScopeMap(u, m) => Some((u, m)),
            _ => None,
        }
    }
    pub fn to_restrictedstring(self) -> Option<String> {
        match self {
            Value::RestrictedString(s) => Some(s),
            _ => None,
        }
    }
    pub fn to_phonenumber(self) -> Option<String> {
        match self {
            Value::PhoneNumber(p, _b) => Some(p),
            _ => None,
        }
    }
    pub fn to_publicbinary(self) -> Option<(String, Vec<u8>)> {
        match self {
            Value::PublicBinary(t, d) => Some((t, d)),
            _ => None,
        }
    }
    pub fn to_address(self) -> Option<Address> {
        match self {
            Value::Address(a) => Some(a),
            _ => None,
        }
    }
    pub fn to_intenttoken(self) -> Option<(String, IntentTokenState)> {
        match self {
            Value::IntentToken(u, s) => Some((u, s)),
            _ => None,
        }
    }
    pub fn to_session(self) -> Option<(Uuid, Session)> {
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
    pub fn is_utf8(&self) -> bool {
        matches!(self, PartialValue::Utf8(_))
    }
    pub fn is_iutf8(&self) -> bool {
        matches!(self, PartialValue::Iutf8(_))
    }
    pub fn is_iname(&self) -> bool {
        matches!(self, PartialValue::Iname(_))
    }
    pub fn is_bool(&self) -> bool {
        matches!(self, PartialValue::Bool(_))
    }
    pub fn is_uuid(&self) -> bool {
        matches!(self, PartialValue::Uuid(_))
    }
    pub fn is_refer(&self) -> bool {
        matches!(self, PartialValue::Refer(_))
    }
    pub fn is_index(&self) -> bool {
        matches!(self, PartialValue::Index(_))
    }
    pub fn is_syntax(&self) -> bool {
        matches!(self, PartialValue::Syntax(_))
    }
    pub fn is_json_filter(&self) -> bool {
        matches!(self, PartialValue::JsonFilt(_))
    }
    pub fn is_credential(&self) -> bool {
        matches!(self, PartialValue::Cred(_))
    }
    pub fn is_secret_string(&self) -> bool {
        matches!(self, PartialValue::SecretValue)
    }
    pub fn is_sshkey(&self) -> bool {
        matches!(self, PartialValue::SshKey(_))
    }
    pub fn is_spn(&self) -> bool {
        matches!(self, PartialValue::Spn(_, _))
    }
    pub fn is_uint32(&self) -> bool {
        matches!(self, PartialValue::Uint32(_))
    }
    pub fn is_cid(&self) -> bool {
        matches!(self, PartialValue::Cid(_))
    }
    pub fn is_nsuniqueid(&self) -> bool {
        matches!(self, PartialValue::Nsuniqueid(_))
    }
    pub fn is_datetime(&self) -> bool {
        matches!(self, PartialValue::DateTime(_))
    }
    pub fn is_email_address(&self) -> bool {
        matches!(self, PartialValue::EmailAddress(_))
    }
    pub fn is_url(&self) -> bool {
        matches!(self, PartialValue::Url(_))
    }
    pub fn is_oauthscope(&self) -> bool {
        matches!(self, PartialValue::OauthScope(_))
    }
    pub fn is_privatebinary(&self) -> bool {
        matches!(self, PartialValue::PrivateBinary)
    }
    pub fn to_str(&self) -> Option<&str> {
        match self {
            PartialValue::Utf8(s) => Some(s.as_str()),
            PartialValue::Iutf8(s) => Some(s.as_str()),
            PartialValue::Iname(s) => Some(s.as_str()),
            _ => None,
        }
    }
}
