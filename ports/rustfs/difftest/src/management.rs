use crate::tests::{self, Rng, b};
use rustfs_kernel::{conddata as c, manage as k, stmts as s};
use rustfs_private_oracle::policy::{
    self as u, Validator,
    function::{self, condition::Condition as UC},
};
fn empty() -> c::Functions {
    c::Functions {
        for_any_value: vec![],
        for_all_values: vec![],
        for_normal: vec![],
    }
}
fn functions(rng: &mut Rng) -> (function::Functions, c::Functions) {
    let mut groups = vec![];
    let mut kf = empty();
    for q in 0..3 {
        let mut us = vec![];
        let mut ks = vec![];
        for _ in 0..rng.below(4) {
            let (mut up, mut port) = crate::condition_data::draw(rng);
            if rng.chance(50) {
                rename(&mut up, &mut port, "aws:username");
            }
            if rng.chance(20) {
                rename(&mut up, &mut port, "s3:prefix");
            }
            us.push(up);
            ks.push(port);
        }
        groups.push(us);
        match q {
            0 => kf.for_normal = ks,
            1 => kf.for_any_value = ks,
            _ => kf.for_all_values = ks,
        }
    }
    (
        function::with_all_conditions(groups.remove(0), groups.remove(0), groups.remove(0)),
        kf,
    )
}
fn rename(up: &mut UC, port: &mut c::Condition, name: &str) {
    let key = u::function::key::Key::try_from(name).unwrap();
    let kk = rustfs_kernel::condfuncs::Key {
        key_name: b(<&str>::from(&key.name)),
        name: b(key.name.name()),
        variable: None,
    };
    fn uk<T>(f: &mut u::function::func::InnerFunc<T>, key: &u::function::key::Key) {
        u::function::func::rename_keys_for_test(f, key);
    }
    fn replace_keys<T>(f: &mut c::InnerFunc<T>, key: &rustfs_kernel::condfuncs::Key) {
        for e in &mut f.entries {
            e.key = key.clone();
        }
    }
    match up {
        UC::IfExists(inner) => rename(inner, port, name),
        UC::StringEquals(f)
        | UC::StringNotEquals(f)
        | UC::StringEqualsIgnoreCase(f)
        | UC::StringNotEqualsIgnoreCase(f)
        | UC::StringLike(f)
        | UC::StringNotLike(f)
        | UC::ArnLike(f)
        | UC::ArnNotLike(f)
        | UC::ArnEquals(f)
        | UC::ArnNotEquals(f) => uk(f, &key),
        UC::BinaryEquals(f) => uk(f, &key),
        UC::IpAddress(f) | UC::NotIpAddress(f) => uk(f, &key),
        UC::Null(f) | UC::Bool(f) => uk(f, &key),
        UC::NumericEquals(f)
        | UC::NumericNotEquals(f)
        | UC::NumericLessThan(f)
        | UC::NumericLessThanEquals(f)
        | UC::NumericGreaterThan(f)
        | UC::NumericGreaterThanEquals(f)
        | UC::NumericGreaterThanIfExists(f) => uk(f, &key),
        UC::DateEquals(f)
        | UC::DateNotEquals(f)
        | UC::DateLessThan(f)
        | UC::DateLessThanEquals(f)
        | UC::DateGreaterThan(f)
        | UC::DateGreaterThanEquals(f) => uk(f, &key),
    }
    match &mut port.data {
        c::Data::Str(f) => replace_keys(f, &kk),
        c::Data::Num(f) => replace_keys(f, &kk),
        c::Data::Boolean(f) => replace_keys(f, &kk),
        c::Data::Addr(f) => replace_keys(f, &kk),
        c::Data::Date(f) => replace_keys(f, &kk),
        c::Data::Binary(f) => replace_keys(f, &kk),
    }
}
fn policy(rng: &mut Rng) -> (u::Policy, k::Policy) {
    let (old, kold) = tests::identity_policy(rng);
    let mut up: u::Policy = serde_json::from_str(&serde_json::to_string(&old).unwrap()).unwrap();
    up.id = (*rng.pick(&["", "id", "é"])).into();
    up.version = rng.pick(&["", "2012-10-17", "wrong"]).to_string();
    let mut sts = vec![];
    for (st, ks) in up.statements.iter_mut().zip(kold) {
        st.sid = (*rng.pick(&["", "one", "two"])).into();
        let (uf, kf) = functions(rng);
        st.conditions = uf;
        sts.push(k::Statement {
            sid: b(&st.sid),
            effect: ks.effect,
            actions: ks.actions,
            not_actions: ks.not_actions,
            resources: ks.resources,
            not_resources: ks.not_resources,
            conditions: kf,
        });
    }
    if rng.chance(20) {
        up.statements.clear();
        sts.clear();
    }
    (
        up.clone(),
        k::Policy {
            id: b(&up.id),
            version: b(&up.version),
            statements: sts,
        },
    )
}
fn assert_policy(up: &u::Policy, port: &k::Policy, sources: &[(u::Statement, k::Statement)]) {
    assert_eq!(port.id, b(&up.id));
    assert_eq!(port.version, b(&up.version));
    assert_eq!(port.statements.len(), up.statements.len());
    for (a, z) in up.statements.iter().zip(&port.statements) {
        let (_, original) = sources
            .iter()
            .find(|(candidate, _)| format!("{:?}", candidate) == format!("{:?}", a))
            .expect("upstream retains an original statement");
        assert_eq!(format!("{:?}", z), format!("{:?}", original));
        assert_eq!(z.sid, b(&a.sid));
        assert_eq!(format!("{:?}", z.effect), format!("{:?}", a.effect));
        assert_eq!(
            z.actions
                .iter()
                .map(|a| String::from_utf8(a.name.clone()).unwrap())
                .collect::<Vec<_>>(),
            a.actions
                .0
                .iter()
                .map(|a| <&str>::from(a).to_string())
                .collect::<Vec<_>>()
        );
        assert_eq!(z.not_actions.len(), a.not_actions.0.len());
        assert_eq!(z.resources.len(), a.resources.0.len());
        assert_eq!(z.not_resources.len(), a.not_resources.0.len());
        assert_eq!(c::is_empty(&z.conditions), a.conditions.is_empty());
    }
}
#[test]
fn management_agrees() {
    let mut rng = Rng(572);
    for _ in 0..4000 {
        let (mut up, mut port) = policy(&mut rng);
        let (other, kother) = policy(&mut rng);
        for (a, z) in up.statements.iter().zip(&port.statements) {
            for (u2, k2) in other.statements.iter().zip(&kother.statements) {
                assert_eq!(k::statement_eq(z, k2), a == u2);
            }
            let mut clone = z.clone();
            clone.sid = b("ignored");
            assert!(k::statement_eq(z, &clone));
        }
        if !up.statements.is_empty() {
            let mut duplicate = up.statements[0].clone();
            duplicate.sid = "kept?".into();
            up.statements.push(duplicate);
            let mut duplicate = port.statements[0].clone();
            duplicate.sid = b("kept?");
            port.statements.push(duplicate);
        }
        let source_pool = up
            .statements
            .iter()
            .cloned()
            .zip(port.statements.iter().cloned())
            .chain(
                other
                    .statements
                    .iter()
                    .cloned()
                    .zip(kother.statements.iter().cloned()),
            )
            .collect::<Vec<_>>();
        assert_eq!(k::is_empty(&port), up.is_empty());
        assert_eq!(
            crate::validation::err(k::is_valid(&port)),
            up.is_valid().map_err(|e| e.to_string())
        );
        assert_eq!(
            crate::validation::err(k::validate(&port)),
            up.validate().map_err(|e| e.to_string())
        );
        let resource = *rng.pick(&["", "bucket", "bucket/x", "key/a", "alias/a", "*"]);
        assert_eq!(
            k::match_resource(&port, resource.as_bytes()),
            pollster::block_on(up.match_resource(resource))
        );
        let inputs = if rng.chance(20) {
            vec![]
        } else {
            vec![port.clone(), kother]
        };
        let uinputs = if inputs.is_empty() {
            vec![]
        } else {
            vec![up.clone(), other]
        };
        assert_policy(
            &u::Policy::merge_policies(uinputs),
            &k::merge_policies(&inputs),
            &source_pool,
        );
        up.dedup_for_test();
        k::drop_duplicate_statements(&mut port);
        assert_policy(&up, &port, &source_pool);
    }
}
#[test]
fn tag_and_full_evaluation_agree() {
    let mut rng = Rng(573);
    for _ in 0..10000 {
        let (up, port) = policy(&mut rng);
        let mut req = tests::request(&mut rng);
        for name in [
            "ExistingObjectTag/k0",
            "ExistingObjectTag/k1",
            "ExistingObjectTag/k2",
            "ExistingObjectTag/k3",
        ] {
            if rng.chance(80) {
                req.conds.insert(
                    name.into(),
                    vec![
                        rng.pick(&[
                            "x",
                            "",
                            "1",
                            "true",
                            "YQ==",
                            "invalid",
                            "2025-01-01T00:00:00Z",
                        ])
                        .to_string(),
                    ],
                );
            }
        }
        let kargs = tests::kargs(&req);
        let env = tests::env(&req.conds);
        let uargs = u::Args {
            account: &req.account,
            groups: &None,
            action: u::action::Action::try_from(<&str>::from(&req.action)).unwrap(),
            bucket: &req.bucket,
            object: &req.object,
            conditions: &req.conds,
            claims: &req.claims,
            is_owner: req.is_owner,
            deny_only: req.deny_only,
        };
        assert_eq!(
            k::policy_uses_existing_object_tag_conditions(&port),
            u::policy_uses_existing_object_tag_conditions(&up)
        );
        assert_eq!(
            k::policy_needs_existing_object_tag_for_args(&port, &kargs, &env),
            pollster::block_on(u::policy_needs_existing_object_tag_for_args(&up, &uargs))
        );
        assert_eq!(
            k::policy_is_allowed(&port, &kargs, &env),
            pollster::block_on(up.is_allowed(&uargs))
        );
        let mut ub = u::BucketPolicy {
            id: up.id.clone(),
            version: up.version.clone(),
            statements: vec![],
        };
        let mut kb = k::BucketPolicy {
            id: port.id.clone(),
            version: port.version.clone(),
            statements: vec![],
        };
        for (a, z) in up.statements.iter().zip(&port.statements) {
            assert_eq!(
                k::functions_use_existing_object_tag(&z.conditions),
                u::functions_use_existing_object_tag(&a.conditions)
            );
            assert_eq!(
                k::statement_is_allowed(z, &kargs, &env),
                pollster::block_on(a.is_allowed(&uargs))
            );
            let principals = if rng.chance(50) {
                vec!["*"]
            } else {
                vec!["alice"]
            };
            let principal = serde_json::from_value(serde_json::json!({"AWS":principals})).unwrap();
            ub.statements.push(u::statement::BPStatement {
                sid: a.sid.clone(),
                effect: a.effect.clone(),
                principal,
                actions: a.actions.clone(),
                not_actions: a.not_actions.clone(),
                resources: a.resources.clone(),
                not_resources: a.not_resources.clone(),
                conditions: a.conditions.clone(),
            });
            kb.statements.push(k::BPStatement {
                sid: z.sid.clone(),
                effect: z.effect,
                principal: s::Principal {
                    aws: principals.iter().map(|s| b(s)).collect(),
                    service: vec![],
                },
                actions: z.actions.clone(),
                not_actions: z.not_actions.clone(),
                resources: z.resources.clone(),
                not_resources: z.not_resources.clone(),
                conditions: z.conditions.clone(),
            });
        }
        let uba = u::BucketPolicyArgs {
            account: &req.account,
            groups: &None,
            action: uargs.action.clone(),
            bucket: &req.bucket,
            object: &req.object,
            conditions: &req.conds,
            is_owner: req.is_owner,
        };
        let kba = s::BucketPolicyArgs {
            account: kargs.account.clone(),
            action: kargs.action.clone(),
            bucket: kargs.bucket.clone(),
            object: kargs.object.clone(),
            conditions: kargs.conditions.clone(),
            is_owner: kargs.is_owner,
        };
        assert_eq!(
            crate::validation::err(k::bucket_is_valid(&kb)),
            ub.is_valid().map_err(|e| e.to_string())
        );
        assert_eq!(
            k::bucket_policy_uses_existing_object_tag_conditions(&kb),
            u::bucket_policy_uses_existing_object_tag_conditions(&ub)
        );
        assert_eq!(
            k::bucket_policy_needs_existing_object_tag_for_args(&kb, &kba),
            pollster::block_on(u::bucket_policy_needs_existing_object_tag_for_args(
                &ub, &uba
            ))
        );
        assert_eq!(
            k::bucket_policy_is_allowed(&kb, &kba, &env),
            pollster::block_on(ub.is_allowed(&uba))
        );
        for (a, z) in ub.statements.iter().zip(&kb.statements) {
            assert_eq!(
                k::bp_statement_is_allowed(z, &kba, &env),
                pollster::block_on(a.is_allowed(&uba))
            );
        }
    }
}
