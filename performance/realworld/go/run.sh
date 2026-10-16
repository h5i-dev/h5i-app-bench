#!/usr/bin/env bash
# Release build of the Go server. WEB_CONCURRENCY sets GOMAXPROCS.
# A single process uses DB_POOL connections (default 32, matching four
# workers times a pool of 8 in the other servers).
set -euo pipefail
cd "$(dirname "$0")"
export PATH="/var/tmp/go/bin:${PATH}"
export GOPATH="${GOPATH:-/var/tmp/gopath}"
export GOCACHE="${GOCACHE:-/var/tmp/gocache}"
export GOMODCACHE="${GOMODCACHE:-/var/tmp/gomodcache}"
export CGO_ENABLED=0
export PORT="${PORT:-8002}"
export DATABASE_URL="${DATABASE_URL:-postgres://conduit:conduit@127.0.0.1:54329/conduit}"
export JWT_SECRET="${JWT_SECRET:-conduit-benchmark-secret}"
export DB_POOL="${DB_POOL:-32}"
export WEB_CONCURRENCY="${WEB_CONCURRENCY:-4}"
mkdir -p /var/tmp/rw-go-bin
go build -trimpath -ldflags "-s -w" -o /var/tmp/rw-go-bin/conduit .
exec /var/tmp/rw-go-bin/conduit
