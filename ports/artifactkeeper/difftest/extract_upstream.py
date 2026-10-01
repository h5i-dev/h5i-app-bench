"""Copy artifact-keeper's authorization code verbatim from the pinned commit
into src/upstream/. Whole files are copied up to their test module; single
items are copied with their doc comments and wrapped only where noted. Files
under src/upstream that this script does not write are hand-written stubs.

Changes to the copied text: `use` lines at the top of item copies, and one
appended `mod probe` line (under `#[cfg(test)]`) that gives the tests access
to private functions.

  python3 extract_upstream.py <artifact-keeper checkout>
"""
import re, subprocess, sys
from pathlib import Path

COMMIT = "7c42891"
HERE = Path(__file__).parent
OUT = HERE / "src/upstream"
HEAD = f"// Copied from artifact-keeper/artifact-keeper @ {COMMIT} by extract_upstream.py. Do not edit.\n"


def show(repo, path):
    return subprocess.run(["git", "-C", repo, "show", f"{COMMIT}:backend/src/{path}"],
                          capture_output=True, text=True, check=True).stdout


def item(src, header):
    """The item starting at the line matching `header`, with its doc comments
    and one-line attributes, through its closing brace or semicolon."""
    m = re.search(rf"^[ \t]*(?:(?:///.*|#\[.*\])\n[ \t]*)*{header}", src, re.M)
    if not m:
        raise SystemExit(f"not found: {header}")
    h = re.compile(header).search(src, m.start())
    depth = 0
    for j in range(h.start(), len(src)):
        c = src[j]
        if c in "{[(":
            depth += 1
        elif c in "}])":
            depth -= 1
            if depth == 0 and c == "}":
                return src[m.start():j + 1] + "\n"
        elif c == ";" and depth == 0:
            return src[m.start():j + 1] + "\n"
    raise SystemExit(f"unbalanced: {header}")


def upto_tests(src):
    """The file up to the attributes of its `mod tests`."""
    i = src.index("\nmod tests {")
    lines = src[:i].split("\n")
    while lines and (lines[-1].startswith("#[") or lines[-1].startswith("//")):
        lines.pop()
    return "\n".join(lines).rstrip() + "\n"


def probe(name):
    return (f"\n// Appended by extract_upstream.py: private items for the tests.\n"
            f"#[cfg(test)]\n#[path = \"{name}\"]\npub(crate) mod probe;\n")


def write(rel, text):
    p = OUT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text)


def main(repo):
    # Whole files.
    write("api/middleware/auth.rs", HEAD + upto_tests(show(repo, "api/middleware/auth.rs"))
          + probe("../../../probes/auth.rs"))
    write("api/middleware/client_ip.rs", HEAD + upto_tests(show(repo, "api/middleware/client_ip.rs")))
    write("api/middleware/guest_access.rs", HEAD + upto_tests(show(repo, "api/middleware/guest_access.rs")))
    write("services/permission_service.rs", HEAD + upto_tests(show(repo, "services/permission_service.rs")))
    write("models/access_scope.rs", HEAD + upto_tests(show(repo, "models/access_scope.rs")))

    # Items.
    rl = show(repo, "api/middleware/rate_limit.rs")
    write("api/middleware/rate_limit.rs", HEAD + "use std::net::IpAddr;\n\n" + "".join(
        item(rl, h) for h in (r"pub struct CidrRange\b", r"impl CidrRange\b", r"fn first_xff_token_in\b",
                              r"fn normalize_xff_token\b", r"fn rightmost_untrusted_xff_token\b",
                              r"pub\(crate\) fn resolve_client_ip_addr\b")))

    oe = show(repo, "api/middleware/oci_errors.rs")
    write("api/middleware/oci_errors_copied.rs", HEAD + item(oe, r"pub\(crate\) fn is_oci_v2_path\b"))

    ts = show(repo, "services/token_service.rs")
    write("services/token_service.rs", HEAD + "".join(
        item(ts, h) for h in (r"pub\(crate\) const ALLOWED_SCOPES\b", r"pub\(crate\) fn validate_scopes_pure\b",
                              r"pub\(crate\) const ADMIN_ONLY_SCOPES\b", r"pub\(crate\) fn enforce_admin_only_scopes\b",
                              r"pub\(crate\) fn scopes_grant_access\b")))

    acs = show(repo, "services/auth_config_service.rs")
    write("services/auth_config_service.rs", HEAD +
          "use sqlx::PgPool;\nuse uuid::Uuid;\n\nuse crate::error::{AppError, Result};\n\n"
          "pub struct AuthConfigService;\n\nimpl AuthConfigService {\n"
          + item(acs, r"pub async fn validate_download_ticket\b") + "}\n")

    auth = show(repo, "services/auth_service.rs")
    write("services/auth_service_claims.rs", HEAD + item(auth, r"impl Claims\b"))

    perms = show(repo, "api/handlers/permissions.rs")
    write("api/handlers/permissions.rs", HEAD +
          "use serde::Deserialize;\nuse utoipa::ToSchema;\nuse uuid::Uuid;\n\n"
          "use crate::api::middleware::auth::AuthExtension;\nuse crate::error::{AppError, Result};\n\n"
          + "".join(item(perms, h) for h in (r"fn require_auth\b", r"pub struct CreatePermissionRequest\b",
                                             r"fn validate_anonymous_rule\b"))
          + probe("../../../probes/permissions.rs"))

    api = show(repo, "api/mod.rs")
    write("api/repo_cache.rs", HEAD + "".join(
        item(api, h) for h in (r"pub const REPO_CACHE_TTL_SECS\b", r"pub struct CachedRepo\b",
                               r"pub type RepoCache\b", r"pub type RepoMissCache\b",
                               r"pub const REPO_MISS_CACHE_MAX_ENTRIES\b")))

    err = show(repo, "error.rs")
    write("error_copied.rs", HEAD + item(err, r"pub\(crate\) fn is_pool_timeout\(msg") +
          "\nimpl AppError {\n" + item(err, r"pub\(crate\) fn is_pool_timeout\(&self") + "}\n")

    rep = show(repo, "models/repository.rs")
    write("models/repository_copied.rs", HEAD + item(rep, r"impl RepositoryVisibility\b"))


if __name__ == "__main__":
    main(sys.argv[1])
