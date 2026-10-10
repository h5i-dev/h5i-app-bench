use crate::tests::{Rng, b};
use rustfs_kernel::keytables as k;
use rustfs_private_oracle::policy::function::key_name::*;
#[test]
fn key_tables_agree() {
    let mut all = Vec::new();
    let variants = vec![
        KeyName::S3(S3KeyName::S3XAmzCopySource),
        KeyName::S3(S3KeyName::S3XAmzServerSideEncryption),
        KeyName::S3(S3KeyName::S3XAmzServerSideEncryptionCustomerAlgorithm),
        KeyName::S3(S3KeyName::S3SignatureVersion),
        KeyName::S3(S3KeyName::S3AuthType),
        KeyName::S3(S3KeyName::S3SignatureAge),
        KeyName::S3(S3KeyName::S3XAmzContentSha256),
        KeyName::S3(S3KeyName::S3XAmzAcl),
        KeyName::S3(S3KeyName::S3LocationConstraint),
        KeyName::S3(S3KeyName::S3VersionId),
        KeyName::S3(S3KeyName::S3ObjectLockRetainUntilDate),
        KeyName::S3(S3KeyName::S3ObjectLockLegalHold),
        KeyName::S3(S3KeyName::S3ObjectLockMode),
        KeyName::S3(S3KeyName::S3MaxKeys),
        KeyName::S3(S3KeyName::S3XAmzMetadataDirective),
        KeyName::S3(S3KeyName::S3XAmzStorageClass),
        KeyName::S3(S3KeyName::S3Prefix),
        KeyName::S3(S3KeyName::S3Delimiter),
        KeyName::S3(S3KeyName::S3XAmzGrantFullControl),
        KeyName::S3(S3KeyName::S3XAmzGrantRead),
        KeyName::S3(S3KeyName::S3XAmzGrantWrite),
        KeyName::S3(S3KeyName::S3XAmzGrantReadAcp),
        KeyName::S3(S3KeyName::S3XAmzGrantWriteAcp),
        KeyName::S3(S3KeyName::S3ExistingObjectTag),
        KeyName::S3(S3KeyName::S3RequestObjectTagKeys),
        KeyName::S3(S3KeyName::S3RequestObjectTag),
    ];
    assert_eq!(k::key_count(k::KeyFamily::S3), variants.len());
    for (i, v) in variants.iter().enumerate() {
        let name = <&str>::from(v);
        assert_eq!(k::key_name(k::KeyFamily::S3, i), b(name));
        assert!(k::contains_name(k::KeyFamily::S3, name.as_bytes()));
        assert_eq!(
            k::is_server_derived(k::KeyFamily::S3, name.as_bytes()),
            v.is_server_derived()
        );
    }
    assert!(k::key_name(k::KeyFamily::S3, variants.len()).is_empty());
    all.push((k::KeyFamily::S3, variants));
    let variants = vec![
        KeyName::Jwt(JwtKeyName::JWTSub),
        KeyName::Jwt(JwtKeyName::JWTIss),
        KeyName::Jwt(JwtKeyName::JWTAud),
        KeyName::Jwt(JwtKeyName::JWTJti),
        KeyName::Jwt(JwtKeyName::JWTName),
        KeyName::Jwt(JwtKeyName::JWTUpn),
        KeyName::Jwt(JwtKeyName::JWTGroups),
        KeyName::Jwt(JwtKeyName::JWTRoles),
        KeyName::Jwt(JwtKeyName::JWTGivenName),
        KeyName::Jwt(JwtKeyName::JWTFamilyName),
        KeyName::Jwt(JwtKeyName::JWTMiddleName),
        KeyName::Jwt(JwtKeyName::JWTNickName),
        KeyName::Jwt(JwtKeyName::JWTPrefUsername),
        KeyName::Jwt(JwtKeyName::JWTProfile),
        KeyName::Jwt(JwtKeyName::JWTPicture),
        KeyName::Jwt(JwtKeyName::JWTWebsite),
        KeyName::Jwt(JwtKeyName::JWTEmail),
        KeyName::Jwt(JwtKeyName::JWTGender),
        KeyName::Jwt(JwtKeyName::JWTBirthdate),
        KeyName::Jwt(JwtKeyName::JWTPhoneNumber),
        KeyName::Jwt(JwtKeyName::JWTAddress),
        KeyName::Jwt(JwtKeyName::JWTScope),
        KeyName::Jwt(JwtKeyName::JWTClientID),
    ];
    assert_eq!(k::key_count(k::KeyFamily::Jwt), variants.len());
    for (i, v) in variants.iter().enumerate() {
        let name = <&str>::from(v);
        assert_eq!(k::key_name(k::KeyFamily::Jwt, i), b(name));
        assert!(k::contains_name(k::KeyFamily::Jwt, name.as_bytes()));
        assert_eq!(
            k::is_server_derived(k::KeyFamily::Jwt, name.as_bytes()),
            v.is_server_derived()
        );
    }
    assert!(k::key_name(k::KeyFamily::Jwt, variants.len()).is_empty());
    all.push((k::KeyFamily::Jwt, variants));
    let variants = vec![KeyName::Svc(SvcKeyName::SVCDurationSeconds)];
    assert_eq!(k::key_count(k::KeyFamily::Svc), variants.len());
    for (i, v) in variants.iter().enumerate() {
        let name = <&str>::from(v);
        assert_eq!(k::key_name(k::KeyFamily::Svc, i), b(name));
        assert!(k::contains_name(k::KeyFamily::Svc, name.as_bytes()));
        assert_eq!(
            k::is_server_derived(k::KeyFamily::Svc, name.as_bytes()),
            v.is_server_derived()
        );
    }
    assert!(k::key_name(k::KeyFamily::Svc, variants.len()).is_empty());
    all.push((k::KeyFamily::Svc, variants));
    let variants = vec![
        KeyName::Ldap(LdapKeyName::User),
        KeyName::Ldap(LdapKeyName::Username),
        KeyName::Ldap(LdapKeyName::Groups),
    ];
    assert_eq!(k::key_count(k::KeyFamily::Ldap), variants.len());
    for (i, v) in variants.iter().enumerate() {
        let name = <&str>::from(v);
        assert_eq!(k::key_name(k::KeyFamily::Ldap, i), b(name));
        assert!(k::contains_name(k::KeyFamily::Ldap, name.as_bytes()));
        assert_eq!(
            k::is_server_derived(k::KeyFamily::Ldap, name.as_bytes()),
            v.is_server_derived()
        );
    }
    assert!(k::key_name(k::KeyFamily::Ldap, variants.len()).is_empty());
    all.push((k::KeyFamily::Ldap, variants));
    let variants = vec![KeyName::Sts(StsKeyName::STSDurationSeconds)];
    assert_eq!(k::key_count(k::KeyFamily::Sts), variants.len());
    for (i, v) in variants.iter().enumerate() {
        let name = <&str>::from(v);
        assert_eq!(k::key_name(k::KeyFamily::Sts, i), b(name));
        assert!(k::contains_name(k::KeyFamily::Sts, name.as_bytes()));
        assert_eq!(
            k::is_server_derived(k::KeyFamily::Sts, name.as_bytes()),
            v.is_server_derived()
        );
    }
    assert!(k::key_name(k::KeyFamily::Sts, variants.len()).is_empty());
    all.push((k::KeyFamily::Sts, variants));
    let variants = vec![
        KeyName::Aws(AwsKeyName::AWSReferer),
        KeyName::Aws(AwsKeyName::AWSSourceIP),
        KeyName::Aws(AwsKeyName::AWSUserAgent),
        KeyName::Aws(AwsKeyName::AWSSecureTransport),
        KeyName::Aws(AwsKeyName::AWSCurrentTime),
        KeyName::Aws(AwsKeyName::AWSEpochTime),
        KeyName::Aws(AwsKeyName::AWSPrincipalType),
        KeyName::Aws(AwsKeyName::AWSUserID),
        KeyName::Aws(AwsKeyName::AWSUsername),
        KeyName::Aws(AwsKeyName::AWSGroups),
        KeyName::Aws(AwsKeyName::AWSSourceArn),
        KeyName::Aws(AwsKeyName::AWSSourceAccount),
    ];
    assert_eq!(k::key_count(k::KeyFamily::Aws), variants.len());
    for (i, v) in variants.iter().enumerate() {
        let name = <&str>::from(v);
        assert_eq!(k::key_name(k::KeyFamily::Aws, i), b(name));
        assert!(k::contains_name(k::KeyFamily::Aws, name.as_bytes()));
        assert_eq!(
            k::is_server_derived(k::KeyFamily::Aws, name.as_bytes()),
            v.is_server_derived()
        );
    }
    assert!(k::key_name(k::KeyFamily::Aws, variants.len()).is_empty());
    all.push((k::KeyFamily::Aws, variants));
    let mut rng = Rng(312);
    for _ in 0..20000 {
        let (family, vs) = rng.pick(&all);
        let names = vs.iter().map(|v| <&str>::from(v)).collect::<Vec<_>>();
        let raw = if rng.chance(40) {
            rng.pick(&names).to_string()
        } else {
            (0..rng.below(40))
                .map(|_| char::from(*rng.pick(b"aws:jwt:s3:ABCabcdefghijklmnopqrstuvwxyz_/*")))
                .collect()
        };
        assert_eq!(
            k::contains_name(*family, raw.as_bytes()),
            names.contains(&raw.as_str())
        );
        if !names.contains(&raw.as_str()) {
            assert!(!k::is_server_derived(*family, raw.as_bytes()));
        }
    }
    assert_eq!(
        k::server_derived_key_names(),
        KeyName::server_derived_key_names()
            .map(b)
            .collect::<Vec<_>>()
    );
    for name in KeyName::COMMON_KEYS.iter().map(KeyName::name).chain([
        "",
        "Username",
        "SOURCEIP",
        "nosuch",
        "username/foo",
        "s3:prefix",
        "É",
    ]) {
        for form in [
            name.to_string(),
            name.to_ascii_uppercase(),
            name.to_ascii_lowercase(),
        ] {
            assert_eq!(
                k::is_server_derived_condition_key(form.as_bytes()),
                rustfs_private_oracle::policy::is_server_derived_condition_key(&form)
            );
        }
    }
}
