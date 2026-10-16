#!/usr/bin/env bash
# Check out an upstream application at its pinned commit in a new worktree,
# apply servers/<app>/<app>.patch, which replaces the code the port covers
# with calls into the port's kernel, and run the upstream test suite.
#   SRC=<upstream checkout> [WORK=<dir>] servers/build.sh <app>
set -euo pipefail
app=$1
here=$(cd "$(dirname "$0")" && pwd)
. "$here/$app/app.env"
src=$(cd "${SRC:?SRC must name the upstream checkout}" && pwd)
work=${WORK:-$(dirname "$src")/h5i-servers}/$app
if [ ! -d "$work" ]; then
  git -C "$src" worktree add --detach "$work" "$COMMIT"
  mkdir -p "$work/h5i"
  ln -sfn "$here/../ports/$PORT/kernel" "$work/h5i/$KERNEL"
  git -C "$work" apply "$here/$app/$app.patch"
fi
cd "$work"
eval "$TEST"
eval "$BUILD"
