# windmill findings (pinned 9dedc42b4ece1fbceae7d695ec51a508caa49710)

No upstream issues were filed.

## W1. Wildcard scope boundary check mixes characters and bytes (low)

- **Where:** `backend/windmill-common/src/scopes.rs:212-243` (`resource_matches_pattern`,
  closure `matches_wildcard`), line
  `resource.chars().nth(prefix.len()) == Some('/')`.
- **What:** `prefix.len()` is a byte length, but `chars().nth` takes a character index.
  When the wildcard prefix contains a multi-byte character, the check reads a
  character past the real boundary. A scope `scripts:read:f/team/dé/*` then grants
  `scripts:read:f/team/déx/y`, a path outside the `dé` subtree.
- **Evidence:**
  - Lean theorem `Properties.wildcard_unicode_crosses_boundary` (class F) proves
    that the kernel, a faithful port of this code, returns `true` for
    `f/dé/*` vs `f/déx/y` while `¬ names "f/dé/*" "f/déx/y"`.
  - Difftest `unicode_prefix_crosses_folder_boundary` shows the same on upstream:
    `ScopeDefinition::includes` returns `true`.
  - For ASCII resources the property holds (`wildcard_ascii_boundary`, class S).
- **Reachability:** Folder names are ASCII-only (`VALID_FOLDER_NAME = ^[a-zA-Z_0-9-]+$`,
  `windmill-api-groups/src/folders.rs:261`), so a grant cannot cross from one folder into
  another. Path segments below the folder may be Unicode, though:
  `PROPER_CHAR = \p{Alphabetic}\p{Nd}_-`, `windmill-common/src/utils.rs:251`. So can a
  user-namespace segment, if usernames allow non-ASCII letters (not checked here).
  A sub-path wildcard such as `f/team/dé/*` therefore also grants sibling sub-paths
  whose name extends `dé` by one more character (`déx/...`), within the same folder.
- **Severity:** low. The over-grant needs a token scoped to a non-ASCII sub-path
  prefix, and it stays inside the same folder or user namespace. The fix is to
  compare bytes (`resource.as_bytes().get(prefix.len()) == Some(&b'/')`), as
  `resource_covers` (line 544) already does.

## W2. Scope matching changes semantics at more than 4 resources; delegation is then not monotone (low)

- **Where:** `backend/windmill-common/src/scopes.rs:162-210`. `resources_match` uses
  `resources_match_small`, which matches symmetrically (a wildcard on either side),
  when both lists have at most 4 entries. Otherwise it uses `resources_match_large`,
  which matches wildcards only on the scope side.
- **What:** Whether a token grants a requirement depends on how many resources the
  token lists. A requirement with a wildcard path (`scripts:read:f/a/*`) is granted by
  the token `scripts:read:f/a/x` (1 entry). It is not granted by
  `scripts:read:f/a/x,f/b/1,f/b/2,f/b/3,f/b/4` (5 entries), even though the second
  token strictly contains the first. As a result `scope_contains` (line 490), the
  minting check, can accept a minted token that satisfies a requirement its minter
  does not satisfy. Delegation is not monotone.
- **Evidence:** difftest `delegation_not_monotone_across_size_split`, run against
  upstream. There is no Lean theorem: the counterexample needs a full spec of
  `resources_match`, which is still open (see STATUS).
- **Reachability:** A requirement carries a wildcard only if the required scope string
  contains `*` in its resource part. `check_scopes` builds required scopes from
  request path parameters (for example `jobs:run:scripts:{script_path}`), so a caller
  can put `*` or `,` into the requirement. `check_proper_path` forbids both in stored
  paths, so such a request then targets an item that cannot exist. No route was found
  where the widened match lets the caller reach a real item.
- **Severity:** low (consistency / defence in depth). The fix is to use one matcher for
  both sizes.

## Observations

- `get_perm_in_extra_perms_for_authed` (`windmill-api-auth/src/lib.rs:1348`) grants if
  any of the user or group keys is `true`. `windmill_common::auth::check_extra_perms`
  (`windmill-common/src/auth.rs:235`) gives the user key precedence, so a user `false`
  overrides a group `true`. The two helpers disagree on that input. This is not
  analysed further; the second function is not ported.
- `check_scopes` treats a scope list made only of `if_jobs:filter_tags:` entries as
  unscoped (full user rights), as its comments document.
