"""Build the `nora-upstream` crate in upstream/ from nora's own sources at the
pinned commit. Whole files are copied up to their test modules, so `crate::`
paths resolve as in nora; only what the authorization code does not need is
replaced: `config`, `metrics`, the JWT half of `auth/oidc.rs` and `AppState`
are stubs in upstream/stubs/. Test seams that seed and read private state are
appended from upstream/seams/.

  python3 extract_upstream.py <nora checkout>
"""
import re, shutil, subprocess, sys
from pathlib import Path

COMMIT = "f864a9a"
HERE = Path(__file__).parent
OUT = HERE / "upstream/src"
STUBS = HERE / "upstream/stubs"
HEAD = f"// Copied from getnora-io/nora @ {COMMIT} by extract_upstream.py. Do not edit.\n"


def show(repo, path):
    return subprocess.run(["git", "-C", repo, "show", f"{COMMIT}:nora-registry/src/{path}"],
                          capture_output=True, text=True, check=True).stdout


def before_tests(src):
    """The file up to its first `#[cfg(test)]` item."""
    i = src.find("\n#[cfg(test)]")
    return src if i < 0 else src[:i + 1]


def item(src, header):
    """The item starting at the line matching `header`, through its closing brace."""
    m = re.search(rf"^[ \t]*(?:(?:///.*|#\[.*\])\n[ \t]*)*{header}", src, re.M)
    if not m:
        raise SystemExit(f"not found: {header}")
    i = src.index("{", m.end() - 1 if src[m.end() - 1] == "{" else m.end())
    depth = 0
    for j in range(i, len(src)):
        depth += {"{": 1, "}": -1}.get(src[j], 0)
        if depth == 0:
            return src[m.start():j + 1] + "\n"
    raise SystemExit(f"unbalanced: {header}")


def between(src, start, end):
    a = src.index(start)
    return src[a:src.index(end, a) + len(end)]


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def main(repo):
    if OUT.exists():
        shutil.rmtree(OUT)

    for f in ("tokens.rs", "validation.rs", "auth/htpasswd.rs", "auth/namespace.rs"):
        write(OUT / f, HEAD + before_tests(show(repo, f)))

    m = before_tests(show(repo, "auth/mod.rs"))
    # Token routes are HTTP handlers for managing tokens, not authorization.
    m = m.replace("mod token_routes;\n", "").replace(
        "pub use token_routes::{token_routes, TokenListItem, TokenListResponse};\n", "")
    write(OUT / "auth/mod.rs", HEAD + m)

    o = show(repo, "auth/oidc.rs")
    frag = between(o, "        // Enforce token lifetime ceiling",
                   "namespace_scope_enforcement: provider.namespace_scope_enforcement,\n        })")
    write(OUT / "auth/oidc/oidc_upstream.rs",
          HEAD + "use super::*;\nuse crate::tokens::Role;\n\n" + item(o, r"fn glob_match\b") +
          item(o, r"pub fn classify_rejection\b") +
          "\nimpl OidcValidator {\n" + item(o, r"fn match_role\b") + "\n"
          "    /// The claims half of `validate_token`, verbatim.\n"
          "    pub fn validate_claims(&self, provider: &OidcProvider, claims: Claims)"
          " -> Result<OidcIdentity, String> {\n" + frag + "\n    }\n}\n")

    c = show(repo, "config/auth.rs")
    write(OUT / "config_upstream.rs", HEAD + "".join(
        item(c, h) for h in (r"pub struct TrustedProxies\b", r"impl TrustedProxies\b",
                             r"pub enum ScopeEnforcement\b")))

    for s in STUBS.glob("**/*.rs"):
        write(OUT / s.relative_to(STUBS), s.read_text())
    # Seams go after the copied text, never inside it.
    for s in (HERE / "upstream/seams").glob("**/*.rs"):
        f = OUT / s.relative_to(HERE / "upstream/seams")
        f.write_text(f.read_text() + s.read_text())


if __name__ == "__main__":
    main(sys.argv[1])
