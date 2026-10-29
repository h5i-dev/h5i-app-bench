Run `python3 prove/ports/artifactkeeper/difftest/migration-safety/run.py` from the
repository root. The runner extracts the unchanged pure scanner functions from
pinned Artifact Keeper revision7c42891cd64f144df6197b8801c9cca4f0e0f5a7,
compiles them alongside the canonical byte kernel, and compares complete outputs.

Coverage includes deterministic random masking/phrase/identifier cases, targeted
nested comments and quote escapes,30,000 compound classifier cases, and every
pinned migration SQL file. The runner prints source/corpus hashes. Migration SQL
is test data, not claimed executable source reach. String rendering becomes byte
vectors and finding kind strings become enums. Phrase needles are ASCII; see
DEVIATIONS.md for the boundary. Differential agreement complements formal
properties and does not establish behavioral equivalence for arbitrary inputs.
