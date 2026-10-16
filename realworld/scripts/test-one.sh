#!/usr/bin/env bash
# Run the pinned RealWorld Hurl suite against one already-started server.
# HOST is the origin without /api, for example http://127.0.0.1:8001.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HURL="${HURL:-/var/tmp/tools/hurl}"
HOST="${HOST:?set HOST to the server origin}"
UID_VAL="${UID_VAL:-$(date +%s)$$}"
echo "hurl $HOST uid=$UID_VAL"
"$HURL" --test --jobs 1 \
  --variable "host=$HOST" \
  --variable "uid=$UID_VAL" \
  "$ROOT"/spec/api/hurl/*.hurl
