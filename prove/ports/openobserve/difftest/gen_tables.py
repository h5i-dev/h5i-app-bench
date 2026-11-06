"""Generate the delegated-token route tables from openobserve's own source.

Reads `src/api/common/src/auth/delegation.rs` at the pinned commit from the
upstream checkout (ports/openobserve/upstream-src) and writes

  kernel/src/tables.rs      the tables as kernel code (Vec pushes)
  proofs/SpecTables.lean    the same tables as Lean lists, for Spec.lean

so neither is transcribed by hand. Run from ports/openobserve:

  python3 difftest/gen_tables.py [upstream checkout]
"""
import re, subprocess, sys
from pathlib import Path

COMMIT = "a7745479a44bb2dd6f3498b2b3902304600bb466"
HERE = Path(__file__).resolve().parent.parent
SRC = "src/api/common/src/auth/delegation.rs"
PART = 8


def show(repo):
    return subprocess.run(["git", "-C", repo, "show", f"{COMMIT}:{SRC}"],
                          capture_output=True, text=True, check=True).stdout


def block(src, header):
    i = src.index(header)
    j = src.index("];", i)
    return src[src.index("[", src.index("=", i)) + 1:j]


def strings(body):
    return re.findall(r'"([^"]*)"', body)


METHODS = {"GET": ["Get"], "POST": ["Post"], "GET_POST": ["Get", "Post"], "PATCH": ["Patch"]}


def routes(body):
    out = []
    for m in re.finditer(r"(v1|v2)\(&\[(.*?)\],\s*(\w+)\)", body):
        segs = []
        for s in re.split(r",\s*", m.group(2).strip()):
            if s == "Param":
                segs.append(("param", None))
            elif s == "Stream":
                segs.append(("stream", None))
            elif s == "ALERT_ID":
                segs.append(("alertId", None))
            else:
                lm = re.fullmatch(r'Lit\("([^"]*)"\)', s)
                if not lm:
                    raise SystemExit(f"unknown segment {s!r}")
                segs.append(("lit", lm.group(1)))
        out.append((m.group(1) == "v2", segs, METHODS[m.group(3)]))
    return out


def rust_routes(name, rs):
    """One function per route, and the table pushing them in upstream's order."""
    parts, fns = [], []
    for k, (v2, segs, methods) in enumerate(rs):
        fn = f"{name}_r{k}"
        fns.append(fn)
        lines = [f"fn {fn}() -> ScopeRoute {{", "    let mut s = Vec::new();"]
        for kind, lit in segs:
            lines.append({"param": "    s.push(Seg::Param);",
                          "stream": "    s.push(Seg::Stream);",
                          "alertId": "    s.push(Seg::AlertId);",
                          "lit": f'    s.push(lit(b"{lit}"));'}[kind])
        lines.append("    let mut m = Vec::new();")
        for me in methods:
            lines.append(f"    m.push(Method::{me});")
        lines.append(f"    ScopeRoute {{ v2: {str(v2).lower()}, segments: s, methods: m }}")
        lines.append("}")
        parts.append("\n".join(lines))
    calls = "\n".join(f"    out.push({fn}());" for fn in fns)
    parts.append(f"pub fn {name}() -> Vec<ScopeRoute> {{\n    let mut out = Vec::new();\n{calls}\n    out\n}}")
    return "\n\n".join(parts), fns


def rust_list(name, xs):
    body = "\n".join(f'    out.push(bytes(b"{x}"));' for x in xs)
    return f"pub fn {name}() -> Vec<Vec<u8>> {{\n    let mut out = Vec::new();\n{body}\n    out\n}}"


def lean_bytes(s):
    return "[" + ", ".join(str(b) for b in s.encode()) + "]"


def lean_seg(kind, lit):
    return f".lit {lean_bytes(lit)} /- {lit} -/" if kind == "lit" else f".{kind}"


def lean_routes(name, rs, fns):
    defs = []
    for fn, (v2, segs, methods) in zip(fns, rs):
        sg = ", ".join(lean_seg(*x) for x in segs)
        m = ", ".join(f".{x}" for x in methods)
        defs.append(f"def {camel(fn)} : SRoute := ⟨{str(v2).lower()}, [{sg}], [{m}]⟩")
    defs.append(f"def {camel(name)} : List SRoute := [" + ", ".join(camel(f) for f in fns) + "]")
    return "\n".join(defs)


def lean_proofs(name, fns):
    out = []
    for fn in fns:
        out.append(f"@[step] theorem {fn}_spec : tables.{fn} ⦃ r => toSRoute r = {camel(fn)} ⦄ := by\n"
                   f"  unfold tables.{fn}; h5i_steps\n"
                   f"  all_goals simp_all [{camel(fn)}, toSRoute, toSSeg, Array.to_slice, Array.make, alloc.vec.Vec.new, nats]\n"
                   f"  all_goals scalar_tac")
    out.append(f"set_option maxRecDepth 16384 in\nset_option maxHeartbeats 8000000 in\n"
               f"@[step] theorem {name}_spec : tables.{name} ⦃ v => v.val.map toSRoute = {camel(name)} ⦄ := by\n"
               f"  unfold tables.{name}; h5i_steps\n"
               f"  all_goals simp_all [{camel(name)}, alloc.vec.Vec.new]\n"
               f"  all_goals scalar_tac")
    return "\n\n".join(out)


def camel(s):
    a, *b = s.split("_")
    return a + "".join(x.capitalize() for x in b)


def main(repo):
    src = show(repo)
    assistant = routes(block(src, "const ASSISTANT_SCOPE"))
    slack = routes(block(src, "const SLACK_ACTION_SCOPE"))
    reserved = strings(block(src, "const RESERVED_STREAM_SLOTS"))
    alert_ids = strings(block(src, "const ALERT_ID_LITERALS"))
    assert len(assistant) == src[src.index("const ASSISTANT_SCOPE"):src.index("const SLACK_ACTION_SCOPE")].count("v1(&[") + \
        src[src.index("const ASSISTANT_SCOPE"):src.index("const SLACK_ACTION_SCOPE")].count("v2(&[")
    ra, fa = rust_routes("assistant_scope", assistant)
    rs, fs = rust_routes("slack_action_scope", slack)
    head = (f"//! Generated by difftest/gen_tables.py from openobserve @ {COMMIT[:7]}\n"
            f"//! `{SRC}`: ASSISTANT_SCOPE ({len(assistant)} routes), SLACK_ACTION_SCOPE\n"
            f"//! ({len(slack)}), RESERVED_STREAM_SLOTS ({len(reserved)}), ALERT_ID_LITERALS ({len(alert_ids)}).\n"
            "//! Do not edit.\n"
            "use crate::delegation::{Method, ScopeRoute, Seg};\n\n"
            "fn bytes(s: &[u8]) -> Vec<u8> {\n    s.to_vec()\n}\n\n"
            "fn lit(s: &[u8]) -> Seg {\n    Seg::Lit(s.to_vec())\n}\n\n")
    (HERE / "kernel/src/tables.rs").write_text(
        head + "\n\n".join([rust_list("reserved_stream_slots", reserved),
                            rust_list("alert_id_literals", alert_ids), ra, rs]) + "\n")
    lean = (f"import OpenobserveKernel\n/-! Generated by difftest/gen_tables.py from openobserve @ {COMMIT[:7]}\n"
            f"`{SRC}`. Do not edit. -/\n"
            "open Aeneas Aeneas.Std openobserve_kernel openobserve_kernel.delegation\n\n"
            "namespace openobserve_kernel.Spec\n\n"
            "/-- The UTF-8 bytes of a literal. -/\n"
            "def lit (s : String) : List Nat := s.toUTF8.toList.map (·.toNat)\n\n"
            "/-- A route segment pattern (`Seg`). -/\n"
            "inductive SSeg where\n  | lit (s : List Nat)\n  | param\n  | stream\n  | alertId\n"
            "  deriving DecidableEq, Repr\n\n"
            "structure SRoute where\n  v2 : Bool\n  segs : List SSeg\n  methods : List Method\n\n"
            "def reservedStreamSlots : List (List Nat) := [\n" + ",\n".join(f'  {lean_bytes(x)} /- {x} -/' for x in reserved) + "]\n\n"
            "def alertIdLiterals : List (List Nat) := [\n" + ",\n".join(f'  {lean_bytes(x)} /- {x} -/' for x in alert_ids) + "]\n\n"
            + lean_routes("assistant_scope", assistant, fa) + "\n\n"
            + lean_routes("slack_action_scope", slack, fs) + "\n\n"
            "end openobserve_kernel.Spec\n")
    (HERE / "proofs/SpecTables.lean").write_text(lean)
    proofs = (f"import Verified.Bytes\n/-! Generated by difftest/gen_tables.py: each route function and table\n"
              f"equals its `SpecTables.lean` counterpart. Do not edit. -/\n"
              "open Aeneas Aeneas.Std Result openobserve_kernel openobserve_kernel.Spec openobserve_kernel.Verified\n"
              "open H5iAppLib hiding lit\nopen openobserve_kernel.delegation\n\n"
              "namespace openobserve_kernel.Verified\n\n"
              "/-- A kernel segment pattern as spec data. -/\n"
              "def toSSeg : Seg → SSeg\n  | .Lit l => .lit (nats l.val)\n  | .Param => .param\n"
              "  | .Stream => .stream\n  | .AlertId => .alertId\n\n"
              "def toSRoute (r : ScopeRoute) : SRoute := ⟨r.v2, r.segments.val.map toSSeg, r.methods.val⟩\n\n"
              "@[step] theorem lit_spec (s : Slice U8) : tables.lit s ⦃ g => toSSeg g = .lit (nats s.val) ⦄ := by\n"
              "  unfold tables.lit; step*; subst s_post; rfl\n\n"
              "@[step] theorem tbytes_spec (s : Slice U8) : tables.bytes s ⦃ v => nats v.val = nats s.val ⦄ := by\n"
              "  unfold tables.bytes; step*; subst s_post; rfl\n\n")
    for lname, lean_name in (("alert_id_literals", "alertIdLiterals"), ("reserved_stream_slots", "reservedStreamSlots")):
        proofs += (f"set_option maxHeartbeats 4000000 in\n"
                   f"@[step] theorem {lname}_spec :\n    tables.{lname} ⦃ v => v.val.map (fun w => nats w.val) = {lean_name} ⦄ := by\n"
                   f"  unfold tables.{lname}\n  h5i_steps\n"
                   f"  all_goals simp_all [{lean_name}, Array.to_slice, Array.make, alloc.vec.Vec.new, nats]\n"
                   f"  all_goals scalar_tac\n\n")
    proofs += lean_proofs("assistant_scope", fa) + "\n\n" + lean_proofs("slack_action_scope", fs)
    proofs += "\n\nend openobserve_kernel.Verified\n"
    (HERE / "proofs/Verified/Tables.lean").write_text(proofs)
    print(f"{len(assistant)} assistant routes, {len(slack)} slack routes, "
          f"{len(reserved)} reserved, {len(alert_ids)} alert-id literals")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else str(HERE / "upstream-src"))
