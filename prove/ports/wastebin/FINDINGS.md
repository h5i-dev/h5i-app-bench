# wastebin: findings

Upstream matze/wastebin @ `c0ec9687ba41e8806654f34841e9a739f0264ced`. Line numbers refer to that
commit. No upstream issues were filed. Severities are our judgement for a public pastebin; none of
these breaks confidentiality of paste *content*.

## F1. Metadata of expired pastes stays readable (low)

**Theorems:** `qr_shows_title_of_expired_paste`, `burn_interstitial_shows_title_of_expired_paste`.

`Handler::get_metadata` (`crates/wastebin_core/src/db.rs:489`) selects `uid, title, expires,
burn_after_reading` without checking `expires < datetime('now')`; only `Handler::get`
(`db.rs:511-514`, used by `Database::get` at `db.rs:648`) checks expiry and deletes the row.
Two handlers answer from metadata alone:

- `/qr/{id}` (`crates/wastebin_server/src/handlers/html/qr.rs:42`) renders the title, the owner's
  delete button state and the page for any row still in the table;
- `/{id}` and `/md/{id}` for a burn-after-reading paste (`handlers/html/paste.rs:102-104`,
  `handlers/html/rendered.rs:60-62`) show the burn interstitial with the title before
  `Database::get` notices the expiry.

Expired rows are removed only when a full read hits them or an operator runs
`wastebin-ctl purge` (`crates/wastebin_ctl/src/main.rs:264`); the server never purges on its own.
So an expired paste's title (user-chosen, stored unencrypted even for password-protected pastes)
and the fact that it existed remain visible indefinitely to anyone who has the URL.

- Exploitability: needs the paste id (64-bit random); reveals title only, never content.
- Reachable: yes, unauthenticated HTTP `GET /qr/{id}`; `GET /{id}` for burn pastes.
- Fix idea: filter `expires` in `get_metadata` (or return `NotFound` for expired rows there).

## F2. Magic-link handoff fixes the owner identity of a cookie-less browser (low)

**Theorem:** `magic_link_fixes_owner_of_fresh_browser` (with `handoff_adds_only_claimed`,
`form_owner_first_or_fresh`, `delete_needs_owner`).

`/{id}?owner=<token>` (`handlers/html/paste.rs:78-91`) appends the token's uid to the browser's
signed `uid` cookie and redirects. The form insert (`handlers/insert/form.rs:79-88`) uses the
cookie's *first* uid as the owner of every new paste. A browser without a `uid` cookie that opens
an attacker's magic link therefore gets the cookie `[attacker_uid]`, and all pastes it creates
afterwards through the form are owned by the attacker's uid. The attacker, holding the token (or a
cookie listing that uid), can delete them (`delete::api::delete`, `delete::form::delete`). The
cookie is `SameSite=Lax` (`handlers/mod.rs:49`), so it is set on a top-level navigation from
another site.

- Exploitability: the attacker must get the victim to open a link before the victim's first paste
  in that browser, and must learn the victim's paste ids to delete them (ids are random; they leak
  when the victim shares the URL). Impact is deletion (integrity/availability), not reading.
- Reachable: yes, HTTP.
- Fix idea: keep a freshly minted primary uid first and append claimed uids after it, or never
  use a claimed uid as the owner of new pastes.

## F3. Paste ids are not canonical: several URLs name the same paste (info)

**Evidence:** differential test `difftest/src/ids_tests.rs::decode_aliases_upstream` (testing
evidence, not a Lean theorem); the kernel reproduces it (`decode_agrees`).

`Id::from_str` (`crates/wastebin_core/src/id.rs:105-140`) ors the last character's six bits into a
value shifted by only two (`id.rs:113`, six-character ids) or four bits (`id.rs:132`,
eleven-character ids). `aaaaba` and `aaaaae` decode to the same `Id32(4)`; and because
`Id::to_i64` maps `Id32(n)` and `Id64(n)` to the same primary key, `aaaaab` and `aaaaaaaaaab` reach
the same row. No access decision depends on the URL spelling (the cache and the database key on
the decoded id), so this is not exploitable; it only defeats URL-based deny lists.

## F4. Configured expiration choices are not enforced (info, not proved)

Observed while reading, not modeled in the kernel. `WASTEBIN_PASTE_EXPIRATIONS`
(`crates/wastebin_server/src/env.rs:155`) only fills the form's drop-down. The JSON API accepts any
`expires` (`handlers/insert/api.rs:17`, `:44`) or none, and the form turns an unparsable value into
"never expires" (`handlers/insert/form.rs:33-35`). An operator who removes "never" from the list
does not stop clients from creating non-expiring pastes.
