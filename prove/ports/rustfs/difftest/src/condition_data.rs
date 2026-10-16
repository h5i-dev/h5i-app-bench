use crate::tests::{Rng, b};
use rustfs_kernel::{
    conddata as k,
    condfuncs::{IpAddr, Key},
    dates,
};
use rustfs_private_oracle::{
    policy::function::{
        binary::BinaryFuncValue, condition::Condition as UC, func::InnerFunc, key::Key as UK,
        key_name::KeyName,
    },
    time::{OffsetDateTime, format_description::well_known::Rfc3339},
};
use serde_json::json;
fn key(name: &str) -> Key {
    let up = UK::try_from(name).unwrap();
    Key {
        key_name: b(<&str>::from(&up.name)),
        name: b(up.name.name()),
        variable: up.variable.clone().map(|s| b(&s)),
    }
}
const OPS: &[k::Op] = &[
    k::Op::StringEquals,
    k::Op::StringNotEquals,
    k::Op::StringEqualsIgnoreCase,
    k::Op::StringNotEqualsIgnoreCase,
    k::Op::StringLike,
    k::Op::StringNotLike,
    k::Op::ArnLike,
    k::Op::ArnNotLike,
    k::Op::ArnEquals,
    k::Op::ArnNotEquals,
    k::Op::BinaryEquals,
    k::Op::IpAddress,
    k::Op::NotIpAddress,
    k::Op::Null,
    k::Op::Boolean,
    k::Op::NumericEquals,
    k::Op::NumericNotEquals,
    k::Op::NumericLessThan,
    k::Op::NumericLessThanEquals,
    k::Op::NumericGreaterThan,
    k::Op::NumericGreaterThanIfExists,
    k::Op::NumericGreaterThanEquals,
    k::Op::DateEquals,
    k::Op::DateNotEquals,
    k::Op::DateLessThan,
    k::Op::DateLessThanEquals,
    k::Op::DateGreaterThan,
    k::Op::DateGreaterThanEquals,
];
pub(crate) fn draw(rng: &mut Rng) -> (UC, k::Condition) {
    let index = rng.below(OPS.len() as u64) as usize;
    let op = OPS[index];
    let count = 1 + rng.below(4);
    let mut map = serde_json::Map::new();
    let mut str_entries = vec![];
    let mut num_entries = vec![];
    let mut bool_entries = vec![];
    let mut ip_entries = vec![];
    let mut date_entries = vec![];
    let mut bin_entries = vec![];
    for i in 0..count {
        let name = format!("s3:ExistingObjectTag/k{i}");
        let kk = key(&name);
        let v = match op {
            k::Op::Boolean | k::Op::Null => {
                let v = rng.chance(50);
                bool_entries.push(k::FuncKeyValue { key: kk, values: v });
                json!(v)
            }
            k::Op::IpAddress | k::Op::NotIpAddress => {
                let n = rng.below(255) as u32;
                ip_entries.push(k::FuncKeyValue {
                    key: kk,
                    values: vec![(IpAddr::V4((10 << 24) | (n << 8)), 24)],
                });
                json!([format!("10.0.{n}.0/24")])
            }
            k::Op::DateEquals
            | k::Op::DateNotEquals
            | k::Op::DateLessThan
            | k::Op::DateLessThanEquals
            | k::Op::DateGreaterThan
            | k::Op::DateGreaterThanEquals => {
                let s = format!("2026-10-{:02}T12:00:00Z", 1 + rng.below(28));
                date_entries.push(k::FuncKeyValue {
                    key: kk,
                    values: dates::parse_value(s.as_bytes()).unwrap(),
                });
                json!(s)
            }
            k::Op::BinaryEquals => {
                let s = *rng.pick(&["", "YQ==", "YWI=", "YWJj"]);
                bin_entries.push(k::FuncKeyValue {
                    key: kk,
                    values: k::binary_new(s.as_bytes()).unwrap(),
                });
                json!(s)
            }
            k::Op::NumericEquals
            | k::Op::NumericNotEquals
            | k::Op::NumericLessThan
            | k::Op::NumericLessThanEquals
            | k::Op::NumericGreaterThan
            | k::Op::NumericGreaterThanIfExists
            | k::Op::NumericGreaterThanEquals => {
                let n = rng.below(200) as i64 - 100;
                num_entries.push(k::FuncKeyValue { key: kk, values: n });
                json!(n)
            }
            _ => {
                let vs = (0..1 + rng.below(4))
                    .map(|_| rng.pick(&["a", "b", "*", "é"]).to_string())
                    .collect::<Vec<_>>();
                str_entries.push(k::FuncKeyValue {
                    key: kk,
                    values: vs.iter().map(|s| b(s)).collect(),
                });
                json!(vs)
            }
        };
        map.insert(name, v);
    }
    let names = [
        "StringEquals",
        "StringNotEquals",
        "StringEqualsIgnoreCase",
        "StringNotEqualsIgnoreCase",
        "StringLike",
        "StringNotLike",
        "ArnLike",
        "ArnNotLike",
        "ArnEquals",
        "ArnNotEquals",
        "BinaryEquals",
        "IpAddress",
        "NotIpAddress",
        "Null",
        "Bool",
        "NumericEquals",
        "NumericNotEquals",
        "NumericLessThan",
        "NumericLessThanEquals",
        "NumericGreaterThan",
        "NumericGreaterThanIfExists",
        "NumericGreaterThanEquals",
        "DateEquals",
        "DateNotEquals",
        "DateLessThan",
        "DateLessThanEquals",
        "DateGreaterThan",
        "DateGreaterThanEquals",
    ];
    let name = names[index].to_string();
    assert_eq!(k::op_name(op), b(&name));
    let uf: rustfs_private_oracle::policy::Functions = decode(json!({name.clone():map})).unwrap();
    let mut up = rustfs_private_oracle::policy::function::normal_conditions(uf).remove(0);
    let data = match op {
        k::Op::Boolean | k::Op::Null => k::Data::Boolean(k::InnerFunc {
            entries: bool_entries,
        }),
        k::Op::IpAddress | k::Op::NotIpAddress => k::Data::Addr(k::InnerFunc {
            entries: ip_entries,
        }),
        k::Op::DateEquals
        | k::Op::DateNotEquals
        | k::Op::DateLessThan
        | k::Op::DateLessThanEquals
        | k::Op::DateGreaterThan
        | k::Op::DateGreaterThanEquals => k::Data::Date(k::InnerFunc {
            entries: date_entries,
        }),
        k::Op::BinaryEquals => k::Data::Binary(k::InnerFunc {
            entries: bin_entries,
        }),
        k::Op::NumericEquals
        | k::Op::NumericNotEquals
        | k::Op::NumericLessThan
        | k::Op::NumericLessThanEquals
        | k::Op::NumericGreaterThan
        | k::Op::NumericGreaterThanIfExists
        | k::Op::NumericGreaterThanEquals => k::Data::Num(k::InnerFunc {
            entries: num_entries,
        }),
        _ => k::Data::Str(k::InnerFunc {
            entries: str_entries,
        }),
    };
    let wrappers = rng.below(4) as usize;
    for _ in 0..wrappers {
        up = UC::IfExists(Box::new(up));
    }
    (up, k::Condition { op, wrappers, data })
}
#[test]
fn condition_metadata_agrees() {
    let mut rng = Rng(992);
    for _ in 0..10000 {
        let (u, c) = draw(&mut rng);
        let (v, d) = if rng.chance(40) {
            (u.clone(), c.clone())
        } else {
            draw(&mut rng)
        };
        assert_eq!(k::to_key(&c), b(u.to_key()));
        assert_eq!(k::to_key_with_suffix(&c), b(&u.to_key_with_suffix()));
        assert_eq!(k::is_negate(&c), u.is_negate());
        assert_eq!(k::condition_eq(&c, &d), u == v);
        let names = match &c.data {
            k::Data::Str(f) => k::key_names(f),
            k::Data::Addr(f) => k::key_names(f),
            k::Data::Boolean(f) => k::key_names(f),
            k::Data::Num(f) => k::key_names(f),
            k::Data::Date(f) => k::key_names(f),
            k::Data::Binary(f) => k::key_names(f),
        };
        let uv = names
            .iter()
            .filter_map(|name| {
                if !rng.chance(70) {
                    return None;
                }
                Some((
                    String::from_utf8(name.clone()).unwrap(),
                    (0..rng.below(4))
                        .map(|_| {
                            rng.pick(&[
                                "a",
                                "b",
                                "true",
                                "false",
                                "0",
                                "99",
                                "invalid",
                                "10.0.1.1",
                                "YQ==",
                                "2026-10-10T12:00:00Z",
                            ])
                            .to_string()
                        })
                        .collect::<Vec<_>>(),
                ))
            })
            .collect::<std::collections::HashMap<_, _>>();
        let kv = uv
            .iter()
            .map(|(s, v)| (b(s), v.iter().map(|s| b(s)).collect()))
            .collect();
        let env = rustfs_kernel::condfuncs::Env {
            ips: uv
                .values()
                .flatten()
                .map(|s| {
                    (
                        b(s),
                        s.parse::<std::net::IpAddr>().ok().map(|ip| match ip {
                            std::net::IpAddr::V4(a) => IpAddr::V4(u32::from(a)),
                            std::net::IpAddr::V6(a) => IpAddr::V6(u128::from(a)),
                        }),
                    )
                })
                .collect(),
            now_rfc3339: vec![],
            now_epoch: vec![],
        };
        assert_eq!(k::has_any_key_in(&c, &kv), u.has_any_key_in(&uv));
        for (q, uq) in [
            (
                rustfs_kernel::condfuncs::Quantifier::None,
                rustfs_private_oracle::policy::function::Quantifier::None,
            ),
            (
                rustfs_kernel::condfuncs::Quantifier::ForAnyValue,
                rustfs_private_oracle::policy::function::Quantifier::ForAnyValue,
            ),
            (
                rustfs_kernel::condfuncs::Quantifier::ForAllValues,
                rustfs_private_oracle::policy::function::Quantifier::ForAllValues,
            ),
        ] {
            assert_eq!(
                k::condition_evaluate(&c, q, &kv, &None, &env),
                pollster::block_on(u.evaluate_with_resolver(uq, &uv, None))
            );
        }
        let a = vec![u.clone(), u.clone()];
        let ca = vec![c.clone(), c.clone()];
        let z = vec![u, v];
        let cz = vec![c, d];
        for qualifier in 0..3 {
            let empty = k::Functions {
                for_any_value: vec![],
                for_all_values: vec![],
                for_normal: vec![],
            };
            assert!(k::is_empty(&empty));
            let mut ka = empty.clone();
            let mut kz = empty;
            match qualifier {
                0 => {
                    ka.for_normal = ca.clone();
                    kz.for_normal = cz.clone()
                }
                1 => {
                    ka.for_any_value = ca.clone();
                    kz.for_any_value = cz.clone()
                }
                _ => {
                    ka.for_all_values = ca.clone();
                    kz.for_all_values = cz.clone()
                }
            }
            let ua = rustfs_private_oracle::policy::function::with_conditions(a.clone(), qualifier);
            let uz = rustfs_private_oracle::policy::function::with_conditions(z.clone(), qualifier);
            assert_eq!(k::functions_eq(&ka, &kz), ua == uz);
            assert_eq!(k::is_empty(&ka), ua.is_empty());
            assert_eq!(
                k::functions_evaluate(&ka, &kv, &None, &env),
                pollster::block_on(ua.evaluate(&uv))
            );
            let view = k::matching_view(&ka);
            for name in ["s3:ExistingObjectTag", "s3:prefix", "aws:username"] {
                let un = KeyName::try_from(name).unwrap();
                assert_eq!(
                    rustfs_kernel::condfuncs::references_key_name(&view, name.as_bytes()),
                    ua.references_key_name(&un)
                );
            }
        }
    }
    // Ordered inner entries, unordered string sets, and key/clone helpers.
    for _ in 0..1000 {
        let names = ["aws:username", "s3:ExistingObjectTag/foo"];
        let vs = (0..rng.below(5))
            .map(|_| rng.below(10) as i64)
            .collect::<Vec<_>>();
        let entries = vs
            .iter()
            .enumerate()
            .map(|(i, n)| k::FuncKeyValue {
                key: key(names[i % 2]),
                values: *n,
            })
            .collect();
        let inner = k::InnerFunc { entries };
        let up: InnerFunc<i64> =
            decode(json!({"aws:username":1,"s3:ExistingObjectTag/foo":2})).unwrap();
        let ki = k::InnerFunc {
            entries: vec![
                k::FuncKeyValue {
                    key: key(names[0]),
                    values: 1i64,
                },
                k::FuncKeyValue {
                    key: key(names[1]),
                    values: 2,
                },
            ],
        };
        assert_eq!(
            k::key_names(&ki),
            up.key_names().map(|s| b(&s)).collect::<Vec<_>>()
        );
        for name in ["aws:username", "s3:ExistingObjectTag", "jwt:sub"] {
            let kn = KeyName::try_from(name).unwrap();
            assert_eq!(
                k::contains_key_name(&ki, name.as_bytes()),
                up.contains_key_name(&kn)
            );
            assert_eq!(
                k::key_is(&ki.entries[0].key, name.as_bytes()),
                UK::try_from(names[0]).unwrap().is(&kn)
            );
        }
        let copy = k::clone_inner(&inner);
        assert_eq!(copy, inner);
        for entry in &inner.entries {
            assert_eq!(*entry, k::clone_key_value(entry));
        }
    }
}
#[test]
fn binary_agrees() {
    use rustfs_private_oracle::base64_simd::STANDARD;
    let mut rng = Rng(993);
    let mut strings = vec![
        "".to_string(),
        "YQ==".into(),
        "YWI=".into(),
        "YWJj".into(),
        "YR==".into(),
        "YWJ=".into(),
        "YQ".into(),
        "a===".into(),
    ];
    for _ in 0..5000 {
        let raw = (0..rng.below(40))
            .map(|_| rng.below(256) as u8)
            .collect::<Vec<_>>();
        strings.push(STANDARD.encode_to_string(&raw));
        strings.push(
            (0..rng.below(30))
                .map(|_| {
                    *rng.pick(
                        b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/= \n",
                    )
                })
                .map(char::from)
                .collect(),
        );
    }
    for s in &strings {
        assert_eq!(
            k::decode_base64(s.as_bytes()).ok(),
            STANDARD.decode_to_vec(s.as_bytes()).ok(),
            "{s:?}"
        );
        let a = k::binary_new(s.as_bytes());
        let u = BinaryFuncValue::new(s);
        assert_eq!(a.is_ok(), u.is_ok());
        if let Ok(a) = a {
            assert_eq!(a.encoded, vec![b(s)]);
            assert_eq!(
                a.decoded,
                vec![STANDARD.decode_to_vec(s.as_bytes()).unwrap()]
            );
            assert_eq!(
                k::binary_eq(&a, &a),
                u.as_ref().unwrap() == u.as_ref().unwrap()
            );
        }
    }
    for _ in 0..4000 {
        let input = (0..rng.below(5))
            .map(|_| rng.pick(&strings).clone())
            .collect::<Vec<_>>();
        let result = k::binary_from_encoded_values(input.iter().map(|s| b(s)).collect());
        let up = rustfs_private_oracle::policy::function::binary::from_encoded_test(input.clone());
        assert_eq!(result.is_ok(), up.is_ok());
        if let Ok(value) = result {
            assert_eq!(
                value.encoded,
                input.iter().map(|s| b(s)).collect::<Vec<_>>()
            );
            assert_eq!(
                value.decoded,
                input
                    .iter()
                    .map(|s| STANDARD.decode_to_vec(s.as_bytes()).unwrap())
                    .collect::<Vec<_>>()
            );
        }
    }
    for _ in 0..4000 {
        let expected = *rng.pick(&["", "YQ==", "YWI=", "YWJj"]);
        let requests = (0..rng.below(4))
            .map(|_| rng.pick(&strings).clone())
            .collect::<Vec<_>>();
        let uf: rustfs_private_oracle::policy::function::binary::BinaryFunc =
            decode(json!({"aws:username":expected})).unwrap();
        let inner = k::InnerFunc {
            entries: vec![k::FuncKeyValue {
                key: key("aws:username"),
                values: k::binary_new(expected.as_bytes()).unwrap(),
            }],
        };
        let present = rng.chance(80);
        let uv = if present {
            std::collections::HashMap::from([("username".to_string(), requests.clone())])
        } else {
            Default::default()
        };
        let kv = uv
            .iter()
            .map(|(s, v)| (b(s), v.iter().map(|s| b(s)).collect()))
            .collect();
        assert_eq!(k::binary_evaluate(&inner, &kv), uf.evaluate(&uv));
    }
}
#[test]
fn dates_agree() {
    let mut rng = Rng(994);
    let mut inputs = vec![
        "".into(),
        "2026-01-01T00:00:00Z".into(),
        "2016-12-31T23:59:60Z".into(),
        "2016-12-31T23:59:60.1Z".into(),
        "2016-12-31T18:59:60-05:00".into(),
        "2017-01-01T00:59:60+01:00".into(),
        "2016-12-31T23:59:60+00:01".into(),
        "0000-01-01T00:00:00+23:59".into(),
        "9999-12-31T23:59:59-23:59".into(),
        "2026-01-01x00:00:00z".into(),
    ];
    for _ in 0..10000 {
        inputs.push(format!(
            "{:04}-{:02}-{:02}{}{:02}:{:02}:{:02}{}{}",
            rng.below(10000),
            rng.below(14),
            rng.below(33),
            char::from(*rng.pick(b"Tt x")),
            rng.below(26),
            rng.below(63),
            rng.below(63),
            rng.pick(&["", ".0", ".123456789987654321", "."]),
            rng.pick(&[
                "Z", "z", "+00:00", "-05:30", "+23:59", "+24:00", "-00:01", "+00:60", "zjunk"
            ])
        ));
    }
    for s in &inputs {
        let parsed = dates::parse_value(s.as_bytes());
        let upstream = OffsetDateTime::parse(s, &Rfc3339).ok();
        assert_eq!(
            parsed.as_ref().map(|v| (v.unix_nanos, v.offset_seconds)),
            upstream.map(|v| (v.unix_timestamp_nanos(), v.offset().whole_seconds()))
        );
        assert_eq!(
            dates::parse_rfc3339(s.as_bytes()),
            OffsetDateTime::parse(s, &Rfc3339)
                .ok()
                .map(|t| t.unix_timestamp_nanos()),
            "{s:?}"
        );
    }
    for op in &OPS[22..] {
        for _ in 0..2000 {
            let s = rng.pick(&inputs);
            let time = OffsetDateTime::parse("2026-10-10T00:00:00Z", &Rfc3339).unwrap();
            let inner = k::InnerFunc {
                entries: vec![k::FuncKeyValue {
                    key: key("aws:CurrentTime"),
                    values: k::DateFuncValue {
                        unix_nanos: time.unix_timestamp_nanos(),
                        offset_seconds: 0,
                    },
                }],
            };
            let up: rustfs_private_oracle::policy::function::date::DateFunc =
                decode(json!({"aws:CurrentTime":"2026-10-10T00:00:00Z"})).unwrap();
            let uv = std::collections::HashMap::from([(
                "CurrentTime".to_string(),
                vec![s.clone(), "invalid ignored second".into()],
            )]);
            let kv = uv
                .iter()
                .map(|(s, v)| (b(s), v.iter().map(|s| b(s)).collect()))
                .collect();
            let compare = |a: &OffsetDateTime, z: &OffsetDateTime| match op {
                k::Op::DateEquals => a == z,
                k::Op::DateNotEquals => a != z,
                k::Op::DateLessThan => a < z,
                k::Op::DateLessThanEquals => a <= z,
                k::Op::DateGreaterThan => a > z,
                _ => a >= z,
            };
            assert_eq!(dates::evaluate(&inner, *op, &kv), up.evaluate(compare, &uv));
            let n = rng.below(200) as i128 - 100;
            assert_eq!(
                dates::compare(*op, n, 0),
                compare(
                    &OffsetDateTime::from_unix_timestamp_nanos(n).unwrap(),
                    &OffsetDateTime::UNIX_EPOCH
                )
            );
        }
    }
}

#[test]
fn date_equality_ignores_offset() {
    let mut cs = Vec::new();
    let mut us = Vec::new();
    for s in ["2026-10-10T00:00:00Z", "2026-10-10T01:00:00+01:00"] {
        let f = decode(json!({"DateEquals":{"aws:CurrentTime":s}})).unwrap();
        us.push(rustfs_private_oracle::policy::function::normal_conditions(f).remove(0));
        cs.push(k::Condition {
            op: k::Op::DateEquals,
            wrappers: 0,
            data: k::Data::Date(k::InnerFunc {
                entries: vec![k::FuncKeyValue {
                    key: key("aws:CurrentTime"),
                    values: dates::parse_value(s.as_bytes()).unwrap(),
                }],
            }),
        });
    }
    assert_eq!(k::condition_eq(&cs[0], &cs[1]), us[0] == us[1]);
    assert!(k::condition_eq(&cs[0], &cs[1]));
}

fn decode<T: rustfs_private_oracle::serde::de::DeserializeOwned>(
    v: serde_json::Value,
) -> Result<T, serde_json::Error> {
    serde_json::from_str(&v.to_string())
}
