//! Stub `metrics`.
pub struct Counter;
impl Counter {
    pub fn with_label_values(&self, _: &[&str]) -> &Self {
        self
    }
    pub fn inc(&self) {}
}
pub static NAMESPACE_SCOPE_DECISIONS: Counter = Counter;
pub fn record_oidc_rejection(_: &str) {}
