import I5hLib.Loops
/-! Tactics for kernel proofs. -/
open Aeneas Aeneas.Std Result

namespace I5hLib

/-- Close the per-step goal of `loop_search` or `loop_fold`. -/
macro "i5h_step" : tactic => `(tactic| (
  step* <;> (repeat' (first | step | split)) <;>
    simp only [I5hLib.SearchStep, I5hLib.FoldStep] <;> simp_all <;> try scalar_tac))

/-- `i5h_step` with extra simp lemmas, for a loop predicate that is a named def. -/
macro "i5h_step" " [" ls:Lean.Parser.Tactic.simpLemma,* "]" : tactic => `(tactic| (
  step* <;> (repeat' (first | step | split)) <;>
    simp only [I5hLib.SearchStep, I5hLib.FoldStep] <;> simp_all [$ls,*] <;> try scalar_tac))

/-- Run `f` symbolically, one goal per path. -/
syntax "walk " ident : tactic
macro_rules
  | `(tactic| walk $f) => `(tactic| (
    unfold $f:ident
    split <;> step* <;> (repeat' (first | step | split | simp only [WP.spec_ok, bind_tc_ok, bind_ok]))
    all_goals (try (rename_i v _; cases v))
    all_goals (try (first | dsimp only | (split; dsimp only)))
    all_goals (repeat' (first | step | split | simp only [WP.spec_ok, bind_tc_ok, bind_ok]))))

/-- Evaluate a concrete extracted kernel call; the lemmas reduce the concrete data. -/
macro "i5h_eval" " (" f:ident g:ident ")" " [" ls:Lean.Parser.Tactic.simpLemma,* "]" : tactic => `(tactic| (
  unfold $f $g
  step*
  all_goals (simp_all [$ls,*])
  all_goals (try scalar_tac)))

/-- Variant for a command whose concrete run calls a third named helper. -/
macro "i5h_eval" " (" f:ident g:ident h:ident ")" " [" ls:Lean.Parser.Tactic.simpLemma,* "]" : tactic => `(tactic| (
  unfold $f $g $h
  step*
  all_goals (simp_all [$ls,*])
  all_goals (try scalar_tac)))

end I5hLib
