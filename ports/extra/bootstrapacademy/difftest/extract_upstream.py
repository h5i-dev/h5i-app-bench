"""Copy Bootstrap Academy's service code verbatim from the pinned commit into
src/upstream/<crate>/. Each crate becomes a module (lib.rs is mod.rs). Only
these lines change:

- `use academy_*`, `use tracing::`, `use uuid::` gain a `crate::upstream::`
  prefix, and `use crate::` becomes `use super::` (`use self::` in mod.rs);
- `pub mod x;` of files not copied is dropped;
- the `#[trace_instrument(..)]` and mockall attributes, the `Build` derive and
  `#[cfg_attr(test, derive(Default))]` are dropped (no logic);
- test modules and `#[cfg(feature = "mock")]` sections are cut;
- the fields of the `*Impl` service structs become `pub`, so the test can
  wire the services (upstream does it with the `Build` derive).

Two small pieces of academy_models logic are copied the same way into
src/upstream/models_verbatim.rs.

The models, repositories, cache and shared services they use are stubbed in
src/upstream/mod.rs.

  python3 extract_upstream.py <Bootstrap-Academy_backend checkout>
"""
import re, subprocess, sys
from pathlib import Path

COMMIT = "fbe5e60"
HERE = Path(__file__).parent
OUT = HERE / "src/upstream"

# crate module -> (source dir, files). The first file is the crate root.
CRATES = {
    "academy_auth_contracts": ("academy_auth/contracts/src", ["lib.rs", "access_token.rs", "refresh_token.rs"]),
    "academy_auth_impl": ("academy_auth/impl/src", ["lib.rs", "access_token.rs", "refresh_token.rs"]),
    "academy_cache_contracts": ("academy_cache/contracts/src", ["lib.rs"]),
    "academy_shared_contracts": ("academy_shared/contracts/src",
                                 ["time.rs", "id.rs", "hash.rs", "secret.rs", "totp.rs", "captcha.rs",
                                  "password.rs", "jwt.rs"]),
    "academy_core_session_contracts": ("academy_core/session/contracts/src",
                                       ["lib.rs", "failed_auth_count.rs", "login_throttle.rs", "session.rs"]),
    "academy_core_session_impl": ("academy_core/session/impl/src",
                                  ["lib.rs", "failed_auth_count.rs", "login_throttle.rs", "session.rs"]),
    "academy_core_mfa_contracts": ("academy_core/mfa/contracts/src",
                                   ["lib.rs", "authenticate.rs", "disable.rs", "recovery.rs", "totp_device.rs"]),
    "academy_core_mfa_impl": ("academy_core/mfa/impl/src",
                              ["lib.rs", "authenticate.rs", "disable.rs", "recovery.rs", "totp_device.rs"]),
    "academy_core_coin_contracts": ("academy_core/coin/contracts/src", ["lib.rs", "coin.rs"]),
    "academy_core_coin_impl": ("academy_core/coin/impl/src", ["lib.rs", "coin.rs"]),
    "academy_core_heart_contracts": ("academy_core/heart/contracts/src", ["lib.rs", "heart.rs"]),
    "academy_core_heart_impl": ("academy_core/heart/impl/src", ["lib.rs", "heart.rs"]),
    "academy_core_withdrawal_contracts": ("academy_core/withdrawal/contracts/src", ["consent.rs"]),
    "academy_core_withdrawal_impl": ("academy_core/withdrawal/impl/src", ["consent.rs"]),
}


def show(repo, path):
    return subprocess.run(["git", "-C", repo, "show", f"{COMMIT}:{path}"],
                          capture_output=True, text=True, check=True).stdout


def drop_attr(src, start):
    """Remove every attribute starting with `start`, with balanced brackets."""
    out, i = [], 0
    while True:
        j = src.find(start, i)
        if j < 0:
            return "".join(out) + src[i:]
        # the attribute's line, from its indentation
        k = src.rfind("\n", 0, j) + 1
        depth, m = 0, j + 1
        while True:
            c = src[m]
            depth += {"[": 1, "(": 1, "]": -1, ")": -1}.get(c, 0)
            m += 1
            if depth == 0:
                break
        if src[m] == "\n":
            m += 1
        out.append(src[i:k])
        i = m


def transform(src, root, files):
    for cut in ("#[cfg(test)]\nmod tests {", "#[cfg(feature = \"mock\")]"):
        k = src.find(cut)
        if k >= 0:
            src = src[:k].rstrip() + "\n"
    src = src.replace("#[cfg(test)]\nmod tests;\n", "")
    src = drop_attr(src, "#[trace_instrument")
    src = drop_attr(src, "#[cfg_attr(feature = \"mock\"")
    src = drop_attr(src, "#[cfg_attr(test, derive(Default))]")
    src = re.sub(r"#\[derive\(([^)]*)\)\]",
                 lambda m: "#[derive(" + ", ".join(x.strip() for x in m.group(1).split(",")
                                                   if x.strip() and x.strip() != "Build") + ")]", src)
    src = re.sub(r"^(\s*)use (academy_|tracing::|uuid::)", r"\1use crate::upstream::\2", src, flags=re.M)
    src = re.sub(r"^(\s*)use crate::(?!upstream)", r"\1use " + ("self::" if root else "super::"), src, flags=re.M)
    src = re.sub(r"(pub struct \w+Impl<[^>]*> \{\n)(.*?)(\n\})",
                 lambda m: m.group(1) + re.sub(r"^    (\w+):", r"    pub \1:", m.group(2), flags=re.M) + m.group(3),
                 src, flags=re.S)
    if root:
        keep = {f[:-3] for f in files}
        src = re.sub(r"^pub mod (\w+);\n", lambda m: m.group(0) if m.group(1) in keep else "", src, flags=re.M)
    return src


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


def main(repo):
    head = f"// Copied from Bootstrap-Academy/backend @ {COMMIT} by extract_upstream.py. Do not edit.\n"
    for krate, (d, files) in CRATES.items():
        out = OUT / krate
        out.mkdir(parents=True, exist_ok=True)
        if files[0] != "lib.rs":
            # Only some modules of this crate: a generated root.
            (out / "mod.rs").write_text(head + "".join(f"pub mod {f[:-3]};\n" for f in files))
        for f in files:
            root = f == "lib.rs"
            text = transform(show(repo, f"{d}/{f}"), root, files)
            # `academy_models::user::UserComposite` is named by path once.
            (out / ("mod.rs" if root else f)).write_text(
                head + "#[allow(unused_imports)]\nuse crate::upstream::academy_models;\n" + text)
    u = show(repo, "academy_models/src/user.rs")
    w = show(repo, "academy_models/src/withdrawal.rs")
    const = re.search(r"^pub const WITHDRAWAL_TEXT_VERSION: &str = .*;\n", w, re.M).group(0)
    (OUT / "models_verbatim.rs").write_text(
        head + "use super::academy_models::{user::*, withdrawal::*};\n\n" + item(u, r"impl UserIdOrSelf\b") + "\n" +
        const + "\n" + item(w, r"impl WithdrawalConsentDeclaration\b"))


if __name__ == "__main__":
    main(sys.argv[1])
