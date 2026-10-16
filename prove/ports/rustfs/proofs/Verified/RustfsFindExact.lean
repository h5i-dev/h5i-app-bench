import Verified.RustfsBytes
import SpecAwsExpansion
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsFindExact
set_option maxHeartbeats 2000000
theorem first_unique (s p : List U8) (offset : Nat) (a b : Option Nat)
    (ha : FirstOccurrence s p offset a) (hb : FirstOccurrence s p offset b) : a=b := by
  cases a with
  | none =>
    cases b with
    | none => rfl
    | some j => exact False.elim (ha j hb.1 hb.2.1)
  | some i =>
    cases b with
    | none => exact False.elim (hb i ha.1 ha.2.1)
    | some j =>
      have hij : i=j := by
        rcases lt_trichotomy i j with h | h | h
        · exact False.elim (hb.2.2 i ha.1 h ha.2.1)
        · exact h
        · exact False.elim (ha.2.2 j hb.1 h hb.2.1)
      simp [hij]
theorem find_ok (s p : Slice U8) (f : Usize) (o : Option Usize)
    (h : bytes.find_from s f p = ok o) : FirstOccurrence s.val p.val f.val (o.map (·.val)) := by
  unfold bytes.find_from bytes.find_from_loop at h
  refine loop_ok _ (fun i : Usize => f.val ≤ i.val ∧
      ∀ k, f.val ≤ k → k < i.val → ¬ByteOccurrence s.val p.val k)
    (fun o => FirstOccurrence s.val p.val f.val (o.map (·.val)))
    (fun i : Usize => s.val.length+1-i.val) ?_ f o ⟨le_refl _,fun k hk hi => by omega⟩ h
  intro x r hx hr
  unfold bytes.find_from_loop.body at hr
  h5i_invert hr
  · have hp := RustfsBytes.starts_with_at_ok s p x b hb
    exact ⟨hx.1,hp.1 hc_2,hx.2⟩
  · have hsub := sub_ok_val hi3
    have hp := RustfsBytes.starts_with_at_ok s p x b hb
    have hadd := add_ok_val hi5
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    intro k hk hki
    by_cases hlt : k < x.val
    · exact hx.2 k hk hlt
    · have he : k=x.val := by scalar_tac
      subst k
      intro hpre
      exact hc_2 (hp.2 hpre)
  · have hsub := sub_ok_val hi3
    intro k hk
    by_cases hlt : k < x.val
    · exact hx.2 k hk hlt
    · exact RustfsBytes.not_prefAt_short (by scalar_tac)
  · intro k hk
    by_cases hlt : k < x.val
    · exact hx.2 k hk hlt
    · exact RustfsBytes.not_prefAt_short (by scalar_tac)
theorem find_iff (s p : Slice U8) (f : Usize) (o : Option Usize) (expected : Option Nat)
    (h : bytes.find_from s f p = ok o) :
    o.map (·.val) = expected ↔ FirstOccurrence s.val p.val f.val expected := by
  have hs := find_ok s p f o h
  constructor
  · intro he; simpa only [← he] using hs
  · exact first_unique _ _ _ _ _ hs
end rustfs_kernel.Verified.RustfsFindExact
