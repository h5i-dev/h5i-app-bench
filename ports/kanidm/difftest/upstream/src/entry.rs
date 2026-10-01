// Stub of `entry.rs`: the entry states carry only what the access module
// reads. `Entry`, `EntryReduced`, the `Clone` impl and the methods below the
// stubs are copied.
use crate::filter::{Filter, FilterResolved, FilterValidResolved};
use crate::prelude::*;
use crate::server::access::AccessEffectivePermission;
use std::collections::BTreeMap as Map;

pub type Eattrs = Map<Attribute, ValueSet>;

#[derive(Clone, Debug)]
pub struct EntryInit;
#[derive(Clone, Debug)]
pub struct EntryNew;
#[derive(Clone, Debug)]
pub struct EntryCommitted;
#[derive(Clone, Debug)]
pub struct EntrySealed {
    uuid: Uuid,
}

pub type EntryInitNew = Entry<EntryInit, EntryNew>;
pub type EntrySealedCommitted = Entry<EntrySealed, EntryCommitted>;
pub type EntryReducedCommitted = Entry<EntryReduced, EntryCommitted>;

impl<VALID, STATE> Entry<VALID, STATE> {
    // Stub: only logs read it.
    pub(crate) fn get_display_id(&self) -> String {
        String::new()
    }
}

// Copied from kanidm/kanidm @ f608c4f by extract_upstream.py. Do not edit.
#[derive(Clone, Debug)]
pub struct EntryReduced {
    uuid: Uuid,
    effective_access: Option<Box<AccessEffectivePermission>>,
}

/// Entry is the core data storage type of the server. Almost every aspect of the server is
/// designed to read, handle and manipulate entries.
///
/// Entries store attribute value assertions, or AVA. These are sets of key-values.
///
/// Entries have a lifecycle within a single operation, and as part of replication.
/// The lifecycle for operations is defined through state and valid types. Each entry has a pair
/// Of these types at anytime. The first is the AVA [`schema`] and [`access`] control assertion
/// state. This is represented by the type `VALID` as one of `EntryValid`, `EntryInvalid` or
/// `EntryReduced`. Every entry starts as `EntryInvalid`, and when checked by the schema for
/// correctness, transitions to `EntryValid`. While an entry is `EntryValid` it can not be
/// altered - you must invalidate it to `EntryInvalid`, then modify, then check again.
/// An entry that has had access controls applied moves from `EntryValid` to `EntryReduced`,
/// to show that the AVAs have reduced to the valid read set of the current [`event`] user.
///
/// The second type of `STATE` represents the database commit state and internal db ID's. A
/// new entry that has never been committed is `EntryNew`, but an entry that has been retrieved
/// from the database is `EntryCommitted`. This affects the operations you can apply IE modify
/// or delete.
///
/// These types exist to prevent at compile time, mishandling of Entries, to ensure they are always
/// handled with the correct lifecycles and processes.
///
/// [`schema`]: ../schema/index.html
/// [`access`]: ../access/index.html
/// [`event`]: ../event/index.html
pub struct Entry<VALID, STATE> {
    valid: VALID,
    state: STATE,
    // We may need to change this to Set to allow borrow of Value -> PartialValue for lookups.
    attrs: Eattrs,
}

impl<VALID, STATE> Clone for Entry<VALID, STATE>
where
    VALID: Clone,
    STATE: Clone,
{
    // Dirty modifiable state. Works on any other state to dirty them.
    fn clone(&self) -> Entry<VALID, STATE> {
        Entry {
            valid: self.valid.clone(),
            state: self.state.clone(),
            attrs: self.attrs.clone(),
        }
    }
}

impl<VALID, STATE> std::fmt::Debug for Entry<VALID, STATE>
where
    STATE: std::fmt::Debug,
    VALID: std::fmt::Debug,
{
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        f.debug_struct("Entry<EntrySealed, _>")
            .field("state", &self.state)
            .field("valid", &self.valid)
            .field("attrs", &self.attrs)
            .finish()
    }
}

impl<STATE> Entry<EntryInit, STATE>
where
    STATE: Clone,
{
    /// Get the uuid of this entry.
    pub fn get_uuid(&self) -> Option<Uuid> {
        self.attrs
            .get(&Attribute::Uuid)
            .and_then(|vs| vs.to_uuid_single())
    }
}

impl Entry<EntrySealed, EntryCommitted> {
    /// Given a set of attributes that are allowed to be seen on this entry, process and remove
    /// all other values that are NOT allowed in this query.
    pub fn reduce_attributes(
        &self,
        allowed_attrs: &BTreeSet<Attribute>,
        effective_access: Option<Box<AccessEffectivePermission>>,
    ) -> Entry<EntryReduced, EntryCommitted> {
        // Remove all attrs from our tree that are NOT in the allowed set.
        let f_attrs: Map<_, _> = self
            .attrs
            .iter()
            .filter_map(|(k, v)| {
                if allowed_attrs.contains(k) {
                    Some((k.clone(), v.clone()))
                } else {
                    None
                }
            })
            .collect();

        let valid = EntryReduced {
            uuid: self.valid.uuid,
            effective_access,
        };
        let state = self.state.clone();

        Entry {
            valid,
            state,
            attrs: f_attrs,
        }
    }
}

impl<STATE> Entry<EntrySealed, STATE> {
    pub fn get_uuid(&self) -> Uuid {
        self.valid.uuid
    }
}

impl<VALID, STATE> Entry<VALID, STATE> {
    pub fn attr_keys(&self) -> impl Iterator<Item = &Attribute> {
        self.attrs.keys()
    }

    /// Get an iterator over the current set of attribute names that this entry contains.
    pub fn get_ava_names(&self) -> impl Iterator<Item = &str> {
        // Get the set of all attribute names in the entry
        self.attrs.keys().map(|a| a.as_str())
    }

    /// Return a reference to the current set of values that are associated to this attribute.
    pub fn get_ava_set<A: AsRef<Attribute>>(&self, attr: A) -> Option<&ValueSet> {
        self.attrs.get(attr.as_ref())
    }

    pub fn get_ava_refer<A: AsRef<Attribute>>(&self, attr: A) -> Option<&BTreeSet<Uuid>> {
        self.get_ava_set(attr).and_then(|vs| vs.as_refer_set())
    }

    pub fn get_ava_as_iutf8<A: AsRef<Attribute>>(&self, attr: A) -> Option<&BTreeSet<String>> {
        self.get_ava_set(attr).and_then(|vs| vs.as_iutf8_set())
    }

    pub fn get_ava_as_oauthscopemaps<A: AsRef<Attribute>>(
        &self,
        attr: A,
    ) -> Option<&std::collections::BTreeMap<Uuid, std::collections::BTreeSet<String>>> {
        self.get_ava_set(attr).and_then(|vs| vs.as_oauthscopemap())
    }

    /// If possible, return an iterator over the set of values transformed into a `&str`.
    pub fn get_ava_iter_iutf8<A: AsRef<Attribute>>(
        &self,
        attr: A,
    ) -> Option<impl Iterator<Item = &str>> {
        self.get_ava_set(attr).and_then(|vs| vs.as_iutf8_iter())
    }

    pub fn get_ava_single_refer<A: AsRef<Attribute>>(&self, attr: A) -> Option<Uuid> {
        self.get_ava_set(attr).and_then(|vs| vs.to_refer_single())
    }

    /// Assert if an attribute of this name is present on this entry.
    pub fn attribute_pres<A: AsRef<Attribute>>(&self, attr: A) -> bool {
        self.attrs.contains_key(attr.as_ref())
    }

    /// Assert if an attribute of this name is present, and one of its values contains
    /// an exact match of this partial value.
    pub fn attribute_equality<A: AsRef<Attribute>>(&self, attr: A, value: &PartialValue) -> bool {
        // we assume based on schema normalisation on the way in
        // that the equality here of the raw values MUST be correct.
        // We also normalise filters, to ensure that their values are
        // syntax valid and will correctly match here with our indexes.
        match self.attrs.get(attr.as_ref()) {
            Some(v_list) => v_list.contains(value),
            None => false,
        }
    }

    /// Assert if an attribute of this name is present, and one of it's values contains
    /// the following substring, if possible to perform the substring comparison.
    pub fn attribute_substring<A: AsRef<Attribute>>(
        &self,
        attr: A,
        subvalue: &PartialValue,
    ) -> bool {
        self.get_ava_set(attr)
            .map(|vset| vset.substring(subvalue))
            .unwrap_or(false)
    }

    /// Assert if an attribute of this name is present, and one of its values startswith
    /// the following string, if possible to perform the comparison.
    pub fn attribute_startswith<A: AsRef<Attribute>>(
        &self,
        attr: A,
        subvalue: &PartialValue,
    ) -> bool {
        self.get_ava_set(attr)
            .map(|vset| vset.startswith(subvalue))
            .unwrap_or(false)
    }

    /// Assert if an attribute of this name is present, and one of its values startswith
    /// the following string, if possible to perform the comparison.
    pub fn attribute_endswith<A: AsRef<Attribute>>(
        &self,
        attr: A,
        subvalue: &PartialValue,
    ) -> bool {
        self.get_ava_set(attr)
            .map(|vset| vset.endswith(subvalue))
            .unwrap_or(false)
    }

    /// Assert if an attribute of this name is present, and one of its values is less than
    /// the following partial value
    pub fn attribute_lessthan<A: AsRef<Attribute>>(
        &self,
        attr: A,
        subvalue: &PartialValue,
    ) -> bool {
        self.get_ava_set(attr)
            .map(|vset| vset.lessthan(subvalue))
            .unwrap_or(false)
    }

    #[inline(always)]
    #[instrument(level = "trace", name = "entry::entry_match_no_index", skip(self))]
    /// Test if the following filter applies to and matches this entry.
    pub fn entry_match_no_index(&self, filter: &Filter<FilterValidResolved>) -> bool {
        self.entry_match_no_index_inner(filter.to_inner())
    }

    fn entry_match_no_index_inner(&self, filter: &FilterResolved) -> bool {
        // Go through the filter components and check them in the entry.
        // This is recursive!!!!
        match filter {
            FilterResolved::Eq(attr, value, _) => self.attribute_equality(attr, value),
            FilterResolved::Cnt(attr, subvalue, _) => self.attribute_substring(attr, subvalue),
            FilterResolved::Stw(attr, subvalue, _) => self.attribute_startswith(attr, subvalue),
            FilterResolved::Enw(attr, subvalue, _) => self.attribute_endswith(attr, subvalue),
            FilterResolved::Pres(attr, _) => self.attribute_pres(attr),
            FilterResolved::LessThan(attr, subvalue, _) => self.attribute_lessthan(attr, subvalue),
            // Check with ftweedal about or filter zero len correctness.
            FilterResolved::Or(l, _) => l.iter().any(|f| self.entry_match_no_index_inner(f)),
            // Check with ftweedal about and filter zero len correctness.
            FilterResolved::And(l, _) => l.iter().all(|f| self.entry_match_no_index_inner(f)),
            FilterResolved::Inclusion(_, _) => {
                // An inclusion doesn't make sense on an entry in isolation!
                // Inclusions are part of exists queries, on search they mean
                // nothing!
                false
            }
            FilterResolved::AndNot(f, _) => !self.entry_match_no_index_inner(f),
            FilterResolved::Invalid(_) => false,
        }
    }
}

// ---- Test seam (not upstream): build entries and read reduced ones. ----

impl Entry<EntrySealed, EntryCommitted> {
    pub fn difftest_new(uuid: Uuid, attrs: Eattrs) -> Self {
        Entry {
            valid: EntrySealed { uuid },
            state: EntryCommitted,
            attrs,
        }
    }
}

impl Entry<EntryInit, EntryNew> {
    pub fn difftest_new(attrs: Eattrs) -> Self {
        Entry {
            valid: EntryInit,
            state: EntryNew,
            attrs,
        }
    }
}

impl Entry<EntryReduced, EntryCommitted> {
    pub fn difftest_parts(&self) -> (Uuid, &Eattrs, Option<&AccessEffectivePermission>) {
        (
            self.valid.uuid,
            &self.attrs,
            self.valid.effective_access.as_deref(),
        )
    }
}
