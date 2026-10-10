import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Solution

def signed (neg : Bool) (v : Nat) : Int := if neg then -(v : Int) else v

/-- The negative magnitude may reach `2^63`; the positive one may not. -/
def limit (neg : Bool) : Nat := if neg then 2 ^ 63 else 2 ^ 63 - 1

def decimal (ds : List Nat) (a : Nat) : Nat :=
  ds.foldl (fun acc d => 10 * acc + (d - 48)) a

def digit (d : Nat) : Bool := decide (48 ≤ d ∧ d ≤ 57)

def digitsModel (neg : Bool) (ds : List Nat) (a : Nat) : Option Int :=
  if ds.all digit ∧ decimal ds a ≤ limit neg then some (signed neg (decimal ds a)) else none

/-- Appending digits cannot bring an overflowing magnitude back into range. -/
theorem decimal_ge (ds : List Nat) (a : Nat) : a ≤ decimal ds a := by
  induction ds generalizing a with
  | nil => simp [decimal]
  | cons d ds ih =>
    have := ih (10 * a + (d - 48))
    simp only [decimal, List.foldl_cons] at *
    omega

theorem signed_bounds (neg : Bool) (a : Nat) :
    (I64.min ≤ signed neg a ∧ signed neg a ≤ I64.max) ↔ a ≤ limit neg := by
  cases neg <;> simp [signed, limit, I64.min, I64.max, I64.numBits]

theorem signed_range (neg : Bool) (a : Nat) :
    (-(2 ^ 63 : Int) ≤ signed neg a ∧ signed neg a < 2 ^ 63) ↔ a ≤ limit neg := by
  cases neg <;> simp [signed, limit] <;> omega

theorem digitsModel_eq_spec (neg : Bool) (ds : List Nat) (hne : ds ≠ []) :
    digitsModel neg ds 0 =
      match digitsVal ds with
      | none => none
      | some v => if -(2 ^ 63 : Int) ≤ signed neg v ∧ signed neg v < 2 ^ 63
          then some (signed neg v) else none := by
  cases ds with
  | nil => contradiction
  | cons d ds =>
    simp only [digitsModel, digitsVal, decimal, signed_range]
    split
    · simp_all [digit]
    · split <;> simp_all [digit]

theorem parseI64Spec_unsigned (d : Nat) (ds : List Nat)
    (hm : d ≠ 45) (hp : d ≠ 43) :
    parseI64Spec (d :: ds) = digitsModel false (d :: ds) 0 := by
  rw [digitsModel_eq_spec false (d :: ds) (by simp)]
  delta parseI64Spec
  split
  rename_i p neg rest hsign
  split at hsign <;> simp_all [signed]
  rfl

theorem digitsModel_nil (neg : Bool) (a : Nat) (ha : a ≤ limit neg) :
    digitsModel neg [] a = some (signed neg a) := by
  simp [digitsModel, decimal, ha]

theorem digitsModel_bad (neg : Bool) (ds : List Nat) (a d : Nat)
    (hd : ¬ (48 ≤ d ∧ d ≤ 57)) : digitsModel neg (d :: ds) a = none := by
  simp [digitsModel, digit, hd]

theorem digitsModel_cons (neg : Bool) (ds : List Nat) (a d : Nat)
    (hd : 48 ≤ d ∧ d ≤ 57) :
    digitsModel neg (d :: ds) a = digitsModel neg ds (10 * a + (d - 48)) := by
  simp [digitsModel, digit, hd, decimal]

theorem digitsModel_overflow (neg : Bool) (ds : List Nat) (a : Nat)
    (ha : limit neg < a) : digitsModel neg ds a = none := by
  have := decimal_ge ds a
  simp [digitsModel, show ¬ decimal ds a ≤ limit neg by omega]

theorem checked_scale (acc : I64) (neg : Bool) (a : Nat)
    (hacc : acc.val = signed neg a) :
    match I64.checked_mul acc 10#i64 with
    | none => limit neg < 10 * a
    | some m => m.val = signed neg (10 * a) := by
  have h := I64.checked_mul_bv_spec acc 10#i64
  cases hm : I64.checked_mul acc 10#i64 with
  | none =>
    simp only [I64.checked_mul] at hm
    rw [hm] at h
    cases neg <;> simp [signed, limit, I64.min, I64.max, I64.numBits] at * <;> omega
  | some m =>
    simp only [I64.checked_mul] at hm
    rw [hm] at h
    cases neg <;> simp [signed] at * <;> omega

theorem checked_digit (m d : I64) (neg : Bool) (a b : Nat)
    (hm : m.val = signed neg a) (hd : d.val = b) :
    match (if neg then I64.checked_sub m d else I64.checked_add m d) with
    | none => limit neg < a + b
    | some v => v.val = signed neg (a + b) := by
  cases neg with
  | false =>
    simp only [Bool.false_eq_true, if_false]
    have h := I64.checked_add_bv_spec m d
    cases hv : I64.checked_add m d with
    | none =>
      simp only [I64.checked_add] at hv
      rw [hv] at h
      simp [signed, limit, I64.min, I64.max, I64.numBits] at *
      omega
    | some v =>
      simp only [I64.checked_add] at hv
      rw [hv] at h
      simp [signed] at *
      omega
  | true =>
    simp only [if_true]
    have h := I64.checked_sub_bv_spec m d
    cases hv : I64.checked_sub m d with
    | none =>
      simp only [I64.checked_sub] at hv
      rw [hv] at h
      simp [signed, limit, I64.min, I64.max, I64.numBits] at *
      omega
    | some v =>
      simp only [I64.checked_sub] at hv
      rw [hv] at h
      simp [signed] at *
      omega

/-- The recursive parser computes the decimal fold of the remaining bytes. -/
theorem parse_digits_spec (ds : List U8) (s : Slice U8) (i : Usize)
    (acc : I64) (neg : Bool) (a : Nat)
    (hi : i.val ≤ s.val.length) (hds : s.val.drop i.val = ds)
    (hacc : acc.val = signed neg a) :
    bytes.parse_digits s i acc neg ⦃ r => r.map (·.val) = digitsModel neg (nats ds) a ⦄ := by
  induction ds generalizing i acc a with
  | nil =>
    have hend : i.val = s.val.length := by
      have := congrArg List.length hds
      simp only [List.length_drop, List.length_nil] at this
      omega
    have ha : a ≤ limit neg := (signed_bounds neg a).1 (by rw [← hacc]; scalar_tac)
    rw [bytes.parse_digits]
    simp only [show i ≥ Slice.len s by scalar_tac, reduceIte, WP.spec_ok,
      Option.map_some, hacc, nats, List.map_nil, digitsModel_nil neg a ha]
  | cons c ds ih =>
    have hlt : i.val < s.val.length := by
      have := congrArg List.length hds
      simp only [List.length_drop, List.length_cons] at this
      omega
    have hc : s.val[i.val] = c := by
      rw [List.drop_eq_getElem_cons hlt] at hds
      exact (List.cons.inj hds).1
    have htail : s.val.drop (i.val + 1) = ds := by
      rw [List.drop_eq_getElem_cons hlt] at hds
      exact (List.cons.inj hds).2
    rw [bytes.parse_digits]
    simp only [show ¬ i ≥ Slice.len s by scalar_tac, reduceIte]
    step as ⟨c', hc'⟩
    have heq : c' = c := hc'.trans hc
    subst c'
    rw [hc]
    split
    · rename_i hbad
      simp only [WP.spec_ok, Option.map_none]
      exact (digitsModel_bad neg (nats ds) a c.val (by scalar_tac)).symm
    · split
      · rename_i hbad
        simp only [WP.spec_ok, Option.map_none]
        exact (digitsModel_bad neg (nats ds) a c.val (by scalar_tac)).symm
      · rename_i hlo hhi
        have hd : 48 ≤ c.val ∧ c.val ≤ 57 := by scalar_tac
        change _ ⦃ (r : Option I64) => r.map (·.val) = digitsModel neg (c.val :: nats ds) a ⦄
        rw [digitsModel_cons neg (nats ds) a c.val hd]
        step as ⟨b, hb, hb'⟩
        step with UScalar.hcast_inBounds_spec .I64 b (by scalar_tac) as ⟨d, hdval⟩
        have hdval' : d.val = (c.val - 48 : Nat) := by omega
        simp only [lift, bind_ok]
        have hscale := checked_scale acc neg a hacc
        cases hmul : I64.checked_mul acc 10#i64 with
        | none =>
          rw [hmul] at hscale
          simp only [WP.spec_ok, Option.map_none]
          exact (digitsModel_overflow neg (nats ds) _ (by omega)).symm
        | some m =>
          rw [hmul] at hscale
          have hnext := checked_digit m d neg (10 * a) (c.val - 48) hscale hdval'
          dsimp only
          rw [show (if neg then ok (I64.checked_sub m d) else ok (I64.checked_add m d)) =
            ok (if neg then I64.checked_sub m d else I64.checked_add m d) by cases neg <;> rfl]
          simp only [bind_ok]
          cases hn : (if neg then I64.checked_sub m d else I64.checked_add m d) with
          | none =>
            rw [hn] at hnext
            simp only [WP.spec_ok, Option.map_none]
            exact (digitsModel_overflow neg (nats ds) _ hnext).symm
          | some v =>
            rw [hn] at hnext
            step as ⟨j, hj⟩
            apply ih j v (10 * a + (c.val - 48)) (by scalar_tac) ?_ hnext
            simpa only [hj] using htail

theorem parse_i64_spec (s : Slice U8) :
    ∃ r, bytes.parse_i64 s = ok r ∧ r.map (·.val) = parseI64Spec (nats s.val) := by
  apply (WP.spec_equiv_exists _ _).1
  cases hs : s.val with
  | nil =>
    unfold bytes.parse_i64
    have hlen : Slice.len s = 0#usize := by scalar_tac
    simp only [hlen, if_true, WP.spec_ok, Option.map_none]
    rfl
  | cons c ds =>
    unfold bytes.parse_i64
    have hlen : Slice.len s ≠ 0#usize := by scalar_tac
    simp only [hlen, reduceIte]
    step as ⟨c', hc'⟩
    have hc : s.val[0]'(by scalar_tac) = c := by simp [hs]
    have heq : c' = c := hc'.trans hc
    subst c'
    rw [hc]
    split
    · rename_i hminus
      simp only [bind_ok]
      split
      · rename_i hend
        have hnil : ds = [] := by
          have hv := congrArg UScalar.val hend
          have hl : ds.length = 0 := by scalar_tac
          exact List.length_eq_zero_iff.mp hl
        subst ds
        rw [hminus]
        simp only [WP.spec_ok, Option.map_none]
        rfl
      · rename_i hmore
        have hne : nats ds ≠ [] := by
          intro hempty
          have hl : ds.length = 0 := by simpa [nats] using congrArg List.length hempty
          apply hmore
          scalar_tac
        rw [hminus]
        simp only [decide_true]
        apply WP.spec_mono (parse_digits_spec ds s 1#usize 0#i64 true 0
          (by scalar_tac) (by simp [hs]) (by simp [signed]))
        intro r hr
        rw [hr, digitsModel_eq_spec true (nats ds) hne]
        rfl
    · split
      · rename_i hplus
        simp only [bind_ok]
        split
        · rename_i hend
          have hnil : ds = [] := by
            have hv := congrArg UScalar.val hend
            have hl : ds.length = 0 := by scalar_tac
            exact List.length_eq_zero_iff.mp hl
          subst ds
          rw [hplus]
          simp only [WP.spec_ok, Option.map_none]
          rfl
        · rename_i hmore
          have hne : nats ds ≠ [] := by
            intro hempty
            have hl : ds.length = 0 := by simpa [nats] using congrArg List.length hempty
            apply hmore
            scalar_tac
          rw [hplus]
          simp only [show (43#u8 : U8) ≠ 45#u8 by decide, decide_false]
          apply WP.spec_mono (parse_digits_spec ds s 1#usize 0#i64 false 0
            (by scalar_tac) (by simp [hs]) (by simp [signed]))
          intro r hr
          rw [hr, digitsModel_eq_spec false (nats ds) hne]
          rfl
      · rename_i hminus hplus
        simp only [bind_ok]
        split
        · rename_i hend
          exact False.elim (hlen hend.symm)
        · simp only [hminus, decide_false]
          apply WP.spec_mono (parse_digits_spec (c :: ds) s 0#usize 0#i64 false 0
            (by scalar_tac) (by simpa using hs) (by simp [signed]))
          intro r hr
          rw [hr]
          have hm : c.val ≠ 45 := by intro h; apply hminus; scalar_tac
          have hp : c.val ≠ 43 := by intro h; apply hplus; scalar_tac
          exact (parseI64Spec_unsigned c.val (nats ds) hm hp).symm

end rustfs_kernel.Solution
