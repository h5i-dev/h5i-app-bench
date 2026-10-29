#![allow(dead_code,non_snake_case,unused_mut)]
use kanidm_kernel::value_observers as port;
#[allow(non_camel_case_types,unused_imports)]
mod reference {include!("../../difftest/value_observers/reference.rs");}
#[derive(Clone,Copy,Debug)] struct Text(u64);
impl Text {fn as_str(&self)->&Self {self}}
#[derive(Clone,Copy,Debug)] struct Payload<T> {handle:u64,_marker:std::marker::PhantomData<T>}
impl<T> Payload<T> {fn new(handle:u64)->Self {Self{handle,_marker:std::marker::PhantomData}}}
trait Norm {fn norm(&self)->std::vec::Vec<u128>;}
impl<T:Norm> Norm for &T {fn norm(&self)->std::vec::Vec<u128> {(*self).norm()}}
impl<T> Norm for Payload<T> {fn norm(&self)->std::vec::Vec<u128> {vec![self.handle as u128]}}
impl Norm for Text {fn norm(&self)->std::vec::Vec<u128> {vec![self.0 as u128]}}
macro_rules! scalar {($($t:ty),*)=>{$(impl Norm for $t {fn norm(&self)->std::vec::Vec<u128> {vec![*self as u128]}})*}}
scalar!(u32,u64,u128,i64,bool);
impl<T:Norm> Norm for Option<T> {fn norm(&self)->std::vec::Vec<u128> {match self {None=>vec![0],Some(x)=>{let mut v=vec![1];v.extend(x.norm());v}}}}
impl<A:Norm,B:Norm> Norm for (A,B) {fn norm(&self)->std::vec::Vec<u128> {let mut v=self.0.norm();v.extend(self.1.norm());v}}
impl Norm for reference::Oauth2Session {fn norm(&self)->std::vec::Vec<u128>{vec![self.rs_uuid,self.payload as u128]}}
impl Norm for port::Oauth2Session {fn norm(&self)->std::vec::Vec<u128>{vec![self.rs_uuid,self.payload as u128]}}
fn make_reference_Value(tag:usize,seed:u64,flag:bool)->reference::Value { match tag {
0=>reference::Value::Utf8(Text(seed.wrapping_add(0))),
1=>reference::Value::Iutf8(Text(seed.wrapping_add(0))),
2=>reference::Value::Iname(Text(seed.wrapping_add(0))),
3=>reference::Value::Uuid(seed.wrapping_add(0) as u128),
4=>reference::Value::Bool(flag),
5=>reference::Value::Syntax(seed.wrapping_add(0)),
6=>reference::Value::Index(seed.wrapping_add(0)),
7=>reference::Value::Refer(seed.wrapping_add(0) as u128),
8=>reference::Value::JsonFilt(seed.wrapping_add(0)),
9=>reference::Value::Cred(Text(seed.wrapping_add(0)),seed.wrapping_add(1)),
10=>reference::Value::SshKey(Text(seed.wrapping_add(0)),seed.wrapping_add(1)),
11=>reference::Value::SecretValue(Text(seed.wrapping_add(0))),
12=>reference::Value::Spn(Text(seed.wrapping_add(0)),Text(seed.wrapping_add(1))),
13=>reference::Value::Uint32(seed.wrapping_add(0) as u32),
14=>reference::Value::Int64(seed.wrapping_add(0) as i64),
15=>reference::Value::Uint64(seed.wrapping_add(0) as u64),
16=>reference::Value::Cid(seed.wrapping_add(0)),
17=>reference::Value::Nsuniqueid(Text(seed.wrapping_add(0))),
18=>reference::Value::DateTime(seed.wrapping_add(0)),
19=>reference::Value::EmailAddress(Text(seed.wrapping_add(0)),flag),
20=>reference::Value::PhoneNumber(Text(seed.wrapping_add(0)),flag),
21=>reference::Value::Address(seed.wrapping_add(0)),
22=>reference::Value::Url(seed.wrapping_add(0)),
23=>reference::Value::OauthScope(Text(seed.wrapping_add(0))),
24=>reference::Value::OauthScopeMap(seed.wrapping_add(0) as u128,Payload::new(seed.wrapping_add(1))),
25=>reference::Value::PrivateBinary(Payload::new(seed.wrapping_add(0))),
26=>reference::Value::PublicBinary(Text(seed.wrapping_add(0)),Payload::new(seed.wrapping_add(1))),
27=>reference::Value::RestrictedString(Text(seed.wrapping_add(0))),
28=>reference::Value::IntentToken(Text(seed.wrapping_add(0)),seed.wrapping_add(1)),
29=>reference::Value::Passkey(seed.wrapping_add(0) as u128,Text(seed.wrapping_add(1)),seed.wrapping_add(2)),
30=>reference::Value::AttestedPasskey(seed.wrapping_add(0) as u128,Text(seed.wrapping_add(1)),seed.wrapping_add(2)),
31=>reference::Value::Session(seed.wrapping_add(0) as u128,seed.wrapping_add(1)),
32=>reference::Value::ApiToken(seed.wrapping_add(0) as u128,seed.wrapping_add(1)),
33=>reference::Value::Oauth2Session(seed.wrapping_add(0) as u128,reference::Oauth2Session{rs_uuid:(seed.wrapping_add(1) as u128)+123456,payload:seed.wrapping_add(1)}),
34=>reference::Value::JwsKeyEs256(seed.wrapping_add(0)),
35=>reference::Value::JwsKeyRs256(seed.wrapping_add(0)),
36=>reference::Value::UiHint(seed.wrapping_add(0)),
37=>reference::Value::TotpSecret(Text(seed.wrapping_add(0)),seed.wrapping_add(1)),
38=>reference::Value::AuditLogString(seed.wrapping_add(0),Text(seed.wrapping_add(1))),
39=>reference::Value::Image(seed.wrapping_add(0)),
40=>reference::Value::CredentialType(seed.wrapping_add(0)),
41=>reference::Value::WebauthnAttestationCaList(seed.wrapping_add(0)),
42=>reference::Value::OauthClaimValue(Text(seed.wrapping_add(0)),seed.wrapping_add(1) as u128,Payload::new(seed.wrapping_add(2))),
43=>reference::Value::OauthClaimMap(Text(seed.wrapping_add(0)),seed.wrapping_add(1)),
44=>reference::Value::KeyInternal{id:seed.wrapping_add(0),usage:seed.wrapping_add(1),valid_from:seed.wrapping_add(2) as u64,status:seed.wrapping_add(3),status_cid:seed.wrapping_add(4),der:Payload::new(seed.wrapping_add(5))},
45=>reference::Value::HexString(Text(seed.wrapping_add(0))),
46=>reference::Value::Certificate(Payload::new(seed.wrapping_add(0))),
47=>reference::Value::ApplicationPassword(seed.wrapping_add(0)),
48=>reference::Value::Json(seed.wrapping_add(0)),
49=>reference::Value::Sha256(seed.wrapping_add(0)),
 _=>panic!("invalid variant")}}
impl Norm for reference::Value {fn norm(&self)->std::vec::Vec<u128> { match self {
reference::Value::Utf8(x0)=>{let mut v=vec![0];v.extend(x0.norm());v},
reference::Value::Iutf8(x0)=>{let mut v=vec![1];v.extend(x0.norm());v},
reference::Value::Iname(x0)=>{let mut v=vec![2];v.extend(x0.norm());v},
reference::Value::Uuid(x0)=>{let mut v=vec![3];v.extend(x0.norm());v},
reference::Value::Bool(x0)=>{let mut v=vec![4];v.extend(x0.norm());v},
reference::Value::Syntax(x0)=>{let mut v=vec![5];v.extend(x0.norm());v},
reference::Value::Index(x0)=>{let mut v=vec![6];v.extend(x0.norm());v},
reference::Value::Refer(x0)=>{let mut v=vec![7];v.extend(x0.norm());v},
reference::Value::JsonFilt(x0)=>{let mut v=vec![8];v.extend(x0.norm());v},
reference::Value::Cred(x0,x1)=>{let mut v=vec![9];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::SshKey(x0,x1)=>{let mut v=vec![10];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::SecretValue(x0)=>{let mut v=vec![11];v.extend(x0.norm());v},
reference::Value::Spn(x0,x1)=>{let mut v=vec![12];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::Uint32(x0)=>{let mut v=vec![13];v.extend(x0.norm());v},
reference::Value::Int64(x0)=>{let mut v=vec![14];v.extend(x0.norm());v},
reference::Value::Uint64(x0)=>{let mut v=vec![15];v.extend(x0.norm());v},
reference::Value::Cid(x0)=>{let mut v=vec![16];v.extend(x0.norm());v},
reference::Value::Nsuniqueid(x0)=>{let mut v=vec![17];v.extend(x0.norm());v},
reference::Value::DateTime(x0)=>{let mut v=vec![18];v.extend(x0.norm());v},
reference::Value::EmailAddress(x0,x1)=>{let mut v=vec![19];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::PhoneNumber(x0,x1)=>{let mut v=vec![20];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::Address(x0)=>{let mut v=vec![21];v.extend(x0.norm());v},
reference::Value::Url(x0)=>{let mut v=vec![22];v.extend(x0.norm());v},
reference::Value::OauthScope(x0)=>{let mut v=vec![23];v.extend(x0.norm());v},
reference::Value::OauthScopeMap(x0,x1)=>{let mut v=vec![24];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::PrivateBinary(x0)=>{let mut v=vec![25];v.extend(x0.norm());v},
reference::Value::PublicBinary(x0,x1)=>{let mut v=vec![26];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::RestrictedString(x0)=>{let mut v=vec![27];v.extend(x0.norm());v},
reference::Value::IntentToken(x0,x1)=>{let mut v=vec![28];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::Passkey(x0,x1,x2)=>{let mut v=vec![29];v.extend(x0.norm());v.extend(x1.norm());v.extend(x2.norm());v},
reference::Value::AttestedPasskey(x0,x1,x2)=>{let mut v=vec![30];v.extend(x0.norm());v.extend(x1.norm());v.extend(x2.norm());v},
reference::Value::Session(x0,x1)=>{let mut v=vec![31];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::ApiToken(x0,x1)=>{let mut v=vec![32];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::Oauth2Session(x0,x1)=>{let mut v=vec![33];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::JwsKeyEs256(x0)=>{let mut v=vec![34];v.extend(x0.norm());v},
reference::Value::JwsKeyRs256(x0)=>{let mut v=vec![35];v.extend(x0.norm());v},
reference::Value::UiHint(x0)=>{let mut v=vec![36];v.extend(x0.norm());v},
reference::Value::TotpSecret(x0,x1)=>{let mut v=vec![37];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::AuditLogString(x0,x1)=>{let mut v=vec![38];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::Image(x0)=>{let mut v=vec![39];v.extend(x0.norm());v},
reference::Value::CredentialType(x0)=>{let mut v=vec![40];v.extend(x0.norm());v},
reference::Value::WebauthnAttestationCaList(x0)=>{let mut v=vec![41];v.extend(x0.norm());v},
reference::Value::OauthClaimValue(x0,x1,x2)=>{let mut v=vec![42];v.extend(x0.norm());v.extend(x1.norm());v.extend(x2.norm());v},
reference::Value::OauthClaimMap(x0,x1)=>{let mut v=vec![43];v.extend(x0.norm());v.extend(x1.norm());v},
reference::Value::KeyInternal{id:x0,usage:x1,valid_from:x2,status:x3,status_cid:x4,der:x5}=>{let mut v=vec![44];v.extend(x0.norm());v.extend(x1.norm());v.extend(x2.norm());v.extend(x3.norm());v.extend(x4.norm());v.extend(x5.norm());v},
reference::Value::HexString(x0)=>{let mut v=vec![45];v.extend(x0.norm());v},
reference::Value::Certificate(x0)=>{let mut v=vec![46];v.extend(x0.norm());v},
reference::Value::ApplicationPassword(x0)=>{let mut v=vec![47];v.extend(x0.norm());v},
reference::Value::Json(x0)=>{let mut v=vec![48];v.extend(x0.norm());v},
reference::Value::Sha256(x0)=>{let mut v=vec![49];v.extend(x0.norm());v},
}}}
fn make_port_Value(tag:usize,seed:u64,flag:bool)->port::Value { match tag {
0=>port::Value::Utf8(seed.wrapping_add(0)),
1=>port::Value::Iutf8(seed.wrapping_add(0)),
2=>port::Value::Iname(seed.wrapping_add(0)),
3=>port::Value::Uuid(seed.wrapping_add(0) as u128),
4=>port::Value::Boolean(flag),
5=>port::Value::Syntax(seed.wrapping_add(0)),
6=>port::Value::Index(seed.wrapping_add(0)),
7=>port::Value::Refer(seed.wrapping_add(0) as u128),
8=>port::Value::JsonFilt(seed.wrapping_add(0)),
9=>port::Value::Cred(seed.wrapping_add(0),seed.wrapping_add(1)),
10=>port::Value::SshKey(seed.wrapping_add(0),seed.wrapping_add(1)),
11=>port::Value::SecretValue(seed.wrapping_add(0)),
12=>port::Value::Spn(seed.wrapping_add(0),seed.wrapping_add(1)),
13=>port::Value::Uint32(seed.wrapping_add(0) as u32),
14=>port::Value::Int64(seed.wrapping_add(0) as i64),
15=>port::Value::Uint64(seed.wrapping_add(0) as u64),
16=>port::Value::Cid(seed.wrapping_add(0)),
17=>port::Value::Nsuniqueid(seed.wrapping_add(0)),
18=>port::Value::DateTime(seed.wrapping_add(0)),
19=>port::Value::EmailAddress(seed.wrapping_add(0),flag),
20=>port::Value::PhoneNumber(seed.wrapping_add(0),flag),
21=>port::Value::Address(seed.wrapping_add(0)),
22=>port::Value::Url(seed.wrapping_add(0)),
23=>port::Value::OauthScope(seed.wrapping_add(0)),
24=>port::Value::OauthScopeMap(seed.wrapping_add(0) as u128,seed.wrapping_add(1)),
25=>port::Value::PrivateBinary(seed.wrapping_add(0)),
26=>port::Value::PublicBinary(seed.wrapping_add(0),seed.wrapping_add(1)),
27=>port::Value::RestrictedString(seed.wrapping_add(0)),
28=>port::Value::IntentToken(seed.wrapping_add(0),seed.wrapping_add(1)),
29=>port::Value::Passkey(seed.wrapping_add(0) as u128,seed.wrapping_add(1),seed.wrapping_add(2)),
30=>port::Value::AttestedPasskey(seed.wrapping_add(0) as u128,seed.wrapping_add(1),seed.wrapping_add(2)),
31=>port::Value::Session(seed.wrapping_add(0) as u128,seed.wrapping_add(1)),
32=>port::Value::ApiToken(seed.wrapping_add(0) as u128,seed.wrapping_add(1)),
33=>port::Value::Oauth2Session(seed.wrapping_add(0) as u128,port::Oauth2Session{rs_uuid:(seed.wrapping_add(1) as u128)+123456,payload:seed.wrapping_add(1)}),
34=>port::Value::JwsKeyEs256(seed.wrapping_add(0)),
35=>port::Value::JwsKeyRs256(seed.wrapping_add(0)),
36=>port::Value::UiHint(seed.wrapping_add(0)),
37=>port::Value::TotpSecret(seed.wrapping_add(0),seed.wrapping_add(1)),
38=>port::Value::AuditLogString(seed.wrapping_add(0),seed.wrapping_add(1)),
39=>port::Value::Image(seed.wrapping_add(0)),
40=>port::Value::CredentialType(seed.wrapping_add(0)),
41=>port::Value::WebauthnAttestationCaList(seed.wrapping_add(0)),
42=>port::Value::OauthClaimValue(seed.wrapping_add(0),seed.wrapping_add(1) as u128,seed.wrapping_add(2)),
43=>port::Value::OauthClaimMap(seed.wrapping_add(0),seed.wrapping_add(1)),
44=>port::Value::KeyInternal{id:seed.wrapping_add(0),usage:seed.wrapping_add(1),valid_from:seed.wrapping_add(2) as u64,status:seed.wrapping_add(3),status_cid:seed.wrapping_add(4),der:seed.wrapping_add(5)},
45=>port::Value::HexString(seed.wrapping_add(0)),
46=>port::Value::Certificate(seed.wrapping_add(0)),
47=>port::Value::ApplicationPassword(seed.wrapping_add(0)),
48=>port::Value::Json(seed.wrapping_add(0)),
49=>port::Value::Sha256(seed.wrapping_add(0)),
 _=>panic!("invalid variant")}}
impl Norm for port::Value {fn norm(&self)->std::vec::Vec<u128> { match self {
port::Value::Utf8(x0)=>{let mut v=vec![0];v.extend(x0.norm());v},
port::Value::Iutf8(x0)=>{let mut v=vec![1];v.extend(x0.norm());v},
port::Value::Iname(x0)=>{let mut v=vec![2];v.extend(x0.norm());v},
port::Value::Uuid(x0)=>{let mut v=vec![3];v.extend(x0.norm());v},
port::Value::Boolean(x0)=>{let mut v=vec![4];v.extend(x0.norm());v},
port::Value::Syntax(x0)=>{let mut v=vec![5];v.extend(x0.norm());v},
port::Value::Index(x0)=>{let mut v=vec![6];v.extend(x0.norm());v},
port::Value::Refer(x0)=>{let mut v=vec![7];v.extend(x0.norm());v},
port::Value::JsonFilt(x0)=>{let mut v=vec![8];v.extend(x0.norm());v},
port::Value::Cred(x0,x1)=>{let mut v=vec![9];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::SshKey(x0,x1)=>{let mut v=vec![10];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::SecretValue(x0)=>{let mut v=vec![11];v.extend(x0.norm());v},
port::Value::Spn(x0,x1)=>{let mut v=vec![12];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::Uint32(x0)=>{let mut v=vec![13];v.extend(x0.norm());v},
port::Value::Int64(x0)=>{let mut v=vec![14];v.extend(x0.norm());v},
port::Value::Uint64(x0)=>{let mut v=vec![15];v.extend(x0.norm());v},
port::Value::Cid(x0)=>{let mut v=vec![16];v.extend(x0.norm());v},
port::Value::Nsuniqueid(x0)=>{let mut v=vec![17];v.extend(x0.norm());v},
port::Value::DateTime(x0)=>{let mut v=vec![18];v.extend(x0.norm());v},
port::Value::EmailAddress(x0,x1)=>{let mut v=vec![19];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::PhoneNumber(x0,x1)=>{let mut v=vec![20];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::Address(x0)=>{let mut v=vec![21];v.extend(x0.norm());v},
port::Value::Url(x0)=>{let mut v=vec![22];v.extend(x0.norm());v},
port::Value::OauthScope(x0)=>{let mut v=vec![23];v.extend(x0.norm());v},
port::Value::OauthScopeMap(x0,x1)=>{let mut v=vec![24];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::PrivateBinary(x0)=>{let mut v=vec![25];v.extend(x0.norm());v},
port::Value::PublicBinary(x0,x1)=>{let mut v=vec![26];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::RestrictedString(x0)=>{let mut v=vec![27];v.extend(x0.norm());v},
port::Value::IntentToken(x0,x1)=>{let mut v=vec![28];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::Passkey(x0,x1,x2)=>{let mut v=vec![29];v.extend(x0.norm());v.extend(x1.norm());v.extend(x2.norm());v},
port::Value::AttestedPasskey(x0,x1,x2)=>{let mut v=vec![30];v.extend(x0.norm());v.extend(x1.norm());v.extend(x2.norm());v},
port::Value::Session(x0,x1)=>{let mut v=vec![31];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::ApiToken(x0,x1)=>{let mut v=vec![32];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::Oauth2Session(x0,x1)=>{let mut v=vec![33];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::JwsKeyEs256(x0)=>{let mut v=vec![34];v.extend(x0.norm());v},
port::Value::JwsKeyRs256(x0)=>{let mut v=vec![35];v.extend(x0.norm());v},
port::Value::UiHint(x0)=>{let mut v=vec![36];v.extend(x0.norm());v},
port::Value::TotpSecret(x0,x1)=>{let mut v=vec![37];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::AuditLogString(x0,x1)=>{let mut v=vec![38];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::Image(x0)=>{let mut v=vec![39];v.extend(x0.norm());v},
port::Value::CredentialType(x0)=>{let mut v=vec![40];v.extend(x0.norm());v},
port::Value::WebauthnAttestationCaList(x0)=>{let mut v=vec![41];v.extend(x0.norm());v},
port::Value::OauthClaimValue(x0,x1,x2)=>{let mut v=vec![42];v.extend(x0.norm());v.extend(x1.norm());v.extend(x2.norm());v},
port::Value::OauthClaimMap(x0,x1)=>{let mut v=vec![43];v.extend(x0.norm());v.extend(x1.norm());v},
port::Value::KeyInternal{id:x0,usage:x1,valid_from:x2,status:x3,status_cid:x4,der:x5}=>{let mut v=vec![44];v.extend(x0.norm());v.extend(x1.norm());v.extend(x2.norm());v.extend(x3.norm());v.extend(x4.norm());v.extend(x5.norm());v},
port::Value::HexString(x0)=>{let mut v=vec![45];v.extend(x0.norm());v},
port::Value::Certificate(x0)=>{let mut v=vec![46];v.extend(x0.norm());v},
port::Value::ApplicationPassword(x0)=>{let mut v=vec![47];v.extend(x0.norm());v},
port::Value::Json(x0)=>{let mut v=vec![48];v.extend(x0.norm());v},
port::Value::Sha256(x0)=>{let mut v=vec![49];v.extend(x0.norm());v},
}}}
fn make_reference_PartialValue(tag:usize,seed:u64,flag:bool)->reference::PartialValue { match tag {
0=>reference::PartialValue::Utf8(Text(seed.wrapping_add(0))),
1=>reference::PartialValue::Iutf8(Text(seed.wrapping_add(0))),
2=>reference::PartialValue::Iname(Text(seed.wrapping_add(0))),
3=>reference::PartialValue::Uuid(seed.wrapping_add(0) as u128),
4=>reference::PartialValue::Bool(flag),
5=>reference::PartialValue::Syntax(seed.wrapping_add(0)),
6=>reference::PartialValue::Index(seed.wrapping_add(0)),
7=>reference::PartialValue::Refer(seed.wrapping_add(0) as u128),
8=>reference::PartialValue::JsonFilt(seed.wrapping_add(0)),
9=>reference::PartialValue::Cred(Text(seed.wrapping_add(0))),
10=>reference::PartialValue::SshKey(Text(seed.wrapping_add(0))),
11=>reference::PartialValue::SecretValue,
12=>reference::PartialValue::Spn(Text(seed.wrapping_add(0)),Text(seed.wrapping_add(1))),
13=>reference::PartialValue::Uint32(seed.wrapping_add(0) as u32),
14=>reference::PartialValue::Cid(seed.wrapping_add(0)),
15=>reference::PartialValue::Nsuniqueid(Text(seed.wrapping_add(0))),
16=>reference::PartialValue::DateTime(seed.wrapping_add(0)),
17=>reference::PartialValue::EmailAddress(Text(seed.wrapping_add(0))),
18=>reference::PartialValue::PhoneNumber(Text(seed.wrapping_add(0))),
19=>reference::PartialValue::Address(Text(seed.wrapping_add(0))),
20=>reference::PartialValue::Url(seed.wrapping_add(0)),
21=>reference::PartialValue::OauthScope(Text(seed.wrapping_add(0))),
22=>reference::PartialValue::PrivateBinary,
23=>reference::PartialValue::PublicBinary(Text(seed.wrapping_add(0))),
24=>reference::PartialValue::RestrictedString(Text(seed.wrapping_add(0))),
25=>reference::PartialValue::IntentToken(Text(seed.wrapping_add(0))),
26=>reference::PartialValue::UiHint(seed.wrapping_add(0)),
27=>reference::PartialValue::Passkey(seed.wrapping_add(0) as u128),
28=>reference::PartialValue::AttestedPasskey(seed.wrapping_add(0) as u128),
29=>reference::PartialValue::Image(Text(seed.wrapping_add(0))),
30=>reference::PartialValue::CredentialType(seed.wrapping_add(0)),
31=>reference::PartialValue::OauthClaim(Text(seed.wrapping_add(0)),seed.wrapping_add(1) as u128),
32=>reference::PartialValue::OauthClaimValue(Text(seed.wrapping_add(0)),seed.wrapping_add(1) as u128,Text(seed.wrapping_add(2))),
33=>reference::PartialValue::HexString(Text(seed.wrapping_add(0))),
34=>reference::PartialValue::Json,
35=>reference::PartialValue::Sha256(seed.wrapping_add(0)),
36=>reference::PartialValue::Int64(seed.wrapping_add(0) as i64),
37=>reference::PartialValue::Uint64(seed.wrapping_add(0) as u64),
 _=>panic!("invalid variant")}}
impl Norm for reference::PartialValue {fn norm(&self)->std::vec::Vec<u128> { match self {
reference::PartialValue::Utf8(x0)=>{let mut v=vec![0];v.extend(x0.norm());v},
reference::PartialValue::Iutf8(x0)=>{let mut v=vec![1];v.extend(x0.norm());v},
reference::PartialValue::Iname(x0)=>{let mut v=vec![2];v.extend(x0.norm());v},
reference::PartialValue::Uuid(x0)=>{let mut v=vec![3];v.extend(x0.norm());v},
reference::PartialValue::Bool(x0)=>{let mut v=vec![4];v.extend(x0.norm());v},
reference::PartialValue::Syntax(x0)=>{let mut v=vec![5];v.extend(x0.norm());v},
reference::PartialValue::Index(x0)=>{let mut v=vec![6];v.extend(x0.norm());v},
reference::PartialValue::Refer(x0)=>{let mut v=vec![7];v.extend(x0.norm());v},
reference::PartialValue::JsonFilt(x0)=>{let mut v=vec![8];v.extend(x0.norm());v},
reference::PartialValue::Cred(x0)=>{let mut v=vec![9];v.extend(x0.norm());v},
reference::PartialValue::SshKey(x0)=>{let mut v=vec![10];v.extend(x0.norm());v},
reference::PartialValue::SecretValue=>{let mut v=vec![11];v},
reference::PartialValue::Spn(x0,x1)=>{let mut v=vec![12];v.extend(x0.norm());v.extend(x1.norm());v},
reference::PartialValue::Uint32(x0)=>{let mut v=vec![13];v.extend(x0.norm());v},
reference::PartialValue::Cid(x0)=>{let mut v=vec![14];v.extend(x0.norm());v},
reference::PartialValue::Nsuniqueid(x0)=>{let mut v=vec![15];v.extend(x0.norm());v},
reference::PartialValue::DateTime(x0)=>{let mut v=vec![16];v.extend(x0.norm());v},
reference::PartialValue::EmailAddress(x0)=>{let mut v=vec![17];v.extend(x0.norm());v},
reference::PartialValue::PhoneNumber(x0)=>{let mut v=vec![18];v.extend(x0.norm());v},
reference::PartialValue::Address(x0)=>{let mut v=vec![19];v.extend(x0.norm());v},
reference::PartialValue::Url(x0)=>{let mut v=vec![20];v.extend(x0.norm());v},
reference::PartialValue::OauthScope(x0)=>{let mut v=vec![21];v.extend(x0.norm());v},
reference::PartialValue::PrivateBinary=>{let mut v=vec![22];v},
reference::PartialValue::PublicBinary(x0)=>{let mut v=vec![23];v.extend(x0.norm());v},
reference::PartialValue::RestrictedString(x0)=>{let mut v=vec![24];v.extend(x0.norm());v},
reference::PartialValue::IntentToken(x0)=>{let mut v=vec![25];v.extend(x0.norm());v},
reference::PartialValue::UiHint(x0)=>{let mut v=vec![26];v.extend(x0.norm());v},
reference::PartialValue::Passkey(x0)=>{let mut v=vec![27];v.extend(x0.norm());v},
reference::PartialValue::AttestedPasskey(x0)=>{let mut v=vec![28];v.extend(x0.norm());v},
reference::PartialValue::Image(x0)=>{let mut v=vec![29];v.extend(x0.norm());v},
reference::PartialValue::CredentialType(x0)=>{let mut v=vec![30];v.extend(x0.norm());v},
reference::PartialValue::OauthClaim(x0,x1)=>{let mut v=vec![31];v.extend(x0.norm());v.extend(x1.norm());v},
reference::PartialValue::OauthClaimValue(x0,x1,x2)=>{let mut v=vec![32];v.extend(x0.norm());v.extend(x1.norm());v.extend(x2.norm());v},
reference::PartialValue::HexString(x0)=>{let mut v=vec![33];v.extend(x0.norm());v},
reference::PartialValue::Json=>{let mut v=vec![34];v},
reference::PartialValue::Sha256(x0)=>{let mut v=vec![35];v.extend(x0.norm());v},
reference::PartialValue::Int64(x0)=>{let mut v=vec![36];v.extend(x0.norm());v},
reference::PartialValue::Uint64(x0)=>{let mut v=vec![37];v.extend(x0.norm());v},
}}}
fn make_port_PartialValue(tag:usize,seed:u64,flag:bool)->port::PartialValue { match tag {
0=>port::PartialValue::Utf8(seed.wrapping_add(0)),
1=>port::PartialValue::Iutf8(seed.wrapping_add(0)),
2=>port::PartialValue::Iname(seed.wrapping_add(0)),
3=>port::PartialValue::Uuid(seed.wrapping_add(0) as u128),
4=>port::PartialValue::Boolean(flag),
5=>port::PartialValue::Syntax(seed.wrapping_add(0)),
6=>port::PartialValue::Index(seed.wrapping_add(0)),
7=>port::PartialValue::Refer(seed.wrapping_add(0) as u128),
8=>port::PartialValue::JsonFilt(seed.wrapping_add(0)),
9=>port::PartialValue::Cred(seed.wrapping_add(0)),
10=>port::PartialValue::SshKey(seed.wrapping_add(0)),
11=>port::PartialValue::SecretValue,
12=>port::PartialValue::Spn(seed.wrapping_add(0),seed.wrapping_add(1)),
13=>port::PartialValue::Uint32(seed.wrapping_add(0) as u32),
14=>port::PartialValue::Cid(seed.wrapping_add(0)),
15=>port::PartialValue::Nsuniqueid(seed.wrapping_add(0)),
16=>port::PartialValue::DateTime(seed.wrapping_add(0)),
17=>port::PartialValue::EmailAddress(seed.wrapping_add(0)),
18=>port::PartialValue::PhoneNumber(seed.wrapping_add(0)),
19=>port::PartialValue::Address(seed.wrapping_add(0)),
20=>port::PartialValue::Url(seed.wrapping_add(0)),
21=>port::PartialValue::OauthScope(seed.wrapping_add(0)),
22=>port::PartialValue::PrivateBinary,
23=>port::PartialValue::PublicBinary(seed.wrapping_add(0)),
24=>port::PartialValue::RestrictedString(seed.wrapping_add(0)),
25=>port::PartialValue::IntentToken(seed.wrapping_add(0)),
26=>port::PartialValue::UiHint(seed.wrapping_add(0)),
27=>port::PartialValue::Passkey(seed.wrapping_add(0) as u128),
28=>port::PartialValue::AttestedPasskey(seed.wrapping_add(0) as u128),
29=>port::PartialValue::Image(seed.wrapping_add(0)),
30=>port::PartialValue::CredentialType(seed.wrapping_add(0)),
31=>port::PartialValue::OauthClaim(seed.wrapping_add(0),seed.wrapping_add(1) as u128),
32=>port::PartialValue::OauthClaimValue(seed.wrapping_add(0),seed.wrapping_add(1) as u128,seed.wrapping_add(2)),
33=>port::PartialValue::HexString(seed.wrapping_add(0)),
34=>port::PartialValue::Json,
35=>port::PartialValue::Sha256(seed.wrapping_add(0)),
36=>port::PartialValue::Int64(seed.wrapping_add(0) as i64),
37=>port::PartialValue::Uint64(seed.wrapping_add(0) as u64),
 _=>panic!("invalid variant")}}
impl Norm for port::PartialValue {fn norm(&self)->std::vec::Vec<u128> { match self {
port::PartialValue::Utf8(x0)=>{let mut v=vec![0];v.extend(x0.norm());v},
port::PartialValue::Iutf8(x0)=>{let mut v=vec![1];v.extend(x0.norm());v},
port::PartialValue::Iname(x0)=>{let mut v=vec![2];v.extend(x0.norm());v},
port::PartialValue::Uuid(x0)=>{let mut v=vec![3];v.extend(x0.norm());v},
port::PartialValue::Boolean(x0)=>{let mut v=vec![4];v.extend(x0.norm());v},
port::PartialValue::Syntax(x0)=>{let mut v=vec![5];v.extend(x0.norm());v},
port::PartialValue::Index(x0)=>{let mut v=vec![6];v.extend(x0.norm());v},
port::PartialValue::Refer(x0)=>{let mut v=vec![7];v.extend(x0.norm());v},
port::PartialValue::JsonFilt(x0)=>{let mut v=vec![8];v.extend(x0.norm());v},
port::PartialValue::Cred(x0)=>{let mut v=vec![9];v.extend(x0.norm());v},
port::PartialValue::SshKey(x0)=>{let mut v=vec![10];v.extend(x0.norm());v},
port::PartialValue::SecretValue=>{let mut v=vec![11];v},
port::PartialValue::Spn(x0,x1)=>{let mut v=vec![12];v.extend(x0.norm());v.extend(x1.norm());v},
port::PartialValue::Uint32(x0)=>{let mut v=vec![13];v.extend(x0.norm());v},
port::PartialValue::Cid(x0)=>{let mut v=vec![14];v.extend(x0.norm());v},
port::PartialValue::Nsuniqueid(x0)=>{let mut v=vec![15];v.extend(x0.norm());v},
port::PartialValue::DateTime(x0)=>{let mut v=vec![16];v.extend(x0.norm());v},
port::PartialValue::EmailAddress(x0)=>{let mut v=vec![17];v.extend(x0.norm());v},
port::PartialValue::PhoneNumber(x0)=>{let mut v=vec![18];v.extend(x0.norm());v},
port::PartialValue::Address(x0)=>{let mut v=vec![19];v.extend(x0.norm());v},
port::PartialValue::Url(x0)=>{let mut v=vec![20];v.extend(x0.norm());v},
port::PartialValue::OauthScope(x0)=>{let mut v=vec![21];v.extend(x0.norm());v},
port::PartialValue::PrivateBinary=>{let mut v=vec![22];v},
port::PartialValue::PublicBinary(x0)=>{let mut v=vec![23];v.extend(x0.norm());v},
port::PartialValue::RestrictedString(x0)=>{let mut v=vec![24];v.extend(x0.norm());v},
port::PartialValue::IntentToken(x0)=>{let mut v=vec![25];v.extend(x0.norm());v},
port::PartialValue::UiHint(x0)=>{let mut v=vec![26];v.extend(x0.norm());v},
port::PartialValue::Passkey(x0)=>{let mut v=vec![27];v.extend(x0.norm());v},
port::PartialValue::AttestedPasskey(x0)=>{let mut v=vec![28];v.extend(x0.norm());v},
port::PartialValue::Image(x0)=>{let mut v=vec![29];v.extend(x0.norm());v},
port::PartialValue::CredentialType(x0)=>{let mut v=vec![30];v.extend(x0.norm());v},
port::PartialValue::OauthClaim(x0,x1)=>{let mut v=vec![31];v.extend(x0.norm());v.extend(x1.norm());v},
port::PartialValue::OauthClaimValue(x0,x1,x2)=>{let mut v=vec![32];v.extend(x0.norm());v.extend(x1.norm());v.extend(x2.norm());v},
port::PartialValue::HexString(x0)=>{let mut v=vec![33];v.extend(x0.norm());v},
port::PartialValue::Json=>{let mut v=vec![34];v},
port::PartialValue::Sha256(x0)=>{let mut v=vec![35];v.extend(x0.norm());v},
port::PartialValue::Int64(x0)=>{let mut v=vec![36];v.extend(x0.norm());v},
port::PartialValue::Uint64(x0)=>{let mut v=vec![37];v.extend(x0.norm());v},
}}}
#[test] fn pinned_value_observers() {let mut seed=0u64;let mut comparisons=0u64;
for round in 0..10004 {seed=match round {0=>0,1=>1,2=>u64::MAX,3=>i64::MAX as u64,_=>seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407)};
for flag in [false,true] {
for tag in 0..50 {let a=make_reference_Value(tag,seed,flag);let b=make_port_Value(tag,seed,flag);
assert_eq!(a.clone().is_utf8().norm(),b.is_utf8().norm(),"Value::is_utf8 tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_iutf8().norm(),b.is_iutf8().norm(),"Value::is_iutf8 tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_insensitive_utf8().norm(),b.is_insensitive_utf8().norm(),"Value::is_insensitive_utf8 tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_iname().norm(),b.is_iname().norm(),"Value::is_iname tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_uuid().norm(),b.is_uuid().norm(),"Value::is_uuid tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_bool().norm(),b.is_bool().norm(),"Value::is_bool tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_syntax().norm(),b.is_syntax().norm(),"Value::is_syntax tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_index().norm(),b.is_index().norm(),"Value::is_index tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_refer().norm(),b.is_refer().norm(),"Value::is_refer tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_json_filter().norm(),b.is_json_filter().norm(),"Value::is_json_filter tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_credential().norm(),b.is_credential().norm(),"Value::is_credential tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_secret_string().norm(),b.is_secret_string().norm(),"Value::is_secret_string tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_sshkey().norm(),b.is_sshkey().norm(),"Value::is_sshkey tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_spn().norm(),b.is_spn().norm(),"Value::is_spn tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_uint32().norm(),b.is_uint32().norm(),"Value::is_uint32 tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_cid().norm(),b.is_cid().norm(),"Value::is_cid tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_nsuniqueid().norm(),b.is_nsuniqueid().norm(),"Value::is_nsuniqueid tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_datetime().norm(),b.is_datetime().norm(),"Value::is_datetime tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_email_address().norm(),b.is_email_address().norm(),"Value::is_email_address tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_url().norm(),b.is_url().norm(),"Value::is_url tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_oauthscope().norm(),b.is_oauthscope().norm(),"Value::is_oauthscope tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_oauthscopemap().norm(),b.is_oauthscopemap().norm(),"Value::is_oauthscopemap tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_privatebinary().norm(),b.is_privatebinary().norm(),"Value::is_privatebinary tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().as_json_filter().norm(),b.as_json_filter().norm(),"Value::as_json_filter tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_credential().norm(),b.to_credential().norm(),"Value::to_credential tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().get_secret_str().norm(),b.get_secret_str().norm(),"Value::get_secret_str tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_privatebinary().norm(),b.to_privatebinary().norm(),"Value::to_privatebinary tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_str().norm(),b.to_str().norm(),"Value::to_str tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_url().norm(),b.to_url().norm(),"Value::to_url tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().as_string().norm(),b.as_string().norm(),"Value::as_string tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_ref_uuid().norm(),b.to_ref_uuid().norm(),"Value::to_ref_uuid tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_uuid().norm(),b.to_uuid().norm(),"Value::to_uuid tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_indextype().norm(),b.to_indextype().norm(),"Value::to_indextype tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_syntaxtype().norm(),b.to_syntaxtype().norm(),"Value::to_syntaxtype tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_bool().norm(),b.to_bool().norm(),"Value::to_bool tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_uint32().norm(),b.to_uint32().norm(),"Value::to_uint32 tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_utf8().norm(),b.to_utf8().norm(),"Value::to_utf8 tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_iutf8().norm(),b.to_iutf8().norm(),"Value::to_iutf8 tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_iname().norm(),b.to_iname().norm(),"Value::to_iname tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_jsonfilt().norm(),b.to_jsonfilt().norm(),"Value::to_jsonfilt tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_cred().norm(),b.to_cred().norm(),"Value::to_cred tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_spn().norm(),b.to_spn().norm(),"Value::to_spn tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_cid().norm(),b.to_cid().norm(),"Value::to_cid tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_nsuniqueid().norm(),b.to_nsuniqueid().norm(),"Value::to_nsuniqueid tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_emailaddress().norm(),b.to_emailaddress().norm(),"Value::to_emailaddress tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_oauthscope().norm(),b.to_oauthscope().norm(),"Value::to_oauthscope tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_oauthscopemap().norm(),b.to_oauthscopemap().norm(),"Value::to_oauthscopemap tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_restrictedstring().norm(),b.to_restrictedstring().norm(),"Value::to_restrictedstring tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_phonenumber().norm(),b.to_phonenumber().norm(),"Value::to_phonenumber tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_publicbinary().norm(),b.to_publicbinary().norm(),"Value::to_publicbinary tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_address().norm(),b.to_address().norm(),"Value::to_address tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_intenttoken().norm(),b.to_intenttoken().norm(),"Value::to_intenttoken tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_session().norm(),b.to_session().norm(),"Value::to_session tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().migrate_iutf8_iname().norm(),b.migrate_iutf8_iname().norm(),"Value::migrate_iutf8_iname tag={tag} seed={seed}"); comparisons+=1;
}
for tag in 0..38 {let a=make_reference_PartialValue(tag,seed,flag);let b=make_port_PartialValue(tag,seed,flag);
assert_eq!(a.clone().is_utf8().norm(),b.is_utf8().norm(),"PartialValue::is_utf8 tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_iutf8().norm(),b.is_iutf8().norm(),"PartialValue::is_iutf8 tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_iname().norm(),b.is_iname().norm(),"PartialValue::is_iname tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_bool().norm(),b.is_bool().norm(),"PartialValue::is_bool tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_uuid().norm(),b.is_uuid().norm(),"PartialValue::is_uuid tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_refer().norm(),b.is_refer().norm(),"PartialValue::is_refer tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_index().norm(),b.is_index().norm(),"PartialValue::is_index tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_syntax().norm(),b.is_syntax().norm(),"PartialValue::is_syntax tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_json_filter().norm(),b.is_json_filter().norm(),"PartialValue::is_json_filter tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_credential().norm(),b.is_credential().norm(),"PartialValue::is_credential tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_secret_string().norm(),b.is_secret_string().norm(),"PartialValue::is_secret_string tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_sshkey().norm(),b.is_sshkey().norm(),"PartialValue::is_sshkey tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_spn().norm(),b.is_spn().norm(),"PartialValue::is_spn tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_uint32().norm(),b.is_uint32().norm(),"PartialValue::is_uint32 tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_cid().norm(),b.is_cid().norm(),"PartialValue::is_cid tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_nsuniqueid().norm(),b.is_nsuniqueid().norm(),"PartialValue::is_nsuniqueid tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_datetime().norm(),b.is_datetime().norm(),"PartialValue::is_datetime tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_email_address().norm(),b.is_email_address().norm(),"PartialValue::is_email_address tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_url().norm(),b.is_url().norm(),"PartialValue::is_url tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_oauthscope().norm(),b.is_oauthscope().norm(),"PartialValue::is_oauthscope tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().is_privatebinary().norm(),b.is_privatebinary().norm(),"PartialValue::is_privatebinary tag={tag} seed={seed}"); comparisons+=1;
assert_eq!(a.clone().to_str().norm(),b.to_str().norm(),"PartialValue::to_str tag={tag} seed={seed}"); comparisons+=1;
}
}}
eprintln!("{comparisons} pinned observer comparisons");}
