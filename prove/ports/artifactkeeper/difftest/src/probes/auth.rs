//! Private items of `api/middleware/auth.rs` for the tests.
use super::*;

pub(crate) fn percent_decode_path_segment(s: &str) -> Option<String> {
    super::percent_decode_path_segment(s).map(|c| c.into_owned())
}
pub(crate) fn is_nuget_push_path(p: &str) -> bool {
    super::is_nuget_push_path(p)
}
pub(crate) fn is_non_mutating_format_post(p: &str) -> bool {
    super::is_non_mutating_format_post(p)
}
pub(crate) fn is_anonymous_readable_format_post(p: &str) -> bool {
    super::is_anonymous_readable_format_post(p)
}
pub(crate) fn path_exempt_from_password_change(p: &str) -> bool {
    super::path_exempt_from_password_change(p)
}
pub(crate) fn ticket_path_allowed(bound: Option<&str>, p: &str) -> bool {
    super::ticket_path_allowed(bound, p)
}
pub(crate) fn violates_csrf_contract(m: &Method, h: &HeaderMap) -> bool {
    super::violates_csrf_contract(m, h)
}
pub(crate) fn has_header_credential(h: &HeaderMap) -> bool {
    super::has_header_credential(h)
}
pub(crate) fn declares_same_origin(h: &HeaderMap) -> bool {
    super::declares_same_origin(h)
}
pub(crate) fn decode_basic_credentials(e: &str) -> Option<(String, String)> {
    super::decode_basic_credentials(e)
}
/// `extract_visibility_token`, owning the credential text.
pub(crate) fn visibility_token(r: &Request) -> (u8, Option<String>) {
    match super::extract_visibility_token(r) {
        ExtractedToken::Bearer(t) => (0, Some(t.to_string())),
        ExtractedToken::ApiKey(t) => (1, Some(t.to_string())),
        ExtractedToken::Basic(t) => (2, Some(t.to_string())),
        ExtractedToken::None => (3, None),
        ExtractedToken::Invalid => (4, None),
    }
}
pub(crate) fn with_scope_gated_admin(e: AuthExtension) -> AuthExtension {
    e.with_scope_gated_admin()
}
