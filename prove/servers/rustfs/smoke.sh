#!/usr/bin/env bash
# Boot rustfs (built with the kernel) and check bucket-policy decisions over
# S3: anonymous requests are refused until a policy allows them, and an
# explicit Deny wins over the Allow, for the owner too.
#   smoke.sh <path to the rustfs binary>
set -euo pipefail
bin=$1
dir=$(mktemp -d)
trap 'kill $pid 2>/dev/null || true; rm -rf "$dir"' EXIT
port=$((20000 + RANDOM % 20000))
ak=h5iadmin sk=h5i-secret-key
mkdir -p "$dir/data"
RUSTFS_ADDRESS=127.0.0.1:$port RUSTFS_ACCESS_KEY=$ak RUSTFS_SECRET_KEY=$sk \
  "$bin" server "$dir/data" > "$dir/rustfs.log" 2>&1 &
pid=$!
url=http://127.0.0.1:$port
for _ in $(seq 240); do curl -fs -o /dev/null "$url/health/ready" && break; sleep 0.5; done

fails=0
check() { # name expected-status curl-args...
  local name=$1 want=$2; shift 2
  local got
  got=$(curl -s -o "$dir/body" -w '%{http_code}' "$@")
  if [ "$got" = "$want" ]; then echo "ok   $name ($got)"; else echo "FAIL $name: got $got, want $want: $(head -c 300 "$dir/body")"; fails=$((fails + 1)); fi
}
signed=(--aws-sigv4 "aws:amz:us-east-1:s3" --user "$ak:$sk")

check "create bucket" 200 "${signed[@]}" -X PUT "$url/demo"
check "put object (root)" 200 "${signed[@]}" -X PUT --data-binary hello "$url/demo/hello.txt"
check "put secret object (root)" 200 "${signed[@]}" -X PUT --data-binary s3cr3t "$url/demo/secret/key.txt"
check "anonymous get, no policy" 403 "$url/demo/hello.txt"

cat > "$dir/policy.json" <<'EOF'
{"Version":"2012-10-17","Statement":[
 {"Effect":"Allow","Principal":{"AWS":["*"]},"Action":["s3:GetObject"],"Resource":["arn:aws:s3:::demo/*"]},
 {"Effect":"Deny","Principal":{"AWS":["*"]},"Action":["s3:GetObject"],"Resource":["arn:aws:s3:::demo/secret/*"]}]}
EOF
check "set bucket policy" 204 "${signed[@]}" -X PUT --data-binary @"$dir/policy.json" "$url/demo?policy"
check "anonymous get, allowed" 200 "$url/demo/hello.txt"
check "anonymous get, denied prefix" 403 "$url/demo/secret/key.txt"
check "anonymous put, not granted" 403 -X PUT --data-binary x "$url/demo/x.txt"
check "root get outside the deny" 200 "${signed[@]}" "$url/demo/hello.txt"
# Deny statements are evaluated before the owner short-circuit, as upstream does.
check "root get under the deny" 403 "${signed[@]}" "$url/demo/secret/key.txt"

[ "$fails" = 0 ] && echo "all checks passed" || { echo "$fails failed"; exit 1; }
