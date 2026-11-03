# Accepted arbitrary string decisions toward 100k+

Accepted: **41,414 deduplicated pinned executable source lines and 1,133
canonical properties**. Baseline `1827206` had 41,133 lines and 1,130
properties. This batch adds 281 lines and three complete classifier properties.
The 100,000-line target remains active; **58,586 lines remain**.

OxiCloud's three display classifiers preserve exact MIME matches, ordered
prefix/substring matches, optional extension fallback and all default outputs.
The complete Lean proofs quantify over arbitrary byte inputs and establish
termination as well as exact decisions. The 54 distinct returned static strings
have a documented enum representation with exact decoding in differential tests.
Filename parsing, normalization and external callers receive no coverage credit.

Validation:

- 201,750 complete-string comparisons against unchanged pinned Rust bodies,
  including all literal MIME/extension combinations, adversarial strings,
  extension absence and 20,000 deterministic randomized UTF-8 pairs.
- Byte predicates tested against standard Rust operations on boundary and binary
  inputs; full OxiCloud Rust suite passes.
- All 1,130 prior canonical theorem statements are unchanged.
- Full OxiCloud gate: 1,728 theorems across 34 modules, allowing only `propext`,
  `Classical.choice`, and `Quot.sound`; inputs unchanged throughout.
- Matching official extraction check passes; generator and pinned-source audit
  reproduce artifacts byte for byte.
- All six apps have fresh gate and extraction evidence; the local dashboard
  reports 1,133/1,133 accepted properties and 41,414 matched lines.
- All 19 source span, project reach, dashboard accounting/detail, and project
  runner tests pass after dashboard refresh. Historical benchmark accounting is
  unchanged at 101 tasks / 99 accepted. No dashboard deployment was performed.

`accepted-checkpoint.json` records exact per-app evidence paths. `NEXT.md` gives
reproduction commands and the remaining substantive directions. One worker;
unrelated performance edits and untracked workspace trees are preserved.
