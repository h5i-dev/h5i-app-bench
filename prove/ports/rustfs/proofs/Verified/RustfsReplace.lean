import SpecSubstitution
import Verified.RustfsBytes
import Verified.RustfsForceDelete
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Verified.RustfsReplace
set_option maxHeartbeats 2000000
open RustfsBytes (push_ok starts_with_at_ok PrefAt)

theorem append_loop (replacement : Slice U8) (initial out : alloc.vec.Vec U8)
    (h : bytes.replace_loop0_loop0 replacement initial 0#usize = ok out) :
    out.val = initial.val ++ replacement.val := by
  unfold bytes.replace_loop0_loop0 at h
  refine loop_ok _ (fun s : alloc.vec.Vec U8 × Usize => s.2.val≤replacement.val.length ∧
      s.1.val=initial.val++replacement.val.take s.2.val)
    (fun out => out.val=initial.val++replacement.val)
    (fun s => replacement.val.length-s.2.val) ?_ _ out ⟨by simp,by simp⟩ h
  rintro ⟨acc,i⟩ result ⟨hi,he⟩ hr
  unfold bytes.replace_loop0_loop0.body at hr
  h5i_invert hr
  · obtain ⟨hlt,hv⟩ := slice_index_ok hi1
    have hadd : j1.val=i.val+1 := by have := add_ok_val hj1; scalar_tac
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    rw [push_ok hout1,he]
    change _ = initial.val ++ replacement.val.take j1.val
    rw [hadd,List.take_add_one,List.getElem?_eq_getElem hlt,hv]
    simp
  · have hn : replacement.val.length ≤ i.val := by scalar_tac
    simpa only [List.take_of_length_le hn] using he

theorem prefix_iff (s p : List U8) (offset : Nat) (hl : offset ≤ s.length) :
    PrefAt s p offset ↔ p <+: s.drop offset := by
  constructor
  · rintro ⟨hlen,hentries⟩
    apply List.prefix_iff_getElem?.mpr
    intro j hj
    rw [List.getElem?_drop]
    exact (hentries j hj).trans (List.getElem?_eq_getElem hj)
  · intro hp
    refine ⟨by have := hp.length_le; simp only [List.length_drop] at this; omega,?_⟩
    intro j hj
    have hh := List.prefix_iff_getElem?.mp hp j hj
    simpa only [List.getElem?_drop, List.getElem?_eq_getElem hj] using hh

theorem replace_ok (s search replacement : Slice U8) (out : alloc.vec.Vec U8)
    (h : bytes.replace s search replacement = ok out) :
    out.val = ReplaceBytes s.val search.val replacement.val := by
  unfold bytes.replace bytes.replace_loop0 at h
  refine loop_ok _ (fun x : alloc.vec.Vec U8 × Usize => x.2.val ≤ s.val.length ∧
      x.1.val ++ ReplaceSuffix s.val search.val replacement.val x.2.val =
        ReplaceBytes s.val search.val replacement.val)
    (fun out => out.val=ReplaceBytes s.val search.val replacement.val)
    (fun x => s.val.length-x.2.val) ?_ _ out ⟨by simp,by rfl⟩ h
  rintro ⟨acc,i⟩ result ⟨hi,he⟩ hr
  unfold bytes.replace_loop0.body at hr
  h5i_invert hr
  · have hlt : i.val<s.val.length := by scalar_tac
    have hpos : 0<search.val.length := by scalar_tac
    have hp := (starts_with_at_ok s search i b hb).mp hc_2
    have hbound := hp.1
    have hprefix := (prefix_iff _ _ _ (by omega)).mp hp
    have hpred : 0<search.val.length ∧ search.val <+: s.val.drop i.val := ⟨hpos,hprefix⟩
    have hadd : i4.val=i.val+search.val.length := by have := add_ok_val hi4; scalar_tac
    simp only [Prod.fst,Prod.snd] at hi he ⊢
    rw [ReplaceSuffix] at he
    simp only [dif_pos hlt,dif_pos hpred] at he
    refine ⟨⟨by omega,?_⟩,by omega⟩
    rw [append_loop _ _ _ hout1,hadd,List.append_assoc]
    exact he
  · have hlt : i.val<s.val.length := by scalar_tac
    have hp : ¬ (0<search.val.length ∧ search.val <+: s.val.drop i.val) := by
      intro hh
      exact hc_2 ((starts_with_at_ok s search i b hb).mpr
        ((prefix_iff _ _ _ (by omega)).mpr hh.2))
    obtain ⟨_,hv⟩ := slice_index_ok hi3
    have hadd : i4.val=i.val+1 := by have := add_ok_val hi4; scalar_tac
    simp only [Prod.fst,Prod.snd] at hi he ⊢
    rw [ReplaceSuffix] at he
    simp only [dif_pos hlt,dif_neg hp] at he
    refine ⟨⟨by omega,?_⟩,by omega⟩
    rw [push_ok hout1,hadd,List.append_assoc]
    simpa only [hv,List.singleton_append] using he
  · have hlt : i.val<s.val.length := by scalar_tac
    have hp : ¬ (0<search.val.length ∧ search.val <+: s.val.drop i.val) := by
      intro hh
      have : 0<search.val.length := hh.1
      scalar_tac
    obtain ⟨_,hv⟩ := slice_index_ok hi3
    have hadd : i4.val=i.val+1 := by have := add_ok_val hi4; scalar_tac
    simp only [Prod.fst,Prod.snd] at hi he ⊢
    rw [ReplaceSuffix] at he
    simp only [dif_pos hlt,dif_neg hp] at he
    refine ⟨⟨by omega,?_⟩,by omega⟩
    rw [push_ok hout1,hadd,List.append_assoc]
    simpa only [hv,List.singleton_append] using he
  · have hlt : ¬i.val<s.val.length := by scalar_tac
    simp only [Prod.fst,Prod.snd] at he
    rw [ReplaceSuffix] at he
    simpa only [dif_neg hlt,List.append_nil] using he
end rustfs_kernel.Verified.RustfsReplace
