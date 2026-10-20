pub mod pricing;
pub mod wide;
use pricing::{MAX_LINES, total};

/// Row-major, fixed-width snapshots. The last two words are discount kind/value.
pub const WIDTH: usize = MAX_LINES * 2 + 3;
pub fn at(row: &[u64]) -> u64 {
    if row.len() != WIDTH || row[0] > MAX_LINES as u64 {
        return pricing::ERROR;
    }
    let n = row[0] as usize;
    total(
        &row[1..1 + n],
        &row[1 + MAX_LINES..1 + MAX_LINES + n],
        row[WIDTH - 2],
        row[WIDTH - 1],
    )
}
pub fn fixture(i: usize, lines: usize) -> [u64; WIDTH] {
    assert!(lines <= MAX_LINES);
    let mut row = [0; WIDTH];
    row[0] = lines as u64;
    for j in 0..lines {
        row[1 + j] = ((i * 7919 + j * 104729) % 100_000) as u64;
        row[1 + MAX_LINES + j] = ((i + j) % 9 + 1) as u64;
    }
    row[WIDTH - 2] = (i % 3) as u64;
    row[WIDTH - 1] = if i % 3 == 1 {
        [0, 1, 1250, 3333, 9999, 10000, 15000][i % 7]
    } else {
        (i % 100_000) as u64
    };
    row
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn money_boundaries_and_rejected_inputs() {
        assert_eq!(total(&[], &[], 0, 0), 0);
        assert_eq!(total(&[1], &[1], 1, 5000), 1); // half cent rounds up
        assert_eq!(total(&[3], &[1], 1, 5000), 2);
        assert_eq!(total(&[1], &[1], 1, 10001), 0); // legacy >100%
        assert_eq!(total(&[100], &[2], 2, 201), 0);
        assert_eq!(
            total(&[pricing::MAX_PRICE; 32], &[1000; 32], 0, 0),
            pricing::MAX_PRICE * 32000
        );
        for row in [vec![0; WIDTH - 1], {
            let mut r = vec![0; WIDTH];
            r[0] = 33;
            r
        }] {
            assert_eq!(at(&row), pricing::ERROR);
        }
        assert_eq!(total(&[1], &[0], 0, 0), pricing::ERROR);
        assert_eq!(total(&[u64::MAX], &[1], 0, 0), pricing::ERROR);
        assert_eq!(total(&[1], &[1], 3, 0), pricing::ERROR);
        assert_eq!(total(&[1], &[], 0, 0), pricing::ERROR);
    }
}
