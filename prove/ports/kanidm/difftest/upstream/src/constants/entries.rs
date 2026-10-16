// Stub head of `constants/entries.rs`: `EntryClass` and its conversions
// below are copied.
use std::fmt::Display;

use crate::value::{PartialValue, Value};
pub use kanidm_proto::attribute::Attribute;
use kanidm_proto::constants::*;

// Copied from kanidm/kanidm @ f608c4f by extract_upstream.py. Do not edit.
#[derive(Copy, Clone, Debug)]
pub enum EntryClass {
    AccessControlCreate,
    AccessControlDelete,
    AccessControlModify,
    AccessControlProfile,
    AccessControlReceiverEntryManager,
    AccessControlReceiverGroup,
    AccessControlSearch,
    AccessControlTargetScope,
    Account,
    AccountPolicy,
    AccountSignupRequest,
    Application,
    AssertionNonce,
    AttributeType,
    Builtin,
    Class,
    ClassType,
    ClientCertificate,
    Conflict,
    DomainInfo,
    DynGroup,
    ExtensibleObject,
    Feature,
    Group,
    KeyProvider,
    KeyProviderInternal,
    KeyObject,
    KeyObjectHkdfS256,
    KeyObjectJwtEs256,
    KeyObjectJwtHs256,
    KeyObjectJwtRs256,
    KeyObjectJweA128GCM,
    KeyObjectJweA256GCM,
    KeyObjectInternal,
    MemberOf,
    Memorial,
    OAuth2Account,
    OAuth2DeviceCodeSession,
    OAuth2ResourceServer,
    OAuth2ResourceServerBasic,
    OAuth2ResourceServerPublic,
    OAuth2Client,
    Object,
    OrgPerson,
    OutboundMessage,
    Person,
    PosixAccount,
    PosixGroup,
    Recycled,
    Service,
    ServiceAccount,
    SyncAccount,
    SyncObject,
    Tombstone,
    User,
    System,
    SystemInfo,
    SystemConfig,
    #[cfg(any(test, debug_assertions))]
    TestClass,
}

impl From<EntryClass> for &'static str {
    fn from(val: EntryClass) -> Self {
        match val {
            EntryClass::AccessControlCreate => ACCESS_CONTROL_CREATE,
            EntryClass::AccessControlDelete => ACCESS_CONTROL_DELETE,
            EntryClass::AccessControlModify => ACCESS_CONTROL_MODIFY,
            EntryClass::AccessControlProfile => ACCESS_CONTROL_PROFILE,
            EntryClass::AccessControlReceiverEntryManager => ACCESS_CONTROL_RECEIVER_ENTRY_MANAGER,
            EntryClass::AccessControlReceiverGroup => ACCESS_CONTROL_RECEIVER_GROUP,
            EntryClass::AccessControlSearch => ACCESS_CONTROL_SEARCH,
            EntryClass::AccessControlTargetScope => ACCESS_CONTROL_TARGET_SCOPE,
            EntryClass::Account => ENTRYCLASS_ACCOUNT,
            EntryClass::AccountPolicy => ENTRYCLASS_ACCOUNT_POLICY,
            EntryClass::AccountSignupRequest => ENTRYCLASS_ACCOUNT_SIGNUP_REQUEST,
            EntryClass::Application => ENTRYCLASS_APPLICATION,
            EntryClass::AssertionNonce => ENTRYCLASS_ASSERTION_NONCE,
            EntryClass::AttributeType => ENTRYCLASS_ATTRIBUTE_TYPE,
            EntryClass::Builtin => ENTRYCLASS_BUILTIN,
            EntryClass::Class => ENTRYCLASS_CLASS,
            EntryClass::ClassType => ENTRYCLASS_CLASS_TYPE,
            EntryClass::ClientCertificate => ENTRYCLASS_CLIENT_CERTIFICATE,
            EntryClass::Conflict => ENTRYCLASS_CONFLICT,
            EntryClass::DomainInfo => ENTRYCLASS_DOMAIN_INFO,
            EntryClass::DynGroup => ENTRYCLASS_DYN_GROUP,
            EntryClass::ExtensibleObject => ENTRYCLASS_EXTENSIBLE_OBJECT,
            EntryClass::Feature => ENTRYCLASS_FEATURE,
            EntryClass::Group => ENTRYCLASS_GROUP,
            EntryClass::KeyProvider => ENTRYCLASS_KEY_PROVIDER,
            EntryClass::KeyProviderInternal => ENTRYCLASS_KEY_PROVIDER_INTERNAL,
            EntryClass::KeyObject => ENTRYCLASS_KEY_OBJECT,
            EntryClass::KeyObjectHkdfS256 => ENTRYCLASS_KEY_OBJECT_HKDF_S256,
            EntryClass::KeyObjectJwtEs256 => ENTRYCLASS_KEY_OBJECT_JWT_ES256,
            EntryClass::KeyObjectJwtHs256 => ENTRYCLASS_KEY_OBJECT_JWT_HS256,
            EntryClass::KeyObjectJwtRs256 => ENTRYCLASS_KEY_OBJECT_JWT_RS256,
            EntryClass::KeyObjectJweA128GCM => ENTRYCLASS_KEY_OBJECT_JWE_A128GCM,
            EntryClass::KeyObjectJweA256GCM => ENTRYCLASS_KEY_OBJECT_JWE_A256GCM,
            EntryClass::KeyObjectInternal => ENTRYCLASS_KEY_OBJECT_INTERNAL,
            EntryClass::MemberOf => ENTRYCLASS_MEMBER_OF,
            EntryClass::Memorial => ENTRYCLASS_MEMORIAL,
            EntryClass::OAuth2Account => ENTRYCLASS_OAUTH2_ACCOUNT,
            EntryClass::OAuth2Client => ENTRYCLASS_OAUTH2_CLIENT,
            EntryClass::OAuth2DeviceCodeSession => OAUTH2_DEVICE_CODE_SESSION,
            EntryClass::OAuth2ResourceServer => OAUTH2_RESOURCE_SERVER,
            EntryClass::OAuth2ResourceServerBasic => OAUTH2_RESOURCE_SERVER_BASIC,
            EntryClass::OAuth2ResourceServerPublic => OAUTH2_RESOURCE_SERVER_PUBLIC,
            EntryClass::Object => ENTRYCLASS_OBJECT,
            EntryClass::OrgPerson => ENTRYCLASS_ORG_PERSON,
            EntryClass::OutboundMessage => ENTRYCLASS_OUTBOUND_MESSAGE,
            EntryClass::Person => ENTRYCLASS_PERSON,
            EntryClass::PosixAccount => ENTRYCLASS_POSIX_ACCOUNT,
            EntryClass::PosixGroup => ENTRYCLASS_POSIX_GROUP,
            EntryClass::Recycled => ENTRYCLASS_RECYCLED,
            EntryClass::Service => ENTRYCLASS_SERVICE,
            EntryClass::ServiceAccount => ENTRYCLASS_SERVICE_ACCOUNT,
            EntryClass::SyncAccount => ENTRYCLASS_SYNC_ACCOUNT,
            EntryClass::SyncObject => ENTRYCLASS_SYNC_OBJECT,
            EntryClass::System => ENTRYCLASS_SYSTEM,
            EntryClass::SystemConfig => ENTRYCLASS_SYSTEM_CONFIG,
            EntryClass::SystemInfo => ENTRYCLASS_SYSTEM_INFO,
            EntryClass::Tombstone => ENTRYCLASS_TOMBSTONE,
            #[cfg(any(test, debug_assertions))]
            EntryClass::TestClass => TEST_ENTRYCLASS_TEST_CLASS,
            EntryClass::User => ENTRYCLASS_USER,
        }
    }
}

impl AsRef<str> for EntryClass {
    fn as_ref(&self) -> &str {
        self.into()
    }
}

impl From<&EntryClass> for &'static str {
    fn from(value: &EntryClass) -> Self {
        (*value).into()
    }
}

impl From<EntryClass> for String {
    fn from(val: EntryClass) -> Self {
        let s: &'static str = val.into();
        s.to_string()
    }
}

impl From<EntryClass> for Value {
    fn from(val: EntryClass) -> Self {
        Value::new_iutf8(val.into())
    }
}

impl From<EntryClass> for PartialValue {
    fn from(val: EntryClass) -> Self {
        PartialValue::new_iutf8(val.into())
    }
}

impl From<EntryClass> for crate::prelude::AttrString {
    fn from(val: EntryClass) -> Self {
        crate::prelude::AttrString::from(val.to_string())
    }
}

impl Display for EntryClass {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> std::fmt::Result {
        let s: String = (*self).into();
        write!(f, "{s}")
    }
}
