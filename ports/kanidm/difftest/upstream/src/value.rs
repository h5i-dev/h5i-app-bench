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

// Copied from kanidm/kanidm @ f608c4f by extract_upstream.py. Do not edit.

impl PartialValue {
    pub fn new_utf8s(s: &str) -> Self {
        PartialValue::Utf8(s.to_string())
    }

    pub fn new_iutf8(s: &str) -> Self {
        PartialValue::Iutf8(s.to_lowercase())
    }

    pub fn new_iname(s: &str) -> Self {
        PartialValue::Iname(s.to_lowercase())
    }

    pub fn to_str(&self) -> Option<&str> {
        match self {
            PartialValue::Utf8(s) => Some(s.as_str()),
            PartialValue::Iutf8(s) => Some(s.as_str()),
            PartialValue::Iname(s) => Some(s.as_str()),
            _ => None,
        }
    }
}

impl Value {
    pub fn new_utf8s(s: &str) -> Self {
        Value::Utf8(s.to_string())
    }

    pub fn new_iutf8(s: &str) -> Self {
        Value::Iutf8(s.to_lowercase())
    }

    pub fn new_iname(s: &str) -> Self {
        Value::Iname(s.to_lowercase())
    }

    pub fn to_str(&self) -> Option<&str> {
        match &self {
            Value::Utf8(s) => Some(s.as_str()),
            Value::Iutf8(s) => Some(s.as_str()),
            Value::Iname(s) => Some(s.as_str()),
            _ => None,
        }
    }
}
