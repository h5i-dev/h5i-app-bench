// Stub of `value.rs`: the syntaxes the access module meets. The
// constructors and `to_str` below the stubs are copied.
use crate::prelude::*;

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub enum PartialValue {
    Utf8(String),
    Iutf8(String),
    Iname(String),
    Uuid(Uuid),
    Refer(Uuid),
    Uint32(u32),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Value {
    Utf8(String),
    Iutf8(String),
    Iname(String),
    Uuid(Uuid),
    Refer(Uuid),
    Uint32(u32),
}
