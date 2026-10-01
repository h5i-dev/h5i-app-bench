"""Build tasks, validate them against the reference proofs, and grade solutions.

  python3 harness/bench.py build [ids...]   # tasks/<id>/{workspace,meta.json}
  python3 harness/bench.py grade <id> <Solution.lean>
"""
import json, os, re, shutil, subprocess, sys, tempfile, time, tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHECKOUTS = {"h5i": Path.home() / "Dev/h5i", "bench": ROOT}
LEAN = Path.home() / ".elan/toolchains/leanprover--lean4---v4.31.0"
PACKAGES = CHECKOUTS["h5i"] / "examples/app/docs/proofs/.lake/packages"
APPLIB = ROOT / "env/h5i-app-lib"
IMAGE = "h5i-app-bench:0"
STD_AXIOMS = {"propext", "Classical.choice", "Quot.sound"}
AENEAS_REQ = ('require aeneas from git\n  "https://github.com/AeneasVerif/aeneas" @ '
              '"b86120db3183b0107eb5f2637b11c424cd06ef1c" / "backends/lean"\n')
# Things a solution may not contain: commands that add axioms or run code
# (matched at the start of a line, so kernel names like `mfa.initialize`
# pass), command elaborators, and names that add declarations past the kernel
# or bypass its check. Tactic and term `elab`s are fine: the kernel still
# checks what they build, and `#print axioms` catches `sorry`.
FORBIDDEN = re.compile(r"^\s*(?:@\[[^\]]*\]\s*)?(?:(?:private|protected|noncomputable|partial|unsafe)\s+)*"
                       r"(axiom|opaque|run_cmd|run_elab|run_meta|#eval|initialize|builtin_initialize)\b"
                       r"|^\s*(?:elab|elab_rules|macro_rules|syntax)\b[^\n]*:\s*command\b"
                       r"|\b(unsafe|implemented_by|extern|skipKernelTC|addDecl|addDeclWithoutChecking|Kernel|Environment)\b", re.M)


def tasks(extra=True):
    """The benchmark's tasks, and with `extra` those kept out of it."""
    files = ["tasks.toml"] + (["extra.toml"] if extra else [])
    return {t["id"]: t for f in files if (ROOT / "dataset" / f).exists()
            for t in tomllib.loads((ROOT / "dataset" / f).read_text())["task"]}


def docker(workdir, cmd, network=False, extra=()):
    # Rootless docker: root in the container is the host user.
    args = ["docker", "run", "--rm",
            "-v", f"{LEAN}:/opt/lean:ro", "-v", f"{PACKAGES}:/opt/lake/packages:ro",
            "-v", f"{APPLIB}:/opt/h5i-app-lib:ro", "-v", f"{workdir}:/work/task",
            "--tmpfs", "/work/home", *extra]
    if not network:
        args += ["--network", "none"]
    return subprocess.run(args + [IMAGE, "bash", "-lc", cmd], capture_output=True, text=True)


def src_dir(t):
    co, rel = t["src"].split(":", 1)
    return CHECKOUTS[co] / rel


def statement(t):
    """The theorem's binders and type, copied from the reference file."""
    text = (src_dir(t) / "proofs" / f"{t['module']}.lean").read_text()
    name = t["theorem"].rsplit(".", 1)[1]
    m = re.search(rf"^theorem {re.escape(name)}\b(.*?)\s:=(?:\s|$)", text, re.S | re.M)
    if not m:
        raise SystemExit(f"{t['id']}: statement of {name} not found")
    return m.group(1).rstrip()


def opens(t):
    return f"open Aeneas Aeneas.Std Result {t['ns']} {t['ns']}.Spec H5iAppLib"


def generated_modules(t):
    return sorted(p.stem for p in (src_dir(t) / "proofs/generated").glob("*.lean"))


def lakefile(t, roots):
    gen = ", ".join(f"`{m}" for m in generated_modules(t))
    rs = ", ".join(f"`{r}" for r in roots)
    return ("import Lake\nopen Lake DSL\n\n" + AENEAS_REQ +
            'require h5i_app_lib from "/opt/h5i-app-lib"\n\npackage bench_task\n\n'
            f'lean_lib Generated where\n  srcDir := "generated"\n  roots := #[{gen}]\n\n'
            f"@[default_target] lean_lib Proofs where\n  roots := #[{rs}]\n")


def manifest(t):
    m = json.loads((src_dir(t) / "proofs/lake-manifest.json").read_text())
    m["name"] = "bench_task"
    for p in m["packages"]:
        if p["name"] == "h5i_app_lib":
            p["dir"] = "/opt/h5i-app-lib"
    return json.dumps(m, indent=1) + "\n"


def solution_template(t):
    name = t["theorem"].rsplit(".", 1)[1]
    imports = "".join(f"import {Path(g).stem}\n" for g in t["given"])
    return (f"{imports}import H5iAppLib\n{opens(t)}\n\nnamespace {t['ns']}.Solution\n\n"
            f"theorem {name}{statement(t)} := by\n  sorry\n\nend {t['ns']}.Solution\n")


def check_file(t, module, full):
    """Checks that `full` has the task's statement, then prints its axioms."""
    return (f"import {module}\nimport H5iAppLib\n{opens(t)}\n\n"
            f"namespace H5iAppBench\naxiom target{statement(t)}\nend H5iAppBench\n\n"
            "open Lean Meta Elab Command in\nrun_cmd liftTermElabM do\n"
            "  let env ← getEnv\n"
            "  let some a := env.find? `H5iAppBench.target | throwError \"no target\"\n"
            f"  let some b := env.find? `{full} | throwError \"MISSING {full}\"\n"
            "  unless b matches .thmInfo _ do throwError \"NOT_A_THEOREM\"\n"
            "  unless ← isDefEq a.type b.type do throwError \"STATEMENT_MISMATCH\"\n"
            "  logInfo \"STATEMENT_OK\"\n\n"
            f"#print axioms {full}\n")


def loc_file(t, full, hand):
    """Lists hand-written declarations the reference proof depends on."""
    mods = ", ".join(f"`{m}" for m in hand)
    return (f"import {t['module']}\n\nopen Lean Elab Command in\nrun_cmd do\n"
            "  let env ← getEnv\n"
            f"  let hand : List Name := [{mods}]\n"
            f"  let mut todo := #[`{full}]\n  let mut seen : NameSet := {{}}\n"
            "  while h : todo.size > 0 do\n"
            "    let n := todo.back; todo := todo.pop\n"
            "    if seen.contains n then continue\n"
            "    seen := seen.insert n\n"
            "    let some ci := env.find? n | continue\n"
            "    let some idx := env.getModuleIdxFor? n | continue\n"
            "    let mod := env.header.moduleNames[idx.toNat]!\n"
            "    unless hand.contains mod do continue\n"
            "    if let some r ← findDeclarationRanges? n then\n"
            "      logInfo m!\"DECL {mod} {n} {r.range.pos.line} {r.range.endPos.line}\"\n"
            "    for c in ci.getUsedConstantsAsSet do todo := todo.push c\n")


def code_lines(lines):
    """Non-blank lines outside comments."""
    n, depth = 0, 0
    for line in lines:
        s = line.strip()
        if depth:
            depth += s.count("/-") - s.count("-/")
            continue
        if s.startswith("/-"):
            depth = s.count("/-") - s.count("-/")
            continue
        if s and not s.startswith("--"):
            n += 1
    return n


def infos(out, tag):
    return [l for l in out.splitlines() if tag in l]


def build(tid):
    t = tasks()[tid]
    src = src_dir(t)
    out = ROOT / "tasks" / tid
    ws = out / "workspace"
    if out.exists():
        shutil.rmtree(out)
    (ws / "proofs/generated").mkdir(parents=True)
    shutil.copytree(src / "kernel/src", ws / "kernel/src")
    shutil.copy(src / "kernel/Cargo.toml", ws / "kernel/Cargo.toml")
    for g in (src / "proofs/generated").glob("*.lean"):
        shutil.copy(g, ws / "proofs/generated" / g.name)
    for g in t["given"]:
        shutil.copy(src / "proofs" / g, ws / "proofs" / g)
    shutil.copy(src / "proofs/lean-toolchain", ws / "proofs/lean-toolchain")
    given = [Path(g).stem for g in t["given"]]
    (ws / "proofs/lakefile.lean").write_text(lakefile(t, given + ["Solution"]))
    (ws / "proofs/lake-manifest.json").write_text(manifest(t))
    (ws / "proofs/Solution.lean").write_text(solution_template(t))
    (ws / "proofs/.lake").mkdir()
    os.symlink("/opt/lake/packages", ws / "proofs/.lake/packages")
    (ws / "TASK.md").write_text(task_md(t))

    # Prebuild generated code and the spec so that timings measure the proof.
    t0 = time.time()
    r = docker(ws, "cd proofs && lake build 2>&1")
    prebuild = time.time() - t0
    if r.returncode or "declaration uses `sorry`" not in r.stdout:
        raise SystemExit(f"{tid}: template build failed\n{r.stdout[-3000:]}{r.stderr[-2000:]}")

    # Most tasks have no reference proof: the statement is backed by the
    # port's falsification tests, and a task no model solves is reviewed.
    ref = validate_reference(t) if t.get("reference", False) else {"ref_proof_loc": None}
    meta = {"id": tid, "repo": t["repo"], "property": t["property"], "theorem": t["theorem"],
            "src": t["src"], "rust_loc": sum(code_lines(f.read_text().splitlines()) for f in (src / "kernel/src").glob("*.rs")),
            "generated_lean_loc": sum(code_lines(g.read_text().splitlines())
                                      for g in (src / "proofs/generated").glob("*.lean")),
            "spec_loc": sum(code_lines((src / "proofs" / g).read_text().splitlines()) for g in t["given"]),
            "prebuild_s": round(prebuild, 1), **ref}
    (out / "meta.json").write_text(json.dumps(meta, indent=1) + "\n")
    print(json.dumps(meta))


def validate_reference(t):
    """Grade the reference proof and measure its size."""
    src = src_dir(t) / "proofs"
    hand = sorted(p.stem for p in src.glob("*.lean")
                  if p.stem not in ("lakefile",) and p.name not in t["given"])
    with tempfile.TemporaryDirectory(dir=ROOT / "results") as d:
        d = Path(d)
        shutil.copytree(src, d, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".lake"))
        (d / ".lake").mkdir()
        os.symlink("/opt/lake/packages", d / ".lake/packages")
        (d / "lakefile.lean").write_text(lakefile(t, [Path(g).stem for g in t["given"]] + hand + ["Check", "Loc"]))
        (d / "lake-manifest.json").write_text(manifest(t))
        (d / "Check.lean").write_text(check_file(t, t["module"], t["theorem"]))
        (d / "Loc.lean").write_text(loc_file(t, t["theorem"], hand))
        r = docker(d, "lake build 2>&1")
        log = r.stdout
        if "STATEMENT_OK" not in log or r.returncode:
            raise SystemExit(f"{t['id']}: reference check failed\n{log[-4000:]}")
        spans = {}
        for l in infos(log, "DECL "):
            mod, name, a, b = l.split("DECL ", 1)[1].split()[:4]
            spans.setdefault(mod, set()).update(range(int(a), int(b) + 1))
        loc, decls = 0, 0
        for mod, lines in spans.items():
            text = (src / f"{mod}.lean").read_text().splitlines()
            loc += code_lines([text[i - 1] for i in sorted(lines) if i <= len(text)])
        decls = len(infos(log, "DECL "))
        return {"ref_proof_loc": loc, "ref_decls": decls, "ref_axioms": axioms(log)}


def axioms(log):
    m = re.search(r"depends on axioms: \[(.*?)\]", log, re.S)
    if m:
        return sorted(a.strip() for a in m.group(1).split(","))
    return [] if "does not depend on any axioms" in log else None


def task_md(t):
    name = t["theorem"].rsplit(".", 1)[1]
    return f"""# Task: {t['id']}

Repository: {t['repo']}, ported to an h5i-app kernel in `kernel/src/lib.rs`.
The kernel is extracted to Lean by Aeneas in `proofs/generated/` (do not edit).
`proofs/Spec.lean` states the policy in plain Lean.

Property: {t['property']}

Replace the `sorry` in `proofs/Solution.lean` with a proof of `{t['ns']}.Solution.{name}`.
Do not change the theorem's name or statement. You may add lemmas and definitions
above it in `Solution.lean`; only that file is graded. Do not use `sorry`, `axiom`,
`native_decide` or other unsafe features.

Check your work with `cd proofs && lake build`. The h5i-app Lean library (`H5iAppLib`)
is at `/opt/h5i-app-lib`; the h5i-app skill explains the proof patterns.
"""


def grade(tid, solution):
    t = tasks()[tid]
    name = t["theorem"].rsplit(".", 1)[1]
    full = f"{t['ns']}.Solution.{name}"
    text = Path(solution).read_text()
    res = {"solution_loc": code_lines(text.splitlines())}
    bad = sorted({m.group(0).strip() for m in FORBIDDEN.finditer(re.sub(r"--.*|/-.*?-/", "", text, flags=re.S))})
    allowed_imports = {Path(g).stem for g in t["given"]} | set(generated_modules(t))
    imports = re.findall(r"^import\s+(\S+)", text, re.M)
    bad += [f"import {i}" for i in imports
            if i not in allowed_imports and not i.startswith(("H5iAppLib", "Aeneas", "Mathlib"))]
    if bad:
        return {**res, "passed": False, "reason": "forbidden: " + ", ".join(bad)}
    with tempfile.TemporaryDirectory(dir=ROOT / "results") as d:
        d = Path(d)
        shutil.copytree(ROOT / "tasks" / tid / "workspace", d, dirs_exist_ok=True, symlinks=True)
        (d / "proofs/Solution.lean").write_text(text)
        given = [Path(g).stem for g in t["given"]]
        (d / "proofs/lakefile.lean").write_text(lakefile(t, given + ["Solution", "Check"]))
        (d / "proofs/Check.lean").write_text(check_file(t, "Solution", full))
        t0 = time.time()
        r = docker(d, "cd proofs && timeout 900 lake build 2>&1")
        res["check_s"] = round(time.time() - t0, 1)
        log = r.stdout
    ax = axioms(log)
    res["axioms"] = ax
    if r.returncode or "STATEMENT_OK" not in log:
        reason = next((k for k in ("STATEMENT_MISMATCH", "MISSING", "NOT_A_THEOREM") if k in log), "build failed")
        return {**res, "passed": False, "reason": reason, "log_tail": log[-2000:]}
    if ax is None or not set(ax) <= STD_AXIOMS:
        return {**res, "passed": False, "reason": f"axioms {ax}"}
    return {**res, "passed": True}


if __name__ == "__main__":
    cmd, *rest = sys.argv[1:]
    if cmd == "build":
        for tid in rest or tasks(extra=False):
            build(tid)
    elif cmd == "grade":
        print(json.dumps(grade(rest[0], rest[1]), indent=1))
