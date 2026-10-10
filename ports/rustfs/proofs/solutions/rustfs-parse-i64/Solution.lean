import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
set_option maxHeartbeats 0
namespace rustfs_kernel.Solution

def signed (neg : Bool) (a : Nat) : Int := if neg then -(a : Int) else a
def cap (neg : Bool) : Nat := if neg then 2 ^ 63 else 2 ^ 63 - 1
def decimal (ds : List Nat) (a : Nat) : Nat := ds.foldl (fun a d => 10 * a + (d - 48)) a
def digitsModel (ds : List Nat) (a : Nat) (neg : Bool) : Option Int :=
  if ds.all (fun d => 48 ≤ d ∧ d ≤ 57) && decide (decimal ds a ≤ cap neg)
  then some (signed neg (decimal ds a)) else none

theorem decimal_ge (ds : List Nat) (a : Nat) : a ≤ decimal ds a := by
  induction ds generalizing a with
  | nil => simp [decimal]
  | cons d ds ih =>
    simp only [decimal, List.foldl_cons]
    have := ih (10 * a + (d - 48))
    unfold decimal at this
    omega

theorem digitsModel_step (d : Nat) (ds : List Nat) (a : Nat) (neg : Bool)
    (hd : 48 ≤ d ∧ d ≤ 57) :
    digitsModel (d :: ds) a neg =
      if 10 * a ≤ cap neg then
        if 10 * a + (d - 48) ≤ cap neg then digitsModel ds (10 * a + (d - 48)) neg else none
      else none := by
  have hg := decimal_ge ds (10 * a + (d - 48))
  unfold decimal at hg
  unfold digitsModel decimal
  simp only [List.all_cons, hd, decide_true, Bool.true_and, List.foldl_cons]
  split <;> split <;> simp_all
  all_goals try split <;> simp_all
  all_goals omega

theorem mul_mag (acc : I64) (a : Nat) (neg : Bool) (ha : acc.val = signed neg a) :
    match I64.checked_mul acc 10#i64 with
    | none => cap neg < 10 * a
    | some m => 10 * a ≤ cap neg ∧ m.val = signed neg (10 * a) := by
  have h := I64.checked_mul_bv_spec acc 10#i64
  cases ho : I64.checked_mul acc 10#i64 <;> rw [ho] at h
  all_goals cases neg <;> simp only [signed, cap, Bool.false_eq_true, if_false, if_true] at ha ⊢
  all_goals scalar_tac

theorem next_mag (m d : I64) (a delta : Nat) (neg : Bool)
    (hm : m.val = signed neg a) (hd : d.val = delta) :
    match (if neg then I64.checked_sub m d else I64.checked_add m d) with
    | none => cap neg < a + delta
    | some v => a + delta ≤ cap neg ∧ v.val = signed neg (a + delta) := by
  cases neg
  · have h := I64.checked_add_bv_spec m d
    simp only [Bool.false_eq_true, if_false]
    cases ho : I64.checked_add m d <;> rw [ho] at h
    all_goals simp only [signed, cap, Bool.false_eq_true, if_false] at hm ⊢
    all_goals scalar_tac
  · have h := I64.checked_sub_bv_spec m d
    simp only [if_true]
    cases ho : I64.checked_sub m d <;> rw [ho] at h
    all_goals simp only [signed, cap, if_true] at hm ⊢
    all_goals scalar_tac

end rustfs_kernel.Solution
