# synctv: status

**Theorem classes: S = 27, C = 9, F = 1** (37 theorems in `[check] theorems`).
Upstream pinned at `38970e0215753a034de6b6659be577fd7e0479c2`. Threat model, ported code
and deviations are in DEVIATIONS.md; findings are in FINDINGS.md.

## Theorems

Classes: **S** is a security property, stated independently of the implementation and
falsifiable by a plausible bug. **C** is a correspondence lemma: kernel = Spec,
totality or an exact constant. **F** is a finding. "Killed by" names a mutant from
`h5i-app.toml` under which the S statement is false, not just its proof. The
counterexample is given in brief.

| Theorem | Class | Statement (informal) | Killed by (counterexample) |
|---|---|---|---|
| `has_correct` | C | `has` tests exactly the permission's bit; total | — |
| `effective_permissions_correct` | C | `effective_permissions` = `Spec.effective`; total | — |
| `role_default_correct` | C | `role_default` = `Spec.roleDefault`; total | — |
| `calculator_correct` | C | `calculator_has_permission` = `Spec.calcHas`; total | — |
| `guest_confined` | S | a guest never holds anything but the 4 guest-assignable permissions, whatever defaults, settings and overrides say | `settings_guest_unmasked` (server guest default with `DeleteRoom` → guest holds it) |
| `guest_effective_confined` | S | same for `effective_permissions` with any role default | `guest_base_unmasked` |
| `member_overrides_confined` | S | a member's own override columns cannot add or remove non-member-assignable permissions | `member_uses_admin_map` (added bit 6 → `DeleteMedia`), `member_p2p_maps_to_delete_media` |
| `member_default_confined` | S | room settings cannot add or remove non-member-assignable permissions from the member default | `member_p2p_maps_to_delete_media` (settings bit 6 → `DeleteMedia`) |
| `admin_ignores_plain_columns` | S | an admin's permissions do not depend on the plain override columns | `admin_reads_plain_columns` |
| `non_admin_ignores_admin_columns` | S | a member's or guest's permissions do not depend on the admin override columns | `member_reads_admin_columns` |
| `removed_never_held` | S | deny wins: a permission removed in the member's own role bitspace is never held | `member_deny_ignored` |
| `creator_holds_all` | C | the creator holds every permission (availability, not a restriction) | `creator_gets_admin_default` |
| `calculator_precheck_redundant` | F | the own-override pre-check of `has_permission` never changes the answer (FINDINGS F2) | — (makes `calculator_skips_own_override_check` an equivalent mutant) |
| `default_admin_spec` | C | the compiled admin default is everything except `DeleteRoom` | `admin_default_includes_delete_room` |
| `default_guest_empty` | S | with the compiled default a guest gets nothing unless explicitly added | `guest_default_nonzero` |
| `default_member_spec` | C | the compiled member default is exactly the member-assignable set | — |
| `admin_delete_room_needs_explicit_grant` | S | with compiled defaults an admin can delete the room only if room settings or their row add `DeleteRoom` | `admin_default_includes_delete_room` |
| `member_delete_room_only_from_server_default` | S | a plain member holds `DeleteRoom` only via the server-wide member default | `member_uses_admin_map` (added bit 18) |
| `creator_role_never_assignable` | S | the creator role can never be assigned | `creator_role_assignable` |
| `only_creator_admits_admins` | S | only the creator admits members as admin; nobody admits a creator | `admin_grant_by_anyone` |
| `role_change_only_by_creator` | S | an accepted role change comes from the creator, does not target the creator, does not confer creator | `role_update_by_non_creator`, `role_update_may_target_creator` |
| `overrides_stay_in_role_space` | S | accepted override bits lie in the bitspace of the member's new role; admin columns in the admin space | `plan_skips_role_space_check`, `plan_skips_admin_bits_check` |
| `override_channel_matches_role` | S | admins change only via admin columns, others only via plain columns; every permission update requires `ManageMemberPermissions` | `channel_admin_check_dropped`, `plan_uses_current_role` (promote to admin with plain columns) |
| `update_needs_existing_member` | S | no update is planned for a non-member | `plan_ignores_missing_member` |
| `kick_cooldown_bounded` | S | an accepted kick cooldown is in (0 s, 30 days] | `kick_cooldown_zero_allowed` |
| `can_manage_eq` | C | `can_manage` = `Spec.manages` | — |
| `manage_needs_higher_role` | S | only root manages root or admins; users manage nobody | `admin_manages_admin` |
| `manager_is_admin_or_above` | S | whoever manages another account is admin or root | `user_manages_user` |
| `banned_cannot_login` | S | banned accounts cannot log in / create / join | `banned_is_active` |
| `expiration_correct` | C | `validate_expiration` = `Spec.notExpired` (saturating), only `Authentication` errors | — |
| `expired_token_rejected` | S | an accepted token satisfies `now ≤ exp + leeway` | `leeway_always_max` (every token accepted forever) |
| `zero_leeway_strict` | S | with zero leeway, rejected from `exp + 1` | `expiry_off_by_one` |
| `token_type_enforced` | S | a token is accepted only as the requested type (refresh ≠ access) | `token_type_unchecked` |
| `guest_revocation_effective` | S | a guest token older than the room's guest version is rejected | `guest_version_unchecked` |
| `guest_access_requires` | S | guests enter only with guest mode on server-wide (fail closed without settings), allowed by the room, and no room password | `guest_password_room_allowed`, `guest_settings_fail_open` |
| `bearer_token_after_scheme` | S | an accepted `Authorization` value starts with `Bearer ` (any case) and the token is a non-empty range after it | `bearer_empty_token_accepted`, `bearer_scheme_unchecked` |
| `pipeline_accepts_only_valid` | S | `SecurityPipeline::check` accepts only existing, non-deleted, non-banned users with matching password version, 2FA when required, non-revoked JTI; blacklist outage fails closed | `pipeline_skips_password_version`, `pipeline_blacklist_fail_open`, `pipeline_skips_two_factor` |

Helper lemmas (bit tables, validators, loop-free specs) are in `proofs/Lemmas.lean`. They
are gated by `h5i app check` but not listed and not counted.

## Mutation (`h5i app mutate ports/synctv`)

- Run 1 (31 hand-written mutants, `-j2`): **31/31 caught, 0 survived, 0 invalid**.
- Run 2 (`--only member_reads_admin_columns --only user_manages_user --only banned_is_active`,
  added so that every S theorem has a semantic killer): **3/3 caught**.
- Total: 34 mutants, all caught. Every S theorem in the table has at least one
  mutant under which its statement is false.

- **Equivalent mutant:** `calculator_skips_own_override_check` is reported as
  "caught", but only because the proof of `calculator_correct` follows the code's
  structure. Its statement still holds under the mutant (see
  `calculator_precheck_redundant`). No S theorem can or should kill it.

## Gate results

- `h5i app doctor ports/synctv`: 0 failed, 0 warnings.
- `h5i app extract --check ports/synctv`: extraction is up to date.
- `h5i app check ports/synctv`: proofs ok. The gate checked 442 theorems in 3 modules
  against propext, Classical.choice and Quot.sound. No sorry, no extra axioms, no
  native_decide.
- `h5i app lint ports/synctv`: **lint ok** when run without the `upstream-src` symlink.
  With the symlink present, lint walks the linked upstream checkout and reports 347
  axum routes of synctv itself. Those routes are outside this kernel.
  **Harness proposal:** `h5i app lint` should skip gitignored paths, or at least
  `upstream-src/`.
- `cargo test` in `difftest/` (`SQLX_OFFLINE=true`): 13 passed.

## Coverage

All functions in the DEVIATIONS.md table are ported, difftested (except the three
transcribed decisions noted there) and covered by C theorems with full specs. Not ported:
the async service layer (repositories, caches, outbox), room password hashing and
verification (crypto), WebSocket tickets, publish keys, rate limiting, OAuth2/OIDC, and
the `models/user.rs` `User` methods (lines 373-398).

## Resume

- Iterate on proofs with `cd proofs && lake build`. `Lemmas.lean` takes about 4 minutes
  because of the bit tables.
- Difftest: `cd difftest && SQLX_OFFLINE=true cargo test`. This needs the `upstream-src`
  symlink to `/mnt/scratch/oss-sec/upstream/synctv` at the pinned commit.
- Next candidates: room password / join decisions (`service/room/join.rs`,
  `password.rs`), `User::can_create_room(allow_user)` (`models/user.rs:385`), kick
  authorization (who may kick whom), and a byte-level Lean proof for
  `extract_bearer_token`.
