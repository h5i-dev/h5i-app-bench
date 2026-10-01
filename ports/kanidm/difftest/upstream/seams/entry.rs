
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
