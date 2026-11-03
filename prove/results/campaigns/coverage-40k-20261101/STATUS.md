# Accepted 40k source reach milestone

Accepted locally on 2026-11-01 UTC (2026-10-31 America/New_York).
Baseline: 20,765 pinned executable source lines / 609 project properties.
Accepted: **40,317 lines / 1,010 properties**, an increase of 19,552 lines
and 401 properties. The 40,000-line target is exceeded by 317 lines.
The refreshed website files have not been deployed.

The new Kanidm batch proves complete ACP, schema, group and entry records,
plus complete ordered record selection for twenty migration lists. It preserves
all 142 prior Kanidm property types. Reach is deduplicated property-type and
extracted dependency reach against exact pinned source; it does not establish
whole-application equivalence or successful database migration.

Validation:
- Pinned differential comparisons cover all 289 ACP, 852 schema, 193 group,
  18 account and 29 entry records, plus twenty ordered migration selections.
- Full Kanidm Rust suite: 43 tests; zero failures.
- Standard Kanidm gate passed with unchanged inputs: 3,514 theorems in 470
  modules checked against propext, Classical.choice and Quot.sound.
- Matching official extraction passed; all six projects retain fresh gates and
  extraction evidence.
- Dashboard regenerated: 1,010/1,010 accepted properties, 40,317 source lines.
- All 13 reach, accounting and detail regression tests passed.

See `accepted-checkpoint.json` for per-project totals and exact evidence logs,
`project-check.log` and `extraction-check.log` for runner records, and `NEXT.md`
for the longer-term 100,000+ plan. One worker; unrelated changes preserved.
