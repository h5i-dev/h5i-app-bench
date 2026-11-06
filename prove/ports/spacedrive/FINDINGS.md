# Spacedrive findings (pinned commit 2c4da346da529f06428fcf40488345ef8b955f15)

No upstream issue has been filed.

## F1. A tar entry can redirect a later extraction write outside the destination via a symlink

- **Upstream:** `core/src/ops/files/archive/directory.rs:26-50` (`ArchiveEntry::landing`),
  `core/src/ops/files/archive/job.rs` (`extract_entries`, the `ArchiveFormat::TarZstd` arm, around
  lines 820-845, `entry.unpack(path)`), and the plan built in
  `core/src/ops/files/archive/plan.rs:35` / `preflight.rs`.
- **Description:** `landing` sanitises each entry's *name* (rejecting `..`, NUL, empty and `.`
  segments, which this port proves). But a `.tar.zst` entry may be a **symlink**, and the tar
  extractor (`tar::Archive::unpack`/`entry.unpack`) writes symlink entries to disk. Consider an
  archive whose first entry is a symlink `lnk -> /some/outside/dir` and whose second entry is a
  regular file `lnk/pwned.txt`. Both names pass `landing` (neither contains `..`), so both are
  planned under the destination. When the tar arm extracts them in order, it first creates the
  symlink `dest/lnk`, then writes `dest/lnk/pwned.txt`, which the OS resolves through the symlink to
  `/some/outside/dir/pwned.txt` — a write outside the destination.
  - The zip arm is not affected the same way: `preflight.rs:95` and `job.rs:306` explicitly skip
    symlink entries for zip ("a zip does not carry a symlink"). The tar arm has no such guard in the
    code read.
- **Evidence:** the differential test `tar_symlink_entry_writes_outside_destination`
  (`difftest/src/tests.rs`, `cargo test --release`) builds exactly this `.tar.zst`, plans both
  entries with the real `ArchiveEntry::landing`, runs upstream's own `extract_entries` (copied
  verbatim at the pinned commit), and asserts that `<outside>/pwned.txt` is created with the
  attacker's contents. The test passes, i.e. the escape reproduces.
- **Severity:** medium. It requires the user to extract an attacker-supplied `.tar.zst` to a chosen
  destination, which is a normal operation. The write lands wherever a symlink target points,
  subject to filesystem permissions of the spacedrive process.
- **Exploitability:** an attacker who can get a user to extract a crafted archive can create or
  overwrite files outside the extraction destination (e.g. under `$HOME`, config dirs), within the
  process's permissions. No path in the entry *names* is needed; the redirection is via the symlink.
- **Reachable from the API/UI:** yes — archive extraction is a user-facing file operation
  (`core/src/ops/files/archive/`).
- **Relationship to the proofs:** this is *not* a counterexample to the `landing` theorems. Those
  state exactly what `landing` guarantees about an entry's path *string* (no `..`, NUL, empty, `.`),
  and they hold. The finding is that string-level sanitisation is insufficient against symlink
  entries in the tar path; the missing guard is a symlink/entry-type check in the tar extractor (as
  the zip path already has), or extracting without following symlinks / under `O_NOFOLLOW`.
- **Fix suggestion:** in the tar arm, skip or reject symlink (and hardlink) entries as the zip arm
  does, or canonicalise the final path and re-check containment under the destination before
  writing, or extract with `tar`'s `set_preserve_permissions(false)` and an explicit per-entry
  symlink check. `follow_symlinks(false)` at `job.rs:398` controls archive *creation*, not extraction.
