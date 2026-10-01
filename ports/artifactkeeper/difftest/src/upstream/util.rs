pub mod bounded_archive {
    use std::future::Future;
    use uuid::Uuid;

    pub enum TenantKey {
        Repo(Uuid),
        Unattributed,
    }

    /// Stub: the per-tenant decode budget does not affect the decision.
    pub async fn run_with_tenant_scope<F: Future>(_key: TenantKey, fut: F) -> F::Output {
        fut.await
    }
}
