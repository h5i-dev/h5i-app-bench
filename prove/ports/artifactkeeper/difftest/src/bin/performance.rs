//! Paired middleware harness timings, not a whole-server benchmark.
use artifactkeeper_difftest::{gen::*, shell::*};
use artifactkeeper_kernel as k;
use std::{hint::black_box, time::Instant};

type Output = (Vec<k::resolve::Write>, k::middleware::Outcome);

fn kernel(
    layer: Layer,
    db: &k::tables::Db,
    o: &k::trusted::Oracle,
    ip: Option<k::net::IpAddr>,
    req: &k::http::Request,
) -> Output {
    match layer {
        Layer::RepoVisibility => k::middleware::repo_visibility_middleware(db, o, ip, req),
        Layer::Auth => k::middleware::auth_middleware(db, o, req),
        Layer::OptionalAuth => k::middleware::optional_auth_middleware(db, o, req),
        Layer::Admin => k::middleware::admin_middleware(db, o, req),
        Layer::Guest(enabled) => (vec![], k::middleware::guest_access_guard(enabled, o, req)),
    }
}

fn measure(rounds: usize, cases: usize, mut f: impl FnMut(usize) -> Output) -> u128 {
    let start = Instant::now();
    for _ in 0..rounds {
        for i in 0..cases {
            black_box(f(i));
        }
    }
    start.elapsed().as_nanos()
}

fn main() {
    let rounds: usize = std::env::args()
        .nth(1)
        .unwrap_or("10".into())
        .parse()
        .unwrap();
    assert!(rounds > 0);
    if std::env::args().any(|arg| arg == "--pure-only") {
        pure_scopes(rounds);
        return;
    }
    let rt = runtime();
    let seed = 0x6172_7469_6661_0011;
    let mut rng = Rng(seed);
    let mut cases = Vec::new();
    let mut skipped = 0;
    for _ in 0..128 {
        let d = db(&mut rng);
        let mut o = oracle(&mut rng, &d);
        let ip = client_ip(&mut rng);
        let m = rand_method(&mut rng);
        let p = path(&mut rng);
        let q = query(&mut rng);
        let hs = headers(&mut rng);
        let Some((_, req)) = request(m, &p, q.as_deref(), &hs) else {
            skipped += 1;
            continue;
        };
        fill_base64(&mut o, &req.headers);
        cases.push((d, o, ip, m, p, q, hs, req));
    }
    assert!(!cases.is_empty());
    for layer in [
        Layer::RepoVisibility,
        Layer::Auth,
        Layer::OptionalAuth,
        Layer::Admin,
        Layer::Guest(false),
        Layer::Guest(true),
    ] {
        let upstream = |i: usize| {
            let (d, o, ip, m, p, q, hs, _) = &cases[i];
            let (req, _) = request(*m, p, q.as_deref(), hs).unwrap();
            run(&rt, layer, d, o, *ip, req)
        };
        let rewritten = |i: usize| {
            let (d, o, ip, _, _, _, _, req) = &cases[i];
            kernel(layer, d, o, *ip, req)
        };
        let mut writes = 0;
        for i in 0..cases.len() {
            let u = upstream(i);
            assert_eq!(rewritten(i), u, "{layer:?}, case {i}");
            writes += usize::from(!u.0.is_empty());
        }
        black_box(measure(1, cases.len(), upstream));
        black_box(measure(1, cases.len(), rewritten));
        let (mut us, mut ks) = (Vec::new(), Vec::new());
        for sample in 0..11 {
            if sample % 2 == 0 {
                us.push(measure(rounds, cases.len(), upstream));
                ks.push(measure(rounds, cases.len(), rewritten));
            } else {
                ks.push(measure(rounds, cases.len(), rewritten));
                us.push(measure(rounds, cases.len(), upstream));
            }
        }
        let mut ratios: Vec<_> = ks.iter().zip(&us).map(|(k, u)| *k as f64 / *u as f64).collect();
        ratios.sort_by(f64::total_cmp);
        println!(
            "{}",
            serde_json::json!({"benchmark":format!("{layer:?}"),
            "cases":cases.len(),"skipped_requests":skipped,"cases_with_writes":writes,
            "seed":format!("0x{seed:x}"),"rounds":rounds,"samples":11,
            "upstream_ns":us,"kernel_ns":ks,"kernel_over_upstream":ratios[5],
            "scope":"wrapper-inclusive: upstream includes axum request construction, fresh mocked database/oracle snapshots, empty caches, router/service setup, async dispatch and output normalization; kernel uses preconverted snapshots and requests; not a matched hot-path or whole-application speedup"})
        );
    }
}

/// Same logical query on preconverted string/byte inputs. Both timings include
/// allocations inside the queried implementation, but no adapter or I/O work.
fn pure_scopes(rounds: usize) {
    let held: Vec<Vec<String>> = [
        vec![], vec!["*"], vec!["admin"], vec!["read"],
        vec!["write:artifacts"], vec!["read", "write"],
        vec!["read:repositories", "write:artifacts", "delete"],
    ].into_iter().map(|v| v.into_iter().map(str::to_owned).collect()).collect();
    let required = ["read", "read:repositories", "write", "write:artifacts", "write:repositories", ":artifacts", "", "admin", "*"];
    let bytes: Vec<Vec<Vec<u8>>> = held.iter().map(|v| v.iter().map(|s| s.as_bytes().to_vec()).collect()).collect();
    let up = |i: usize| artifactkeeper_difftest::upstream_scopes_grant_access(
        black_box(&held[i / required.len()]), black_box(required[i % required.len()]));
    let port = |i: usize| k::token_scope::scopes_grant_access(
        black_box(&bytes[i / required.len()]), black_box(required[i % required.len()].as_bytes()));
    let cases = held.len() * required.len();
    for i in 0..cases { assert_eq!(up(i), port(i), "scope query {i}"); }
    let timed = |f: &dyn Fn(usize) -> bool, n: usize| {
        let start = Instant::now();
        for _ in 0..n { for i in 0..cases { black_box(f(i)); } }
        start.elapsed().as_nanos() as f64 / (n * cases) as f64
    };
    timed(&up, rounds / 10 + 1);
    timed(&port, rounds / 10 + 1);
    let (mut us, mut ks, mut ratios) = (Vec::new(), Vec::new(), Vec::new());
    for sample in 0..11 {
        let (u, p) = if sample % 2 == 0 {
            (timed(&up, rounds), timed(&port, rounds))
        } else {
            let p = timed(&port, rounds); (timed(&up, rounds), p)
        };
        us.push(u); ks.push(p); ratios.push(p / u);
    }
    let median = |v: &[f64]| { let mut v = v.to_vec(); v.sort_by(f64::total_cmp); v[v.len() / 2] };
    println!("{}", serde_json::json!({"benchmark":"scopes_grant_access", "cases":cases,
        "held_scopes":held, "required_scopes":required, "rounds":rounds, "samples":11,
        "upstream_samples_ns":us, "kernel_samples_ns":ks, "reply_parity":true,
        "upstream_ns_per_call":median(&us), "kernel_ns_per_call":median(&ks),
        "kernel_over_upstream":median(&ratios),
        "scope":"matched function-only queries; preconverted String/bytes; includes internal allocations on both sides; excludes adapters, database, async execution and input construction"}));
}
