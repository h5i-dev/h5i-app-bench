import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Solution

macro "literal_bytes" : tactic => `(tactic| (
  unfold lit
  rw [String.toUTF8_eq_toByteArray, ← String.utf8Encode_toList]
  simp only [String.reduceToList]
  simp [List.utf8Encode, String.utf8EncodeChar]
  simp only [List.toByteArray, List.toByteArray.loop, ByteArray.empty, ByteArray.push,
    ByteArray.emptyWithCapacity]
  simp only [ByteArray.toList]
  repeat' (rw [ByteArray.toList.loop]; simp only [ByteArray.size, _root_.Array.size, _root_.Array.empty, _root_.Array.toList_push, List.length_append, List.length_cons, List.length_nil, Nat.reduceAdd]; dsimp [_root_.Array.emptyWithCapacity])
  decide))

@[simp] lemma lit_class : lit "class" = [99, 108, 97, 115, 115] := by literal_bytes
@[simp] lemma lit_uuid : lit "uuid" = [117, 117, 105, 100] := by literal_bytes
@[simp] lemma lit_system : lit "system" = [115, 121, 115, 116, 101, 109] := by literal_bytes
@[simp] lemma lit_domain_info : lit "domain_info" = [100, 111, 109, 97, 105, 110, 95, 105, 110, 102, 111] := by literal_bytes
@[simp] lemma lit_system_info : lit "system_info" = [115, 121, 115, 116, 101, 109, 95, 105, 110, 102, 111] := by literal_bytes
@[simp] lemma lit_system_config : lit "system_config" = [115, 121, 115, 116, 101, 109, 95, 99, 111, 110, 102, 105, 103] := by literal_bytes
@[simp] lemma lit_dyngroup : lit "dyngroup" = [100, 121, 110, 103, 114, 111, 117, 112] := by literal_bytes
@[simp] lemma lit_sync_object : lit "sync_object" = [115, 121, 110, 99, 95, 111, 98, 106, 101, 99, 116] := by literal_bytes
@[simp] lemma lit_tombstone : lit "tombstone" = [116, 111, 109, 98, 115, 116, 111, 110, 101] := by literal_bytes
@[simp] lemma lit_recycled : lit "recycled" = [114, 101, 99, 121, 99, 108, 101, 100] := by literal_bytes

lemma nats_eq_iff (a b : List U8) : nats a = nats b ↔ a = b := by
  induction a generalizing b with
  | nil => cases b <;> simp [nats]
  | cons x xs ih =>
    cases b <;> simp_all [nats, u8_eq_iff]

@[step] lemma bytes_eq_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  unfold bset.bytes_eq
  dsimp only
  split
  · rename_i h
    simp only [WP.spec_ok]
    have hn : a.val ≠ b.val := by
      intro he
      simp [Slice.len, he] at h
    simp [nats_eq_iff, hn]
  · rename_i h
    have hlen : a.val.length = b.val.length := by
      simpa using h
    unfold bset.bytes_eq_loop
    apply loop_idx_spec _ id a.val.length
      (fun i => ∀ j, j < i.val → a.val[j]? = b.val[j]?)
      (fun r => r = decide (nats a.val = nats b.val))
    · intro i hi hn
      unfold bset.bytes_eq_loop.body
      step* <;> simp_all [nats_eq_iff]
      · intro he; simp_all only
      · constructor
        · intro j hj
          by_cases he : j = i.val
          · subst j
            have ha : i.val < a.val.length := by scalar_tac
            have hb : i.val < b.val.length := by omega
            simp_all [u8_eq_iff]
          · apply hi; omega
        · scalar_tac
      · apply List.ext_getElem?
        intro j
        by_cases hj : j < i.val
        · exact hi j hj
        · rw [List.getElem?_eq_none (by omega), List.getElem?_eq_none (by omega)]
    · simp
    · simp

@[step] lemma ava_spec (e : Entry) (a : Slice U8) :
    entry_impl.get_ava_set e a ⦃ r => r = ava e (nats a.val) ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  apply WP.spec_mono (loop_search e.attrs.val
    (fun x => nats x.attr.val == nats a.val) id (fun _ x => some x.vs) none _ ?_ 0#usize (by simp))
  · intro r hr
    simp only [id] at hr
    rw [hr, searchFrom_find]
    simp [ava]
  · intro i hi
    unfold entry_impl.get_ava_set_loop.body
    h5i_step [alloc.vec.Vec.deref]

@[step] lemma iutf8_spec (e : Entry) (a : Slice U8) :
    entry_impl.get_ava_as_iutf8 e a ⦃ r =>
      (match r with | some s => names s.val | none => []) =
      (match ava e (nats a.val) with | some (.Iutf8 s) => names s.val | _ => []) ⦄ := by
  unfold entry_impl.get_ava_as_iutf8
  step
  rw [o_post]
  cases ava e (nats a.val) with
  | none => simp
  | some v => cases v <;> simp [valueset.as_iutf8_set]

@[step] lemma uuid_single_spec (v : ValueSet) :
    valueset.to_uuid_single v ⦃ r => r =
      (match v with | .Uuid s => if s.val.length = 1 then s.val.head? else none | _ => none) ⦄ := by
  unfold valueset.to_uuid_single
  cases v <;> try simp
  step*
  simp_all
  constructor
  · scalar_tac
  · rw [List.head?_eq_getElem?]; simp

@[step] lemma uuid_spec (e : Entry) :
    entry_impl.get_uuid_init e ⦃ r => r = uuidOf e ⦄ := by
  unfold entry_impl.get_uuid_init
  step* <;> simp_all [uuidOf, nats, Array.make, Array.to_slice, -List.find?_eq_none]
  all_goals rw [← o_post]
  cases vs <;> rfl

@[step] lemma protected_class_spec (c : Slice U8) :
    protected.protected_entry_classes c ⦃ r => r = decide (nats c.val ∈ protectedEntryClasses) ⦄ := by
  unfold protected.protected_entry_classes
  step* <;> simp_all [protectedEntryClasses, nats, Array.make, Array.to_slice]

@[step] lemma disjoint_spec (cs : Slice (alloc.vec.Vec U8)) :
    protected.disjoint_protected_entry_classes cs ⦃ r =>
      r = true → ∀ c ∈ names cs.val, c ∉ protectedEntryClasses ⦄ := by
  unfold protected.disjoint_protected_entry_classes protected.disjoint_protected_entry_classes_loop
  h5i_search_all cs.val (fun c => decide (nats c.val ∈ protectedEntryClasses))
  all_goals try simp_all [names, alloc.vec.Vec.deref]
  all_goals try scalar_tac
  rename_i hr
  rw [← hr]
  simp

def SafeCreate (e : Entry) : Prop :=
  (∀ u, uuidOf e = some u → UUID_ANONYMOUS < u) ∧
    ∀ c ∈ classes e, c ∉ protectedEntryClasses

@[step] lemma protected_filter_spec (i : Identity) (e : Entry)
    (hk : IsUser i ∨ i.origin = .Internal .Migration) :
    create_acc.protected_filter_entry i e ⦃ r => r ≠ .Deny → SafeCreate e ⦄ := by
  unfold create_acc.protected_filter_entry
  rcases hk with ⟨u, hu⟩ | hm
  · rw [hu]
    step* <;> simp_all [SafeCreate, Spec.classes, nats, Array.make, Array.to_slice, alloc.vec.Vec.deref]
    all_goals constructor
    all_goals first
      | (intro v hv; rw [← o_post] at hv; simp only [Option.some.injEq, reduceCtorEq] at hv <;> (subst v; assumption))
      | exact b_post
      | (split at o1_post <;> simp_all)
  · rw [hm]
    step* <;> simp_all [SafeCreate, Spec.classes, nats, Array.make, Array.to_slice, alloc.vec.Vec.deref]
    all_goals constructor
    all_goals first
      | (intro v hv; rw [← o_post] at hv; simp only [Option.some.injEq, reduceCtorEq] at hv <;> (subst v; assumption))
      | exact b_post
      | (split at o1_post <;> simp_all)

lemma apply_denied (i : Identity) (ps : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (hd : create_acc.protected_filter_entry i e = ok .Deny)
    (r : create_acc.CreateResult) (h : create_acc.apply_create_access i ps e = ok r) :
    r = .Deny := by
  unfold create_acc.apply_create_access at h
  rw [hd] at h
  simp only [bind_ok] at h
  obtain ⟨mq, hmq, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨x, hx, h⟩ := bind_tc_eq_ok.1 h
  have hxdeny : x.1 = true := by
    cases mq <;> h5i_invert hx <;> rfl
  rcases x with ⟨d, g, p, c⟩
  simp only at hxdeny
  subst d
  try dsimp only at h
  obtain ⟨mig, hmig, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨x, hx, h⟩ := bind_tc_eq_ok.1 h
  have hxdeny : x.1 = true := by
    cases mig <;> h5i_invert hx <;> rfl
  rcases x with ⟨d, g, p, c⟩
  simp only at hxdeny
  subst d
  try dsimp only at h
  obtain ⟨acp, hacp, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨x, hx, h⟩ := bind_tc_eq_ok.1 h
  have hxdeny : x.1 = true := by
    cases acp <;> h5i_invert hx <;> rfl
  rcases x with ⟨d, g, p, c⟩
  simp only at hxdeny
  subst d
  simpa using (result_ok_inj h).symm

lemma apply_safe (i : Identity) (ps : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (hk : IsUser i ∨ i.origin = .Internal .Migration)
    (r : create_acc.CreateResult) (h : create_acc.apply_create_access i ps e = ok r)
    (hn : r ≠ .Deny) : SafeCreate e := by
  have hs := protected_filter_spec i e hk
  obtain ⟨pr, hp⟩ := ok_of hs
  apply post_of_ok hs hp
  intro hd
  subst pr
  exact hn (apply_denied i ps e hp r h)

lemma entry_safe (i : Identity) (ps : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (hk : IsUser i ∨ i.origin = .Internal .Migration)
    (h : access.create_allow_entry i ps e = ok true) : SafeCreate e := by
  unfold access.create_allow_entry at h
  h5i_invert h
  all_goals apply apply_safe i ps e hk _ hcr
  all_goals simp

lemma all_entries_safe (i : Identity) (ps : Slice profiles.AccessControlCreateResolved) (es : Slice Entry)
    (hk : IsUser i ∨ i.origin = .Internal .Migration)
    (h : access.create_all_entries i ps es = ok true) : ∀ e ∈ es.val, SafeCreate e := by
  unfold access.create_all_entries access.create_all_entries_loop at h
  have hs := loop_idx_ok (access.create_all_entries_loop.body i ps es) id es.val.length
    (fun k => ∀ j, j < k.val → ∀ e, es.val[j]? = some e → SafeCreate e)
    (fun b => b = true → ∀ e ∈ es.val, SafeCreate e) ?_ 0#usize true (by simp) (by simp) h
  · exact hs rfl
  · intro k r hinv hbound hbody
    unfold access.create_all_entries_loop.body at hbody
    h5i_invert hbody
    all_goals h5i_simp
    all_goals simp -failIfUnchanged only [false_implies]
    · have hnext : i2.val = k.val + 1 := by simpa using add_ok_val hi2
      obtain ⟨hlt, hidx⟩ := slice_index_ok he
      refine ⟨?_, by h5i_arith, by h5i_arith⟩
      intro j hj x hx
      by_cases hjk : j < k.val
      · exact hinv j hjk x hx
      · have hjk : j = k.val := by omega
        subst j
        have hxe : x = e := by
          have hget : es.val[k.val]? = some e := by
            rw [List.getElem?_eq_getElem hlt, hidx]
          exact Option.some.inj (hx.symm.trans hget)
        subst x
        exact entry_safe i ps e hk (by simpa [hc_1] using hb)
    · intro _ e he
      obtain ⟨j, hj, hje⟩ := List.getElem_of_mem he
      have hlen : es.val.length ≤ k.val := by simpa using hc
      have hjk : j < k.val := by omega
      exact hinv j hjk e (by rw [List.getElem?_eq_getElem hj, hje])

theorem create_protected (ctl : AccessControlsInner) (ce : CreateEvent) (es : Slice Entry) (e : Entry)
    (hk : IsUser ce.ident ∨ ce.ident.origin = .Internal .Migration)
    (h : access.create_allow_operation ctl ce es = ok (.Ok true)) (he : e ∈ es.val) :
    (∀ u, uuidOf e = some u → UUID_ANONYMOUS < u) ∧ ∀ c ∈ classes e, c ∉ protectedEntryClasses := by
  unfold access.create_allow_operation at h
  h5i_invert h
  exact all_entries_safe ce.ident _ es hk hb e he

end kanidm_kernel.Solution
