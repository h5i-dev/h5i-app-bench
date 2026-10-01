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
