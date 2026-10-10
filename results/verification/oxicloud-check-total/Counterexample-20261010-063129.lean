import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

namespace OxiOverflow

@[step] theorem contains_spec (ids : Slice U64) (x : U64) :
    acl.contains ids x ⦃ b => b = decide (x ∈ ids.val) ⦄ := by
  unfold acl.contains acl.contains_loop
  h5i_search_any ids.val (fun y => decide (y = x))
  all_goals simp_all [any_eq_iff]
  rename_i hr
  rw [← hr]
  apply Bool.eq_iff_iff.mpr
  simp

theorem push_full (v : alloc.vec.Vec U64) (x : U64)
    (h : v.length = Usize.max) :
    alloc.vec.Vec.push v x = fail Error.maximumSizeExceeded := by
  have h32 : U32.max ≤ Usize.max := by
    rcases Usize.bounds_eq with h | h <;>
      simp [h, U32.max_def, U64.max_def, U32.numBits, U64.numBits]
  unfold alloc.vec.Vec.push
  simp only [h]
  have h1 : ¬ Usize.max + 1 ≤ U32.max := by omega
  have h2 : ¬ Usize.max + 1 ≤ Usize.max := by omega
  simp [h1, h2]

theorem push_new_full (v : alloc.vec.Vec U64) (x : U64)
    (h : v.length = Usize.max) (hx : x ∉ v.val) :
    acl.push_new v x = fail Error.maximumSizeExceeded := by
  have hc := eq_ok_of_spec (contains_spec (alloc.vec.Vec.deref v) x)
  have hx' : x ∉ (alloc.vec.Vec.deref v).val := by
    simpa [alloc.vec.Vec.deref] using hx
  unfold acl.push_new
  simp only [hc]
  simpa [hx'] using push_full v x h

theorem push_val_of_ok {v w : alloc.vec.Vec U64} {x : U64}
    (h : alloc.vec.Vec.push v x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · h5i_invert h
    simp
  · simp at h

theorem push_new_val_of_ok {v w : alloc.vec.Vec U64} {x : U64}
    (hx : x ∉ v.val) (h : acl.push_new v x = ok w) :
    w.val = v.val ++ [x] := by
  have hc := eq_ok_of_spec (contains_spec (alloc.vec.Vec.deref v) x)
  have hx' : x ∉ (alloc.vec.Vec.deref v).val := by
    simpa [alloc.vec.Vec.deref] using hx
  unfold acl.push_new at h
  simp only [hc] at h
  simp [hx'] at h
  exact push_val_of_ok h


theorem expand_loop_concat (initial direct final : alloc.vec.Vec U64)
    (hn : direct.val.Nodup)
    (hd : ∀ x ∈ direct.val, x ∉ initial.val)
    (h : acl.expand_user_loop initial direct 0#usize = ok final) :
    final.val = initial.val ++ direct.val := by
  unfold acl.expand_user_loop at h
  refine loop_idx_ok _ (fun x => x.2) direct.length
    (fun x => x.1.val = initial.val ++ direct.val.take x.2.val)
    (fun result => result.val = initial.val ++ direct.val) ?_
    (initial, 0#usize) final (by simp) (by simp) h
  rintro ⟨set, i⟩ res hi hib hs
  dsimp only at hi hib ⊢
  unfold acl.expand_user_loop.body at hs
  h5i_invert hs
  · have hlt : i.val < direct.val.length := by scalar_tac
    have he : direct.val[i.val] = i2 := by
      simpa [List.getElem?_eq_getElem hlt] using vec_index_slice_ok_get? hi2
    have hx0 : i2 ∉ initial.val := hd _ (he ▸ List.getElem_mem hlt)
    have hxt : i2 ∉ direct.val.take i.val := by
      intro hm
      obtain ⟨j, hj, heq⟩ := List.mem_take_iff_getElem.mp hm
      have hjlt : j < direct.val.length := by omega
      have hij : j = i.val := hn.getElem_inj_iff.mp (heq.trans he.symm)
      omega
    have hx : i2 ∉ set.val := by simp [hi, hx0, hxt]
    have hp := push_new_val_of_ok hx hset1
    have hadd := add_ok_val hi3
    change i3.val = i.val + 1 at hadd
    dsimp only
    refine ⟨?_, by omega, by change i3.val ≤ direct.val.length; omega⟩
    rw [hp, hi, hadd, List.take_succ_eq_append_getElem hlt, List.append_assoc, he]
  · have hend : direct.val.length ≤ i.val := by scalar_tac
    simpa [List.take_of_length_le hend] using hi


theorem expand_loop_not_total (initial direct : alloc.vec.Vec U64)
    (hn : direct.val.Nodup)
    (hd : ∀ x ∈ direct.val, x ∉ initial.val)
    (hsize : Usize.max < initial.val.length + direct.val.length) :
    ¬ ∃ final, acl.expand_user_loop initial direct 0#usize = ok final := by
  rintro ⟨final, hf⟩
  have he := expand_loop_concat initial direct final hn hd hf
  have hb := final.property
  rw [he, List.length_append] at hb
  omega


def ident (n : Nat) : U64 := ⟨BitVec.ofNat 64 n⟩

theorem ident_val (n : Nat) (h : n < 2 ^ 64) : (ident n).val = n := by
  change n % 2 ^ 64 = n
  exact Nat.mod_eq_of_lt h

theorem max_bound : Usize.max < 2 ^ 64 := by
  have h := usize_max_le
  rw [U64.max_def] at h
  simp [U64.numBits] at h
  omega

theorem expansion_counterexample :
    ∃ initial direct : alloc.vec.Vec U64,
      initial.val = [0#u64, 1#u64] ∧
      direct.length = Usize.max - 1 ∧ direct.length < Usize.max ∧
      ¬ ∃ final, acl.expand_user_loop initial direct 0#usize = ok final := by
  have hbig := usize_max_ge
  let initial : alloc.vec.Vec U64 := vecOf [0#u64, 1#u64] (by simp; omega)
  let groups := List.range' 2 (Usize.max - 1)
  let direct : alloc.vec.Vec U64 := vecOf (groups.map ident) (by
    simp [groups])
  have hlen : direct.length = Usize.max - 1 := by simp [direct, groups]
  have hival : initial.val = [0#u64, 1#u64] := by simp [initial]
  have hv : ∀ n ∈ groups, (ident n).val = n := by
    intro n hn
    have hn' : 2 ≤ n ∧ n < 2 + (Usize.max - 1) := by
      simpa [groups] using hn
    apply ident_val
    have := max_bound
    omega
  have hn : direct.val.Nodup := by
    simp only [direct, vecOf_val]
    apply List.Nodup.map_on _ (List.nodup_range')
    intro a ha b hb he
    have hh := congrArg UScalar.val he
    simpa [hv a ha, hv b hb] using hh
  have hd : ∀ x ∈ direct.val, x ∉ initial.val := by
    intro x hx
    simp only [direct, vecOf_val, List.mem_map] at hx
    obtain ⟨n, hn, rfl⟩ := hx
    have hn' : 2 ≤ n := (List.mem_range'_1.mp hn).1
    rw [hival]
    simp only [List.mem_cons, List.not_mem_nil, or_false]
    intro hh
    rcases hh with hh | hh
    · have hh' := congrArg UScalar.val hh
      rw [hv n hn] at hh'
      change n = 0 at hh'
      omega
    · have hh' := congrArg UScalar.val hh
      rw [hv n hn] at hh'
      change n = 1 at hh'
      omega
  refine ⟨initial, direct, hival, hlen, by rw [hlen]; omega, ?_⟩
  apply expand_loop_not_total initial direct hn hd
  simp only [hival, List.length_cons, List.length_nil, hlen]
  omega



theorem nth_not_mem_take {xs : List U64} (hn : xs.Nodup) (i : Nat)
    (hi : i < xs.length) : xs[i] ∉ xs.take i := by
  intro hm
  obtain ⟨j, hj, heq⟩ := List.mem_take_iff_getElem.mp hm
  have hjlt : j < xs.length := by omega
  have hij : j = i := hn.getElem_inj_iff.mp heq
  omega

def membership (uid gid : U64) : model.Membership := ⟨gid, .User uid⟩

theorem add_first_ok (db : model.Db) (uid : U64) (groups : List U64)
    (hdb : db.memberships.val = groups.map (membership uid)) (hn : groups.Nodup)
    (out : alloc.vec.Vec U64) (grew : Bool)
    (h : acl.add_parents db uid (alloc.vec.Vec.new U64) = ok (out, grew)) :
    out.val = groups := by
  have hlen : db.memberships.length = groups.length := by simp [hdb]
  unfold acl.add_parents acl.add_parents_loop at h
  refine loop_idx_ok _ (fun x => x.2.2) groups.length
    (fun x => x.1.val = groups.take x.2.2.val)
    (fun r => r.1.val = groups) ?_
    (alloc.vec.Vec.new U64, false, 0#usize) (out, grew) (by simp) (by simp) h
  rintro ⟨set, grew, i⟩ res hi hib hs
  dsimp only at hi hib ⊢
  dsimp only at hs
  unfold acl.add_parents_loop.body at hs
  dsimp only at hs
  split at hs
  · rename_i hc
    have hlt : i.val < groups.length := by scalar_tac
    obtain ⟨m, hm, hs⟩ := bind_tc_eq_ok.mp hs
    have hmval := vec_index_slice_ok_get? hm
    rw [hdb] at hmval
    simp only [List.getElem?_map, List.getElem?_eq_getElem hlt, Option.map_some] at hmval
    have hm' : membership uid groups[i.val] = m := Option.some.inj hmval
    subst m
    have hcontains := eq_ok_of_spec
      (contains_spec (alloc.vec.Vec.deref set) groups[i.val])
    have hnot : groups[i.val] ∉ (alloc.vec.Vec.deref set).val := by
      simpa [alloc.vec.Vec.deref, hi] using nth_not_mem_take hn i.val hlt
    simp [membership, acl.member_reaches, hcontains, hnot] at hs
    h5i_invert hs
    have hp := push_val_of_ok hx
    have hadd := add_ok_val hi2
    change i2.val = i.val + 1 at hadd
    dsimp only
    refine ⟨?_, by omega, by omega⟩
    rw [hp, hi, hadd, List.take_succ_eq_append_getElem hlt]
  · rename_i hc
    have hend : groups.length ≤ i.val := by scalar_tac
    h5i_invert hs
    simpa [List.take_of_length_le hend] using hi



theorem add_existing_ok (db : model.Db) (uid : U64) (groups : List U64)
    (hdb : db.memberships.val = groups.map (membership uid))
    (found out : alloc.vec.Vec U64) (hf : found.val = groups) (grew : Bool)
    (h : acl.add_parents db uid found = ok (out, grew)) :
    out.val = groups ∧ grew = false := by
  have hlen : db.memberships.length = groups.length := by simp [hdb]
  unfold acl.add_parents acl.add_parents_loop at h
  refine loop_idx_ok _ (fun x => x.2.2) groups.length
    (fun x => x.1.val = groups ∧ x.2.1 = false)
    (fun r => r.1.val = groups ∧ r.2 = false) ?_
    (found, false, 0#usize) (out, grew) ⟨hf, rfl⟩ (by simp) h
  rintro ⟨set, grew, i⟩ res ⟨hi, hg⟩ hib hs
  dsimp only at hi hg hib ⊢
  dsimp only at hs
  unfold acl.add_parents_loop.body at hs
  dsimp only at hs
  split at hs
  · rename_i hc
    have hlt : i.val < groups.length := by scalar_tac
    obtain ⟨m, hm, hs⟩ := bind_tc_eq_ok.mp hs
    have hmval := vec_index_slice_ok_get? hm
    rw [hdb] at hmval
    simp only [List.getElem?_map, List.getElem?_eq_getElem hlt, Option.map_some] at hmval
    have hm' : membership uid groups[i.val] = m := Option.some.inj hmval
    subst m
    have hcontains := eq_ok_of_spec
      (contains_spec (alloc.vec.Vec.deref set) groups[i.val])
    have hmem : groups[i.val] ∈ (alloc.vec.Vec.deref set).val := by
      simp [alloc.vec.Vec.deref, hi, List.getElem_mem hlt]
    simp [membership, acl.member_reaches, hcontains, hmem] at hs
    h5i_invert hs
    have hadd := add_ok_val hi2
    change i2.val = i.val + 1 at hadd
    dsimp only
    exact ⟨⟨hi, hg⟩, by omega, by omega⟩
  · h5i_invert hs
    exact ⟨hi, hg⟩



theorem groups_loop_existing_ok (db : model.Db) (uid : U64) (groups : List U64)
    (hdb : db.memberships.val = groups.map (membership uid))
    (found out : alloc.vec.Vec U64) (round : Usize) (grew : Bool)
    (hf : found.val = groups)
    (h : acl.groups_for_user_loop db uid found round grew = ok out) :
    out.val = groups := by
  unfold acl.groups_for_user_loop at h
  refine loop_ok _ (fun x => x.1.val = groups) (fun v => v.val = groups)
    (fun x => db.memberships.length + 1 - x.2.1.val) ?_
    (found, round, grew) out hf h
  rintro ⟨set, round, grew⟩ res hs hstep
  dsimp only at hs ⊢
  dsimp only at hstep
  unfold acl.groups_for_user_loop.body at hstep
  dsimp only at hstep
  split at hstep
  · split at hstep
    · rename_i hg hr
      obtain ⟨x, hx, hstep⟩ := bind_tc_eq_ok.mp hstep
      rcases x with ⟨next, g⟩
      have hnext := add_existing_ok db uid groups hdb set next hs g hx
      change (do
        let round1 ← round + 1#usize
        ok (ControlFlow.cont (next, round1, g))) = ok res at hstep
      h5i_invert hstep
      dsimp only
      refine ⟨hnext.1, ?_⟩
      have hadd := add_ok_val hround1
      change round1.val = round.val + 1 at hadd
      scalar_tac
    · h5i_invert hstep
      exact hs
  · h5i_invert hstep
    exact hs

theorem groups_for_user_ok (db : model.Db) (uid : U64) (groups : List U64)
    (hdb : db.memberships.val = groups.map (membership uid)) (hn : groups.Nodup)
    (out : alloc.vec.Vec U64) (h : acl.groups_for_user db uid = ok out) :
    out.val = groups := by
  unfold acl.groups_for_user acl.groups_for_user_loop at h
  rw [loop] at h
  dsimp only at h
  unfold acl.groups_for_user_loop.body at h
  have hz : 0#usize ≤ db.memberships.len := by scalar_tac
  simp only [if_true, hz] at h
  obtain ⟨r, hr, h⟩ := bind_tc_eq_ok.mp h
  h5i_invert hr
  rcases x with ⟨next, g⟩
  change (do let round1 ← 0#usize + 1#usize; ok (ControlFlow.cont (next, round1, g))) = ok r at hr
  h5i_invert hr
  have hnext := add_first_ok db uid groups hdb hn next g hx
  change acl.groups_for_user_loop db uid next round1 g = ok out at h
  exact groups_loop_existing_ok db uid groups hdb next out round1 g hnext h



theorem internal_user (db : model.Db)
    (hu : db.users.val = [{id := 0#u64, is_external := false}]) :
    acl.is_external db 0#u64 = ok false := by
  apply eq_ok_of_spec
  unfold acl.is_external acl.is_external_loop
  rw [loop]
  unfold acl.is_external_loop.body
  step*
  all_goals simp_all
  all_goals step*
  all_goals simp_all



theorem expand_user_not_total (db : model.Db) (groups : List U64)
    (hu : db.users.val = [{id := 0#u64, is_external := false}])
    (hdb : db.memberships.val = groups.map (membership 0#u64))
    (hn : groups.Nodup)
    (hd : ∀ x ∈ groups, x ≠ 0#u64 ∧ x ≠ 1#u64)
    (hsize : Usize.max < 2 + groups.length) :
    ¬ ∃ final, acl.expand_user db 0#u64 = ok final := by
  rintro ⟨final, h⟩
  unfold acl.expand_user at h
  rw [internal_user db hu] at h
  h5i_invert h
  have hs := push_val_of_ok hset
  have hsetval : set.val = [0#u64] := by simpa using hs
  have hnot : acl.INTERNAL_GROUP_ID ∉ set.val := by
    simp [hsetval, acl.INTERNAL_GROUP_ID]
  have hs1 := push_new_val_of_ok hnot hset1
  have hset1val : set1.val = [0#u64, 1#u64] := by
    simpa [hsetval, acl.INTERNAL_GROUP_ID] using hs1
  have hdir := groups_for_user_ok db 0#u64 groups hdb hn direct hdirect
  have hdisjoint : ∀ x ∈ direct.val, x ∉ set1.val := by
    intro x hx
    have hd' := hd x (by simpa [hdir] using hx)
    simpa [hset1val] using hd'
  exact expand_loop_not_total set1 direct (by simpa [hdir] using hn)
    hdisjoint (by simpa [hset1val, hdir] using hsize) ⟨final, h⟩

theorem read_gate : acl.read_only_gate_applies model.Permission.Read = ok false := by
  simp [acl.read_only_gate_applies, core.cmp.PartialEq.ne.trait_default,
    core.cmp.PartialEq.ne.default,
    model.Permission.Insts.CoreCmpPartialEqPermission.eq]

theorem check_calendar_requires_expand (db : model.Db) (now : I64) (b : Bool)
    (h : acl.check db false now (.User 0#u64) .Read (.Calendar 0#u64) = ok b) :
    ∃ final, acl.expand_user db 0#u64 = ok final := by
  unfold acl.check at h
  simp only [read_gate, bind_ok, Bool.false_eq_true, if_false] at h
  unfold acl.subject_match_set at h
  h5i_invert h
  h5i_invert hx
  exact ⟨v, hv⟩



theorem bad_groups : ∃ groups : List U64,
    groups.length = Usize.max - 1 ∧ groups.Nodup ∧
    ∀ x ∈ groups, x ≠ 0#u64 ∧ x ≠ 1#u64 := by
  let ns := List.range' 2 (Usize.max - 1)
  let groups := ns.map ident
  have hv : ∀ n ∈ ns, (ident n).val = n := by
    intro n hn
    have hn' : 2 ≤ n ∧ n < 2 + (Usize.max - 1) := by simpa [ns] using hn
    apply ident_val
    have := max_bound
    omega
  refine ⟨groups, by simp [groups, ns], ?_, ?_⟩
  · apply List.Nodup.map_on _ List.nodup_range'
    intro a ha b hb he
    have hh := congrArg UScalar.val he
    simpa [hv a ha, hv b hb] using hh
  · intro x hx
    obtain ⟨n, hn, rfl⟩ := List.mem_map.mp hx
    have hlow : 2 ≤ n := (List.mem_range'_1.mp hn).1
    constructor
    · intro he
      have hh := congrArg UScalar.val he
      rw [hv n hn] at hh
      change n = 0 at hh
      omega
    · intro he
      have hh := congrArg UScalar.val he
      rw [hv n hn] at hh
      change n = 1 at hh
      omega

theorem check_counterexample : ∃ db : model.Db,
    db.memberships.length < Usize.max ∧
    ¬ ∃ b, acl.check db false 0#i64 (.User 0#u64) .Read (.Calendar 0#u64) = ok b := by
  obtain ⟨groups, hlen, hn, hd⟩ := bad_groups
  have hbig := usize_max_ge
  let db : model.Db := {
    users := vecOf [{ id := 0#u64, is_external := false }] (by simp; omega)
    memberships := vecOf (groups.map (membership 0#u64)) (by simp [hlen])
    grants := alloc.vec.Vec.new model.Grant
    drives := alloc.vec.Vec.new model.Drive
    folders := alloc.vec.Vec.new model.Folder
    files := alloc.vec.Vec.new model.File }
  have hu : db.users.val = [{id := 0#u64, is_external := false}] := by simp [db]
  have hdb : db.memberships.val = groups.map (membership 0#u64) := by simp [db]
  refine ⟨db, ?_, ?_⟩
  · simp only [db, alloc.vec.Vec.length, vecOf_val, List.length_map, hlen]
    omega
  · rintro ⟨b, hb⟩
    have hsize : Usize.max < 2 + groups.length := by rw [hlen]; omega
    exact expand_user_not_total db groups hu hdb hn hd hsize
      (check_calendar_requires_expand db 0#i64 b hb)

theorem check_total_false :
    ¬ ∀ (db : model.Db) (ro : Bool) (now : I64) (s : model.Subject)
      (p : model.Permission) (r : model.Resource),
      db.memberships.length < Usize.max → ∃ b, acl.check db ro now s p r = ok b := by
  intro h
  obtain ⟨db, hm, hbad⟩ := check_counterexample
  exact hbad (h db false 0#i64 (.User 0#u64) .Read (.Calendar 0#u64) hm)

end OxiOverflow

#print axioms OxiOverflow.check_total_false
