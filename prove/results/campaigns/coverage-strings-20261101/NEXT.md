# Continuing toward 100k

Baseline: 41,133 lines / 1,130 canonical properties at `1827206`.
This batch adds three complete arbitrary-byte classifier properties; consult
`accepted-checkpoint.json` for the actual accepted total after the gates.
The target remains 100,000 accepted deduplicated pinned executable lines.

Reproduce:

```
python3 prove/harness/display_classifiers.py audit
python3 prove/results/campaigns/coverage-strings-20261101/prior-statements.py
cargo test --manifest-path prove/ports/oxicloud/kernel/Cargo.toml
python3 prove/harness/project_checks.py check --app oxicloud --timeout 3600
python3 prove/harness/project_checks.py extract-check --app oxicloud --timeout 1800
python3 prove/harness/dashboard.py docs/prove/data --refresh-project-checks
python3 prove/results/campaigns/coverage-strings-20261101/accept.py
```

The generator is the canonical reproduction path. Historical prototype scripts
in this results directory are not needed. The primitives template supplies the
hand-written byte-window/search proofs; generated specifications preserve rule
order and exact output strings. Rust test output counts complete string
comparisons, not accepted source lines.

Next substantive directions remain Kanidm set conversions and entry diff/merge,
Artifactkeeper scanners/metadata, and string/configuration transforms. The
remaining-candidates inventory from the previous campaign is heuristic and now
includes these three already-covered classifiers; remove mapped identities
before selecting another batch. In particular, `mask_message_args` uses Unicode
character classification and nested state; an ASCII-only port would not justify
credit for its full body. Preserve real character/output/error semantics.

Do not count candidate estimates, comments, enum declarations, synthetic chunk
functions, generated source, or tests as upstream coverage. Preserve all prior
canonical statements and benchmark accounting at each accepted checkpoint.
