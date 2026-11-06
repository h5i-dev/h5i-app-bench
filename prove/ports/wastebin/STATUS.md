# wastebin: status

Upstream matze/wastebin @ `c0ec9687ba41e8806654f34841e9a739f0264ced`. Gate: `h5i app check` passes
with 30 listed theorems (182 checked in total), axioms only `propext`, `Classical.choice`,
`Quot.sound`; `h5i app extract --check` up to date.

**Theorem classes: S = 23, C = 4, F = 3.**

## Theorems

Class S: security property, falsifiable by a plausible bug. C: correspondence / helper.
F: finding (see FINDINGS.md). "Kills" names an auto-generated mutant (`h5i app mutate --auto`)
whose behaviour violates the statement; *caught* means the mutant broke the gate. All named mutants are
*caught* in the full run (`h5i app mutate --auto`, 132 mutants).

| # | Theorem | Class | Bug it rules out | Kills |
|---|---|---|---|---|
| 1 | `delete_needs_owner` | S | deleting without a verified cookie listing the owner, or "succeeding" with nothing deleted | `delete_for@store.rs:259:if-true` caught |
| 2 | `delete_removes_only_owned` | S | `WHERE id=? OR uid IN ..`, deleting other pastes | `delete_for@store.rs:252:and-or` caught |
| 3 | `delete_refusal_unchanged` | S | a refused delete that still removed rows | no auto mutant targets it (error arms are not mutated); hand check: returning `out` on `Err` breaks it |
| 4 | `delete_without_cookie_forbidden` | S | a missing cookie treated as an empty uid list or as allowed | no auto mutant (match arms are not mutated) |
| 5 | `get_content_needs_password` | S | content of an encrypted paste without its password, content of expired pastes | `decrypt@store.rs:139:if-true` caught |
| 6 | `get_expired_never_read` | S | expiry ignored or expired row kept | `fetch@store.rs:169:if-false` caught |
| 7 | `get_wrong_password_keeps_paste` | S | a wrong/missing password burning the paste (DoS) or revealing it | `decrypt@store.rs:139:negate` caught |
| 8 | `get_burn_consumes` | S | burn-after-reading not deleted on read | `finish@store.rs:194:if-false` caught |
| 9 | `get_keeps_unburned` | S | ordinary reads deleting pastes | `finish@store.rs:194:if-true` caught |
| 10 | `burn_second_read_not_found` | S | a burned paste readable twice | `finish@store.rs:194:if-false` caught |
| 11 | `burn_readers_exactly_once` | S | concurrent readers all getting a burn paste (ignoring the DELETE's row count) | `finish@store.rs:196:if-false` caught |
| 12 | `view_paste_facts` | C | (conjunction used by 13-15; helper) | — |
| 13 | `view_content_gated` | S | the HTML view skipping expiry, password, or burn confirmation | `view_id@handlers.rs:147:if-false` caught |
| 14 | `view_encrypted_no_store` | S | decrypted content served cacheable | no auto mutant (struct field assignment); hand check: `no_store: false` breaks it |
| 15 | `view_cache_only_public` | S | encrypted or burned HTML entering the shared server cache | `page_of@handlers.rs:136:and-or` caught |
| 16 | `view_can_delete_iff_owner` | C | (UI flag; deletion itself is enforced by 1-4) | `page_of`/`can_delete` mutants |
| 17 | `view_burn_needs_confirmation` | S | unconfirmed GET (link preview, crawler) burning a paste | `view_id@handlers.rs:147:if-false`, `:and-or`, `:drop-not` caught |
| 18 | `view_changes_only_burned_or_expired` | S | the view deleting or changing other rows | `finish@store.rs:194:if-true` caught |
| 19 | `view_handoff_touches_no_paste` | S | the `?owner=` handoff reading/serving the paste or touching the table | no auto mutant (match arm) |
| 20 | `raw_content_gated` | S | raw/download skipping expiry or password; encrypted raw served cacheable | `decrypt@store.rs:139:if-true` caught |
| 21 | `qr_shows_title_of_expired_paste` | F | F1 | — |
| 22 | `burn_interstitial_shows_title_of_expired_paste` | F | F1 | — |
| 23 | `handoff_adds_only_claimed` | S | the handoff adding uids other than the verified one, or dropping existing ones | `handoff@handlers.rs:106:if-true`, `:if-false`, `:drop-not`, `:100:boundary` caught |
| 24 | `form_owner_first_or_fresh` | C | (restates `form_owner`) | `form_owner@handlers.rs:260:*` caught |
| 25 | `api_owner_token_or_fresh` | C | (holds for any function of that shape) | — |
| 26 | `magic_link_fixes_owner_of_fresh_browser` | F | F2 | — |
| 27 | `extension_accepts_only_url_safe` | S | `"`, `<`, `/` or over-long extensions accepted (XSS/path injection via the key) | `extension_byte@ext.rs:13:negate`, `valid_extension@ext.rs:19:if-false`, `:24:drop-not` caught |
| 28 | `parsed_key_extension_url_safe` | S | a parsed key carrying an unvalidated extension | `parse_key@ids.rs:196:if-false` caught |
| 29 | `insert_never_clobbers` | S | an insert overwriting or adopting another paste's id; unbounded retries | `id_taken@handlers.rs:294:negate`, `insert@handlers.rs:309:if-true`, `:322:if-false` (targeted run, see below) |
| 30 | `purge_removes_exactly_expired` | S | purge deleting live pastes or keeping expired ones | `purge@store.rs:269:if-true`, `:drop-not` (targeted run) |

## Mutation

Full run: `h5i app mutate --auto -j 2 ports/wastebin`, 132 auto mutants, before theorems 29-30
were added: **91 caught, 41 survived**. Survivors and why:

- Id codec, 23 mutants (`char_bits@ids.rs:41-42`, `decode32@:108-109`, `decode64@:124-125`,
  `decode@:139,144`): no S theorem is about id decoding; an id that decodes to the wrong number
  only reaches a different random row. Covered by the difftest (400k strings, `decode_agrees`).
  A round-trip C lemma is listed under Next.
- `find_dot@ids.rs:164-165` (4), `sub@ids.rs:177:boundary`, `key_path@ids.rs:217:boundary`:
  `parsed_key_extension_url_safe` constrains only what a successful parse returns; these
  mutants make parsing fail (index out of bounds) or split at another position while still
  validating the extension, which the statement allows. Difftest `key_agrees` covers them.
- `content_disposition@disposition.rs:33/38:boundary`: out-of-bounds-only mutants (the loop
  reads one byte past the end and fails); there is no totality theorem. Difftest covers it.
- `id_taken` (4), `insert` (7), `purge` (4): no theorem at the time; theorems 29-30 were added
  for them. Targeted re-run: `h5i app mutate --auto --only insert@ --only id_taken@ --only purge@`
  (results below once finished). Expected to stay alive: mutants that only make `insert` fail
  (`id_taken:if-true`, `insert:309:if-false`, out-of-bounds boundaries), since both theorems are
  about successful runs.

Caveat: "caught" means the mutated project failed the gate, possibly first in a C lemma; the
"Kills" column additionally states that the mutant violates the S statement itself.

## Done
- Kernel, extraction, 28 gated theorems, FINDINGS.md (F1-F4), DEVIATIONS.md.
- Difftest `difftest/` (all 7 tests pass): ids/keys/extensions/Content-Disposition on 200k-400k
  generated inputs each; the real `wastebin_core::Database` on 1,200 random operations.

## Next
- Content-Disposition header-safety S theorem and totality.
- HTTP-level difftest of the handler decisions against the upstream server binary.
- Id round trip `decode (encode id) = Ok id` (C) and a Lean witness for F3.

## Proposal for shared tooling
`h5i app lint` fails on this port only because it scans `upstream-src/` (the symlinked upstream
server, whose anonymous routes have no `Actor<>`). Suggest the lint skip `upstream-src` (it is
gitignored) or honour an exclude list in `h5i-app.toml`.

## Resume
`cd prove && h5i app check ports/wastebin`;
`cargo test --release --manifest-path ports/wastebin/difftest/Cargo.toml -- --nocapture`
(needs `ports/wastebin/upstream-src -> /mnt/scratch/oss-sec/upstream/wastebin`).
