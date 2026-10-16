// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
/// True when `path` is on the OCI distribution surface (`/v2` or `/v2/...`),
/// where any JSON 4XX body must be the spec's error envelope.
pub(crate) fn is_oci_v2_path(path: &str) -> bool {
    path == "/v2" || path == "/v2/" || path.starts_with("/v2/")
}
