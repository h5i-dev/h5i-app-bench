//! `pathcheck` against `synctv_common::validation::validate_path_for_traversal`.
use crate::Rng;
use synctv_common::validation::validate_path_for_traversal as upstream;
use synctv_kernel::pathcheck::{self as k, TraversalError as E};

fn kind(r: Result<(), synctv_common::validation::PathTraversalError>) -> Result<(), E> {
    match r {
        Ok(()) => Ok(()),
        Err(e) => Err(match e.reason.as_str() {
            "must not contain '..' for path traversal" => E::DotDot,
            "must not contain null bytes" => E::NullByte,
            "must not contain mixed dot sequences" => E::MixedDots,
            "must not contain URL-encoded dot character" => E::EncodedDot,
            "must not contain double-encoded dot character" => E::DoubleEncodedDot,
            "must not contain triple-encoded dot character" => E::TripleEncodedDot,
            other => panic!("unexpected reason {other:?}"),
        }),
    }
}

/// Paths over an alphabet heavy in `%`, hex digits, `.`, `/`, `+`, NUL and non-ASCII.
fn random_path(r: &mut Rng) -> String {
    const PIECES: &[&str] = &[
        "%", "2", "5", "e", "E", "0", "%2e", "%2E", "%25", "%252e", "%25252e", ".", "/", "a", "+",
        "\0", "\u{e9}", "%A\u{e9}", "%00", "f", "F", "9", "\\", "%2", "%65",
    ];
    let n = r.below(10);
    (0..n).map(|_| PIECES[r.below(PIECES.len() as u64) as usize]).collect()
}

#[test]
fn traversal_check_agrees() {
    let mut r = Rng(0x5157_0301);
    let mut n = 0;
    for _ in 0..400_000 {
        let p = random_path(&mut r);
        assert_eq!(k::validate_path_for_traversal(p.as_bytes()), kind(upstream(&p)), "{p:?}");
        n += 1;
    }
    // Every string of length <= 3 over a small alphabet, exhaustively.
    const A: &[u8] = b"%2e5.0/+E";
    for len in 0..=4u32 {
        let total = (A.len() as u64).pow(len);
        for code in 0..total {
            let mut c = code;
            let s: String = (0..len).map(|_| { let ch = A[(c % A.len() as u64) as usize] as char; c /= A.len() as u64; ch }).collect();
            assert_eq!(k::validate_path_for_traversal(s.as_bytes()), kind(upstream(&s)), "{s:?}");
            n += 1;
        }
    }
    eprintln!("traversal_check_agrees: {n} paths");
}

/// One round of percent-decoding (`%XX` with two hex digits), keeping anything else.
pub fn percent_decode_once(s: &[u8]) -> Vec<u8> {
    let hex = |b: u8| (b as char).to_digit(16);
    let mut out = Vec::new();
    let mut i = 0;
    while i < s.len() {
        if s[i] == b'%' && i + 2 < s.len() {
            if let (Some(h), Some(l)) = (hex(s[i + 1]), hex(s[i + 2])) {
                out.push((h * 16 + l) as u8);
                i += 3;
                continue;
            }
        }
        out.push(s[i]);
        i += 1;
    }
    out
}

/// FINDING S3: the "double-encoded dot" check only recognises `%25` followed by `2e`.
/// Encoding the hex digits instead (`%2%65` decodes to `%2e`) passes, and two rounds of
/// decoding then yield `..`.
#[test]
fn double_decoding_bypass() {
    let p = "%2%65%2%65/etc";
    assert!(upstream(p).is_ok(), "upstream now rejects; update FINDINGS.md");
    let twice = percent_decode_once(&percent_decode_once(p.as_bytes()));
    assert_eq!(&twice[..3], b"../");
    let q = "%25%32%65%25%32%65";
    assert!(upstream(q).is_ok());
    assert_eq!(percent_decode_once(&percent_decode_once(q.as_bytes())), b"..");
}
