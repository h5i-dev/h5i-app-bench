use crate::tests::*;
use rustfs_kernel::{valids as k, resets as rs, rsrc::Resource, stmts::{Effect, Statement, BPStatement, Principal}};
use rustfs_policy::policy::{self as u, Validator};
use rustfs_private_oracle::policy::Validator as _;
use rustfs_policy::policy::resource::Resource as UR;
use rustfs_private_oracle::policy::statement as private;

fn err(result: Result<(), k::ValidationError>) -> Result<(), String> {
    use k::ErrorKind::*;
    result.map_err(|e| match e.kind {
        InvalidVersion => format!("invalid Version '{}'", String::from_utf8(e.value).unwrap()),
        NonAction => "both 'Action' and 'NotAction' are empty".into(),
        BothActionAndNotAction => "'Action' and 'NotAction' cannot both be specified in the same statement".into(),
        MixedActionFamilies => "'Action' contains mixed action families in the same statement".into(),
        NonResource => "'Resource' is empty".into(),
        BothResourceAndNotResource => "'Resource' and 'NotResource' cannot both be specified in the same statement".into(),
        KmsResourceWithNonKmsAction => "KMS resources require a statement whose actions are all KMS actions".into(),
        KmsUnsupportedInBucketPolicy => "bucket policies do not support KMS actions or resources".into(),
        InvalidResource => format!("invalid resource, type: '{}', pattern: '{}'", String::from_utf8(e.family).unwrap(), String::from_utf8(e.value).unwrap()),
        EmptyPrincipal => "io error: Principal is empty".into(),
    })
}
fn kr(r: &UR) -> Resource { match r { UR::S3(s) => Resource::S3(b(s)), UR::Kms(s) => Resource::Kms(b(s)) } }
const PATTERNS: &[&str] = &["", "/", "/bucket", "bucket/*", "bucket", "*", "key/", "key/k1", "key/k*/a", "key/k\\x", "alias/", "alias/a/b", "alias/a\\b", "é", "..", "key/é", "alias//"];
fn resource(rng: &mut Rng) -> UR { if rng.chance(50) { UR::S3(rng.pick(PATTERNS).to_string()) } else { UR::Kms(rng.pick(PATTERNS).to_string()) } }
fn resources(rng: &mut Rng) -> u::ResourceSet { u::ResourceSet((0..rng.below(5)).map(|_| resource(rng)).collect()) }

#[test]
fn resource_helpers_agree() {
    let mut rng = Rng(911);
    for _ in 0..10000 {
        let left = resources(&mut rng); let right = resources(&mut rng);
        let kl = left.0.iter().map(kr).collect::<Vec<_>>(); let kr = right.0.iter().map(kr).collect::<Vec<_>>();
        assert_eq!(rs::is_empty(&kl), left.is_empty()); assert_eq!(rs::as_slice(&kl), kl);
        assert_eq!(rs::eq(&kl, &kr), left == right);
        let mut reversed = kl.clone(); reversed.reverse(); reversed.extend(kl.clone()); assert!(rs::eq(&kl, &reversed));
        assert_eq!(err(k::resources_is_valid(&kl)), left.is_valid().map_err(|e| e.to_string()));
        for (up, port) in left.0.iter().zip(&kl) { assert_eq!(err(k::resource_is_valid(port)), up.is_valid().map_err(|e| e.to_string())); }
        let mut unique = Vec::new(); for r in &kl { rs::push_unique(&mut unique, r.clone()); }
        let mut expected = Vec::new(); for r in &left.0 { if !expected.contains(r) { expected.push(r.clone()); } }
        assert_eq!(unique, expected.iter().map(crate_resource).collect::<Vec<_>>());
        let name = *rng.pick(PATTERNS); let values = std::collections::HashMap::new();
        assert_eq!(rs::set_matches(&kl, name.as_bytes(), &vec![]), pollster::block_on(left.is_match(name, &values)));
        assert_eq!(rs::set_match_resource(&kl, name.as_bytes()), pollster::block_on(left.match_resource(name)));
        for (up, port) in left.0.iter().zip(&kl) {
            assert_eq!(rs::is_match(port, name.as_bytes(), &vec![]), pollster::block_on(up.is_match(name, &values)));
            assert_eq!(rs::match_resource(port, name.as_bytes()), pollster::block_on(up.match_resource(name)));
            assert_eq!(rs::member(&kl, port), left.0.contains(up));
        }
    }
}
fn crate_resource(r: &UR) -> Resource { kr(r) }

#[test]
fn statement_validation_agrees() {
    let mut rng = Rng(912);
    for _ in 0..30000 {
        let draw_action = |rng: &mut Rng| if rng.chance(20) { u::action::Action::None } else { u::action::Action::try_from(*rng.pick(ACTIONS)).unwrap() };
        let effect = if rng.chance(50) { u::Effect::Allow } else { u::Effect::Deny };
        let up = u::Statement { effect: effect.clone(), sid: (*rng.pick(&["", "SID", "é"])).into(),
            actions: u::ActionSet((0..rng.below(4)).map(|_| draw_action(&mut rng)).collect()),
            not_actions: u::ActionSet((0..rng.below(4)).map(|_| draw_action(&mut rng)).collect()),
            resources: resources(&mut rng), not_resources: resources(&mut rng), conditions: Default::default() };
        let port = Statement { effect: if effect == u::Effect::Allow { Effect::Allow } else { Effect::Deny },
            actions: up.actions.0.iter().map(kaction).collect(), not_actions: up.not_actions.0.iter().map(kaction).collect(),
            resources: up.resources.0.iter().map(kr).collect(), not_resources: up.not_resources.0.iter().map(kr).collect(),
            conditions: rustfs_kernel::condfuncs::Functions { for_any_value: vec![], for_all_values: vec![], for_normal: vec![] } };
        assert_eq!(err(k::statement_is_valid(&port, up.sid.as_bytes())), up.is_valid().map_err(|e| e.to_string()));
        let names = up.actions.0.iter().map(|a| if matches!(a, u::action::Action::None) { None } else { Some(<&str>::from(a).to_owned()) }).collect();
        let (admin, sts, family) = private::classify_actions(names);
        assert_eq!(k::is_admin(&port), admin); assert_eq!(k::is_sts(&port), sts);
        let f = k::action_family(&port).map(|f| match f { k::ActionFamily::S3 => 0, k::ActionFamily::Admin => 1, k::ActionFamily::Sts => 2, k::ActionFamily::Kms => 3, k::ActionFamily::Mixed => 4 });
        assert_eq!(f, family);
        assert_eq!(k::id_is_empty(up.sid.as_bytes()), up.sid.is_empty());
        assert_eq!(k::id_as_slice(up.sid.as_bytes()), up.sid.as_bytes()); assert_eq!(k::id_is_valid(up.sid.as_bytes()), up.sid.is_valid().is_ok());
        assert_eq!(k::effect_is_valid(port.effect), effect.is_valid().is_ok()); assert_eq!(k::default_is_valid(), rustfs_private_oracle::policy::function::key::Key::try_from("aws:username").unwrap().is_valid().is_ok());
        let aws = if rng.chance(50) { vec!["*".to_string()] } else { vec![] };
        let service = if rng.chance(50) { vec!["service".to_string()] } else { vec![] };
        let principal: u::Principal = if aws.is_empty() && service.is_empty() { Default::default() } else { serde_json::from_value(serde_json::json!({"AWS":aws,"Service":service})).unwrap() };
        let kp = Principal { aws: aws.iter().map(|s|b(s)).collect(), service: service.iter().map(|s|b(s)).collect() };
        assert_eq!(err(k::principal_is_valid(&kp)), principal.is_valid().map_err(|e|e.to_string()));
        let bp = u::statement::BPStatement { sid: up.sid.clone(), effect, principal, actions: up.actions.clone(), not_actions: up.not_actions.clone(), resources: up.resources.clone(), not_resources: up.not_resources.clone(), conditions: Default::default() };
        let kb = BPStatement { effect: port.effect, principal: kp, actions: port.actions.clone(), not_actions: port.not_actions.clone(), resources: port.resources.clone(), not_resources: port.not_resources.clone(), conditions: port.conditions.clone() };
        assert_eq!(err(k::bp_statement_is_valid(&kb, up.sid.as_bytes())), bp.is_valid().map_err(|e|e.to_string()));
    }
}
