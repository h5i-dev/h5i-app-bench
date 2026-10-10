//! Paired route benchmark using the differential harness's in-memory services.
//! Not a full upstream server benchmark: includes adapter/service construction.
use std::{hint::black_box, time::Instant};
use tuwunel_difftest::{
    generate::{Rng, request, snapshot},
    world::upstream,
};
use tuwunel_kernel::{Error, Reply, transition};

fn normalize(r: Result<Reply, Error>) -> Result<Reply, Error> {
    r.map(|x| match x {
        Reply::JoinedMembers { mut joined } => {
            joined.sort();
            joined.dedup();
            Reply::JoinedMembers { joined }
        }
        x => x,
    })
}

fn median(v: &[f64]) -> f64 {
    let mut v = v.to_vec();
    v.sort_by(f64::total_cmp);
    v[v.len() / 2]
}

fn main() {
    let rounds: usize = std::env::args()
        .nth(1)
        .map(|s| s.parse().unwrap())
        .unwrap_or(10);
    assert!(rounds > 0);
    let seed = 0x7455776e656c_u64;
    let mut rng = Rng(seed);
    let corpus: Vec<_> = (0..32)
        .map(|_| {
            let s = snapshot(&mut rng).snapshot;
            let qs: Vec<_> = (0..40).map(|_| request(&mut rng, &s)).collect();
            (s, qs)
        })
        .collect();
    let mut successes = 0;
    for (s, qs) in &corpus {
        for q in qs {
            let u = normalize(upstream(s, q));
            let k = normalize(transition(s, q));
            assert_eq!(u, k, "request: {q:?}");
            successes += usize::from(k.is_ok());
        }
    }
    let measure = |kernel: bool, n: usize| {
        let start = Instant::now();
        for _ in 0..n {
            for (s, qs) in &corpus {
                for q in qs {
                    black_box(if kernel {
                        transition(black_box(s), black_box(q))
                    } else {
                        upstream(black_box(s), black_box(q))
                    });
                }
            }
        }
        start.elapsed().as_nanos() as f64 / (n * 1280) as f64
    };
    measure(false, 1);
    measure(true, 1);
    let (mut us, mut ks, mut ratios) = (Vec::new(), Vec::new(), Vec::new());
    for i in 0..11 {
        let (u, k) = if i % 2 == 0 {
            (measure(false, rounds), measure(true, rounds))
        } else {
            let k = measure(true, rounds);
            (measure(false, rounds), k)
        };
        us.push(u);
        ks.push(k);
        ratios.push(k / u);
    }
    println!(
        "{}",
        serde_json::json!({
            "benchmark": "mixed_routes_adapter_inclusive", "seed": seed,
            "inputs": 1280, "successful_inputs": successes, "rounds": rounds,
            "samples": 11, "upstream_ns_per_call": median(&us),
            "kernel_ns_per_call": median(&ks), "kernel_over_upstream": median(&ratios),
            "upstream_samples_ns": us, "kernel_samples_ns": ks, "reply_parity": true,
            "scope": "copied upstream routes with in-memory service stubs; includes snapshot loading and adapter conversion; not full upstream server"
        })
    );
}
