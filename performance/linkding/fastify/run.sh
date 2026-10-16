#!/usr/bin/env bash
# Production Fastify: tsc build, NODE_ENV=production, node:cluster.
# WEB_CONCURRENCY workers (default 4). Each worker keeps DB_POOL connections
# (default 8).
set -euo pipefail
cd "$(dirname "$0")"
export NODE_ENV=production
export npm_config_cache="${npm_config_cache:-/var/tmp/npm-cache}"
export PATH="${PATH}:/home/ht2673/.nvm/versions/node/v24.21.0/bin"
export PORT="${PORT:-8103}"
export DATABASE_URL="${DATABASE_URL:-postgres://linkding:linkding@127.0.0.1:5440/linkding}"
export DB_POOL="${DB_POOL:-8}"
export WEB_CONCURRENCY="${WEB_CONCURRENCY:-4}"
if [ ! -x node_modules/.bin/tsc ]; then
  npm install --cache "$npm_config_cache" --no-audit --no-fund
fi
./node_modules/.bin/tsc -p tsconfig.json
exec node dist/server.js
