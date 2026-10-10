"""Run one model on one task in the sandbox and grade the result.

  python3 harness/run.py <task> <model> [--effort high] [--minutes 40]

The container has no network. Its only way out is a unix socket to
harness/proxy.py on the host, which holds the API keys. It sees the task
workspace, the h5i-app skill, H5iAppLib and the Lean toolchain, nothing else.

harness/proxy.py and harness/billing.py are the host's copies of
proxy.example.py and billing.example.py. billing.Meter(model, usage_log) is
created before a run; its cost() is the run's cost in USD.
"""
import argparse, shlex, json, os, re, shutil, subprocess, sys, tempfile, time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import bench, billing

ROOT = bench.ROOT
CODEX = Path.home() / ".codex/packages/standalone/current/bin/codex"
CLAUDE = Path(os.path.realpath(Path.home() / ".local/bin/claude"))
GEMINI_JS = "/opt/gemini-cli/lib/node_modules/@google/gemini-cli/bundle/gemini.js"

PROMPT = """Read TASK.md in the current directory and complete it. Use the h5i-app skill.
Work until `cd proofs && lake build` succeeds with no `sorry` in Solution.lean."""
NUDGE = """You stopped, but the task is not finished: Solution.lean still has `sorry` or does not build.
Continue working until `cd proofs && lake build` succeeds with no `sorry` in Solution.lean."""
RESUME_MIN_S = 120
PROTOCOL = 2  # 1: one session; 2: one resume when the agent stops early


def codex_config(model, effort):
    return f"""model = "{model}"
model_provider = "bench"
model_reasoning_effort = "{effort}"
model_context_window = 200000
web_search = "disabled"
approval_policy = "never"
sandbox_mode = "danger-full-access"

[model_providers.bench]
name = "bench"
base_url = "http://127.0.0.1:4000/v1"
env_key = "BENCH_KEY"
wire_api = "responses"
request_max_retries = 4
stream_max_retries = 4
stream_idle_timeout_ms = 900000

[projects."/work/task"]
trust_level = "trusted"
"""


def gemini_settings():
    # Web tools would run on Google's side, outside the sandbox.
    return {"security": {"auth": {"selectedType": "gemini-api-key"}},
            "tools": {"exclude": ["google_web_search", "web_fetch"]},
            "general": {"disableAutoUpdate": True, "disableUpdateNag": True},
            "privacy": {"usageStatisticsEnabled": False},
            "telemetry": {"enabled": False}}


def run_name(task, model, agent):
    """codex and claude runs keep the old names; other agents add a suffix."""
    return f"{task}-{model.replace('/', '_')}" + ("" if agent in ("codex", "claude") else f"-{agent}")


def is_lake(cmd):
    """A Lean check: `lake build`, `lake env lean F.lean` or `lean F.lean`."""
    return re.search(r"\blake\s+(build|env)\b|(^|[\s;&|'\"])lean\s+\S+\.lean", cmd) is not None


def lake_stats(runs):
    """`runs` is (exit code, output) per Lean check. Models often pipe the build
    through `tail` or `grep`, which hides the exit code, so a run counts as
    failed when it exits nonzero or prints a Lean error. A run is clean when
    it did not fail and shows the build finishing with no `sorry`; a filtered
    output that shows neither counts as unknown, not clean."""
    failed = [code != 0 or re.search(r"(^|\s)error(:|\b)", out) is not None for code, out in runs]
    clean = [not f and "Build completed successfully" in out and "sorry" not in out
             for f, (_, out) in zip(failed, runs)]
    return {"lake_runs": len(runs),
            "lake_failures": sum(failed),
            "lake_first_clean": next((i + 1 for i, ok in enumerate(clean) if ok), None)}


def summarize(events_path):
    """Commands, lake builds and token totals from codex's JSON events."""
    cmds, usage, turns, lake = [], {}, 0, []
    t_first_ok = None
    for line in events_path.read_text().splitlines():
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "turn.completed":
            turns += 1
            for k, v in (ev.get("usage") or {}).items():
                usage[k] = usage.get(k, 0) + v
        item = ev.get("item") or {}
        if ev.get("type") == "item.completed" and item.get("type") == "command_execution":
            c = item.get("command", "")
            cmds.append(c)
            if is_lake(c):
                lake.append((item.get("exit_code"), item.get("aggregated_output", "")))
    return {"commands": len(cmds), "turns": turns, "usage": usage, **lake_stats(lake)}


def summarize_claude(events_path):
    """The same summary from Claude Code's stream-json output."""
    cmds, lake, usage, turns, cost = {}, [], {}, 0, None
    for line in events_path.read_text().splitlines():
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        content = (ev.get("message") or {}).get("content")
        if ev.get("type") == "assistant" and isinstance(content, list):
            for c in content:
                if c.get("type") == "tool_use" and c.get("name") == "Bash":
                    cmds[c["id"]] = c["input"].get("command", "")
        if ev.get("type") == "user" and isinstance(content, list):
            for c in content:
                cmd = cmds.get(c.get("tool_use_id"))
                if c.get("type") == "tool_result" and cmd and is_lake(cmd):
                    out = c.get("content")
                    out = out if isinstance(out, str) else json.dumps(out)
                    lake.append((1 if c.get("is_error") else 0, out))
        if ev.get("type") == "result":
            turns += ev.get("num_turns", 0)
            for k, v in (ev.get("usage") or {}).items():
                if isinstance(v, int):
                    usage[k] = usage.get(k, 0) + v
            cost = (cost or 0) + (ev.get("total_cost_usd") or 0)
    return {"commands": len(cmds), **lake_stats(lake), "turns": turns, "usage": {k: v for k, v in usage.items() if isinstance(v, int)},
            "agent_reported_cost": cost}


def summarize_gemini(events_path):
    """The same summary from gemini-cli's stream-json output."""
    cmds, lake, usage, turns = {}, [], {}, 0
    for line in events_path.read_text().splitlines():
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "tool_use" and ev.get("tool_name") == "run_shell_command":
            cmds[ev.get("tool_id")] = (ev.get("parameters") or {}).get("command", "")
        if ev.get("type") == "tool_result" and is_lake(cmds.get(ev.get("tool_id"), "")):
            out = ev.get("output") or json.dumps(ev.get("error") or "")
            code = re.search(r"Exit Code: (-?\d+)", out)
            lake.append((int(code.group(1)) if code else int(ev.get("status") != "success"), out))
        if ev.get("type") == "result":
            turns += 1
            for k, v in (ev.get("stats") or {}).items():
                if isinstance(v, int):
                    usage[k] = usage.get(k, 0) + v
    return {"commands": len(cmds), "turns": turns, "usage": usage, **lake_stats(lake)}


def slim(run):
    """Drop what can be rebuilt or is not read later: Lean build output, the
    skill copy and codex's SQLite state. Transcripts are gzipped."""
    shutil.rmtree(run / "workspace/proofs/.lake/build", ignore_errors=True)
    home = run / "agent"
    for p in [*home.glob("*.sqlite*"), home / "skills", home / ".claude/skills", home / "tmp"]:
        shutil.rmtree(p, ignore_errors=True) if p.is_dir() else p.unlink(missing_ok=True)
    for p in home.rglob("*.jsonl"):
        subprocess.run(["gzip", "-f", str(p)])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("task")
    ap.add_argument("model")
    ap.add_argument("--effort", default="high")
    ap.add_argument("--minutes", type=int, default=40)
    ap.add_argument("--agent", choices=["codex", "claude", "gemini"], default="codex")
    a = ap.parse_args()

    stamp = time.strftime("%Y%m%d-%H%M%S")
    run = ROOT / "results/runs" / f"{stamp}-{run_name(a.task, a.model, a.agent)}"
    ws, home = run / "workspace", run / "agent"
    # AF_UNIX paths are limited to 108 bytes.
    sock = Path(tempfile.mkdtemp(prefix="h5iab-"))
    shutil.copytree(ROOT / "tasks" / a.task / "workspace", ws, symlinks=True)
    relay = "socat TCP-LISTEN:4000,fork,reuseaddr,bind=127.0.0.1 UNIX-CONNECT:/run/llm/llm.sock & sleep 0.5; "
    out = "< /dev/null >> /work/agent/events.jsonl 2>> /work/agent/stderr.txt; echo exit=$? >> /work/agent/stderr.txt"
    if a.agent == "codex":
        shutil.copytree(ROOT / "skill", home / "skills")
        (home / "config.toml").write_text(codex_config(a.model, a.effort))
        start = f"codex exec --json --skip-git-repo-check -C /work/task {shlex.quote(PROMPT)}"
        again = f"cd /work/task && codex exec resume --last --json --skip-git-repo-check {shlex.quote(NUDGE)}"
        env = {"CODEX_HOME": "/work/agent", "BENCH_KEY": "unused"}
        # Recent codex runs tools through a helper next to its binary.
        host = CODEX.with_name("codex-code-mode-host")
        mounts = ["-v", f"{CODEX}:/opt/codex/codex:ro",
                  *(["-v", f"{host}:/opt/codex/codex-code-mode-host:ro"] if host.exists() else [])]
    elif a.agent == "gemini":
        # A Node install and an npm prefix holding @google/gemini-cli.
        node, cli = os.environ.get("BENCH_NODE"), os.environ.get("BENCH_GEMINI_CLI")
        if not (node and cli):
            raise SystemExit("gemini needs BENCH_NODE (a Node install) and BENCH_GEMINI_CLI "
                             "(an npm prefix with @google/gemini-cli)")
        shutil.copytree(ROOT / "skill", home / ".gemini/skills")
        (home / ".gemini/settings.json").write_text(json.dumps(gemini_settings(), indent=1))
        gemini = f"PATH=/opt/node/bin:$PATH /opt/node/bin/node {GEMINI_JS}"
        flags = f"--model {a.model} --output-format stream-json --yolo --skip-trust"
        start = f"cd /work/task && {gemini} --prompt {shlex.quote(PROMPT)} {flags}"
        again = f"cd /work/task && {gemini} --resume latest --prompt {shlex.quote(NUDGE)} {flags}"
        # proxy.py replaces the dummy key.
        env = {"HOME": "/work/agent", "GEMINI_API_KEY": "unused", "GOOGLE_GEMINI_BASE_URL": "http://127.0.0.1:4000"}
        mounts = ["-v", f"{node}:/opt/node:ro", "-v", f"{cli}:/opt/gemini-cli:ro"]
    else:
        shutil.copytree(ROOT / "skill", home / ".claude/skills")
        flags = (f"--model {a.model} --output-format stream-json --verbose "
                 f"--dangerously-skip-permissions --disallowedTools WebSearch WebFetch")
        start = f"cd /work/task && claude -p {shlex.quote(PROMPT)} {flags}"
        again = f"cd /work/task && claude -p --continue {shlex.quote(NUDGE)} {flags}"
        env = {"HOME": "/work/agent", "IS_SANDBOX": "1", "ANTHROPIC_BASE_URL": "http://127.0.0.1:4000",
               "ANTHROPIC_API_KEY": "unused", "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
               "DISABLE_AUTOUPDATER": "1", "ANTHROPIC_DEFAULT_HAIKU_MODEL": a.model,
               "CLAUDE_CODE_EFFORT_LEVEL": a.effort}
        mounts = ["-v", f"{CLAUDE}:/opt/codex/claude:ro"]
    # An agent that stops with time left and the proof unfinished is resumed
    # once, for every model alike; `resumes` in the result records it.
    unfinished = "(grep -q sorry proofs/Solution.lean || ! (cd proofs && lake build > /dev/null 2>&1))"
    inner = (f"end=$(( $(date +%s) + {a.minutes * 60} )); timeout {a.minutes * 60} sh -c {shlex.quote(start)} {out}; "
             f"cd /work/task; left=$(( end - $(date +%s) )); "
             f"if [ $left -gt {RESUME_MIN_S} ] && {unfinished}; then echo 1 > /work/agent/resumed; "
             f"left=$(( end - $(date +%s) )); timeout $left sh -c {shlex.quote(again)} {out}; fi")
    meter = billing.Meter(a.model, run / "usage.jsonl")
    proxy = subprocess.Popen([sys.executable, str(ROOT / "harness/proxy.py"),
                              str(sock / "llm.sock"), str(run / "usage.jsonl")])
    time.sleep(1)
    t0 = time.time()
    try:
        bench.docker(ws, relay + inner, extra=[
            "-v", f"{home}:/work/agent", "-v", f"{sock}:/run/llm", *mounts,
            *[x for k, v in env.items() for x in ("-e", f"{k}={v}")]])
    finally:
        wall = time.time() - t0
        proxy.terminate()
        shutil.rmtree(sock, ignore_errors=True)

    template = (ROOT / "tasks" / a.task / "workspace/proofs/Solution.lean").read_text()
    grade = bench.grade(a.task, ws / "proofs/Solution.lean")
    grade["proof_loc"] = grade["solution_loc"] - bench.code_lines(template.splitlines()) + 1
    meta = json.loads((ROOT / "tasks" / a.task / "meta.json").read_text())
    summary = {"codex": summarize, "claude": summarize_claude, "gemini": summarize_gemini}[a.agent](home / "events.jsonl")
    skill = subprocess.run("find skill -type f | sort | xargs sha256sum | sha256sum", shell=True,
                           cwd=ROOT, capture_output=True, text=True).stdout[:12]
    res = {"task": a.task, "model": a.model, "agent": a.agent, "effort": a.effort, "skill": skill, "protocol": PROTOCOL,
           "resumes": int((home / "resumed").exists()), "wall_s": round(wall, 1),
           "cost_usd": meter.cost(), **summary,
           "infra_error": summary["turns"] == 0 and summary["commands"] == 0,
           "grade": grade, "ref_proof_loc": meta["ref_proof_loc"]}
    (run / "result.json").write_text(json.dumps(res, indent=1) + "\n")
    slim(run)
    print(json.dumps({k: v for k, v in res.items() if k != "grade"} | {
        "passed": grade["passed"], "reason": grade.get("reason"), "proof_loc": grade["proof_loc"]}))


if __name__ == "__main__":
    main()
