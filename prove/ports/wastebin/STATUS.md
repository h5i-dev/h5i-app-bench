# wastebin: status

Upstream matze/wastebin @ c0ec9687ba41e8806654f34841e9a739f0264ced (see DEVIATIONS.md).

## Done
- Kernel: `store` (Database::get/get_metadata/delete_for/purge, burn commit split as fetch/finish),
  `handlers` (paste view, raw/download, QR, delete, owner identity, insert), `ids`, `ext`, `disposition`.
- Proofs: deletion authorization (4 theorems), gate passes.
- Difftest `difftest/`: ids/keys/extensions/Content-Disposition (copied upstream items) and the
  real `wastebin_core::Database` on random tables and op sequences.

## Next
- Proofs for get (expiry, password, burn-once), view/raw/qr, owner identity, ids/ext/disposition.
- HTTP difftest of the handlers against the upstream server binary.
- DEVIATIONS.md, mutate.

## Resume
`cd prove && h5i app check ports/wastebin`; `cargo test --release --manifest-path ports/wastebin/difftest/Cargo.toml`
(needs `ports/wastebin/upstream-src -> /mnt/scratch/oss-sec/upstream/wastebin`).
