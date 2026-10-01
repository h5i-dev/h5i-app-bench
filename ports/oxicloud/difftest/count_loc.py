"""Lines of OxiCloud's access control the kernel ports, cut from the pinned
commit and counted without blank lines, comments and attributes.

  python3 count_loc.py <OxiCloud checkout>
"""
import re, subprocess, sys

COMMIT = "8c0dd33"
BASE = "src/"
ACL = "infrastructure/services/pg_acl_engine.rs"
PORTED = {
    "domain/services/authorization.rs": [r"pub fn expand\(self\)", r"pub fn roles_implying\b"],
    "application/ports/authorization_ports.rs": [r"async fn require\(\n"],
    ACL: [r"async fn expand_user\b", r"async fn subject_match_set\b", r"async fn drive_of\b",
          r"fn roles_implying_strings\b", r"async fn direct_grant_exists\b", r"async fn folder_cascade_grant_exists\b",
          r"async fn file_direct_grant_exists\b", r"async fn query_parent_point\b", r"async fn direct_grant_cached\b",
          r"async fn cascade_grant_cached\b", r"async fn caller_role_on_drive_cached\b", r"async fn drive_policies_cached\b",
          r"fn read_only_gate_applies\b", r"pub async fn find_grant_full_by_id\b", r"async fn check_inner\b",
          r"async fn revoke\(&self", r"async fn set_role\(\n", r"async fn clear_role\b"],
    "infrastructure/repositories/pg/subject_group_pg_repository.rs": [r"async fn groups_for_user\b"],
    "infrastructure/repositories/pg/folder_db_repository.rs": [r"pub async fn get_folder_drive_id\b"],
    "infrastructure/repositories/pg/file_blob_read_repository.rs": [r"pub async fn get_file_drive_id\b"],
    "infrastructure/repositories/pg/drive_pg_repository.rs": [r"async fn get_policies_for_file\b", r"async fn get_policies_for_folder\b"],
    "domain/entities/drive.rs": [r"pub fn refuse_public_links\b", r"pub fn refuse_sharing\b", r"pub fn refuse_owner_role_change\b",
                                 r"pub fn refuse_external_sharing\b"],
    "application/services/drive_management_service.rs": [r"pub async fn set_member_role\b", r"pub async fn remove_member\b",
        r"async fn refuse_if_personal\b", r"async fn refuse_if_forbid_external_sharing\b",
        r"async fn refuse_if_forbid_owner_role_change\b", r"async fn refuse_if_last_owner_change\b"],
    "interfaces/api/handlers/grant_handler.rs": [r"pub async fn create_grant\b", r"pub async fn revoke_grant\b",
                                                 r"pub async fn set_role\b"],
}
# Not ported: the e-mail invitation branch of create_grant and the message-bus
# publish after revoke_grant.
SKIP = [("        SubjectInputDto::Email { email } => {", "        }\n    };"),
        ("    if let Subject::User(target_user) = subject {", "\n    }\n")]


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


def strip(text):
    """Drop `tracing::*!(..);` calls and the unported branches."""
    for a, b in SKIP:
        i = text.find(a)
        if i >= 0:
            text = text[:i] + text[text.index(b, i) + len(b):]
    while (i := text.find("tracing::")) >= 0:
        j = text.index("(", i)
        depth, k = 0, j
        while True:
            depth += {"(": 1, ")": -1}.get(text[k], 0)
            if depth == 0:
                break
            k += 1
        end = text.find(";", k)
        text = text[:i] + text[end + 1:]
    return text


def code(text):
    return sum(1 for line in strip(text).splitlines()
               if line.strip() and not line.strip().startswith(("//", "#[")))


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
