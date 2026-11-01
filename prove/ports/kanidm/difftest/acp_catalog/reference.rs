#![allow(dead_code,non_upper_case_globals,non_snake_case)]
use std::sync::LazyLock;
use std::fmt;
#[derive(Clone,Copy,Debug)] struct Uuid(u128);
impl fmt::Display for Uuid { fn fmt(&self,f:&mut fmt::Formatter)->fmt::Result {let n=self.0;write!(f,"{:08x}-{:04x}-{:04x}-{:04x}-{:012x}",n>>96,(n>>80)&65535,(n>>64)&65535,(n>>48)&65535,n&0xffffffffffff)}}
#[derive(Clone,Copy,Debug)] struct Attribute(u16);
impl Attribute {
 const AccountExpire:Self=Self(0);
 const AccountSoftlockExpire:Self=Self(1);
 const AccountValidFrom:Self=Self(2);
 const AcpCreateAttr:Self=Self(3);
 const AcpCreateClass:Self=Self(4);
 const AcpEnable:Self=Self(5);
 const AcpModifyClass:Self=Self(6);
 const AcpModifyPresentAttr:Self=Self(7);
 const AcpModifyRemovedAttr:Self=Self(8);
 const AcpReceiverGroup:Self=Self(9);
 const AcpSearchAttr:Self=Self(10);
 const AcpTargetScope:Self=Self(11);
 const AllowPrimaryCredFallback:Self=Self(12);
 const ApiTokenSession:Self=Self(13);
 const ApplicationPassword:Self=Self(14);
 const AttestedPasskeys:Self=Self(15);
 const AttributeName:Self=Self(16);
 const AuthPasswordMinimumLength:Self=Self(17);
 const AuthSessionExpiry:Self=Self(18);
 const BadlistPassword:Self=Self(19);
 const Certificate:Self=Self(20);
 const Class:Self=Self(21);
 const ClassName:Self=Self(22);
 const CredentialTypeMinimum:Self=Self(23);
 const DeleteAfter:Self=Self(24);
 const DeniedName:Self=Self(25);
 const Description:Self=Self(26);
 const DisplayName:Self=Self(27);
 const DomainAllowAccountRecovery:Self=Self(28);
 const DomainAllowEasterEggs:Self=Self(29);
 const DomainDisplayName:Self=Self(30);
 const DomainLdapBasedn:Self=Self(31);
 const DomainName:Self=Self(32);
 const DomainSsid:Self=Self(33);
 const DomainUuid:Self=Self(34);
 const DynMember:Self=Self(35);
 const Enabled:Self=Self(36);
 const EntryManagedBy:Self=Self(37);
 const GidNumber:Self=Self(38);
 const Image:Self=Self(39);
 const Index:Self=Self(40);
 const JwsEs256PrivateKey:Self=Self(41);
 const KeyActionRevoke:Self=Self(42);
 const KeyActionRotate:Self=Self(43);
 const KeyInternalData:Self=Self(44);
 const LastModifiedCid:Self=Self(45);
 const LdapAllowUnixPwBind:Self=Self(46);
 const LdapMaxQueryableAttrs:Self=Self(47);
 const LegalName:Self=Self(48);
 const LimitSearchMaxFilterTest:Self=Self(49);
 const LimitSearchMaxResults:Self=Self(50);
 const LinkedGroup:Self=Self(51);
 const LoginShell:Self=Self(52);
 const Mail:Self=Self(53);
 const MailDestination:Self=Self(54);
 const May:Self=Self(55);
 const Member:Self=Self(56);
 const MemberOf:Self=Self(57);
 const MessageTemplate:Self=Self(58);
 const MultiValue:Self=Self(59);
 const Must:Self=Self(60);
 const Name:Self=Self(61);
 const OAuth2AccountCredentialUuid:Self=Self(62);
 const OAuth2AccountProvider:Self=Self(63);
 const OAuth2AccountUniqueUserId:Self=Self(64);
 const OAuth2AccountUniqueUserSub:Self=Self(65);
 const OAuth2AllowInsecureClientDisablePkce:Self=Self(66);
 const OAuth2AllowLocalhostRedirect:Self=Self(67);
 const OAuth2AuthorisationEndpoint:Self=Self(68);
 const OAuth2ClientId:Self=Self(69);
 const OAuth2ClientSecret:Self=Self(70);
 const OAuth2ConsentPromptEnable:Self=Self(71);
 const OAuth2DeviceFlowEnable:Self=Self(72);
 const OAuth2JwtLegacyCryptoEnable:Self=Self(73);
 const OAuth2PreferShortUsername:Self=Self(74);
 const OAuth2RefreshTokenExpiry:Self=Self(75);
 const OAuth2RequestScopes:Self=Self(76);
 const OAuth2RsBasicSecret:Self=Self(77);
 const OAuth2RsClaimMap:Self=Self(78);
 const OAuth2RsName:Self=Self(79);
 const OAuth2RsOrigin:Self=Self(80);
 const OAuth2RsOriginLanding:Self=Self(81);
 const OAuth2RsScopeMap:Self=Self(82);
 const OAuth2RsSupScopeMap:Self=Self(83);
 const OAuth2Session:Self=Self(84);
 const OAuth2StrictRedirectUri:Self=Self(85);
 const OAuth2TokenEndpoint:Self=Self(86);
 const OAuth2TokenIntrospectEndpoint:Self=Self(87);
 const PassKeys:Self=Self(88);
 const PasswordChangedTime:Self=Self(89);
 const PrimaryCredential:Self=Self(90);
 const PrivilegeExpiry:Self=Self(91);
 const RadiusSecret:Self=Self(92);
 const Refers:Self=Self(93);
 const SendAfter:Self=Self(94);
 const SentAt:Self=Self(95);
 const Spn:Self=Self(96);
 const SshPublicKey:Self=Self(97);
 const SyncCookie:Self=Self(98);
 const SyncCredentialPortal:Self=Self(99);
 const SyncParentUuid:Self=Self(100);
 const SyncTokenSession:Self=Self(101);
 const SyncYieldAuthority:Self=Self(102);
 const Syntax:Self=Self(103);
 const SystemMay:Self=Self(104);
 const SystemMust:Self=Self(105);
 const Unique:Self=Self(106);
 const UnixPassword:Self=Self(107);
 const UserAuthTokenSession:Self=Self(108);
 const Uuid:Self=Self(109);
 const Version:Self=Self(110);
 const WebauthnAttestationCaList:Self=Self(111);
}
impl fmt::Display for Attribute {fn fmt(&self,f:&mut fmt::Formatter)->fmt::Result{let names=["account_expire", "account_softlock_expire", "account_valid_from", "acp_create_attr", "acp_create_class", "acp_enable", "acp_modify_class", "acp_modify_presentattr", "acp_modify_removedattr", "acp_receiver_group", "acp_search_attr", "acp_targetscope", "allow_primary_cred_fallback", "api_token_session", "application_password", "attested_passkeys", "attributename", "auth_password_minimum_length", "authsession_expiry", "badlist_password", "certificate", "class", "classname", "credential_type_minimum", "delete_after", "denied_name", "description", "displayname", "domain_allow_account_recovery", "domain_allow_easter_eggs", "domain_display_name", "domain_ldap_basedn", "domain_name", "domain_ssid", "domain_uuid", "dynmember", "enabled", "entry_managed_by", "gidnumber", "image", "index", "jws_es256_private_key", "key_action_revoke", "key_action_rotate", "key_internal_data", "last_modified_cid", "ldap_allow_unix_pw_bind", "ldap_max_queryable_attrs", "legalname", "limit_search_max_filter_test", "limit_search_max_results", "linked_group", "loginshell", "mail", "mail_destination", "may", "member", "memberof", "message_template", "multivalue", "must", "name", "oauth2_account_credential_uuid", "oauth2_account_provider", "oauth2_account_unique_user_id", "oauth2_account_unique_user_sub", "oauth2_allow_insecure_client_disable_pkce", "oauth2_allow_localhost_redirect", "oauth2_authorisation_endpoint", "oauth2_client_id", "oauth2_client_secret", "oauth2_consent_prompt_enable", "oauth2_device_flow_enable", "oauth2_jwt_legacy_crypto_enable", "oauth2_prefer_short_username", "oauth2_refresh_token_expiry", "oauth2_request_scopes", "oauth2_rs_basic_secret", "oauth2_rs_claim_map", "oauth2_rs_name", "oauth2_rs_origin", "oauth2_rs_origin_landing", "oauth2_rs_scope_map", "oauth2_rs_sup_scope_map", "oauth2_session", "oauth2_strict_redirect_uri", "oauth2_token_endpoint", "oauth2_token_introspect_endpoint", "passkeys", "pwd_changed_time", "primary_credential", "privilege_expiry", "radius_secret", "refers", "send_after", "sent_at", "spn", "ssh_publickey", "sync_cookie", "sync_credential_portal", "sync_parent_uuid", "sync_token_session", "sync_yield_authority", "syntax", "systemmay", "systemmust", "unique", "unix_password", "user_auth_token_session", "uuid", "version", "webauthn_attestation_ca_list"];f.write_str(names[self.0 as usize])}}
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
 const ClientCertificate:Self=Self(11);
 const Feature:Self=Self(12);
 const Group:Self=Self(13);
 const OAuth2Account:Self=Self(14);
 const OAuth2Client:Self=Self(15);
 const OAuth2ResourceServer:Self=Self(16);
 const OAuth2ResourceServerBasic:Self=Self(17);
 const OAuth2ResourceServerPublic:Self=Self(18);
 const Object:Self=Self(19);
 const OutboundMessage:Self=Self(20);
 const Person:Self=Self(21);
 const PosixAccount:Self=Self(22);
 const PosixGroup:Self=Self(23);
 const Recycled:Self=Self(24);
 const ServiceAccount:Self=Self(25);
 const SyncAccount:Self=Self(26);
 const Tombstone:Self=Self(27);
}
impl fmt::Display for EntryClass {fn fmt(&self,f:&mut fmt::Formatter)->fmt::Result{let names=["access_control_create", "access_control_delete", "access_control_modify", "access_control_profile", "access_control_search", "account", "account_policy", "application", "attributetype", "class", "classtype", "client_certificate", "feature", "group", "oauth2_account", "oauth2_client", "oauth2_resource_server", "oauth2_resource_server_basic", "oauth2_resource_server_public", "object", "outbound_message", "person", "posixaccount", "posixgroup", "recycled", "service_account", "sync_account", "tombstone"];f.write_str(names[self.0 as usize])}}
const UUID_DOMAIN_ADMINS:Uuid=Uuid(32);
const UUID_IDM_ACCESS_CONTROL_ADMINS:Uuid=Uuid(17);
const UUID_IDM_ACCOUNT_MAIL_READ:Uuid=Uuid(57);
const UUID_IDM_ACCOUNT_POLICY_ADMINS:Uuid=Uuid(71);
const UUID_IDM_ACP_ACCOUNT_MAIL_READ_V1:Uuid=Uuid(281474959933509);
const UUID_IDM_ACP_ACCOUNT_SELF_WRITE_V1:Uuid=Uuid(281474959933510);
const UUID_IDM_ACP_ACCOUNT_UNIX_EXTEND_V1:Uuid=Uuid(281474959933545);
const UUID_IDM_ACP_ACP_MANAGE_V1:Uuid=Uuid(281474959933465);
const UUID_IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1:Uuid=Uuid(281474959933446);
const UUID_IDM_ACP_APPLICATION_ENTRY_MANAGER:Uuid=Uuid(281474959933554);
const UUID_IDM_ACP_APPLICATION_MANAGE:Uuid=Uuid(281474959933555);
const UUID_IDM_ACP_DOMAIN_ADMIN_V1:Uuid=Uuid(281474959933478);
const UUID_IDM_ACP_FEATURE_MANAGE:Uuid=Uuid(281474959933574);
const UUID_IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE:Uuid=Uuid(281474959933513);
const UUID_IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY:Uuid=Uuid(281474959933512);
const UUID_IDM_ACP_GROUP_ENTRY_MANAGER_V1:Uuid=Uuid(281474959933520);
const UUID_IDM_ACP_GROUP_MANAGE_V1:Uuid=Uuid(281474959933474);
const UUID_IDM_ACP_GROUP_READ:Uuid=Uuid(281474959933522);
const UUID_IDM_ACP_GROUP_UNIX_MANAGE_V1:Uuid=Uuid(281474959933544);
const UUID_IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER:Uuid=Uuid(281474959933553);
const UUID_IDM_ACP_HP_GROUP_UNIX_MANAGE_V1:Uuid=Uuid(281474959933543);
const UUID_IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1:Uuid=Uuid(281474959933528);
const UUID_IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY:Uuid=Uuid(281474959933539);
const UUID_IDM_ACP_MAIL_SERVERS:Uuid=Uuid(281474959933556);
const UUID_IDM_ACP_MESSAGE_MANAGE:Uuid=Uuid(281474959933559);
const UUID_IDM_ACP_MESSAGE_SENDER:Uuid=Uuid(281474959933560);
const UUID_IDM_ACP_OAUTH2_ACCOUNT_ENROL:Uuid=Uuid(281474959933568);
const UUID_IDM_ACP_OAUTH2_CLIENT_ADMIN:Uuid=Uuid(281474959933561);
const UUID_IDM_ACP_OAUTH2_MANAGE_BASIC:Uuid=Uuid(281474959933569);
const UUID_IDM_ACP_OAUTH2_MANAGE_V1:Uuid=Uuid(281474959933493);
const UUID_IDM_ACP_PEOPLE_CREATE_V1:Uuid=Uuid(281474959933524);
const UUID_IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1:Uuid=Uuid(281474959933527);
const UUID_IDM_ACP_PEOPLE_DELETE_V1:Uuid=Uuid(281474959933525);
const UUID_IDM_ACP_PEOPLE_MANAGE_V1:Uuid=Uuid(281474959933526);
const UUID_IDM_ACP_PEOPLE_PII_MANAGE_V1:Uuid=Uuid(281474959933459);
const UUID_IDM_ACP_PEOPLE_PII_READ_V1:Uuid=Uuid(281474959933447);
const UUID_IDM_ACP_PEOPLE_READ_V1:Uuid=Uuid(281474959933523);
const UUID_IDM_ACP_PEOPLE_SELF_WRITE_MAIL:Uuid=Uuid(281474959933505);
const UUID_IDM_ACP_RADIUS_SECRET_MANAGE_V1:Uuid=Uuid(281474959933542);
const UUID_IDM_ACP_RADIUS_SERVERS_V1:Uuid=Uuid(281474959933460);
const UUID_IDM_ACP_RECYCLE_BIN_REVIVE_V1:Uuid=Uuid(281474959933443);
const UUID_IDM_ACP_RECYCLE_BIN_SEARCH_V1:Uuid=Uuid(281474959933442);
const UUID_IDM_ACP_SCHEMA_WRITE_ATTRS_V1:Uuid=Uuid(281474959933464);
const UUID_IDM_ACP_SCHEMA_WRITE_CLASSES_V1:Uuid=Uuid(281474959933472);
const UUID_IDM_ACP_SELF_NAME_WRITE_V1:Uuid=Uuid(281474959933521);
const UUID_IDM_ACP_SELF_READ:Uuid=Uuid(281474959933444);
const UUID_IDM_ACP_SELF_WRITE_V1:Uuid=Uuid(281474959933473);
const UUID_IDM_ACP_SERVICE_ACCOUNT_CREATE_V1:Uuid=Uuid(281474959933529);
const UUID_IDM_ACP_SERVICE_ACCOUNT_DELETE_V1:Uuid=Uuid(281474959933536);
const UUID_IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY:Uuid=Uuid(281474959933538);
const UUID_IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1:Uuid=Uuid(281474959933537);
const UUID_IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1:Uuid=Uuid(281474959933540);
const UUID_IDM_ACP_SYNC_ACCOUNT_MANAGE_V1:Uuid=Uuid(281474959933541);
const UUID_IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1:Uuid=Uuid(281474959933480);
const UUID_IDM_ALL_ACCOUNTS:Uuid=Uuid(54);
const UUID_IDM_ALL_PERSONS:Uuid=Uuid(53);
const UUID_IDM_APPLICATION_ADMINS:Uuid=Uuid(80);
const UUID_IDM_CLIENT_CERTIFICATE_ADMINS:Uuid=Uuid(73);
const UUID_IDM_GROUP_ADMINS:Uuid=Uuid(21);
const UUID_IDM_HIGH_PRIVILEGE:Uuid=Uuid(4096);
const UUID_IDM_MAIL_SERVERS:Uuid=Uuid(82);
const UUID_IDM_MESSAGE_ADMINS:Uuid=Uuid(84);
const UUID_IDM_MESSAGE_SENDERS:Uuid=Uuid(85);
const UUID_IDM_OAUTH2_ACCOUNT_ADMINS:Uuid=Uuid(87);
const UUID_IDM_OAUTH2_ADMINS:Uuid=Uuid(39);
const UUID_IDM_OAUTH2_CLIENT_ADMINS:Uuid=Uuid(86);
const UUID_IDM_PEOPLE_ADMINS:Uuid=Uuid(19);
const UUID_IDM_PEOPLE_ON_BOARDING:Uuid=Uuid(69);
const UUID_IDM_PEOPLE_PII_READ:Uuid=Uuid(2);
const UUID_IDM_PEOPLE_SELF_MAIL_WRITE:Uuid=Uuid(51);
const UUID_IDM_PEOPLE_SELF_NAME_WRITE:Uuid=Uuid(72);
const UUID_IDM_RADIUS_ADMINS:Uuid=Uuid(67);
const UUID_IDM_RADIUS_SERVERS:Uuid=Uuid(7);
const UUID_IDM_RECYCLE_BIN_ADMINS:Uuid=Uuid(66);
const UUID_IDM_SCHEMA_ADMINS:Uuid=Uuid(16);
const UUID_IDM_SERVICE_ACCOUNT_ADMINS:Uuid=Uuid(70);
const UUID_IDM_SERVICE_DESK:Uuid=Uuid(65);
const UUID_IDM_UNIX_ADMINS:Uuid=Uuid(68);
const UUID_IDM_UNIX_AUTHENTICATION_READ:Uuid=Uuid(83);
const ATTR_RECYCLED:&str="recycled";
const STR_UUID_DOMAIN_INFO:&str="00000000-0000-0000-0000-ffffff000025";
const STR_UUID_SYSTEM_CONFIG:&str="00000000-0000-0000-0000-ffffff000027";
#[derive(Clone,Debug)] enum ProtoFilter {Eq(String,String),And(Vec<Self>),Or(Vec<Self>),AndNot(Box<Self>),SelfUuid,Pres(String)}
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
 ProtoFilter::AndNot(x)=>{b.push(3);filter_bytes(x,b)},ProtoFilter::SelfUuid=>b.push(4),ProtoFilter::Pres(a)=>{b.push(5);len_bytes(a.len(),b);b.extend_from_slice(a.as_bytes());}}}
fn render(v:&BuiltinAcp)->String {
 let (receiver,groups)=match &v.receiver {BuiltinAcpReceiver::None=>(0,vec![]),BuiltinAcpReceiver::Group(xs)=>(1,xs.iter().map(|x|x.0).collect::<Vec<_>>()),BuiltinAcpReceiver::EntryManager=>(2,vec![])};
 let mut target=vec![];if let BuiltinAcpTarget::Filter(f)=&v.target{filter_bytes(f,&mut target)};
 format!("{{\"classes\":{:?},\"name\":{:?},\"uuid\":{},\"description\":{:?},\"receiver\":{},\"groups\":{:?},\"target\":{:?},\"search_attrs\":{:?},\"modify_present_attrs\":{:?},\"modify_removed_attrs\":{:?},\"modify_classes\":{:?},\"modify_present_classes\":{:?},\"modify_remove_classes\":{:?},\"create_classes\":{:?},\"create_attrs\":{:?}}}",v.classes.iter().map(|x|x.0).collect::<Vec<_>>(),v.name.as_bytes(),v.uuid.0,v.description.as_bytes(),receiver,groups,target,v.search_attrs.iter().map(|x|x.0).collect::<Vec<_>>(),v.modify_present_attrs.iter().map(|x|x.0).collect::<Vec<_>>(),v.modify_removed_attrs.iter().map(|x|x.0).collect::<Vec<_>>(),v.modify_classes.iter().map(|x|x.0).collect::<Vec<_>>(),v.modify_present_classes.iter().map(|x|x.0).collect::<Vec<_>>(),v.modify_remove_classes.iter().map(|x|x.0).collect::<Vec<_>>(),v.create_classes.iter().map(|x|x.0).collect::<Vec<_>>(),v.create_attrs.iter().map(|x|x.0).collect::<Vec<_>>())
}
fn main(){
 println!("{}\t{}", "dl11/IDM_ACP_ACCOUNT_MAIL_READ_DL6", render(&dl11::IDM_ACP_ACCOUNT_MAIL_READ_DL6));
 println!("{}\t{}", "dl11/IDM_ACP_ACCOUNT_SELF_WRITE_V1", render(&dl11::IDM_ACP_ACCOUNT_SELF_WRITE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1", render(&dl11::IDM_ACP_ACCOUNT_UNIX_EXTEND_V1));
 println!("{}\t{}", "dl11/IDM_ACP_ACP_MANAGE_V1", render(&dl11::IDM_ACP_ACP_MANAGE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1", render(&dl11::IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1));
 println!("{}\t{}", "dl11/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8", render(&dl11::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8));
 println!("{}\t{}", "dl11/IDM_ACP_APPLICATION_MANAGE_DL8", render(&dl11::IDM_ACP_APPLICATION_MANAGE_DL8));
 println!("{}\t{}", "dl11/IDM_ACP_DOMAIN_ADMIN_DL9", render(&dl11::IDM_ACP_DOMAIN_ADMIN_DL9));
 println!("{}\t{}", "dl11/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8", render(&dl11::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8));
 println!("{}\t{}", "dl11/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl11::IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl11/IDM_ACP_GROUP_ENTRY_MANAGER_V1", render(&dl11::IDM_ACP_GROUP_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl11/IDM_ACP_GROUP_MANAGE_DL9", render(&dl11::IDM_ACP_GROUP_MANAGE_DL9));
 println!("{}\t{}", "dl11/IDM_ACP_GROUP_READ_V1", render(&dl11::IDM_ACP_GROUP_READ_V1));
 println!("{}\t{}", "dl11/IDM_ACP_GROUP_UNIX_MANAGE_V1", render(&dl11::IDM_ACP_GROUP_UNIX_MANAGE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7", render(&dl11::IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7));
 println!("{}\t{}", "dl11/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1", render(&dl11::IDM_ACP_HP_GROUP_UNIX_MANAGE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1", render(&dl11::IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1));
 println!("{}\t{}", "dl11/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl11::IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl11/IDM_ACP_MAIL_SERVERS_DL8", render(&dl11::IDM_ACP_MAIL_SERVERS_DL8));
 println!("{}\t{}", "dl11/IDM_ACP_OAUTH2_MANAGE", render(&dl11::IDM_ACP_OAUTH2_MANAGE));
 println!("{}\t{}", "dl11/IDM_ACP_PEOPLE_CREATE_DL6", render(&dl11::IDM_ACP_PEOPLE_CREATE_DL6));
 println!("{}\t{}", "dl11/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1", render(&dl11::IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1));
 println!("{}\t{}", "dl11/IDM_ACP_PEOPLE_DELETE_V1", render(&dl11::IDM_ACP_PEOPLE_DELETE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_PEOPLE_MANAGE_V1", render(&dl11::IDM_ACP_PEOPLE_MANAGE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_PEOPLE_PII_MANAGE_V1", render(&dl11::IDM_ACP_PEOPLE_PII_MANAGE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_PEOPLE_PII_READ_V1", render(&dl11::IDM_ACP_PEOPLE_PII_READ_V1));
 println!("{}\t{}", "dl11/IDM_ACP_PEOPLE_READ_V1", render(&dl11::IDM_ACP_PEOPLE_READ_V1));
 println!("{}\t{}", "dl11/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1", render(&dl11::IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1));
 println!("{}\t{}", "dl11/IDM_ACP_RADIUS_SECRET_MANAGE_V1", render(&dl11::IDM_ACP_RADIUS_SECRET_MANAGE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_RADIUS_SERVERS_V1", render(&dl11::IDM_ACP_RADIUS_SERVERS_V1));
 println!("{}\t{}", "dl11/IDM_ACP_RECYCLE_BIN_REVIVE_V1", render(&dl11::IDM_ACP_RECYCLE_BIN_REVIVE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_RECYCLE_BIN_SEARCH_V1", render(&dl11::IDM_ACP_RECYCLE_BIN_SEARCH_V1));
 println!("{}\t{}", "dl11/IDM_ACP_SCHEMA_WRITE_ATTRS_V1", render(&dl11::IDM_ACP_SCHEMA_WRITE_ATTRS_V1));
 println!("{}\t{}", "dl11/IDM_ACP_SCHEMA_WRITE_CLASSES_V1", render(&dl11::IDM_ACP_SCHEMA_WRITE_CLASSES_V1));
 println!("{}\t{}", "dl11/IDM_ACP_SELF_NAME_WRITE_DL7", render(&dl11::IDM_ACP_SELF_NAME_WRITE_DL7));
 println!("{}\t{}", "dl11/IDM_ACP_SELF_READ_DL8", render(&dl11::IDM_ACP_SELF_READ_DL8));
 println!("{}\t{}", "dl11/IDM_ACP_SELF_WRITE_DL8", render(&dl11::IDM_ACP_SELF_WRITE_DL8));
 println!("{}\t{}", "dl11/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1", render(&dl11::IDM_ACP_SERVICE_ACCOUNT_CREATE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1", render(&dl11::IDM_ACP_SERVICE_ACCOUNT_DELETE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl11::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl11/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1", render(&dl11::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl11/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1", render(&dl11::IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1", render(&dl11::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl11/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1", render(&dl11::IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_ACCOUNT_MAIL_READ_DL6", render(&dl12::IDM_ACP_ACCOUNT_MAIL_READ_DL6));
 println!("{}\t{}", "dl12/IDM_ACP_ACCOUNT_SELF_WRITE_V1", render(&dl12::IDM_ACP_ACCOUNT_SELF_WRITE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1", render(&dl12::IDM_ACP_ACCOUNT_UNIX_EXTEND_V1));
 println!("{}\t{}", "dl12/IDM_ACP_ACP_MANAGE_V1", render(&dl12::IDM_ACP_ACP_MANAGE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1", render(&dl12::IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1));
 println!("{}\t{}", "dl12/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8", render(&dl12::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8));
 println!("{}\t{}", "dl12/IDM_ACP_APPLICATION_MANAGE_DL8", render(&dl12::IDM_ACP_APPLICATION_MANAGE_DL8));
 println!("{}\t{}", "dl12/IDM_ACP_DOMAIN_ADMIN_DL9", render(&dl12::IDM_ACP_DOMAIN_ADMIN_DL9));
 println!("{}\t{}", "dl12/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8", render(&dl12::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8));
 println!("{}\t{}", "dl12/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl12::IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl12/IDM_ACP_GROUP_ENTRY_MANAGER_V1", render(&dl12::IDM_ACP_GROUP_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl12/IDM_ACP_GROUP_MANAGE_DL9", render(&dl12::IDM_ACP_GROUP_MANAGE_DL9));
 println!("{}\t{}", "dl12/IDM_ACP_GROUP_READ_V1", render(&dl12::IDM_ACP_GROUP_READ_V1));
 println!("{}\t{}", "dl12/IDM_ACP_GROUP_UNIX_MANAGE_V1", render(&dl12::IDM_ACP_GROUP_UNIX_MANAGE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7", render(&dl12::IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7));
 println!("{}\t{}", "dl12/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1", render(&dl12::IDM_ACP_HP_GROUP_UNIX_MANAGE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1", render(&dl12::IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1));
 println!("{}\t{}", "dl12/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl12::IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl12/IDM_ACP_MAIL_SERVERS_DL8", render(&dl12::IDM_ACP_MAIL_SERVERS_DL8));
 println!("{}\t{}", "dl12/IDM_ACP_MESSAGE_MANAGE", render(&dl12::IDM_ACP_MESSAGE_MANAGE));
 println!("{}\t{}", "dl12/IDM_ACP_MESSAGE_SENDER", render(&dl12::IDM_ACP_MESSAGE_SENDER));
 println!("{}\t{}", "dl12/IDM_ACP_OAUTH2_ACCOUNT_ENROL", render(&dl12::IDM_ACP_OAUTH2_ACCOUNT_ENROL));
 println!("{}\t{}", "dl12/IDM_ACP_OAUTH2_CLIENT_ADMIN", render(&dl12::IDM_ACP_OAUTH2_CLIENT_ADMIN));
 println!("{}\t{}", "dl12/IDM_ACP_OAUTH2_MANAGE", render(&dl12::IDM_ACP_OAUTH2_MANAGE));
 println!("{}\t{}", "dl12/IDM_ACP_PEOPLE_CREATE_DL6", render(&dl12::IDM_ACP_PEOPLE_CREATE_DL6));
 println!("{}\t{}", "dl12/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1", render(&dl12::IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1));
 println!("{}\t{}", "dl12/IDM_ACP_PEOPLE_DELETE_V1", render(&dl12::IDM_ACP_PEOPLE_DELETE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_PEOPLE_MANAGE_V1", render(&dl12::IDM_ACP_PEOPLE_MANAGE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_PEOPLE_PII_MANAGE_V1", render(&dl12::IDM_ACP_PEOPLE_PII_MANAGE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_PEOPLE_PII_READ_V1", render(&dl12::IDM_ACP_PEOPLE_PII_READ_V1));
 println!("{}\t{}", "dl12/IDM_ACP_PEOPLE_READ_V1", render(&dl12::IDM_ACP_PEOPLE_READ_V1));
 println!("{}\t{}", "dl12/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1", render(&dl12::IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1));
 println!("{}\t{}", "dl12/IDM_ACP_RADIUS_SECRET_MANAGE_V1", render(&dl12::IDM_ACP_RADIUS_SECRET_MANAGE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_RADIUS_SERVERS_V1", render(&dl12::IDM_ACP_RADIUS_SERVERS_V1));
 println!("{}\t{}", "dl12/IDM_ACP_RECYCLE_BIN_REVIVE_V1", render(&dl12::IDM_ACP_RECYCLE_BIN_REVIVE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_RECYCLE_BIN_SEARCH_V1", render(&dl12::IDM_ACP_RECYCLE_BIN_SEARCH_V1));
 println!("{}\t{}", "dl12/IDM_ACP_SCHEMA_WRITE_ATTRS_V1", render(&dl12::IDM_ACP_SCHEMA_WRITE_ATTRS_V1));
 println!("{}\t{}", "dl12/IDM_ACP_SCHEMA_WRITE_CLASSES_V1", render(&dl12::IDM_ACP_SCHEMA_WRITE_CLASSES_V1));
 println!("{}\t{}", "dl12/IDM_ACP_SELF_NAME_WRITE_DL7", render(&dl12::IDM_ACP_SELF_NAME_WRITE_DL7));
 println!("{}\t{}", "dl12/IDM_ACP_SELF_READ_DL8", render(&dl12::IDM_ACP_SELF_READ_DL8));
 println!("{}\t{}", "dl12/IDM_ACP_SELF_WRITE_DL8", render(&dl12::IDM_ACP_SELF_WRITE_DL8));
 println!("{}\t{}", "dl12/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1", render(&dl12::IDM_ACP_SERVICE_ACCOUNT_CREATE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1", render(&dl12::IDM_ACP_SERVICE_ACCOUNT_DELETE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl12::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1", render(&dl12::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl12/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1", render(&dl12::IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1", render(&dl12::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl12/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1", render(&dl12::IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_ACCOUNT_MAIL_READ_DL6", render(&dl13::IDM_ACP_ACCOUNT_MAIL_READ_DL6));
 println!("{}\t{}", "dl13/IDM_ACP_ACCOUNT_SELF_WRITE_V1", render(&dl13::IDM_ACP_ACCOUNT_SELF_WRITE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1", render(&dl13::IDM_ACP_ACCOUNT_UNIX_EXTEND_V1));
 println!("{}\t{}", "dl13/IDM_ACP_ACP_MANAGE_V1", render(&dl13::IDM_ACP_ACP_MANAGE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1", render(&dl13::IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1));
 println!("{}\t{}", "dl13/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8", render(&dl13::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8));
 println!("{}\t{}", "dl13/IDM_ACP_APPLICATION_MANAGE_DL8", render(&dl13::IDM_ACP_APPLICATION_MANAGE_DL8));
 println!("{}\t{}", "dl13/IDM_ACP_DOMAIN_ADMIN_DL9", render(&dl13::IDM_ACP_DOMAIN_ADMIN_DL9));
 println!("{}\t{}", "dl13/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8", render(&dl13::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8));
 println!("{}\t{}", "dl13/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl13::IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl13/IDM_ACP_GROUP_ENTRY_MANAGER_V1", render(&dl13::IDM_ACP_GROUP_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl13/IDM_ACP_GROUP_MANAGE_DL9", render(&dl13::IDM_ACP_GROUP_MANAGE_DL9));
 println!("{}\t{}", "dl13/IDM_ACP_GROUP_READ_V1", render(&dl13::IDM_ACP_GROUP_READ_V1));
 println!("{}\t{}", "dl13/IDM_ACP_GROUP_UNIX_MANAGE_V1", render(&dl13::IDM_ACP_GROUP_UNIX_MANAGE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7", render(&dl13::IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7));
 println!("{}\t{}", "dl13/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1", render(&dl13::IDM_ACP_HP_GROUP_UNIX_MANAGE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1", render(&dl13::IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1));
 println!("{}\t{}", "dl13/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl13::IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl13/IDM_ACP_MAIL_SERVERS_DL8", render(&dl13::IDM_ACP_MAIL_SERVERS_DL8));
 println!("{}\t{}", "dl13/IDM_ACP_MESSAGE_MANAGE", render(&dl13::IDM_ACP_MESSAGE_MANAGE));
 println!("{}\t{}", "dl13/IDM_ACP_MESSAGE_SENDER", render(&dl13::IDM_ACP_MESSAGE_SENDER));
 println!("{}\t{}", "dl13/IDM_ACP_OAUTH2_ACCOUNT_ENROL", render(&dl13::IDM_ACP_OAUTH2_ACCOUNT_ENROL));
 println!("{}\t{}", "dl13/IDM_ACP_OAUTH2_CLIENT_ADMIN", render(&dl13::IDM_ACP_OAUTH2_CLIENT_ADMIN));
 println!("{}\t{}", "dl13/IDM_ACP_OAUTH2_MANAGE", render(&dl13::IDM_ACP_OAUTH2_MANAGE));
 println!("{}\t{}", "dl13/IDM_ACP_OAUTH2_MANAGE_BASIC", render(&dl13::IDM_ACP_OAUTH2_MANAGE_BASIC));
 println!("{}\t{}", "dl13/IDM_ACP_PEOPLE_CREATE_DL6", render(&dl13::IDM_ACP_PEOPLE_CREATE_DL6));
 println!("{}\t{}", "dl13/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1", render(&dl13::IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1));
 println!("{}\t{}", "dl13/IDM_ACP_PEOPLE_DELETE_V1", render(&dl13::IDM_ACP_PEOPLE_DELETE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_PEOPLE_MANAGE_V1", render(&dl13::IDM_ACP_PEOPLE_MANAGE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_PEOPLE_PII_MANAGE_V1", render(&dl13::IDM_ACP_PEOPLE_PII_MANAGE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_PEOPLE_PII_READ_V1", render(&dl13::IDM_ACP_PEOPLE_PII_READ_V1));
 println!("{}\t{}", "dl13/IDM_ACP_PEOPLE_READ_V1", render(&dl13::IDM_ACP_PEOPLE_READ_V1));
 println!("{}\t{}", "dl13/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1", render(&dl13::IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1));
 println!("{}\t{}", "dl13/IDM_ACP_RADIUS_SECRET_MANAGE_V1", render(&dl13::IDM_ACP_RADIUS_SECRET_MANAGE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_RADIUS_SERVERS_V1", render(&dl13::IDM_ACP_RADIUS_SERVERS_V1));
 println!("{}\t{}", "dl13/IDM_ACP_RECYCLE_BIN_REVIVE_V1", render(&dl13::IDM_ACP_RECYCLE_BIN_REVIVE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_RECYCLE_BIN_SEARCH_V1", render(&dl13::IDM_ACP_RECYCLE_BIN_SEARCH_V1));
 println!("{}\t{}", "dl13/IDM_ACP_SCHEMA_WRITE_ATTRS_V1", render(&dl13::IDM_ACP_SCHEMA_WRITE_ATTRS_V1));
 println!("{}\t{}", "dl13/IDM_ACP_SCHEMA_WRITE_CLASSES_V1", render(&dl13::IDM_ACP_SCHEMA_WRITE_CLASSES_V1));
 println!("{}\t{}", "dl13/IDM_ACP_SELF_NAME_WRITE_DL7", render(&dl13::IDM_ACP_SELF_NAME_WRITE_DL7));
 println!("{}\t{}", "dl13/IDM_ACP_SELF_READ_DL8", render(&dl13::IDM_ACP_SELF_READ_DL8));
 println!("{}\t{}", "dl13/IDM_ACP_SELF_WRITE_DL8", render(&dl13::IDM_ACP_SELF_WRITE_DL8));
 println!("{}\t{}", "dl13/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1", render(&dl13::IDM_ACP_SERVICE_ACCOUNT_CREATE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1", render(&dl13::IDM_ACP_SERVICE_ACCOUNT_DELETE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl13::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl13/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1", render(&dl13::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl13/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1", render(&dl13::IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1", render(&dl13::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl13/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1", render(&dl13::IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_ACCOUNT_MAIL_READ_DL6", render(&dl14::IDM_ACP_ACCOUNT_MAIL_READ_DL6));
 println!("{}\t{}", "dl14/IDM_ACP_ACCOUNT_SELF_WRITE_V1", render(&dl14::IDM_ACP_ACCOUNT_SELF_WRITE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1", render(&dl14::IDM_ACP_ACCOUNT_UNIX_EXTEND_V1));
 println!("{}\t{}", "dl14/IDM_ACP_ACP_MANAGE_V1", render(&dl14::IDM_ACP_ACP_MANAGE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1", render(&dl14::IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1));
 println!("{}\t{}", "dl14/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8", render(&dl14::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8));
 println!("{}\t{}", "dl14/IDM_ACP_APPLICATION_MANAGE_DL8", render(&dl14::IDM_ACP_APPLICATION_MANAGE_DL8));
 println!("{}\t{}", "dl14/IDM_ACP_DOMAIN_ADMIN_DL9", render(&dl14::IDM_ACP_DOMAIN_ADMIN_DL9));
 println!("{}\t{}", "dl14/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8", render(&dl14::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8));
 println!("{}\t{}", "dl14/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl14::IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl14/IDM_ACP_GROUP_ENTRY_MANAGER_V1", render(&dl14::IDM_ACP_GROUP_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl14/IDM_ACP_GROUP_MANAGE_DL9", render(&dl14::IDM_ACP_GROUP_MANAGE_DL9));
 println!("{}\t{}", "dl14/IDM_ACP_GROUP_READ_V1", render(&dl14::IDM_ACP_GROUP_READ_V1));
 println!("{}\t{}", "dl14/IDM_ACP_GROUP_UNIX_MANAGE_V1", render(&dl14::IDM_ACP_GROUP_UNIX_MANAGE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7", render(&dl14::IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7));
 println!("{}\t{}", "dl14/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1", render(&dl14::IDM_ACP_HP_GROUP_UNIX_MANAGE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1", render(&dl14::IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1));
 println!("{}\t{}", "dl14/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl14::IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl14/IDM_ACP_MAIL_SERVERS_DL8", render(&dl14::IDM_ACP_MAIL_SERVERS_DL8));
 println!("{}\t{}", "dl14/IDM_ACP_MESSAGE_MANAGE", render(&dl14::IDM_ACP_MESSAGE_MANAGE));
 println!("{}\t{}", "dl14/IDM_ACP_MESSAGE_SENDER", render(&dl14::IDM_ACP_MESSAGE_SENDER));
 println!("{}\t{}", "dl14/IDM_ACP_OAUTH2_ACCOUNT_ENROL", render(&dl14::IDM_ACP_OAUTH2_ACCOUNT_ENROL));
 println!("{}\t{}", "dl14/IDM_ACP_OAUTH2_CLIENT_ADMIN", render(&dl14::IDM_ACP_OAUTH2_CLIENT_ADMIN));
 println!("{}\t{}", "dl14/IDM_ACP_OAUTH2_MANAGE", render(&dl14::IDM_ACP_OAUTH2_MANAGE));
 println!("{}\t{}", "dl14/IDM_ACP_OAUTH2_MANAGE_BASIC", render(&dl14::IDM_ACP_OAUTH2_MANAGE_BASIC));
 println!("{}\t{}", "dl14/IDM_ACP_PEOPLE_CREATE_DL6", render(&dl14::IDM_ACP_PEOPLE_CREATE_DL6));
 println!("{}\t{}", "dl14/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1", render(&dl14::IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1));
 println!("{}\t{}", "dl14/IDM_ACP_PEOPLE_DELETE_V1", render(&dl14::IDM_ACP_PEOPLE_DELETE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_PEOPLE_MANAGE_V1", render(&dl14::IDM_ACP_PEOPLE_MANAGE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_PEOPLE_PII_MANAGE_V1", render(&dl14::IDM_ACP_PEOPLE_PII_MANAGE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_PEOPLE_PII_READ_V1", render(&dl14::IDM_ACP_PEOPLE_PII_READ_V1));
 println!("{}\t{}", "dl14/IDM_ACP_PEOPLE_READ_V1", render(&dl14::IDM_ACP_PEOPLE_READ_V1));
 println!("{}\t{}", "dl14/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1", render(&dl14::IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1));
 println!("{}\t{}", "dl14/IDM_ACP_RADIUS_SECRET_MANAGE_V1", render(&dl14::IDM_ACP_RADIUS_SECRET_MANAGE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_RADIUS_SERVERS_V1", render(&dl14::IDM_ACP_RADIUS_SERVERS_V1));
 println!("{}\t{}", "dl14/IDM_ACP_RECYCLE_BIN_REVIVE_V1", render(&dl14::IDM_ACP_RECYCLE_BIN_REVIVE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_RECYCLE_BIN_SEARCH_V1", render(&dl14::IDM_ACP_RECYCLE_BIN_SEARCH_V1));
 println!("{}\t{}", "dl14/IDM_ACP_SCHEMA_WRITE_ATTRS_V1", render(&dl14::IDM_ACP_SCHEMA_WRITE_ATTRS_V1));
 println!("{}\t{}", "dl14/IDM_ACP_SCHEMA_WRITE_CLASSES_V1", render(&dl14::IDM_ACP_SCHEMA_WRITE_CLASSES_V1));
 println!("{}\t{}", "dl14/IDM_ACP_SELF_NAME_WRITE_DL7", render(&dl14::IDM_ACP_SELF_NAME_WRITE_DL7));
 println!("{}\t{}", "dl14/IDM_ACP_SELF_READ_DL8", render(&dl14::IDM_ACP_SELF_READ_DL8));
 println!("{}\t{}", "dl14/IDM_ACP_SELF_WRITE_DL8", render(&dl14::IDM_ACP_SELF_WRITE_DL8));
 println!("{}\t{}", "dl14/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1", render(&dl14::IDM_ACP_SERVICE_ACCOUNT_CREATE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1", render(&dl14::IDM_ACP_SERVICE_ACCOUNT_DELETE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl14::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl14/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1", render(&dl14::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl14/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1", render(&dl14::IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1", render(&dl14::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl14/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1", render(&dl14::IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_ACCOUNT_MAIL_READ_DL6", render(&dl15::IDM_ACP_ACCOUNT_MAIL_READ_DL6));
 println!("{}\t{}", "dl15/IDM_ACP_ACCOUNT_SELF_WRITE_V1", render(&dl15::IDM_ACP_ACCOUNT_SELF_WRITE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1", render(&dl15::IDM_ACP_ACCOUNT_UNIX_EXTEND_V1));
 println!("{}\t{}", "dl15/IDM_ACP_ACP_MANAGE_V1", render(&dl15::IDM_ACP_ACP_MANAGE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1", render(&dl15::IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1));
 println!("{}\t{}", "dl15/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8", render(&dl15::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8));
 println!("{}\t{}", "dl15/IDM_ACP_APPLICATION_MANAGE_DL8", render(&dl15::IDM_ACP_APPLICATION_MANAGE_DL8));
 println!("{}\t{}", "dl15/IDM_ACP_DOMAIN_ADMIN_DL9", render(&dl15::IDM_ACP_DOMAIN_ADMIN_DL9));
 println!("{}\t{}", "dl15/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8", render(&dl15::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8));
 println!("{}\t{}", "dl15/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl15::IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl15/IDM_ACP_GROUP_ENTRY_MANAGER_V1", render(&dl15::IDM_ACP_GROUP_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl15/IDM_ACP_GROUP_MANAGE_DL9", render(&dl15::IDM_ACP_GROUP_MANAGE_DL9));
 println!("{}\t{}", "dl15/IDM_ACP_GROUP_READ_V1", render(&dl15::IDM_ACP_GROUP_READ_V1));
 println!("{}\t{}", "dl15/IDM_ACP_GROUP_UNIX_MANAGE_V1", render(&dl15::IDM_ACP_GROUP_UNIX_MANAGE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7", render(&dl15::IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7));
 println!("{}\t{}", "dl15/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1", render(&dl15::IDM_ACP_HP_GROUP_UNIX_MANAGE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1", render(&dl15::IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1));
 println!("{}\t{}", "dl15/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl15::IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl15/IDM_ACP_MAIL_SERVERS_DL8", render(&dl15::IDM_ACP_MAIL_SERVERS_DL8));
 println!("{}\t{}", "dl15/IDM_ACP_MESSAGE_MANAGE", render(&dl15::IDM_ACP_MESSAGE_MANAGE));
 println!("{}\t{}", "dl15/IDM_ACP_MESSAGE_SENDER", render(&dl15::IDM_ACP_MESSAGE_SENDER));
 println!("{}\t{}", "dl15/IDM_ACP_OAUTH2_ACCOUNT_ENROL", render(&dl15::IDM_ACP_OAUTH2_ACCOUNT_ENROL));
 println!("{}\t{}", "dl15/IDM_ACP_OAUTH2_CLIENT_ADMIN", render(&dl15::IDM_ACP_OAUTH2_CLIENT_ADMIN));
 println!("{}\t{}", "dl15/IDM_ACP_OAUTH2_MANAGE", render(&dl15::IDM_ACP_OAUTH2_MANAGE));
 println!("{}\t{}", "dl15/IDM_ACP_OAUTH2_MANAGE_BASIC", render(&dl15::IDM_ACP_OAUTH2_MANAGE_BASIC));
 println!("{}\t{}", "dl15/IDM_ACP_PEOPLE_CREATE_DL6", render(&dl15::IDM_ACP_PEOPLE_CREATE_DL6));
 println!("{}\t{}", "dl15/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1", render(&dl15::IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1));
 println!("{}\t{}", "dl15/IDM_ACP_PEOPLE_DELETE_V1", render(&dl15::IDM_ACP_PEOPLE_DELETE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_PEOPLE_MANAGE_V1", render(&dl15::IDM_ACP_PEOPLE_MANAGE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_PEOPLE_PII_MANAGE_V1", render(&dl15::IDM_ACP_PEOPLE_PII_MANAGE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_PEOPLE_PII_READ_V1", render(&dl15::IDM_ACP_PEOPLE_PII_READ_V1));
 println!("{}\t{}", "dl15/IDM_ACP_PEOPLE_READ_V1", render(&dl15::IDM_ACP_PEOPLE_READ_V1));
 println!("{}\t{}", "dl15/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1", render(&dl15::IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1));
 println!("{}\t{}", "dl15/IDM_ACP_RADIUS_SECRET_MANAGE_V1", render(&dl15::IDM_ACP_RADIUS_SECRET_MANAGE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_RADIUS_SERVERS_V1", render(&dl15::IDM_ACP_RADIUS_SERVERS_V1));
 println!("{}\t{}", "dl15/IDM_ACP_RECYCLE_BIN_REVIVE_V1", render(&dl15::IDM_ACP_RECYCLE_BIN_REVIVE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_RECYCLE_BIN_SEARCH_V1", render(&dl15::IDM_ACP_RECYCLE_BIN_SEARCH_V1));
 println!("{}\t{}", "dl15/IDM_ACP_SCHEMA_WRITE_ATTRS_V1", render(&dl15::IDM_ACP_SCHEMA_WRITE_ATTRS_V1));
 println!("{}\t{}", "dl15/IDM_ACP_SCHEMA_WRITE_CLASSES_V1", render(&dl15::IDM_ACP_SCHEMA_WRITE_CLASSES_V1));
 println!("{}\t{}", "dl15/IDM_ACP_SELF_NAME_WRITE_DL7", render(&dl15::IDM_ACP_SELF_NAME_WRITE_DL7));
 println!("{}\t{}", "dl15/IDM_ACP_SELF_READ_DL8", render(&dl15::IDM_ACP_SELF_READ_DL8));
 println!("{}\t{}", "dl15/IDM_ACP_SELF_WRITE_DL8", render(&dl15::IDM_ACP_SELF_WRITE_DL8));
 println!("{}\t{}", "dl15/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1", render(&dl15::IDM_ACP_SERVICE_ACCOUNT_CREATE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1", render(&dl15::IDM_ACP_SERVICE_ACCOUNT_DELETE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl15::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl15/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1", render(&dl15::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl15/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1", render(&dl15::IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1", render(&dl15::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl15/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1", render(&dl15::IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_ACCOUNT_MAIL_READ_DL6", render(&dl_1_12::IDM_ACP_ACCOUNT_MAIL_READ_DL6));
 println!("{}\t{}", "dl_1_12/IDM_ACP_ACCOUNT_SELF_WRITE_V1", render(&dl_1_12::IDM_ACP_ACCOUNT_SELF_WRITE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1", render(&dl_1_12::IDM_ACP_ACCOUNT_UNIX_EXTEND_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_ACP_MANAGE_V1", render(&dl_1_12::IDM_ACP_ACP_MANAGE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1", render(&dl_1_12::IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8", render(&dl_1_12::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8));
 println!("{}\t{}", "dl_1_12/IDM_ACP_APPLICATION_MANAGE_DL8", render(&dl_1_12::IDM_ACP_APPLICATION_MANAGE_DL8));
 println!("{}\t{}", "dl_1_12/IDM_ACP_DOMAIN_ADMIN_DL9", render(&dl_1_12::IDM_ACP_DOMAIN_ADMIN_DL9));
 println!("{}\t{}", "dl_1_12/IDM_ACP_FEATURE_MANAGE", render(&dl_1_12::IDM_ACP_FEATURE_MANAGE));
 println!("{}\t{}", "dl_1_12/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8", render(&dl_1_12::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8));
 println!("{}\t{}", "dl_1_12/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl_1_12::IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_GROUP_ENTRY_MANAGER_V1", render(&dl_1_12::IDM_ACP_GROUP_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_GROUP_MANAGE_DL9", render(&dl_1_12::IDM_ACP_GROUP_MANAGE_DL9));
 println!("{}\t{}", "dl_1_12/IDM_ACP_GROUP_READ_V1", render(&dl_1_12::IDM_ACP_GROUP_READ_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_GROUP_UNIX_MANAGE_V1", render(&dl_1_12::IDM_ACP_GROUP_UNIX_MANAGE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7", render(&dl_1_12::IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7));
 println!("{}\t{}", "dl_1_12/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1", render(&dl_1_12::IDM_ACP_HP_GROUP_UNIX_MANAGE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1", render(&dl_1_12::IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl_1_12::IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_MAIL_SERVERS_DL8", render(&dl_1_12::IDM_ACP_MAIL_SERVERS_DL8));
 println!("{}\t{}", "dl_1_12/IDM_ACP_MESSAGE_MANAGE", render(&dl_1_12::IDM_ACP_MESSAGE_MANAGE));
 println!("{}\t{}", "dl_1_12/IDM_ACP_MESSAGE_SENDER", render(&dl_1_12::IDM_ACP_MESSAGE_SENDER));
 println!("{}\t{}", "dl_1_12/IDM_ACP_OAUTH2_ACCOUNT_ENROL", render(&dl_1_12::IDM_ACP_OAUTH2_ACCOUNT_ENROL));
 println!("{}\t{}", "dl_1_12/IDM_ACP_OAUTH2_CLIENT_ADMIN", render(&dl_1_12::IDM_ACP_OAUTH2_CLIENT_ADMIN));
 println!("{}\t{}", "dl_1_12/IDM_ACP_OAUTH2_MANAGE", render(&dl_1_12::IDM_ACP_OAUTH2_MANAGE));
 println!("{}\t{}", "dl_1_12/IDM_ACP_OAUTH2_MANAGE_BASIC", render(&dl_1_12::IDM_ACP_OAUTH2_MANAGE_BASIC));
 println!("{}\t{}", "dl_1_12/IDM_ACP_PEOPLE_CREATE_DL6", render(&dl_1_12::IDM_ACP_PEOPLE_CREATE_DL6));
 println!("{}\t{}", "dl_1_12/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1", render(&dl_1_12::IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_PEOPLE_DELETE_V1", render(&dl_1_12::IDM_ACP_PEOPLE_DELETE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_PEOPLE_MANAGE_V1", render(&dl_1_12::IDM_ACP_PEOPLE_MANAGE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_PEOPLE_PII_MANAGE_V1", render(&dl_1_12::IDM_ACP_PEOPLE_PII_MANAGE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_PEOPLE_PII_READ_V1", render(&dl_1_12::IDM_ACP_PEOPLE_PII_READ_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_PEOPLE_READ_V1", render(&dl_1_12::IDM_ACP_PEOPLE_READ_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1", render(&dl_1_12::IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_RADIUS_SECRET_MANAGE_V1", render(&dl_1_12::IDM_ACP_RADIUS_SECRET_MANAGE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_RADIUS_SERVERS_V1", render(&dl_1_12::IDM_ACP_RADIUS_SERVERS_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_RECYCLE_BIN_REVIVE_V1", render(&dl_1_12::IDM_ACP_RECYCLE_BIN_REVIVE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_RECYCLE_BIN_SEARCH_V1", render(&dl_1_12::IDM_ACP_RECYCLE_BIN_SEARCH_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SCHEMA_WRITE_ATTRS_V1", render(&dl_1_12::IDM_ACP_SCHEMA_WRITE_ATTRS_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SCHEMA_WRITE_CLASSES_V1", render(&dl_1_12::IDM_ACP_SCHEMA_WRITE_CLASSES_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SELF_NAME_WRITE_DL7", render(&dl_1_12::IDM_ACP_SELF_NAME_WRITE_DL7));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SELF_READ_DL8", render(&dl_1_12::IDM_ACP_SELF_READ_DL8));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SELF_WRITE_DL8", render(&dl_1_12::IDM_ACP_SELF_WRITE_DL8));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1", render(&dl_1_12::IDM_ACP_SERVICE_ACCOUNT_CREATE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1", render(&dl_1_12::IDM_ACP_SERVICE_ACCOUNT_DELETE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1", render(&dl_1_12::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1", render(&dl_1_12::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1", render(&dl_1_12::IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1", render(&dl_1_12::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1));
 println!("{}\t{}", "dl_1_12/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1", render(&dl_1_12::IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1));
}

fn observe(v:&BuiltinAcp)->kanidm_kernel::acp_catalog::Profile {
 let (receiver,groups)=match &v.receiver {BuiltinAcpReceiver::None=>(0,vec![]),BuiltinAcpReceiver::Group(xs)=>(1,xs.iter().map(|x|x.0).collect()),BuiltinAcpReceiver::EntryManager=>(2,vec![])};
 let mut target=vec![];if let BuiltinAcpTarget::Filter(f)=&v.target{filter_bytes(f,&mut target)};
 kanidm_kernel::acp_catalog::Profile {classes:v.classes.iter().map(|x|x.0).collect(),name:v.name.as_bytes().to_vec(),uuid:v.uuid.0,description:v.description.as_bytes().to_vec(),receiver,groups,target,
search_attrs:v.search_attrs.iter().map(|x|x.0).collect(),
modify_present_attrs:v.modify_present_attrs.iter().map(|x|x.0).collect(),
modify_removed_attrs:v.modify_removed_attrs.iter().map(|x|x.0).collect(),
modify_classes:v.modify_classes.iter().map(|x|x.0).collect(),
modify_present_classes:v.modify_present_classes.iter().map(|x|x.0).collect(),
modify_remove_classes:v.modify_remove_classes.iter().map(|x|x.0).collect(),
create_classes:v.create_classes.iter().map(|x|x.0).collect(),
create_attrs:v.create_attrs.iter().map(|x|x.0).collect(),
}
}
pub fn profiles()->Vec<(&'static str,kanidm_kernel::acp_catalog::Profile)>{vec![
("dl11/IDM_ACP_ACCOUNT_MAIL_READ_DL6",observe(&dl11::IDM_ACP_ACCOUNT_MAIL_READ_DL6)),
("dl11/IDM_ACP_ACCOUNT_SELF_WRITE_V1",observe(&dl11::IDM_ACP_ACCOUNT_SELF_WRITE_V1)),
("dl11/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1",observe(&dl11::IDM_ACP_ACCOUNT_UNIX_EXTEND_V1)),
("dl11/IDM_ACP_ACP_MANAGE_V1",observe(&dl11::IDM_ACP_ACP_MANAGE_V1)),
("dl11/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1",observe(&dl11::IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1)),
("dl11/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8",observe(&dl11::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8)),
("dl11/IDM_ACP_APPLICATION_MANAGE_DL8",observe(&dl11::IDM_ACP_APPLICATION_MANAGE_DL8)),
("dl11/IDM_ACP_DOMAIN_ADMIN_DL9",observe(&dl11::IDM_ACP_DOMAIN_ADMIN_DL9)),
("dl11/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8",observe(&dl11::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8)),
("dl11/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl11::IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl11/IDM_ACP_GROUP_ENTRY_MANAGER_V1",observe(&dl11::IDM_ACP_GROUP_ENTRY_MANAGER_V1)),
("dl11/IDM_ACP_GROUP_MANAGE_DL9",observe(&dl11::IDM_ACP_GROUP_MANAGE_DL9)),
("dl11/IDM_ACP_GROUP_READ_V1",observe(&dl11::IDM_ACP_GROUP_READ_V1)),
("dl11/IDM_ACP_GROUP_UNIX_MANAGE_V1",observe(&dl11::IDM_ACP_GROUP_UNIX_MANAGE_V1)),
("dl11/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7",observe(&dl11::IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7)),
("dl11/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1",observe(&dl11::IDM_ACP_HP_GROUP_UNIX_MANAGE_V1)),
("dl11/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1",observe(&dl11::IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1)),
("dl11/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl11::IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl11/IDM_ACP_MAIL_SERVERS_DL8",observe(&dl11::IDM_ACP_MAIL_SERVERS_DL8)),
("dl11/IDM_ACP_OAUTH2_MANAGE",observe(&dl11::IDM_ACP_OAUTH2_MANAGE)),
("dl11/IDM_ACP_PEOPLE_CREATE_DL6",observe(&dl11::IDM_ACP_PEOPLE_CREATE_DL6)),
("dl11/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1",observe(&dl11::IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1)),
("dl11/IDM_ACP_PEOPLE_DELETE_V1",observe(&dl11::IDM_ACP_PEOPLE_DELETE_V1)),
("dl11/IDM_ACP_PEOPLE_MANAGE_V1",observe(&dl11::IDM_ACP_PEOPLE_MANAGE_V1)),
("dl11/IDM_ACP_PEOPLE_PII_MANAGE_V1",observe(&dl11::IDM_ACP_PEOPLE_PII_MANAGE_V1)),
("dl11/IDM_ACP_PEOPLE_PII_READ_V1",observe(&dl11::IDM_ACP_PEOPLE_PII_READ_V1)),
("dl11/IDM_ACP_PEOPLE_READ_V1",observe(&dl11::IDM_ACP_PEOPLE_READ_V1)),
("dl11/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1",observe(&dl11::IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1)),
("dl11/IDM_ACP_RADIUS_SECRET_MANAGE_V1",observe(&dl11::IDM_ACP_RADIUS_SECRET_MANAGE_V1)),
("dl11/IDM_ACP_RADIUS_SERVERS_V1",observe(&dl11::IDM_ACP_RADIUS_SERVERS_V1)),
("dl11/IDM_ACP_RECYCLE_BIN_REVIVE_V1",observe(&dl11::IDM_ACP_RECYCLE_BIN_REVIVE_V1)),
("dl11/IDM_ACP_RECYCLE_BIN_SEARCH_V1",observe(&dl11::IDM_ACP_RECYCLE_BIN_SEARCH_V1)),
("dl11/IDM_ACP_SCHEMA_WRITE_ATTRS_V1",observe(&dl11::IDM_ACP_SCHEMA_WRITE_ATTRS_V1)),
("dl11/IDM_ACP_SCHEMA_WRITE_CLASSES_V1",observe(&dl11::IDM_ACP_SCHEMA_WRITE_CLASSES_V1)),
("dl11/IDM_ACP_SELF_NAME_WRITE_DL7",observe(&dl11::IDM_ACP_SELF_NAME_WRITE_DL7)),
("dl11/IDM_ACP_SELF_READ_DL8",observe(&dl11::IDM_ACP_SELF_READ_DL8)),
("dl11/IDM_ACP_SELF_WRITE_DL8",observe(&dl11::IDM_ACP_SELF_WRITE_DL8)),
("dl11/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1",observe(&dl11::IDM_ACP_SERVICE_ACCOUNT_CREATE_V1)),
("dl11/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1",observe(&dl11::IDM_ACP_SERVICE_ACCOUNT_DELETE_V1)),
("dl11/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl11::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl11/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1",observe(&dl11::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1)),
("dl11/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1",observe(&dl11::IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1)),
("dl11/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1",observe(&dl11::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1)),
("dl11/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1",observe(&dl11::IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1)),
("dl12/IDM_ACP_ACCOUNT_MAIL_READ_DL6",observe(&dl12::IDM_ACP_ACCOUNT_MAIL_READ_DL6)),
("dl12/IDM_ACP_ACCOUNT_SELF_WRITE_V1",observe(&dl12::IDM_ACP_ACCOUNT_SELF_WRITE_V1)),
("dl12/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1",observe(&dl12::IDM_ACP_ACCOUNT_UNIX_EXTEND_V1)),
("dl12/IDM_ACP_ACP_MANAGE_V1",observe(&dl12::IDM_ACP_ACP_MANAGE_V1)),
("dl12/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1",observe(&dl12::IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1)),
("dl12/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8",observe(&dl12::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8)),
("dl12/IDM_ACP_APPLICATION_MANAGE_DL8",observe(&dl12::IDM_ACP_APPLICATION_MANAGE_DL8)),
("dl12/IDM_ACP_DOMAIN_ADMIN_DL9",observe(&dl12::IDM_ACP_DOMAIN_ADMIN_DL9)),
("dl12/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8",observe(&dl12::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8)),
("dl12/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl12::IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl12/IDM_ACP_GROUP_ENTRY_MANAGER_V1",observe(&dl12::IDM_ACP_GROUP_ENTRY_MANAGER_V1)),
("dl12/IDM_ACP_GROUP_MANAGE_DL9",observe(&dl12::IDM_ACP_GROUP_MANAGE_DL9)),
("dl12/IDM_ACP_GROUP_READ_V1",observe(&dl12::IDM_ACP_GROUP_READ_V1)),
("dl12/IDM_ACP_GROUP_UNIX_MANAGE_V1",observe(&dl12::IDM_ACP_GROUP_UNIX_MANAGE_V1)),
("dl12/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7",observe(&dl12::IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7)),
("dl12/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1",observe(&dl12::IDM_ACP_HP_GROUP_UNIX_MANAGE_V1)),
("dl12/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1",observe(&dl12::IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1)),
("dl12/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl12::IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl12/IDM_ACP_MAIL_SERVERS_DL8",observe(&dl12::IDM_ACP_MAIL_SERVERS_DL8)),
("dl12/IDM_ACP_MESSAGE_MANAGE",observe(&dl12::IDM_ACP_MESSAGE_MANAGE)),
("dl12/IDM_ACP_MESSAGE_SENDER",observe(&dl12::IDM_ACP_MESSAGE_SENDER)),
("dl12/IDM_ACP_OAUTH2_ACCOUNT_ENROL",observe(&dl12::IDM_ACP_OAUTH2_ACCOUNT_ENROL)),
("dl12/IDM_ACP_OAUTH2_CLIENT_ADMIN",observe(&dl12::IDM_ACP_OAUTH2_CLIENT_ADMIN)),
("dl12/IDM_ACP_OAUTH2_MANAGE",observe(&dl12::IDM_ACP_OAUTH2_MANAGE)),
("dl12/IDM_ACP_PEOPLE_CREATE_DL6",observe(&dl12::IDM_ACP_PEOPLE_CREATE_DL6)),
("dl12/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1",observe(&dl12::IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1)),
("dl12/IDM_ACP_PEOPLE_DELETE_V1",observe(&dl12::IDM_ACP_PEOPLE_DELETE_V1)),
("dl12/IDM_ACP_PEOPLE_MANAGE_V1",observe(&dl12::IDM_ACP_PEOPLE_MANAGE_V1)),
("dl12/IDM_ACP_PEOPLE_PII_MANAGE_V1",observe(&dl12::IDM_ACP_PEOPLE_PII_MANAGE_V1)),
("dl12/IDM_ACP_PEOPLE_PII_READ_V1",observe(&dl12::IDM_ACP_PEOPLE_PII_READ_V1)),
("dl12/IDM_ACP_PEOPLE_READ_V1",observe(&dl12::IDM_ACP_PEOPLE_READ_V1)),
("dl12/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1",observe(&dl12::IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1)),
("dl12/IDM_ACP_RADIUS_SECRET_MANAGE_V1",observe(&dl12::IDM_ACP_RADIUS_SECRET_MANAGE_V1)),
("dl12/IDM_ACP_RADIUS_SERVERS_V1",observe(&dl12::IDM_ACP_RADIUS_SERVERS_V1)),
("dl12/IDM_ACP_RECYCLE_BIN_REVIVE_V1",observe(&dl12::IDM_ACP_RECYCLE_BIN_REVIVE_V1)),
("dl12/IDM_ACP_RECYCLE_BIN_SEARCH_V1",observe(&dl12::IDM_ACP_RECYCLE_BIN_SEARCH_V1)),
("dl12/IDM_ACP_SCHEMA_WRITE_ATTRS_V1",observe(&dl12::IDM_ACP_SCHEMA_WRITE_ATTRS_V1)),
("dl12/IDM_ACP_SCHEMA_WRITE_CLASSES_V1",observe(&dl12::IDM_ACP_SCHEMA_WRITE_CLASSES_V1)),
("dl12/IDM_ACP_SELF_NAME_WRITE_DL7",observe(&dl12::IDM_ACP_SELF_NAME_WRITE_DL7)),
("dl12/IDM_ACP_SELF_READ_DL8",observe(&dl12::IDM_ACP_SELF_READ_DL8)),
("dl12/IDM_ACP_SELF_WRITE_DL8",observe(&dl12::IDM_ACP_SELF_WRITE_DL8)),
("dl12/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1",observe(&dl12::IDM_ACP_SERVICE_ACCOUNT_CREATE_V1)),
("dl12/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1",observe(&dl12::IDM_ACP_SERVICE_ACCOUNT_DELETE_V1)),
("dl12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl12::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1",observe(&dl12::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1)),
("dl12/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1",observe(&dl12::IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1)),
("dl12/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1",observe(&dl12::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1)),
("dl12/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1",observe(&dl12::IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1)),
("dl13/IDM_ACP_ACCOUNT_MAIL_READ_DL6",observe(&dl13::IDM_ACP_ACCOUNT_MAIL_READ_DL6)),
("dl13/IDM_ACP_ACCOUNT_SELF_WRITE_V1",observe(&dl13::IDM_ACP_ACCOUNT_SELF_WRITE_V1)),
("dl13/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1",observe(&dl13::IDM_ACP_ACCOUNT_UNIX_EXTEND_V1)),
("dl13/IDM_ACP_ACP_MANAGE_V1",observe(&dl13::IDM_ACP_ACP_MANAGE_V1)),
("dl13/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1",observe(&dl13::IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1)),
("dl13/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8",observe(&dl13::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8)),
("dl13/IDM_ACP_APPLICATION_MANAGE_DL8",observe(&dl13::IDM_ACP_APPLICATION_MANAGE_DL8)),
("dl13/IDM_ACP_DOMAIN_ADMIN_DL9",observe(&dl13::IDM_ACP_DOMAIN_ADMIN_DL9)),
("dl13/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8",observe(&dl13::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8)),
("dl13/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl13::IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl13/IDM_ACP_GROUP_ENTRY_MANAGER_V1",observe(&dl13::IDM_ACP_GROUP_ENTRY_MANAGER_V1)),
("dl13/IDM_ACP_GROUP_MANAGE_DL9",observe(&dl13::IDM_ACP_GROUP_MANAGE_DL9)),
("dl13/IDM_ACP_GROUP_READ_V1",observe(&dl13::IDM_ACP_GROUP_READ_V1)),
("dl13/IDM_ACP_GROUP_UNIX_MANAGE_V1",observe(&dl13::IDM_ACP_GROUP_UNIX_MANAGE_V1)),
("dl13/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7",observe(&dl13::IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7)),
("dl13/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1",observe(&dl13::IDM_ACP_HP_GROUP_UNIX_MANAGE_V1)),
("dl13/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1",observe(&dl13::IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1)),
("dl13/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl13::IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl13/IDM_ACP_MAIL_SERVERS_DL8",observe(&dl13::IDM_ACP_MAIL_SERVERS_DL8)),
("dl13/IDM_ACP_MESSAGE_MANAGE",observe(&dl13::IDM_ACP_MESSAGE_MANAGE)),
("dl13/IDM_ACP_MESSAGE_SENDER",observe(&dl13::IDM_ACP_MESSAGE_SENDER)),
("dl13/IDM_ACP_OAUTH2_ACCOUNT_ENROL",observe(&dl13::IDM_ACP_OAUTH2_ACCOUNT_ENROL)),
("dl13/IDM_ACP_OAUTH2_CLIENT_ADMIN",observe(&dl13::IDM_ACP_OAUTH2_CLIENT_ADMIN)),
("dl13/IDM_ACP_OAUTH2_MANAGE",observe(&dl13::IDM_ACP_OAUTH2_MANAGE)),
("dl13/IDM_ACP_OAUTH2_MANAGE_BASIC",observe(&dl13::IDM_ACP_OAUTH2_MANAGE_BASIC)),
("dl13/IDM_ACP_PEOPLE_CREATE_DL6",observe(&dl13::IDM_ACP_PEOPLE_CREATE_DL6)),
("dl13/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1",observe(&dl13::IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1)),
("dl13/IDM_ACP_PEOPLE_DELETE_V1",observe(&dl13::IDM_ACP_PEOPLE_DELETE_V1)),
("dl13/IDM_ACP_PEOPLE_MANAGE_V1",observe(&dl13::IDM_ACP_PEOPLE_MANAGE_V1)),
("dl13/IDM_ACP_PEOPLE_PII_MANAGE_V1",observe(&dl13::IDM_ACP_PEOPLE_PII_MANAGE_V1)),
("dl13/IDM_ACP_PEOPLE_PII_READ_V1",observe(&dl13::IDM_ACP_PEOPLE_PII_READ_V1)),
("dl13/IDM_ACP_PEOPLE_READ_V1",observe(&dl13::IDM_ACP_PEOPLE_READ_V1)),
("dl13/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1",observe(&dl13::IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1)),
("dl13/IDM_ACP_RADIUS_SECRET_MANAGE_V1",observe(&dl13::IDM_ACP_RADIUS_SECRET_MANAGE_V1)),
("dl13/IDM_ACP_RADIUS_SERVERS_V1",observe(&dl13::IDM_ACP_RADIUS_SERVERS_V1)),
("dl13/IDM_ACP_RECYCLE_BIN_REVIVE_V1",observe(&dl13::IDM_ACP_RECYCLE_BIN_REVIVE_V1)),
("dl13/IDM_ACP_RECYCLE_BIN_SEARCH_V1",observe(&dl13::IDM_ACP_RECYCLE_BIN_SEARCH_V1)),
("dl13/IDM_ACP_SCHEMA_WRITE_ATTRS_V1",observe(&dl13::IDM_ACP_SCHEMA_WRITE_ATTRS_V1)),
("dl13/IDM_ACP_SCHEMA_WRITE_CLASSES_V1",observe(&dl13::IDM_ACP_SCHEMA_WRITE_CLASSES_V1)),
("dl13/IDM_ACP_SELF_NAME_WRITE_DL7",observe(&dl13::IDM_ACP_SELF_NAME_WRITE_DL7)),
("dl13/IDM_ACP_SELF_READ_DL8",observe(&dl13::IDM_ACP_SELF_READ_DL8)),
("dl13/IDM_ACP_SELF_WRITE_DL8",observe(&dl13::IDM_ACP_SELF_WRITE_DL8)),
("dl13/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1",observe(&dl13::IDM_ACP_SERVICE_ACCOUNT_CREATE_V1)),
("dl13/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1",observe(&dl13::IDM_ACP_SERVICE_ACCOUNT_DELETE_V1)),
("dl13/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl13::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl13/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1",observe(&dl13::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1)),
("dl13/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1",observe(&dl13::IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1)),
("dl13/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1",observe(&dl13::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1)),
("dl13/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1",observe(&dl13::IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1)),
("dl14/IDM_ACP_ACCOUNT_MAIL_READ_DL6",observe(&dl14::IDM_ACP_ACCOUNT_MAIL_READ_DL6)),
("dl14/IDM_ACP_ACCOUNT_SELF_WRITE_V1",observe(&dl14::IDM_ACP_ACCOUNT_SELF_WRITE_V1)),
("dl14/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1",observe(&dl14::IDM_ACP_ACCOUNT_UNIX_EXTEND_V1)),
("dl14/IDM_ACP_ACP_MANAGE_V1",observe(&dl14::IDM_ACP_ACP_MANAGE_V1)),
("dl14/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1",observe(&dl14::IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1)),
("dl14/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8",observe(&dl14::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8)),
("dl14/IDM_ACP_APPLICATION_MANAGE_DL8",observe(&dl14::IDM_ACP_APPLICATION_MANAGE_DL8)),
("dl14/IDM_ACP_DOMAIN_ADMIN_DL9",observe(&dl14::IDM_ACP_DOMAIN_ADMIN_DL9)),
("dl14/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8",observe(&dl14::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8)),
("dl14/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl14::IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl14/IDM_ACP_GROUP_ENTRY_MANAGER_V1",observe(&dl14::IDM_ACP_GROUP_ENTRY_MANAGER_V1)),
("dl14/IDM_ACP_GROUP_MANAGE_DL9",observe(&dl14::IDM_ACP_GROUP_MANAGE_DL9)),
("dl14/IDM_ACP_GROUP_READ_V1",observe(&dl14::IDM_ACP_GROUP_READ_V1)),
("dl14/IDM_ACP_GROUP_UNIX_MANAGE_V1",observe(&dl14::IDM_ACP_GROUP_UNIX_MANAGE_V1)),
("dl14/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7",observe(&dl14::IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7)),
("dl14/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1",observe(&dl14::IDM_ACP_HP_GROUP_UNIX_MANAGE_V1)),
("dl14/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1",observe(&dl14::IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1)),
("dl14/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl14::IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl14/IDM_ACP_MAIL_SERVERS_DL8",observe(&dl14::IDM_ACP_MAIL_SERVERS_DL8)),
("dl14/IDM_ACP_MESSAGE_MANAGE",observe(&dl14::IDM_ACP_MESSAGE_MANAGE)),
("dl14/IDM_ACP_MESSAGE_SENDER",observe(&dl14::IDM_ACP_MESSAGE_SENDER)),
("dl14/IDM_ACP_OAUTH2_ACCOUNT_ENROL",observe(&dl14::IDM_ACP_OAUTH2_ACCOUNT_ENROL)),
("dl14/IDM_ACP_OAUTH2_CLIENT_ADMIN",observe(&dl14::IDM_ACP_OAUTH2_CLIENT_ADMIN)),
("dl14/IDM_ACP_OAUTH2_MANAGE",observe(&dl14::IDM_ACP_OAUTH2_MANAGE)),
("dl14/IDM_ACP_OAUTH2_MANAGE_BASIC",observe(&dl14::IDM_ACP_OAUTH2_MANAGE_BASIC)),
("dl14/IDM_ACP_PEOPLE_CREATE_DL6",observe(&dl14::IDM_ACP_PEOPLE_CREATE_DL6)),
("dl14/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1",observe(&dl14::IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1)),
("dl14/IDM_ACP_PEOPLE_DELETE_V1",observe(&dl14::IDM_ACP_PEOPLE_DELETE_V1)),
("dl14/IDM_ACP_PEOPLE_MANAGE_V1",observe(&dl14::IDM_ACP_PEOPLE_MANAGE_V1)),
("dl14/IDM_ACP_PEOPLE_PII_MANAGE_V1",observe(&dl14::IDM_ACP_PEOPLE_PII_MANAGE_V1)),
("dl14/IDM_ACP_PEOPLE_PII_READ_V1",observe(&dl14::IDM_ACP_PEOPLE_PII_READ_V1)),
("dl14/IDM_ACP_PEOPLE_READ_V1",observe(&dl14::IDM_ACP_PEOPLE_READ_V1)),
("dl14/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1",observe(&dl14::IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1)),
("dl14/IDM_ACP_RADIUS_SECRET_MANAGE_V1",observe(&dl14::IDM_ACP_RADIUS_SECRET_MANAGE_V1)),
("dl14/IDM_ACP_RADIUS_SERVERS_V1",observe(&dl14::IDM_ACP_RADIUS_SERVERS_V1)),
("dl14/IDM_ACP_RECYCLE_BIN_REVIVE_V1",observe(&dl14::IDM_ACP_RECYCLE_BIN_REVIVE_V1)),
("dl14/IDM_ACP_RECYCLE_BIN_SEARCH_V1",observe(&dl14::IDM_ACP_RECYCLE_BIN_SEARCH_V1)),
("dl14/IDM_ACP_SCHEMA_WRITE_ATTRS_V1",observe(&dl14::IDM_ACP_SCHEMA_WRITE_ATTRS_V1)),
("dl14/IDM_ACP_SCHEMA_WRITE_CLASSES_V1",observe(&dl14::IDM_ACP_SCHEMA_WRITE_CLASSES_V1)),
("dl14/IDM_ACP_SELF_NAME_WRITE_DL7",observe(&dl14::IDM_ACP_SELF_NAME_WRITE_DL7)),
("dl14/IDM_ACP_SELF_READ_DL8",observe(&dl14::IDM_ACP_SELF_READ_DL8)),
("dl14/IDM_ACP_SELF_WRITE_DL8",observe(&dl14::IDM_ACP_SELF_WRITE_DL8)),
("dl14/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1",observe(&dl14::IDM_ACP_SERVICE_ACCOUNT_CREATE_V1)),
("dl14/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1",observe(&dl14::IDM_ACP_SERVICE_ACCOUNT_DELETE_V1)),
("dl14/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl14::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl14/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1",observe(&dl14::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1)),
("dl14/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1",observe(&dl14::IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1)),
("dl14/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1",observe(&dl14::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1)),
("dl14/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1",observe(&dl14::IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1)),
("dl15/IDM_ACP_ACCOUNT_MAIL_READ_DL6",observe(&dl15::IDM_ACP_ACCOUNT_MAIL_READ_DL6)),
("dl15/IDM_ACP_ACCOUNT_SELF_WRITE_V1",observe(&dl15::IDM_ACP_ACCOUNT_SELF_WRITE_V1)),
("dl15/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1",observe(&dl15::IDM_ACP_ACCOUNT_UNIX_EXTEND_V1)),
("dl15/IDM_ACP_ACP_MANAGE_V1",observe(&dl15::IDM_ACP_ACP_MANAGE_V1)),
("dl15/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1",observe(&dl15::IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1)),
("dl15/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8",observe(&dl15::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8)),
("dl15/IDM_ACP_APPLICATION_MANAGE_DL8",observe(&dl15::IDM_ACP_APPLICATION_MANAGE_DL8)),
("dl15/IDM_ACP_DOMAIN_ADMIN_DL9",observe(&dl15::IDM_ACP_DOMAIN_ADMIN_DL9)),
("dl15/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8",observe(&dl15::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8)),
("dl15/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl15::IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl15/IDM_ACP_GROUP_ENTRY_MANAGER_V1",observe(&dl15::IDM_ACP_GROUP_ENTRY_MANAGER_V1)),
("dl15/IDM_ACP_GROUP_MANAGE_DL9",observe(&dl15::IDM_ACP_GROUP_MANAGE_DL9)),
("dl15/IDM_ACP_GROUP_READ_V1",observe(&dl15::IDM_ACP_GROUP_READ_V1)),
("dl15/IDM_ACP_GROUP_UNIX_MANAGE_V1",observe(&dl15::IDM_ACP_GROUP_UNIX_MANAGE_V1)),
("dl15/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7",observe(&dl15::IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7)),
("dl15/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1",observe(&dl15::IDM_ACP_HP_GROUP_UNIX_MANAGE_V1)),
("dl15/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1",observe(&dl15::IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1)),
("dl15/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl15::IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl15/IDM_ACP_MAIL_SERVERS_DL8",observe(&dl15::IDM_ACP_MAIL_SERVERS_DL8)),
("dl15/IDM_ACP_MESSAGE_MANAGE",observe(&dl15::IDM_ACP_MESSAGE_MANAGE)),
("dl15/IDM_ACP_MESSAGE_SENDER",observe(&dl15::IDM_ACP_MESSAGE_SENDER)),
("dl15/IDM_ACP_OAUTH2_ACCOUNT_ENROL",observe(&dl15::IDM_ACP_OAUTH2_ACCOUNT_ENROL)),
("dl15/IDM_ACP_OAUTH2_CLIENT_ADMIN",observe(&dl15::IDM_ACP_OAUTH2_CLIENT_ADMIN)),
("dl15/IDM_ACP_OAUTH2_MANAGE",observe(&dl15::IDM_ACP_OAUTH2_MANAGE)),
("dl15/IDM_ACP_OAUTH2_MANAGE_BASIC",observe(&dl15::IDM_ACP_OAUTH2_MANAGE_BASIC)),
("dl15/IDM_ACP_PEOPLE_CREATE_DL6",observe(&dl15::IDM_ACP_PEOPLE_CREATE_DL6)),
("dl15/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1",observe(&dl15::IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1)),
("dl15/IDM_ACP_PEOPLE_DELETE_V1",observe(&dl15::IDM_ACP_PEOPLE_DELETE_V1)),
("dl15/IDM_ACP_PEOPLE_MANAGE_V1",observe(&dl15::IDM_ACP_PEOPLE_MANAGE_V1)),
("dl15/IDM_ACP_PEOPLE_PII_MANAGE_V1",observe(&dl15::IDM_ACP_PEOPLE_PII_MANAGE_V1)),
("dl15/IDM_ACP_PEOPLE_PII_READ_V1",observe(&dl15::IDM_ACP_PEOPLE_PII_READ_V1)),
("dl15/IDM_ACP_PEOPLE_READ_V1",observe(&dl15::IDM_ACP_PEOPLE_READ_V1)),
("dl15/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1",observe(&dl15::IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1)),
("dl15/IDM_ACP_RADIUS_SECRET_MANAGE_V1",observe(&dl15::IDM_ACP_RADIUS_SECRET_MANAGE_V1)),
("dl15/IDM_ACP_RADIUS_SERVERS_V1",observe(&dl15::IDM_ACP_RADIUS_SERVERS_V1)),
("dl15/IDM_ACP_RECYCLE_BIN_REVIVE_V1",observe(&dl15::IDM_ACP_RECYCLE_BIN_REVIVE_V1)),
("dl15/IDM_ACP_RECYCLE_BIN_SEARCH_V1",observe(&dl15::IDM_ACP_RECYCLE_BIN_SEARCH_V1)),
("dl15/IDM_ACP_SCHEMA_WRITE_ATTRS_V1",observe(&dl15::IDM_ACP_SCHEMA_WRITE_ATTRS_V1)),
("dl15/IDM_ACP_SCHEMA_WRITE_CLASSES_V1",observe(&dl15::IDM_ACP_SCHEMA_WRITE_CLASSES_V1)),
("dl15/IDM_ACP_SELF_NAME_WRITE_DL7",observe(&dl15::IDM_ACP_SELF_NAME_WRITE_DL7)),
("dl15/IDM_ACP_SELF_READ_DL8",observe(&dl15::IDM_ACP_SELF_READ_DL8)),
("dl15/IDM_ACP_SELF_WRITE_DL8",observe(&dl15::IDM_ACP_SELF_WRITE_DL8)),
("dl15/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1",observe(&dl15::IDM_ACP_SERVICE_ACCOUNT_CREATE_V1)),
("dl15/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1",observe(&dl15::IDM_ACP_SERVICE_ACCOUNT_DELETE_V1)),
("dl15/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl15::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl15/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1",observe(&dl15::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1)),
("dl15/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1",observe(&dl15::IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1)),
("dl15/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1",observe(&dl15::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1)),
("dl15/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1",observe(&dl15::IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1)),
("dl_1_12/IDM_ACP_ACCOUNT_MAIL_READ_DL6",observe(&dl_1_12::IDM_ACP_ACCOUNT_MAIL_READ_DL6)),
("dl_1_12/IDM_ACP_ACCOUNT_SELF_WRITE_V1",observe(&dl_1_12::IDM_ACP_ACCOUNT_SELF_WRITE_V1)),
("dl_1_12/IDM_ACP_ACCOUNT_UNIX_EXTEND_V1",observe(&dl_1_12::IDM_ACP_ACCOUNT_UNIX_EXTEND_V1)),
("dl_1_12/IDM_ACP_ACP_MANAGE_V1",observe(&dl_1_12::IDM_ACP_ACP_MANAGE_V1)),
("dl_1_12/IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1",observe(&dl_1_12::IDM_ACP_ALL_ACCOUNTS_POSIX_READ_V1)),
("dl_1_12/IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8",observe(&dl_1_12::IDM_ACP_APPLICATION_ENTRY_MANAGER_DL8)),
("dl_1_12/IDM_ACP_APPLICATION_MANAGE_DL8",observe(&dl_1_12::IDM_ACP_APPLICATION_MANAGE_DL8)),
("dl_1_12/IDM_ACP_DOMAIN_ADMIN_DL9",observe(&dl_1_12::IDM_ACP_DOMAIN_ADMIN_DL9)),
("dl_1_12/IDM_ACP_FEATURE_MANAGE",observe(&dl_1_12::IDM_ACP_FEATURE_MANAGE)),
("dl_1_12/IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8",observe(&dl_1_12::IDM_ACP_GROUP_ACCOUNT_POLICY_MANAGE_DL8)),
("dl_1_12/IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl_1_12::IDM_ACP_GROUP_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl_1_12/IDM_ACP_GROUP_ENTRY_MANAGER_V1",observe(&dl_1_12::IDM_ACP_GROUP_ENTRY_MANAGER_V1)),
("dl_1_12/IDM_ACP_GROUP_MANAGE_DL9",observe(&dl_1_12::IDM_ACP_GROUP_MANAGE_DL9)),
("dl_1_12/IDM_ACP_GROUP_READ_V1",observe(&dl_1_12::IDM_ACP_GROUP_READ_V1)),
("dl_1_12/IDM_ACP_GROUP_UNIX_MANAGE_V1",observe(&dl_1_12::IDM_ACP_GROUP_UNIX_MANAGE_V1)),
("dl_1_12/IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7",observe(&dl_1_12::IDM_ACP_HP_CLIENT_CERTIFICATE_MANAGER_DL7)),
("dl_1_12/IDM_ACP_HP_GROUP_UNIX_MANAGE_V1",observe(&dl_1_12::IDM_ACP_HP_GROUP_UNIX_MANAGE_V1)),
("dl_1_12/IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1",observe(&dl_1_12::IDM_ACP_HP_PEOPLE_CREDENTIAL_RESET_V1)),
("dl_1_12/IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl_1_12::IDM_ACP_HP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl_1_12/IDM_ACP_MAIL_SERVERS_DL8",observe(&dl_1_12::IDM_ACP_MAIL_SERVERS_DL8)),
("dl_1_12/IDM_ACP_MESSAGE_MANAGE",observe(&dl_1_12::IDM_ACP_MESSAGE_MANAGE)),
("dl_1_12/IDM_ACP_MESSAGE_SENDER",observe(&dl_1_12::IDM_ACP_MESSAGE_SENDER)),
("dl_1_12/IDM_ACP_OAUTH2_ACCOUNT_ENROL",observe(&dl_1_12::IDM_ACP_OAUTH2_ACCOUNT_ENROL)),
("dl_1_12/IDM_ACP_OAUTH2_CLIENT_ADMIN",observe(&dl_1_12::IDM_ACP_OAUTH2_CLIENT_ADMIN)),
("dl_1_12/IDM_ACP_OAUTH2_MANAGE",observe(&dl_1_12::IDM_ACP_OAUTH2_MANAGE)),
("dl_1_12/IDM_ACP_OAUTH2_MANAGE_BASIC",observe(&dl_1_12::IDM_ACP_OAUTH2_MANAGE_BASIC)),
("dl_1_12/IDM_ACP_PEOPLE_CREATE_DL6",observe(&dl_1_12::IDM_ACP_PEOPLE_CREATE_DL6)),
("dl_1_12/IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1",observe(&dl_1_12::IDM_ACP_PEOPLE_CREDENTIAL_RESET_V1)),
("dl_1_12/IDM_ACP_PEOPLE_DELETE_V1",observe(&dl_1_12::IDM_ACP_PEOPLE_DELETE_V1)),
("dl_1_12/IDM_ACP_PEOPLE_MANAGE_V1",observe(&dl_1_12::IDM_ACP_PEOPLE_MANAGE_V1)),
("dl_1_12/IDM_ACP_PEOPLE_PII_MANAGE_V1",observe(&dl_1_12::IDM_ACP_PEOPLE_PII_MANAGE_V1)),
("dl_1_12/IDM_ACP_PEOPLE_PII_READ_V1",observe(&dl_1_12::IDM_ACP_PEOPLE_PII_READ_V1)),
("dl_1_12/IDM_ACP_PEOPLE_READ_V1",observe(&dl_1_12::IDM_ACP_PEOPLE_READ_V1)),
("dl_1_12/IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1",observe(&dl_1_12::IDM_ACP_PEOPLE_SELF_WRITE_MAIL_V1)),
("dl_1_12/IDM_ACP_RADIUS_SECRET_MANAGE_V1",observe(&dl_1_12::IDM_ACP_RADIUS_SECRET_MANAGE_V1)),
("dl_1_12/IDM_ACP_RADIUS_SERVERS_V1",observe(&dl_1_12::IDM_ACP_RADIUS_SERVERS_V1)),
("dl_1_12/IDM_ACP_RECYCLE_BIN_REVIVE_V1",observe(&dl_1_12::IDM_ACP_RECYCLE_BIN_REVIVE_V1)),
("dl_1_12/IDM_ACP_RECYCLE_BIN_SEARCH_V1",observe(&dl_1_12::IDM_ACP_RECYCLE_BIN_SEARCH_V1)),
("dl_1_12/IDM_ACP_SCHEMA_WRITE_ATTRS_V1",observe(&dl_1_12::IDM_ACP_SCHEMA_WRITE_ATTRS_V1)),
("dl_1_12/IDM_ACP_SCHEMA_WRITE_CLASSES_V1",observe(&dl_1_12::IDM_ACP_SCHEMA_WRITE_CLASSES_V1)),
("dl_1_12/IDM_ACP_SELF_NAME_WRITE_DL7",observe(&dl_1_12::IDM_ACP_SELF_NAME_WRITE_DL7)),
("dl_1_12/IDM_ACP_SELF_READ_DL8",observe(&dl_1_12::IDM_ACP_SELF_READ_DL8)),
("dl_1_12/IDM_ACP_SELF_WRITE_DL8",observe(&dl_1_12::IDM_ACP_SELF_WRITE_DL8)),
("dl_1_12/IDM_ACP_SERVICE_ACCOUNT_CREATE_V1",observe(&dl_1_12::IDM_ACP_SERVICE_ACCOUNT_CREATE_V1)),
("dl_1_12/IDM_ACP_SERVICE_ACCOUNT_DELETE_V1",observe(&dl_1_12::IDM_ACP_SERVICE_ACCOUNT_DELETE_V1)),
("dl_1_12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1",observe(&dl_1_12::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGED_BY_MODIFY_V1)),
("dl_1_12/IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1",observe(&dl_1_12::IDM_ACP_SERVICE_ACCOUNT_ENTRY_MANAGER_V1)),
("dl_1_12/IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1",observe(&dl_1_12::IDM_ACP_SERVICE_ACCOUNT_MANAGE_V1)),
("dl_1_12/IDM_ACP_SYNC_ACCOUNT_MANAGE_V1",observe(&dl_1_12::IDM_ACP_SYNC_ACCOUNT_MANAGE_V1)),
("dl_1_12/IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1",observe(&dl_1_12::IDM_ACP_SYSTEM_CONFIG_ACCOUNT_POLICY_MANAGE_V1)),
]}
