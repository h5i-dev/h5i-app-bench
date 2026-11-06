//! `scopes` against `windmill_common::scopes`.
use crate as up;
use crate::{b, bl, random_resources, random_scope, Rng};
use windmill_common::scopes::{intersect_job_token_scopes, scope_contains, ScopeDefinition};
use windmill_kernel::scopes as k;

fn to_kernel(s: &ScopeDefinition) -> k::Scope {
    k::Scope {
        domain: b(&s.domain),
        action: b(&s.action),
        has_kind: s.kind.is_some(),
        kind: s.kind.as_deref().map(b).unwrap_or_default(),
        has_resource: s.resource.is_some(),
        resource: s.resource.as_deref().map(bl).unwrap_or_default(),
    }
}

#[test]
fn parse_agrees() {
    let mut r = Rng(0x3d11_0001);
    for _ in 0..200_000 {
        let s = random_scope(&mut r);
        let u = ScopeDefinition::from_scope_string(&s).ok().map(|d| to_kernel(&d));
        assert_eq!(k::from_scope_string(s.as_bytes()), u, "{s:?}");
    }
}

#[test]
fn includes_agrees() {
    let mut r = Rng(0x3d11_0002);
    let mut n = 0;
    while n < 300_000 {
        let (a, c) = (random_scope(&mut r), random_scope(&mut r));
        let (Ok(ua), Ok(uc)) = (ScopeDefinition::from_scope_string(&a), ScopeDefinition::from_scope_string(&c))
        else {
            continue;
        };
        // Bias towards comparable pairs: same domain half of the time.
        let uc = if r.bool() { ScopeDefinition { domain: ua.domain.clone(), ..uc } } else { uc };
        let (ka, kc) = (to_kernel(&ua), to_kernel(&uc));
        assert_eq!(k::includes(&ka, &kc), ua.includes(&uc), "{a:?} includes {uc:?}");
        assert_eq!(k::scope_contains(&ka, &kc), scope_contains(&ua, &uc), "{a:?} contains {uc:?}");
        n += 1;
    }
}

#[test]
fn resource_matchers_agree() {
    let mut r = Rng(0x3d11_0003);
    for _ in 0..300_000 {
        let (x, y) = (random_resources(&mut r), random_resources(&mut r));
        let (kx, ky) = (bl(&x), bl(&y));
        assert_eq!(k::resources_match(&kx, &ky), up::resources_match(&x, &y), "{x:?} {y:?}");
        assert_eq!(k::resources_match_small(&kx, &ky), up::resources_match_small(&x, &y));
        assert_eq!(k::resources_match_large(&kx, &ky), up::resources_match_large(&x, &y));
        assert_eq!(k::resource_set_contains(&kx, &ky), up::resource_set_contains(&x, &y));
        for (p, q) in x.iter().zip(y.iter()) {
            assert_eq!(k::resource_matches_pattern(p.as_bytes(), q.as_bytes()), up::resource_matches_pattern(p, q), "{p:?} {q:?}");
            assert_eq!(k::resource_covers(p.as_bytes(), q.as_bytes()), up::resource_covers(p, q), "{p:?} {q:?}");
        }
    }
}

#[test]
fn intersect_agrees() {
    let mut r = Rng(0x3d11_0004);
    for _ in 0..50_000 {
        let c: Vec<String> = (0..r.below(5)).map(|_| random_scope(&mut r)).collect();
        let o: Vec<String> = (0..r.below(5)).map(|_| random_scope(&mut r)).collect();
        let u = intersect_job_token_scopes(Some(&c), Some(&o)).expect("both Some");
        assert_eq!(k::intersect_job_token_scopes(&bl(&c), &bl(&o)), bl(&u), "{c:?} {o:?}");
    }
}

/// FINDING W1: `resource_matches_pattern` compares a character index with a byte
/// length, so with a multi-byte character in the prefix the `/` boundary check looks one
/// character too far: a grant on folder `dé` also matches folder `déx`.
#[test]
fn unicode_prefix_crosses_folder_boundary() {
    let grant = ScopeDefinition::from_scope_string("scripts:read:f/d\u{e9}/*").unwrap();
    let other_folder = ScopeDefinition::from_scope_string("scripts:read:f/d\u{e9}x/y").unwrap();
    assert!(grant.includes(&other_folder), "upstream fixed; update FINDINGS.md");
    let ascii_grant = ScopeDefinition::from_scope_string("scripts:read:f/de/*").unwrap();
    let ascii_other = ScopeDefinition::from_scope_string("scripts:read:f/dex/y").unwrap();
    assert!(!ascii_grant.includes(&ascii_other));
}

/// FINDING W2: `resources_match` uses the symmetric matcher for lists of at most 4
/// entries but an asymmetric one above, so a token minted under `scope_contains` can
/// satisfy a wildcard requirement that its minter cannot.
#[test]
fn delegation_not_monotone_across_size_split() {
    let caller = ScopeDefinition::from_scope_string("scripts:read:f/a/x,f/b/1,f/b/2,f/b/3,f/b/4").unwrap();
    let minted = ScopeDefinition::from_scope_string("scripts:read:f/a/x").unwrap();
    let required = ScopeDefinition::from_scope_string("scripts:read:f/a/*").unwrap();
    assert!(scope_contains(&caller, &minted));
    assert!(minted.includes(&required));
    assert!(!caller.includes(&required), "upstream fixed; update FINDINGS.md");
}
