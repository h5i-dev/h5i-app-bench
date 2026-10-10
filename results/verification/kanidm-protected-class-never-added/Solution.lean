import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Solution

open Aeneas.Std.WP ControlFlow

theorem bytes_toList (b : ByteArray) : b.toList = b.data.toList := by
  unfold ByteArray.toList
  suffices ∀ i r, ByteArray.toList.loop b i r = r.reverse ++ b.data.toList.drop i by
    simpa using this 0 []
  intro i r
  fun_induction ByteArray.toList.loop b i r
  · rename_i i r hi ih
    rw [ih]
    simp only [List.reverse_cons, List.append_assoc]
    have hlen : i < b.data.toList.length := by
      change i < b.data.size at hi
      simpa only [_root_.Array.length_toList] using hi
    conv => rhs; rw [List.drop_eq_getElem_cons hlen]
    simp only [ByteArray.get!, _root_.Array.getElem_toList]
    rw [getElem!_pos b.data i (by simpa only [_root_.Array.length_toList] using hlen)]
    rfl
  · rename_i i r hi
    have hlen : b.data.toList.length ≤ i := by
      change ¬i < b.data.size at hi
      simpa only [_root_.Array.length_toList] using Nat.le_of_not_gt hi
    simp [List.drop_eq_nil_of_le hlen]

theorem nats_eq_iff (xs ys : List U8) : nats xs = nats ys ↔ xs = ys := by
  induction xs generalizing ys with
  | nil => cases ys <;> simp [nats]
  | cons x xs ih =>
    cases ys with
    | nil => simp [nats]
    | cons y ys =>
      simpa only [nats, List.map_cons, List.cons.injEq, ← u8_eq_iff]
        using and_congr (Iff.rfl : x = y ↔ x = y) (ih ys)

theorem class_bytes : lit "class" = [99, 108, 97, 115, 115] := by
  simp [lit, String.toUTF8, ← String.utf8Encode_toList]
  simp [List.utf8Encode, String.utf8EncodeChar_eq_utf8EncodeCharFast,
    String.utf8EncodeCharFast, bytes_toList]

theorem protected_bytes : protectedModPresClasses =
    [[115, 121, 115, 116, 101, 109],
     [100, 111, 109, 97, 105, 110, 95, 105, 110, 102, 111],
     [115, 121, 115, 116, 101, 109, 95, 105, 110, 102, 111],
     [115, 121, 115, 116, 101, 109, 95, 99, 111, 110, 102, 105, 103],
     [100, 121, 110, 103, 114, 111, 117, 112],
     [115, 121, 110, 99, 95, 111, 98, 106, 101, 99, 116],
     [116, 111, 109, 98, 115, 116, 111, 110, 101],
     [114, 101, 99, 121, 99, 108, 101, 100]] := by
  simp [protectedModPresClasses, protectedEntryClasses, lit, String.toUTF8,
    ← String.utf8Encode_toList]
  simp [List.utf8Encode, String.utf8EncodeChar_eq_utf8EncodeCharFast,
    String.utf8EncodeCharFast, bytes_toList]

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  simp only [nats_eq_iff]
  unfold bset.bytes_eq
  dsimp only
  split
  · rename_i hn
    simp only [spec_ok]
    have hne : a.val ≠ b.val := by
      intro he
      simp [Slice.len, he] at hn
    simp [hne]
  · rename_i he
    have hlen : a.val.length = b.val.length := by scalar_tac
    unfold bset.bytes_eq_loop
    apply spec_mono (loop_search (a.val.zip b.val)
      (fun p => !decide (p.1 = p.2)) id (fun _ _ => false) true _ ?_ 0#usize (by simp))
    · intro r hr
      have hs := search_all _ _ _ hr
      simpa [Bool.not_not, zip_all_eq _ _ hlen] using hs
    · intro i hi
      unfold bset.bytes_eq_loop.body
      step*
      all_goals simp_all [SearchStep, List.length_zip, List.getElem_zip]
      all_goals scalar_tac

@[step] theorem contains_spec (xs : Slice (alloc.vec.Vec U8)) (x : Slice U8) :
    bset.contains xs x ⦃ b => b = decide (nats x.val ∈ names xs.val) ⦄ := by
  unfold bset.contains bset.contains_loop
  h5i_search_any xs.val (fun v => decide (nats v.val = nats x.val))
  all_goals simp_all [names, List.mem_map, eq_comm, alloc.vec.Vec.deref]
  all_goals first
    | scalar_tac
    | (apply Bool.eq_iff_iff.2; simp only [decide_eq_true_eq, List.any_eq_true])

@[step] theorem protected_pres_spec (c : Slice U8) :
    protected.protected_mod_pres_entry_classes c
      ⦃ b => b = decide (nats c.val ∈ protectedModPresClasses) ⦄ := by
  unfold protected.protected_mod_pres_entry_classes
  step*
  all_goals simp_all [protected_bytes, nats,
    Array.to_slice, Array.make]

theorem push_val {α} {xs ys : alloc.vec.Vec α} {x : α}
    (h : alloc.vec.Vec.push xs x = ok ys) : ys.val = xs.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  h5i_invert h
  simp [List.concat_eq_append]

theorem insert_mem (xs ys : alloc.vec.Vec (alloc.vec.Vec U8)) (x : Slice U8)
    (h : bset.insert xs x = ok ys) :
    ∀ c, c ∈ names ys.val ↔ c ∈ names xs.val ∨ c = nats x.val := by
  unfold bset.insert at h
  h5i_invert h
  · have hb := post_of_ok (contains_spec _ _) hb
    intro c
    simp_all [alloc.vec.Vec.deref]
  · have hv := post_of_ok
      (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 x (fun _ _ => rfl)) hv
    have hp := push_val h
    intro c
    simp_all [names, alloc.vec.Vec.deref, alloc.vec.Vec.val]

theorem extend_mem (xs ys : alloc.vec.Vec (alloc.vec.Vec U8))
    (zs : Slice (alloc.vec.Vec U8)) (h : bset.extend xs zs = ok ys) :
    ∀ c, c ∈ names ys.val ↔ c ∈ names xs.val ∨ c ∈ names zs.val := by
  unfold bset.extend bset.extend_loop at h
  apply loop_idx_ok _ Prod.snd zs.val.length
    (fun s => ∀ c, c ∈ names s.1.val ↔
      c ∈ names xs.val ∨ c ∈ names (zs.val.take s.2.val))
    (fun out => ∀ c, c ∈ names out.val ↔ c ∈ names xs.val ∨ c ∈ names zs.val)
    ?_ (xs, 0#usize) ys (by simp [names]) (by simp) h
  rintro ⟨out, i⟩ r hinv hi hr
  unfold bset.extend_loop.body at hr
  dsimp only at hr
  h5i_invert hr
  · have hv := slice_index_ok hv
    have hs := insert_mem _ _ _ hset1
    have ha : i2.val = i.val + 1 := by h5i_arith
    have hlt : i.val < zs.val.length := by scalar_tac
    refine ⟨?_, by scalar_tac, by scalar_tac⟩
    intro c
    dsimp only
    simp only [ha, List.take_succ_eq_append_getElem hlt, names,
      List.map_append, List.map_cons, List.map_nil, List.mem_append,
      List.mem_singleton]
    have hs' : c ∈ names set1.val ↔ c ∈ names out.val ∨ c = nats v.val := by
      simpa [alloc.vec.Vec.deref] using hs c
    simpa [names, hv.2, or_assoc] using
      (hs'.trans (or_congr (hinv c) Iff.rfl))
  · have he : i.val = zs.val.length := by scalar_tac
    simpa [he] using hinv

@[step] theorem subset_spec (xs ys : Slice (alloc.vec.Vec U8)) :
    bset.is_subset xs ys ⦃ b => b = decide (names xs.val ⊆ names ys.val) ⦄ := by
  unfold bset.is_subset bset.is_subset_loop
  h5i_search_all xs.val (fun v => !decide (nats v.val ∈ names ys.val))
  all_goals simp_all [alloc.vec.Vec.deref, alloc.vec.Vec.val]
  all_goals first
    | scalar_tac
    | (rename_i hr; rw [← hr];
       apply Bool.eq_iff_iff.2;
       simp only [List.all_eq_true, decide_eq_true_eq];
       change (∀ x ∈ xs.val, nats x.val ∈ names ys.val) ↔ names xs.val ⊆ names ys.val;
       exact List.forall_mem_map.symm)

theorem remove_protected_safe (xs : Slice (alloc.vec.Vec U8))
    (ys : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : protected.remove_protected_mod_pres xs = ok ys) :
    ∀ c ∈ names ys.val, c ∉ protectedModPresClasses := by
  unfold protected.remove_protected_mod_pres protected.remove_protected_mod_pres_loop at h
  apply loop_idx_ok _ Prod.snd xs.val.length
    (fun s => ∀ c ∈ names s.1.val, c ∉ protectedModPresClasses)
    (fun out => ∀ c ∈ names out.val, c ∉ protectedModPresClasses)
    ?_ _ ys (by simp [names, alloc.vec.Vec.new]) (by simp) h
  rintro ⟨out, i⟩ r hinv hi hr
  unfold protected.remove_protected_mod_pres_loop.body at hr
  dsimp only at hr
  simp only [u8vec_clone] at hr
  h5i_invert hr
  ·
    h5i_invert hout1
    · exact ⟨hinv, by h5i_arith, by h5i_arith⟩
    · have hb := post_of_ok (protected_pres_spec _) hb
      have hp := push_val hout1
      refine ⟨?_, by h5i_arith, by h5i_arith⟩
      intro c hc
      simp only [hp, names, List.map_append, List.map_cons, List.map_nil,
        List.mem_append, List.mem_singleton] at hc
      rcases hc with hc | rfl
      · exact hinv _ hc
      · have hn : b ≠ true := by assumption
        rw [hb] at hn
        simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using hn
  · exact hinv

theorem present_class_mem (entry : Entry) (a : alloc.vec.Vec U8) (v : PartialValue)
    (c : List Nat) (ps rs : alloc.vec.Vec (alloc.vec.Vec U8))
    (hc : nats a.val = lit "class") (hv : strOf v = some c)
    (h : access.modify_class_change entry (.Present a v) = ok (some (ps, rs))) :
    c ∈ names ps.val := by
  cases v <;> simp only [strOf, Option.some.injEq, reduceCtorEq] at hv
  all_goals subst c
  all_goals
    unfold access.modify_class_change at h
    dsimp only at h
    h5i_invert h
    simp [lift, Array.to_slice, Array.make] at hs1
    subst s1
    have hb := post_of_ok (bytes_eq_spec _ _) hb
    have hclass : nats a.val = [99, 108, 97, 115, 115] := hc.trans class_bytes
    have he : b = true := by
      rw [hb]
      simp only [decide_eq_true_eq]
      simpa [alloc.vec.Vec.deref, nats] using hclass
    simp only [he, ↓reduceIte] at hpres
    simp only [valueset.to_str, u8vec_clone] at hpres
    h5i_invert hpres
    have hp := push_val hpres
    simp only [Option.some.injEq, Prod.mk.injEq] at h
    rcases h with ⟨rfl, rfl⟩
    simp [hp, names, alloc.vec.Vec.new]

theorem requested_classes_mem (entry : Entry) (ms : Slice Modify)
    (a : alloc.vec.Vec U8) (v : PartialValue) (c : List Nat)
    (ps rs : alloc.vec.Vec (alloc.vec.Vec U8))
    (hm : .Present a v ∈ ms.val) (hc : nats a.val = lit "class")
    (hv : strOf v = some c)
    (h : access.requested_classes entry ms = ok (some (ps, rs))) :
    c ∈ names ps.val := by
  obtain ⟨j, hj, he⟩ := List.getElem_of_mem hm
  unfold access.requested_classes access.requested_classes_loop at h
  -- Once the loop has visited the requested addition, its class stays in the set.
  have hq := loop_idx_ok _ (fun s => s.2.2) ms.val.length
    (fun s => j < s.2.2.val → c ∈ names s.1.val)
    (fun out => match out with | none => True | some p => c ∈ names p.1.val)
    ?_ _ (some (ps, rs)) (by simp) (by simp) h
  · exact hq
  · rintro ⟨pres, rem, i⟩ r hinv hi hr
    unfold access.requested_classes_loop.body at hr
    dsimp only at hr
    h5i_invert hr
    · trivial
    · rcases p with ⟨padd, radd⟩
      obtain ⟨pres', hp, hr⟩ := bind_eq_ok.1 hr
      obtain ⟨rem', hrm, hr⟩ := bind_eq_ok.1 hr
      obtain ⟨i2, hi2, hr⟩ := bind_eq_ok.1 hr
      have heq := result_ok_inj hr
      subst r
      have hidx := slice_index_ok hm_1
      have hx := extend_mem _ _ _ hp
      have ha : i2.val = i.val + 1 := by h5i_arith
      refine ⟨?_, by h5i_arith, by h5i_arith⟩
      intro hjnew
      apply (hx c).2
      by_cases hjold : j < i.val
      · exact Or.inl (hinv hjold)
      · have hji : j = i.val := by dsimp only at hjnew; omega
        have hmcur : m = .Present a v := by
          exact hidx.2.symm.trans (by simpa only [hji] using he)
        rw [hmcur] at ho
        exact Or.inr (by simpa [alloc.vec.Vec.deref] using
          present_class_mem entry a v c padd radd hc hv ho)
    · have hle : ms.val.length ≤ i.val := by scalar_tac
      apply hinv
      dsimp only
      omega

theorem ident_not_grant (ident : Identity) (abr : AccessBasicResult)
    (hn : ident.origin ≠ .Internal .System)
    (h : modify_acc.modify_ident_test ident = ok abr) : abr ≠ .Grant := by
  unfold modify_acc.modify_ident_test identity_impl.access_scope at h
  h5i_invert h <;> simp_all

def SafeModify : modify_acc.ModifyResult → Prop
  | .Deny => True
  | .Grant => False
  | .Allow _ _ pc _ => ∀ c ∈ names pc.val, c ∉ protectedModPresClasses

theorem apply_modify_safe (ident : Identity)
    (acps : Slice profiles.AccessControlModifyResolved) (sas : Slice SyncAgreement)
    (entry : Entry) (r : modify_acc.ModifyResult)
    (hn : ident.origin ≠ .Internal .System)
    (h : modify_acc.apply_modify_access ident acps sas entry = ok r) : SafeModify r := by
  unfold modify_acc.apply_modify_access at h
  obtain ⟨imo, himo, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨uuid, huuid, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨abr, habr, h⟩ := bind_tc_eq_ok.1 h
  -- Only the system identity can bypass the protected-class filter with Grant.
  have hng := ident_not_grant ident abr hn habr
  obtain ⟨dg, hdg, h⟩ := bind_tc_eq_ok.1 h
  have hg : dg.2 = false := by
    cases abr with
    | Deny => simp only [ok.injEq] at hdg; rw [← hdg]
    | Grant => exact False.elim (hng rfl)
    | Ignore => simp only [ok.injEq] at hdg; rw [← hdg]
  rcases dg with ⟨denied, grant⟩
  dsimp only at hg
  subst grant
  obtain ⟨amr, hamr, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨p1, hp1, h⟩ := bind_tc_eq_ok.1 h
  try dsimp only at h
  obtain ⟨amr1, hamr1, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨p2, hp2, h⟩ := bind_tc_eq_ok.1 h
  try dsimp only at h
  obtain ⟨p3, hp3, h⟩ := bind_tc_eq_ok.1 h
  rcases p3 with ⟨d3, cp1, ap1, cr1, ar1, pc1, rc1⟩
  change (if d3 = true then ok .Deny else _) = ok r at h
  h5i_invert h
  · trivial
  · exact remove_protected_safe _ _ hallowed_pres_cls1

theorem per_entry_safe (ctl : AccessControlsInner) (ident : Identity)
    (acps : Slice profiles.AccessControlModifyResolved) (entry : Entry) (ms : Slice Modify)
    (a : alloc.vec.Vec U8) (v : PartialValue) (c : List Nat)
    (hn : ident.origin ≠ .Internal .System) (hm : .Present a v ∈ ms.val)
    (hc : nats a.val = lit "class") (hv : strOf v = some c)
    (h : access.modify_allow_operation_per_entry ctl ident acps entry ms = ok true) :
    c ∉ protectedModPresClasses := by
  unfold access.modify_allow_operation_per_entry at h
  h5i_invert h
  all_goals rcases p with ⟨rcp, rcr⟩
  all_goals try (have hf : (false : Bool) = true := result_ok_inj h; cases hf)
  all_goals obtain ⟨mr, hmr, h⟩ := bind_eq_ok.1 h
  all_goals have hs := apply_modify_safe ident acps _ entry mr hn hmr
  all_goals h5i_invert h
  all_goals try exact False.elim hs
  all_goals
    -- Success requires the requested presence classes to be allowed.
    have hbtrue : b2 = true := by
      by_contra hn2
      rw [if_neg hn2] at hdecision2
      simp at hdecision2
    have hsub := post_of_ok (subset_spec _ _) hb2
    have hsubset : names rcp.val ⊆ names a_3.val := by
      simpa [hbtrue, alloc.vec.Vec.deref] using hsub.symm
    exact hs c (hsubset
      (requested_classes_mem entry ms a v c rcp rcr hm hc hv ho))

theorem protected_class_never_added (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry)
    (a : alloc.vec.Vec U8) (v : PartialValue) (c : List Nat)
    (hn : me.ident.origin ≠ .Internal .System) (hne : es.val ≠ [])
    (h : access.modify_allow_operation ctl me es = ok (.Ok true))
    (hm : .Present a v ∈ me.modlist.val) (hc : nats a.val = lit "class") (hv : strOf v = some c) :
    c ∉ protectedModPresClasses := by
  unfold access.modify_allow_operation at h
  h5i_invert h
  unfold access.modify_all_entries access.modify_all_entries_loop at hb
  rw [loop] at hb
  obtain ⟨r, hr, hk⟩ := bind_eq_ok.1 hb
  unfold access.modify_all_entries_loop.body at hr
  dsimp only at hr
  have hi : (0#usize) < es.len := by
    have hl : 0 < es.val.length := List.length_pos_iff.mpr hne
    scalar_tac
  rw [if_pos hi] at hr
  -- The first entry exists, so overall success includes a successful entry check.
  obtain ⟨entry, he, hr⟩ := bind_eq_ok.1 hr
  obtain ⟨b, hbentry, hr⟩ := bind_eq_ok.1 hr
  by_cases ht : b = true
  · exact per_entry_safe ctl me.ident related_acp.deref entry me.modlist.deref
      a v c hn (by simpa [alloc.vec.Vec.deref] using hm) hc hv (ht ▸ hbentry)
  · rw [if_neg ht] at hr
    have heq := result_ok_inj hr
    subst r
    simp at hk

end kanidm_kernel.Solution
