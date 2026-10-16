import SpecExtras
import Verified.RustfsBytes
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Verified.RustfsPatternPrefix

def Inv (p t : List U8) (i : Nat) : Prop :=
  i ≤ p.length ∧ i ≤ t.length ∧ ∀ j < i,
    p[j]? ≠ some (42#u8) ∧ (p[j]? = some (63#u8) ∨ p[j]? = t[j]?)

theorem star_accept (p t : List U8) (i : Nat) (hi : Inv p t i)
    (hp : i < p.length) (ht : i < t.length) (hs : p[i]? = some (42#u8)) :
    PatternPrefix p t :=
  ⟨i,hi.1,hi.2.1,fun j hj => (hi.2.2 j hj).2,Or.inl ⟨hp,ht,hs⟩⟩

theorem end_accept (p t : List U8) (i : Nat) (hi : Inv p t i) (ht : t.length ≤ i) :
    PatternPrefix p t := by
  have ht2 := hi.2.1
  have he : i = t.length := by omega
  exact ⟨i,hi.1,hi.2.1,fun j hj => (hi.2.2 j hj).2,Or.inr he⟩

theorem advance (p t : List U8) (i : Nat) (hi : Inv p t i)
    (hp : i < p.length) (ht : i < t.length) (hs : p[i]? ≠ some (42#u8))
    (ha : p[i]? = some (63#u8) ∨ p[i]? = t[i]?) : Inv p t (i+1) := by
  refine ⟨by omega,by omega,fun j hj => ?_⟩
  by_cases hji : j < i
  · exact hi.2.2 j hji
  · have he : j = i := by omega
    simpa [he] using And.intro hs ha

theorem mismatch_reject (p t : List U8) (i : Nat) (hi : Inv p t i)
    (ht : i < t.length) (hs : p[i]? ≠ some (42#u8))
    (ha : ¬ (p[i]? = some (63#u8) ∨ p[i]? = t[i]?)) : ¬ PatternPrefix p t := by
  rintro ⟨k,hkp,hkt,hagree,hend⟩
  by_cases hik : i < k
  · exact ha (hagree i hik)
  · rcases hend with ⟨_,_,hkstar⟩ | hk
    · by_cases hki : k < i
      · exact (hi.2.2 k hki).1 hkstar
      · have he : k = i := by omega
        exact hs (he ▸ hkstar)
    · omega

theorem short_reject (p t : List U8) (i : Nat) (hi : Inv p t i)
    (hp : p.length ≤ i) (ht : p.length < t.length) : ¬ PatternPrefix p t := by
  rintro ⟨k,hkp,hkt,hagree,hend⟩
  rcases hend with ⟨hk,_,hkstar⟩ | hk
  · exact (hi.2.2 k (by omega)).1 hkstar
  · omega

theorem prefix_ok (p t : Slice U8) (b : Bool)
    (h : extras.is_match_as_pattern_prefix p t = ok b) : (b = true ↔ PatternPrefix p.val t.val) := by
  unfold extras.is_match_as_pattern_prefix extras.is_match_as_pattern_prefix_loop at h
  refine loop_ok _ (fun i : Usize => Inv p.val t.val i.val)
    (fun b => b = true ↔ PatternPrefix p.val t.val)
    (fun i => p.val.length - i.val) ?_ _ b ⟨by simp,by simp,by simp⟩ h
  intro i r hi hr
  unfold extras.is_match_as_pattern_prefix_loop.body at hr
  h5i_invert hr
  · obtain ⟨hp,hpx⟩ := slice_index_ok hx
    obtain ⟨ht,hty⟩ := slice_index_ok hy
    simp only [true_iff]
    exact star_accept _ _ _ hi hp ht (by rw [List.getElem?_eq_getElem hp,hpx,hc_2])
  · obtain ⟨hp,hpx⟩ := slice_index_ok hx
    obtain ⟨ht,hty⟩ := slice_index_ok hy
    have hxp : p.val[i.val]? = some x := by rw [List.getElem?_eq_getElem hp,hpx]
    have hyt : t.val[i.val]? = some y := by rw [List.getElem?_eq_getElem ht,hty]
    simp only [Bool.false_eq_true, false_iff]
    apply mismatch_reject _ _ _ hi ht
    · simpa [hxp] using hc_2
    · simpa [hxp,hyt] using And.intro hc_3 hc_4
  · obtain ⟨hp,hpx⟩ := slice_index_ok hx
    obtain ⟨ht,hty⟩ := slice_index_ok hy
    have hxp : p.val[i.val]? = some x := by rw [List.getElem?_eq_getElem hp,hpx]
    have hyt : t.val[i.val]? = some y := by rw [List.getElem?_eq_getElem ht,hty]
    have hadd := add_ok_val hi3
    have he : i3.val = i.val+1 := by scalar_tac
    constructor
    · rw [he]
      apply advance _ _ _ hi hp ht
      · simpa [hxp] using hc_2
      · right
        have hxy : x = y := by scalar_tac
        simp [hxp,hyt,hxy]
    · scalar_tac
  · obtain ⟨hp,hpx⟩ := slice_index_ok hx
    obtain ⟨ht,hty⟩ := slice_index_ok hy
    have hxp : p.val[i.val]? = some x := by rw [List.getElem?_eq_getElem hp,hpx]
    have hadd := add_ok_val hi3
    have he : i3.val = i.val+1 := by scalar_tac
    constructor
    · rw [he]
      apply advance _ _ _ hi hp ht
      · simpa [hxp] using hc_2
      · left
        have hxq : x = 63#u8 := by scalar_tac
        simp [hxp,hxq]
    · scalar_tac
  · have hip := hi.1
    have hit := hi.2.1
    have htp : t.len ≤ p.len := by scalar_tac
    simp only [htp,decide_true,true_iff]
    exact end_accept _ _ _ hi (by scalar_tac)
  · have hip := hi.1
    have hit := hi.2.1
    by_cases htp : t.len ≤ p.len
    · simp only [htp,decide_true,true_iff]
      exact end_accept _ _ _ hi (by scalar_tac)
    · simp only [htp,decide_false,Bool.false_eq_true,false_iff]
      exact short_reject _ _ _ hi (by scalar_tac) (by scalar_tac)
end rustfs_kernel.Verified.RustfsPatternPrefix
