//! Ids, keys, extensions and `Content-Disposition`: kernel against upstream
//! on generated strings and numbers.

use std::str::FromStr;

use wastebin_core::id::{self as uid, Id as UId};
use wastebin_kernel::{disposition, ext, ids};

use crate::{ALPHABET, Rng, random_string, upstream};

fn to_kernel(id: UId) -> ids::Id {
    match id {
        UId::Id32(n) => ids::Id::Id32(n),
        UId::Id64(n) => ids::Id::Id64(n),
    }
}

fn err_kernel(e: &uid::Error) -> ids::IdError {
    match e {
        uid::Error::IllegalCharacters => ids::IdError::IllegalCharacters,
        uid::Error::WrongSize => ids::IdError::WrongSize,
    }
}

const EDGE_U32: &[u32] = &[0, 1, 2, 3, 4, 63, 64, 0xff, 0x7fff_ffff, 0x8000_0000, 0xffff_fffe, 0xffff_ffff];
const EDGE_I64: &[i64] = &[0, 1, -1, 15, 16, i64::MIN, i64::MAX, i64::MIN + 1, 0xfff_ffff_ffff_ffff];

#[test]
fn encode_agrees() {
    let mut r = Rng(0x5eed_0001);
    let mut n32: Vec<u32> = EDGE_U32.to_vec();
    let mut n64: Vec<i64> = EDGE_I64.to_vec();
    for _ in 0..200_000 {
        n32.push(r.next() as u32);
        n64.push(r.next() as i64);
    }
    for &n in &n32 {
        let up = UId::from(n);
        assert_eq!(ids::encode(ids::Id::Id32(n)), up.to_string().into_bytes(), "Id32 {n}");
        assert_eq!(ids::to_i64(ids::Id::Id32(n)), up.to_i64());
    }
    for &n in &n64 {
        let up = UId::from(n);
        assert_eq!(ids::encode(ids::Id::Id64(n)), up.to_string().into_bytes(), "Id64 {n}");
        assert_eq!(ids::to_i64(ids::Id::Id64(n)), up.to_i64());
    }
}

fn id_like(r: &mut Rng) -> String {
    let len = match r.below(10) {
        0..=3 => 6,
        4..=7 => 11,
        _ => r.below(14) as usize,
    };
    if r.chance(1, 2) {
        (0..len).map(|_| ALPHABET.as_bytes()[r.below(64) as usize] as char).collect()
    } else {
        random_string(r, len)
    }
}

#[test]
fn decode_agrees() {
    let mut r = Rng(0x5eed_0002);
    let (mut ok, mut wrong, mut illegal) = (0, 0, 0);
    for _ in 0..400_000 {
        let s = id_like(&mut r);
        let k = ids::decode(s.as_bytes());
        match UId::from_str(&s) {
            Ok(id) => {
                ok += 1;
                assert_eq!(k, Ok(to_kernel(id)), "{s:?}");
            }
            Err(e) => {
                match e {
                    uid::Error::WrongSize => wrong += 1,
                    uid::Error::IllegalCharacters => illegal += 1,
                }
                assert_eq!(k, Err(err_kernel(&e)), "{s:?}");
            }
        }
    }
    assert!(ok > 100_000 && wrong > 10_000 && illegal > 50_000, "{ok} {wrong} {illegal}");
}

/// Upstream's decoder is not injective: the last character's six bits are
/// or-ed into a value shifted by only two (Id32) or four (Id64) bits, so
/// distinct URLs name the same paste. The kernel agrees (`decode_agrees`);
/// this pins the upstream behavior the proofs record.
#[test]
fn decode_aliases_upstream() {
    let a = UId::from_str("aaaaba").unwrap();
    let b = UId::from_str("aaaaae").unwrap();
    assert_eq!(a, b);
    assert_eq!(a.to_string(), "aaaaba");
    let c = UId::from_str("aaaaaaaaaab").unwrap();
    let d = UId::from_str("aaaaab").unwrap();
    assert_eq!(c.to_i64(), d.to_i64(), "an Id64 and an Id32 URL reach the same row");
    assert_eq!(ids::decode(b"aaaaba"), ids::decode(b"aaaaae"));
}

fn key_like(r: &mut Rng) -> String {
    let id = id_like(r);
    match r.below(4) {
        0 => id,
        1 => format!("{id}."),
        _ => {
            let len = if r.chance(1, 8) { 30 + r.below(6) as usize } else { r.below(12) as usize };
            let ext: String = if r.chance(1, 2) {
                (0..len).map(|_| *r.pick(&['a', 'Z', '9', '.', '_', '-'])).collect()
            } else {
                random_string(r, len)
            };
            format!("{id}.{ext}")
        }
    }
}

#[test]
fn key_agrees() {
    let mut r = Rng(0x5eed_0003);
    let mut accepted = 0;
    for _ in 0..300_000 {
        let s = key_like(&mut r);
        let k = ids::parse_key(s.as_bytes());
        match upstream::parse_key(&s) {
            Ok((id, ext)) => {
                accepted += 1;
                let kk = k.unwrap_or_else(|e| panic!("{s:?}: kernel {e:?}"));
                assert_eq!(kk.id, to_kernel(id), "{s:?}");
                assert_eq!(kk.ext, ext.clone().map(String::into_bytes), "{s:?}");
                assert_eq!(ids::key_path(&kk), upstream::key_string(id, ext).into_bytes(), "{s:?}");
            }
            Err(e) => assert_eq!(k, Err(err_kernel(&e)), "{s:?}"),
        }
    }
    assert!(accepted > 50_000, "{accepted}");
}

#[test]
fn extension_agrees() {
    let mut r = Rng(0x5eed_0004);
    for _ in 0..300_000 {
        let len = if r.chance(1, 4) { 28 + r.below(8) as usize } else { r.below(10) as usize };
        let s: String = if r.chance(1, 2) {
            (0..len).map(|_| *r.pick(&['a', 'Q', '0', '.', '_', '-'])).collect()
        } else {
            random_string(&mut r, len)
        };
        assert_eq!(ext::valid_extension(s.as_bytes()), upstream::valid_ext(&s), "{s:?}");
    }
}

#[test]
fn disposition_agrees() {
    let mut r = Rng(0x5eed_0005);
    let mut inputs: Vec<String> = vec![String::new(), "a\"b".into(), "x\r\nSet-Cookie: a=b".into()];
    for _ in 0..200_000 {
        let len = r.below(24) as usize;
        inputs.push(random_string(&mut r, len));
    }
    for s in inputs {
        let up = upstream::disposition(&s);
        assert_ne!(up, b"attachment".to_vec(), "upstream fell back for {s:?}");
        assert_eq!(disposition::content_disposition(s.as_bytes()), up, "{s:?}");
    }
}
