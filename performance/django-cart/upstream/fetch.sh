#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
commit=$(cat "$here/COMMIT")
dest=${1:-/var/tmp/h5i-bench-django-cart-src}
if [[ ! -d "$dest/.git" ]]; then
  git clone --no-checkout git@github.com:bmentges/django-cart.git "$dest"
fi
git -C "$dest" fetch --depth 1 origin "$commit"
git -C "$dest" checkout --detach "$commit"
test "$(git -C "$dest" rev-parse HEAD)" = "$commit"
