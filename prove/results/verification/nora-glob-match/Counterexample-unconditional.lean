import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit
namespace Counterexample
set_option maxHeartbeats 2000000

theorem push_length {α} (a b : alloc.vec.Vec α) (x : α)
    (h : alloc.vec.Vec.push a x = ok b) : b.val.length = a.val.length + 1 := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · have he := result_ok_inj h
    subst b
    simp
  · simp at h

theorem all_stars_loop (s : Slice U8) (hs : ∀ x ∈ s.val, x = 42#u8)
    (out : alloc.vec.Vec (alloc.vec.Vec U8)) (cur : alloc.vec.Vec U8) (i : Usize)
    (hi : i.val ≤ s.val.length) (ho : out.val.length = i.val)
    (r : alloc.vec.Vec (alloc.vec.Vec U8) × alloc.vec.Vec U8)
    (hr : split_loop s 42#u8 out cur i = ok r) :
    r.1.val.length = s.val.length := by
  unfold split_loop at hr
  apply loop_ok _
    (fun st => st.2.2.val ≤ s.val.length ∧ st.1.val.length = st.2.2.val)
    (fun r => r.1.val.length = s.val.length)
    (fun st => s.val.length - st.2.2.val) ?_ (out, cur, i) r ⟨hi, ho⟩ hr
  rintro ⟨o, c, j⟩ cf ⟨hj, hlen⟩ hstep
  simp only at hj hlen ⊢
  unfold split_loop.body at hstep
  h5i_invert hstep
  · have hstar := hs _ (slice_index_ok_mem hi2)
    subst i2
    h5i_invert hx
    change (do let k ← j + 1#usize
               ok (ControlFlow.cont (out2, alloc.vec.Vec.new U8, k))) = ok cf at hstep
    h5i_invert hstep
    have hpush := push_length _ _ _ hout2
    have hadd := add_ok_val hk
    simp only [UScalar.ofNatCore_val_eq] at hadd
    change (k.val ≤ s.val.length ∧ out2.val.length = k.val) ∧
      s.val.length - k.val < s.val.length - j.val
    constructor
    · constructor
      · scalar_tac
      · omega
    · scalar_tac
  · simp only
    scalar_tac

theorem split_all_stars_impossible (s : Slice U8)
    (hlen : s.val.length = Usize.max)
    (hs : ∀ x ∈ s.val, x = 42#u8)
    (r : alloc.vec.Vec (alloc.vec.Vec U8)) : split s 42#u8 ≠ ok r := by
  intro h
  unfold split at h
  obtain ⟨st, hst, hpush⟩ := bind_eq_ok.mp h
  have he := all_stars_loop s hs _ _ 0#usize (by simp) (by simp) st hst
  have hp := push_length _ _ _ hpush
  have hb := r.property
  omega

def longStars : Slice U8 :=
  Slice.from (List.replicate Usize.max 42#u8) (by simp)

theorem longStars_length : longStars.val.length = Usize.max := by
  simp [longStars]

theorem longStars_star : is_star longStars = ok false := by
  unfold is_star
  dsimp only
  have hn : longStars.len ≠ 1#usize := by
    have hg := usize_max_ge
    have hl := longStars_length
    scalar_tac
  rw [if_neg hn]

theorem longStars_no_result (v : Slice U8) (b : Bool) :
    glob_match longStars v ≠ ok b := by
  intro h
  unfold glob_match at h
  simp only [longStars_star, bind_ok, Bool.false_eq_true, if_false] at h
  obtain ⟨parts, hp, _⟩ := bind_eq_ok.mp h
  exact split_all_stars_impossible longStars longStars_length
    (by simp [longStars]) parts hp

theorem requested_statement_is_false :
    ¬ (∀ pattern v : Slice U8,
      glob_match pattern v = ok (globSpec (nats pattern.val) (nats v.val))) := by
  intro h
  exact longStars_no_result (Slice.new U8) _ (h longStars (Slice.new U8))

end Counterexample

-- Audit the proof's dependencies: there is no sorryAx or custom assumption.
#print axioms Counterexample.requested_statement_is_false
