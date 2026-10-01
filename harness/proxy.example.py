"""Forward the sandbox's model traffic to an upstream API over a unix socket.
Copy to harness/proxy.py.

The upstream at BENCH_UPSTREAM (a base URL) must serve the API each agent
speaks: the Responses API (`/v1/responses`, Codex), the Messages API
(`/v1/messages`, Claude Code) and the Gemini API (`/v1beta/models/...`,
gemini-cli). BENCH_API_KEY is sent with every request and never enters the
sandbox. Provider-hosted tools (web search, image generation, ...) are
stripped from requests, since they would run outside the sandbox. Each
response's usage is appended to the log.

  python3 harness/proxy.py <socket> <usage.jsonl>
"""
import http.client, json, os, socketserver, sys, time, urllib.parse
from http.server import BaseHTTPRequestHandler
from billing import gateway_id

UPSTREAM = urllib.parse.urlsplit(os.environ.get("BENCH_UPSTREAM", ""))
KEY = os.environ.get("BENCH_API_KEY", "")
GEMINI = "/v1beta/models/"
# Responses API tool types that run in the sandbox; Messages API client tools
# have no type or "custom". Anything else runs on the provider's servers.
LOCAL_TOOLS = {"function", "custom", "local_shell", None}
# OpenAI-only request fields that other providers reject.
OPENAI_ONLY = ("client_metadata",)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def do_GET(self):
        self.forward(None)

    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        try:
            req = json.loads(body)
            if isinstance(req.get("model"), str):
                req["model"] = gateway_id(req["model"])
            if isinstance(req.get("tools"), list):
                req["tools"] = [t for t in req["tools"] if t.get("type") in LOCAL_TOOLS]
                if self.path.startswith(GEMINI):
                    # Gemini tools are {"functionDeclarations": [...]}; others are Google-hosted.
                    req["tools"] = [t for t in req["tools"] if set(t) == {"functionDeclarations"}]
            if not str(req.get("model", "")).startswith("gpt"):
                for k in OPENAI_ONLY:
                    req.pop(k, None)
            self.keys = sorted(req)
            body = json.dumps(req).encode()
        except ValueError:
            pass
        self.forward(body)

    def forward(self, body):
        headers = {k: v for k, v in self.headers.items()
                   if k.lower() not in ("host", "authorization", "x-api-key", "x-goog-api-key",
                                        "content-length", "connection")}
        headers["Authorization"] = "Bearer " + KEY
        path = self.path
        if path.startswith("/v1/messages"):
            headers["x-api-key"] = KEY
        elif path.startswith(GEMINI):
            headers["x-goog-api-key"] = KEY
            model, _, call = path.removeprefix(GEMINI).partition(":")
            path = GEMINI + gateway_id(model) + ":" + call
        conn = (http.client.HTTPSConnection if UPSTREAM.scheme == "https" else http.client.HTTPConnection)(
            UPSTREAM.netloc, timeout=900)
        t0 = time.time()
        conn.request(self.command, UPSTREAM.path.rstrip("/") + path, body=body, headers=headers)
        resp = conn.getresponse()
        self.send_response(resp.status)
        for k, v in resp.getheaders():
            if k.lower() not in ("transfer-encoding", "content-length", "connection", "content-encoding"):
                self.send_header(k, v)
        self.send_header("Connection", "close")
        self.end_headers()
        tail = b""
        while chunk := resp.read1(65536):
            self.wfile.write(chunk)
            self.wfile.flush()
            tail = (tail + chunk)[-200_000:]
        self.close_connection = True
        record(self.path, resp.status, time.time() - t0, tail, getattr(self, "keys", None))


def record(path, status, secs, tail, keys):
    """Usage of one response. Responses API: `response.completed` carries it.
    Messages API: `message_start` has the input and cache counts,
    `message_delta` the output count; they are merged. Gemini API: the last
    chunk's `usageMetadata`, in Responses API terms (output includes thoughts)."""
    usage, model = {}, None
    text = tail.decode("utf-8", "replace")
    # A non-streamed Gemini response is one pretty-printed object.
    lines = [json.dumps(json.loads(text))] if text.lstrip().startswith("{") and '"usageMetadata"' in text else text.splitlines()
    for line in lines:
        line = line.removeprefix("data: ").strip()
        if '"usage' not in line:
            continue
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if not isinstance(ev, dict):
            continue
        if ev.get("usageMetadata"):
            u = ev["usageMetadata"]
            usage = {"input_tokens": u.get("promptTokenCount", 0),
                     "input_tokens_details": {"cached_tokens": u.get("cachedContentTokenCount", 0)},
                     "output_tokens": u.get("candidatesTokenCount", 0) + u.get("thoughtsTokenCount", 0),
                     "output_tokens_details": {"reasoning_tokens": u.get("thoughtsTokenCount", 0)}}
            model = ev.get("modelVersion")
        elif ev.get("type") == "message_start":
            usage.update(ev["message"].get("usage") or {})
            model = ev["message"].get("model")
        elif ev.get("type") == "message_delta":
            usage.update({k: v for k, v in (ev.get("usage") or {}).items() if v is not None})
        else:
            r = ev.get("response", ev)
            if r.get("usage"):
                usage, model = dict(r["usage"]), r.get("model")
    with open(LOG, "a") as f:
        f.write(json.dumps({"t": time.time(), "path": path, "status": status,
                            "secs": round(secs, 2), "model": model, "usage": usage or None,
                            "keys": keys, "error": tail[:300].decode("utf-8", "replace") if status >= 400 else None}) + "\n")


class Server(socketserver.ThreadingMixIn, socketserver.UnixStreamServer):
    daemon_threads = True


if __name__ == "__main__":
    if not UPSTREAM.netloc:
        raise SystemExit("set BENCH_UPSTREAM to the upstream base URL")
    sock, LOG = sys.argv[1], sys.argv[2]
    if os.path.exists(sock):
        os.unlink(sock)
    Server(sock, Handler).serve_forever()
