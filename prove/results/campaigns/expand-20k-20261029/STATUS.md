# 20k expansion status

Updated UTC: 2026-10-29T18:15:00Z

Accepted checkpoint: **20,765 pinned upstream executable lines / 609 properties**.
The 20,000-line target is reached by this accepted checkpoint (+765 over target).
Latest accepted batch: complete Kanidm built-in ACP default initializers,
**+4,253 lines / +20 properties** (Kanidm 7,283 / 122 -> 11,536 / 142).
Previous accepted checkpoint: 16,512 / 589 at 6bf9a99.

ACP batch: 66 original initializers (eleven profiles x dl11, dl12, dl13, dl14,
dl15, dl_1_12) at kanidm f608c4fe, covered by 20 distinct owned full-record
constructors. Each of the 20 manifest theorems proves unconditional success and
the exact entire 15-field record (including every empty permission list and the
complete encoded target filter) of the extracted implementation. No sorry, no added
axioms; the gate checked 1886 theorems in 65 modules against propext,
Classical.choice and Quot.sound only. All 66 mapping spans re-hashed against the
pinned upstream (0 mismatches).

Evidence:
- Pinned differential: 66 profiles / all 15 fields / 20 records matched
  (kanidm-acp-differential.log); the upstream reference was regenerated from git
  and is byte-identical.
- Kanidm check: 20261029T180421291839Z; exact extraction: 20261029T180720498436Z.
- Other five apps: inputs unchanged; their recorded gates/extractions remain fresh
  and source-matched (see accepted-checkpoint.json).
- Official dashboard refreshed (609/609 properties); 13 dashboard accounting /
  project reach / project detail tests passed afterwards.

Accounting is TYPE-seeded extracted dependency reach to pinned executable source,
not equivalence of entire upstream applications.

Session notes: proofs fixed by renaming the Lean model field `name` (a token in
scope) to «name» and unfolding `alloc.vec.FromVecArray.from` / `Std.Array.empty`
for `Vec::from([..])`. Work done by one Claude Code worker (tmux prove-claude-acp);
no agents or extra AI sessions. Not done here (out of scope): final whole-branch
review and main merge. No blocker.
