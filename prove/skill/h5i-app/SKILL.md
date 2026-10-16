---
name: h5i-app
description: Prove properties of h5i-app kernels in Lean 4. Use when a task asks for a proof about Rust code that Aeneas extracted to proofs/generated/*.lean, with H5iAppLib available.
---

# Proving h5i-app kernels

An h5i-app application keeps its logic in a pure kernel, `transition(principal, snapshot,
command) -> Result<(writes, reply), error>`, written in the subset of Rust that
Aeneas translates. Aeneas extracts it to `proofs/generated/`, where each Rust
function becomes a Lean function returning `Result` (`ok x`, `fail e` or
`div`). `Spec.lean` states the policy over plain lists without calling the
kernel's helpers, and theorems relate the extracted functions to it.

The library `H5iAppLib` is at `/opt/h5i-app-lib/H5iAppLib/`. Read the file for a
lemma or tactic before writing your own version of it — the tables below name
the file for each. Two tutorials sit next to this file: `tutorials/calculator`
covers loops and specs, and `tutorials/board` covers permissions, invariants
and one lemma per command.

The task's `open` already brings in `Aeneas`, `Aeneas.Std`, `Result`, the
kernel namespace and its `Spec`, and `H5iAppLib` (without `lit`, so `Spec.lit`
wins). If you need the weakest-precondition lemmas by name, also
`open Aeneas.Std.WP`.

## Reading extracted code

`x ⦃ v => P v ⦄` is Aeneas' weakest precondition: `x` succeeds and its value
satisfies `P`. The tactics `step` and `step*` pass through a call by using a
`@[step]` theorem of that shape about it.

`Result` is an interaction tree, so `rfl`, `cases h` and `injection h` on
`f x = ok y` usually fail — use the tactics and lemmas here instead.

A Rust `Vec<T>` is `alloc.vec.Vec T`, and `.val` gives its `List T`. Integers
have types such as `U64` and `Usize`, with `.val` the `Nat`; `scalar_tac`
proves bounds on them. A `for` loop becomes a `..._loop` function over an
iterator, and an index loop (`while i < v.len()`) becomes a `loop body i`. Rust
`match` and `if` stay `match` and `if`.

## Tactics

The WP/stepping and inversion tactics are in `H5iAppLib/Tactics.lean` unless
noted.

- `step*` runs the code symbolically through binds, using `@[step]` specs.
- `h5i_steps` does the same and also goes through a bind on an `if`/`match`
  whose branches call functions, where `step*` stops.
- `h5i_simp` cleans up `if false = true`, `id` and `ok` binds. It never fails.
- `h5i_invert h`, for `h : f x = ok y` with `f` unfolded, leaves one goal per
  successful path. `let x ← m` leaves `x` and `hx : m = ok x`; a branch
  condition becomes `hc` (`h5i_invert h with hcond` renames it); an `r?`
  result splits into `Ok`/`Err`; a final `h : x = e` is substituted. It lets
  you reason about a successful run without proving every callee total.
- `h5i_ok_facts` adds a `_val` hypothesis for each `h : x + y = ok z` (also
  `-`, `*`, `/`, `%`, `index_usize`, `Vec.index`). `h5i_arith` runs that then
  `scalar_tac`, for goals about computed values. (`Inv.lean`)
- `h5i_derive_all` (command) runs `h5i_derive_eq`/`h5i_derive_clone` for every
  extracted `PartialEq`/`Clone`; put it right after the opens. `h5i_derive_eq T f`
  (`Sets.lean`) gives `DecidableEq T` and a `@[step]` spec for a derived `==`,
  which the WP tactics do not reduce on their own — run it on field types
  before the structs that contain them. `h5i_derive_clone T f` (`Basic.lean`)
  proves a derived `clone` returns its argument, for `T` and `Vec T`.
- `h5i_eval (f g) [lemmas]` evaluates a concrete call; for a concrete enum
  argument use `simp [f]`, not `rfl`.
- `@[h5i_spec]` (`Spec.lean`) on `thm : f xs ⦃ r => P r ⦄` also generates
  `thm.inv : f xs = ok r → P r` and, when `r` is a value `g`, `thm.eq : f xs = ok g`.

## How the existing proofs are organized

Each table loop gets a spec over lists (`find?`, `any`, `filter`), stated as
`model = extracted` and tagged `@[step]` (and usually `@[h5i_spec]`), for
example `find_user us u ⦃ o => us.val.find? (·.id = u) = o ⦄`. Later `step*`
calls then use it, and `simp_all` can rewrite with it.

Each command, or each helper that decides a permission, then gets one lemma
saying what a successful run writes and why it succeeded. Only these lemmas
look at extracted code. The theorem itself goes by cases on the command and
uses them.

For a statement of the form "a successful run satisfies P", start with
`refine of_spec (P := ...) ?_ h`, unfold `transition`, and continue with
`step*` or `h5i_steps`; or invert directly with `h5i_invert h`. `OnOk P`
(`Authz.lean`) lifts a property of `(writes, reply)` to a postcondition;
`of_spec`/`post_of_ok` combine a `… ⦃ OnOk P ⦄` spec with `h : … = .ok (.Ok (ws, r))`
to give `P ws r` (`Basic.lean`).

## Lemmas, by the hypothesis you have

(`Basic.lean` unless the name says otherwise.)

| You have | Lemma | You get |
|---|---|---|
| `ok a = ok b` | `Result.ok.inj`, `result_ok_inj` | `a = b` |
| `ok a = fail e` | `ok_ne_fail`, `fail_ne_ok` | `False` |
| `.Ok (a, b) = .Ok (a', b')` | `ok_inj` | `a = a' ∧ b = b'` |
| `(do let a ← x; f a) = ok y` | `bind_tc_eq_ok`, `bind_eq_ok` | `∃ a, x = ok a ∧ f a = ok y` |
| `x + y = ok z` (and `-`, `*`, `/`, `%`) | `add_ok_val`, `sub_ok_val`, `mul_ok_val`, `div_ok_val`, `rem_ok_val` | the value (and bounds / `y ≠ 0`) |
| `saturating_add/sub x y` | `saturating_add_val`, `saturating_sub_val` | `min (x+y) max`, `x - y` |
| `UScalar.cast tgt x` | `cast_val`, `usize_cast_u64` | `x.val` |
| `v.index_usize i = ok x` | `vec_index_ok`, `vec_index_ok_get?`, `vec_index_ok_mem` | `v.val[i.val] = x`, `x ∈ v.val` |
| `s.index_usize i = ok x` (slice) | `slice_index_ok`, `slice_index_ok_mem` | the same |
| `m ⦃ P ⦄` and `m = ok x` | `post_of_ok` | `P x` |
| `m ⦃ x => x = v ⦄` | `eq_ok_of_spec` | `m = ok v` |
| `m ⦃ P ⦄` | `ok_of` | `∃ r, m = ok r` |

## Loops

| Goal | Use |
|---|---|
| a spec, the loop stops at the first match | `loop_search` + `search_any`/`search_all`/`search_find`/`search_findIdx`, or the `h5i_search_any/all/find` tactics (after `unfold f f_loop`) |
| a spec, the loop runs to the end | `loop_fold`, `loop_fold2` (`foldl_count`, `foldl_filter`, `foldl_map`) — `Loops.lean` |
| `for x in v.iter()` | `iter_loop`, `iter_fold`, `iter_search`, `iter_any`, `iter_find`, `iter_filter_map`, or `h5i_iter` — `Iter.lean`; `h5i_for f using (iter_find l P _ ?_) [defs]` for a one-loop body |
| from `loop body x = ok y` | `loop_ok` (any measure), `loop_idx_ok` (measure `n - idx`) |
| from `loop … = ok true` / `ok false` | `loop_true_witness` / `loop_false_all` |
| the loop does not fail | `loop_idx_spec`, `h5i_total idx n` (measure `n - idx`); `h5i_measure_induction e with ih` for slice-index recursion |

To prove a result does not depend on part of the database, first prove its spec
as a list function (`= l.any P`, `= l.find? P`), then prove the property on
lists (`List.any_filter` and relatives already exist). Do not compare the two
runs directly.

## Bits

| Goal | Use |
|---|---|
| `held &&& req = req` (bitflags) | `Covers`, `covers_iff_testBit`, `covers_or_iff`, `Covers.trans` |
| `x &&& m = y &&& m`, `m = MAX <<< s` (CIDR) | `u32_masked_eq_iff`, `u64_masked_eq_iff`, `masked_eq_iff`: gives `x.val / 2^s = y.val / 2^s` |
| `MAX.bv` | `u32_max_bv` and friends: `BitVec.allOnes _` |
| anything else on bits | `h5i_bv` (`Bits.lean`) |

## Working

Build with `cd proofs && lake build`, which takes 10 to 30 seconds. Prove
small lemmas first. You can leave `sorry` in parts you have not done to check
the rest, but the final file must have none. The grader rejects `sorry`,
`axiom` and `native_decide`.

When a match on a `find?` result does not reduce, add `-List.find?_eq_none`
to the simp set. After unfolding, `simp only [reduceIte]` removes decided
`if`s. When `step*` stops at a bind on an `if`, use `h5i_steps`, and when it
stops at `==` on a struct, run `h5i_derive_eq` (or `h5i_derive_all` once up
front).
