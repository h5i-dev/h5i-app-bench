//! In-memory stand-in for tuwunel_database: each column is an ordered map
//! of byte keys, built once before a request runs. Keys serialize as
//! upstream's: strings as bytes, integers big-endian, tuple elements joined
//! by `0xFF`. Values hold big-endian integers or JSON.
use std::{collections::BTreeMap, ops::Bound, sync::Mutex};

use futures::{Stream, future::ready, stream};
use serde::{
    Deserialize,
    de::{self, Visitor},
};
use tuwunel_core::{Error, Result, err};

pub type Key<'a> = &'a [u8];
pub type Val<'a> = &'a [u8];
pub type KeyVal<'a> = (Key<'a>, Val<'a>);

pub mod keyval {
    pub use super::{Key, KeyVal, Val};
}

/// A key element that is skipped when deserializing (`(Ignore, &UserId)`).
pub struct Ignore;

/// A trailing separator in a prefix: `(room_id, Interfix)` is `room 0xFF`.
pub struct Interfix;

pub const SEP: u8 = 0xFF;

/// Serializes a key as upstream's `serialize_key`.
pub trait AsKey {
    fn key_into(&self, out: &mut Vec<u8>);

    fn key(&self) -> Vec<u8> {
        let mut v = Vec::new();
        self.key_into(&mut v);
        v
    }
}

impl<T: AsKey + ?Sized> AsKey for &T {
    fn key_into(&self, out: &mut Vec<u8>) {
        (**self).key_into(out)
    }
}

impl AsKey for [u8] {
    fn key_into(&self, out: &mut Vec<u8>) {
        out.extend_from_slice(self)
    }
}

impl<const N: usize> AsKey for [u8; N] {
    fn key_into(&self, out: &mut Vec<u8>) {
        out.extend_from_slice(self)
    }
}

impl AsKey for str {
    fn key_into(&self, out: &mut Vec<u8>) {
        out.extend_from_slice(self.as_bytes())
    }
}

impl AsKey for u64 {
    fn key_into(&self, out: &mut Vec<u8>) {
        out.extend_from_slice(&self.to_be_bytes())
    }
}

impl AsKey for Interfix {
    fn key_into(&self, _out: &mut Vec<u8>) {}
}

macro_rules! id_key {
    ($($t:ty),*) => {$(
        impl AsKey for $t {
            fn key_into(&self, out: &mut Vec<u8>) {
                out.extend_from_slice(self.as_bytes())
            }
        }
    )*};
}
id_key!(ruma::UserId, ruma::RoomId, ruma::EventId, ruma::OwnedUserId, ruma::OwnedRoomId, ruma::OwnedEventId);

impl AsKey for tuwunel_core::RawPduId {
    fn key_into(&self, out: &mut Vec<u8>) {
        out.extend_from_slice(self.as_bytes())
    }
}

impl<A: AsKey, B: AsKey> AsKey for (A, B) {
    fn key_into(&self, out: &mut Vec<u8>) {
        self.0.key_into(out);
        out.push(SEP);
        self.1.key_into(out);
    }
}

impl<A: AsKey, B: AsKey, C: AsKey> AsKey for (A, B, C) {
    fn key_into(&self, out: &mut Vec<u8>) {
        self.0.key_into(out);
        out.push(SEP);
        self.1.key_into(out);
        out.push(SEP);
        self.2.key_into(out);
    }
}

/// A value read from a column.
pub struct Handle<'a>(&'a [u8]);

impl std::ops::Deref for Handle<'_> {
    type Target = [u8];
    fn deref(&self) -> &[u8] {
        self.0
    }
}

/// A key read back as typed parts (`keys_prefix`).
pub trait FromKey<'a>: Sized {
    fn from_key(k: &'a [u8]) -> Result<Self>;
}

impl<'a> FromKey<'a> for (Ignore, &'a ruma::UserId) {
    fn from_key(k: &'a [u8]) -> Result<Self> {
        let i = k.iter().position(|&b| b == SEP).ok_or(Error::Database)?;
        let s = std::str::from_utf8(&k[i + 1..]).map_err(|_| Error::Database)?;
        Ok((Ignore, ruma::UserId::from_borrowed(s)))
    }
}

#[derive(Default)]
pub struct Map {
    pub data: BTreeMap<Vec<u8>, Vec<u8>>,
    /// Keys `remove` was called on; reads do not see removals, and one
    /// request runs per snapshot.
    pub removed: Mutex<Vec<Vec<u8>>>,
}

impl Map {
    pub fn insert<K: AsKey + ?Sized>(&mut self, k: &K, v: Vec<u8>) {
        self.data.insert(k.key(), v);
    }

    fn lookup(&self, k: Vec<u8>) -> Result<Handle<'_>> {
        match self.data.get(&k) {
            Some(v) => Ok(Handle(v)),
            None => Err(err!(Request(NotFound("Not found in database")))),
        }
    }

    pub fn get<'a, K: AsKey + ?Sized>(&'a self, k: &K) -> impl Future<Output = Result<Handle<'a>>> + Send + use<'a, K> {
        ready(self.lookup(k.key()))
    }

    pub fn qry<'a, K: AsKey + ?Sized>(&'a self, k: &K) -> impl Future<Output = Result<Handle<'a>>> + Send + use<'a, K> {
        ready(self.lookup(k.key()))
    }

    pub fn contains<'a, K: AsKey + ?Sized>(&'a self, k: &K) -> impl Future<Output = bool> + Send + use<'a, K> {
        ready(self.data.contains_key(&k.key()))
    }

    pub fn aqry<'a, const N: usize, K: AsKey + ?Sized>(&'a self, k: &K) -> impl Future<Output = Result<Handle<'a>>> + Send + use<'a, N, K> {
        ready(self.lookup(k.key()))
    }

    pub fn remove<K: AsKey + ?Sized>(&self, k: &K) {
        self.removed.lock().unwrap().push(k.key());
    }

    fn from(&self, start: Vec<u8>) -> Vec<KeyVal<'_>> {
        self.data
            .range::<[u8], _>((Bound::Included(&start[..]), Bound::Unbounded))
            .map(|(k, v)| (&k[..], &v[..]))
            .collect()
    }

    fn rev_from(&self, start: Vec<u8>) -> Vec<KeyVal<'_>> {
        self.data
            .range::<[u8], _>((Bound::Unbounded, Bound::Included(&start[..])))
            .rev()
            .map(|(k, v)| (&k[..], &v[..]))
            .collect()
    }

    pub fn raw_stream_from<'a, K: AsKey + ?Sized>(&'a self, from: &K) -> impl Stream<Item = Result<KeyVal<'a>>> + Send + use<'a, K> {
        stream::iter(self.from(from.key()).into_iter().map(Ok))
    }

    pub fn rev_raw_stream_from<'a, K: AsKey + ?Sized>(&'a self, from: &K) -> impl Stream<Item = Result<KeyVal<'a>>> + Send + use<'a, K> {
        stream::iter(self.rev_from(from.key()).into_iter().map(Ok))
    }

    pub fn raw_keys_from<'a, K: AsKey + ?Sized>(&'a self, from: &K) -> impl Stream<Item = Result<Key<'a>>> + Send + use<'a, K> {
        stream::iter(self.from(from.key()).into_iter().map(|(k, _)| Ok(k)))
    }

    pub fn rev_raw_keys_from<'a, K: AsKey + ?Sized>(&'a self, from: &K) -> impl Stream<Item = Result<Key<'a>>> + Send + use<'a, K> {
        stream::iter(self.rev_from(from.key()).into_iter().map(|(k, _)| Ok(k)))
    }

    pub fn keys_raw_from<'a, T, K>(&'a self, from: &K) -> impl Stream<Item = Result<T>> + Send + use<'a, T, K>
    where
        T: From<&'a [u8]> + Send + 'a,
        K: AsKey + ?Sized,
    {
        stream::iter(self.from(from.key()).into_iter().map(|(k, _)| Ok(T::from(k))))
    }

    pub fn keys_prefix_raw<'a, K: AsKey + ?Sized>(&'a self, prefix: &K) -> impl Stream<Item = Result<Key<'a>>> + Send + use<'a, K> {
        let p = prefix.key();
        let keys: Vec<Key<'_>> = self.from(p.clone()).into_iter().map(|(k, _)| k).take_while(|k| k.starts_with(&p)).collect();
        stream::iter(keys.into_iter().map(Ok))
    }

    pub fn keys_prefix<'a, T, K>(&'a self, prefix: &K) -> impl Stream<Item = Result<T>> + Send + use<'a, T, K>
    where
        T: FromKey<'a> + Send + 'a,
        K: AsKey + ?Sized,
    {
        let p = prefix.key();
        let keys: Vec<Key<'a>> = self.from(p.clone()).into_iter().map(|(k, _)| k).take_while(|k| k.starts_with(&p)).collect();
        stream::iter(keys.into_iter().map(T::from_key))
    }
}

/// `deserialized()` on a read: big-endian integers, strings, JSON.
pub trait Deserialized {
    fn deserialized<T: for<'de> Deserialize<'de>>(self) -> Result<T>;
}

impl Deserialized for Result<Handle<'_>> {
    fn deserialized<T: for<'de> Deserialize<'de>>(self) -> Result<T> {
        let h = self?;
        T::deserialize(De(h.0)).map_err(|_| Error::Database)
    }
}

#[derive(Debug)]
pub struct DeError(String);

impl std::fmt::Display for DeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.0)
    }
}

impl std::error::Error for DeError {}

impl de::Error for DeError {
    fn custom<T: std::fmt::Display>(msg: T) -> Self {
        DeError(msg.to_string())
    }
}

struct De<'a>(&'a [u8]);

impl<'de> de::Deserializer<'de> for De<'de> {
    type Error = DeError;

    fn deserialize_any<V: Visitor<'de>>(self, v: V) -> Result<V::Value, DeError> {
        let mut d = serde_json::Deserializer::from_slice(self.0);
        de::Deserializer::deserialize_any(&mut d, v).map_err(|e| DeError(e.to_string()))
    }

    fn deserialize_u64<V: Visitor<'de>>(self, v: V) -> Result<V::Value, DeError> {
        let b: [u8; 8] = self.0.try_into().map_err(|_| DeError("u64 needs 8 bytes".into()))?;
        v.visit_u64(u64::from_be_bytes(b))
    }

    fn deserialize_str<V: Visitor<'de>>(self, v: V) -> Result<V::Value, DeError> {
        v.visit_str(std::str::from_utf8(self.0).map_err(|e| DeError(e.to_string()))?)
    }

    fn deserialize_string<V: Visitor<'de>>(self, v: V) -> Result<V::Value, DeError> {
        self.deserialize_str(v)
    }

    fn deserialize_struct<V: Visitor<'de>>(self, _n: &'static str, _f: &'static [&'static str], v: V) -> Result<V::Value, DeError> {
        self.deserialize_any(v)
    }

    serde::forward_to_deserialize_any! {
        bool i8 i16 i32 i64 i128 u8 u16 u32 u128 f32 f64 char bytes byte_buf option unit
        unit_struct newtype_struct seq tuple tuple_struct map enum identifier ignored_any
    }
}
