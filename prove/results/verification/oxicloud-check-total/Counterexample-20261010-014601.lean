import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

namespace oxicloud_kernel.Counterexample

/-!
A counterexample to the unrestricted `Solution.check_total` statement.
`oversizedDb` has `Usize.max` distinct groups, each containing user 0.
A successful expansion would have to contain user 0 and every group, hence
at least `Usize.max + 1` distinct IDs, exceeding the vector's size bound.
The final theorem shows that even a read check on a calendar cannot succeed.
The proof reasons symbolically about the list's membership and cardinality.
-/

@[step] theorem contains_spec (ids : Slice U64) (x : U64) :
    acl.contains ids x ⦃ b => b = ids.val.any (fun y => decide (y = x)) ⦄ := by
  unfold acl.contains acl.contains_loop
  h5i_search_any ids.val (fun y => decide (y = x))

theorem contains_ok (ids : Slice U64) (x : U64) (b : Bool)
    (h : acl.contains ids x = ok b) : b = true ↔ x ∈ ids.val := by
  have hb := post_of_ok (contains_spec ids x) h
  simp [hb, List.any_eq_true]

theorem push_ok {α : Type} (v w : alloc.vec.Vec α) (x : α)
    (h : alloc.vec.Vec.push v x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · have := result_ok_inj h
    subst w
    simp
  · simp at h

theorem parents_body_facts (db : model.Db) (uid : U64)
    (out : alloc.vec.Vec U64) (grew : Bool) (i : Usize)
    (out' : alloc.vec.Vec U64) (grew' : Bool) (i' : Usize)
    (h : acl.add_parents_loop.body db uid out grew i = ok (.cont (out', grew', i'))) :
    out.val ⊆ out'.val ∧ i'.val = i.val + 1 ∧ i.val < db.memberships.val.length ∧
      (∀ hi : i.val < db.memberships.val.length,
        db.memberships.val[i.val].member = .User uid →
        db.memberships.val[i.val].group_id ∈ out'.val) := by
  unfold acl.add_parents_loop.body at h
  h5i_invert h
  rcases x with ⟨out1, grew1⟩
  change (do let j ← i + 1#usize;
             ok (ControlFlow.cont (β := alloc.vec.Vec U64 × Bool) (out1, grew1, j))) =
    ok (ControlFlow.cont (out', grew', i')) at h
  h5i_invert h
  h5i_invert hx
  all_goals
    obtain ⟨rfl, rfl⟩ := hx
    simp only [ControlFlow.cont.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, rfl, rfl⟩ := h
    have hm := vec_index_ok_get? hm
    have hi : i.val < db.memberships.val.length := by scalar_tac
    have hm' : m = db.memberships.val[i.val] := by
      simpa [List.getElem?_eq_getElem hi] using hm.symm
    subst m
    have hinc := add_ok_val hj
    simp only [UScalar.ofNatCore_val_eq] at hinc
  · refine ⟨by simp, hinc, hi, ?_⟩
    intro _ _
    simpa [vec_deref_val] using (contains_ok _ _ _ hb1).mp hc_2
  · have hp := push_ok _ _ _ hout2
    refine ⟨?_, hinc, hi, ?_⟩
    · rw [hp]; exact List.subset_append_left _ _
    · intro _ _; simp [hp]
  · refine ⟨by simp, hinc, hi, ?_⟩
    intro _ huser
    simp [huser, acl.member_reaches] at hb
    simp_all

theorem parents_body_done (db : model.Db) (uid : U64)
    (out : alloc.vec.Vec U64) (grew : Bool) (i : Usize)
    (y : alloc.vec.Vec U64 × Bool)
    (h : acl.add_parents_loop.body db uid out grew i = ok (.done y)) :
    db.memberships.val.length ≤ i.val ∧ y = (out, grew) := by
  unfold acl.add_parents_loop.body at h
  h5i_invert h
  · rcases x with ⟨out1, grew1⟩
    change (do let j ← i + 1#usize;
               ok (ControlFlow.cont (β := alloc.vec.Vec U64 × Bool) (out1, grew1, j))) =
      ok (ControlFlow.done y) at h
    h5i_invert h
  · simp only [ControlFlow.done.injEq] at h
    exact ⟨by scalar_tac, h.symm⟩

theorem add_parents_facts (db : model.Db) (uid : U64)
    (found : alloc.vec.Vec U64) (out : alloc.vec.Vec U64) (grew : Bool)
    (h : acl.add_parents db uid found = ok (out, grew)) :
    found.val ⊆ out.val ∧ ∀ k (hk : k < db.memberships.val.length),
      db.memberships.val[k].member = .User uid → db.memberships.val[k].group_id ∈ out.val := by
  unfold acl.add_parents acl.add_parents_loop at h
  let Inv := fun x : alloc.vec.Vec U64 × Bool × Usize =>
    found.val ⊆ x.1.val ∧ ∀ k (hk : k < db.memberships.val.length),
      k < x.2.2.val → db.memberships.val[k].member = .User uid →
      db.memberships.val[k].group_id ∈ x.1.val
  apply loop_idx_ok _ (fun x => x.2.2) db.memberships.val.length Inv
    (fun y => found.val ⊆ y.1.val ∧ ∀ k (hk : k < db.memberships.val.length),
      db.memberships.val[k].member = .User uid → db.memberships.val[k].group_id ∈ y.1.val)
    ?_ (found, false, 0#usize) (out, grew) ?_ (by simp) h
  · rintro ⟨v, g, i⟩ cf ⟨hsub, hseen⟩ hi hc
    dsimp only at hsub hseen hi
    cases cf with
    | done y =>
      obtain ⟨hle, rfl⟩ := parents_body_done db uid v g i y hc
      refine ⟨hsub, ?_⟩
      intro k hk hu
      exact hseen k hk (by omega) hu
    | cont x =>
      rcases x with ⟨v', g', i'⟩
      dsimp only [Inv]
      obtain ⟨hsub', hinc, hlt, hnew⟩ := parents_body_facts db uid v g i v' g' i' hc
      refine ⟨⟨List.Subset.trans hsub hsub', ?_⟩, by omega, by omega⟩
      intro k hk hki hu
      by_cases hki' : k < i.val
      · exact hsub' (hseen k hk hki' hu)
      · have he : k = i.val := by omega
        subst k
        exact hnew hk hu
  · refine ⟨by simp, ?_⟩
    intro k hk hki
    simp at hki

theorem groups_loop_preserves (db : model.Db) (uid : U64)
    (found out : alloc.vec.Vec U64) (round : Usize) (grew : Bool)
    (h : acl.groups_for_user_loop db uid found round grew = ok out) :
    found.val ⊆ out.val := by
  unfold acl.groups_for_user_loop at h
  apply loop_ok _ (fun x => found.val ⊆ x.1.val)
    (fun v => found.val ⊆ v.val)
    (fun x => db.memberships.val.length + 1 - x.2.1.val)
    ?_ (found, round, grew) out (by simp) h
  rintro ⟨v, j, g⟩ cf hsub hc
  dsimp only at hsub ⊢
  unfold acl.groups_for_user_loop.body at hc
  h5i_invert hc
  · rcases x with ⟨next, g'⟩
    change (do let j' ← j + 1#usize;
               ok (ControlFlow.cont (β := alloc.vec.Vec U64) (next, j', g'))) = ok cf at hc
    h5i_invert hc
    have hnext := (add_parents_facts db uid v next g' hx).1
    have hj' := add_ok_val hj'
    simp only [UScalar.ofNatCore_val_eq] at hj'
    exact ⟨List.Subset.trans hsub hnext, by scalar_tac⟩
  · exact hsub
  · exact hsub

theorem groups_facts (db : model.Db) (uid : U64) (out : alloc.vec.Vec U64)
    (h : acl.groups_for_user db uid = ok out) :
    ∀ k (hk : k < db.memberships.val.length),
      db.memberships.val[k].member = .User uid → db.memberships.val[k].group_id ∈ out.val := by
  unfold acl.groups_for_user acl.groups_for_user_loop at h
  rw [loop] at h
  simp only [acl.groups_for_user_loop.body, ite_true] at h
  have hz : (0#usize : Usize) ≤ alloc.vec.Vec.len db.memberships := by scalar_tac
  simp only [hz, ite_true] at h
  h5i_invert h
  all_goals
    obtain ⟨pair, hp, hr⟩ := bind_tc_eq_ok.mp hr
    rcases pair with ⟨next, g⟩
    change (do let j ← (0#usize : Usize) + 1#usize;
               ok (ControlFlow.cont (β := alloc.vec.Vec U64) (next, j, g))) = _ at hr
    h5i_invert hr
  simp only [ControlFlow.cont.injEq] at hr
  subst x
  have hseen := (add_parents_facts db uid (alloc.vec.Vec.new U64) next g hp).2
  have hsub := groups_loop_preserves db uid next out j g h
  intro k hk hu
  exact hsub (hseen k hk hu)

theorem push_new_facts (v out : alloc.vec.Vec U64) (x : U64)
    (h : acl.push_new v x = ok out) : v.val ⊆ out.val ∧ x ∈ out.val := by
  unfold acl.push_new at h
  h5i_invert h
  · exact ⟨by simp, by simpa [vec_deref_val] using (contains_ok _ _ _ hb).mp hc⟩
  · have hp := push_ok _ _ _ h
    rw [hp]
    simp

theorem expand_loop_facts (set direct out : alloc.vec.Vec U64)
    (h : acl.expand_user_loop set direct 0#usize = ok out) :
    set.val ⊆ out.val ∧ direct.val ⊆ out.val := by
  unfold acl.expand_user_loop at h
  let Inv := fun x : alloc.vec.Vec U64 × Usize =>
    set.val ⊆ x.1.val ∧ ∀ k (hk : k < direct.val.length),
      k < x.2.val → direct.val[k] ∈ x.1.val
  have hseen : set.val ⊆ out.val ∧ ∀ k (hk : k < direct.val.length),
      direct.val[k] ∈ out.val := by
    apply loop_idx_ok _ (fun x => x.2) direct.val.length Inv
      (fun y => set.val ⊆ y.val ∧ ∀ k (hk : k < direct.val.length), direct.val[k] ∈ y.val)
      ?_ (set, 0#usize) out ?_ (by simp) h
    · rintro ⟨v, i⟩ cf ⟨hsub, hseen⟩ hi hc
      dsimp only at hsub hseen hi
      unfold acl.expand_user_loop.body at hc
      h5i_invert hc
      · have hf := vec_index_ok_get? hi2
        have hlt : i.val < direct.val.length := by scalar_tac
        have hf' : i2 = direct.val[i.val] := by
          simpa [List.getElem?_eq_getElem hlt] using hf.symm
        have hp := push_new_facts v set1 i2 hset1
        have hinc := add_ok_val hi3
        simp only [UScalar.ofNatCore_val_eq] at hinc
        dsimp only [Inv]
        refine ⟨⟨List.Subset.trans hsub hp.1, ?_⟩, by omega, by omega⟩
        intro k hk hki
        by_cases hki' : k < i.val
        · exact hp.1 (hseen k hk hki')
        · have he : k = i.val := by omega
          subst k
          simpa [hf'] using hp.2
      · refine ⟨hsub, ?_⟩
        intro k hk
        apply hseen k hk
        scalar_tac
    · refine ⟨by simp, ?_⟩
      intro k hk hki
      simp at hki
  refine ⟨hseen.1, ?_⟩
  intro x hx
  obtain ⟨k, hk, rfl⟩ := List.getElem_of_mem hx
  exact hseen.2 k hk

theorem expand_facts (db : model.Db) (uid : U64) (out : alloc.vec.Vec U64)
    (h : acl.expand_user db uid = ok out) :
    uid ∈ out.val ∧ ∀ k (hk : k < db.memberships.val.length),
      db.memberships.val[k].member = .User uid → db.memberships.val[k].group_id ∈ out.val := by
  unfold acl.expand_user at h
  h5i_invert h
  have hloop := expand_loop_facts set1 direct out h
  have hgroups := groups_facts db uid direct hdirect
  have hset : uid ∈ set.val := by simp [push_ok _ _ _ hset]
  refine ⟨?_, fun k hk hu => hloop.2 (hgroups k hk hu)⟩
  apply hloop.1
  h5i_invert hset1
  · exact hset
  · exact (push_new_facts set set1 acl.INTERNAL_GROUP_ID hset1).1 hset

theorem check_read_calendar_expands (db : model.Db) (uid : U64) (b : Bool)
    (h : acl.check db false 0#i64 (.User uid) .Read (.Calendar 0#u64) = ok b) :
    ∃ out, acl.expand_user db uid = ok out := by
  simp [acl.check, acl.read_only_gate_applies,
    core.cmp.PartialEq.ne.trait_default, core.cmp.PartialEq.ne.default,
    model.Permission.Insts.CoreCmpPartialEqPermission.eq,
    model.Permission.read_discriminant] at h
  h5i_invert h
  unfold acl.subject_match_set at hx
  h5i_invert hx
  exact ⟨v, hv⟩

def groupId (i : Fin Usize.max) : U64 :=
  U64.ofNatCore (i.val + 1) (by
    have hmax := usize_max_le
    have hi := i.isLt
    rw [U64.max_def] at hmax
    change i.val + 1 < 2 ^ 64
    norm_num [U64.numBits] at hmax
    omega)

@[simp] theorem groupId_val (i : Fin Usize.max) : (groupId i).val = i.val + 1 := by
  simp [groupId]

def oversizedDb : model.Db := {
  users := alloc.vec.Vec.new _
  memberships := vecOf (List.ofFn (fun i : Fin Usize.max =>
    ({group_id := groupId i, member := .User 0#u64} : model.Membership))) (by simp)
  grants := alloc.vec.Vec.new _
  drives := alloc.vec.Vec.new _
  folders := alloc.vec.Vec.new _
  files := alloc.vec.Vec.new _
}

theorem groupId_injective : Function.Injective groupId := by
  intro i j he
  have hv := congrArg UScalar.val he
  simp only [groupId_val] at hv
  apply Fin.ext
  omega

theorem oversized_expansion_impossible (out : alloc.vec.Vec U64)
    (h : acl.expand_user oversizedDb 0#u64 = ok out) : False := by
  obtain ⟨hzero, hgroups⟩ := expand_facts oversizedDb 0#u64 out h
  let required : List U64 := 0#u64 :: List.ofFn groupId
  have hsub : required ⊆ out.val := by
    intro x hx
    simp only [required, List.mem_cons, List.mem_ofFn] at hx
    rcases hx with rfl | ⟨i, rfl⟩
    · exact hzero
    · have hi : i.val < oversizedDb.memberships.val.length := by
        simp [oversizedDb]
      have hg := hgroups i.val hi
      simpa [oversizedDb, List.getElem_ofFn] using hg
  have hnodup : required.Nodup := by
    apply List.nodup_cons.mpr
    refine ⟨?_, List.nodup_ofFn.mpr groupId_injective⟩
    simp only [List.mem_ofFn]
    rintro ⟨i, he⟩
    have hv := congrArg UScalar.val he
    simp only [groupId_val, UScalar.ofNatCore_val_eq] at hv
    omega
  have hfinset : required.toFinset ⊆ out.val.toFinset := by
    intro x hx
    exact List.mem_toFinset.mpr (hsub (List.mem_toFinset.mp hx))
  have hcard := Finset.card_le_card hfinset
  rw [List.toFinset_card_of_nodup hnodup] at hcard
  have hout := List.toFinset_card_le out.val
  have hbound := out.property
  have hlen : required.length = Usize.max + 1 := by simp [required]
  omega

theorem check_not_total :
    ¬ ∃ b, acl.check oversizedDb false 0#i64 (.User 0#u64) .Read (.Calendar 0#u64) = ok b := by
  rintro ⟨b, hb⟩
  obtain ⟨out, hout⟩ := check_read_calendar_expands oversizedDb 0#u64 b hb
  exact oversized_expansion_impossible out hout

theorem check_total_statement_false :
    ¬ (∀ (db : model.Db) (ro : Bool) (now : I64) (s : model.Subject)
        (p : model.Permission) (r : model.Resource),
        ∃ b, acl.check db ro now s p r = ok b) := by
  intro htotal
  exact check_not_total (htotal oversizedDb false 0#i64 (.User 0#u64) .Read (.Calendar 0#u64))

#print axioms check_total_statement_false

end oxicloud_kernel.Counterexample
