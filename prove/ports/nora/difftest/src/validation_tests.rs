use crate::tests::Rng;
use nora_upstream::validation as up;
use nora_kernel::validation::{self as k, ValidationError as E};

/// Upstream's error, in the kernel's terms.
fn map(e: up::ValidationError) -> E {
    use up::ValidationError as U;
    match e {
        U::PathTraversal => E::PathTraversal,
        U::EmptyInput => E::EmptyInput,
        U::TooLong { .. } => E::TooLong,
        U::ForbiddenCharacter(c) if c.is_ascii() => E::ForbiddenCharacter(c as u8),
        U::ForbiddenCharacter(_) => E::ForbiddenNonAscii,
        U::InvalidDockerName(m) => match m.as_str() {
            "must be lowercase" => E::DockerNameUppercase,
            "cannot start with separator or special character" => E::DockerNameStart,
            "cannot end with /" => E::DockerNameEnd,
            "consecutive separators not allowed" => E::DockerNameConsecutive,
            "empty path segment" => E::DockerNameEmptySegment,
            "segment must start with alphanumeric" => E::DockerNameSegmentStart,
            m => panic!("unknown docker name reason {m}"),
        },
        U::InvalidDigest(m) => {
            if m.starts_with("missing algorithm") {
                E::DigestNoAlgorithm
            } else if m.contains("hash must be") && m.contains("characters") {
                E::DigestLength
            } else if m.starts_with("unsupported algorithm") {
                E::DigestAlgorithm
            } else if m == "hash must be lowercase hex" {
                E::DigestUppercase
            } else if m.starts_with("invalid character in hash") {
                E::DigestCharacter
            } else {
                panic!("unknown digest reason {m}")
            }
        }
        U::InvalidReference(_) => E::ReferenceStart,
    }
}

/// Strings over an alphabet that reaches every branch, sometimes long.
fn text(r: &mut Rng) -> String {
    const A: &[&str] = &["a", "z", "0", "9", "f", "A", "F", ".", "..", "/", "\\", "-", "_", ":", "\0",
        "é", " ", "sha256:", "sha512:", "sha256", "a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4"];
    let n = if r.chance(3) { 300 + r.below(1000) } else { r.below(8) };
    (0..n).map(|_| A[r.below(A.len() as u64) as usize]).collect()
}

#[test]
fn validation_agrees() {
    let mut r = Rng(0xA5A5_1234_5678_9ABC);
    let mut ok = [0usize; 4];
    for _ in 0..2_000_000 {
        let s = text(&mut r);
        let b = s.as_bytes();
        let pairs = [
            (k::validate_storage_key(b), up::validate_storage_key(&s).map_err(map)),
            (k::validate_docker_name(b), up::validate_docker_name(&s).map_err(map)),
            (k::validate_digest(b), up::validate_digest(&s).map_err(map)),
            (k::validate_docker_reference(b), up::validate_docker_reference(&s).map_err(map)),
        ];
        for (i, (got, want)) in pairs.into_iter().enumerate() {
            assert_eq!(got, want, "validator {i} on {s:?}");
            ok[i] += got.is_ok() as usize;
        }
        let t = text(&mut r);
        assert_eq!(k::ends_with_ci(b, t.as_bytes()), up::ends_with_ci(&s, &t), "{s:?} {t:?}");
    }
    // Every validator accepts some inputs.
    assert!(ok.iter().all(|&n| n > 100), "{ok:?}");
}
