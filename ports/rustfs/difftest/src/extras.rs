use crate::tests::{Rng, b};
use rustfs_kernel::extras as k;
use rustfs_private_oracle::policy::{
    principal as p,
    utils::{path, wildcard},
};
use serde_json::json;
#[test]
fn extras_agree() {
    let mut rng = Rng(902);
    for _ in 0..20000 {
        let string = |rng: &mut Rng| {
            (0..rng.below(30))
                .map(|_| rng.pick(&["a", "b", "é", "*", "?", "/"]).to_string())
                .collect::<String>()
        };
        let s = string(&mut rng);
        let text = string(&mut rng);
        assert_eq!(
            k::is_match_as_pattern_prefix(s.as_bytes(), text.as_bytes()),
            wildcard::is_match_as_pattern_prefix(&s, &text)
        );
        let buf = k::lazybuf_new(s.as_bytes());
        let (us, ub, uw) = path::lazybuf_state(&s);
        assert_eq!(buf.source, b(&us));
        assert_eq!(buf.buffer.is_some(), ub);
        assert_eq!(buf.written, uw);
        let vs = (0..rng.below(5))
            .map(|_| rng.pick(&["", "*", "AWS", "service", "é"]).to_string())
            .collect::<Vec<_>>();
        for single in [true, false] {
            let input = if single { json!(&s) } else { json!(&vs) };
            let kv = if single {
                k::PrincipalValues::Single(b(&s))
            } else {
                k::PrincipalValues::Multiple(vs.iter().map(|s| b(s)).collect())
            };
            let mut actual = k::principal_values_into_set(kv);
            actual.sort();
            let mut expected = p::principal_values_set(input)
                .unwrap()
                .into_iter()
                .map(|s| b(&s))
                .collect::<Vec<_>>();
            expected.sort();
            assert_eq!(actual, expected);
        }
        let object = k::PrincipalFormat::Object(k::PrincipalObject {
            aws: Some(k::PrincipalValues::Single(b(&s))),
            service: None,
        });
        if let k::PrincipalFormat::Object(v) = object {
            assert!(v.aws.is_some());
            assert!(v.service.is_none());
        }
    }
    for v in [json!(null), json!(23), json!(["a", 7]), json!({"AWS":"*"})] {
        assert!(p::principal_values_set(v).is_err());
    }
}
