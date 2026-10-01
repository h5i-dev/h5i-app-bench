#!/usr/bin/env bash
# Link the upstream checkouts that the rustfs and OxiCloud differential tests
# build against, as ports/<app>/upstream-src. Check each one out at the commit
# its DEVIATIONS.md pins.
#   RUSTFS_SRC=<rustfs checkout> OXICLOUD_SRC=<OxiCloud checkout> scripts/link-upstream.sh
set -euo pipefail
cd "$(dirname "$0")/.."
for pair in "rustfs:${RUSTFS_SRC:-}" "oxicloud:${OXICLOUD_SRC:-}"; do
  app=${pair%%:*} src=${pair#*:}
  if [ -z "$src" ]; then echo "skipping $app: no source checkout given"; continue; fi
  ln -sfn "$(cd "$src" && pwd)" "ports/$app/upstream-src"
  echo "ports/$app/upstream-src -> $src"
done
