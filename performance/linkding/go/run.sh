#!/usr/bin/env bash
# Release build of the Go server. WEB_CONCURRENCY sets GOMAXPROCS.
# A single process uses DB_POOL connections (default 32, matching four
# workers times a pool of 8 in the other servers).
set -euo pipefail
cd "$(dirname "$0")"
export PATH="/var/tmp/go/bin:${PATH}"
export GOPATH="${GOPATH:-/var/tmp/ld-gopath}"
export GOCACHE="${GOCACHE:-/var/tmp/ld-gocache}"
export GOMODCACHE="${GOMODCACHE:-/var/tmp/ld-gomodcache}"
export CGO_ENABLED=0
export PORT="${PORT:-8102}"
export DATABASE_URL="${DATABASE_URL:-postgres://linkding:linkding@127.0.0.1:5440/linkding}"
export DB_POOL="${DB_POOL:-32}"
export WEB_CONCURRENCY="${WEB_CONCURRENCY:-4}"
mkdir -p /var/tmp/ld-go-bin "$GOPATH" "$GOCACHE" "$GOMODCACHE"
go build -trimpath -ldflags "-s -w" -o /var/tmp/ld-go-bin/linkding .
exec /var/tmp/ld-go-bin/linkding
