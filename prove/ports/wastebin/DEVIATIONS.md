# wastebin: what the kernel covers and where it differs

Upstream: matze/wastebin @ `c0ec9687ba41e8806654f34841e9a739f0264ced` (2026-10-20), crates
`wastebin_core` and `wastebin_server`. The checkout is linked as `upstream-src` (gitignored); the
difftest's `build.rs` reads files with `git show <rev>:<path>`, so a moved checkout cannot change
what is tested.

## Threat model

wastebin is an anonymous pastebin. There are no accounts; the security-relevant decisions are:

| Asset / decision | Attacker | Upstream mechanism |
|---|---|---|
| Content of a password-protected paste | anyone with the URL | XChaCha20-Poly1305 under an argon2 key; `decrypt` gate in `Database::get` |
| Burn-after-reading: content shown once | concurrent readers, wrong-password guessers | `must_be_deleted` + `DELETE ... WHERE id=?` whose affected-row count decides the winner |
| Expiry | anyone with the URL | `expires < datetime('now')` checked in `Handler::get` |
| Deletion | anyone with the id | signed `uid` cookie listing the owner; `DELETE ... AND uid IN (..)` |
| Owner identity | cross-site attacker | `?owner=<signed token>` handoff; form/API insert picks the uid |
| Caches | other readers / intermediaries | server HTML cache only for plaintext, non-burned; `Cache-Control: no-store` for encrypted |
| Markup/URL injection through the key | anyone | `valid_extension` on the extension echoed into links |
| Header injection through the title | paste author | `make_content_disposition` percent-encoding |

## Covered

| Kernel | Upstream |
|---|---|
| `store::find_row`, `get_metadata`, `delete`, `fetch`, `finish`, `get` | `db.rs` `Handler::get_metadata`, `Handler::get`, `Handler::delete`, `read::DatabaseEntry::decrypt`, `Database::get` (burn, precedence of `Encrypted` over `Burned`) |
| `store::delete_for`, `owned_by`, `contains_uid` | `db.rs` `Handler::delete_for` (the SQL `id=? AND uid IN (..)`) |
| `store::purge` | `db.rs` `Handler::purge` |
| `handlers::view`, `view_id`, `page_of`, `can_delete`, `no_password` | `handlers/html/paste.rs` `get` (handoff, interstitial, password page, cache-put condition, `no_store`), `handlers/html/rendered.rs` `get` (same minus handoff) |
| `handlers::raw`, `raw_id` | `handlers/raw.rs` `get`, `handlers/download.rs` `get` |
| `handlers::qr`, `qr_id` | `handlers/html/qr.rs` `get` (metadata part) |
| `handlers::delete_paste` | `handlers/delete/api.rs`, `handlers/delete/form.rs`, the `Uids` extractor's rejection |
| `handlers::handoff`, `form_owner`, `api_owner` | `paste.rs` `?owner=` branch, `insert/form.rs` uid choice, `insert/api.rs` uid choice |
| `handlers::insert`, `id_taken` | `db.rs` `Handler::insert` (retry on primary-key conflict, at most 11 ids) |
| `handlers::db_status` | `errors.rs` `From<Error> for StatusCode` (the database arms) |
| `ids::encode`, `decode`, `to_i64`, `parse_key`, `key_path` | `id.rs` `Display`/`FromStr`/`to_i64`, `cache.rs` `Key::from_str`, `Display for Key` |
| `ext::valid_extension` | `cache.rs` `valid_extension` |
| `disposition::content_disposition` | `download.rs` `make_content_disposition` |

## How it is checked

- `difftest/src/store_tests.rs` runs the real `wastebin_core::Database` (SQLite through the upstream
  handler thread, zstd, argon2 + XChaCha20-Poly1305) next to the kernel on 4 random tables of 40
  pastes and 1,200 random operations (`get` with/without/wrong password, `get_metadata`,
  `delete_for` with random uid lists, `purge`), comparing results and the table after every step.
  Expiry times are set through a second SQLite connection, at least 15 minutes from the clock.
  Encrypted operations are bounded (18 encrypted pastes, 40 decryptions) because each costs argon2.
- `difftest/src/ids_tests.rs` compares the copied upstream `valid_extension`, `Key::from_str`,
  `Display for Key` and `make_content_disposition`, and the linked `Id` codec, on 200k-400k
  generated inputs each (id alphabet, punctuation, quotes, whitespace, multi-byte characters).
- Seeds are fixed (`Rng(0x5eed_....)`). Testing is evidence, not a proof of equivalence.
- Not differentially tested: the handler-level functions (`view`, `raw`, `qr`, `delete_paste`,
  `handoff`, `form_owner`, `api_owner`, `insert`). They are read against the upstream source; an
  HTTP-level difftest against the upstream server binary is the next step (STATUS.md).

## Trusted (assumed, not proved)

- Cryptography: decryption with password `p` succeeds exactly when `p` is the password the paste was
  encrypted with (`secret = some k`, `p = k`). Argon2 collisions and AEAD forgeries are excluded.
  Passwords are abstract `u64` names.
- Cookie signing: the `Uids` extractor's HMAC check (axum-extra `SignedCookieJar`) and
  `verify_owner_token`; the kernel receives the verified uid list / uid. `parse_uids` is not modeled.
- SQLite: `WHERE id=?` returns the first row with the id (the primary key makes it unique);
  `datetime` comparison equals integer second comparison; statements are atomic and the handler
  thread serializes them (that is what makes `burnReaders` sequential).
- The HTTP framework: routing, path decoding (`Path<String>`), form/JSON extraction, the empty
  password filter of the form (`PasteForm` filters `""`, raw/download do not).
- Compression, highlighting, markdown rendering, templates, the QR encoder, `safe_referer` (uses
  the `url` crate), metrics and logs.

## Differences in form

| Where | Upstream | Kernel | Why |
|---|---|---|---|
| everywhere | `&str`, `String` | `&[u8]`, `Vec<u8>` | no strings in the Aeneas subset; upstream's checks are bytewise. A multi-byte character is rejected by both (`decode`: no byte of it is in the table) |
| the table | SQLite | `Vec<Row>`; content/title as `u64` names | data is opaque to every decision |
| time | `datetime('now')` text | `now: i64` seconds | |
| `Database::get` | one async call | `fetch` (read + decrypt) and `finish` (the burning `DELETE`) | to state the concurrent-reader theorem; `get` = `fetch` then `finish` on the same table |
| `get_metadata` expiration | remaining seconds if positive | raw `expires` | display only |
| cache | LRU of HTML per (id, ext, mode) | input `cached: bool`, output `cache_put` | the cache content is not modeled |
| view/raw/qr | parse inside the handler | `view` parses then calls `view_id` (same for raw/qr) | proof structure; same behavior |
| insert | random ids generated inside the loop | ids given as a slice | randomness is an input |
| `unreserved`, `extension_byte` | one boolean expression | uses `is_ascii_alphanumeric` | proof size; same truth table |

## Not covered

`safe_referer`, `parse_uids`/`serialize_uids` (signed, server-written), `Expiration` parsing and
display, i18n/language negotiation, theme cookies, the highlighter and markdown renderer (XSS of
rendered markdown is out of scope), `wastebin-ctl`, migrations.

## Abandoned / unfinished attempts

- `Content-Disposition` full functional spec: started (prefix copy loop, hex table); paused after
  the byte-class spec, because the shift/mask lemmas for `b >> 4`, `b & 15` needed more time. The
  difftest covers it (200k inputs, never the `"attachment"` fallback).
- `decode (encode id) = Ok id` round trip: not attempted yet (bit arithmetic on `u32`/`i64`).
- Lint: `h5i app lint` fails because it scans the upstream server under the `upstream-src` link and
  reports every route without an `Actor<>` parameter. wastebin is anonymous by design (no actor
  exists); the lint finding is accurate for upstream and not about the kernel. Removing the link
  makes the lint pass but breaks the difftest; proposal in STATUS.md.
