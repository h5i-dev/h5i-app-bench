import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

namespace oxicloud_kernel.Verified.OxicloudExpiredGrants


/-- Databases that agree on every table but the grants. -/
def NG (a b : model.Db) : Prop :=
  a.users = b.users ∧ a.memberships = b.memberships ∧ a.drives = b.drives ∧ a.folders = b.folders ∧ a.files = b.files

theorem find_folder_cong {a b : model.Db} (h : NG a b) (id : U64) :
    acl.find_folder a id = acl.find_folder b id := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := h
  simp only [acl.find_folder, acl.find_folder_loop, acl.find_folder_loop.body, h4]

theorem find_file_cong {a b : model.Db} (h : NG a b) (id : U64) :
    acl.find_file a id = acl.find_file b id := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := h
  simp only [acl.find_file, acl.find_file_loop, acl.find_file_loop.body, h5]

theorem subject_match_set_cong {a b : model.Db} (h : NG a b) (s : model.Subject) :
    acl.subject_match_set a s = acl.subject_match_set b s := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := h
  simp only [acl.subject_match_set, acl.expand_user, acl.is_external, acl.is_external_loop,
    acl.is_external_loop.body, acl.groups_for_user, acl.groups_for_user_loop,
    acl.groups_for_user_loop.body, acl.add_parents, acl.add_parents_loop, acl.add_parents_loop.body,
    h1, h2]

theorem drive_policies_cong {a b : model.Db} (h : NG a b) (d : U64) :
    acl.drive_policies a d = acl.drive_policies b d := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := h
  simp only [acl.drive_policies, acl.drive_policies_loop, acl.drive_policies_loop.body, h3]

theorem drive_of_cong {a b : model.Db} (h : NG a b) (r : model.Resource) :
    acl.drive_of a r = acl.drive_of b r := by
  simp only [acl.drive_of, find_folder_cong h, find_file_cong h]

theorem file_parent_folder_cong {a b : model.Db} (h : NG a b) (id : U64) :
    acl.file_parent_folder a id = acl.file_parent_folder b id := by
  simp only [acl.file_parent_folder, find_file_cong h]

theorem grant_folder_covers_cong {a b : model.Db} (h : NG a b) (g : model.Grant) (t : Slice U64) :
    acl.grant_folder_covers a g t = acl.grant_folder_covers b g t := by
  simp only [acl.grant_folder_covers, find_folder_cong h]

/-! ## Per-grant tests, as plain functions -/

theorem resource_eq_ok (a b : model.Resource) :
    model.Resource.Insts.CoreCmpPartialEqResource.eq a b = ok (decide (a = b)) := by
  unfold model.Resource.Insts.CoreCmpPartialEqResource.eq
  cases a <;> cases b <;> simp [lift, model.Resource.read_discriminant]

@[step] theorem resource_eq_spec (a b : model.Resource) :
    model.Resource.Insts.CoreCmpPartialEqResource.eq a b ⦃ r => r = decide (a = b) ⦄ := by
  simp [resource_eq_ok]

theorem role_eq_ok (a b : model.Role) :
    model.Role.Insts.CoreCmpPartialEqRole.eq a b = ok (decide (a = b)) := by
  unfold model.Role.Insts.CoreCmpPartialEqRole.eq
  cases a <;> cases b <;> simp [model.Role.read_discriminant]

@[step] theorem contains_spec (ids : Slice U64) (x : U64) :
    acl.contains ids x ⦃ b => b = ids.val.any (· == x) ⦄ := by
  unfold acl.contains acl.contains_loop
  h5i_search_any ids.val (fun y => y == x)

@[step] theorem contains_u8_spec (ids : Slice U8) (x : U8) :
    acl.contains_u8 ids x ⦃ b => b = ids.val.any (· == x) ⦄ := by
  unfold acl.contains_u8 acl.contains_u8_loop
  h5i_search_any ids.val (fun y => y == x)

def stype : model.Subject → U8
  | .User _ => 0#u8
  | .Group _ => 1#u8
  | .Token _ => 2#u8

def sid : model.Subject → U64
  | .User x | .Group x | .Token x => x

def SM (types : Slice U8) (ids : Slice U64) (g : model.Grant) : Bool :=
  types.val.any (· == stype g.subject) && ids.val.any (· == sid g.subject)

@[step] theorem subject_matches_spec (g : model.Grant) (types : Slice U8) (ids : Slice U64) :
    acl.subject_matches g types ids ⦃ b => b = SM types ids g ⦄ := by
  unfold acl.subject_matches
  cases h : g.subject <;> simp only [acl.subject_type, acl.subject_id] <;> step* <;>
    simp_all [SM, stype, sid]
  all_goals (intro hm; have := b_post _ hm; simp at this)

/-- The value of a run that succeeds. -/
noncomputable def pv (m : Result Bool) : Bool :=
  open Classical in if h : ∃ b, m = ok b then h.choose else false

theorem pv_eq {m : Result Bool} (h : ∃ b, m = ok b) : m = ok (pv m) := by
  rw [pv, dif_pos h]; exact h.choose_spec

noncomputable def RI (role : model.Role) (p : model.Permission) : Bool := pv (acl.role_implies role p)

@[step] theorem role_implies_spec (role : model.Role) (p : model.Permission) :
    acl.role_implies role p ⦃ b => b = RI role p ⦄ := by
  have : ∃ b, acl.role_implies role p = ok b := by
    cases role <;> cases p <;> simp [acl.role_implies, role_eq_ok]
  rw [pv_eq this]; simp [RI]

theorem live_ok (g : model.Grant) (now : I64) : acl.live g now = ok (live g now) := by
  unfold acl.live live
  cases g.expires_at <;> simp

@[step] theorem live_spec (g : model.Grant) (now : I64) : acl.live g now ⦃ b => b = live g now ⦄ := by
  simp [live_ok]

def rank : model.Role → Nat
  | .Owner => 0
  | .Editor => 1
  | .Contributor => 2
  | .Commenter => 3
  | .Viewer => 4

def STR (a : Option model.Role) (b : model.Role) : Option model.Role :=
  match a with
  | none => some b
  | some x => if rank b < rank x then some b else some x

@[step] theorem stronger_spec (a : Option model.Role) (b : model.Role) :
    acl.stronger a b ⦃ r => r = STR a b ⦄ := by
  unfold acl.stronger STR
  cases a with
  | none => simp
  | some x => cases b <;> cases x <;> simp [acl.role_rank, rank]

theorem lpath_contains_total (a b : Slice U64) : acl.lpath_contains a b ⦃ _ => True ⦄ := by
  unfold acl.lpath_contains
  simp only
  split
  · simp
  · have hab : a.length ≤ b.length := by scalar_tac
    unfold acl.lpath_contains_loop
    apply H5iAppLib.loop_idx_spec _ (fun i => i) a.length (fun _ => True) _ ?step _ trivial (by simp)
    intro x _ hx
    unfold acl.lpath_contains_loop.body
    step*

@[step] theorem find_folder_spec (db : model.Db) (id : U64) :
    acl.find_folder db id ⦃ o => o = db.folders.val.find? (·.id == id) ⦄ := by
  unfold acl.find_folder acl.find_folder_loop
  h5i_search_find db.folders.val (fun f => f.id == id)

noncomputable def COV (db : model.Db) (t : Slice U64) (g : model.Grant) : Bool :=
  pv (acl.grant_folder_covers db g t)

@[step] theorem grant_folder_covers_spec (db : model.Db) (g : model.Grant) (t : Slice U64) :
    acl.grant_folder_covers db g t ⦃ b => b = COV db t g ⦄ := by
  have : ∃ b, acl.grant_folder_covers db g t = ok b := by
    unfold acl.grant_folder_covers
    cases g.resource <;> simp
    rename_i fid
    obtain ⟨o, ho⟩ := ok_of (find_folder_spec db fid)
    rw [ho]
    cases o with
    | none => simp
    | some gf =>
      obtain ⟨r, hr⟩ := ok_of (lpath_contains_total (alloc.vec.Vec.deref gf.lpath) t)
      simp [hr]
  rw [pv_eq this]; simp [COV]

/-! ## The three loops over the grants -/

def CS (types : Slice U8) (ids : Slice U64) (d : U64) (now : I64) (acc : Option model.Role)
    (g : model.Grant) : Option model.Role :=
  if SM types ids g && decide (g.resource = .Drive d) && live g now then STR acc g.role else acc

theorem direct_loop_spec (db : model.Db) (types : Slice U8) (ids : Slice U64) (p : model.Permission)
    (r : model.Resource) (now : I64) :
    acl.direct_grant_exists_loop db types ids p r now 0#usize ⦃ b => b =
      db.grants.val.any (fun g => SM types ids g && RI g.role p && decide (g.resource = r) && live g now) ⦄ := by
  unfold acl.direct_grant_exists_loop
  h5i_search_any db.grants.val (fun g => SM types ids g && RI g.role p && decide (g.resource = r) && live g now)

theorem folder_loop_spec (db : model.Db) (types : Slice U8) (ids : Slice U64) (p : model.Permission)
    (now : I64) (target : alloc.vec.Vec U64) :
    acl.folder_cascade_grant_exists_loop db types ids p now target 0#usize ⦃ b => b =
      db.grants.val.any (fun g => SM types ids g && RI g.role p && live g now &&
        COV db (alloc.vec.Vec.deref target) g) ⦄ := by
  unfold acl.folder_cascade_grant_exists_loop
  h5i_search_any db.grants.val (fun g => SM types ids g && RI g.role p && live g now &&
    COV db (alloc.vec.Vec.deref target) g)

theorem caller_loop_spec (db : model.Db) (d : U64) (now : I64) (types : alloc.vec.Vec U8)
    (ids : alloc.vec.Vec U64) (best : Option model.Role) :
    acl.caller_role_on_drive_loop db d now types ids best 0#usize ⦃ r => r =
      db.grants.val.foldl (CS (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) d now) best ⦄ := by
  unfold acl.caller_role_on_drive_loop
  apply WP.spec_mono (H5iAppLib.loop_fold db.grants.val id
    (CS (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) d now) (fun _ _ => True) _ ?step best 0#usize
    (by simp) trivial)
  · intro r hr; simpa using hr
  case step =>
    intro s i hi _
    simp only
    unfold acl.caller_role_on_drive_loop.body
    h5i_step [CS]

/-! ## Equal results on the two databases -/

theorem direct_eq {a b : model.Db} (hg : a.grants.val = b.grants.val.filter (fun g => live g now))
    (types : Slice U8) (ids : Slice U64) (p : model.Permission) (r : model.Resource) :
    acl.direct_grant_exists a types ids p r now = acl.direct_grant_exists b types ids p r now := by
  unfold acl.direct_grant_exists
  rw [eq_ok_of_spec (direct_loop_spec a types ids p r now), eq_ok_of_spec (direct_loop_spec b types ids p r now),
    hg, any_filter_of_imp]
  intro x _ hx
  simp_all

theorem folder_loop_eq {a b : model.Db} (h : NG a b)
    (hg : a.grants.val = b.grants.val.filter (fun g => live g now))
    (types : Slice U8) (ids : Slice U64) (p : model.Permission) (target : alloc.vec.Vec U64) :
    acl.folder_cascade_grant_exists_loop a types ids p now target 0#usize =
      acl.folder_cascade_grant_exists_loop b types ids p now target 0#usize := by
  rw [eq_ok_of_spec (folder_loop_spec a types ids p now target),
    eq_ok_of_spec (folder_loop_spec b types ids p now target), hg, any_filter_of_imp]
  · simp only [COV, grant_folder_covers_cong h]
  · intro x _ hx
    simp_all

theorem folder_eq {a b : model.Db} (h : NG a b)
    (hg : a.grants.val = b.grants.val.filter (fun g => live g now))
    (types : Slice U8) (ids : Slice U64) (p : model.Permission) (fid : U64) :
    acl.folder_cascade_grant_exists a types ids p fid now =
      acl.folder_cascade_grant_exists b types ids p fid now := by
  simp only [acl.folder_cascade_grant_exists, find_folder_cong h, folder_loop_eq h hg]

theorem caller_eq {a b : model.Db} (h : NG a b)
    (hg : a.grants.val = b.grants.val.filter (fun g => live g now)) (s : model.Subject) (d : U64) :
    acl.caller_role_on_drive a s d now = acl.caller_role_on_drive b s d now := by
  have hl : ∀ types ids, acl.caller_role_on_drive_loop a d now types ids none 0#usize =
      acl.caller_role_on_drive_loop b d now types ids none 0#usize := by
    intro types ids
    rw [eq_ok_of_spec (caller_loop_spec a d now types ids none),
      eq_ok_of_spec (caller_loop_spec b d now types ids none), hg, foldl_filter_of_skip]
    intro acc x hx
    simp [CS, hx]
  simp only [acl.caller_role_on_drive, subject_match_set_cong h, hl]

theorem cascade_eq {a b : model.Db} (h : NG a b)
    (hg : a.grants.val = b.grants.val.filter (fun g => live g now))
    (s : model.Subject) (r : model.Resource) (p : model.Permission) :
    acl.cascade_grant a s r p now = acl.cascade_grant b s r p now := by
  simp only [acl.cascade_grant, subject_match_set_cong h, file_parent_folder_cong h, folder_eq h hg,
    direct_eq hg]

theorem expired_grants_ignored (db db' : model.Db) (ro : Bool) (now : I64) (s : model.Subject)
    (p : model.Permission) (r : model.Resource) (hs : SameButGrants db db')
    (hg : db'.grants.val = db.grants.val.filter (fun g => live g now)) :
    acl.check db' ro now s p r = acl.check db ro now s p r := by
  have h : NG db' db := ⟨hs.1.symm, hs.2.1.symm, hs.2.2.1.symm, hs.2.2.2.1.symm, hs.2.2.2.2.symm⟩
  simp only [acl.check, drive_of_cong h, drive_policies_cong h, caller_eq h hg, cascade_eq h hg,
    subject_match_set_cong h, direct_eq hg]

end oxicloud_kernel.Verified.OxicloudExpiredGrants
