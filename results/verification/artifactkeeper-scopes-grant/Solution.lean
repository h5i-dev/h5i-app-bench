import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Solution

theorem nats_inj (a b : List U8) : nats a = nats b ↔ a = b := by
  unfold nats
  exact List.map_inj_right (fun _ _ h => u8_eq_iff _ _ |>.mpr h)

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    strs.bytes_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  unfold strs.bytes_eq
  dsimp only
  split
  · rename_i h
    simp only [WP.spec_ok]
    have hn : a.val ≠ b.val := by
      intro he
      have : a.len = b.len := by simp [Slice.len, he]
      simp [this] at h
    simp [nats_inj, hn]
  · rename_i h
    have hlen : a.val.length = b.val.length := by
      scalar_tac
    unfold strs.bytes_eq_loop
    apply WP.spec_mono (loop_search (a.val.zip b.val)
      (fun p => !decide (p.1 = p.2)) id (fun _ _ => false) true _ ?_ 0#usize (by simp))
    · intro r hr
      have hh := search_all _ _ _ hr
      simp only [Bool.not_not] at hh
      simpa only [id, zip_all_eq _ _ hlen, nats_inj] using hh
    · intro i hi
      unfold strs.bytes_eq_loop.body
      h5i_step [List.length_zip, hlen, List.getElem_zip]

@[step] theorem any_eq_spec (xs : Slice (alloc.vec.Vec U8)) (s : Slice U8) :
    strs.any_eq xs s ⦃ r => r = (xs.val.map (fun v => nats v.val)).contains (nats s.val) ⦄ := by
  unfold strs.any_eq strs.any_eq_loop
  apply WP.spec_mono (loop_search xs.val (fun v => decide (nats v.val = nats s.val))
    id (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    have hh := search_any _ _ _ hr
    dsimp only [id] at hh
    rw [hh]
    apply Bool.eq_iff_iff.mpr
    simp only [List.any_eq_true, decide_eq_true_eq, List.contains_iff_mem, List.mem_map]
  · intro i hi
    unfold strs.any_eq_loop.body
    h5i_step [alloc.vec.Vec.deref]

@[step] theorem find_byte_spec (s : Slice U8) (b : U8) :
    strs.find_byte s b ⦃ r => r.map (·.val) = s.val.findIdx? (fun x => decide (x = b)) ⦄ := by
  unfold strs.find_byte strs.find_byte_loop
  apply WP.spec_mono (loop_search s.val (fun x => decide (x = b))
    (fun o => o.map (·.val)) (fun i _ => some i) none _ ?_ 0#usize (by simp))
  · intro r hr
    exact search_findIdx _ _ _ hr
  · intro i hi
    unfold strs.find_byte_loop.body
    h5i_step

@[step] theorem sub_spec (s : Slice U8) (a b : Usize)
    (ha : a.val ≤ b.val) (hb : b.val ≤ s.val.length) :
    strs.sub s a b ⦃ r => r.val = (s.val.take b.val).drop a.val ⦄ := by
  unfold strs.sub strs.sub_loop
  apply WP.spec_mono (loop_fold (s.val.take b.val) (fun v : alloc.vec.Vec U8 => v.val)
    (fun xs x => xs ++ [x]) (fun v i => a.val ≤ i ∧ v.val.length = i - a.val)
    _ ?_ (alloc.vec.Vec.new U8) a (by simp; omega) (by simp))
  · intro r hr
    simpa only [vec_new_val, foldl_snoc, List.nil_append] using hr
  · intro out i hi hI
    unfold strs.sub_loop.body
    h5i_step [List.length_take, Nat.min_eq_left hb, List.getElem_take]

@[step] theorem split_once_spec (s : Slice U8) (b : U8) :
    strs.split_once s b ⦃ r =>
      r.map (fun p => (p.1.val, p.2.val)) = splitOnce b s.val ⦄ := by
  unfold strs.split_once
  step
  have ho := o_post
  cases o with
  | none =>
    simp only [Option.map_none] at ho
    simp [WP.spec_ok, splitOnce, ← ho]
  | some i =>
    simp only [Option.map_some] at ho
    have hfind := ho.symm
    rw [List.findIdx?_eq_some_iff_getElem] at hfind
    obtain ⟨hlt, he, hpre⟩ := hfind
    step*
    simp only [splitOnce, ← ho, Option.map_some, Option.some.injEq, Prod.mk.injEq]
    simp_all [Slice.len]

theorem star_lit : lit "*" = [42] := by
  unfold lit String.toUTF8
  rw [← String.utf8Encode_toList]
  simp only [String.reduceToList, List.utf8Encode, List.flatMap_cons, List.flatMap_nil,
    String.utf8EncodeChar]
  decide +kernel
theorem admin_lit : lit "admin" = [97, 100, 109, 105, 110] := by
  unfold lit String.toUTF8
  rw [← String.utf8Encode_toList]
  simp only [String.reduceToList, List.utf8Encode, List.flatMap_cons, List.flatMap_nil,
    String.utf8EncodeChar]
  decide +kernel

theorem split_none_no_colon {s : List U8} (h : splitOnce 58#u8 s = none) :
    (nats s).contains 58 = false := by
  have hm := splitOnce_eq_none.mp h
  apply Bool.eq_false_iff.mpr
  intro hc
  change (nats s).contains 58 = true at hc
  have hc := List.contains_iff_mem.mp hc
  simp only [nats, List.mem_map] at hc
  obtain ⟨x, hx, he⟩ := hc
  apply hm
  have : x = 58#u8 := by scalar_tac
  simpa [this] using hx

theorem split_parent_model {s a b : List U8} (h : splitOnce 58#u8 s = some (a, b)) :
    (nats s).contains 58 = true ∧ (nats s).takeWhile (· ≠ 58) = nats a := by
  obtain ⟨rfl, ha⟩ := splitOnce_eq_some h
  have hn : ∀ x ∈ a, x.val ≠ 58 := by
    intro x hx he
    have : x = 58#u8 := by scalar_tac
    exact ha (this ▸ hx)
  constructor
  · simp [nats]
  · have ht : (nats a).takeWhile (· ≠ 58) = nats a := by
      apply List.takeWhile_eq_self_iff.mpr
      intro x hx
      obtain ⟨y, hy, rfl⟩ := List.mem_map.mp hx
      simpa using hn y hy
    simp only [nats, List.map_append, List.map_cons, UScalar.ofNatCore_val_eq] at ht ⊢
    rw [List.takeWhile_append, ht]
    simp

theorem scopes_grant_access_spec (scopes : Slice (alloc.vec.Vec U8)) (req : Slice U8) :
    token_scope.scopes_grant_access scopes req =
      ok (scopeGrants (scopes.val.map (fun s => nats s.val)) (nats req.val)) := by
  apply eq_ok_of_spec
  unfold token_scope.scopes_grant_access
  h5i_steps
  all_goals try
    rcases p with ⟨parent, suffix⟩
    change (if parent.len > 0#usize then strs.any_eq scopes parent.deref else ok false)
      ⦃ r => r = scopeGrants (scopes.val.map (fun v => nats v.val)) (nats req.val) ⦄
    h5i_steps
  all_goals try
    have ho : splitOnce 58#u8 req.val = some (parent.val, suffix.val) := by
      simpa only [‹o = some (parent, suffix)›, Option.map_some] using o_post.symm
    obtain ⟨hcolon, hparent⟩ := split_parent_model ho
  all_goals (try simp_all [scopeGrants, star_lit, admin_lit, nats, Array.to_slice, Array.make])
  · have hc := split_none_no_colon o_post.symm
    have hn : ¬ ∃ x ∈ req.val, x.val = 58 := by
      intro h
      have he : (nats req.val).contains 58 = true := by
        simp only [List.contains_iff_mem, nats, List.mem_map]
        exact h
      exact Bool.false_ne_true (hc.symm.trans he)
    exact ⟨b_post, fun x hx he => False.elim (hn ⟨x, hx, he⟩)⟩
  all_goals try simp_all [alloc.vec.Vec.deref, List.mem_map]
  · have hs : ¬ [42] ∈ scopes.val.map (fun v => v.val.map (·.val)) := by
      intro hm
      obtain ⟨v, hv, he⟩ := List.mem_map.mp hm
      obtain ⟨x, hx, hval⟩ := List.map_eq_singleton_iff.mp he
      exact b_post v hv x hx hval
    have hp : parent.val ≠ [] := by
      intro he
      have hh := ‹0 < parent.val.length›
      simp [he] at hh
    have hsf : decide ([42] ∈ scopes.val.map (fun v => v.val.map (·.val))) = false :=
      decide_eq_false hs
    have haf : decide (∃ a ∈ scopes.val, a.val.map (·.val) = [97, 100, 109, 105, 110]) = false := by
      apply decide_eq_false
      rintro ⟨a, ha, he⟩
      exact has_admin_wildcard_post a ha he
    have hef : decide (∃ a ∈ scopes.val, a.val.map (·.val) = req.val.map (·.val)) = false := by
      apply decide_eq_false
      rintro ⟨a, ha, he⟩
      exact b1_post a ha he
    have hpf : parent.val.isEmpty = false := by
      apply Bool.eq_false_iff.mpr
      intro h
      exact hp (List.isEmpty_iff.mp h)
    rw [hsf, haf, hef, hpf]
    rfl
  · exact b_post

end artifactkeeper_kernel.Solution
