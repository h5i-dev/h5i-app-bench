# Benchmark result policy

Do not commit raw benchmark data, per-round or per-repetition samples, logs,
process snapshots, conformance output, or environment dumps. Keep them local.
Only aggregate summary CSV/JSON/Markdown files and the placement report may be
tracked under results/. Preserve the ignore allowlist; never force-add raw data.
Before committing, inspect the staged file list against this policy.
