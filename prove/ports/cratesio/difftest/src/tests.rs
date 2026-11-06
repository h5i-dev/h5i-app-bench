//! Kernel against upstream on generated inputs.

use std::str::FromStr;

use chrono::{TimeZone, Utc};
use cratesio_kernel as k;
use crates_io_validation as uv;
use http::{HeaderValue, Request};

use crate::{Rng, auth as ua, scopes as us, trustpub as ut};

const NAME_CHARS: &[char] = &[
    'a', 'z', 'A', 'Z', 'm', '0', '9', '5', '-', '_', '*', '.', ' ', '/', 'ü', '漢', '😀', '+',
];

fn name_like(r: &mut Rng) -> String {
    let len = match r.below(10) {
        0 => 0,
        1 => 60 + r.below(10) as usize,
        _ => 1 + r.below(12) as usize,
    };
    if r.chance(1, 2) {
        let mut s = r.string(&['a', 'b', 'Q', '-', '_', '3'], len);
        if r.chance(1, 2) && !s.is_empty() {
            s.replace_range(0..1, "x");
        }
        s
    } else {
        r.string(NAME_CHARS, len)
    }
}

fn crate_err(e: &uv::InvalidCrateName) -> k::validation::InvalidName {
    use k::validation::InvalidName as K;
    match e {
        uv::InvalidCrateName::TooLong { .. } => K::TooLong,
        uv::InvalidCrateName::Empty { .. } => K::Empty,
        uv::InvalidCrateName::StartWithDigit { .. } => K::StartWithDigit,
        uv::InvalidCrateName::Start { .. } => K::Start,
        uv::InvalidCrateName::Char { .. } => K::Char,
    }
}

fn dep_err(e: &uv::InvalidDependencyName) -> k::validation::InvalidName {
    use k::validation::InvalidName as K;
    match e {
        uv::InvalidDependencyName::TooLong(_) => K::TooLong,
        uv::InvalidDependencyName::Empty => K::Empty,
        uv::InvalidDependencyName::StartWithDigit(_) => K::StartWithDigit,
        uv::InvalidDependencyName::Start(..) => K::Start,
        uv::InvalidDependencyName::Char(..) => K::Char,
    }
}

#[test]
fn names_agree() {
    let mut r = Rng(0xc1a7_0001);
    let mut ok = 0;
    for _ in 0..300_000 {
        let s = name_like(&mut r);
        let kc = k::validation::validate_crate_name(s.as_bytes());
        match uv::validate_crate_name("crate", &s) {
            Ok(()) => {
                ok += 1;
                assert_eq!(kc, Ok(()), "{s:?}")
            }
            Err(e) => assert_eq!(kc, Err(crate_err(&e)), "{s:?}"),
        }
        let kd = k::validation::validate_dependency_name(s.as_bytes());
        match uv::validate_dependency_name(&s) {
            Ok(()) => assert_eq!(kd, Ok(()), "{s:?}"),
            Err(e) => assert_eq!(kd, Err(dep_err(&e)), "{s:?}"),
        }
    }
    assert!(ok > 50_000, "{ok}");
}

#[test]
fn crate_scopes_agree() {
    let mut r = Rng(0xc1a7_0002);
    let mut valid = 0;
    let mut matched = 0;
    for _ in 0..300_000 {
        let p = match r.below(4) {
            0 => "*".to_string(),
            1 => format!("{}*", name_like(&mut r)),
            _ => name_like(&mut r),
        };
        let kv = k::scopes::is_valid_pattern(p.as_bytes());
        let uvp = us::CrateScope::try_from(p.as_str());
        assert_eq!(kv, uvp.is_ok(), "pattern {p:?}");
        if let Ok(scope) = uvp {
            valid += 1;
            for _ in 0..4 {
                let n = if r.chance(1, 2) {
                    format!("{}{}", p.trim_end_matches('*'), name_like(&mut r))
                } else {
                    name_like(&mut r)
                };
                let km = k::scopes::scope_matches(p.as_bytes(), n.as_bytes());
                assert_eq!(km, scope.matches(&n), "pattern {p:?} name {n:?}");
                matched += km as usize;
            }
        }
    }
    assert!(valid > 50_000 && matched > 20_000, "{valid} {matched}");
}

const SCOPES: [(ua::EndpointScope, k::scopes::EndpointScope); 5] = [
    (ua::EndpointScope::PublishNew, k::scopes::EndpointScope::PublishNew),
    (ua::EndpointScope::PublishUpdate, k::scopes::EndpointScope::PublishUpdate),
    (ua::EndpointScope::TrustedPublishing, k::scopes::EndpointScope::TrustedPublishing),
    (ua::EndpointScope::Yank, k::scopes::EndpointScope::Yank),
    (ua::EndpointScope::ChangeOwners, k::scopes::EndpointScope::ChangeOwners),
];

#[test]
fn auth_check_scopes_agree() {
    let mut r = Rng(0xc1a7_0003);
    let pats = ["*", "serde", "serde*", "tokio", "tok*", "a", "a-b_c", "x*"];
    let names = ["serde", "serde_json", "tokio", "tokio-util", "a", "a-b_c", "x", "xy", "b"];
    for _ in 0..200_000 {
        let es: Option<Vec<usize>> =
            if r.chance(1, 4) { None } else { Some((0..r.below(4)).map(|_| r.below(5) as usize).collect()) };
        let cs: Option<Vec<&str>> =
            if r.chance(1, 4) { None } else { Some((0..r.below(3)).map(|_| *r.pick(&pats)).collect()) };
        let scope = if r.chance(1, 5) { None } else { Some(r.below(5) as usize) };
        let name = if r.chance(1, 3) { None } else { Some(*r.pick(&names)) };
        let any = r.chance(1, 2);
        let up = ua::AuthCheck {
            allow_token: true,
            endpoint_scope: scope.map(|i| SCOPES[i].0),
            crate_name: name.map(String::from),
            allow_any_crate_scope: any,
        };
        let kc = k::auth::AuthCheck {
            allow_token: true,
            endpoint_scope: scope.map(|i| SCOPES[i].1),
            crate_name: name.map(|n| n.as_bytes().to_vec()),
            allow_any_crate_scope: any,
        };
        let ues: Option<Vec<ua::EndpointScope>> = es.as_ref().map(|v| v.iter().map(|&i| SCOPES[i].0).collect());
        let kes: Option<Vec<k::scopes::EndpointScope>> = es.as_ref().map(|v| v.iter().map(|&i| SCOPES[i].1).collect());
        assert_eq!(ua::endpoint_matches(&up, ues.as_ref()), k::auth::endpoint_scope_matches(&kc, &kes));
        let ucs: Option<Vec<us::CrateScope>> =
            cs.as_ref().map(|v| v.iter().map(|p| us::CrateScope::try_from(*p).unwrap()).collect());
        let kcs: Option<Vec<Vec<u8>>> = cs.as_ref().map(|v| v.iter().map(|p| p.as_bytes().to_vec()).collect());
        assert_eq!(ua::crate_matches(&up, ucs.as_ref()), k::auth::crate_scope_matches(&kc, &kcs), "{cs:?} {name:?} {any}");
    }
}

#[test]
fn account_locks_agree() {
    let mut r = Rng(0xc1a7_0004);
    let now = Utc::now().timestamp();
    for _ in 0..100_000 {
        let reason = r.chance(2, 3);
        let until = if r.chance(1, 3) {
            None
        } else {
            let d = 1 + r.below(1_000_000) as i64;
            Some(if r.chance(1, 2) { now + 600 + d } else { now - 600 - d })
        };
        let u = ua::User {
            account_lock_reason: reason.then(|| "spam".to_string()),
            account_lock_until: until.map(|t| Utc.timestamp_opt(t, 0).unwrap()),
        };
        let ku = k::auth::User { id: 1, lock_reason: reason, lock_until: until, session_epoch: 0 };
        assert_eq!(ua::ensure_not_locked(&u).is_err(), k::auth::is_locked(&ku, now), "{reason} {until:?}");
    }
}

#[test]
fn auth_header_agrees() {
    let mut r = Rng(0xc1a7_0005);
    let parts_of = |v: &[u8]| {
        let mut req = Request::builder().body(()).unwrap();
        req.headers_mut().insert(http::header::AUTHORIZATION, HeaderValue::from_bytes(v).unwrap());
        req.into_parts().0
    };
    let bytes: Vec<u8> = (0x20u8..0x7f).chain([b'\t', 0x80, 0xff, 0xc3, 0xa9]).collect();
    let mut oks = 0;
    for _ in 0..200_000 {
        let mut v: Vec<u8> = Vec::new();
        match r.below(4) {
            0 => v.extend_from_slice(r.pick(&[&b"Bearer "[..], b"bearer ", b"BEARER ", b"Basic ", b" ", b"Token "])),
            _ => {}
        }
        let len = r.below(12) as usize;
        for _ in 0..len {
            v.push(if r.chance(3, 4) { *r.pick(b"cio_tpAZaz09 \t") } else { *r.pick(&bytes) });
        }
        if HeaderValue::from_bytes(&v).is_err() {
            continue;
        }
        let parts = parts_of(&v);
        let up = futures::executor::block_on(ua::AuthHeader::optional_from_request_parts(&parts));
        let kp = k::auth::parse_auth_header(&v);
        match (up, kp) {
            (Ok(Some(h)), Ok(t)) => {
                oks += 1;
                use secrecy::ExposeSecret;
                assert_eq!(ua::header_token(&h).expose_secret().as_bytes(), &t[..], "{v:?}")
            }
            (Err((s, m)), Err(e)) => {
                assert_eq!(s, http::StatusCode::UNAUTHORIZED);
                let want = if m.contains("non-ASCII") {
                    k::auth::AuthError::HeaderNotAscii
                } else {
                    k::auth::AuthError::HeaderScheme
                };
                assert_eq!(e, want, "{v:?} {m}")
            }
            (up, kp) => panic!("{v:?}: upstream {:?} kernel {kp:?}", up.map(|o| o.is_some())),
        }
    }
    assert!(oks > 50_000, "{oks}");
}

#[test]
fn access_tokens_agree() {
    let mut r = Rng(0xc1a7_0006);
    use secrecy::ExposeSecret;
    let mut valid = 0;
    for i in 0..100_000 {
        let s: String = if i % 3 == 0 {
            ut::AccessToken::generate().finalize().expose_secret().to_string()
        } else {
            let base = ut::AccessToken::generate().finalize().expose_secret().to_string();
            let mut b: Vec<char> = base.chars().collect();
            match r.below(4) {
                0 => {
                    let p = r.below(b.len() as u64) as usize;
                    b[p] = *r.pick(&['a', 'Z', '0', '_', '-', 'é', '9']);
                }
                1 => {
                    b.pop();
                }
                2 => b.push('x'),
                _ => b.truncate(r.below(10) as usize),
            }
            b.into_iter().collect()
        };
        let up = ut::AccessToken::from_str(&s);
        let kp = k::publish::parse_access_token(s.as_bytes());
        match (up, kp) {
            (Ok(t), Some(raw)) => {
                valid += 1;
                let fin = t.finalize();
                assert_eq!(&fin.expose_secret().as_bytes()[7..38], &raw[..], "{s:?}");
            }
            (Err(_), None) => {}
            (up, kp) => panic!("{s:?}: upstream ok {} kernel {kp:?}", up.is_ok()),
        }
    }
    assert!(valid > 30_000, "{valid}");
}

#[test]
fn workflow_filenames_agree() {
    let mut r = Rng(0xc1a7_0007);
    let parts = [
        "owner", "repo", ".github", "workflows", "ci.yml", "release.yaml", "x.yml@y", "a.yml", "yml", ".yml",
        "@refs", "heads", "main", "b.yaml@c", "ü.yml", "", "\n", "@", "a@b.yml",
    ];
    let mut some = 0;
    for _ in 0..300_000 {
        let n = 1 + r.below(7) as usize;
        let mut s = String::new();
        for j in 0..n {
            if j > 0 {
                s.push(*r.pick(&['/', '/', '/', '@', '\n']));
            }
            s.push_str(r.pick(&parts));
        }
        if r.chance(1, 3) {
            s = format!("o/r/.github/workflows/{}@refs/heads/{}", r.pick(&parts), r.pick(&parts));
        }
        let up = ut::workflow_filename(&s);
        let kp = k::trustpub::workflow_filename(s.as_bytes());
        assert_eq!(up.map(|x| x.as_bytes().to_vec()), kp, "{s:?}");
        some += up.is_some() as usize;
    }
    assert!(some > 50_000, "{some}");
}

#[test]
fn owner_ids_agree() {
    let mut r = Rng(0xc1a7_0008);
    let edge = ["", "+", "-", "0", "-0", "+0", "2147483647", "2147483648", "-2147483648", "-2147483649",
        "99999999999999999999", "007", "1_000", " 1", "1 "];
    for s in edge {
        assert_eq!(k::trustpub::parse_i32(s.as_bytes()), s.parse::<i32>().ok(), "{s:?}");
    }
    for _ in 0..300_000 {
        let len = r.below(13) as usize;
        let s = r.string(&['0', '1', '2', '4', '7', '9', '-', '+', 'a', ' '], len);
        assert_eq!(k::trustpub::parse_i32(s.as_bytes()), s.parse::<i32>().ok(), "{s:?}");
    }
}
