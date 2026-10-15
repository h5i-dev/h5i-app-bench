import SpecKernel
open Aeneas Aeneas.Std rustfs_kernel
namespace rustfs_kernel.Spec

/-! Condition-key tables in declaration order: data-table characterizations. -/
def s3KeyNames : List (List Nat) :=
  [lit "s3:x-amz-copy-source",
   lit "s3:x-amz-server-side-encryption",
   lit "s3:x-amz-server-side-encryption-customer-algorithm",
   lit "s3:signatureversion",
   lit "s3:authType",
   lit "s3:signatureAge",
   lit "s3:x-amz-content-sha256",
   lit "s3:x-amz-acl",
   lit "s3:LocationConstraint",
   lit "s3:versionid",
   lit "s3:object-lock-retain-until-date",
   lit "s3:object-lock-legal-hold",
   lit "s3:object-lock-mode",
   lit "s3:max-keys",
   lit "s3:x-amz-metadata-directive",
   lit "s3:x-amz-storage-class",
   lit "s3:prefix",
   lit "s3:delimiter",
   lit "s3:x-amz-grant-full-control",
   lit "s3:x-amz-grant-read",
   lit "s3:x-amz-grant-write",
   lit "s3:x-amz-grant-read-acp",
   lit "s3:x-amz-grant-write-acp",
   lit "s3:ExistingObjectTag",
   lit "s3:RequestObjectTagKeys",
   lit "s3:RequestObjectTag"]

def jwtKeyNames : List (List Nat) :=
  [lit "jwt:sub",
   lit "jwt:iss",
   lit "jwt:aud",
   lit "jwt:jti",
   lit "jwt:name",
   lit "jwt:upn",
   lit "jwt:groups",
   lit "jwt:roles",
   lit "jwt:given_name",
   lit "jwt:family_name",
   lit "jwt:middle_name",
   lit "jwt:nickname",
   lit "jwt:preferred_username",
   lit "jwt:profile",
   lit "jwt:picture",
   lit "jwt:website",
   lit "jwt:email",
   lit "jwt:gender",
   lit "jwt:birthdate",
   lit "jwt:phone_number",
   lit "jwt:address",
   lit "jwt:scope",
   lit "jwt:client_id"]

def svcKeyNames : List (List Nat) :=
  [lit "svc:DurationSeconds"]

def ldapKeyNames : List (List Nat) :=
  [lit "ldap:user",
   lit "ldap:username",
   lit "ldap:groups"]

def stsKeyNames : List (List Nat) :=
  [lit "sts:DurationSeconds"]

def awsKeyNames : List (List Nat) :=
  [lit "aws:Referer",
   lit "aws:SourceIp",
   lit "aws:UserAgent",
   lit "aws:SecureTransport",
   lit "aws:CurrentTime",
   lit "aws:EpochTime",
   lit "aws:principaltype",
   lit "aws:userid",
   lit "aws:username",
   lit "aws:groups",
   lit "aws:SourceArn",
   lit "aws:SourceAccount"]

def keyNames : keytables.KeyFamily → List (List Nat)
  | .S3 => s3KeyNames
  | .Jwt => jwtKeyNames
  | .Svc => svcKeyNames
  | .Ldap => ldapKeyNames
  | .Sts => stsKeyNames
  | .Aws => awsKeyNames

def keyPrefix : keytables.KeyFamily → List Nat
  | .S3 => lit "s3:"
  | .Jwt => lit "jwt:"
  | .Svc => lit "svc:"
  | .Ldap => lit "ldap:"
  | .Sts => lit "sts:"
  | .Aws => lit "aws:"
/-- COMMON_KEYS table; repeated names retain their original positions. -/
def commonKeyEntries : List (List Nat × List Nat) :=
  [(lit "signatureversion", lit "${s3:s3:signatureversion}"),
   (lit "authType", lit "${s3:s3:authType}"),
   (lit "signatureAge", lit "${s3:s3:signatureAge}"),
   (lit "x-amz-content-sha256", lit "${s3:s3:x-amz-content-sha256}"),
   (lit "LocationConstraint", lit "${s3:s3:LocationConstraint}"),
   (lit "versionid", lit "${s3:s3:versionid}"),
   (lit "Referer", lit "${aws:aws:Referer}"),
   (lit "SourceIp", lit "${aws:aws:SourceIp}"),
   (lit "UserAgent", lit "${aws:aws:UserAgent}"),
   (lit "SecureTransport", lit "${aws:aws:SecureTransport}"),
   (lit "CurrentTime", lit "${aws:aws:CurrentTime}"),
   (lit "EpochTime", lit "${aws:aws:EpochTime}"),
   (lit "principaltype", lit "${aws:aws:principaltype}"),
   (lit "userid", lit "${aws:aws:userid}"),
   (lit "username", lit "${aws:aws:username}"),
   (lit "groups", lit "${aws:aws:groups}"),
   (lit "user", lit "${ldap:ldap:user}"),
   (lit "username", lit "${ldap:ldap:username}"),
   (lit "groups", lit "${ldap:ldap:groups}"),
   (lit "sub", lit "${jwt:jwt:sub}"),
   (lit "iss", lit "${jwt:jwt:iss}"),
   (lit "aud", lit "${jwt:jwt:aud}"),
   (lit "jti", lit "${jwt:jwt:jti}"),
   (lit "name", lit "${jwt:jwt:name}"),
   (lit "upn", lit "${jwt:jwt:upn}"),
   (lit "groups", lit "${jwt:jwt:groups}"),
   (lit "roles", lit "${jwt:jwt:roles}"),
   (lit "given_name", lit "${jwt:jwt:given_name}"),
   (lit "family_name", lit "${jwt:jwt:family_name}"),
   (lit "middle_name", lit "${jwt:jwt:middle_name}"),
   (lit "nickname", lit "${jwt:jwt:nickname}"),
   (lit "preferred_username", lit "${jwt:jwt:preferred_username}"),
   (lit "profile", lit "${jwt:jwt:profile}"),
   (lit "picture", lit "${jwt:jwt:picture}"),
   (lit "website", lit "${jwt:jwt:website}"),
   (lit "email", lit "${jwt:jwt:email}"),
   (lit "gender", lit "${jwt:jwt:gender}"),
   (lit "birthdate", lit "${jwt:jwt:birthdate}"),
   (lit "phone_number", lit "${jwt:jwt:phone_number}"),
   (lit "address", lit "${jwt:jwt:address}"),
   (lit "scope", lit "${jwt:jwt:scope}"),
   (lit "client_id", lit "${jwt:jwt:client_id}")]

def serverDerivedNames : List (List Nat) :=
  (commonKeyEntries.map Prod.fst).filter (fun n => ! decide (lit "x-amz-" <+: n))

def asciiLower (n : Nat) : Nat := if 65 ≤ n ∧ n ≤ 90 then n + 32 else n

end rustfs_kernel.Spec
