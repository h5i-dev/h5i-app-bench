# Spacedrive port: scope, deviations, trusted boundary

## Upstream pin

- Repository: https://github.com/spacedriveapp/spacedrive (AGPL-3.0)
- Commit: `2c4da346da529f06428fcf40488345ef8b955f15` (2026-11-05, "Reconcile each source with its disk at startup (#3202)")
- Local checkout: `ports/spacedrive/upstream-src` → `/mnt/scratch/oss-sec/upstream/spacedrive`
  (a gitignored symlink). The difftest reads files with `git show <commit>:<path>`, so edits to the
  working tree there do not affect it.
- License: the kernel is a rewrite of AGPL-3.0 code and stays under AGPL-3.0. No upstream source is
  committed; `difftest/build.rs` copies the upstream items into the build directory at build time.

## Threat model

Spacedrive's core is a large async/DB/P2P Rust crate. The pure, security-critical decision logic
that can be isolated includes: archive-extraction path landing, the extension capability model, HLC
sync-operation ordering, P2P path-containment checks, WebDAV range parsing, and pairing/vouch
acceptance (surveyed in git history). This port takes the first of these as a complete vertical
slice:

| Asset / decision | Upstream | Attacker goal |
|---|---|---|
| Where an archive entry lands beneath the extraction destination | `core/src/ops/files/archive/directory.rs:26-50` `ArchiveEntry::landing` | make an entry escape the destination (`..`, absolute, NUL, empty) |

## What the kernel ports (`kernel/src/archive.rs`)

| Kernel | Upstream | Notes |
|---|---|---|
| `archive::normalize` | `name.replace('\\', "/")` | byte loop, `\`→`/` |
| `archive::{is_dot, is_dotdot, has_nul}` | the `match part` arms | `"."`, `".."`, NUL checks |
| `archive::components` | the `for part in normalized.split('/')` loop | returns `None` on `..`/NUL, skips `""`/`"."`, keeps the rest in order |
| `archive::skip` | `components.into_iter().skip(strip as usize).collect()` | index loop cloning the kept tail |
| `archive::landing` | `ArchiveEntry::landing(strip)` | `None` on escape or when stripping leaves nothing |

## Differences from upstream

- **Paths are byte strings.** Upstream works with `String`/`PathBuf`; the kernel works with
  `Vec<u8>`/`&[u8]` segments. `landing` returns the *list of segments* (`Option<Vec<Vec<u8>>>`) that
  upstream builds a `PathBuf` from via `kept.iter().collect()`, rather than a `PathBuf`.
- **`split('/')` + the `\`→`/` normalisation** are modelled exactly; `is_dot`/`is_dotdot` compare
  the segment bytes; `has_nul` scans for `0`.
- **The absolute-path branch** (upstream's `if normalized.starts_with('/') && !components.is_empty()
  { /* no-op */ }`) is a no-op upstream and is simply omitted: a leading `/` produces an empty first
  segment which is skipped, so the result is read relative to the destination, matching upstream.
- **Not modelled:** the `PathBuf` assembly on the host side, and crucially the *extraction* step
  (`extract_entries`), which is IO and is where FINDINGS F1 lives. `landing` is a pure name check; it
  does not see entry types (symlink vs file). The kernel is only this name check.

## Trusted boundary

Assumed, not proved: that the host builds `destination.join(PathBuf::from_iter(segments))` and that
`PathBuf::from_iter` over the kept segments produces a path that stays under `destination` on the
target OS. On Unix this follows from every segment being a non-empty `Normal` component (no `/`,
no `..`); the kernel proves segments are non-empty, not `.`/`..`, and NUL-free. On **Windows** a
segment such as `C:` or one containing `\` could be reinterpreted — not modelled (the difftest uses
Unix component semantics). The extraction step, symlink handling (FINDINGS F1), the tar/zip
libraries, and Charon/Aeneas/Lean are trusted.

## Differential tests (`difftest/`)

`cargo test --release` compiles upstream's own `directory.rs` (the `ArchiveEntry` struct and
`landing`), `job.rs` (`extract_entries`, `Report`, `zip_system_time`) and `input.rs`
(`ArchiveFormat`) at the pinned commit (`build.rs` via `git show`, taking whole items). Seeds are
fixed (splitmix64).

| Test | Cases | Compared |
|---|---:|---|
| `landing_agrees` | 200,000 | `landing(strip)` vs the kernel, on random names over `{a,b,.,..,/,\,NUL,C:,é,x.txt,//,./,../}` and `strip ∈ 0..3`; both `None` and `Some` outcomes exercised (>10,000 each). Upstream `PathBuf` results are compared component-wise as `Normal` segments. |
| `tar_symlink_entry_writes_outside_destination` | 1 | FINDINGS F1: upstream's own `extract_entries` writes through a symlink entry outside the destination, although both entry names pass `landing`. |

All pass. Testing is evidence, not an equivalence proof; the Lean theorems certify the kernel's
`landing` under the byte-string model and the Unix-component assumption above.

## Unsuccessful or abandoned attempts (kept for the record)

- The `components` loop proof initially used an invariant bounding the index by `normalized.length`;
  the loop actually runs the index to `length + 1` (it flushes the final segment at `i == length`),
  so the bound was relaxed to `length + 1`.
- Matching the per-guard hypotheses after `h5i_invert` by name was fragile (the boolean guards come
  back as `is_dot s = ok b` with a separate `¬ b = true`); the proof normalises with
  `simp only [Bool.not_eq_true]; subst_vars` and then matches the `= ok false` forms anonymously.
- `SafeSeg` was first stated to also forbid `/` (47) and `\` (92) in a segment; proving the no-`47`
  part needs a `cur`-never-contains-`/` loop invariant and the no-`92` part needs `normalize`
  correctness. These are true but were dropped from the gated property to keep it to the four guards
  `components` directly applies; the retained four are what rule out traversal.
