#!/usr/bin/env bash
# Boot nora (built with the kernel) with htpasswd auth and API tokens, and
# check each branch of the auth middleware over HTTP.
#   smoke.sh <path to the nora binary>
set -euo pipefail
bin=$1
dir=$(mktemp -d)
trap 'kill $pid 2>/dev/null || true; rm -rf "$dir"' EXIT
port=$((20000 + RANDOM % 20000))
python3 -c "import bcrypt; print('alice:' + bcrypt.hashpw(b'secret', bcrypt.gensalt(4)).decode())" > "$dir/htpasswd"

cd "$dir"
NORA_HOST=127.0.0.1 NORA_PORT=$port NORA_STORAGE_PATH="$dir/data" \
NORA_AUTH_ENABLED=true NORA_AUTH_HTPASSWD_FILE="$dir/htpasswd" NORA_AUTH_TOKEN_STORAGE="$dir/tokens" \
  "$bin" serve > "$dir/nora.log" 2>&1 &
pid=$!
url=http://127.0.0.1:$port
for _ in $(seq 50); do curl -fs "$url/health" > /dev/null && break; sleep 0.2; done

fails=0
check() { # name expected-status curl-args...
  local name=$1 want=$2; shift 2
  local got
  got=$(curl -s -o "$dir/body" -w '%{http_code}' "$@")
  if [ "$got" = "$want" ]; then echo "ok   $name ($got)"; else echo "FAIL $name: got $got, want $want: $(cat "$dir/body")"; fails=$((fails + 1)); fi
}

check "public /health" 200 "$url/health"
check "/v2/ without credentials" 401 "$url/v2/"
check "/v2/ with Basic" 200 -u alice:secret "$url/v2/"
check "wrong password" 401 -u alice:wrong "$url/v2/"
check "raw upload with Basic" 201 -u alice:secret -X PUT --data-binary hello "$url/raw/demo/hello.txt"
check "raw download with Basic" 200 -u alice:secret "$url/raw/demo/hello.txt"
check "admin path with Basic" 403 -u alice:secret "$url/api/v1/admin/x"

read_token=$(curl -s -X POST -H 'content-type: application/json' \
  -d '{"username":"alice","password":"secret","role":"read"}' "$url/api/tokens" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')
check "read token: download" 200 -H "Authorization: Bearer $read_token" "$url/raw/demo/hello.txt"
check "read token: upload" 403 -H "Authorization: Bearer $read_token" -X PUT --data-binary x "$url/raw/demo/x.txt"
check "read token as Basic password" 200 -u "alice:$read_token" "$url/raw/demo/hello.txt"
check "unknown token" 401 -H "Authorization: Bearer nra_00000000000000000000000000000000" "$url/v2/"

for _ in 1 2 3 4 5; do curl -s -o /dev/null -u alice:wrong "$url/v2/"; done
check "lockout after 5 failures" 429 -u alice:secret "$url/v2/"

[ "$fails" = 0 ] && echo "all checks passed" || { echo "$fails failed"; exit 1; }
