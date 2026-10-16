//! Built-ins compared structurally and on generated requests against the pinned table.
use crate::tests::*;
use rustfs_kernel::{defaults as k, rsrc::Resource, stmts::Statement};
use rustfs_policy::policy::{Policy, default as u};

fn compare_statement(up: &rustfs_policy::policy::Statement, port: &Statement) {
    use rustfs_policy::policy::resource::Resource as UResource;
    assert_eq!(format!("{:?}", up.effect), format!("{:?}", port.effect));
    assert_eq!(
        up.actions.0.iter().map(kaction).collect::<Vec<_>>(),
        port.actions
    );
    assert_eq!(
        up.not_actions.0.iter().map(kaction).collect::<Vec<_>>(),
        port.not_actions
    );
    let resources = |rs: &rustfs_policy::policy::ResourceSet| {
        rs.0.iter()
            .map(|r| match r {
                UResource::S3(s) => Resource::S3(b(s)),
                UResource::Kms(s) => Resource::Kms(b(s)),
            })
            .collect::<Vec<_>>()
    };
    assert_eq!(resources(&up.resources), port.resources);
    assert_eq!(resources(&up.not_resources), port.not_resources);
    assert!(
        port.conditions.for_normal.is_empty()
            && port.conditions.for_any_value.is_empty()
            && port.conditions.for_all_values.is_empty()
    );
    assert_eq!(
        serde_json::to_value(&up.conditions).unwrap(),
        serde_json::json!({})
    );
}

#[test]
fn builtin_policies_agree() {
    let ports = k::default_policies();
    assert_eq!(ports.len(), u::DEFAULT_POLICIES.len());
    for ((uname, up), (name, port)) in u::DEFAULT_POLICIES.iter().zip(&ports) {
        assert_eq!(uname.as_bytes(), name);
        assert_eq!(
            serde_json::to_value(&up.id).unwrap(),
            serde_json::json!(String::from_utf8(port.id.clone()).unwrap())
        );
        assert_eq!(up.version.as_bytes(), port.version);
        assert_eq!(up.statements.len(), port.statements.len());
        for (s, t) in up.statements.iter().zip(&port.statements) {
            compare_statement(s, t);
        }
        let mut rng = Rng(713);
        for _ in 0..2000 {
            let q = request(&mut rng);
            assert_eq!(
                upstream_identity(up, &q),
                rustfs_kernel::policies::policy_is_allowed(
                    &port.statements,
                    &kargs(&q),
                    &env(&q.conds)
                )
            );
        }
    }
    assert_eq!(
        k::default_version(),
        rustfs_policy::policy::DEFAULT_VERSION.as_bytes()
    );
    assert_eq!(
        k::kms_key_administrator(),
        u::KMS_KEY_ADMINISTRATOR.as_bytes()
    );
    assert_eq!(k::kms_key_user(), u::KMS_KEY_USER.as_bytes());
    assert_eq!(k::kms_auditor(), u::KMS_AUDITOR.as_bytes());
    assert_eq!(k::all_kms_keys(), b("*"));
    // Exercise the constructors with empty and mixed lists as well as the valid canned inputs.
    let mut rng = Rng(714);
    for _ in 0..1000 {
        let actions = (0..rng.below(8))
            .map(|_| rustfs_policy::policy::action::Action::try_from(*rng.pick(ACTIONS)).unwrap())
            .collect::<Vec<_>>();
        let up = rustfs_policy::policy::Statement {
            effect: rustfs_policy::policy::Effect::Allow,
            actions: rustfs_policy::policy::ActionSet(actions.clone()),
            resources: rustfs_policy::policy::ResourceSet(vec![
                rustfs_policy::policy::resource::Resource::Kms("*".into()),
            ]),
            ..Default::default()
        };
        compare_statement(&up, &k::kms_allow(actions.iter().map(kaction).collect()));
    }
    let up: Policy = serde_json::from_value(
        serde_json::json!({"Statement":[{"Effect":"Allow", "Action":"sts:AssumeRole"}]}),
    )
    .unwrap();
    compare_statement(&up.statements[0], &k::assume_role_allow());
}
