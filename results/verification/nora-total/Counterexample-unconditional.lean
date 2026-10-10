import Spec
import H5iAppLib

/-!
The requested totality statement is false for the extracted model's inputs.
Slices permit length `Usize.max`. Splitting that many separator bytes needs
`Usize.max + 1` output pieces, which cannot fit in a modeled vector.

The provider below places this pattern in its first role rule, making the
failure reachable through `transition`. Check with:
  cd proofs && lake env lean Counterexample.lean
-/

open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Counterexample

set_option maxHeartbeats 1000000

def stars : alloc.vec.Vec U8 :=
  .from (List.replicate Usize.max 42#u8) (by simp)

@[simp] theorem stars_val : stars.slice.val = List.replicate Usize.max 42#u8 := by
  simp [stars, alloc.vec.Vec.from]

theorem push_length {α : Type} (v w : alloc.vec.Vec α) (x : α)
    (h : alloc.vec.Vec.push v x = ok w) : w.val.length = v.val.length + 1 := by
  unfold alloc.vec.Vec.push at h
  h5i_invert h
  simp

theorem split_loop_length (out : alloc.vec.Vec (alloc.vec.Vec U8)) (cur : alloc.vec.Vec U8)
    (h : split_loop stars.slice 42#u8 (alloc.vec.Vec.new _) (alloc.vec.Vec.new _) 0#usize = ok (out, cur)) :
    out.val.length = Usize.max := by
  unfold split_loop at h
  apply loop_ok _ (fun x => x.1.val.length = x.2.2.val)
    (fun y => y.1.val.length = Usize.max) (fun x => Usize.max - x.2.2.val)
    ?_ _ _ (by simp) h
  rintro ⟨o, c, i⟩ r hi hr
  have hslen : stars.slice.val.length = Usize.max := by simp
  dsimp only at hi
  unfold split_loop.body at hr
  h5i_invert hr
  · have hb : i2 = 42#u8 := by
      have hb := slice_index_ok_mem hi2
      exact (by simpa using hb : Usize.max ≠ 0 ∧ i2 = 42#u8).2
    simp only [hb] at hx
    h5i_invert hx
    change (do let j ← i + 1#usize
               ok (ControlFlow.cont (out2, alloc.vec.Vec.new U8, j))) = ok r at hr
    h5i_invert hr
    have hl := push_length _ _ _ hout2
    h5i_ok_facts
    dsimp only
    scalar_tac
  · dsimp only
    scalar_tac

theorem split_no_ok (y : alloc.vec.Vec (alloc.vec.Vec U8)) :
    split stars.slice 42#u8 ≠ ok y := by
  intro h
  unfold split at h
  obtain ⟨⟨out, cur⟩, hloop, hpush⟩ := bind_tc_eq_ok.1 h
  have hout := split_loop_length out cur hloop
  have hlen := push_length _ _ _ hpush
  have hy := y.property
  omega

theorem stars_not_single : stars.slice.len ≠ 1#usize := by
  intro h
  have hv := congrArg UScalar.val h
  have hslen : stars.slice.val.length = Usize.max := by simp
  have hm := usize_max_ge
  scalar_tac

theorem stars_not_star : is_star stars.slice = ok false := by
  simp [is_star, stars_not_single]

theorem glob_no_ok (v : Slice U8) (b : Bool) : glob_match stars.slice v ≠ ok b := by
  intro h
  unfold glob_match at h
  rw [stars_not_star] at h
  h5i_invert h
  all_goals exact split_no_ok _ hparts

def provider : OidcProvider := {
  max_token_lifetime_secs := 0#u64
  role_rules := .from [{ pattern := stars, role := alloc.vec.Vec.new _, namespace_scope := none }]
    (by simpa using (Nat.le_of_lt (usize_lt_max (by decide : 1 < 2 ^ 32 - 1))))
  namespace_scope := alloc.vec.Vec.new _
  namespace_scope_enforcement := .Enforce
}

theorem role_no_ok (sub : Slice U8) (y : Option (Role × Option (alloc.vec.Vec (alloc.vec.Vec U8)))) :
    match_role provider sub ≠ ok y := by
  intro h
  unfold match_role match_role_loop at h
  rw [loop] at h
  obtain ⟨cf, hbody, _⟩ := bind_eq_ok.1 h
  unfold match_role_loop.body at hbody
  have hzero : 0#usize < provider.role_rules.len := by
    simp [provider]
  simp only [hzero, if_true] at hbody
  obtain ⟨rule, hrule, hbody⟩ := bind_tc_eq_ok.1 hbody
  have hruleval := vec_index_slice_ok_get? hrule
  simp [provider] at hruleval
  subst rule
  obtain ⟨b, hb, _⟩ := bind_tc_eq_ok.1 hbody
  apply glob_no_ok sub b
  have hd : stars.deref = stars.slice := by
    apply Slice.ext
    simp [alloc.vec.Vec.deref, alloc.vec.Vec.val]
  change glob_match stars.deref sub = ok b at hb
  rwa [hd] at hb

def claims : Claims := { sub := none, iat := none, exp := none }

theorem claims_no_ok (y : core.result.Result OidcIdentity nora_kernel.Error) :
    validate_claims provider claims ≠ ok y := by
  intro h
  unfold validate_claims at h
  simp only [claims] at h
  h5i_invert h
  all_goals exact role_no_ok _ _ ho

theorem transition_not_total (r : Request) :
    ¬ ∃ y, transition provider claims r = ok y := by
  rintro ⟨y, h⟩
  unfold transition at h
  obtain ⟨v, hv, _⟩ := bind_tc_eq_ok.1 h
  exact claims_no_ok v hv

theorem requested_statement_false :
    ¬ (∀ (p : OidcProvider) (c : Claims) (r : Request),
      ∃ y, transition p c r = ok y) := by
  intro h
  exact transition_not_total { method := .Get, is_admin := false, «namespace» := none }
    (h provider claims _)

#print axioms requested_statement_false

end nora_kernel.Counterexample
