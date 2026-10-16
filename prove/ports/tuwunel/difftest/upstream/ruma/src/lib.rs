//! The parts of ruma that tuwunel's visibility code touches, as plain Rust.
//! Ids are string newtypes (borrowed `UserId` as in ruma, owned
//! `OwnedUserId`); event contents deserialize from the same JSON as ruma's.
use std::{borrow::Borrow, fmt, ops::Deref};

pub use js_int::{TryFromIntError, UInt, uint};

macro_rules! id {
    ($id:ident, $owned:ident) => {
        #[repr(transparent)]
        #[derive(PartialEq, Eq, PartialOrd, Ord, Hash)]
        pub struct $id(str);

        impl $id {
            pub fn from_borrowed(s: &str) -> &Self {
                // SAFETY: `$id` is a transparent wrapper of `str`.
                unsafe { &*(s as *const str as *const Self) }
            }
            pub fn as_str(&self) -> &str {
                &self.0
            }
            pub fn as_bytes(&self) -> &[u8] {
                self.0.as_bytes()
            }
        }

        #[derive(Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
        pub struct $owned(Box<str>);

        impl $owned {
            pub fn new(s: &str) -> Self {
                Self(s.into())
            }
        }

        impl Deref for $owned {
            type Target = $id;
            fn deref(&self) -> &$id {
                $id::from_borrowed(&self.0)
            }
        }
        impl Borrow<$id> for $owned {
            fn borrow(&self) -> &$id {
                self
            }
        }
        impl AsRef<$id> for $owned {
            fn as_ref(&self) -> &$id {
                self
            }
        }
        impl AsRef<str> for $id {
            fn as_ref(&self) -> &str {
                &self.0
            }
        }
        impl AsRef<[u8]> for $id {
            fn as_ref(&self) -> &[u8] {
                self.0.as_bytes()
            }
        }
        impl ToOwned for $id {
            type Owned = $owned;
            fn to_owned(&self) -> $owned {
                $owned(self.0.into())
            }
        }
        impl From<&$id> for $owned {
            fn from(x: &$id) -> Self {
                x.to_owned()
            }
        }
        impl<'a> TryFrom<&'a str> for &'a $id {
            type Error = ();
            fn try_from(s: &'a str) -> Result<Self, ()> {
                Ok($id::from_borrowed(s))
            }
        }
        impl PartialEq<$id> for $owned {
            fn eq(&self, o: &$id) -> bool {
                **self == *o
            }
        }
        impl PartialEq<$owned> for $id {
            fn eq(&self, o: &$owned) -> bool {
                *self == **o
            }
        }
        impl PartialEq<&$id> for $owned {
            fn eq(&self, o: &&$id) -> bool {
                **self == **o
            }
        }
        impl PartialEq<$owned> for &$id {
            fn eq(&self, o: &$owned) -> bool {
                **self == **o
            }
        }
        impl fmt::Debug for $id {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                fmt::Debug::fmt(&self.0, f)
            }
        }
        impl fmt::Display for $id {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                f.write_str(&self.0)
            }
        }
        impl fmt::Debug for $owned {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                fmt::Debug::fmt(&*self.0, f)
            }
        }
        impl fmt::Display for $owned {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                f.write_str(&self.0)
            }
        }
        impl ::serde::Serialize for $id {
            fn serialize<S: ::serde::Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
                s.serialize_str(&self.0)
            }
        }
        impl ::serde::Serialize for $owned {
            fn serialize<S: ::serde::Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
                s.serialize_str(&self.0)
            }
        }
        impl<'de> ::serde::Deserialize<'de> for $owned {
            fn deserialize<D: ::serde::Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
                let s = String::deserialize(d)?;
                Ok($owned(s.into()))
            }
        }
    };
}

id!(UserId, OwnedUserId);
id!(RoomId, OwnedRoomId);
id!(EventId, OwnedEventId);
id!(ServerName, OwnedServerName);
id!(DeviceId, OwnedDeviceId);

impl UserId {
    /// `@local:server` has server `server`.
    pub fn server_name(&self) -> &ServerName {
        let s = self.as_str();
        ServerName::from_borrowed(&s[s.find(':').map_or(s.len(), |i| i + 1)..])
    }
    pub fn parse(s: &str) -> Result<OwnedUserId, ()> {
        if s.starts_with('@') && s.contains(':') { Ok(OwnedUserId::new(s)) } else { Err(()) }
    }
}

impl ServerName {
    pub fn host(&self) -> &str {
        self.as_str()
    }
}

impl<'de> ::serde::Deserialize<'de> for &'de UserId {
    fn deserialize<D: ::serde::Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
        let s: &'de str = <&str>::deserialize(d)?;
        Ok(UserId::from_borrowed(s))
    }
}

pub type CanonicalJsonObject = serde_json::Map<String, serde_json::Value>;

pub mod api {
    #[derive(Clone, Copy, Debug, PartialEq, Eq)]
    pub enum Direction {
        Forward,
        Backward,
    }

    pub mod client;
}

pub mod events;

pub mod serde {
    use std::marker::PhantomData;

    /// An event as served: the stub keeps its JSON.
    #[derive(Clone, Debug)]
    pub struct Raw<T> {
        pub json: serde_json::Value,
        _t: PhantomData<T>,
    }

    impl<T> Raw<T> {
        pub fn from_json_value(json: serde_json::Value) -> Self {
            Self { json, _t: PhantomData }
        }
    }
}
