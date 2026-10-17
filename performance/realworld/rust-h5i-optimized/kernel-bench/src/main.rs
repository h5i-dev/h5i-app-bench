//! Microbenchmark of one kernel decision against the same decision inlined.
use std::hint::black_box;
use std::time::Instant;

use conduit_kernel::{transition, Command, Delta, Reply, View};

fn view(already: bool) -> View {
    View {
        actor: 7,
        article_exists: true,
        article_author: 3,
        comment_exists: true,
        comment_author: 7,
        profile_exists: true,
        already,
    }
}

fn inlined(already: bool) -> (bool, u8) {
    if already {
        (true, 0)
    } else {
        (true, 1)
    }
}

fn main() {
    let n: u64 = std::env::var("KERNEL_ITERS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(2_000_000);
    let v = view(true);
    let cmd = Command::Favorite;
    let start = Instant::now();
    let mut acc = 0u64;
    for _ in 0..n {
        match transition(black_box(&v), black_box(&cmd)) {
            Ok(Reply::Favorite { favorited, delta }) => {
                acc = acc.wrapping_add(u64::from(favorited));
                acc = acc.wrapping_add(match delta {
                    Delta::Same => 1,
                    Delta::Up => 2,
                    Delta::Down => 3,
                });
            }
            _ => acc = acc.wrapping_add(9),
        }
    }
    let kernel_ns = start.elapsed().as_nanos() / u128::from(n);
    black_box(acc);

    let start = Instant::now();
    let mut acc = 0u64;
    for _ in 0..n {
        let (favorited, delta) = inlined(black_box(true));
        acc = acc.wrapping_add(u64::from(favorited));
        acc = acc.wrapping_add(u64::from(delta));
    }
    let inline_ns = start.elapsed().as_nanos() / u128::from(n);
    black_box(acc);

    println!(
        "{{\"iters\":{n},\"kernel_ns\":{kernel_ns},\"inlined_ns\":{inline_ns}}}"
    );
}
