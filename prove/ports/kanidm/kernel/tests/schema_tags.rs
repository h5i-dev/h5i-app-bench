#[path = "../../difftest/schema/reference.rs"]
mod reference;
use kanidm_kernel::schema_tags::{self, Syntax};
fn syntax(i:usize)->Syntax { match i {
0 => Syntax::Utf8String,
1 => Syntax::Utf8StringInsensitive,
2 => Syntax::Uuid,
3 => Syntax::Boolean,
4 => Syntax::SyntaxId,
5 => Syntax::IndexId,
6 => Syntax::ReferenceUuid,
7 => Syntax::JsonFilter,
8 => Syntax::Credential,
9 => Syntax::SecretUtf8String,
10 => Syntax::SshKey,
11 => Syntax::SecurityPrincipalName,
12 => Syntax::Uint32,
13 => Syntax::Cid,
14 => Syntax::Utf8StringIname,
15 => Syntax::NsUniqueId,
16 => Syntax::DateTime,
17 => Syntax::EmailAddress,
18 => Syntax::Url,
19 => Syntax::OauthScope,
20 => Syntax::OauthScopeMap,
21 => Syntax::PrivateBinary,
22 => Syntax::IntentToken,
23 => Syntax::Passkey,
24 => Syntax::AttestedPasskey,
25 => Syntax::Session,
26 => Syntax::JwsKeyEs256,
27 => Syntax::JwsKeyRs256,
28 => Syntax::Oauth2Session,
29 => Syntax::UiHint,
30 => Syntax::TotpSecret,
31 => Syntax::ApiToken,
32 => Syntax::AuditLogString,
33 => Syntax::EcKeyPrivate,
34 => Syntax::Image,
35 => Syntax::CredentialType,
36 => Syntax::WebauthnAttestationCaList,
37 => Syntax::OauthClaimMap,
38 => Syntax::KeyInternal,
39 => Syntax::HexString,
40 => Syntax::Certificate,
41 => Syntax::ApplicationPassword,
42 => Syntax::Json,
43 => Syntax::Message,
44 => Syntax::Sha256,
45 => Syntax::Int64,
46 => Syntax::Uint64,
_ => panic!("invalid syntax") }}
#[test]
fn exhaustive_schema_dispatch() {
 let attr="test".to_string(); let mut comparisons=0usize;
 for si in 0..47 { let s=reference::SchemaAttribute {syntax:reference::syntax(si),multivalue:false,name:attr.clone()};
  for tag in 0..reference::PARTIAL_TAG_COUNT as u16 { assert_eq!(schema_tags::partial_accepts(syntax(si),tag),s.validate_partialvalue(&attr,&reference::partial(tag as usize,true)).is_ok(),"partial {si} {tag}"); comparisons+=1; }
  for tag in 0..reference::VALUE_TAG_COUNT as u16 { for valid in [false,true] { assert_eq!(schema_tags::value_accepts(syntax(si),tag,valid),s.validate_value(&attr,&reference::value(tag as usize,valid)).is_ok(),"value {si} {tag} {valid}"); comparisons+=1; }}
  for actual in 0..47 { for multi in [false,true] { for count in [0,1,2,usize::MAX] { for valid in [false,true] {
   let s=reference::SchemaAttribute {syntax:reference::syntax(si),multivalue:multi,name:attr.clone()};
   let set=reference::ValueSet {syntax:reference::syntax(actual),count,valid};
   assert_eq!(schema_tags::ava_accepts(multi,count,si as u16,actual as u16,valid),s.validate_ava(&attr,&set).is_ok(),"ava {si} {actual} {multi} {count} {valid}"); comparisons+=1;
  }}}}
 }
 println!("{comparisons} exhaustive schema-dispatch comparisons");
}
