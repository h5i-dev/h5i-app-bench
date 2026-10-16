#!/usr/bin/env bash
# Boot tuwunel (built with the kernel) and check history-visibility
# decisions over the client API: who may read an event (/event, /messages),
# the room state (/state) and the room (/messages) as members join and leave
# and the visibility changes.
#   smoke.sh <path to the tuwunel binary>
set -euo pipefail
bin=$1
dir=$(mktemp -d)
trap 'kill $pid 2>/dev/null || true; rm -rf "$dir"' EXIT
port=$((20000 + RANDOM % 20000))
mkdir -p "$dir/db"
TUWUNEL_SERVER_NAME=smoke.test TUWUNEL_DATABASE_PATH="$dir/db" \
TUWUNEL_ADDRESS=127.0.0.1 TUWUNEL_PORT=$port TUWUNEL_ALLOW_FEDERATION=false \
TUWUNEL_ALLOW_REGISTRATION=true \
TUWUNEL_YES_I_AM_VERY_VERY_SURE_I_WANT_AN_OPEN_REGISTRATION_SERVER_PRONE_TO_ABUSE=true \
  "$bin" > "$dir/tuwunel.log" 2>&1 &
pid=$!
url=http://127.0.0.1:$port
for _ in $(seq 240); do curl -fs -o /dev/null "$url/_matrix/client/versions" && break; sleep 0.5; done

URL=$url python3 - <<'EOF'
import json, os, sys, urllib.request, urllib.error

url = os.environ["URL"]
fails = 0

def call(method, path, token=None, body=None):
    req = urllib.request.Request(url + path, method=method,
                                 data=None if body is None else json.dumps(body).encode())
    req.add_header("content-type", "application/json")
    if token:
        req.add_header("authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.load(r)
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b"{}")

def register(name):
    body = {"username": name, "password": "smoke-" + name + "-pass"}
    status, r = call("POST", "/_matrix/client/v3/register", body=body)
    if status == 401:
        body["auth"] = {"type": "m.login.dummy", "session": r["session"]}
        status, r = call("POST", "/_matrix/client/v3/register", body=body)
    assert status == 200, (status, r)
    return r["access_token"]

def check(name, want, status):
    global fails
    ok = status == want
    fails += not ok
    print(("ok  " if ok else "FAIL") + f" {name} ({status}{'' if ok else ', want ' + str(want)})")

n = 0
def send(token, room, text):
    global n
    n += 1
    s, r = call("PUT", f"/_matrix/client/v3/rooms/{room}/send/m.room.message/t{n}", token,
                {"msgtype": "m.text", "body": text})
    assert s == 200, (s, r)
    return r["event_id"]

def visibility(token, room, v):
    s, r = call("PUT", f"/_matrix/client/v3/rooms/{room}/state/m.room.history_visibility/", token,
                {"history_visibility": v})
    assert s == 200, (s, r)

def messages(token, room):
    s, r = call("GET", f"/_matrix/client/v3/rooms/{room}/messages?dir=b&limit=100", token)
    return s, [e["event_id"] for e in r.get("chunk", [])]

alice, bob, carol = register("alice"), register("bob"), register("carol")
s, r = call("POST", "/_matrix/client/v3/createRoom", alice,
            {"preset": "private_chat",
             "initial_state": [{"type": "m.room.history_visibility", "state_key": "",
                                "content": {"history_visibility": "joined"}}]})
assert s == 200, (s, r)
room = r["room_id"]

m1 = send(alice, room, "before bob")
s, _ = call("POST", f"/_matrix/client/v3/rooms/{room}/invite", alice, {"user_id": "@bob:smoke.test"})
assert s == 200
s, _ = call("POST", f"/_matrix/client/v3/rooms/{room}/join", bob, {})
assert s == 200
m2 = send(alice, room, "after bob")

# joined: bob sees only what came after his join
check("joined: bob reads the event after his join", 200,
      call("GET", f"/_matrix/client/v3/rooms/{room}/event/{m2}", bob)[0])
check("joined: bob cannot read the event before his join", 404,
      call("GET", f"/_matrix/client/v3/rooms/{room}/event/{m1}", bob)[0])
s, ids = messages(bob, room)
check("joined: /messages shows bob the later event", True, m2 in ids)
check("joined: /messages hides the earlier event", False, m1 in ids)

# a stranger sees neither state nor room
check("stranger: no room state", 403, call("GET", f"/_matrix/client/v3/rooms/{room}/state", carol)[0])
check("stranger: no /messages", 403, messages(carol, room)[0])
check("stranger: no event", 404, call("GET", f"/_matrix/client/v3/rooms/{room}/event/{m2}", carol)[0])

# shared: a former member keeps what came before the leave
visibility(alice, room, "shared")
m3 = send(alice, room, "shared, bob present")
s, _ = call("POST", f"/_matrix/client/v3/rooms/{room}/leave", bob, {})
assert s == 200
m4 = send(alice, room, "shared, after bob left")
check("shared: bob reads what came before he left", 200,
      call("GET", f"/_matrix/client/v3/rooms/{room}/event/{m3}", bob)[0])
check("shared: bob cannot read what came after he left", 404,
      call("GET", f"/_matrix/client/v3/rooms/{room}/event/{m4}", bob)[0])
check("shared: the former member still sees the room", 200, messages(bob, room)[0])

# world_readable: anyone reads the state and later events
visibility(alice, room, "world_readable")
m5 = send(alice, room, "world readable")
check("world_readable: stranger reads the state", 200,
      call("GET", f"/_matrix/client/v3/rooms/{room}/state", carol)[0])
check("world_readable: stranger reads the event", 200,
      call("GET", f"/_matrix/client/v3/rooms/{room}/event/{m5}", carol)[0])
check("world_readable: stranger still cannot read the joined-era event", 404,
      call("GET", f"/_matrix/client/v3/rooms/{room}/event/{m1}", carol)[0])

print("all checks passed" if fails == 0 else f"{fails} failed")
sys.exit(1 if fails else 0)
EOF
