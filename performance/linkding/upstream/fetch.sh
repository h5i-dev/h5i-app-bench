#!/usr/bin/env bash
# Clone the pinned linkding release into DEST (default /tmp/linkding-src).
set -euo pipefail
TAG="v1.47.0"
DEST="${1:-/tmp/linkding-src}"
if [ -d "$DEST/.git" ]; then
  git -C "$DEST" fetch --depth 1 origin "refs/tags/${TAG}:refs/tags/${TAG}"
  git -C "$DEST" checkout --detach "$TAG"
else
  git clone --depth 1 --branch "$TAG" https://github.com/sissbruecker/linkding.git "$DEST"
fi
git -C "$DEST" rev-parse HEAD
