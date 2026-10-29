use smol_str::SmolStr;
#[derive(Debug,Clone,PartialEq,Eq)]
pub enum LiveRole {
    /// The account exists and is active. Carries the caller's *current*
    /// role string (`"admin"` / `"user"`), which is authoritative and
    /// supersedes the — possibly stale — JWT `role` claim. `SmolStr` so the
    /// per-request render of the (≤23-byte) role never heap-allocates.
    Active(SmolStr),
    /// The account is deactivated or deleted: the request must be rejected
    /// even though its token is still cryptographically valid.
    Revoked,
}
