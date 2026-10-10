#!/usr/bin/env bash
# Copy the built Git-pinned H5iAppLib from the standard project's Lake cache into env/h5i-app-lib, the
# read-only library the sandbox mounts at /opt/h5i-app-lib.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
src=${1:-$root/ports/nora/proofs/.lake/packages/h5i_app_lib/crates/h5i-app-core/proofs}
test -f "$src/H5iAppLib.lean" || {
  echo 'Build the standard project first: h5i app check ports/nora' >&2
  exit 1
}
# Preserve the previous snapshot rather than deleting a user's library cache.
mkdir -p "$root/results/scratch"
if test -e "$root/env/h5i-app-lib"; then
  backup=$(mktemp -d "$root/results/scratch/library-snapshot.XXXXXX")
  mv "$root/env/h5i-app-lib" "$backup/h5i-app-lib"
fi
rsync -a --exclude .lake/packages --exclude .lake/ci "$src/" "$root/env/h5i-app-lib/"
ln -sfn /opt/lake/packages "$root/env/h5i-app-lib/.lake/packages"
git -C "$src" rev-parse HEAD > "$root/env/h5i-app-lib/VERSION"
