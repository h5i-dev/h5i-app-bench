# Spacedrive port: status

**Theorems in the gate: S 4 / C 5 / F 0** (9 in `[check] theorems`). S ≥ C/3 holds.

**Gate:** `h5i app doctor`, `h5i app extract --check`, `h5i app check` (25 theorems in 3 modules,
only propext/Classical.choice/Quot.sound) and `h5i app lint` all pass. Move `upstream-src` away
before `lint`/`mutate` (they walk the project directory).

**Differential tests:** `cd difftest && cargo test --release` — 2 tests pass (`landing_agrees`
200,000 cases; `tar_symlink_entry_writes_outside_destination`, which demonstrates FINDINGS F1 with
upstream's own `extract_entries`).

**Mutation:** `h5i app mutate -j 2 ports/spacedrive` is running (`/mnt/scratch/oss-sec/tmp/c/mutate_sd.log`).

Upstream: spacedriveapp/spacedrive @ `2c4da346da529f06428fcf40488345ef8b955f15`. Scope, trusted
boundary and deviations are in [DEVIATIONS.md](DEVIATIONS.md); the finding is in [FINDINGS.md](FINDINGS.md).

## Theorems

Prefixes: `V` = `spacedrive_kernel.Verified`, `P` = `spacedrive_kernel.Properties`. Every S theorem
is about the extracted `archive.landing` and holds for every entry name and `strip`.

### S: security properties (of `ArchiveEntry::landing`)

| Theorem | Statement (for every accepted landing `kept`) | Bug it rules out | Killing mutant |
|---|---|---|---|
| `P.landing_rejects_parent` | no kept segment is `..` | an entry climbing to a parent of the destination | `keep_parent` |
| `P.landing_rejects_nul` | no kept segment contains a NUL byte | a NUL that a join could truncate/reinterpret | `keep_nul` |
| `P.landing_rejects_empty` | every kept segment is non-empty | an empty path component | `keep_empty_and_curdir` |
| `P.landing_rejects_curdir` | no kept segment is `.` | a `.` re-entering the current directory | `keep_empty_and_curdir` |

### C: correspondence and foundations

| Theorem | What it establishes |
|---|---|
| `P.landing_safe_all` | the full per-segment invariant (`SafeSeg`) the four S theorems project out |
| `P.components_safe_all` | the same safety already holds of every segment `components` keeps, before `skip` |
| `V.is_dot_spec`, `V.is_dotdot_spec`, `V.has_nul_spec` | each guard equals its `Spec` decision over byte lists |

`V.components_safe`, `V.skip_safe`, `V.skip_safe'`, `V.landing_safe`, `V.flush_safe` and the loop
helpers back these; `components_safe` is the loop-invariant proof (no `..`/NUL/empty/`.` segment is
ever pushed), `skip_safe` shows the strip/clone step only drops and copies segments.

## What is next / possible extensions

1. Record the mutation result (expect 3/3 caught).
2. Further pure spacedrive logic identified but not yet ported (see the context survey in git history):
   the extension capability model (`ManifestPermissions`, `glob_extensions` fail-closed), HLC sync
   ordering (`update`/`generate`, likely a clock-regression / counter-overflow finding), the P2P
   path-containment predicates (`provider::resolve`, `byterange::authorize_path`), WebDAV
   `parse_range` bounds, and the proxy-vouch acceptance chain. Each is pure and copy-verbatim testable.

## How to resume

- Toolchain: `source /mnt/scratch/oss-sec/env.sh`. `proofs/.lake/packages` must be the shared-cache
  symlink. Never let lake rebuild Mathlib.
- `h5i app extract ports/spacedrive`, then `lake build` in `proofs/`.
- Difftest: `cd difftest && cargo test --release` (needs `ports/spacedrive/upstream-src`, a gitignored
  symlink to `/mnt/scratch/oss-sec/upstream/spacedrive`). `build.rs` copies upstream's own
  `directory.rs`/`job.rs`/`input.rs` at the pinned commit via `git show`.
