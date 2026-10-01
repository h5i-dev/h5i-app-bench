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

The library `H5iAppLib` is at `/opt/h5i-app-lib/H5iAppLib/`. Read the file for a lemma
before writing your own version of it. Two tutorials sit next to this file:
`tutorials/calculator` covers loops and specs, and `tutorials/board` covers
permissions, invariants and one lemma per command.

## Reading extracted code

`x ⦃ v => P v ⦄` is Aeneas' weakest precondition: `x` succeeds and its value
satisfies `P`. The tactics `step` and `step*` pass through a call by using a
`@[step]` theorem of that shape about it.

A Rust `Vec<T>` is `alloc.vec.Vec T`, and `.val` gives its `List T`. Integers
have types such as `U64` and `Usize`, with `.val` the `Nat`; `scalar_tac`
proves bounds on them. A `for` loop becomes a `..._loop` function over an
iterator, and an index loop becomes one that takes the index. Rust `match` and
`if` stay `match` and `if`.

## Tactics

These are in `H5iAppLib/Tactics.lean`.

- `step*` runs the code symbolically through binds, using `@[step]` specs.
- `h5i_steps` does the same and also goes through a bind on an `if` whose
  branches call functions, and splits a `match` where `step*` stops.
- `h5i_simp` cleans up `if false = true`, `id` and `ok` binds. It never fails.
- `h5i_invert h`, for `h : f x = ok y` with `f` unfolded, leaves one goal per
  successful path with each call's equation as a hypothesis. It lets you
  reason about a successful run without proving every callee total.
- `h5i_for f using (iter_find l P _ ?_) [defs]` proves the spec of a function
  whose body is one `for` loop. `iter_any`, `iter_filter_map` and `iter_fold`
  in `H5iAppLib/Iter.lean` cover the other loop shapes.
- `loop_search` and `loop_fold` in `H5iAppLib/Loops.lean`, with `h5i_step` for
  the per-step goal, prove specs of index loops (`while i < v.len()`).
- `h5i_derive_eq T f` gives `DecidableEq T` and a `@[step]` spec for a derived
  `==`, which the WP tactics do not reduce on their own. Run it on field
  types before the structs that contain them.
- `h5i_derive_clone T f` proves that a derived `clone` returns its argument,
  for `T` and for `Vec T`.

`H5iAppLib/Basic.lean` has the glue lemmas. `OnOk P` lifts a property of
`(writes, reply)` to a postcondition. `of_spec` and `post_of_ok` combine
`transition ... ⦃ OnOk P ⦄` with `h : transition ... = .ok (.Ok (ws, r))` to
give `P ws r`, and `ok_of` gives totality. `bind_tc_eq_ok` and `loop_ok`
invert successful runs.

## How the existing proofs are organized

Each table loop gets a spec over lists (`find?`, `any`, `filter`), stated as
`model = extracted` and tagged `@[step]`, for example
`find_user us u ⦃ o => us.val.find? (·.id = u) = o ⦄`. Later `step*` calls
then use it, and `simp_all` can rewrite with it.

Each command, or each helper that decides a permission, then gets one lemma
saying what a successful run writes and why it succeeded. Only these lemmas
look at extracted code. The theorem itself goes by cases on the command and
uses them.

For a statement of the form "a successful run satisfies P", start with
`refine of_spec (P := ...) ?_ h`, unfold `transition`, and continue with
`step*` or `h5i_steps`. Alternatively, `h5i_invert h`.

## Working

Build with `cd proofs && lake build`, which takes 10 to 30 seconds. Prove
small lemmas first. You can leave `sorry` in parts you have not done to check
the rest, but the final file must have none. The grader rejects `sorry`,
`axiom` and `native_decide`.

When a match on a `find?` result does not reduce, add `-List.find?_eq_none`
to the simp set. After unfolding, `simp only [reduceIte]` removes decided
`if`s. When `step*` stops at a bind on an `if`, use `h5i_steps`, and when it
stops at `==` on a struct, run `h5i_derive_eq`.
