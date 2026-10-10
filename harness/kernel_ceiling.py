"""Estimate how much of each upstream scope could be an h5i-app kernel.

  python3 harness/kernel_ceiling.py [--app nora ...]

A kernel is pure, synchronous and deterministic: no I/O, async, database,
network, filesystem, clock, randomness, environment, threads, locks or
global mutable state, and no unsafe or FFI. Representation changes are
allowed, since ports rewrite strings to bytes and iterators to loops.

Each non-test function and data item of the pinned scope (the same scope as
source_inventory.py) is classified:

- shell: its body or type uses a shell marker below, or it calls a crate
  function that is shell (to a fixpoint). Calls resolve by name: `Ty::f` to
  methods of `Ty`, `f(..)` to free functions, `.f(..)` to every crate method
  named `f` unless `f` is a common std name.
- kernel-eligible: everything else.

The ceiling is the eligible lines; lines are counted as dashboard.py counts
them (no blanks, comments or attributes). Name-based resolution and the
marker lists make this an estimate: it errs toward shell when a common
method name hides an effectful callee, and toward kernel when an effect is
hidden behind a trait object or an unlisted crate.
Writes results/source-coverage/kernel-ceiling.json, and every item's
classification to kernel-ceiling-items.jsonl.gz for auditing.
"""
import argparse, gzip, io, json, subprocess, tarfile, tempfile
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

from source_inventory import SOURCES

ROOT = Path(__file__).resolve().parent.parent
TOOL = ROOT / "harness/kernel-ceiling"

# Identifiers that put an item in the shell.
SHELL_IDENTS = {
    # async runtimes and web/IO stacks
    "tokio", "async_std", "futures", "async_trait", "hyper", "axum", "tower", "tower_http", "actix_web",
    "reqwest", "tonic", "ruma_client", "Stream", "StreamExt", "Future",
    # databases and storage
    "sqlx", "PgPool", "PgConnection", "Postgres", "rusqlite", "diesel", "sea_orm", "deadpool", "bb8",
    "redis", "rocksdb", "Database", "Engine", "opendal", "aws_sdk_s3", "object_store",
    "BackendReadTransaction", "BackendWriteTransaction", "IdlSqlite", "IdlArcSqlite", "be_txn", "get_be_txn",
    # filesystem, network, processes, environment
    "fs", "File", "OpenOptions", "read_dir", "TcpStream", "TcpListener", "UdpSocket", "Command", "Stdio",
    "lettre", "ldap3", "env", "var_os",
    # clock and randomness
    "SystemTime", "Instant", "thread_rng", "OsRng", "rand", "getrandom", "new_v4", "now_v7",
    # threads, locks, global state
    "thread", "Mutex", "RwLock", "Condvar", "OnceLock", "OnceCell",
    "AtomicBool", "AtomicU8", "AtomicU16", "AtomicU32", "AtomicU64", "AtomicUsize", "AtomicI32", "AtomicI64",
    "mpsc", "broadcast", "oneshot", "watch", "Notify", "Semaphore",
}
# Identifier prefixes: backend handles named after their engine.
SHELL_PREFIXES = ("IdlArcSqlite", "IdlSqlite", "Pg", "Sqlite", "Redis", "S3Client", "HttpClient")
# Lazily initialized statics (`LazyLock`, `lazy_static!`) are deterministic
# constants, so they are not shell markers by themselves.
# `X::now()`, `X::new_v4()` and friends.
SHELL_CALLS = {("Utc", "now"), ("Local", "now"), ("OffsetDateTime", "now_utc"), ("Timestamp", "now"),
               ("Uuid", "new_v4"), ("Uuid", "now_v7"), ("", "spawn"), ("", "sleep")}
SHELL_METHODS = {"lock", "try_lock", "spawn", "await"}
# Method names too common to resolve to one crate function.
COMMON = set("""new default clone fmt eq ne cmp partial_cmp hash from into try_from try_into as_ref as_mut
deref deref_mut drop to_string to_owned len is_empty get get_mut insert remove push pop contains iter
iter_mut into_iter map filter collect next unwrap expect ok err is_some is_none is_ok is_err and_then
or_else unwrap_or unwrap_or_default unwrap_or_else map_err extend append clear first last keys values
entry starts_with ends_with split trim parse as_str as_bytes to_vec join find any all count sum max min
sort sort_by dedup retain chars bytes lines write read send recv build finish serialize deserialize
validate check run execute handle process apply update create delete open close flush with capacity
or and xor is_some_and is_none_or is_ok_and take replace map_or map_or_else filter_map flat_map fold zip
rev skip chain cloned copied as_deref split_once rsplit_once to_lowercase to_uppercase contains_key
get_or_insert_with or_insert or_default ok_or ok_or_else then then_some position windows chunks peekable
enumerate take_while skip_while last_mut split_at strip_prefix strip_suffix trim_start trim_end""".split())


def code_lines(lines):
    """Lines without blanks, comments and attributes, as dashboard.py counts."""
    n, block = 0, False
    for line in lines:
        t = line.strip()
        if block or t.startswith("/*"):
            block = "*/" not in t
            continue
        if t and not t.startswith(("//", "#[", "#![")):
            n += 1
    return n


def is_test_path(path):
    parts = Path(path).parts
    name = parts[-1]
    return (any(p in ("tests", "benches", "test", "testkit") for p in parts[:-1])
            or name in ("tests.rs", "test.rs") or name.endswith(("_tests.rs", "_test.rs")) or name.startswith("test_"))


def classify(items):
    """Mark each item shell or kernel; returns the list of shell reasons per item."""
    fns = [i for i in items if i["kind"] in ("fn", "method")]
    by_name, by_ty = defaultdict(list), defaultdict(list)
    for i, f in enumerate(fns):
        by_name[f["name"]].append(i)
        if f["self_ty"]:
            by_ty[(f["self_ty"], f["name"])].append(i)
    free = {n: [i for i in ids if fns[i]["kind"] == "fn"] for n, ids in by_name.items()}

    for f in items:
        idents = set(f.get("idents", []))
        reasons = []
        if f.get("async") or f.get("await"):
            reasons.append("async")
        if f.get("unsafe") or f["kind"] == "static_mut":
            reasons.append("unsafe")
        if hit := sorted((idents & SHELL_IDENTS) | {i for i in idents if i.startswith(SHELL_PREFIXES)}):
            reasons.append("uses " + ", ".join(hit[:4]))
        if hit := [c for c in map(tuple, f.get("calls", [])) if c in SHELL_CALLS or ("", c[1]) in SHELL_CALLS]:
            reasons.append("calls " + ", ".join("::".join(x for x in c if x) for c in hit[:3]))
        if hit := sorted(set(f.get("methods", [])) & SHELL_METHODS):
            reasons.append("." + ", .".join(hit))
        f["reasons"] = reasons

    callees = []
    for f in fns:
        out = set()
        for ty, name in map(tuple, f.get("calls", [])):
            if ty and (ty, name) in by_ty:
                out.update(by_ty[(ty, name)])
            elif not ty or ty in ("self", "Self", "super", "crate"):
                out.update(free.get(name) or by_ty.get((f["self_ty"], name), []))
        for m in f.get("methods", []):
            if m not in COMMON:
                out.update(by_name.get(m, []))
        callees.append(out)

    changed = True
    while changed:
        changed = False
        for i, f in enumerate(fns):
            if f["reasons"]:
                continue
            bad = next((j for j in callees[i] if fns[j]["reasons"]), None)
            if bad is not None:
                g = fns[bad]
                f["reasons"] = [f"calls shell {g['self_ty'] + '::' if g['self_ty'] else ''}{g['name']}"]
                changed = True


def analyze(app, pin, scope):
    repo = ROOT / "results/upstream" / f"{app}.git"
    rev = subprocess.check_output(["git", "-C", repo, "rev-parse", pin], text=True).strip()
    with tempfile.TemporaryDirectory(dir=Path("/dev/shm") if Path("/dev/shm").is_dir() else None) as tmp:
        data = subprocess.check_output(["git", "-C", repo, "archive", rev, scope])
        tarfile.open(fileobj=io.BytesIO(data)).extractall(tmp, filter="data")
        out = subprocess.run([TOOL / "target/release/kernel-ceiling", tmp], capture_output=True, text=True, check=True)
        texts = {str(p.relative_to(tmp)): p.read_text(errors="replace").splitlines() for p in Path(tmp).rglob("*.rs")}
    rows = [json.loads(l) for l in out.stdout.splitlines()]
    errors = [r for r in rows if r["kind"] == "parse_error"]
    items = [r for r in rows if r["kind"] != "parse_error" and not r["test"] and not is_test_path(r["file"])]
    test_items = [r for r in rows if r["kind"] != "parse_error" and (r["test"] or is_test_path(r["file"]))]
    for r in items + test_items:
        r["loc"] = code_lines(texts[r["file"]][r["start"] - 1:r["end"]])
    classify(items)
    total = sum(code_lines(t) for f, t in texts.items() if not is_test_path(f)) - sum(
        r["loc"] for r in test_items if not is_test_path(r["file"]))
    fn = [r for r in items if r["kind"] in ("fn", "method")]
    dat = [r for r in items if r["kind"] not in ("fn", "method")]
    kern = lambda rs: sum(r["loc"] for r in rs if not r["reasons"])
    reasons = defaultdict(int)
    for r in items:
        if r["reasons"]:
            key = r["reasons"][0].split(" ")[0] if not r["reasons"][0].startswith("uses") else r["reasons"][0]
            reasons["transitive" if key == "calls" and "shell" in r["reasons"][0] else key] += r["loc"]
    row = {"app": app, "upstream_revision": rev, "scope": scope,
           "counting_convention": "code lines: no blanks, comments or attributes; tests excluded",
           "parse_errors": [e["file"] for e in errors],
           "code_lines": total, "fn_lines": sum(r["loc"] for r in fn), "data_lines": sum(r["loc"] for r in dat),
           "kernel_fn_lines": kern(fn), "kernel_data_lines": kern(dat),
           "kernel_ceiling_lines": kern(items),
           "functions": len(fn), "kernel_functions": sum(not r["reasons"] for r in fn),
           "shell_lines_by_reason": dict(sorted(reasons.items(), key=lambda kv: -kv[1])[:15])}
    row["items"] = [{k: r[k] for k in ("file", "kind", "name", "self_ty", "start", "end", "loc", "reasons")} for r in items]
    return row


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--app", nargs="+", choices=SOURCES, default=list(SOURCES))
    a = ap.parse_args()
    subprocess.run(["cargo", "build", "--release", "--offline", "-q"], cwd=TOOL, check=True)
    rows = []
    for app in a.app:
        pin, scope = SOURCES[app]
        row = analyze(app, pin, scope)
        rows.append(row)
        print(f"{app}: ceiling {row['kernel_ceiling_lines']:,} of {row['code_lines']:,} code lines "
              f"({row['kernel_ceiling_lines'] / max(1, row['code_lines']):.0%}); "
              f"{row['kernel_functions']}/{row['functions']} functions", flush=True)
    out = ROOT / "results/source-coverage"
    with gzip.open(out / "kernel-ceiling-items.jsonl.gz", "wt") as f:
        for row in rows:
            for item in row["items"]:
                f.write(json.dumps({"app": row["app"], **item}) + "\n")
    for row in rows:
        del row["items"]
    (out / "kernel-ceiling.json").write_text(json.dumps({"timestamp": datetime.now(timezone.utc).isoformat(),
                                                         "method": __doc__.strip(), "apps": rows}, indent=1) + "\n")


if __name__ == "__main__":
    main()
