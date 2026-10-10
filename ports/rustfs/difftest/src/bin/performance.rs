//! Paired microbenchmarks against the actual pinned rustfs-policy crate.
// The upstream modules are private; compile the pinned source files directly
// without changing their visibility or implementation in the upstream copy.
#[path = "../../../upstream-src/crates/policy/src/policy/utils/path.rs"]
mod path;
#[path = "../../../upstream-src/crates/policy/src/policy/utils/wildcard.rs"]
mod wildcard;
use std::{hint::black_box, time::Instant};

fn median(xs: &[f64]) -> f64 {
    let mut xs = xs.to_vec();
    xs.sort_by(f64::total_cmp);
    xs[xs.len() / 2]
}

fn compare<T, U>(
    name: &str,
    scope: &str,
    up: impl Fn(&str) -> T,
    port: impl Fn(&str) -> U,
    inputs: &[String],
    rounds: usize,
) {
    let measure = |kernel: bool, n: usize| {
        let start = Instant::now();
        for _ in 0..n {
            for s in inputs {
                if kernel {
                    black_box(port(black_box(s)));
                } else {
                    black_box(up(black_box(s)));
                }
            }
        }
        start.elapsed().as_nanos() as f64 / (n * inputs.len()) as f64
    };
    measure(false, rounds / 10 + 1);
    measure(true, rounds / 10 + 1);
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
        serde_json::json!({"benchmark": name, "inputs": inputs.len(),
        "input_lengths_bytes": inputs.iter().map(String::len).collect::<Vec<_>>(),
        "rounds": rounds, "samples": 11, "upstream_ns_per_call": median(&us),
        "kernel_ns_per_call": median(&ks), "kernel_over_upstream": median(&ratios),
        "upstream_samples_ns": us, "kernel_samples_ns": ks, "reply_parity": true,
        "scope": scope})
    );
}

fn main() {
    let rounds: usize = std::env::args()
        .nth(1)
        .map(|s| s.parse().unwrap())
        .unwrap_or(100_000);
    assert!(rounds > 0);
    let inputs: Vec<String> = [
        "",
        "/",
        "bucket/a",
        "bucket/a/../b",
        "a//b/./c",
        "../a/../../b",
        "/a/b/../../c",
        "é/a/../x",
        "a\\b/../x",
    ]
    .into_iter()
    .map(str::to_owned)
    .chain(["a/".repeat(128), format!("{}/../x", "a".repeat(1024))])
    .collect();
    // Upstream returns a String; the kernel returns bytes, which the shell must
    // turn back into the String upstream's callers use. Time that conversion
    // on the kernel side, as `String::from_utf8_lossy` like upstream's own.
    let kernel_clean = |s: &str| String::from_utf8_lossy(&rustfs_kernel::pathclean::clean(s.as_bytes())).into_owned();
    for s in &inputs {
        assert_eq!(path::clean(s), kernel_clean(s));
    }
    compare(
        "path_clean",
        "matched function-only; pinned upstream crate; prebuilt str; both sides return String (kernel bytes converted back by the shell); includes output allocations",
        |s| path::clean(s),
        kernel_clean,
        &inputs,
        rounds,
    );
    for pattern in ["*", "bucket/*", "b?cket/a", "bucket/a/../b"] {
        for s in &inputs {
            assert_eq!(
                wildcard::is_match(pattern, s),
                rustfs_kernel::wildmatch::is_match(pattern.as_bytes(), s.as_bytes())
            );
        }
        compare(
            &format!("wildcard:{pattern}"),
            "matched function-only; pinned upstream crate; prebuilt str/bytes; bool result; no shell conversion",
            |s| wildcard::is_match(pattern, s),
            |s| rustfs_kernel::wildmatch::is_match(pattern.as_bytes(), s.as_bytes()),
            &inputs,
            rounds,
        );
    }
}
