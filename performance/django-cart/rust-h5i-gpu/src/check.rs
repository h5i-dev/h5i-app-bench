//! Binary fixture protocol for the independent upstream Python oracle.
use django_cart_pricing::{WIDTH, at};
use std::io::{Read, Write};
fn main() {
    let mut input = vec![];
    std::io::stdin().read_to_end(&mut input).unwrap();
    assert_eq!(input.len() % (WIDTH * 8), 0, "truncated fixture");
    let mut out = std::io::BufWriter::new(std::io::stdout().lock());
    for bytes in input.chunks_exact(WIDTH * 8) {
        let row: Vec<_> = bytes
            .chunks_exact(8)
            .map(|b| u64::from_le_bytes(b.try_into().unwrap()))
            .collect();
        out.write_all(&at(&row).to_le_bytes()).unwrap();
    }
}
