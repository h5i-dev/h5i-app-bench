// Stub of `valueset/`: `ValueSet` is a boxed trait object as upstream; the
// trait lists the methods the access module reaches. The method bodies of
// each implementation below the stubs are copied. The trait's default
// accessors return `None` as upstream does in release builds.
use crate::prelude::*;

pub type ValueSet = Box<dyn ValueSetT + Send + Sync + 'static>;

pub trait ValueSetT: std::fmt::Debug {
    fn contains(&self, pv: &PartialValue) -> bool;
    fn substring(&self, pv: &PartialValue) -> bool;
    fn startswith(&self, pv: &PartialValue) -> bool;
    fn endswith(&self, pv: &PartialValue) -> bool;
    fn lessthan(&self, pv: &PartialValue) -> bool;
    fn clone_box(&self) -> ValueSet;
    fn as_iutf8_set(&self) -> Option<&BTreeSet<String>> {
        None
    }
    fn as_iutf8_iter(&self) -> Option<Box<dyn Iterator<Item = &str> + '_>> {
        None
    }
    fn as_refer_set(&self) -> Option<&BTreeSet<Uuid>> {
        None
    }
    fn to_refer_single(&self) -> Option<Uuid> {
        None
    }
    fn to_uuid_single(&self) -> Option<Uuid> {
        None
    }
    fn as_oauthscopemap(&self) -> Option<&BTreeMap<Uuid, BTreeSet<String>>> {
        None
    }
}

impl Clone for ValueSet {
    fn clone(&self) -> Self {
        self.clone_box()
    }
}

#[derive(Debug, Clone)]
pub struct ValueSetUtf8 {
    pub set: BTreeSet<String>,
}
#[derive(Debug, Clone)]
pub struct ValueSetIutf8 {
    pub set: BTreeSet<String>,
}
#[derive(Debug, Clone)]
pub struct ValueSetIname {
    pub set: BTreeSet<String>,
}
// Upstream's set is a `SmolSet<[Uuid; 1]>`.
#[derive(Debug, Clone)]
pub struct ValueSetUuid {
    pub set: BTreeSet<Uuid>,
}
#[derive(Debug, Clone)]
pub struct ValueSetRefer {
    pub set: BTreeSet<Uuid>,
}
#[derive(Debug, Clone)]
pub struct ValueSetUint32 {
    pub set: BTreeSet<u32>,
}
#[derive(Debug, Clone)]
pub struct ValueSetOauthScopeMap {
    pub map: BTreeMap<Uuid, BTreeSet<String>>,
}

// Copied from kanidm/kanidm @ f608c4f by extract_upstream.py. Do not edit.

impl ValueSetT for ValueSetUtf8 {
    fn contains(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Utf8(s) => self.set.contains(s.as_str()),
            _ => false,
        }
    }

    fn substring(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Utf8(s2) => {
                // We lowercase as LDAP and similar expect case insensitive searches here.
                let s2_lower = s2.to_lowercase();
                self.set
                    .iter()
                    .any(|s1| s1.to_lowercase().contains(&s2_lower))
            }
            _ => {
                debug_assert!(false);
                false
            }
        }
    }

    fn startswith(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Utf8(s2) => {
                // We lowercase as LDAP and similar expect case insensitive searches here.
                let s2_lower = s2.to_lowercase();
                self.set
                    .iter()
                    .any(|s1| s1.to_lowercase().starts_with(&s2_lower))
            }
            _ => {
                debug_assert!(false);
                false
            }
        }
    }

    fn endswith(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Utf8(s2) => {
                // We lowercase as LDAP and similar expect case insensitive searches here.
                let s2_lower = s2.to_lowercase();
                self.set
                    .iter()
                    .any(|s1| s1.to_lowercase().ends_with(&s2_lower))
            }
            _ => {
                debug_assert!(false);
                false
            }
        }
    }

    fn lessthan(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn clone_box(&self) -> ValueSet {
        Box::new(self.clone())
    }
}

impl ValueSetT for ValueSetIutf8 {
    fn contains(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Iutf8(s) => self.set.contains(s.as_str()),
            _ => false,
        }
    }

    fn substring(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Iutf8(s2) => self.set.iter().any(|s1| s1.contains(s2)),
            _ => {
                debug_assert!(false);
                false
            }
        }
    }

    fn startswith(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Iutf8(s2) => self.set.iter().any(|s1| s1.starts_with(s2)),
            _ => {
                debug_assert!(false);
                false
            }
        }
    }

    fn endswith(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Iutf8(s2) => self.set.iter().any(|s1| s1.ends_with(s2)),
            _ => {
                debug_assert!(false);
                false
            }
        }
    }

    fn lessthan(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn as_iutf8_set(&self) -> Option<&BTreeSet<String>> {
        Some(&self.set)
    }

    fn as_iutf8_iter(&self) -> Option<Box<dyn Iterator<Item = &str> + '_>> {
        Some(Box::new(self.set.iter().map(|s| s.as_str())))
    }

    fn clone_box(&self) -> ValueSet {
        Box::new(self.clone())
    }
}

impl ValueSetT for ValueSetIname {
    fn contains(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Iname(s) => self.set.contains(s.as_str()),
            _ => false,
        }
    }

    fn substring(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Iname(s2) => self.set.iter().any(|s1| s1.contains(s2)),
            _ => {
                debug_assert!(false);
                false
            }
        }
    }

    fn startswith(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Iname(s2) => self.set.iter().any(|s1| s1.starts_with(s2)),
            _ => {
                debug_assert!(false);
                false
            }
        }
    }

    fn endswith(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Iname(s2) => self.set.iter().any(|s1| s1.ends_with(s2)),
            _ => {
                debug_assert!(false);
                false
            }
        }
    }

    fn lessthan(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn clone_box(&self) -> ValueSet {
        Box::new(self.clone())
    }
}

impl ValueSetT for ValueSetUuid {
    fn contains(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Uuid(u) => self.set.contains(u),
            _ => false,
        }
    }

    fn substring(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn startswith(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn endswith(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn lessthan(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Uuid(u) => self.set.iter().any(|v| v < u),
            _ => false,
        }
    }

    fn to_uuid_single(&self) -> Option<Uuid> {
        if self.set.len() == 1 {
            self.set.iter().copied().take(1).next()
        } else {
            None
        }
    }

    fn clone_box(&self) -> ValueSet {
        Box::new(self.clone())
    }
}

impl ValueSetT for ValueSetRefer {
    fn contains(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Refer(u) => self.set.contains(u),
            _ => false,
        }
    }

    fn substring(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn startswith(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn endswith(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn lessthan(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Refer(u) => self.set.iter().any(|v| v < u),
            _ => false,
        }
    }

    fn to_refer_single(&self) -> Option<Uuid> {
        if self.set.len() == 1 {
            self.set.iter().copied().take(1).next()
        } else {
            None
        }
    }

    fn as_refer_set(&self) -> Option<&BTreeSet<Uuid>> {
        Some(&self.set)
    }

    fn clone_box(&self) -> ValueSet {
        Box::new(self.clone())
    }
}

impl ValueSetT for ValueSetUint32 {
    fn contains(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Uint32(u) => self.set.contains(u),
            _ => false,
        }
    }

    fn substring(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn startswith(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn endswith(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn lessthan(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Uint32(u) => self.set.iter().any(|i| i < u),
            _ => false,
        }
    }

    fn clone_box(&self) -> ValueSet {
        Box::new(self.clone())
    }
}

impl ValueSetT for ValueSetOauthScopeMap {
    fn contains(&self, pv: &PartialValue) -> bool {
        match pv {
            PartialValue::Refer(u) => self.map.contains_key(u),
            _ => false,
        }
    }

    fn substring(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn startswith(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn endswith(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn lessthan(&self, _pv: &PartialValue) -> bool {
        false
    }

    fn as_oauthscopemap(&self) -> Option<&BTreeMap<Uuid, BTreeSet<String>>> {
        Some(&self.map)
    }

    fn clone_box(&self) -> ValueSet {
        Box::new(self.clone())
    }
}
