#!/usr/bin/env python3
"""Proof mutation suite for the example kernel.

Each mutant injects a known bug into examples/docs/kernel, re-extracts it with
Charon + Aeneas, and rebuilds the proofs. A mutant is caught when the proofs no
longer build. A surviving mutant means the spec is too weak.

Usage: scripts/mutants.py [-j JOBS] [NAME ...]
Needs charon and aeneas on PATH (source /home/ht2673/tools/aeneas-env.sh) and a
built examples/docs/proofs/.lake (its packages are shared, read-only).
"""

import argparse
import concurrent.futures as cf
import os
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KERNEL = os.path.join(ROOT, "examples/docs/kernel")
PROOFS = os.path.join(ROOT, "examples/docs/proofs")
THEOREMS = ["Theorems", "Invariants", "Noninterference", "Frame", "Check"]

# name -> list of (old, new) replacements in kernel/src/lib.rs
MUTANTS = {
    "baseline": [],
    "self_approval_allowed": [
        ("if d.author == user {\n                return Err(Error::SelfApproval);",
         "if false {\n                return Err(Error::SelfApproval);"),
    ],
    "editor_can_approve": [
        ("            Action::Approve => false,\n            Action::Manage => false,\n        },\n        Role::Viewer",
         "            Action::Approve => true,\n            Action::Manage => false,\n        },\n        Role::Viewer"),
    ],
    "remove_last_owner": [
        ("if r == Role::Owner && count_owners(&snap.members, *project) <= 1 {",
         "if r == Role::Owner && count_owners(&snap.members, *project) < 1 {"),
    ],
    "demote_last_owner": [
        ("if demotes_owner && count_owners(&snap.members, *project) <= 1 {",
         "if false && count_owners(&snap.members, *project) <= 1 {"),
    ],
    "hidden_doc_forbidden": [
        ("if !can(snap, user, d.project, Action::Read) {\n                Err(Error::NotFound)",
         "if !can(snap, user, d.project, Action::Read) {\n                Err(Error::Forbidden)"),
    ],
    "publish_from_review": [
        ("if d.status != Status::Approved {", "if d.status != Status::InReview {"),
    ],
    "edit_keeps_approver": [
        ("let mut e = match with_status(d, Status::Draft, None) {",
         "let keep = d.approver;\n            let mut e = match with_status(d, Status::Draft, keep) {"),
    ],
    "list_without_permission": [
        ("if !can(snap, user, *project, Action::Read) {\n                return Err(Error::Forbidden);\n            }\n            Ok((\n                Vec::new(),\n                Reply::Docs(",
         "if false {\n                return Err(Error::Forbidden);\n            }\n            Ok((\n                Vec::new(),\n                Reply::Docs("),
    ],
    "delete_needs_only_write": [
        ("authorized_doc(snap, user, *doc, Action::Manage)", "authorized_doc(snap, user, *doc, Action::Write)"),
    ],
    "counter_not_incremented": [
        ("Ok((id, Counter { next_id: id + 1 }))", "Ok((id, Counter { next_id: id }))"),
    ],
    "get_skips_read_check": [
        ("Command::GetDocument { doc } => {\n            let d = match authorized_doc(snap, user, *doc, Action::Read) {",
         "Command::GetDocument { doc } => {\n            let d = match find_document_or_missing(&snap.documents, *doc) {"),
        ("fn one(w: Write)",
         "fn find_document_or_missing(docs: &Vec<Document>, id: u64) -> Result<Document, Error> {\n"
         "    match find_document(docs, id) {\n        Some(d) => Ok(d),\n        None => Err(Error::NotFound),\n    }\n}\n\nfn one(w: Write)"),
    ],
    "webhook_without_manage": [
        ("Command::SetWebhook { project, dest } => {\n            if !can(snap, user, *project, Action::Manage) {",
         "Command::SetWebhook { project, dest } => {\n            if false {"),
    ],
    "effect_to_fixed_destination": [
        ("Some(dest) => Some(Effect {\n                    dest,",
         "Some(dest) => Some(Effect {\n                    dest: 0,"),
    ],
    "scope_too_narrow": [
        ("Command::SetWebhook { project, .. } => Scope::Project(*project),",
         "Command::SetWebhook { .. } => Scope::Counter,"),
    ],
    "checker_skips_doc_ids": [
        ("        && doc_ids_unique(&s.documents)\n", ""),
    ],
    "manage_any_project": [
        ("            role,\n        } => {\n            if !can(snap, user, *project, Action::Manage) {",
         "            role,\n        } => {\n            if false {"),
    ],
}

SCHEMA = os.path.join(ROOT, "crates/i5h-schema")

# The kernel and its only dependency, the i5h-schema macros.
WORKSPACE_TOML = """[workspace]
resolver = "2"
members = ["kernel", "i5h-schema"]

[workspace.package]
edition = "2021"
license = "Apache-2.0"
version = "0.1.0"

[workspace.dependencies]
i5h-schema = { path = "i5h-schema" }
"""


def run(cmd, cwd, log):
    with open(log, "a") as f:
        f.write(f"$ {' '.join(cmd)}\n")
        f.flush()
        return subprocess.run(cmd, cwd=cwd, stdout=f, stderr=subprocess.STDOUT).returncode


def mutate(src, edits):
    for old, new in edits:
        if src.count(old) != 1:
            raise ValueError(f"pattern matched {src.count(old)} times: {old[:60]!r}")
        src = src.replace(old, new)
    return src


def check(name, edits, keep):
    tmp = tempfile.mkdtemp(prefix=f"i5h-mutant-{name}-")
    log = os.path.join(tmp, "log.txt")
    try:
        shutil.copytree(KERNEL, os.path.join(tmp, "kernel"), ignore=shutil.ignore_patterns("target"))
        shutil.copytree(SCHEMA, os.path.join(tmp, "i5h-schema"), ignore=shutil.ignore_patterns("target"))
        with open(os.path.join(tmp, "Cargo.toml"), "w") as f:
            f.write(WORKSPACE_TOML)
        lib = os.path.join(tmp, "kernel/src/lib.rs")
        with open(lib) as f:
            src = mutate(f.read(), edits)
        with open(lib, "w") as f:
            f.write(src)

        proofs = os.path.join(tmp, "proofs")
        os.makedirs(os.path.join(proofs, ".lake"))
        os.symlink(os.path.join(PROOFS, ".lake/packages"), os.path.join(proofs, ".lake/packages"))
        for f in os.listdir(PROOFS):
            if f.endswith(".lean") or f in ("lake-manifest.json", "lean-toolchain", "lakefile.lean"):
                shutil.copy(os.path.join(PROOFS, f), proofs)
        # The proof library is required by relative path; point it at the real one.
        lib = os.path.join(ROOT, "crates/i5h/proofs")
        for f in ("lakefile.lean", "lake-manifest.json"):
            path = os.path.join(proofs, f)
            with open(path) as fh:
                text = fh.read().replace("../../../crates/i5h/proofs", lib)
            with open(path, "w") as fh:
                fh.write(text)

        # Rust must still compile, or the mutant is invalid.
        if run(["cargo", "check", "-q", "-p", "docs-kernel"], tmp, log) != 0:
            return name, "invalid (rust)", tmp
        llbc = os.path.join(tmp, "docs_kernel.llbc")
        rc = run(["charon", "cargo", "--preset=aeneas", "--start-from", "docs_kernel::transition",
                  "--start-from", "docs_kernel::apply", "--start-from", "docs_kernel::read_scope",
                  "--start-from", "docs_kernel::check_inv",
                  "--dest-file", llbc], os.path.join(tmp, "kernel"), log)
        if rc != 0:
            return name, "invalid (charon)", tmp
        if run(["aeneas", "-backend", "lean", llbc, "-dest", proofs], tmp, log) != 0:
            return name, "invalid (aeneas)", tmp
        rc = run(["lake", "build"] + THEOREMS, proofs, log)
        if name == "baseline":
            return name, "ok" if rc == 0 else "BASELINE FAILS", tmp
        return name, "caught" if rc != 0 else "SURVIVED", tmp
    finally:
        if not keep:
            shutil.rmtree(tmp, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-j", type=int, default=6)
    ap.add_argument("--keep", action="store_true", help="keep temp dirs for inspection")
    ap.add_argument("names", nargs="*")
    args = ap.parse_args()
    names = args.names or list(MUTANTS)
    start = time.time()
    results = {}
    with cf.ThreadPoolExecutor(args.j) as ex:
        futs = {ex.submit(check, n, MUTANTS[n], args.keep): n for n in names}
        for fut in cf.as_completed(futs):
            try:
                name, verdict, tmp = fut.result()
            except Exception as e:  # noqa: BLE001
                name, verdict, tmp = futs[fut], f"error: {e}", ""
            results[name] = verdict
            print(f"{name:28} {verdict}" + (f"  ({tmp})" if args.keep else ""), flush=True)
    mutants = [n for n in names if n != "baseline"]
    caught = sum(results[n] == "caught" for n in mutants)
    print(f"\n{caught}/{len(mutants)} mutants caught in {time.time() - start:.0f}s")
    bad = [n for n in names if results[n] not in ("ok", "caught")]
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
