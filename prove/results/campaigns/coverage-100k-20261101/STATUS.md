# Finite catalog checkpoint toward 100k

This batch reaches **41,133 accepted deduplicated pinned executable source
lines and 1,130 canonical properties**, adding 816 lines and 120 properties
to the 40,317-line checkpoint. The 100,000-line target remains **58,867 lines
away**. The exact fresh gate/extraction logs and accepted count are recorded in
`accepted-checkpoint.json`.

The baseline is commit `c793a05`: 40,317 accepted deduplicated pinned executable
source lines and 1,010 canonical project properties. This batch adds 120 complete
finite-domain output properties across all six apps. It covers 88 closed unit
enums, with 712 exhaustive input comparisons against unchanged pinned method
bodies. Enum declarations, test code and generated files add no upstream credit.
All earlier canonical property statements remain unchanged.

The reusable importer is `prove/harness/finite_catalog.py`. It compiles closed
method groups, rejects unresolved dependencies, preserves enum variants and
discriminants, and retains exact pinned method bodies. String results are
represented as UTF-8 byte vectors. Each Lean property specifies the complete
output for every input variant, including termination and absence of panic in
that finite domain. These properties do not establish whole-application
equivalence or cover external effects.

Validation evidence includes all 133 Rust tests, all 712 new input comparisons,
exact pinned-reference audits, and byte-for-byte isolated regeneration of every
new generated artifact. All six fresh full project and axiom gates passed with unchanged inputs, as
did all matching official extraction checks. The dashboard assets are refreshed
and all 13 source reach/dashboard accounting/detail tests pass. The historical
101 benchmark tasks and their 99 accepted results remain intact. Dashboard
deployment has not been performed.

The first Nora gate attempt exhausted its 30-minute budget after approximately
24 minutes waiting for the shared package lock. Its independent full build
passed; the standard check was rerun with a one-hour limit. No proof input was
changed to address the timeout.

The new Artifactkeeper bit-mask proof explicitly unfolds the preserved numeric
discriminant before proving its shift result. The Rust behavior and expected
outputs remain unchanged.

`NEXT.md` and `remaining-candidates.json` describe substantive follow-up work.
Inventory estimates and provisional results are not accepted coverage.
