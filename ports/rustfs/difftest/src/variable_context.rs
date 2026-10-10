use crate::claim_tests::{claims, draw};
use crate::tests::{Rng, b};
use rustfs_kernel::{condfuncs::Env, varctx as k};
use rustfs_private_oracle::policy::variables::{
    PolicyVariableResolver, VariableContext, VariableResolver,
};
use serde_json::json;
#[test]
fn context_agrees() {
    let default = k::context_new();
    let up = VariableContext::new();
    assert_eq!(default.is_https, up.is_https);
    assert_eq!(default.claims.is_some(), up.claims.is_some());
    assert_eq!(default.source_ip, up.source_ip.map(|s| b(&s)));
    assert_eq!(default.account_id, up.account_id.map(|s| b(&s)));
    assert_eq!(default.region, up.region.map(|s| b(&s)));
    assert_eq!(default.username, up.username.map(|s| b(&s)));
    assert_eq!(default.conditions.len(), up.conditions.len());
    assert_eq!(default.custom_variables.len(), up.custom_variables.len());
    let mut rng = Rng(903);
    for _ in 0..10000 {
        let mut uc = VariableContext::new();
        uc.is_https = rng.chance(50);
        let mut fields = (0..4)
            .map(|_| {
                if rng.chance(70) {
                    Some(
                        rng.pick(&["", "alice", "us-east-1", "123", "é"])
                            .to_string(),
                    )
                } else {
                    None
                }
            })
            .collect::<Vec<_>>();
        uc.username = fields.remove(0);
        uc.source_ip = fields.remove(0);
        uc.account_id = fields.remove(0);
        uc.region = fields.remove(0);
        if rng.chance(80) {
            let mut map = std::collections::HashMap::new();
            for name in [
                "sub",
                "parent",
                "roleArn",
                "sa-policy",
                "x",
                "SUB",
                "PARENT",
                "RoleArn",
            ] {
                if rng.chance(70) {
                    map.insert(name.to_string(), draw(&mut rng, 2));
                }
            }
            if rng.chance(50) {
                map.insert("sub".into(), json!(["first", 2, true, null, "last"]));
            }
            if rng.chance(20) {
                let number = rng.pick(&[
                    "-123",
                    "18446744073709551615",
                    "-9223372036854775808",
                    "-0.0",
                    "1.25",
                    "1e-250",
                    "1e250",
                ]);
                let v: serde_json::Value = serde_json::from_str(number).unwrap();
                map.insert(
                    "sub".into(),
                    if rng.chance(50) {
                        v.clone()
                    } else {
                        json!([null, {}, v, false, []])
                    },
                );
            }
            uc.claims = Some(map);
        }
        uc.custom_variables = (0..rng.below(5))
            .map(|i| (format!("k{i}"), rng.pick(&["", "x", "é"]).to_string()))
            .collect();
        let kc = k::VariableContext {
            is_https: uc.is_https,
            source_ip: uc.source_ip.as_ref().map(|s| b(s)),
            account_id: uc.account_id.as_ref().map(|s| b(s)),
            region: uc.region.as_ref().map(|s| b(s)),
            username: uc.username.as_ref().map(|s| b(s)),
            claims: uc.claims.as_ref().map(claims),
            conditions: vec![],
            custom_variables: uc
                .custom_variables
                .iter()
                .map(|(s, v)| (b(s), b(v)))
                .collect(),
        };
        let kr = k::resolver_new(kc);
        let ur = VariableResolver::new(uc);
        let env = Env {
            ips: vec![],
            now_rfc3339: b("2026-10-10T00:00:00Z"),
            now_epoch: b("1791590400"),
        };
        for name in [
            "sub",
            "parent",
            "roleArn",
            "sa-policy",
            "x",
            "SUB",
            "PARENT",
            "RoleArn",
            "missing",
        ] {
            assert_eq!(
                k::get_claim_as_strings(&kr, name.as_bytes()),
                ur.claim_strings_for_test(name)
                    .map(|v| v.iter().map(|s| b(s)).collect())
            );
        }
        for (name, f) in [
            (
                "aws:username",
                k::resolve_username as fn(&k::VariableResolver) -> Option<Vec<u8>>,
            ),
            ("aws:userid", k::resolve_userid),
            ("aws:SourceIp", k::resolve_source_ip),
            ("aws:AccountId", k::resolve_account_id),
            ("aws:Region", k::resolve_region),
        ] {
            assert_eq!(f(&kr), pollster::block_on(ur.resolve(name)).map(|s| b(&s)));
        }
        assert_eq!(
            k::resolve_principal_type(&kr),
            b(&pollster::block_on(ur.resolve("aws:PrincipalType")).unwrap())
        );
        assert_eq!(
            k::resolve_secure_transport(&kr),
            b(&pollster::block_on(ur.resolve("aws:SecureTransport")).unwrap())
        );
        for name in [
            "aws:username",
            "aws:userid",
            "aws:PrincipalType",
            "aws:SecureTransport",
            "aws:AccountId",
            "aws:Region",
            "aws:SourceIp",
            "custom:k0",
            "custom:k3",
            "custom:missing",
            "custom:",
            "CUSTOM:k0",
            "unknown",
            "aws:Username",
            "aws:currentTime",
            "AWS:userid",
        ] {
            assert_eq!(
                k::resolve(&kr, name.as_bytes(), &env),
                pollster::block_on(ur.resolve(name)).map(|s| b(&s))
            );
            assert_eq!(
                k::resolve_multiple(&kr, name.as_bytes(), &env),
                pollster::block_on(ur.resolve_multiple(name))
                    .map(|vs| vs.iter().map(|s| b(s)).collect())
            );
            assert_eq!(
                k::resolve_custom_variable(&kr, name.as_bytes()),
                if name.starts_with("custom:") {
                    pollster::block_on(ur.resolve(name)).map(|s| b(&s))
                } else {
                    None
                }
            );
            assert_eq!(k::is_dynamic(name.as_bytes()), ur.is_dynamic(name));
        }
        for name in ["aws:CurrentTime", "aws:EpochTime"] {
            assert_eq!(k::is_dynamic(name.as_bytes()), ur.is_dynamic(name));
            let v = if name == "aws:CurrentTime" {
                env.now_rfc3339.clone()
            } else {
                env.now_epoch.clone()
            };
            assert_eq!(k::resolve(&kr, name.as_bytes(), &env), Some(v.clone()));
            assert_eq!(
                k::resolve_multiple(&kr, name.as_bytes(), &env),
                Some(vec![v])
            );
        }
    }
}
