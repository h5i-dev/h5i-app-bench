//! Differential tests: extracted kernel decisions vs upstream pico-bit logic
//! (anapeksha/pico-bit @ b6349e2). Deterministic seeds; evidence, not proof.

use pico_bit_difftest::reference as up;
use pico_bit_difftest::{escapes_armory, kernel_decode, kernel_valid_name};

/// Small deterministic xorshift generator.
struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {
        let mut x = self.0;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.0 = x;
        x
    }
    fn byte_from(&mut self, alphabet: &[u8]) -> u8 {
        alphabet[(self.next() as usize) % alphabet.len()]
    }
}

/// A byte alphabet rich in the characters that matter for traversal.
const ALPHABET: &[u8] = b"ab.%/\\2efEF0\x00 -_";

fn gen_inputs() -> Vec<Vec<u8>> {
    let mut out: Vec<Vec<u8>> = Vec::new();

    // Hand-picked adversarial vectors.
    for v in [
        &b""[..],
        &b"."[..],
        &b".."[..],
        &b"../"[..],
        &b"../secret"[..],
        &b"..\\secret"[..],
        &b"%2e%2e"[..],
        &b"%2e%2e%2f"[..],
        &b"%2e%2e/etc"[..],
        &b"a%2fb"[..],
        &b"a%5cb"[..],
        &b"a/b"[..],
        &b"a\\b"[..],
        &b"payload.bin"[..],
        &b"loot.bin"[..],
        &b"%41%42"[..],
        &b"good_name-1"[..],
        &b"%00"[..],
        &b"ab%2"[..],
        &b"%zz"[..],
    ] {
        out.push(v.to_vec());
    }

    // Random fuzzing over the adversarial alphabet, deterministic seed.
    let mut rng = Rng(0x9E3779B97F4A7C15);
    for _ in 0..20_000 {
        let len = (rng.next() as usize) % 10;
        let mut s = Vec::with_capacity(len);
        for _ in 0..len {
            s.push(rng.byte_from(ALPHABET));
        }
        out.push(s);
    }
    out
}

#[test]
fn valid_name_matches_upstream_exactly() {
    // The acceptance gate on already-decoded bytes is bit-for-bit upstream.
    for s in gen_inputs() {
        assert_eq!(
            kernel_valid_name(&s),
            up::valid_armory_asset_filename(&s),
            "valid_name disagreed on {:?}",
            s
        );
    }
}

#[test]
fn decode_agrees_modulo_utf8() {
    // decode_filename == decode_armory_asset_filename, except the kernel omits
    // upstream's trailing UTF-8 check (documented in DEVIATIONS.md). So:
    //  - whenever upstream accepts, the kernel accepts with identical bytes;
    //  - whenever the kernel accepts valid-UTF-8 bytes, upstream accepts too.
    for s in gen_inputs() {
        let k = kernel_decode(&s);
        let u = up::decode_armory_asset_filename(&s);
        match (&k, &u) {
            (Some(kb), Some(ub)) => assert_eq!(kb, ub, "decoded bytes differ on {:?}", s),
            (Some(kb), None) => {
                // Only allowed difference: kb is not valid UTF-8.
                assert!(
                    core::str::from_utf8(kb).is_err(),
                    "kernel accepted {:?} -> {:?} but upstream rejected (and it is valid UTF-8)",
                    s,
                    kb
                );
            }
            (None, Some(ub)) => {
                panic!("upstream accepted {:?} -> {:?} but kernel rejected", s, ub);
            }
            (None, None) => {}
        }
    }
}

#[test]
fn accepted_names_never_escape_armory() {
    // The security property, witnessed at runtime: every decoded name the
    // kernel accepts builds a path that stays a direct child of /armory.
    for s in gen_inputs() {
        if let Some(name) = kernel_decode(&s) {
            assert!(
                !escapes_armory(&name),
                "accepted name {:?} (from {:?}) escapes /armory",
                name,
                s
            );
            // And the upstream path builder agrees it is a confined /armory child.
            let path = up::armory_storage_path_unrestricted(&name)
                .expect("accepted name must build a path");
            assert!(path.starts_with(b"/armory/"));
            // The part after the prefix is a single component with no separator.
            let leaf = &path[b"/armory/".len()..];
            assert!(!leaf.contains(&b'/') && leaf != b".." && leaf != b".");
        }
    }
}

#[test]
fn known_traversal_vectors_rejected() {
    for v in [
        &b".."[..],
        &b"../x"[..],
        &b"%2e%2e"[..],
        &b"%2e%2e%2f"[..],
        &b"a%2fb"[..],
        &b"a/b"[..],
        &b"a\\b"[..],
        &b"%00"[..],
    ] {
        assert!(kernel_decode(v).is_none(), "kernel accepted traversal vector {:?}", v);
        assert!(up::decode_armory_asset_filename(v).is_none(), "upstream accepted {:?}", v);
    }
}
