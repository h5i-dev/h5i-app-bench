import I5hLib.Loops
/-! Tactics for kernel proofs. -/
open Aeneas Aeneas.Std Result

namespace I5hLib

/-- Close the per-step goal of `loop_search` or `loop_fold` after unfolding
the loop body. -/
macro "i5h_step" : tactic => `(tactic| (
  step* <;> (repeat' (first | step | split)) <;>
    simp only [I5hLib.SearchStep, I5hLib.FoldStep] <;> simp_all <;> try scalar_tac))

/-- `i5h_step` with extra simp lemmas, for a loop predicate that is a named def. -/
macro "i5h_step" " [" ls:Lean.Parser.Tactic.simpLemma,* "]" : tactic => `(tactic| (
  step* <;> (repeat' (first | step | split)) <;>
    simp only [I5hLib.SearchStep, I5hLib.FoldStep] <;> simp_all [$ls,*] <;> try scalar_tac))

/-- Execute `f` symbolically, leaving one goal per path. Splits `if`s and
`match`es and destructures returned pairs. -/
syntax "walk " ident : tactic
macro_rules
  | `(tactic| walk $f) => `(tactic| (
    unfold $f:ident
    split <;> step* <;> (repeat' (first | step | split | simp only [WP.spec_ok, bind_tc_ok, bind_ok]))
    all_goals (try (rename_i v _; cases v))
    all_goals (try (first | dsimp only | (split; dsimp only)))
    all_goals (repeat' (first | step | split | simp only [WP.spec_ok, bind_tc_ok, bind_ok]))))

end I5hLib
