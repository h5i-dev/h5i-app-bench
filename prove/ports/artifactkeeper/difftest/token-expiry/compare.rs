#[allow(dead_code)]
#[path = "UPSTREAM"]
mod upstream;
#[allow(dead_code)]
#[path = "PORT"]
mod port;
fn category(message: &str) -> port::PolicyError {
    use port::PolicyError::*;
    if message.starts_with("min_days") { Minimum }
    else if message.starts_with("max_days") && message.contains("must be >=") { ReversedRange }
    else if message.starts_with("max_days") { Maximum }
    else if message.starts_with("default_days") { DefaultRange }
    else if message.starts_with("This instance requires") { Required }
    else if message.starts_with("expires_in_days") { RequestedRange }
    else { panic!("unknown upstream error: {message}") }
}
fn compare(p: port::Policy, request: Option<i64>, service: bool) {
    let u = upstream::ApiTokenExpiryPolicy {
        require_expiration: p.require_expiration, min_days: p.min_days, max_days: p.max_days,
        default_days: p.default_days, apply_to_service_accounts: p.apply_to_service_accounts,
    };
    assert_eq!(u.validate().map_err(|e| category(&e)), port::validate(&p));
    let actual = port::resolve_expiry(&p, request, service).map(|v| (v.expires_in_days, v.policy_applied));
    let expected = upstream::resolve_expiry(&u, request, service)
        .map(|v| (v.expires_in_days, v.policy_applied)).map_err(|e| category(&e));
    assert_eq!(actual, expected, "{p:?}, request {request:?}, service {service}");
}
fn next(seed: &mut u64) -> u64 {
    *seed ^= *seed << 13; *seed ^= *seed >> 7; *seed ^= *seed << 17; *seed
}
fn main() {
    let d = upstream::ApiTokenExpiryPolicy::default();
    assert_eq!(port::default_policy(), port::Policy {
        require_expiration: d.require_expiration, min_days: d.min_days, max_days: d.max_days,
        default_days: d.default_days, apply_to_service_accounts: d.apply_to_service_accounts,
    });
    let edges = [i64::MIN, -1, 0, 1, 2, 89, 90, 91, 3649, 3650, 3651, i64::MAX];
    let mut boundary = 0;
    for min in edges { for max in edges { for def in std::iter::once(None).chain(edges.map(Some)) {
        for req in std::iter::once(None).chain(edges.map(Some)) { for bits in 0..8 {
            compare(port::Policy { require_expiration: bits & 1 != 0, min_days: min, max_days: max,
                default_days: def, apply_to_service_accounts: bits & 2 != 0 }, req, bits & 4 != 0);
            boundary += 1;
        }}
    }}}
    let mut seed = 0x1b7c42891u64;
    for _ in 0..500_000 {
        let min = next(&mut seed) as i64; let max = next(&mut seed) as i64;
        let def = if next(&mut seed) & 1 == 0 { None } else { Some(next(&mut seed) as i64) };
        let request = if next(&mut seed) & 1 == 0 { None } else { Some(next(&mut seed) as i64) };
        let bits = next(&mut seed);
        compare(port::Policy { require_expiration: bits & 1 != 0, min_days: min, max_days: max,
            default_days: def, apply_to_service_accounts: bits & 2 != 0 }, request, bits & 4 != 0);
    }
    println!("PASS: {boundary} boundary cases and 500000 deterministic random cases; default, validation error precedence and all resolution fields compared");
}
