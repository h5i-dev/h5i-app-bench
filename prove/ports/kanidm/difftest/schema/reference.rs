// Generated pinned reference. Regenerate with schema/prepare.py; do not edit.
#![allow(dead_code,unused_variables)]
use std::fmt;
macro_rules! error { ($($t:tt)*) => {} }
macro_rules! trace { ($($t:tt)*) => {} }
macro_rules! admin_error { ($($t:tt)*) => {} }
type Attribute = String;
#[derive(Debug, PartialEq, Eq)]
pub enum SchemaError { InvalidAttributeSyntax(String) }
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
#[derive(Debug)]
pub enum PartialValue {
    Bool(bool),
    Syntax(bool),
    Index(bool),
    Uuid(bool),
    Refer(bool),
    Iutf8(bool),
    Iname(bool),
    Utf8(bool),
    JsonFilt(bool),
    Cred(bool),
    SecretValue,
    SshKey(bool),
    Spn(bool,u8),
    Uint32(bool),
    Int64(bool),
    Uint64(bool),
    Cid(bool),
    Nsuniqueid(bool),
    DateTime(bool),
    EmailAddress(bool),
    Url(bool),
    OauthScope(bool),
    OauthClaimValue(bool,u8,u8),
    OauthClaim(bool,u8),
    PrivateBinary,
    IntentToken(bool),
    Passkey(bool),
    AttestedPasskey(bool),
    UiHint(bool),
    CredentialType(bool),
    HexString(bool),
    Sha256(bool),
    Json,
    PhoneNumber(bool),
    Address(bool),
    PublicBinary(bool),
    RestrictedString(bool),
    Image(bool),
}
#[derive(Debug)]
pub enum Value {
    Bool(bool),
    Syntax(bool),
    Index(bool),
    Uuid(bool),
    Refer(bool),
    Iutf8(bool),
    Iname(bool),
    Utf8(bool),
    JsonFilt(bool),
    Cred(bool,u8),
    SecretValue(bool),
    SshKey(bool,u8),
    Spn(bool,u8),
    Uint32(bool),
    Int64(bool),
    Uint64(bool),
    Cid(bool),
    Nsuniqueid(bool),
    DateTime(bool),
    EmailAddress(bool,u8),
    Url(bool),
    OauthScope(bool),
    OauthScopeMap(bool,u8),
    OauthClaimValue(bool,u8,u8),
    OauthClaimMap(bool,u8),
    PrivateBinary(bool),
    IntentToken(bool,u8),
    Passkey(bool,u8,u8),
    AttestedPasskey(bool,u8,u8),
    Session(bool,u8),
    ApiToken(bool,u8),
    Oauth2Session(bool,u8),
    JwsKeyEs256(bool),
    JwsKeyRs256(bool),
    UiHint(bool),
    TotpSecret(bool,u8),
    Image(bool),
    CredentialType(bool),
    WebauthnAttestationCaList(bool),
    KeyInternal { valid: bool },
    HexString(bool),
    Certificate(bool),
    ApplicationPassword(bool),
    Json(bool),
    Sha256(bool),
    PhoneNumber(bool),
    Address(bool),
    PublicBinary(bool),
    RestrictedString(bool),
    AuditLogString(bool),
}
pub const PARTIAL_TAG_COUNT: usize = 38;
pub const VALUE_TAG_COUNT: usize = 50;
impl Value { fn validate(&self)->bool { match self {
    Self::Bool(valid) => *valid,
    Self::Syntax(valid) => *valid,
    Self::Index(valid) => *valid,
    Self::Uuid(valid) => *valid,
    Self::Refer(valid) => *valid,
    Self::Iutf8(valid) => *valid,
    Self::Iname(valid) => *valid,
    Self::Utf8(valid) => *valid,
    Self::JsonFilt(valid) => *valid,
    Self::Cred(valid,_) => *valid,
    Self::SecretValue(valid) => *valid,
    Self::SshKey(valid,_) => *valid,
    Self::Spn(valid,_) => *valid,
    Self::Uint32(valid) => *valid,
    Self::Int64(valid) => *valid,
    Self::Uint64(valid) => *valid,
    Self::Cid(valid) => *valid,
    Self::Nsuniqueid(valid) => *valid,
    Self::DateTime(valid) => *valid,
    Self::EmailAddress(valid,_) => *valid,
    Self::Url(valid) => *valid,
    Self::OauthScope(valid) => *valid,
    Self::OauthScopeMap(valid,_) => *valid,
    Self::OauthClaimValue(valid,_,_) => *valid,
    Self::OauthClaimMap(valid,_) => *valid,
    Self::PrivateBinary(valid) => *valid,
    Self::IntentToken(valid,_) => *valid,
    Self::Passkey(valid,_,_) => *valid,
    Self::AttestedPasskey(valid,_,_) => *valid,
    Self::Session(valid,_) => *valid,
    Self::ApiToken(valid,_) => *valid,
    Self::Oauth2Session(valid,_) => *valid,
    Self::JwsKeyEs256(valid) => *valid,
    Self::JwsKeyRs256(valid) => *valid,
    Self::UiHint(valid) => *valid,
    Self::TotpSecret(valid,_) => *valid,
    Self::Image(valid) => *valid,
    Self::CredentialType(valid) => *valid,
    Self::WebauthnAttestationCaList(valid) => *valid,
    Self::KeyInternal { valid } => *valid,
    Self::HexString(valid) => *valid,
    Self::Certificate(valid) => *valid,
    Self::ApplicationPassword(valid) => *valid,
    Self::Json(valid) => *valid,
    Self::Sha256(valid) => *valid,
    Self::PhoneNumber(valid) => *valid,
    Self::Address(valid) => *valid,
    Self::PublicBinary(valid) => *valid,
    Self::RestrictedString(valid) => *valid,
    Self::AuditLogString(valid) => *valid,
}}}
pub struct ValueSet { pub syntax: SyntaxType, pub count: usize, pub valid: bool }
impl ValueSet { fn len(&self)->usize {self.count} fn syntax(&self)->SyntaxType {self.syntax}
fn validate(&self,_:&SchemaAttribute)->bool {self.valid} }
#[derive(Debug)]
pub struct SchemaAttribute {pub syntax: SyntaxType,pub multivalue: bool,pub name: String}
impl SchemaAttribute {
    pub fn validate_partialvalue(
        &self,
        a: &Attribute,
        v: &PartialValue,
    ) -> Result<(), SchemaError> {
        let r = match self.syntax {
            SyntaxType::Boolean => matches!(v, PartialValue::Bool(_)),
            SyntaxType::SyntaxId => matches!(v, PartialValue::Syntax(_)),
            SyntaxType::IndexId => matches!(v, PartialValue::Index(_)),
            SyntaxType::Uuid => matches!(v, PartialValue::Uuid(_)),
            SyntaxType::ReferenceUuid => matches!(v, PartialValue::Refer(_)),
            SyntaxType::Utf8StringInsensitive => matches!(v, PartialValue::Iutf8(_)),
            SyntaxType::Utf8StringIname => matches!(v, PartialValue::Iname(_)),
            SyntaxType::Utf8String => matches!(v, PartialValue::Utf8(_)),
            SyntaxType::JsonFilter => matches!(v, PartialValue::JsonFilt(_)),
            SyntaxType::Credential => matches!(v, PartialValue::Cred(_)),
            SyntaxType::SecretUtf8String => matches!(v, PartialValue::SecretValue),
            SyntaxType::SshKey => matches!(v, PartialValue::SshKey(_)),
            SyntaxType::SecurityPrincipalName => matches!(v, PartialValue::Spn(_, _)),
            SyntaxType::Uint32 => matches!(v, PartialValue::Uint32(_)),
            SyntaxType::Int64 => matches!(v, PartialValue::Int64(_)),
            SyntaxType::Uint64 => matches!(v, PartialValue::Uint64(_)),
            SyntaxType::Cid => matches!(v, PartialValue::Cid(_)),
            SyntaxType::NsUniqueId => matches!(v, PartialValue::Nsuniqueid(_)),
            SyntaxType::DateTime => matches!(v, PartialValue::DateTime(_)),
            SyntaxType::EmailAddress => matches!(v, PartialValue::EmailAddress(_)),
            SyntaxType::Url => matches!(v, PartialValue::Url(_)),
            SyntaxType::OauthScope => matches!(v, PartialValue::OauthScope(_)),
            SyntaxType::OauthScopeMap => matches!(v, PartialValue::Refer(_)),
            SyntaxType::OauthClaimMap => {
                matches!(v, PartialValue::Iutf8(_))
                    || matches!(v, PartialValue::Refer(_))
                    || matches!(v, PartialValue::OauthClaimValue(_, _, _))
                    || matches!(v, PartialValue::OauthClaim(_, _))
            }
            SyntaxType::PrivateBinary => matches!(v, PartialValue::PrivateBinary),
            SyntaxType::IntentToken => matches!(v, PartialValue::IntentToken(_)),
            SyntaxType::Passkey => matches!(v, PartialValue::Passkey(_)),
            SyntaxType::AttestedPasskey => matches!(v, PartialValue::AttestedPasskey(_)),
            // Allow refer types.
            SyntaxType::Session => matches!(v, PartialValue::Refer(_)),
            SyntaxType::ApiToken => matches!(v, PartialValue::Refer(_)),
            SyntaxType::Oauth2Session => matches!(v, PartialValue::Refer(_)),
            // These are just insensitive string lookups on the hex-ified kid.
            SyntaxType::JwsKeyEs256 => matches!(v, PartialValue::Iutf8(_)),
            SyntaxType::JwsKeyRs256 => matches!(v, PartialValue::Iutf8(_)),
            SyntaxType::UiHint => matches!(v, PartialValue::UiHint(_)),
            SyntaxType::EcKeyPrivate => matches!(v, PartialValue::SecretValue),
            // Comparing on the label.
            SyntaxType::TotpSecret => matches!(v, PartialValue::Utf8(_)),
            SyntaxType::AuditLogString => matches!(v, PartialValue::Utf8(_)),
            SyntaxType::Image => matches!(v, PartialValue::Utf8(_)),
            SyntaxType::CredentialType => matches!(v, PartialValue::CredentialType(_)),

            SyntaxType::HexString | SyntaxType::Certificate | SyntaxType::KeyInternal => {
                matches!(v, PartialValue::HexString(_))
            }

            SyntaxType::WebauthnAttestationCaList => false,
            SyntaxType::ApplicationPassword => {
                matches!(v, PartialValue::Uuid(_)) || matches!(v, PartialValue::Refer(_))
            }
            SyntaxType::Sha256 => matches!(v, PartialValue::Sha256(_)),
            // SyntaxType::Json => matches!(v, PartialValue::Json),
            // Should not be queried
            SyntaxType::Json | SyntaxType::Message => false,
        };
        if r {
            Ok(())
        } else {
            error!(
                ?a,
                ?self,
                ?v,
                "validate_partialvalue InvalidAttributeSyntax"
            );
            Err(SchemaError::InvalidAttributeSyntax(a.to_string()))
        }
    }

    pub fn validate_value(&self, a: &Attribute, v: &Value) -> Result<(), SchemaError> {
        let r = v.validate()
            && match self.syntax {
                SyntaxType::Boolean => matches!(v, Value::Bool(_)),
                SyntaxType::SyntaxId => matches!(v, Value::Syntax(_)),
                SyntaxType::IndexId => matches!(v, Value::Index(_)),
                SyntaxType::Uuid => matches!(v, Value::Uuid(_)),
                SyntaxType::ReferenceUuid => matches!(v, Value::Refer(_)),
                SyntaxType::Utf8StringInsensitive => matches!(v, Value::Iutf8(_)),
                SyntaxType::Utf8StringIname => matches!(v, Value::Iname(_)),
                SyntaxType::Utf8String => matches!(v, Value::Utf8(_)),
                SyntaxType::JsonFilter => matches!(v, Value::JsonFilt(_)),
                SyntaxType::Credential => matches!(v, Value::Cred(_, _)),
                SyntaxType::SecretUtf8String => matches!(v, Value::SecretValue(_)),
                SyntaxType::SshKey => matches!(v, Value::SshKey(_, _)),
                SyntaxType::SecurityPrincipalName => matches!(v, Value::Spn(_, _)),
                SyntaxType::Uint32 => matches!(v, Value::Uint32(_)),
                SyntaxType::Int64 => matches!(v, Value::Int64(_)),
                SyntaxType::Uint64 => matches!(v, Value::Uint64(_)),
                SyntaxType::Cid => matches!(v, Value::Cid(_)),
                SyntaxType::NsUniqueId => matches!(v, Value::Nsuniqueid(_)),
                SyntaxType::DateTime => matches!(v, Value::DateTime(_)),
                SyntaxType::EmailAddress => matches!(v, Value::EmailAddress(_, _)),
                SyntaxType::Url => matches!(v, Value::Url(_)),
                SyntaxType::OauthScope => matches!(v, Value::OauthScope(_)),
                SyntaxType::OauthScopeMap => matches!(v, Value::OauthScopeMap(_, _)),
                SyntaxType::OauthClaimMap => {
                    matches!(v, Value::OauthClaimValue(_, _, _))
                        || matches!(v, Value::OauthClaimMap(_, _))
                }
                SyntaxType::PrivateBinary => matches!(v, Value::PrivateBinary(_)),
                SyntaxType::IntentToken => matches!(v, Value::IntentToken(_, _)),
                SyntaxType::Passkey => matches!(v, Value::Passkey(_, _, _)),
                SyntaxType::AttestedPasskey => matches!(v, Value::AttestedPasskey(_, _, _)),
                SyntaxType::Session => matches!(v, Value::Session(_, _)),
                SyntaxType::ApiToken => matches!(v, Value::ApiToken(_, _)),
                SyntaxType::Oauth2Session => matches!(v, Value::Oauth2Session(_, _)),
                SyntaxType::JwsKeyEs256 => matches!(v, Value::JwsKeyEs256(_)),
                SyntaxType::JwsKeyRs256 => matches!(v, Value::JwsKeyRs256(_)),
                SyntaxType::UiHint => matches!(v, Value::UiHint(_)),
                SyntaxType::TotpSecret => matches!(v, Value::TotpSecret(_, _)),
                SyntaxType::AuditLogString => matches!(v, Value::Utf8(_)),
                SyntaxType::Image => matches!(v, Value::Image(_)),
                SyntaxType::CredentialType => matches!(v, Value::CredentialType(_)),
                SyntaxType::WebauthnAttestationCaList => {
                    matches!(v, Value::WebauthnAttestationCaList(_))
                }
                SyntaxType::KeyInternal => matches!(v, Value::KeyInternal { .. }),
                SyntaxType::HexString => matches!(v, Value::HexString(_)),
                SyntaxType::Certificate => matches!(v, Value::Certificate(_)),
                SyntaxType::ApplicationPassword => matches!(v, Value::ApplicationPassword(..)),
                SyntaxType::Json => matches!(v, Value::Json(_)),
                SyntaxType::Sha256 => matches!(v, Value::Sha256(_)),
                SyntaxType::EcKeyPrivate => matches!(v, Value::SecretValue(_)),
                SyntaxType::Message => false,
            };
        if r {
            Ok(())
        } else {
            error!(
                ?a,
                ?self,
                ?v,
                "validate_value failure - InvalidAttributeSyntax"
            );
            Err(SchemaError::InvalidAttributeSyntax(a.to_string()))
        }
    }

    pub fn validate_ava(&self, a: &Attribute, ava: &ValueSet) -> Result<(), SchemaError> {
        trace!("Checking for valid {:?} -> {:?}", self.name, ava);
        // Check multivalue
        if !self.multivalue && ava.len() > 1 {
            // lrequest_error!("Ava len > 1 on single value attribute!");
            admin_error!("Ava len > 1 on single value attribute!");
            return Err(SchemaError::InvalidAttributeSyntax(a.to_string()));
        };
        // If syntax, check the type is correct
        let valid = self.syntax == ava.syntax();
        if valid && ava.validate(self) {
            Ok(())
        } else {
            error!(
                ?a,
                "validate_ava - InvalidAttributeSyntax for {:?}", self.syntax
            );
            Err(SchemaError::InvalidAttributeSyntax(a.to_string()))
        }
    }
}
pub fn syntax(n: usize)->SyntaxType { match n {
0 => SyntaxType::Utf8String,
1 => SyntaxType::Utf8StringInsensitive,
2 => SyntaxType::Uuid,
3 => SyntaxType::Boolean,
4 => SyntaxType::SyntaxId,
5 => SyntaxType::IndexId,
6 => SyntaxType::ReferenceUuid,
7 => SyntaxType::JsonFilter,
8 => SyntaxType::Credential,
9 => SyntaxType::SecretUtf8String,
10 => SyntaxType::SshKey,
11 => SyntaxType::SecurityPrincipalName,
12 => SyntaxType::Uint32,
13 => SyntaxType::Cid,
14 => SyntaxType::Utf8StringIname,
15 => SyntaxType::NsUniqueId,
16 => SyntaxType::DateTime,
17 => SyntaxType::EmailAddress,
18 => SyntaxType::Url,
19 => SyntaxType::OauthScope,
20 => SyntaxType::OauthScopeMap,
21 => SyntaxType::PrivateBinary,
22 => SyntaxType::IntentToken,
23 => SyntaxType::Passkey,
24 => SyntaxType::AttestedPasskey,
25 => SyntaxType::Session,
26 => SyntaxType::JwsKeyEs256,
27 => SyntaxType::JwsKeyRs256,
28 => SyntaxType::Oauth2Session,
29 => SyntaxType::UiHint,
30 => SyntaxType::TotpSecret,
31 => SyntaxType::ApiToken,
32 => SyntaxType::AuditLogString,
33 => SyntaxType::EcKeyPrivate,
34 => SyntaxType::Image,
35 => SyntaxType::CredentialType,
36 => SyntaxType::WebauthnAttestationCaList,
37 => SyntaxType::OauthClaimMap,
38 => SyntaxType::KeyInternal,
39 => SyntaxType::HexString,
40 => SyntaxType::Certificate,
41 => SyntaxType::ApplicationPassword,
42 => SyntaxType::Json,
43 => SyntaxType::Message,
44 => SyntaxType::Sha256,
45 => SyntaxType::Int64,
46 => SyntaxType::Uint64,
_=>panic!() }}
pub fn partial(n:usize,valid:bool)->PartialValue { match n {
0=>PartialValue::Bool(true),
1=>PartialValue::Syntax(true),
2=>PartialValue::Index(true),
3=>PartialValue::Uuid(true),
4=>PartialValue::Refer(true),
5=>PartialValue::Iutf8(true),
6=>PartialValue::Iname(true),
7=>PartialValue::Utf8(true),
8=>PartialValue::JsonFilt(true),
9=>PartialValue::Cred(true),
10=>PartialValue::SecretValue,
11=>PartialValue::SshKey(true),
12=>PartialValue::Spn(true,0),
13=>PartialValue::Uint32(true),
14=>PartialValue::Int64(true),
15=>PartialValue::Uint64(true),
16=>PartialValue::Cid(true),
17=>PartialValue::Nsuniqueid(true),
18=>PartialValue::DateTime(true),
19=>PartialValue::EmailAddress(true),
20=>PartialValue::Url(true),
21=>PartialValue::OauthScope(true),
22=>PartialValue::OauthClaimValue(true,0,0),
23=>PartialValue::OauthClaim(true,0),
24=>PartialValue::PrivateBinary,
25=>PartialValue::IntentToken(true),
26=>PartialValue::Passkey(true),
27=>PartialValue::AttestedPasskey(true),
28=>PartialValue::UiHint(true),
29=>PartialValue::CredentialType(true),
30=>PartialValue::HexString(true),
31=>PartialValue::Sha256(true),
32=>PartialValue::Json,
33=>PartialValue::PhoneNumber(true),
34=>PartialValue::Address(true),
35=>PartialValue::PublicBinary(true),
36=>PartialValue::RestrictedString(true),
37=>PartialValue::Image(true),
_=>panic!() }}
pub fn value(n:usize,valid:bool)->Value { match n {
0=>Value::Bool(valid),
1=>Value::Syntax(valid),
2=>Value::Index(valid),
3=>Value::Uuid(valid),
4=>Value::Refer(valid),
5=>Value::Iutf8(valid),
6=>Value::Iname(valid),
7=>Value::Utf8(valid),
8=>Value::JsonFilt(valid),
9=>Value::Cred(valid,0),
10=>Value::SecretValue(valid),
11=>Value::SshKey(valid,0),
12=>Value::Spn(valid,0),
13=>Value::Uint32(valid),
14=>Value::Int64(valid),
15=>Value::Uint64(valid),
16=>Value::Cid(valid),
17=>Value::Nsuniqueid(valid),
18=>Value::DateTime(valid),
19=>Value::EmailAddress(valid,0),
20=>Value::Url(valid),
21=>Value::OauthScope(valid),
22=>Value::OauthScopeMap(valid,0),
23=>Value::OauthClaimValue(valid,0,0),
24=>Value::OauthClaimMap(valid,0),
25=>Value::PrivateBinary(valid),
26=>Value::IntentToken(valid,0),
27=>Value::Passkey(valid,0,0),
28=>Value::AttestedPasskey(valid,0,0),
29=>Value::Session(valid,0),
30=>Value::ApiToken(valid,0),
31=>Value::Oauth2Session(valid,0),
32=>Value::JwsKeyEs256(valid),
33=>Value::JwsKeyRs256(valid),
34=>Value::UiHint(valid),
35=>Value::TotpSecret(valid,0),
36=>Value::Image(valid),
37=>Value::CredentialType(valid),
38=>Value::WebauthnAttestationCaList(valid),
39=>Value::KeyInternal { valid },
40=>Value::HexString(valid),
41=>Value::Certificate(valid),
42=>Value::ApplicationPassword(valid),
43=>Value::Json(valid),
44=>Value::Sha256(valid),
45=>Value::PhoneNumber(valid),
46=>Value::Address(valid),
47=>Value::PublicBinary(valid),
48=>Value::RestrictedString(valid),
49=>Value::AuditLogString(valid),
_=>panic!() }}
