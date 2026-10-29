#![allow(dead_code,non_upper_case_globals,non_snake_case)]
use std::sync::LazyLock;
use std::fmt;
#[derive(Clone,Copy,Debug)] struct Uuid(u128);
impl fmt::Display for Uuid { fn fmt(&self,f:&mut fmt::Formatter)->fmt::Result {let n=self.0;write!(f,"{:08x}-{:04x}-{:04x}-{:04x}-{:012x}",n>>96,(n>>80)&65535,(n>>64)&65535,(n>>48)&65535,n&0xffffffffffff)}}
#[derive(Clone,Copy,Debug)] struct Attribute(u16);
impl Attribute {
 const AccountExpire:Self=Self(0);
 const AccountValidFrom:Self=Self(1);
 const AcpCreateAttr:Self=Self(2);
 const AcpCreateClass:Self=Self(3);
 const AcpEnable:Self=Self(4);
 const AcpModifyClass:Self=Self(5);
 const AcpModifyPresentAttr:Self=Self(6);
 const AcpModifyRemovedAttr:Self=Self(7);
 const AcpReceiverGroup:Self=Self(8);
 const AcpSearchAttr:Self=Self(9);
 const AcpTargetScope:Self=Self(10);
 const AllowPrimaryCredFallback:Self=Self(11);
 const ApiTokenSession:Self=Self(12);
 const AttributeName:Self=Self(13);
 const AuthPasswordMinimumLength:Self=Self(14);
 const AuthSessionExpiry:Self=Self(15);
 const Class:Self=Self(16);
 const ClassName:Self=Self(17);
 const CredentialTypeMinimum:Self=Self(18);
 const Description:Self=Self(19);
 const DisplayName:Self=Self(20);
 const DomainAllowAccountRecovery:Self=Self(21);
 const DomainAllowEasterEggs:Self=Self(22);
 const DomainDisplayName:Self=Self(23);
 const DomainLdapBasedn:Self=Self(24);
 const DomainName:Self=Self(25);
 const DomainSsid:Self=Self(26);
 const DomainUuid:Self=Self(27);
 const DynMember:Self=Self(28);
 const EntryManagedBy:Self=Self(29);
 const GidNumber:Self=Self(30);
 const Image:Self=Self(31);
 const Index:Self=Self(32);
 const JwsEs256PrivateKey:Self=Self(33);
 const KeyActionRevoke:Self=Self(34);
 const KeyActionRotate:Self=Self(35);
 const KeyInternalData:Self=Self(36);
 const LdapAllowUnixPwBind:Self=Self(37);
 const LdapMaxQueryableAttrs:Self=Self(38);
 const LimitSearchMaxFilterTest:Self=Self(39);
 const LimitSearchMaxResults:Self=Self(40);
 const LinkedGroup:Self=Self(41);
 const LoginShell:Self=Self(42);
 const Mail:Self=Self(43);
 const May:Self=Self(44);
 const Member:Self=Self(45);
 const MemberOf:Self=Self(46);
 const MultiValue:Self=Self(47);
 const Must:Self=Self(48);
 const Name:Self=Self(49);
 const OAuth2AllowInsecureClientDisablePkce:Self=Self(50);
 const OAuth2AllowLocalhostRedirect:Self=Self(51);
 const OAuth2DeviceFlowEnable:Self=Self(52);
 const OAuth2JwtLegacyCryptoEnable:Self=Self(53);
 const OAuth2PreferShortUsername:Self=Self(54);
 const OAuth2RefreshTokenExpiry:Self=Self(55);
 const OAuth2RsBasicSecret:Self=Self(56);
 const OAuth2RsClaimMap:Self=Self(57);
 const OAuth2RsName:Self=Self(58);
 const OAuth2RsOrigin:Self=Self(59);
 const OAuth2RsOriginLanding:Self=Self(60);
 const OAuth2RsScopeMap:Self=Self(61);
 const OAuth2RsSupScopeMap:Self=Self(62);
 const OAuth2Session:Self=Self(63);
 const OAuth2StrictRedirectUri:Self=Self(64);
 const PassKeys:Self=Self(65);
 const PrimaryCredential:Self=Self(66);
 const PrivilegeExpiry:Self=Self(67);
 const Spn:Self=Self(68);
 const SshPublicKey:Self=Self(69);
 const SyncCookie:Self=Self(70);
 const SyncCredentialPortal:Self=Self(71);
 const SyncTokenSession:Self=Self(72);
 const SyncYieldAuthority:Self=Self(73);
 const Syntax:Self=Self(74);
 const SystemMay:Self=Self(75);
 const SystemMust:Self=Self(76);
 const Unique:Self=Self(77);
 const UnixPassword:Self=Self(78);
 const UserAuthTokenSession:Self=Self(79);
 const Uuid:Self=Self(80);
 const Version:Self=Self(81);
 const WebauthnAttestationCaList:Self=Self(82);
}
impl fmt::Display for Attribute {fn fmt(&self,f:&mut fmt::Formatter)->fmt::Result{let names=["account_expire", "account_valid_from", "acp_create_attr", "acp_create_class", "acp_enable", "acp_modify_class", "acp_modify_presentattr", "acp_modify_removedattr", "acp_receiver_group", "acp_search_attr", "acp_targetscope", "allow_primary_cred_fallback", "api_token_session", "attributename", "auth_password_minimum_length", "authsession_expiry", "class", "classname", "credential_type_minimum", "description", "displayname", "domain_allow_account_recovery", "domain_allow_easter_eggs", "domain_display_name", "domain_ldap_basedn", "domain_name", "domain_ssid", "domain_uuid", "dynmember", "entry_managed_by", "gidnumber", "image", "index", "jws_es256_private_key", "key_action_revoke", "key_action_rotate", "key_internal_data", "ldap_allow_unix_pw_bind", "ldap_max_queryable_attrs", "limit_search_max_filter_test", "limit_search_max_results", "linked_group", "loginshell", "mail", "may", "member", "memberof", "multivalue", "must", "name", "oauth2_allow_insecure_client_disable_pkce", "oauth2_allow_localhost_redirect", "oauth2_device_flow_enable", "oauth2_jwt_legacy_crypto_enable", "oauth2_prefer_short_username", "oauth2_refresh_token_expiry", "oauth2_rs_basic_secret", "oauth2_rs_claim_map", "oauth2_rs_name", "oauth2_rs_origin", "oauth2_rs_origin_landing", "oauth2_rs_scope_map", "oauth2_rs_sup_scope_map", "oauth2_session", "oauth2_strict_redirect_uri", "passkeys", "primary_credential", "privilege_expiry", "spn", "ssh_publickey", "sync_cookie", "sync_credential_portal", "sync_token_session", "sync_yield_authority", "syntax", "systemmay", "systemmust", "unique", "unix_password", "user_auth_token_session", "uuid", "version", "webauthn_attestation_ca_list"];f.write_str(names[self.0 as usize])}}
#[derive(Clone,Copy,Debug)] struct EntryClass(u16);
impl EntryClass {
 const AccessControlCreate:Self=Self(0);
 const AccessControlDelete:Self=Self(1);
 const AccessControlModify:Self=Self(2);
 const AccessControlProfile:Self=Self(3);
 const AccessControlSearch:Self=Self(4);
 const Account:Self=Self(5);
 const AccountPolicy:Self=Self(6);
 const Application:Self=Self(7);
 const AttributeType:Self=Self(8);
 const Class:Self=Self(9);
 const ClassType:Self=Self(10);
 const Group:Self=Self(11);
 const OAuth2ResourceServer:Self=Self(12);
 const OAuth2ResourceServerBasic:Self=Self(13);
 const OAuth2ResourceServerPublic:Self=Self(14);
 const Object:Self=Self(15);
 const Recycled:Self=Self(16);
 const ServiceAccount:Self=Self(17);
 const SyncAccount:Self=Self(18);
 const Tombstone:Self=Self(19);
}
impl fmt::Display for EntryClass {fn fmt(&self,f:&mut fmt::Formatter)->fmt::Result{let names=["access_control_create", "access_control_delete", "access_control_modify", "access_control_profile", "access_control_search", "account", "account_policy", "application", "attributetype", "class", "classtype", "group", "oauth2_resource_server", "oauth2_resource_server_basic", "oauth2_resource_server_public", "object", "recycled", "service_account", "sync_account", "tombstone"];f.write_str(names[self.0 as usize])}}
const UUID_DOMAIN_ADMINS:Uuid=Uuid(32);
const UUID_IDM_ACCESS_CONTROL_ADMINS:Uuid=Uuid(17);
const UUID_IDM_ACCOUNT_POLICY_ADMINS:Uuid=Uuid(71);
const UUID_IDM_ACP_ACP_MANAGE_V1:Uuid=Uuid(281474959933465);
const UUID_IDM_ACP_APPLICATION_ENTRY_MANAGER:Uuid=Uuid(281474959933554);
const UUID_IDM_ACP_APPLICATION_MANAGE:Uuid=Uuid(281474959933555);
const UUID_IDM_ACP_DOMAIN_ADMIN_V1:Uuid=Uuid(281474959933478);
const UUID_IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE:Uuid=Uuid(281474959933513);
const UUID_IDM_ACP_GROUP_MANAGE_V1:Uuid=Uuid(281474959933474);
const UUID_IDM_ACP_OAUTH2_MANAGE_V1:Uuid=Uuid(281474959933493);
const UUID_IDM_ACP_SCHEMA_WRITE_ATTRS_V1:Uuid=Uuid(281474959933464);
const UUID_IDM_ACP_SCHEMA_WRITE_CLASSES_V1:Uuid=Uuid(281474959933472);
const UUID_IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1:Uuid=Uuid(281474959933537);
const UUID_IDM_ACP_SYNC_ACCOUNT_MANAGE_V1:Uuid=Uuid(281474959933541);
const UUID_IDM_APPLICATION_ADMINS:Uuid=Uuid(80);
const UUID_IDM_GROUP_ADMINS:Uuid=Uuid(21);
const UUID_IDM_HIGH_PRIVILEGE:Uuid=Uuid(4096);
const UUID_IDM_OAUTH2_ADMINS:Uuid=Uuid(39);
const UUID_IDM_SCHEMA_ADMINS:Uuid=Uuid(16);
const STR_UUID_DOMAIN_INFO:&str="00000000-0000-0000-0000-ffffff000025";
#[derive(Clone,Debug)] enum ProtoFilter {Eq(String,String),And(Vec<Self>),Or(Vec<Self>),AndNot(Box<Self>),SelfUuid}
macro_rules! match_class_filter {($c:expr)=>{ProtoFilter::Eq(Attribute::Class.to_string(),$c.to_string())}}
#[derive(Clone,Debug,Default)] enum BuiltinAcpReceiver {#[default] None,Group(Vec<Uuid>),EntryManager}
#[derive(Clone,Debug,Default)] enum BuiltinAcpTarget {#[default] None,Filter(ProtoFilter)}
#[derive(Clone,Debug,Default)] struct BuiltinAcp {
 classes:Vec<EntryClass>, name:&'static str, uuid:Uuid, description:&'static str,
 receiver:BuiltinAcpReceiver,target:BuiltinAcpTarget,
 search_attrs:Vec<Attribute>,
 modify_present_attrs:Vec<Attribute>,
 modify_removed_attrs:Vec<Attribute>,
 modify_classes:Vec<EntryClass>,
 modify_present_classes:Vec<EntryClass>,
 modify_remove_classes:Vec<EntryClass>,
 create_classes:Vec<EntryClass>,
 create_attrs:Vec<Attribute>,
}
impl Default for Uuid {fn default()->Self{Self(0)}}
mod dl11 {include!("dl11.rs");}
mod dl12 {include!("dl12.rs");}
mod dl13 {include!("dl13.rs");}
mod dl14 {include!("dl14.rs");}
mod dl15 {include!("dl15.rs");}
mod dl_1_12 {include!("dl_1_12.rs");}
fn len_bytes(n:usize,b:&mut Vec<u8>){assert!(n<=65535);b.extend_from_slice(&(n as u16).to_le_bytes());}
fn filter_bytes(f:&ProtoFilter,b:&mut Vec<u8>){match f {
 ProtoFilter::Eq(a,v)=>{b.push(0);len_bytes(a.len(),b);b.extend_from_slice(a.as_bytes());len_bytes(v.len(),b);b.extend_from_slice(v.as_bytes());},
 ProtoFilter::And(xs)|ProtoFilter::Or(xs)=>{b.push(if matches!(f,ProtoFilter::And(_)){1}else{2});len_bytes(xs.len(),b);for x in xs{filter_bytes(x,b)}},
 ProtoFilter::AndNot(x)=>{b.push(3);filter_bytes(x,b)},ProtoFilter::SelfUuid=>b.push(4)}}
fn render(v:&BuiltinAcp)->String {
 let (receiver,groups)=match &v.receiver {BuiltinAcpReceiver::None=>(0,vec![]),BuiltinAcpReceiver::Group(xs)=>(1,xs.iter().map(|x|x.0).collect::<Vec<_>>()),BuiltinAcpReceiver::EntryManager=>(2,vec![])};
 let mut target=vec![];if let BuiltinAcpTarget::Filter(f)=&v.target{filter_bytes(f,&mut target)};
 format!("{{\"classes\":{:?},\"name\":{:?},\"uuid\":{},\"description\":{:?},\"receiver\":{},\"groups\":{:?},\"target\":{:?},\"search_attrs\":{:?},\"modify_present_attrs\":{:?},\"modify_removed_attrs\":{:?},\"modify_classes\":{:?},\"modify_present_classes\":{:?},\"modify_remove_classes\":{:?},\"create_classes\":{:?},\"create_attrs\":{:?}}}",v.classes.iter().map(|x|x.0).collect::<Vec<_>>(),v.name.as_bytes(),v.uuid.0,v.description.as_bytes(),receiver,groups,target,v.search_attrs.iter().map(|x|x.0).collect::<Vec<_>>(),v.modify_present_attrs.iter().map(|x|x.0).collect::<Vec<_>>(),v.modify_removed_attrs.iter().map(|x|x.0).collect::<Vec<_>>(),v.modify_classes.iter().map(|x|x.0).collect::<Vec<_>>(),v.modify_present_classes.iter().map(|x|x.0).collect::<Vec<_>>(),v.modify_remove_classes.iter().map(|x|x.0).collect::<Vec<_>>(),v.create_classes.iter().map(|x|x.0).collect::<Vec<_>>(),v.create_attrs.iter().map(|x|x.0).collect::<Vec<_>>())
}
fn main(){
 println!("{}\t{}", "dl11/IDM_ACP_OAUTH2_MANAGE", render(&dl11::IDM_ACP_OAUTH2_MANAGE));
 println!("{}\t{}", "dl11/IDM_ACP_ACP_MANAGE_V1", render(&dl11::IDM_ACP_ACP_MANAGE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_APPLICATION_MANAGE_DL8", render(&dl11::IDM_ACP_APPLICATION_MANAGE_DL8));
 println!("{}\t{}", "dl11/IDM_ACP_DOMAIN_ADMIN_DL9", render(&dl11::IDM_ACP_DOMAIN_ADMIN_DL9));
 println!("{}\t{}", "dl11/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1", render(&dl11::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl11/IDM_ACP_SCHEMA_WRITE_ATTRS_V1", render(&dl11::IDM_ACP_SCHEMA_WRITE_ATTRS_V1));
 println!("{}\t{}", "dl11/IDM_ACP_GROUP_MANAGE_DL9", render(&dl11::IDM_ACP_GROUP_MANAGE_DL9));
 println!("{}\t{}", "dl11/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8", render(&dl11::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8));
 println!("{}\t{}", "dl11/IDM_ACP_SCHEMA_WRITE_CLASSES_V1", render(&dl11::IDM_ACP_SCHEMA_WRITE_CLASSES_V1));
 println!("{}\t{}", "dl11/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8", render(&dl11::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8));
 println!("{}\t{}", "dl11/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1", render(&dl11::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_OAUTH2_MANAGE", render(&dl12::IDM_ACP_OAUTH2_MANAGE));
 println!("{}\t{}", "dl12/IDM_ACP_ACP_MANAGE_V1", render(&dl12::IDM_ACP_ACP_MANAGE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_APPLICATION_MANAGE_DL8", render(&dl12::IDM_ACP_APPLICATION_MANAGE_DL8));
 println!("{}\t{}", "dl12/IDM_ACP_DOMAIN_ADMIN_DL9", render(&dl12::IDM_ACP_DOMAIN_ADMIN_DL9));
 println!("{}\t{}", "dl12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1", render(&dl12::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl12/IDM_ACP_SCHEMA_WRITE_ATTRS_V1", render(&dl12::IDM_ACP_SCHEMA_WRITE_ATTRS_V1));
 println!("{}\t{}", "dl12/IDM_ACP_GROUP_MANAGE_DL9", render(&dl12::IDM_ACP_GROUP_MANAGE_DL9));
 println!("{}\t{}", "dl12/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8", render(&dl12::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8));
 println!("{}\t{}", "dl12/IDM_ACP_SCHEMA_WRITE_CLASSES_V1", render(&dl12::IDM_ACP_SCHEMA_WRITE_CLASSES_V1));
 println!("{}\t{}", "dl12/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8", render(&dl12::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8));
 println!("{}\t{}", "dl12/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1", render(&dl12::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_OAUTH2_MANAGE", render(&dl13::IDM_ACP_OAUTH2_MANAGE));
 println!("{}\t{}", "dl13/IDM_ACP_ACP_MANAGE_V1", render(&dl13::IDM_ACP_ACP_MANAGE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_APPLICATION_MANAGE_DL8", render(&dl13::IDM_ACP_APPLICATION_MANAGE_DL8));
 println!("{}\t{}", "dl13/IDM_ACP_DOMAIN_ADMIN_DL9", render(&dl13::IDM_ACP_DOMAIN_ADMIN_DL9));
 println!("{}\t{}", "dl13/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1", render(&dl13::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl13/IDM_ACP_SCHEMA_WRITE_ATTRS_V1", render(&dl13::IDM_ACP_SCHEMA_WRITE_ATTRS_V1));
 println!("{}\t{}", "dl13/IDM_ACP_GROUP_MANAGE_DL9", render(&dl13::IDM_ACP_GROUP_MANAGE_DL9));
 println!("{}\t{}", "dl13/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8", render(&dl13::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8));
 println!("{}\t{}", "dl13/IDM_ACP_SCHEMA_WRITE_CLASSES_V1", render(&dl13::IDM_ACP_SCHEMA_WRITE_CLASSES_V1));
 println!("{}\t{}", "dl13/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8", render(&dl13::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8));
 println!("{}\t{}", "dl13/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1", render(&dl13::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_OAUTH2_MANAGE", render(&dl14::IDM_ACP_OAUTH2_MANAGE));
 println!("{}\t{}", "dl14/IDM_ACP_ACP_MANAGE_V1", render(&dl14::IDM_ACP_ACP_MANAGE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_APPLICATION_MANAGE_DL8", render(&dl14::IDM_ACP_APPLICATION_MANAGE_DL8));
 println!("{}\t{}", "dl14/IDM_ACP_DOMAIN_ADMIN_DL9", render(&dl14::IDM_ACP_DOMAIN_ADMIN_DL9));
 println!("{}\t{}", "dl14/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1", render(&dl14::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl14/IDM_ACP_SCHEMA_WRITE_ATTRS_V1", render(&dl14::IDM_ACP_SCHEMA_WRITE_ATTRS_V1));
 println!("{}\t{}", "dl14/IDM_ACP_GROUP_MANAGE_DL9", render(&dl14::IDM_ACP_GROUP_MANAGE_DL9));
 println!("{}\t{}", "dl14/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8", render(&dl14::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8));
 println!("{}\t{}", "dl14/IDM_ACP_SCHEMA_WRITE_CLASSES_V1", render(&dl14::IDM_ACP_SCHEMA_WRITE_CLASSES_V1));
 println!("{}\t{}", "dl14/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8", render(&dl14::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8));
 println!("{}\t{}", "dl14/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1", render(&dl14::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_OAUTH2_MANAGE", render(&dl15::IDM_ACP_OAUTH2_MANAGE));
 println!("{}\t{}", "dl15/IDM_ACP_ACP_MANAGE_V1", render(&dl15::IDM_ACP_ACP_MANAGE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_APPLICATION_MANAGE_DL8", render(&dl15::IDM_ACP_APPLICATION_MANAGE_DL8));
 println!("{}\t{}", "dl15/IDM_ACP_DOMAIN_ADMIN_DL9", render(&dl15::IDM_ACP_DOMAIN_ADMIN_DL9));
 println!("{}\t{}", "dl15/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1", render(&dl15::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl15/IDM_ACP_SCHEMA_WRITE_ATTRS_V1", render(&dl15::IDM_ACP_SCHEMA_WRITE_ATTRS_V1));
 println!("{}\t{}", "dl15/IDM_ACP_GROUP_MANAGE_DL9", render(&dl15::IDM_ACP_GROUP_MANAGE_DL9));
 println!("{}\t{}", "dl15/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8", render(&dl15::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8));
 println!("{}\t{}", "dl15/IDM_ACP_SCHEMA_WRITE_CLASSES_V1", render(&dl15::IDM_ACP_SCHEMA_WRITE_CLASSES_V1));
 println!("{}\t{}", "dl15/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8", render(&dl15::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8));
 println!("{}\t{}", "dl15/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1", render(&dl15::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_OAUTH2_MANAGE", render(&dl_1_12::IDM_ACP_OAUTH2_MANAGE));
 println!("{}\t{}", "dl_1_12/IDM_ACP_ACP_MANAGE_V1", render(&dl_1_12::IDM_ACP_ACP_MANAGE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_APPLICATION_MANAGE_DL8", render(&dl_1_12::IDM_ACP_APPLICATION_MANAGE_DL8));
 println!("{}\t{}", "dl_1_12/IDM_ACP_DOMAIN_ADMIN_DL9", render(&dl_1_12::IDM_ACP_DOMAIN_ADMIN_DL9));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1", render(&dl_1_12::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SCHEMA_WRITE_ATTRS_V1", render(&dl_1_12::IDM_ACP_SCHEMA_WRITE_ATTRS_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_GROUP_MANAGE_DL9", render(&dl_1_12::IDM_ACP_GROUP_MANAGE_DL9));
 println!("{}\t{}", "dl_1_12/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8", render(&dl_1_12::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SCHEMA_WRITE_CLASSES_V1", render(&dl_1_12::IDM_ACP_SCHEMA_WRITE_CLASSES_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8", render(&dl_1_12::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1", render(&dl_1_12::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1));
}
