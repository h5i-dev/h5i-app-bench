import Spec
import H5iAppLib
import Mathlib.Data.List.Perm.Subperm
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

namespace oxicloud_kernel.Solution

open Aeneas.Std.WP

h5i_derive_eq model.Permission model.Permission.Insts.CoreCmpPartialEqPermission.eq
h5i_derive_clone model.Folder model.Folder.Insts.CoreCloneClone.clone

@[step] theorem role_eq_total (a b : model.Role) :
    model.Role.Insts.CoreCmpPartialEqRole.eq a b ⦃ _ => True ⦄ := by
  simp [model.Role.Insts.CoreCmpPartialEqRole.eq]

@[step] theorem resource_eq_total (a b : model.Resource) :
    model.Resource.Insts.CoreCmpPartialEqResource.eq a b ⦃ _ => True ⦄ := by
  cases a <;> cases b <;> simp [model.Resource.Insts.CoreCmpPartialEqResource.eq,
    model.Resource.read_discriminant, lift]

@[step, h5i_spec] theorem contains_spec (ids : Slice U64) (x : U64) :
    acl.contains ids x ⦃ b => b = decide (x ∈ ids.val) ⦄ := by
  unfold acl.contains acl.contains_loop
  refine WP.spec_mono (loop_search ids.val (fun y => decide (y = x)) id
    (fun _ _ => true) false _ ?_ 0#usize (by simp)) ?_
  · intro i hi
    unfold acl.contains_loop.body
    h5i_step
  · intro b hb
    have he := search_any ids.val (fun y => decide (y = x)) b hb
    rw [he]
    apply Bool.eq_iff_iff.mpr
    simp

@[step] theorem contains_u8_total (ids : Slice U8) (x : U8) :
    acl.contains_u8 ids x ⦃ _ => True ⦄ := by
  unfold acl.contains_u8 acl.contains_u8_loop
  h5i_total (fun i => i) ids.val.length

@[step] theorem is_external_total (db : model.Db) (uid : U64) :
    acl.is_external db uid ⦃ _ => True ⦄ := by
  unfold acl.is_external acl.is_external_loop
  h5i_total (fun i => i) db.users.val.length

@[step] theorem member_reaches_total (m : model.Member) (uid : U64) (ids : Slice U64) :
    acl.member_reaches m uid ids ⦃ _ => True ⦄ := by
  cases m <;> unfold acl.member_reaches <;> h5i_steps

@[step] theorem role_grants_total (role : model.Role) (p : model.Permission) :
    acl.role_grants role p ⦃ _ => True ⦄ := by
  cases role <;> unfold acl.role_grants <;> h5i_steps

@[step] theorem role_implies_total (role : model.Role) (p : model.Permission) :
    acl.role_implies role p ⦃ _ => True ⦄ := by
  cases p <;> unfold acl.role_implies <;> h5i_steps

@[step] theorem read_only_gate_total (p : model.Permission) :
    acl.read_only_gate_applies p ⦃ _ => True ⦄ := by
  cases p <;> simp [acl.read_only_gate_applies, core.cmp.PartialEq.ne.trait_default,
    core.cmp.PartialEq.ne.default,
    model.Permission.Insts.CoreCmpPartialEqPermission.eq, model.Permission.read_discriminant]

@[step] theorem subject_type_total (s : model.Subject) :
    acl.subject_type s ⦃ _ => True ⦄ := by
  cases s <;> simp [acl.subject_type]

@[step] theorem subject_id_total (s : model.Subject) :
    acl.subject_id s ⦃ _ => True ⦄ := by
  cases s <;> simp [acl.subject_id]

@[step] theorem subject_matches_total (g : model.Grant) (types : Slice U8) (ids : Slice U64) :
    acl.subject_matches g types ids ⦃ _ => True ⦄ := by
  unfold acl.subject_matches
  h5i_steps

@[step] theorem live_total (g : model.Grant) (now : I64) :
    acl.live g now ⦃ _ => True ⦄ := by
  unfold acl.live
  split <;> simp

@[step] theorem find_folder_total (db : model.Db) (id : U64) :
    acl.find_folder db id ⦃ _ => True ⦄ := by
  unfold acl.find_folder acl.find_folder_loop
  h5i_total (fun i => i) db.folders.val.length

@[step] theorem find_file_total (db : model.Db) (id : U64) :
    acl.find_file db id ⦃ _ => True ⦄ := by
  unfold acl.find_file acl.find_file_loop
  h5i_total (fun i => i) db.files.val.length

@[step] theorem drive_policies_total (db : model.Db) (id : U64) :
    acl.drive_policies db id ⦃ _ => True ⦄ := by
  unfold acl.drive_policies acl.drive_policies_loop
  h5i_total (fun i => i) db.drives.val.length

@[step] theorem lpath_contains_total (a b : Slice U64) :
    acl.lpath_contains a b ⦃ _ => True ⦄ := by
  unfold acl.lpath_contains
  dsimp only
  split
  · simp
  · rename_i hab
    unfold acl.lpath_contains_loop
    h5i_total (fun i => i) a.val.length

@[step] theorem grant_folder_covers_total (db : model.Db) (g : model.Grant) (target : Slice U64) :
    acl.grant_folder_covers db g target ⦃ _ => True ⦄ := by
  unfold acl.grant_folder_covers
  h5i_steps

@[step] theorem direct_grant_total (db : model.Db) (types : Slice U8) (ids : Slice U64)
    (p : model.Permission) (r : model.Resource) (now : I64) :
    acl.direct_grant_exists db types ids p r now ⦃ _ => True ⦄ := by
  unfold acl.direct_grant_exists acl.direct_grant_exists_loop
  h5i_total (fun i => i) db.grants.val.length

@[step] theorem folder_cascade_loop_total (db : model.Db) (types : Slice U8) (ids : Slice U64)
    (p : model.Permission) (now : I64) (target : alloc.vec.Vec U64) :
    acl.folder_cascade_grant_exists_loop db types ids p now target 0#usize ⦃ _ => True ⦄ := by
  unfold acl.folder_cascade_grant_exists_loop
  h5i_total (fun i => i) db.grants.val.length

@[step] theorem folder_cascade_total (db : model.Db) (types : Slice U8) (ids : Slice U64)
    (p : model.Permission) (id : U64) (now : I64) :
    acl.folder_cascade_grant_exists db types ids p id now ⦃ _ => True ⦄ := by
  unfold acl.folder_cascade_grant_exists
  h5i_steps

@[step] theorem file_parent_total (db : model.Db) (id : U64) :
    acl.file_parent_folder db id ⦃ _ => True ⦄ := by
  unfold acl.file_parent_folder
  h5i_steps

@[step] theorem drive_of_total (db : model.Db) (r : model.Resource) :
    acl.drive_of db r ⦃ _ => True ⦄ := by
  unfold acl.drive_of
  h5i_steps

@[step] theorem role_rank_total (r : model.Role) :
    acl.role_rank r ⦃ _ => True ⦄ := by
  cases r <;> simp [acl.role_rank]

@[step] theorem stronger_total (a : Option model.Role) (b : model.Role) :
    acl.stronger a b ⦃ _ => True ⦄ := by
  unfold acl.stronger
  h5i_steps

@[step] theorem role_has_total (r : Option model.Role) (p : model.Permission) :
    acl.role_has r p ⦃ _ => True ⦄ := by
  unfold acl.role_has
  h5i_steps

/-- A deduplicated vector drawn from a fixed finite list. -/
def SetWithin (allowed : List U64) (v : alloc.vec.Vec U64) : Prop :=
  v.val.Nodup ∧ v.val ⊆ allowed

theorem within_length {allowed : List U64} {v : alloc.vec.Vec U64}
    (hv : SetWithin allowed v) : v.val.length ≤ allowed.length :=
  (hv.1.subperm hv.2).length_le

theorem append_within {allowed xs : List U64} {x : U64}
    (hd : xs.Nodup) (hs : xs ⊆ allowed) (hx : x ∈ allowed) (hn : x ∉ xs) :
    (xs ++ [x]).Nodup ∧ xs ++ [x] ⊆ allowed := by
  constructor
  · rw [List.nodup_append]
    refine ⟨hd, by simp, ?_⟩
    intro y hy z hz he
    have hz' := List.mem_singleton.mp hz
    exact hn (by simpa only [he, hz'] using hy)
  · intro y hy
    rcases List.mem_append.mp hy with hy | hy
    · exact hs hy
    · simpa using (List.mem_singleton.mp hy) ▸ hx

theorem push_new_within (allowed : List U64) (v : alloc.vec.Vec U64) (x : U64)
    (hb : allowed.length ≤ Usize.max) (hv : SetWithin allowed v) (hx : x ∈ allowed) :
    acl.push_new v x ⦃ w => SetWithin allowed w ⦄ := by
  unfold acl.push_new
  step
  split
  · simp_all
  · rename_i hn
    have hn' : x ∉ v.val := by simpa [w_post, alloc.vec.Vec.deref] using hn
    have ha := append_within hv.1 hv.2 hx hn'
    have hlen := (ha.1.subperm ha.2).length_le
    have hpush : v.val.length < Usize.max := by
      simp only [List.length_append, List.length_singleton] at hlen
      omega
    step*
    simp_all [SetWithin]

abbrev groupIds (db : model.Db) : List U64 := db.memberships.val.map (·.group_id)

@[step] theorem add_parents_within (db : model.Db) (uid : U64) (found : alloc.vec.Vec U64)
    (hm : db.memberships.length + 2 ≤ Usize.max) (hf : SetWithin (groupIds db) found) :
    acl.add_parents db uid found ⦃ r => SetWithin (groupIds db) r.1 ⦄ := by
  unfold acl.add_parents acl.add_parents_loop
  refine loop_idx_spec
    (fun (x : alloc.vec.Vec U64 × Bool × Usize) => acl.add_parents_loop.body db uid x.1 x.2.1 x.2.2)
    (fun x => x.2.2) db.memberships.val.length
    (fun x => SetWithin (groupIds db) x.1) (fun r => SetWithin (groupIds db) r.1)
    ?_ _ hf (by simp)
  rintro ⟨out, grew, i⟩ hI hi
  unfold acl.add_parents_loop.body
  h5i_steps
  all_goals simp_all only [SetWithin]
  · have hl := (hI.1.subperm hI.2).length_le
    simp only [List.length_map] at hl
    scalar_tac
  · refine ⟨append_within hI.1 hI.2 ?_ ?_, by scalar_tac, by scalar_tac⟩
    · exact List.mem_map_of_mem (List.getElem_mem _)
    · simp_all [alloc.vec.Vec.deref]

@[step] theorem groups_for_user_within (db : model.Db) (uid : U64)
    (hm : db.memberships.length + 2 ≤ Usize.max) :
    acl.groups_for_user db uid ⦃ v => SetWithin (groupIds db) v ⦄ := by
  unfold acl.groups_for_user acl.groups_for_user_loop
  refine loop_idx_spec
    (fun (x : alloc.vec.Vec U64 × Usize × Bool) =>
      acl.groups_for_user_loop.body db uid x.1 x.2.1 x.2.2)
    (fun x => x.2.1) (db.memberships.val.length + 1)
    (fun x => SetWithin (groupIds db) x.1) (SetWithin (groupIds db))
    ?_ _ (by simp [SetWithin, alloc.vec.Vec.new]) (by simp)
  rintro ⟨found, round, grew⟩ hI hi
  unfold acl.groups_for_user_loop.body
  h5i_steps

theorem expand_loop_within (allowed : List U64) (set direct : alloc.vec.Vec U64)
    (hb : allowed.length ≤ Usize.max) (hs : SetWithin allowed set)
    (hd : direct.val ⊆ allowed) :
    acl.expand_user_loop set direct 0#usize ⦃ v => SetWithin allowed v ⦄ := by
  unfold acl.expand_user_loop
  refine loop_idx_spec
    (fun (x : alloc.vec.Vec U64 × Usize) => acl.expand_user_loop.body direct x.1 x.2)
    (fun x => x.2) direct.val.length
    (fun x => SetWithin allowed x.1) (SetWithin allowed) ?_ _ hs (by simp)
  rintro ⟨v, i⟩ hv hi
  unfold acl.expand_user_loop.body
  dsimp only
  split
  · step as ⟨x, hx⟩
    have hmem : x ∈ allowed := hd (by simp [hx])
    step with push_new_within allowed v x hb hv hmem
    step*
  · simp [hv]

abbrev userIds (db : model.Db) (uid : U64) : List U64 :=
  uid :: acl.INTERNAL_GROUP_ID :: groupIds db

@[step] theorem expand_user_total (db : model.Db) (uid : U64)
    (hm : db.memberships.length + 2 ≤ Usize.max) :
    acl.expand_user db uid ⦃ _ => True ⦄ := by
  have hb : (userIds db uid).length ≤ Usize.max := by
    simp only [userIds, groupIds, List.length_cons, List.length_map]
    change db.memberships.val.length + 2 ≤ Usize.max at hm
    omega
  unfold acl.expand_user
  step as ⟨set, hset⟩
  have hs : SetWithin (userIds db uid) set := by simp [SetWithin, hset]
  step as ⟨b⟩
  simp only [bind_ite]
  split
  · step as ⟨direct, hdir⟩
    have hd : direct.val ⊆ userIds db uid :=
      fun _ h => List.mem_cons_of_mem _ (List.mem_cons_of_mem _ (hdir.2 h))
    exact WP.spec_mono (expand_loop_within (userIds db uid) set direct hb hs hd) (by intro _ _; trivial)
  · step with push_new_within (userIds db uid) set acl.INTERNAL_GROUP_ID hb hs (by simp)
      as ⟨set1, hs1⟩
    step as ⟨direct, hdir⟩
    have hd : direct.val ⊆ userIds db uid :=
      fun _ h => List.mem_cons_of_mem _ (List.mem_cons_of_mem _ (hdir.2 h))
    exact WP.spec_mono (expand_loop_within (userIds db uid) set1 direct hb hs1 hd) (by intro _ _; trivial)

@[step] theorem subject_match_set_total (db : model.Db) (s : model.Subject)
    (hm : db.memberships.length + 2 ≤ Usize.max) :
    acl.subject_match_set db s ⦃ _ => True ⦄ := by
  unfold acl.subject_match_set
  h5i_steps

@[step] theorem cascade_grant_total (db : model.Db) (s : model.Subject) (r : model.Resource)
    (p : model.Permission) (now : I64) (hm : db.memberships.length + 2 ≤ Usize.max) :
    acl.cascade_grant db s r p now ⦃ _ => True ⦄ := by
  unfold acl.cascade_grant
  h5i_steps
  rcases x with ⟨types, ids⟩
  h5i_steps

@[step] theorem caller_role_loop_total (db : model.Db) (id : U64) (now : I64)
    (types : alloc.vec.Vec U8) (ids : alloc.vec.Vec U64) :
    acl.caller_role_on_drive_loop db id now types ids none 0#usize ⦃ _ => True ⦄ := by
  unfold acl.caller_role_on_drive_loop
  h5i_total (fun x => x.2) db.grants.val.length

@[step] theorem caller_role_total (db : model.Db) (s : model.Subject) (id : U64) (now : I64)
    (hm : db.memberships.length + 2 ≤ Usize.max) :
    acl.caller_role_on_drive db s id now ⦃ _ => True ⦄ := by
  unfold acl.caller_role_on_drive
  h5i_steps

theorem check_total (db : model.Db) (ro : Bool) (now : I64) (s : model.Subject) (p : model.Permission)
    (r : model.Resource) (hm : db.memberships.length + 2 ≤ Usize.max) : ∃ b, acl.check db ro now s p r = ok b := by
  apply ok_of (P := fun _ => True)
  unfold acl.check
  h5i_steps

end oxicloud_kernel.Solution
