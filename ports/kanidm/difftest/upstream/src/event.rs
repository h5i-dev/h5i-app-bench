// Stub of `event.rs`: the event structs below are copied.
use crate::filter::{Filter, FilterValid};
use crate::prelude::*;

// Copied from kanidm/kanidm @ f608c4f by extract_upstream.py. Do not edit.
#[derive(Debug)]
pub struct SearchEvent {
    pub ident: Identity,
    // This is the filter as we apply and process it.
    pub filter: Filter<FilterValid>,
    // This is the original filter, for the purpose of ACI checking.
    pub filter_orig: Filter<FilterValid>,
    pub attrs: Option<BTreeSet<Attribute>>,
    pub effective_access_check: bool,
}

#[derive(Debug)]
pub struct CreateEvent {
    pub ident: Identity,
    // This may still actually change to handle the *raw* nature of the
    // input that we plan to parse.
    pub entries: Vec<Entry<EntryInit, EntryNew>>,
    // Is the CreateEvent from an internal or external source?
    // This may affect which plugins are run ...
    /// If true, the list of created entry UUID's will be returned.
    pub return_created_uuids: bool,
}

#[derive(Debug)]
pub struct DeleteEvent {
    pub ident: Identity,
    // This is the filter, as it will be processed.
    pub filter: Filter<FilterValid>,
    // This is the original filter, for the purpose of ACI checking.
    pub filter_orig: Filter<FilterValid>,
}

#[derive(Debug)]
pub struct ModifyEvent {
    pub ident: Identity,
    // This is the filter, as it will be processed.
    pub filter: Filter<FilterValid>,
    // This is the original filter, for the purpose of ACI checking.
    pub filter_orig: Filter<FilterValid>,
    pub modlist: ModifyList<ModifyValid>,
}
