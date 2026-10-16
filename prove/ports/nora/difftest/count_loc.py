"""Lines of upstream code the kernel ports: each item is cut from the pinned
commit and counted without blank lines, comments and attributes.

  python3 count_loc.py <nora checkout>
"""
import re, sys
from extract_upstream import item, show

PORTED = {
    "auth/mod.rs": [r"pub struct AuthFailureTracker\b", r"impl AuthFailureTracker\b", r"fn is_public_path\b",
                    r"fn is_web_surface\b", r"fn is_docker_path\b", r"fn is_admin_path\b",
                    r"pub\(crate\) fn resolve_client_ip\b", r"fn extract_client_ip\b",
                    r"async fn anonymous_read_passthrough\b", r"pub async fn auth_middleware\b",
                    r"fn try_basic_auth\b"],
    "auth/namespace.rs": [r"pub enum NamespaceAuthority\b", r"impl NamespaceAuthority\b",
                          r"pub fn enforce_namespace_scope\b"],
    "auth/oidc.rs": [r"fn glob_match\b", r"fn match_role\b"],
    "auth/htpasswd.rs": [r"pub fn authenticate\b"],
    "config/auth.rs": [r"pub struct TrustedProxies\b", r"pub fn contains\b"],
    "tokens.rs": [r"pub enum Role\b", r"impl Role\b", r"pub fn verify_token\b", r"pub struct TokenInfo\b",
                  r"fn invalidate_cache\b", r"pub fn revoke_token\b", r"pub fn revoke_all_for_user\b",
                  r"fn is_valid_hash_prefix\b"],
    "validation.rs": [r"pub fn ends_with_ci\b", r"pub fn validate_storage_key\b", r"pub fn validate_docker_name\b",
                      r"pub fn validate_digest\b", r"pub fn validate_docker_reference\b", r"pub fn namespace_match\b",
                      r"fn segments_match\b", r"fn segment_glob\b"],
}
# The claims half of `validate_token` is ported, not the JWT half.
FRAGMENTS = {"auth/oidc.rs": ("        // Enforce token lifetime ceiling",
                              "namespace_scope_enforcement: provider.namespace_scope_enforcement,\n        })")}


def code(text):
    n, depth = 0, 0
    for line in text.splitlines():
        s = line.strip()
        if depth or s.startswith("/*"):
            depth = 0 if "*/" in s else 1
            continue
        if s and not s.startswith("//") and not s.startswith("#["):
            n += 1
    return n


def main(repo):
    total = 0
    for f, heads in PORTED.items():
        src = show(repo, f)
        n = sum(code(item(src, h)) for h in heads)
        if f in FRAGMENTS:
            a, b = FRAGMENTS[f]
            i = src.index(a)
            n += code(src[i:src.index(b, i) + len(b)])
        print(f"{n:5}  {f}")
        total += n
    print(f"{total:5}  total")


if __name__ == "__main__":
    main(sys.argv[1])
