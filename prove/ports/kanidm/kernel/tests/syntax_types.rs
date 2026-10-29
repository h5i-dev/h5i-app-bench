#![allow(dead_code)]
use kanidm_kernel::syntax_types as port;
#[allow(non_camel_case_types,unused_imports)]
mod reference {include!("../../difftest/syntax_types/reference.rs");}
#[test] fn pinned_syntax_metadata(){
let mut comparisons=0;
{let a=reference::SyntaxType::Utf8String;let b=port::SyntaxType::Utf8String;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Utf8StringInsensitive;let b=port::SyntaxType::Utf8StringInsensitive;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Utf8StringIname;let b=port::SyntaxType::Utf8StringIname;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Uuid;let b=port::SyntaxType::Uuid;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Boolean;let b=port::SyntaxType::Boolean;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::SyntaxId;let b=port::SyntaxType::SyntaxId;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::IndexId;let b=port::SyntaxType::IndexId;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::ReferenceUuid;let b=port::SyntaxType::ReferenceUuid;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::JsonFilter;let b=port::SyntaxType::JsonFilter;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Credential;let b=port::SyntaxType::Credential;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::SecretUtf8String;let b=port::SyntaxType::SecretUtf8String;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::SshKey;let b=port::SyntaxType::SshKey;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::SecurityPrincipalName;let b=port::SyntaxType::SecurityPrincipalName;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Uint32;let b=port::SyntaxType::Uint32;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Cid;let b=port::SyntaxType::Cid;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::NsUniqueId;let b=port::SyntaxType::NsUniqueId;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::DateTime;let b=port::SyntaxType::DateTime;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::EmailAddress;let b=port::SyntaxType::EmailAddress;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Url;let b=port::SyntaxType::Url;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::OauthScope;let b=port::SyntaxType::OauthScope;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::OauthScopeMap;let b=port::SyntaxType::OauthScopeMap;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::PrivateBinary;let b=port::SyntaxType::PrivateBinary;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::IntentToken;let b=port::SyntaxType::IntentToken;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Passkey;let b=port::SyntaxType::Passkey;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::AttestedPasskey;let b=port::SyntaxType::AttestedPasskey;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Session;let b=port::SyntaxType::Session;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::JwsKeyEs256;let b=port::SyntaxType::JwsKeyEs256;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::JwsKeyRs256;let b=port::SyntaxType::JwsKeyRs256;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Oauth2Session;let b=port::SyntaxType::Oauth2Session;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::UiHint;let b=port::SyntaxType::UiHint;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::TotpSecret;let b=port::SyntaxType::TotpSecret;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::ApiToken;let b=port::SyntaxType::ApiToken;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::AuditLogString;let b=port::SyntaxType::AuditLogString;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::EcKeyPrivate;let b=port::SyntaxType::EcKeyPrivate;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Image;let b=port::SyntaxType::Image;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::CredentialType;let b=port::SyntaxType::CredentialType;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::WebauthnAttestationCaList;let b=port::SyntaxType::WebauthnAttestationCaList;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::OauthClaimMap;let b=port::SyntaxType::OauthClaimMap;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::KeyInternal;let b=port::SyntaxType::KeyInternal;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::HexString;let b=port::SyntaxType::HexString;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Certificate;let b=port::SyntaxType::Certificate;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::ApplicationPassword;let b=port::SyntaxType::ApplicationPassword;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Json;let b=port::SyntaxType::Json;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Message;let b=port::SyntaxType::Message;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Sha256;let b=port::SyntaxType::Sha256;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Int64;let b=port::SyntaxType::Int64;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
{let a=reference::SyntaxType::Uint64;let b=port::SyntaxType::Uint64;
assert_eq!(port::display(b),a.to_string().as_bytes());
assert_eq!(port::index_types(b).iter().map(|x|*x as u16).collect::<Vec<_>>(),a.index_types().iter().map(|x|*x as u16).collect::<Vec<_>>()); comparisons+=2;}
let mut inputs:Vec<String>=vec!["utf8string".into(),"utf8string_insensitive".into(),"utf8string_iname".into(),"uuid".into(),"boolean".into(),"syntax_id".into(),"index_id".into(),"reference_uuid".into(),"json_filter".into(),"credential".into(),"secret_utf8string".into(),"sshkey".into(),"security_principal_name".into(),"uint32".into(),"cid".into(),"nsuniqueid".into(),"datetime".into(),"email_address".into(),"url".into(),"oauth_scope".into(),"oauth_scope_map".into(),"private_binary".into(),"intent_token".into(),"passkey".into(),"attested_passkey".into(),"session".into(),"jws_key_es256".into(),"jws_key_rs256".into(),"oauth2session".into(),"uihint".into(),"totpsecret".into(),"apitoken".into(),"audit_log_string".into(),"ec_key_private".into(),"image".into(),"credential_type".into(),"webauthn_attestation_ca_list".into(),"oauth_claim_map".into(),"key_internal".into(),"hex_string".into(),"certificate".into(),"application_password".into(),"json".into(),"message".into(),"sha256".into(),"int64".into(),"uint64".into(),"RADIUS_UTF8STRING".into(),"İ".into(),"ß".into(),"".into(),"utf8string ".into()];
let mut seed=7u64;
for i in 0..100000 {let mut s=String::new();for _ in 0..(i%35) {seed=seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);s.push(char::from_u32(((seed>>24)%0x110000) as u32).unwrap_or('x'));}inputs.push(s);}
for s in inputs {let normalized=s.to_uppercase(); assert_eq!(port::parse_normalized(normalized.as_bytes()).map(|s|s as u16),reference::SyntaxType::try_from(s.as_str()).ok().map(|s|s as u16),"{s}");comparisons+=1;}
eprintln!("{comparisons} pinned syntax metadata comparisons");}
