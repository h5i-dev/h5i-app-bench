import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

namespace oxicloud_kernel.Counterexample

/- Removing a Contributor drive grant exposes the remaining Commenter grant.
Contributor ranks above Commenter, but does not grant Comment permission.
The task's statement has no GrantsUnique hypothesis, so both rows below
are permitted by its assumptions. -/

h5i_derive_eq model.Permission model.Permission.Insts.CoreCmpPartialEqPermission.eq
deriving instance DecidableEq for model.Subject

def commenter : model.Grant :=
  ⟨1#u64, .Group 1#u64, .Drive 1#u64, .Commenter, 0#u64, none⟩

def contributor : model.Grant :=
  ⟨2#u64, .Group 1#u64, .Drive 1#u64, .Contributor, 0#u64, none⟩

def database (gs : List model.Grant) (bound : gs.length ≤ Usize.max) : model.Db :=
  ⟨alloc.vec.Vec.new _, alloc.vec.Vec.new _, alloc.vec.Vec.from gs bound,
    alloc.vec.Vec.new _, alloc.vec.Vec.new _, alloc.vec.Vec.new _⟩

def more : model.Db := database [commenter, contributor] (by scalar_tac)
def fewer : model.Db := database [commenter] (by scalar_tac)

theorem same_tables : SameButGrants more fewer := by
  simp [SameButGrants, more, fewer, database]

theorem grants_subset : ∀ g ∈ fewer.grants.val, g ∈ more.grants.val := by
  simp [more, fewer, database]

theorem contains_spec (xs : Slice U64) (x : U64) :
    acl.contains xs x ⦃ b => b = decide (x ∈ xs.val) ⦄ := by
  unfold acl.contains acl.contains_loop
  h5i_search_any xs.val (fun y => decide (y = x))
  rename_i hr
  rw [← hr, any_eq_iff]
  apply Bool.eq_iff_iff.mpr
  simp only [decide_eq_true_eq]

theorem contains_u8_spec (xs : Slice U8) (x : U8) :
    acl.contains_u8 xs x ⦃ b => b = decide (x ∈ xs.val) ⦄ := by
  unfold acl.contains_u8 acl.contains_u8_loop
  h5i_search_any xs.val (fun y => decide (y = x))
  rename_i hr
  rw [← hr, any_eq_iff]
  apply Bool.eq_iff_iff.mpr
  simp only [decide_eq_true_eq]

attribute [local step] contains_spec contains_u8_spec

def roleRank : model.Role → U8
  | .Owner => 0#u8
  | .Editor => 1#u8
  | .Contributor => 2#u8
  | .Commenter => 3#u8
  | .Viewer => 4#u8

def pick (a : Option model.Role) (b : model.Role) : Option model.Role :=
  match a with
  | none => some b
  | some x => if roleRank b < roleRank x then some b else a

@[step] theorem rank_spec (r : model.Role) :
    acl.role_rank r ⦃ x => x = roleRank r ⦄ := by
  cases r <;> simp [acl.role_rank, roleRank]

@[step] theorem stronger_spec (a : Option model.Role) (b : model.Role) :
    acl.stronger a b ⦃ x => x = pick a b ⦄ := by
  unfold acl.stronger
  cases a <;> step* <;> simp_all [pick]

@[step] theorem resource_eq_spec (a b : model.Resource) :
    model.Resource.Insts.CoreCmpPartialEqResource.eq a b ⦃ x => x = decide (a = b) ⦄ := by
  unfold model.Resource.Insts.CoreCmpPartialEqResource.eq
  cases a <;> cases b <;> simp [lift, model.Resource.read_discriminant]

@[step] theorem match_spec (g : model.Grant) (types : Slice U8) (ids : Slice U64) :
    acl.subject_matches g types ids ⦃ b => b =
      match g.subject with
      | .User x => decide (0#u8 ∈ types.val ∧ x ∈ ids.val)
      | .Group x => decide (1#u8 ∈ types.val ∧ x ∈ ids.val)
      | .Token x => decide (2#u8 ∈ types.val ∧ x ∈ ids.val) ⦄ := by
  unfold acl.subject_matches acl.subject_type acl.subject_id
  cases g.subject <;> step* <;> simp_all

@[step] theorem live_spec (g : model.Grant) (now : I64) :
    acl.live g now ⦃ b => b = Spec.live g now ⦄ := by
  unfold acl.live Spec.live
  cases g.expires_at <;> step*

def subjectMatches (g : model.Grant) (types : Slice U8) (ids : Slice U64) : Bool :=
  match g.subject with
  | .User x => decide (0#u8 ∈ types.val ∧ x ∈ ids.val)
  | .Group x => decide (1#u8 ∈ types.val ∧ x ∈ ids.val)
  | .Token x => decide (2#u8 ∈ types.val ∧ x ∈ ids.val)

def driveStep (types : Slice U8) (ids : Slice U64) (d : U64) (now : I64)
    (best : Option model.Role) (g : model.Grant) : Option model.Role :=
  if subjectMatches g types ids && decide (g.resource = .Drive d) && Spec.live g now
  then pick best g.role else best

@[step] theorem role_loop_spec (db : model.Db) (d : U64) (now : I64)
    (types : alloc.vec.Vec U8) (ids : alloc.vec.Vec U64) (best : Option model.Role) :
    acl.caller_role_on_drive_loop db d now types ids best 0#usize ⦃ x =>
      x = db.grants.val.foldl
        (driveStep (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) d now) best ⦄ := by
  unfold acl.caller_role_on_drive_loop
  apply WP.spec_mono (loop_fold db.grants.val id
    (driveStep (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) d now)
    (fun _ _ => True) _ ?_ best 0#usize (by simp) trivial)
  · intro y hy
    simpa using hy
  · intro best i hi _
    unfold acl.caller_role_on_drive_loop.body
    h5i_steps
    all_goals simp_all [FoldStep, driveStep, subjectMatches]
    all_goals scalar_tac

@[step] theorem group_set_spec (db : model.Db) (x : U64) :
    acl.subject_match_set db (.Group x) ⦃ v =>
      v.1.val = [1#u8] ∧ v.2.val = [x] ⦄ := by
  unfold acl.subject_match_set
  step*

theorem group_role (db : model.Db) (x d : U64) (now : I64) :
    acl.caller_role_on_drive db (.Group x) d now ⦃ role =>
      role = db.grants.val.foldl
        (fun best g => if g.subject = .Group x ∧ g.resource = .Drive d ∧ Spec.live g now = true
          then pick best g.role else best) none ⦄ := by
  unfold acl.caller_role_on_drive
  step*
  rw [role_post]
  congr 1
  funext best g
  cases hs : g.subject <;>
    simp [driveStep, subjectMatches, vec_deref_val, types_post, types_post1, hs]

theorem fewer_role :
    acl.caller_role_on_drive fewer (.Group 1#u64) 1#u64 0#i64 = ok (some .Commenter) := by
  apply eq_ok_of_spec
  apply WP.spec_mono (group_role fewer 1#u64 1#u64 0#i64)
  intro role hrole
  simpa [fewer, database, commenter, Spec.live, pick] using hrole

theorem more_role :
    acl.caller_role_on_drive more (.Group 1#u64) 1#u64 0#i64 = ok (some .Contributor) := by
  apply eq_ok_of_spec
  apply WP.spec_mono (group_role more 1#u64 1#u64 0#i64)
  intro role hrole
  simpa [more, database, commenter, contributor, Spec.live, pick, roleRank] using hrole

theorem policies (gs : List model.Grant) (bound : gs.length ≤ Usize.max) :
    acl.drive_policies (database gs bound) 1#u64 = ok
      ⟨false, false, false, false, false⟩ := by
  unfold acl.drive_policies acl.drive_policies_loop
  rw [loop]
  simp [acl.drive_policies_loop.body, database]

theorem fewer_allows :
    acl.check fewer false 0#i64 (.Group 1#u64) .Comment (.Drive 1#u64) = ok true := by
  simp [acl.check, acl.read_only_gate_applies, core.cmp.PartialEq.ne.trait_default,
    core.cmp.PartialEq.ne.default, model.Permission.read_discriminant,
    model.Permission.Insts.CoreCmpPartialEqPermission.eq, fewer_role,
    show acl.drive_policies fewer 1#u64 = ok ⟨false, false, false, false, false⟩ from policies _ _,
    acl.role_has, acl.role_grants]

theorem more_denies :
    acl.check more false 0#i64 (.Group 1#u64) .Comment (.Drive 1#u64) = ok false := by
  simp [acl.check, acl.read_only_gate_applies, core.cmp.PartialEq.ne.trait_default,
    core.cmp.PartialEq.ne.default, model.Permission.read_discriminant,
    model.Permission.Insts.CoreCmpPartialEqPermission.eq, more_role,
    show acl.drive_policies more 1#u64 = ok ⟨false, false, false, false, false⟩ from policies _ _,
    acl.role_has, acl.role_grants]

/-- The universally quantified statement requested in TASK.md is false. -/
theorem not_fewer_grants_allow_no_more :
    ¬ (∀ (db db' : model.Db) (ro : Bool) (now : I64) (s : model.Subject)
        (p : model.Permission) (r : model.Resource),
      SameButGrants db db' →
      (∀ g ∈ db'.grants.val, g ∈ db.grants.val) →
      acl.check db' ro now s p r = ok true →
      acl.check db ro now s p r = ok true) := by
  intro monotone
  have contradiction := monotone more fewer false 0#i64 (.Group 1#u64)
    .Comment (.Drive 1#u64) same_tables grants_subset fewer_allows
  rw [more_denies] at contradiction
  have := Result.ok.inj contradiction
  exact Bool.false_ne_true this

#print axioms not_fewer_grants_allow_no_more

end oxicloud_kernel.Counterexample
