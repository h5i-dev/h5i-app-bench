//! Falsification and non-vacuity tests for proofs/Properties.lean, on the
//! same random policies and requests as the differential tests.
use crate::tests::*;
use rustfs_kernel::acts::{statement_covers, Action, Family};
use rustfs_kernel::awsvars::{resolve_aws_variables, ClaimStrings, VarContext};
use rustfs_kernel::policies::{bucket_policy_is_allowed, policy_is_allowed};
use rustfs_kernel::stmts::*;
use rustfs_kernel::{bytes, pathclean, wildmatch};

const N: usize = 300_000;
const MIN_HITS: usize = 300;

fn identity_cases(seed: u64, mut check: impl FnMut(&[Statement], &Args, bool) -> bool) {
    let mut r = Rng(seed);
    let mut hits = 0;
    for _ in 0..N {
        let (_, sts) = identity_policy(&mut r);
        let q = request(&mut r);
        let a = kargs(&q);
        let e = env(&q.conds);
        let allowed = policy_is_allowed(&sts, &a, &e);
        if check(&sts, &a, allowed) {
            hits += 1;
        }
    }
    assert!(hits >= MIN_HITS, "premises held {hits} times");
}

fn env_of(a: &Args) -> rustfs_kernel::condfuncs::Env {
    let m = a.conditions.iter().map(|(k, v)| (String::from_utf8(k.clone()).unwrap(),
        v.iter().map(|x| String::from_utf8(x.clone()).unwrap()).collect())).collect();
    env(&m)
}

#[test]
fn explicit_deny_wins() {
    identity_cases(1, |sts, a, allowed| {
        let e = env_of(a);
        if !sts.iter().any(|s| s.effect == Effect::Deny && !statement_is_allowed(s, a, &e)) { return false }
        assert!(!allowed);
        true
    });
}

#[test]
fn allow_needs_allow_statement() {
    identity_cases(2, |sts, a, allowed| {
        if !allowed || a.is_owner || a.deny_only { return false }
        let e = env_of(a);
        assert!(sts.iter().any(|s| s.effect == Effect::Allow && statement_is_allowed(s, a, &e)));
        true
    });
}

#[test]
fn owner_allowed_unless_denied() {
    identity_cases(3, |sts, a, allowed| {
        let e = env_of(a);
        if !a.is_owner || sts.iter().any(|s| s.effect == Effect::Deny && !statement_is_allowed(s, a, &e)) { return false }
        assert!(allowed);
        true
    });
}

fn is_force_delete(a: &Action) -> bool {
    a.family == Family::S3 && (a.name == b"s3:ForceDeleteBucket" || a.name == b"s3:ForceDeleteObject")
}

#[test]
fn force_delete_needs_explicit_grant() {
    identity_cases(4, |sts, a, allowed| {
        if !allowed || a.is_owner || a.deny_only || !is_force_delete(&a.action) { return false }
        assert!(sts.iter().any(|s| s.effect == Effect::Allow && s.actions.iter().any(|x| x == &a.action)));
        true
    });
}

#[test]
fn get_object_version_covers_get_object() {
    let gov = Action { family: Family::S3, name: b("s3:GetObjectVersion") };
    let go = Action { family: Family::S3, name: b("s3:GetObject") };
    for deny in [false, true] {
        assert!(statement_covers(&[gov.clone()], &[], &go, deny));
    }
}

#[test]
fn bucket_allow_needs_principal() {
    let mut r = Rng(5);
    let mut hits = 0;
    for _ in 0..N {
        let (_, sts) = bucket_policy(&mut r);
        let q = request(&mut r);
        let kb = BucketPolicyArgs { account: b(&q.account), action: kaction(&q.action), bucket: b(&q.bucket),
            conditions: kconds(&q.conds), is_owner: q.is_owner, object: b(&q.object) };
        let e = env(&q.conds);
        if q.is_owner || !bucket_policy_is_allowed(&sts, &kb, &e) { continue }
        hits += 1;
        assert!(sts.iter().any(|s| s.effect == Effect::Allow && principal_is_match(&s.principal, &kb.account)
            && bp_statement_is_allowed(s, &kb, &e)));
    }
    assert!(hits >= MIN_HITS, "{hits}");
}

/// The declarative glob the Lean spec states: `*` any run, `?` one byte.
fn glob(p: &[u8], n: &[u8]) -> bool {
    match p.split_first() {
        None => n.is_empty(),
        Some((b'*', rest)) => glob(rest, n) || (!n.is_empty() && glob(p, &n[1..])),
        Some((b'?', rest)) => !n.is_empty() && glob(rest, &n[1..]),
        Some((c, rest)) => !n.is_empty() && n[0] == *c && glob(rest, &n[1..]),
    }
}

fn text(r: &mut Rng, alpha: &[u8], max: u64) -> Vec<u8> {
    (0..r.below(max + 1)).map(|_| *r.pick(alpha)).collect()
}

#[test]
fn wildcard_matches_glob() {
    let mut r = Rng(6);
    let mut yes = 0;
    for _ in 0..N {
        let p = text(&mut r, b"ab*?", 6);
        let n = text(&mut r, b"ab", 6);
        let got = wildmatch::is_match(&p, &n);
        assert_eq!(got, glob(&p, &n), "{p:?} {n:?}");
        yes += got as usize;
    }
    assert!(yes > MIN_HITS);
}

#[test]
fn clean_idempotent_and_canonical() {
    let mut r = Rng(7);
    for _ in 0..N {
        let p = text(&mut r, b"a/.", 10);
        let c = pathclean::clean(&p);
        assert_eq!(pathclean::clean(&c), c, "{p:?}");
        let rooted = c.first() == Some(&b'/');
        let body: &[u8] = if rooted { &c[1..] } else { &c };
        if c != b"." && body != b"" {
            for seg in body.split(|&x| x == b'/') {
                assert!(!seg.is_empty() && seg != b".", "{p:?} -> {c:?}");
            }
        }
    }
}

#[test]
fn parse_i64_like_std() {
    let mut r = Rng(8);
    let mut ok = 0;
    for _ in 0..N {
        let s = if r.chance(5) { r.pick(&["9223372036854775807", "-9223372036854775808", "9223372036854775808", "+", "-", ""]).as_bytes().to_vec() }
            else { text(&mut r, b"+-0123456789x", 5) };
        let want = std::str::from_utf8(&s).unwrap().parse::<i64>().ok();
        assert_eq!(bytes::parse_i64(&s), want, "{s:?}");
        ok += want.is_some() as usize;
    }
    assert!(ok > MIN_HITS);
}

/// Resolution stops when no value it substitutes contains `${`.
#[test]
fn resolution_terminates_without_nested_values() {
    let mut r = Rng(9);
    for _ in 0..N {
        let pick = |r: &mut Rng| text(r, b"a${}:usernid", 8);
        let ctx = VarContext {
            username: b(r.pick(&["alice", "bob"])), account: b("acct"),
            claims: ClaimStrings { sub: Some(vec![b("s1"), b("s2")]), parent: None, parent_str: None,
                has_parent: false, has_role_arn: r.chance(30), has_sa_policy: false },
            now_rfc3339: b("t"), now_epoch: b("1"),
        };
        let p = if r.chance(50) { pick(&mut r) } else { b(r.pick(&["${aws:username}/${aws:userid}", "${${aws:username}}", "a${aws:PrincipalType}"])) };
        let out = resolve_aws_variables(&ctx, &p);
        assert!(!out.is_empty());
    }
}

#[test]
fn deny_only_ignores_allows() {
    identity_cases(10, |sts, a, allowed| {
        let e = env_of(a);
        if !a.deny_only || sts.iter().any(|s| s.effect == Effect::Deny && !statement_is_allowed(s, a, &e)) { return false }
        assert!(allowed);
        true
    });
}
