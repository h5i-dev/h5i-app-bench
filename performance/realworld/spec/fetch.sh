#!/usr/bin/env bash
# Replace spec/api with specs/api from the pinned upstream commit.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
REV="$(tr -d '[:space:]' < "$ROOT/UPSTREAM_COMMIT")"
WORKDIR="$(mktemp -d /var/tmp/rw-spec-XXXXXX)"
trap 'rm -rf "$WORKDIR"' EXIT
git clone --depth 1 https://github.com/realworld-apps/realworld.git "$WORKDIR/src"
git -C "$WORKDIR/src" fetch --depth 1 origin "$REV"
git -C "$WORKDIR/src" checkout "$REV"
rm -rf "$ROOT/api"
cp -a "$WORKDIR/src/specs/api" "$ROOT/api"
echo "pinned $REV"
