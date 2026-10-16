//! Paired release-mode microbenchmarks of verbatim upstream validators.
//! Includes validator allocations; excludes input construction and shell conversion.
use nora_kernel::validation as kernel;
use nora_upstream::validation as upstream;
use std::{hint::black_box, time::Instant};

fn measure(f: impl Fn(&str) -> bool, inputs: &[String], rounds: usize) -> f64 {
    let start = Instant::now();
    for _ in 0..rounds {
        for s in inputs {
            black_box(f(black_box(s)));
        }
    }
    start.elapsed().as_nanos() as f64 / (rounds * inputs.len()) as f64
}

fn median(xs: &[f64]) -> f64 {
    let mut xs = xs.to_vec();
    xs.sort_by(f64::total_cmp);
    xs[xs.len() / 2]
}

fn compare(
    name: &str,
    up: fn(&str) -> bool,
    port: fn(&str) -> bool,
    inputs: Vec<String>,
    rounds: usize,
) {
    // Acceptance parity only; full error equivalence is covered by validation_agrees.
    for s in &inputs {
        assert_eq!(up(s), port(s), "{name}: {s:?}");
    }
    measure(up, &inputs, rounds / 10 + 1);
    measure(port, &inputs, rounds / 10 + 1);
    let (mut us, mut ks, mut ratios) = (Vec::new(), Vec::new(), Vec::new());
    for i in 0..11 {
        let (u, k) = if i % 2 == 0 {
            (measure(up, &inputs, rounds), measure(port, &inputs, rounds))
        } else {
            let k = measure(port, &inputs, rounds);
            (measure(up, &inputs, rounds), k)
        };
        us.push(u);
        ks.push(k);
        ratios.push(k / u);
    }
    println!(
        "{}",
        serde_json::json!({"benchmark": name, "inputs": inputs.len(),
        "rounds": rounds, "samples": us.len(), "upstream_ns_per_call": median(&us),
        "kernel_ns_per_call": median(&ks), "kernel_over_upstream": median(&ratios),
        "upstream_samples_ns": us, "kernel_samples_ns": ks,
        "acceptance_parity": true, "scope": "validator-only; prebuilt str/bytes; no shell conversion"})
    );
}

fn main() {
    let rounds: usize = std::env::args()
        .nth(1)
        .map(|s| s.parse().expect("positive rounds"))
        .unwrap_or(100_000);
    assert!(rounds > 0);
    compare(
        "storage_key",
        |s| upstream::validate_storage_key(s).is_ok(),
        |s| kernel::validate_storage_key(s.as_bytes()).is_ok(),
        vec![
            "a".into(),
            "repo/blobs/abcdef".into(),
            "../secret".into(),
            "".into(),
            "é".into(),
            "a".repeat(1024),
        ],
        rounds,
    );
    compare(
        "docker_name",
        |s| upstream::validate_docker_name(s).is_ok(),
        |s| kernel::validate_docker_name(s.as_bytes()).is_ok(),
        vec![
            "repo".into(),
            "org/project-name".into(),
            "Bad/Name".into(),
            "a//b".into(),
            "é".into(),
            "a".repeat(256),
        ],
        rounds,
    );
    compare(
        "digest",
        |s| upstream::validate_digest(s).is_ok(),
        |s| kernel::validate_digest(s.as_bytes()).is_ok(),
        vec![
            format!("sha256:{}", "a".repeat(64)),
            format!("sha512:{}", "0".repeat(128)),
            "sha256:xyz".into(),
            "md5:abc".into(),
            "".into(),
            format!("sha256:{}", "A".repeat(64)),
        ],
        rounds,
    );
    compare(
        "docker_reference",
        |s| upstream::validate_docker_reference(s).is_ok(),
        |s| kernel::validate_docker_reference(s.as_bytes()).is_ok(),
        vec![
            "latest".into(),
            "v1.2.3".into(),
            format!("sha256:{}", "a".repeat(64)),
            "".into(),
            "../secret".into(),
            "é".into(),
            "a".repeat(256),
        ],
        rounds,
    );
}
