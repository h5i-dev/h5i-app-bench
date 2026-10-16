// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
/// The canonical list of allowed API token scopes.
pub(crate) const ALLOWED_SCOPES: &[&str] = &[
    "read:artifacts",
    "write:artifacts",
    "delete:artifacts",
    "promote:artifacts",
    "read:repositories",
    "write:repositories",
    "delete:repositories",
    "read:users",
    "write:users",
    "trigger:sync",
    // #3411: ingest security findings from an out-of-tree scanner. Dedicated
    // rather than folded into `write:artifacts`, because a credential that may
    // publish packages must not thereby be able to write the verdicts the
    // download gate, the promotion gate and the repository score read.
    "write:findings",
    "admin",
    "*",
];
/// Validate token scopes against the allowed scope list.
/// Returns Ok(()) if all scopes are valid, Err(message) otherwise.
pub(crate) fn validate_scopes_pure(scopes: &[String]) -> std::result::Result<(), String> {
    for scope in scopes {
        if !ALLOWED_SCOPES.contains(&scope.as_str()) {
            return Err(format!(
                "Invalid scope: '{}'. Allowed scopes: {:?}",
                scope, ALLOWED_SCOPES
            ));
        }
    }
    Ok(())
}
/// Scopes that grant elevated, admin-class capabilities and may not be
/// embedded in a token issued by a non-admin caller. The restriction is
/// purely on token issuance — a non-admin can still hold such a token if
/// an admin minted it for them.
///
/// Includes:
///   * `admin`, `*` — short-circuit any scope check via
///     [`scopes_grant_access`]. A non-admin minting one of these would
///     have a token that satisfies every scope-only authorization gate
///     (anywhere the request is API-token-authenticated and the
///     authorization decision rests solely on the token's scope set).
///   * `delete:artifacts`, `delete:repositories` — destructive
///     scope-gated operations.
///   * `promote:artifacts` — promotes artifacts across repositories and
///     is a privileged release-management capability; only an admin may
///     mint a token that carries it (the holder still passes the tenant
///     and approval gates at promote time).
///   * `write:users` — user-management write capability.
///   * `write:findings` — writes security verdicts that the download gate,
///     promotion gates and the repository score all read (#3411); a non-admin
///     minting one could suppress or manufacture a block.
///   * `trigger:sync` — triggers an upstream curation/RPM metadata sync for a
///     repository (#2357); privileged because it drives outbound fetches and
///     mutates the synced catalog, so only an admin may mint a token that
///     carries it (the holder still passes the per-repo tenant gate).
///
/// `write:artifacts` and `write:repositories` are deliberately NOT on
/// this list: artifact publishing is a routine non-admin action and
/// repository creation is sometimes delegated to non-admin users via
/// permission grants. If your deployment wants to lock those down,
/// add them in a follow-up alongside a configurable policy knob.
pub(crate) const ADMIN_ONLY_SCOPES: &[&str] = &[
    "admin",
    "*",
    "delete:artifacts",
    "delete:repositories",
    "promote:artifacts",
    "trigger:sync",
    "write:users",
    "write:findings",
];
/// Enforce that a non-admin caller may not grant any admin-class scope
/// from [`ADMIN_ONLY_SCOPES`] to a token.
///
/// Returns `Ok(())` when the caller is admin, or when none of the
/// requested scopes are admin-class. Otherwise returns `Err` naming the
/// first admin-class scope encountered so the caller can produce an
/// actionable error message.
pub(crate) fn enforce_admin_only_scopes(
    scopes: &[String],
    caller_is_admin: bool,
) -> std::result::Result<(), String> {
    if caller_is_admin {
        return Ok(());
    }
    for scope in scopes {
        if ADMIN_ONLY_SCOPES.contains(&scope.as_str()) {
            return Err(format!(
                "Scope '{}' is admin-only and cannot be granted by a non-admin caller. \
                 Admin-only scopes: {:?}",
                scope, ADMIN_ONLY_SCOPES,
            ));
        }
    }
    Ok(())
}
/// Check if a set of scopes grants access for a required scope.
///
/// A held scope satisfies the requirement iff one of:
///   * it is the exact required scope (`write:artifacts` -> `write:artifacts`),
///   * it is `*` or `admin` (wildcard short-circuit),
///   * the required scope is colon-form (`action:resource`) and the held scope
///     is its bare action parent — a broad `write` covers the specific
///     `write:artifacts` (#2989).
///
/// The direction is deliberately broad-covers-specific ONLY. A held
/// colon-form scope never satisfies a bare requirement and never satisfies a
/// colon-form requirement for a *different* resource: `write:artifacts` does
/// NOT satisfy bare `write` (which still gates non-artifact writes such as
/// repository settings) and does NOT satisfy `write:repositories`. Widening
/// either of those directions would let a least-privilege resource token cross
/// into other resources.
pub(crate) fn scopes_grant_access(scopes: &[String], required_scope: &str) -> bool {
    // `*` / `admin` wildcard policy, in the #1316-canonical form (the
    // `check-no-legacy-admin-scope.sh` gate forbids `.any(...)` closures that
    // compare against "admin" and `== "*"` / `== "admin"` on one line).
    let has_admin_wildcard =
        scopes.iter().any(|s| s == "*") || scopes.contains(&"admin".to_string());
    if scopes.iter().any(|s| s == required_scope) || has_admin_wildcard {
        return true;
    }
    // Bare-parent satisfaction: held `write` covers required `write:artifacts`.
    match required_scope.split_once(':') {
        Some((parent, _resource)) => !parent.is_empty() && scopes.iter().any(|s| s == parent),
        None => false,
    }
}
