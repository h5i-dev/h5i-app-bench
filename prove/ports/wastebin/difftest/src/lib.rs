//! Differential tests of the wastebin kernel against wastebin @ c0ec968.
//!
//! `upstream` holds the server crate's private items, copied verbatim by
//! `build.rs`; `wastebin_core` (ids, the database) is linked as the upstream
//! crate itself. Every test uses a fixed seed.

#![allow(dead_code)]

/// The upstream server items, with the one crate type they name stubbed:
/// `crate::errors::Error` keeps only its `Id` variant, which is all
/// `Key::from_str` produces.
pub mod upstream {
    use std::fmt::{Display, Write};
    use std::str::FromStr;

    use http::HeaderValue;
    use wastebin_core::id::{self, Id};

    #[derive(Debug)]
    pub enum Error {
        Id(id::Error),
    }

    impl From<id::Error> for Error {
        fn from(e: id::Error) -> Self {
            Error::Id(e)
        }
    }

    include!(concat!(env!("OUT_DIR"), "/upstream_server.rs"));

    /// `Key::from_str`, for the tests.
    pub fn parse_key(s: &str) -> Result<(Id, Option<String>), id::Error> {
        match Key::from_str(s) {
            Ok(k) => Ok((k.id, k.ext)),
            Err(Error::Id(e)) => Err(e),
        }
    }

    /// `Key`'s `Display`.
    pub fn key_string(id: Id, ext: Option<String>) -> String {
        Key { id, ext }.to_string()
    }

    pub fn valid_ext(s: &str) -> bool {
        valid_extension(s)
    }

    pub fn disposition(s: &str) -> Vec<u8> {
        make_content_disposition(s).as_bytes().to_vec()
    }
}

/// SplitMix64: a fixed-seed generator, so every run sees the same cases.
pub struct Rng(pub u64);

impl Rng {
    pub fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9e37_79b9_7f4a_7c15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xbf58_476d_1ce4_e5b9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94d0_49bb_1331_11eb);
        z ^ (z >> 31)
    }
    pub fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
    pub fn chance(&mut self, num: u64, den: u64) -> bool {
        self.below(den) < num
    }
    pub fn pick<'a, T>(&mut self, xs: &'a [T]) -> &'a T {
        &xs[self.below(xs.len() as u64) as usize]
    }
}

pub const ALPHABET: &str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-+";

/// Characters that exercise the parsers: the id alphabet, the extension
/// punctuation, separators, quotes, whitespace, and multi-byte characters.
pub const NOISE: &[char] = &[
    '.', '_', '-', '+', '/', '\\', '"', '\'', '<', '>', ' ', '\t', '\n', '\r', '%', '#', '?', '&',
    ';', ',', '=', '~', '*', '\0', 'ü', 'é', '€', '漢', '😀', '\u{a0}', '\u{7f}', '\u{200b}',
];

pub fn random_char(r: &mut Rng) -> char {
    if r.chance(3, 4) {
        ALPHABET.as_bytes()[r.below(64) as usize] as char
    } else {
        *r.pick(NOISE)
    }
}

pub fn random_string(r: &mut Rng, len: usize) -> String {
    (0..len).map(|_| random_char(r)).collect()
}

#[cfg(test)]
mod ids_tests;
#[cfg(test)]
mod store_tests;
