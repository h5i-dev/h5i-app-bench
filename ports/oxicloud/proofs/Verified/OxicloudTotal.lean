import Verified.OxicloudExpiredGrants
import Mathlib.Data.List.Perm.Subperm
import Verified.OxicloudTokenGrant
open Aeneas Aeneas.Std Result oxicloud_kernel
open H5iAppLib hiding lit
open oxicloud_kernel.Verified.OxicloudExpiredGrants

namespace oxicloud_kernel.Verified.OxicloudTotal

/-- A finite set of identifiers, contained in a fixed universe. -/
def Within (pool : List U64) (v : alloc.vec.Vec U64) : Prop :=
  v.val.Nodup ∧ v.val ⊆ pool

theorem within_length {u : List U64} {v : alloc.vec.Vec U64} (h : Within u v) :
    v.val.length ≤ u.length :=
  (List.subperm_of_subset h.1 h.2).length_le

theorem new_capacity {u : List U64} {v : alloc.vec.Vec U64} {x : U64}
    (h : Within u v) (hx : x ∈ u) (hn : x ∉ v.val) (hu : u.length ≤ Usize.max) :
    v.val.length < Usize.max := by
  have hd : (v.val ++ [x]).Nodup := by simpa using List.Nodup.concat hn h.1
  have hs : v.val ++ [x] ⊆ u := by
    intro y hy
    simp only [List.mem_append, List.mem_singleton] at hy
    rcases hy with hy | rfl
    · exact h.2 hy
    · exact hx
  have hl := (List.subperm_of_subset hd hs).length_le
  simp only [List.length_append, List.length_singleton] at hl
  omega

theorem within_append {u : List U64} {v out : alloc.vec.Vec U64} {x : U64}
    (h : Within u v) (hx : x ∈ u) (hn : x ∉ v.val)
    (he : out.val = v.val ++ [x]) : Within u out := by
  rw [Within, he]
  constructor
  · simpa using List.Nodup.concat hn h.1
  · intro y hy
    simp only [List.mem_append, List.mem_singleton] at hy
    rcases hy with hy | rfl
    · exact h.2 hy
    · exact hx

@[step] theorem push_new_spec (u : List U64) (v : alloc.vec.Vec U64) (x : U64)
    (h : Within u v) (hx : x ∈ u) (hu : u.length ≤ Usize.max) :
    acl.push_new v x ⦃ out => Within u out ⦄ := by
  unfold acl.push_new
  step
  simp only [oxicloud_kernel.Verified.OxicloudTokenGrant.deref_val] at out_post
  by_cases hm : x ∈ v.val
  · have hb : out = true := by simpa [hm] using out_post
    simp only [hb, ite_true]
    simpa using h
  · have hb : out = false := by simpa [hm] using out_post
    simp only [hb, Bool.false_eq_true, ite_false]
    apply WP.spec_mono (alloc.vec.Vec.push_spec v x (new_capacity h hx hm hu))
    intro out hout
    rw [Within, hout]
    constructor
    · simpa using List.Nodup.concat hm h.1
    · intro y hy
      simp only [List.mem_append, List.mem_singleton] at hy
      rcases hy with hy | rfl
      · exact h.2 hy
      · exact hx

@[step] theorem member_reaches_total (m : model.Member) (uid : U64) (v : Slice U64) :
    acl.member_reaches m uid v ⦃ _ => True ⦄ := by
  cases m <;> unfold acl.member_reaches
  · step*
  · exact WP.spec_mono (contains_spec v _) (by intro _ _; trivial)

/-- Group expansion cannot create an identifier absent from the membership table. -/
@[step] theorem add_parents_spec (db : model.Db) (uid : U64) (v : alloc.vec.Vec U64)
    (hv : Within (db.memberships.val.map (·.group_id)) v)
    (hm : db.memberships.length < Usize.max) :
    acl.add_parents db uid v ⦃ out => Within (db.memberships.val.map (·.group_id)) out.1 ⦄ := by
  unfold acl.add_parents acl.add_parents_loop
  apply loop_idx_spec (α := alloc.vec.Vec U64 × Bool × Usize) (β := alloc.vec.Vec U64 × Bool) _ (fun x => x.2.2) db.memberships.length
    (fun x => Within (db.memberships.val.map (·.group_id)) x.1)
    (fun out => Within (db.memberships.val.map (·.group_id)) out.1) ?_ _ hv (by simp)
  rintro ⟨out, grew, i⟩ hout hi
  unfold acl.add_parents_loop.body
  dsimp only
  split
  · rename_i hlt
    have hil : i.val < db.memberships.val.length := by scalar_tac
    step
    have hmem : m.group_id ∈ db.memberships.val.map (·.group_id) := by
      apply List.mem_map.mpr
      exact ⟨m, by rw [m_post]; exact List.getElem_mem hil, rfl⟩
    step
    cases b <;> simp only [Bool.false_eq_true, ite_false, ite_true]
    · step*
    · step
      simp only [oxicloud_kernel.Verified.OxicloudTokenGrant.deref_val] at grew1
      cases out1 <;> simp only [Bool.false_eq_true, ite_false, ite_true] at *
      · have hn : m.group_id ∉ out.val := by simpa using grew1.symm
        have hcap := new_capacity hout hmem hn (by simp only [List.length_map]; exact Nat.le_of_lt hm)
        step*
        exact ⟨within_append hout hmem hn x_post, by scalar_tac, by scalar_tac⟩
      · step*
  · step*

@[step] theorem groups_for_user_spec (db : model.Db) (uid : U64)
    (hm : db.memberships.length + 2 ≤ Usize.max) :
    acl.groups_for_user db uid ⦃ out => Within (db.memberships.val.map (·.group_id)) out ⦄ := by
  unfold acl.groups_for_user acl.groups_for_user_loop
  apply loop_idx_spec (α := alloc.vec.Vec U64 × Usize × Bool) (β := alloc.vec.Vec U64)
    _ (fun x => x.2.1) (db.memberships.length + 1)
    (fun x => Within (db.memberships.val.map (·.group_id)) x.1)
    (fun out => Within (db.memberships.val.map (·.group_id)) out) ?_ _
    (by simp [Within, alloc.vec.Vec.new]) (by simp)
  rintro ⟨found, round, grew⟩ hfound hr
  unfold acl.groups_for_user_loop.body
  have hm' : db.memberships.length < Usize.max := by omega
  have hs := add_parents_spec db uid found hfound hm'
  step*

@[step] theorem is_external_total (db : model.Db) (uid : U64) :
    acl.is_external db uid ⦃ _ => True ⦄ := by
  unfold acl.is_external acl.is_external_loop
  apply loop_idx_spec _ (fun i => i) db.users.length (fun _ => True) (fun _ => True) ?_ _ trivial (by simp)
  intro i _ hi
  unfold acl.is_external_loop.body
  step*

@[step] theorem expand_user_total (db : model.Db) (uid : U64)
    (hm : db.memberships.length + 2 ≤ Usize.max) :
    acl.expand_user db uid ⦃ _ => True ⦄ := by
  let pool := uid :: acl.INTERNAL_GROUP_ID :: db.memberships.val.map (·.group_id)
  have hpool : pool.length ≤ Usize.max := by simp only [pool, List.length_cons, List.length_map]; scalar_tac
  have hstart : (alloc.vec.Vec.new U64).val.length < Usize.max := by simp; scalar_tac
  unfold acl.expand_user
  step
  step
  have hset : Within pool set := by simp_all [Within, pool]
  have hint : acl.INTERNAL_GROUP_ID ∈ pool := by simp [pool]
  have hp := push_new_spec pool set acl.INTERNAL_GROUP_ID hset hint hpool
  have hif : (if b = true then ok set else acl.push_new set acl.INTERNAL_GROUP_ID) ⦃ out => Within pool out ⦄ := by
    cases b <;> simp only [Bool.false_eq_true, ite_false, ite_true]
    · exact hp
    · simpa using hset
  step
  have hset1 : Within pool set1 := set1_post
  step
  have hdir := within_length direct_post
  unfold acl.expand_user_loop
  apply loop_idx_spec (α := alloc.vec.Vec U64 × Usize) (β := alloc.vec.Vec U64)
    _ (fun x => x.2) direct.length (fun x => Within pool x.1) (fun _ => True)
    ?_ _ hset1 (by simp)
  rintro ⟨acc, i⟩ hacc hi
  unfold acl.expand_user_loop.body
  dsimp only
  split
  · rename_i hlt
    have hil : i.val < direct.val.length := by scalar_tac
    step
    have hmem : i2 ∈ pool := by
      have hx : i2 ∈ direct.val := by rw [i2_post]; exact List.getElem_mem hil
      have := direct_post.2 hx
      simp only [pool, List.mem_cons]
      exact Or.inr (Or.inr this)
    have hs := push_new_spec pool acc i2 hacc hmem hpool
    step*
  · step*

@[step] theorem subject_match_set_total (db : model.Db) (s : model.Subject)
    (hm : db.memberships.length + 2 ≤ Usize.max) :
    acl.subject_match_set db s ⦃ _ => True ⦄ := by
  have hs := expand_user_total db
  cases s <;> unfold acl.subject_match_set <;> step*

@[step] theorem find_file_spec (db : model.Db) (id : U64) :
    acl.find_file db id ⦃ o => o = db.files.val.find? (·.id == id) ⦄ := by
  unfold acl.find_file acl.find_file_loop
  h5i_search_find db.files.val (fun f => f.id == id)

@[step] theorem drive_of_total (db : model.Db) (r : model.Resource) :
    acl.drive_of db r ⦃ _ => True ⦄ := by
  cases r <;> unfold acl.drive_of <;> step*

@[step] theorem file_parent_folder_total (db : model.Db) (id : U64) :
    acl.file_parent_folder db id ⦃ _ => True ⦄ := by
  unfold acl.file_parent_folder
  step*

@[step] theorem drive_policies_total (db : model.Db) (id : U64) :
    acl.drive_policies db id ⦃ _ => True ⦄ := by
  unfold acl.drive_policies acl.drive_policies_loop
  apply loop_idx_spec _ (fun i => i) db.drives.length (fun _ => True) (fun _ => True) ?_ _ trivial (by simp)
  intro i _ hi
  unfold acl.drive_policies_loop.body
  step*

@[step] theorem caller_role_total (db : model.Db) (s : model.Subject) (id : U64) (now : I64)
    (hm : db.memberships.length + 2 ≤ Usize.max) :
    acl.caller_role_on_drive db s id now ⦃ _ => True ⦄ := by
  unfold acl.caller_role_on_drive
  step
  exact WP.spec_mono (caller_loop_spec db id now types ids none) (by intro _ _; trivial)

@[step] theorem direct_grant_total (db : model.Db) (types : Slice U8) (ids : Slice U64)
    (p : model.Permission) (r : model.Resource) (now : I64) :
    acl.direct_grant_exists db types ids p r now ⦃ _ => True ⦄ := by
  unfold acl.direct_grant_exists
  exact WP.spec_mono (direct_loop_spec db types ids p r now) (by intro _ _; trivial)

@[step] theorem folder_cascade_total (db : model.Db) (types : Slice U8) (ids : Slice U64)
    (p : model.Permission) (id : U64) (now : I64) :
    acl.folder_cascade_grant_exists db types ids p id now ⦃ _ => True ⦄ := by
  unfold acl.folder_cascade_grant_exists
  step
  cases o with
  | none => simp
  | some f =>
    exact WP.spec_mono (folder_loop_spec db types ids p now f.lpath) (by intro _ _; trivial)

@[step] theorem cascade_total (db : model.Db) (s : model.Subject) (r : model.Resource)
    (p : model.Permission) (now : I64) (hm : db.memberships.length + 2 ≤ Usize.max) :
    acl.cascade_grant db s r p now ⦃ _ => True ⦄ := by
  cases r <;> unfold acl.cascade_grant <;> step*
  cases o <;> step*
  rcases x with ⟨types, ids⟩
  step*

@[step] theorem role_grants_total (r : model.Role) (p : model.Permission) :
    acl.role_grants r p ⦃ _ => True ⦄ := by
  cases r <;> cases p <;> simp [acl.role_grants, model.Permission.Insts.CoreCmpPartialEqPermission.eq, model.Permission.read_discriminant]

@[step] theorem role_has_total (r : Option model.Role) (p : model.Permission) :
    acl.role_has r p ⦃ _ => True ⦄ := by
  cases r <;> unfold acl.role_has <;> step*

@[step] theorem read_only_gate_total (p : model.Permission) :
    acl.read_only_gate_applies p ⦃ _ => True ⦄ := by
  cases p <;> simp [acl.read_only_gate_applies, model.Permission.Insts.CoreCmpPartialEqPermission.eq, core.cmp.PartialEq.ne.trait_default, core.cmp.PartialEq.ne.default, model.Permission.read_discriminant]

theorem check_total (db : model.Db) (ro : Bool) (now : I64) (s : model.Subject)
    (p : model.Permission) (r : model.Resource) (hm : db.memberships.length + 2 ≤ Usize.max) :
    ∃ b, acl.check db ro now s p r = ok b := by
  apply ok_of (P := fun _ => True)
  cases r <;> unfold acl.check <;> step*

end oxicloud_kernel.Verified.OxicloudTotal
