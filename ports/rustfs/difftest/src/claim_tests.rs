use crate::tests::{Rng, b};
use rustfs_kernel::{claims as k, unicode};
use rustfs_private_oracle::policy::{
    self as u,
    utils::{self as utils, ClaimLookup},
};
use serde_json::{Value, json};
pub fn value(v: &Value) -> k::Value {
    match v {
        Value::Null => k::Value::Null,
        Value::Bool(v) => k::Value::Bool(*v),
        Value::Number(v) => k::Value::Number(b(&v.to_string())),
        Value::String(v) => k::Value::String(b(v)),
        Value::Array(v) => k::Value::Array(v.iter().map(value).collect()),
        Value::Object(v) => k::Value::Object(v.iter().map(|(s, v)| (b(s), value(v))).collect()),
    }
}
pub fn claims(v: &std::collections::HashMap<String, Value>) -> k::Claims {
    v.iter().map(|(s, v)| (b(s), value(v))).collect()
}
pub(crate) fn draw(rng: &mut Rng, depth: usize) -> Value {
    match rng.below(if depth == 0 { 4 } else { 6 }) {
        0 => Value::Null,
        1 => json!(rng.chance(50)),
        2 => json!(rng.below(100)),
        3 => json!(rng.pick(&[
            "",
            " a,b , a",
            "é,é",
            "\u{2003}x\u{2003},y",
            " , ",
            "ExistingObjectTag/foo",
            "admin,readonly"
        ])),
        4 => Value::Array((0..rng.below(4)).map(|_| draw(rng, depth - 1)).collect()),
        _ => {
            let mut m = serde_json::Map::new();
            for _ in 0..rng.below(4) {
                m.insert(
                    rng.pick(&[
                        "ExistingObjectTag",
                        "s3:ExistingObjectTag/foo",
                        "x",
                        "existingobjecttag",
                        "ExistingObjectTags",
                    ])
                    .to_string(),
                    draw(rng, depth - 1),
                );
            }
            Value::Object(m)
        }
    }
}
#[test]
fn claims_agree() {
    let mut rng = Rng(211);
    for _ in 0..10000 {
        let mut up = std::collections::HashMap::new();
        for _ in 0..rng.below(8) {
            up.insert(
                rng.pick(&[
                    "policy", "POLICY", "Policy", "PoLiCy", "roleArn", "ROLEARN", "İ", "i\u{307}",
                    "É", "é", "Σ", "σ",
                ])
                .to_string(),
                draw(&mut rng, 2),
            );
        }
        let port = claims(&up);
        let query = rng.pick(&[
            "policy", "POLICY", "pOLICy", "roleArn", "İ", "i\u{307}", "É", "é", "Σ", "σ", "missing",
        ]);
        let look = utils::get_claim_case_insensitive(&up, query);
        match (k::get_claim_case_insensitive(&port, query.as_bytes()), look) {
            (k::ClaimLookup::Missing, ClaimLookup::Missing)
            | (k::ClaimLookup::Ambiguous, ClaimLookup::Ambiguous) => {}
            (k::ClaimLookup::Found(i), ClaimLookup::Found(v)) => {
                assert_eq!(json_value(&port[i].1), *v)
            }
            other => panic!("lookup mismatch {other:?}"),
        }
        let exact = up.get(*query);
        assert_eq!(k::find(&port, query.as_bytes()).is_some(), exact.is_some());
        let (v, present) = utils::_get_values_from_claims(&up, query);
        assert_eq!(
            k::values_from_claims(&port, query.as_bytes()),
            (v.iter().map(|s| b(s)).collect(), present)
        );
        let (v, present) = u::get_policies_from_claims(&up, query);
        let mut expected = v.iter().map(|s| b(s)).collect::<Vec<_>>();
        expected.sort();
        for f in [
            k::get_values_from_claims,
            k::get_policies_from_claims,
            k::args_get_policies,
        ] {
            let (mut actual, p) = f(&port, query.as_bytes());
            actual.sort();
            assert_eq!((actual, p), (expected.clone(), present));
        }
        assert_eq!(
            k::get_role_arn(&port),
            up.get("roleArn").and_then(Value::as_str).map(b)
        );
        let args = u::Args {
            account: "a",
            groups: &None,
            action: u::action::Action::None,
            bucket: "",
            conditions: &Default::default(),
            is_owner: false,
            object: "",
            claims: &up,
            deny_only: false,
        };
        assert_eq!(k::get_role_arn(&port), args.get_role_arn().map(b));
        let (v, p) = args.get_policies(query);
        assert_eq!(v.len(), expected.len());
        assert_eq!(p, present);
        let v = draw(&mut rng, 3);
        assert_eq!(
            k::value_uses_existing_object_tag(&value(&v)),
            u::value_uses_existing_object_tag_condition_key(&v)
        );
        let path = (0..rng.below(20))
            .map(|_| rng.pick(&["a", "é", "/", "."]).to_string())
            .collect::<String>();
        for second in [true, false] {
            let (a, z) = utils::_split_path(&path, second);
            assert_eq!(k::split_path(path.as_bytes(), second), (b(a), b(z)));
        }
    }
    assert_eq!(
        k::iam_policy_claim_name_sa(),
        b(&u::iam_policy_claim_name_sa())
    );
    for name in [
        "ExistingObjectTag",
        "ExistingObjectTag/",
        "s3:ExistingObjectTag",
        "s3:ExistingObjectTag/foo",
        "",
        "s3:existingObjectTag",
        "ExistingObjectTagger",
    ] {
        assert_eq!(
            k::is_existing_object_tag_condition_key(name.as_bytes()),
            u::is_existing_object_tag_condition_key(name)
        );
    }
}
#[test]
fn unicode_agrees() {
    for cp in 0..=0x10ffff {
        if let Some(ch) = char::from_u32(cp) {
            let s = ch.to_string();
            let expected = ch.to_lowercase().collect::<String>();
            let (a, z, count) = unicode::lowercase_scalar(cp);
            let mut out = String::new();
            out.push(char::from_u32(a).unwrap());
            if count == 2 {
                out.push(char::from_u32(z).unwrap());
            }
            assert_eq!(out, expected, "U+{cp:X}");
            assert_eq!(unicode::scalar_at(s.as_bytes(), 0), (cp, s.len()));
            let mut bytes = vec![];
            unicode::append_scalar(&mut bytes, cp);
            assert_eq!(bytes, b(&s));
            assert_eq!(unicode::whitespace(cp), ch.is_whitespace());
        }
    }
    let strings = [
        "",
        "ÉİΣABC",
        "e\u{301}",
        "i\u{307}",
        "\u{2003} x \u{2003}",
        "\t\r\n\u{a0}",
        "ΟΣ",
        "ος",
        "οσ",
        "𐐀",
        "𐐨",
    ];
    for a in strings {
        assert_eq!(
            unicode::lower(a.as_bytes()),
            b(&a.chars().flat_map(char::to_lowercase).collect::<String>())
        );
        assert_eq!(unicode::trim(a.as_bytes()), b(a.trim()));
        let expected = a
            .split(',')
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .map(b)
            .collect::<Vec<_>>();
        assert_eq!(k::split_values(a.as_bytes()), expected);
        for z in strings {
            assert_eq!(
                k::case_insensitive_eq(a.as_bytes(), z.as_bytes()),
                a.chars()
                    .flat_map(char::to_lowercase)
                    .eq(z.chars().flat_map(char::to_lowercase))
            );
        }
    }
}

fn json_value(v: &k::Value) -> Value {
    match v {
        k::Value::Null => Value::Null,
        k::Value::Bool(b) => Value::Bool(*b),
        k::Value::Number(n) => serde_json::from_slice(n).unwrap(),
        k::Value::String(s) => Value::String(String::from_utf8(s.clone()).unwrap()),
        k::Value::Array(a) => Value::Array(a.iter().map(json_value).collect()),
        k::Value::Object(o) => Value::Object(
            o.iter()
                .map(|(key, v)| (String::from_utf8(key.clone()).unwrap(), json_value(v)))
                .collect(),
        ),
    }
}
