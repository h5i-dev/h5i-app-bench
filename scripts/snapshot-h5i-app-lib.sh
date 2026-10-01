#!/usr/bin/env bash
# Copy the built H5iAppLib from the sibling h5i-app checkout into env/h5i-app-lib, the
# read-only library the sandbox mounts at /opt/h5i-app-lib.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
src=${1:-$root/../h5i/crates/h5i-app-core/proofs}
rm -rf "$root/env/h5i-app-lib"
rsync -a --exclude .lake/packages --exclude .lake/ci "$src/" "$root/env/h5i-app-lib/"
ln -sfn /opt/lake/packages "$root/env/h5i-app-lib/.lake/packages"
git -C "$src" log -1 --format='h5i %h' -- . > "$root/env/h5i-app-lib/VERSION"
