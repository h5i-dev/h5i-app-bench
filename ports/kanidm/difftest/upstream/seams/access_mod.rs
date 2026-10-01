
// ---- Test seam (not upstream): a transaction over given profiles. ----

pub struct DifftestAccessControls {
    inner: AccessControlsInner,
}

impl DifftestAccessControls {
    pub fn new(
        acps_search: Vec<AccessControlSearch>,
        acps_create: Vec<AccessControlCreate>,
        acps_modify: Vec<AccessControlModify>,
        acps_delete: Vec<AccessControlDelete>,
        sync_agreements: Vec<(Uuid, BTreeSet<Attribute>)>,
    ) -> Self {
        let sync_agreements: HashMap<Uuid, BTreeSet<Attribute>> = sync_agreements.into_iter().collect();
        DifftestAccessControls {
            inner: AccessControlsInner {
                acps_search,
                acps_create,
                acps_modify,
                acps_delete,
                sync_agreements,
            },
        }
    }
}

impl<'a> AccessControlsTransaction<'a> for DifftestAccessControls {
    fn get_search(&self) -> &Vec<AccessControlSearch> {
        &self.inner.acps_search
    }

    fn get_create(&self) -> &Vec<AccessControlCreate> {
        &self.inner.acps_create
    }

    fn get_modify(&self) -> &Vec<AccessControlModify> {
        &self.inner.acps_modify
    }

    fn get_delete(&self) -> &Vec<AccessControlDelete> {
        &self.inner.acps_delete
    }

    fn get_sync_agreements(&self) -> &HashMap<Uuid, BTreeSet<Attribute>> {
        &self.inner.sync_agreements
    }

    fn get_acp_resolve_filter_cache(&self) -> &mut ResolveFilterCacheReadTxn<'a> {
        Box::leak(Box::default())
    }
}
