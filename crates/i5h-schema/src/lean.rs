//! Renders the Lean side of a schema: each row's encoding as SQL values, its
//! key length and table number, and the lemmas that the extracted `to_row`
//! and `from_row` compute and invert it.
//!
//! Column types map to Lean by their resolved Rust name. An app's own column
//! types (enums) need `T.col`, `T.col_to_val`, `T.col_from_val` and a simp
//! lemma `T.col_inj` in a hand-written `Columns.lean`.

use std::fmt::Write;

/// One row type: name, table, fields as (name, Rust type), key length.
pub type RowDecl<'a> = (&'a str, &'a str, Vec<(&'a str, &'a str)>, usize);

#[derive(Clone, Copy, PartialEq, Eq)]
enum Prim {
    U64,
    U32,
    Bool,
    Bytes,
    OptU64,
}

enum Col<'a> {
    Prim(Prim),
    Own(&'a str),
}

fn col(ty: &str) -> Col<'_> {
    match ty {
        "u64" => Col::Prim(Prim::U64),
        "u32" => Col::Prim(Prim::U32),
        "bool" => Col::Prim(Prim::Bool),
        "alloc::vec::Vec<u8>" => Col::Prim(Prim::Bytes),
        "core::option::Option<u64>" => Col::Prim(Prim::OptU64),
        other => Col::Own(other.rsplit("::").next().unwrap_or(other)),
    }
}

fn expr(c: &Col, x: &str) -> String {
    match c {
        Col::Prim(Prim::U64 | Prim::U32) => format!("int {x}.val"),
        Col::Prim(Prim::Bool) => format!(".Bool {x}"),
        Col::Prim(Prim::Bytes) => format!(".Bytes {x}"),
        Col::Prim(Prim::OptU64) => format!("optV {x}"),
        Col::Own(t) => format!("{t}.col {x}"),
    }
}

fn module(krate: &str) -> String {
    krate.split('_').map(|w| {
        let mut c = w.chars();
        c.next().map(|f| f.to_uppercase().collect::<String>() + c.as_str()).unwrap_or_default()
    }).collect()
}

const U64: &str = r#"
@[simp] theorem u64_val_eq (x y : U64) : x.val = y.val ↔ x = y :=
  ⟨fun h => by scalar_tac, fun h => h ▸ rfl⟩

theorem int_inj {a b : Nat} (ha : a < 2 ^ 64) (hb : b < 2 ^ 64) (h : int a = int b) : a = b := by
  simp only [int, i5h_sql.Val.Int.injEq, IScalar.mk.injEq] at h
  have := congrArg BitVec.toNat h
  simp only [BitVec.toNat_ofNat] at this
  rwa [Nat.mod_eq_of_lt (by simpa using ha), Nat.mod_eq_of_lt (by simpa using hb)] at this

@[simp] theorem int_u64 (x y : U64) : int x.val = int y.val ↔ x = y := by
  refine ⟨fun h => ?_, fun h => h ▸ rfl⟩
  have := int_inj (by scalar_tac) (by scalar_tac) h
  scalar_tac

theorem u64_to_val_eq (x : U64) : U64.Insts.I5h_sqlColumn.to_val x = ok (int x.val) := by
  unfold U64.Insts.I5h_sqlColumn.to_val int
  simp only [lift, UScalar.hcast]
  rw [← UScalar.bv_toNat, BitVec.ofNat_toNat]
  simp [BitVec.zeroExtend]

@[step] theorem u64_to_val (x : U64) : U64.Insts.I5h_sqlColumn.to_val x ⦃ v => v = int x.val ⦄ := by
  simp [u64_to_val_eq]

theorem u64_from_val (x : U64) : U64.Insts.I5h_sqlColumn.from_val (int x.val) = ok (some x) := by
  simp only [U64.Insts.I5h_sqlColumn.from_val, int, lift, IScalar.hcast]
  rw [← UScalar.bv_toNat, BitVec.ofNat_toNat]
  simp [BitVec.signExtend_eq]
"#;

const BYTES: &str = r#"
theorem u8vec_clone (v : alloc.vec.Vec U8) : alloc.vec.CloneVec.clone core.clone.CloneU8 v = ok v :=
  vec_clone_eq _ v (fun _ => rfl)

@[step] theorem bytes_to_val (v : alloc.vec.Vec U8) :
    alloc.vec.VecU8.Insts.I5h_sqlColumn.to_val v ⦃ x => x = .Bytes v ⦄ := by
  simp [alloc.vec.VecU8.Insts.I5h_sqlColumn.to_val, u8vec_clone]

theorem bytes_from_val (v : alloc.vec.Vec U8) :
    alloc.vec.VecU8.Insts.I5h_sqlColumn.from_val (.Bytes v) = ok (some v) := by
  simp [alloc.vec.VecU8.Insts.I5h_sqlColumn.from_val, u8vec_clone]
"#;

const OPT: &str = r#"
def optV : Option U64 → Val
  | some x => int x.val
  | none => .Null

@[step] theorem opt_to_val (o : Option U64) :
    core.option.Option.Insts.I5h_sqlColumn.to_val U64.Insts.I5h_sqlColumn o ⦃ x => x = optV o ⦄ := by
  cases o with
  | none => simp [core.option.Option.Insts.I5h_sqlColumn.to_val, optV]
  | some x => simpa [core.option.Option.Insts.I5h_sqlColumn.to_val, optV] using u64_to_val x

theorem opt_from_val (o : Option U64) :
    core.option.Option.Insts.I5h_sqlColumn.from_val U64.Insts.I5h_sqlColumn (optV o) = ok (some o) := by
  cases o with
  | none => simp [core.option.Option.Insts.I5h_sqlColumn.from_val, optV]
  | some x =>
    simp only [core.option.Option.Insts.I5h_sqlColumn.from_val, optV, int]
    rw [← int, u64_from_val]
    simp

@[simp] theorem optV_inj (a b : Option U64) : optV a = optV b ↔ a = b := by
  cases a <;> cases b <;> simp only [optV, reduceCtorEq, Option.some.injEq, int_u64] <;> simp [int]
"#;

/// The generated Lean file for a kernel crate `krate`.
pub fn render(krate: &str, rows: &[RowDecl]) -> String {
    let mut used: Vec<Prim> = Vec::new();
    let mut own: Vec<&str> = Vec::new();
    for (_, _, fields, _) in rows {
        for (_, ty) in fields {
            match col(ty) {
                Col::Prim(p) => {
                    if !used.contains(&p) {
                        used.push(p);
                    }
                }
                Col::Own(t) => {
                    if !own.contains(&t) {
                        own.push(t);
                    }
                }
            }
        }
    }
    let has = |p: Prim| used.contains(&p);
    let ints = has(Prim::U64) || has(Prim::U32) || has(Prim::OptU64);

    let mut s = String::new();
    let m = module(krate);
    let _ = writeln!(s, "-- Generated by i5h_schema::schema! from the rows of `{krate}`. Do not edit.");
    let _ = writeln!(s, "-- `cargo test` checks it is current; I5H_BLESS=1 rewrites it.");
    let _ = writeln!(s, "import {m}");
    let _ = writeln!(s, "import I5hLib");
    if !own.is_empty() {
        let _ = writeln!(s, "import Columns");
    }
    let _ = writeln!(s, "/-!\n# Rows of `{krate}` as SQL values\n\nKey columns first; tables numbered in declaration order.\n-/");
    let _ = writeln!(s, "open Aeneas Aeneas.Std Result {krate} I5hLib\n");
    let _ = writeln!(s, "namespace {krate}.Schema\n");
    let _ = writeln!(s, "abbrev Val := i5h_sql.Val\n");
    if ints {
        let _ = writeln!(s, "/-- An integer column: its 64 bits as a `BIGINT`. -/\ndef int (n : Nat) : Val := .Int ⟨BitVec.ofNat _ n⟩");
        s.push_str(U64);
    }
    if has(Prim::Bytes) {
        s.push_str(BYTES);
    }
    if has(Prim::OptU64) {
        s.push_str(OPT);
    }
    for t in &own {
        let _ = writeln!(
            s,
            "\n@[step] theorem {t}_col_to_val (x : {t}) : {t}.Insts.I5h_sqlColumn.to_val x ⦃ v => v = {t}.col x ⦄ := by\n  simp [{t}.col_to_val]"
        );
    }

    for (i, (name, table, fields, key_len)) in rows.iter().enumerate() {
        let names: Vec<String> = fields.iter().map(|(f, _)| format!("`{f}`")).collect();
        let cols: Vec<String> = fields.iter().map(|(f, ty)| expr(&col(ty), &format!("x.{f}"))).collect();
        let _ = writeln!(s, "\n/-! ## `{name}` (table `{table}`) -/\n");
        let _ = writeln!(s, "/-- Columns {}. -/\ndef {name}.row (x : {name}) : List Val :=\n  [{}]\n", names.join(", "), cols.join(", "));
        let _ = writeln!(s, "def {name}.table : Nat := {i}\ndef {name}.keyLen : Nat := {key_len}\n");
        let _ = writeln!(
            s,
            "@[step] theorem {name}.to_row_spec (x : {name}) : {name}.to_row x ⦃ v => v.val = {name}.row x ⦄ := by\n  have := usize_max_le\n  unfold {name}.to_row; step* <;> simp_all [{name}.row] <;> scalar_tac\n"
        );
        let _ = writeln!(
            s,
            "theorem {name}.row_inj : Function.Injective {name}.row := by\n  intro a b h; cases a; cases b; simp_all [{name}.row]"
        );
    }

    // Lemmas `row_tac` may read a column with. It comes after the row
    // definitions so the names in it resolve.
    let mut dec = vec!["List.getElem_cons_zero", "List.getElem_cons_succ", "Nat.zero_add", "Nat.reduceAdd", "bind_tc_ok"];
    if ints {
        dec.push("u64_from_val");
    }
    if has(Prim::Bytes) {
        dec.push("bytes_from_val");
    }
    if has(Prim::OptU64) {
        dec.push("opt_from_val");
    }
    let own_from: Vec<String> = own.iter().map(|t| format!("{t}.col_from_val")).collect();
    dec.extend(own_from.iter().map(|x| x.as_str()));
    let row_defs: Vec<String> = rows.iter().map(|(n, ..)| format!("{n}.row")).collect();
    let _ = writeln!(
        s,
        "\n/-! ## Decoding -/\n\n/-- Step through a generated `from_row`, reading each column from the known row. -/\nmacro \"row_tac\" : tactic => `(tactic| (\n  repeat (first\n    | (step*; done)\n    | (simp_all only [{}, {}]; step*))\n  all_goals simp_all))",
        row_defs.join(", "),
        dec.join(", ")
    );

    for (name, _, fields, _) in rows {
        let n = fields.len();
        let _ = writeln!(
            s,
            "\ntheorem {name}.from_row_spec (x : {name}) (v : alloc.vec.Vec Val) (h : v.val = {name}.row x) :\n    {name}.from_row v ⦃ o => o = some x ⦄ := by\n  have hl : v.length = {n} := by simp [alloc.vec.Vec.length, h, {name}.row]\n  unfold {name}.from_row; row_tac"
        );
    }

    let _ = writeln!(s, "\n/-- Key length per table. -/\ndef kl : Nat → Nat");
    for (i, (_, _, _, key_len)) in rows.iter().enumerate() {
        let _ = writeln!(s, "  | {i} => {key_len}");
    }
    let _ = writeln!(s, "  | _ => 0\n\nend {krate}.Schema");
    s
}

/// Test helper: the file at `path` must equal `text`; `I5H_BLESS=1` rewrites it.
pub fn check(path: &str, text: &str) {
    if std::env::var("I5H_BLESS").is_ok_and(|v| v == "1") {
        std::fs::write(path, text).unwrap();
        return;
    }
    let old = std::fs::read_to_string(path).unwrap_or_default();
    assert!(old == text, "{path} is stale; rerun with I5H_BLESS=1");
}
