#!/usr/bin/env bash
# Run the Hurl suite against one already-started server.
# HOST is the origin without a path, for example http://127.0.0.1:8101.
# Bookmark, tag, and bundle rows are cleared before each file. Users stay.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HURL="${HURL:-/var/tmp/tools/hurl}"
HOST="${HOST:?set HOST to the server origin}"
PG="${LINKDING_PG_CONTAINER:-linkding-pg}"

# rust-h5i keeps its rows in its own schema (see bench/seed_h5i_app.sql);
# test-all.sh sets TRUNCATE_SQL for it.
TRUNCATE_SQL="${TRUNCATE_SQL:-TRUNCATE bookmark_tags, bookmarks, tags, bundles RESTART IDENTITY CASCADE;}"

truncate_rows() {
  docker exec -i "$PG" psql -U linkding -d linkding -v ON_ERROR_STOP=1 \
    -c "$TRUNCATE_SQL" \
    >/dev/null
}

alice="$(printf 'a%.0s' {1..40})"
bob="$(printf 'b%.0s' {1..40})"
cara="$(printf 'c%.0s' {1..40})"
dave="$(printf 'd%.0s' {1..40})"
erin="$(printf 'e%.0s' {1..40})"

for file in "$ROOT"/tests/*.hurl; do
  echo "hurl $(basename "$file") $HOST"
  truncate_rows
  "$HURL" --test --jobs 1 \
    --variable "host=$HOST" \
    --variable "alice=$alice" \
    --variable "bob=$bob" \
    --variable "cara=$cara" \
    --variable "dave=$dave" \
    --variable "erin=$erin" \
    "$file"
done
echo "hurl ok $HOST"
