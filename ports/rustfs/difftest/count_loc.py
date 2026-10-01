"""Lines of rustfs's `crates/policy` the kernel ports, cut from the pinned
commit and counted without blank lines, comments and attributes.

  python3 count_loc.py <rustfs checkout>
"""
import re, subprocess, sys

COMMIT = "e870a6d"
BASE = "crates/policy/src/policy/"
PORTED = {
    "utils/wildcard.rs": [r"pub fn is_simple_match\b", r"pub fn is_match<", r"fn inner_match\b", r"fn deep_match\b"],
    "utils/path.rs": [r"struct LazyBuf\b", r"impl<'a> LazyBuf<'a>", r"pub fn clean\b"],
    "variables.rs": [r"impl VariableResolver \{", r"impl PolicyVariableResolver for VariableResolver\b",
                     r"pub async fn resolve_aws_variables\b", r"async fn resolve_single_pass\b"],
    "action.rs": [r"pub fn is_match_for_effect\(&self, action: &Action, deny: bool\) -> bool \{\n        for",
                  r"pub fn statement_covers\b", r"impl Action \{\n    pub fn is_match\b", r"fn action_requires_explicit_grant\b",
                  r"pub\(crate\) fn is_table_resource_scoped\b"],
    "resource.rs": [r"pub async fn is_match_with_resolver\(\n        &self,\n        resource: &str,\n        conditions: &HashMap<String, Vec<String>>,\n        resolver: Option<&dyn PolicyVariableResolver>,\n    \) -> bool \{\n        for",
                    r"pub async fn is_match_with_resolver\(\n        &self,\n        resource: &str,\n        conditions: &HashMap<String, Vec<String>>,\n        resolver: Option<&dyn PolicyVariableResolver>,\n    \) -> bool \{\n        let pattern",
                    r"pub fn is_kms\b"],
    "function.rs": [r"pub async fn evaluate_with_resolver\b", r"pub fn references_key_name\b"],
    "function/condition.rs": [r"pub fn has_any_key_in\b", r"pub fn references_key_name\b", r"pub fn evaluate_with_resolver\b",
                              r"pub fn is_negate\b"],
    "function/string.rs": [r"impl StringFunc \{", r"impl FuncKeyValue<StringFuncValue> \{"],
    "function/bool_null.rs": [r"impl BoolFunc \{"],
    "function/number.rs": [r"impl NumberFunc \{"],
    "function/addr.rs": [r"impl AddrFunc \{"],
    "function/key.rs": [r"pub fn name\(&self\) -> String\b"],
    "function/key_name.rs": [r"pub const COMMON_KEYS\b", r"pub const fn prefix\b", r"pub fn name\(&self\) -> &str\b",
                             r"pub fn var_name\b"],
    "statement.rs": [r"pub\(crate\) fn variable_resolver_for_policy_args\b", r"fn build_resource\b",
                     r"fn skips_resource_match_for_args\b", r"fn is_kms\(&self\)", r"fn is_admin\(&self\)",
                     r"fn is_sts\(&self\)", r"async fn kms_key_scope_matches\b",
                     r"pub\(crate\) async fn request_reaches_condition_eval\(&self, args: &Args",
                     r"pub async fn is_allowed\(&self, args: &Args",
                     r"pub\(crate\) async fn request_reaches_condition_eval\(&self, args: &BucketPolicyArgs",
                     r"pub async fn is_allowed\(&self, args: &BucketPolicyArgs"],
    "principal.rs": [r"pub fn is_match\b"],
    "effect.rs": [r"pub fn is_allowed\b"],
    "policy.rs": [r"pub async fn is_allowed\(&self, args: &Args", r"pub async fn is_allowed\(&self, args: &BucketPolicyArgs"],
}


def show(repo, path):
    return subprocess.run(["git", "-C", repo, "show", f"{COMMIT}:{BASE}{path}"],
                          capture_output=True, text=True, check=True).stdout


def item(src, header):
    """From the line matching `header` through the closing brace of its first
    `{` (or the `;` of a const)."""
    m = re.search(header, src, re.M)
    if not m:
        raise SystemExit(f"not found: {header}")
    start = src.rfind("\n", 0, m.start()) + 1
    j = m.start()
    while src[j] not in "{;" or (src[j] == ";" and "{" not in src[m.start():j] and "[" in src[m.start():j]
                                  and src[m.start():j].count("[") > src[m.start():j].count("]")):
        j += 1
    if src[j] == ";":
        return src[start:j + 1]
    depth, k = 0, j
    while k < len(src):
        c = src[k]
        if c == '"':  # skip a string literal
            k += 1
            while src[k] != '"':
                k += 2 if src[k] == "\\" else 1
        elif c == "'" and re.match(r"'(\\.|[^\\'])'", src[k:k + 4]):  # a char literal
            k = src.index("'", k + 2 if src[k + 1] == "\\" else k + 1)
        elif c in "{}":
            depth += 1 if c == "{" else -1
            if depth == 0:
                return src[start:k + 1]
        k += 1
    raise SystemExit(f"unbalanced: {header}")


def code(text):
    n = 0
    for line in text.splitlines():
        s = line.strip()
        if s and not s.startswith("//") and not s.startswith("#["):
            n += 1
    return n


def main(repo):
    total = 0
    for f, heads in PORTED.items():
        src = show(repo, f)
        test = src.find("#[cfg(test)]\nmod tests")
        src = src if test < 0 else src[:test]
        n = sum(code(item(src, h)) for h in heads)
        print(f"{n:5}  {f}")
        total += n
    print(f"{total:5}  total")


if __name__ == "__main__":
    main(sys.argv[1])
