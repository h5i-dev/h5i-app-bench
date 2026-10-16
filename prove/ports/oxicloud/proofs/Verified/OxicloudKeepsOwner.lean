import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

namespace oxicloud_kernel.Verified.OxicloudKeepsOwner



@[step] theorem role_eq_spec (a b : model.Role) :
    model.Role.Insts.CoreCmpPartialEqRole.eq a b ⦃ r => r = decide (a = b) ⦄ := by
  unfold model.Role.Insts.CoreCmpPartialEqRole.eq
  cases a <;> cases b <;> simp [model.Role.read_discriminant]

@[step] theorem resource_eq_spec (a b : model.Resource) :
    model.Resource.Insts.CoreCmpPartialEqResource.eq a b ⦃ r => r = decide (a = b) ⦄ := by
  unfold model.Resource.Insts.CoreCmpPartialEqResource.eq
  cases a <;> cases b <;> simp [model.Resource.read_discriminant, lift, core.cmp.impls.PartialEqU64.eq]

@[step] theorem subject_eq_spec (a b : model.Subject) :
    model.Subject.Insts.CoreCmpPartialEqSubject.eq a b ⦃ r => r = decide (a = b) ⦄ := by
  unfold model.Subject.Insts.CoreCmpPartialEqSubject.eq
  cases a <;> cases b <;> simp [model.Subject.read_discriminant, lift, core.cmp.impls.PartialEqU64.eq]

theorem subject_is_owner_spec (db : model.Db) (d : U64) (s : model.Subject) :
    grantapi.subject_is_owner db d s ⦃ b => b = db.grants.val.any
      (fun g => decide (g.resource = .Drive d ∧ g.subject = s ∧ g.role = .Owner)) ⦄ := by
  unfold grantapi.subject_is_owner grantapi.subject_is_owner_loop
  apply WP.spec_mono (loop_search db.grants.val
    (fun g => decide (g.resource = .Drive d ∧ g.subject = s ∧ g.role = .Owner)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr; exact search_any _ _ _ hr
  · intro j hj; unfold grantapi.subject_is_owner_loop.body; h5i_step


theorem owner_count_spec (db : model.Db) (d : U64) :
    grantapi.owner_count db d ⦃ n => n.val = ownerCount db d ⦄ := by
  unfold grantapi.owner_count grantapi.owner_count_loop
  apply WP.spec_mono (loop_fold db.grants.val (fun n : Usize => n.val)
    (fun c g => c + if decide (g.resource = .Drive d ∧ g.role = .Owner) then 1 else 0)
    (fun n i => n.val ≤ i) _ ?_ 0#usize 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, foldl_count]; simp [ownerCount]
  · intro n j hj hn; unfold grantapi.owner_count_loop.body; h5i_step


theorem push_ok {α} {v w : alloc.vec.Vec α} {x : α} (h : v.push x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h; simp only at h
  split at h
  · simp at h; subst h; simp
  · simp at h

@[step] theorem same_key_spec (g : model.Grant) (s : model.Subject) (r : model.Resource) :
    acl.same_key g s r ⦃ b => b = decide (g.subject = s ∧ g.resource = r) ⦄ := by
  unfold acl.same_key
  step*

/-- What `set_role` does to each existing grant. -/
def upd (s : model.Subject) (r : model.Resource) (role : model.Role) (gb : U64) (e : Option I64)
    (g : model.Grant) : model.Grant :=
  if g.subject = s ∧ g.resource = r then
    { g with subject := s, resource := r, role, granted_by := gb, expires_at := e }
  else g

theorem set_role_loop_ok (grants : Slice model.Grant) (gb : U64) (s : model.Subject)
    (role : model.Role) (r : model.Resource) (e : Option I64)
    (out : alloc.vec.Vec model.Grant) (fresh : U64) (found : Bool) (i : Usize)
    out' fresh' found'
    (h : acl.set_role_loop grants gb s role r e out fresh found i = ok (out', fresh', found'))
    (hinv : out.val = (grants.val.take i.val).map (upd s r role gb e))
    (hf : found = true → ∃ g ∈ out.val, g.resource = r ∧ g.role = role)
    (hi : i.val ≤ grants.val.length) :
    out'.val = grants.val.map (upd s r role gb e) ∧
      (found' = true → ∃ g ∈ out'.val, g.resource = r ∧ g.role = role) := by
  unfold acl.set_role_loop at h
  refine loop_idx_ok _ (fun x => x.2.2.2) grants.val.length
    (fun x => x.1.val = (grants.val.take x.2.2.2.val).map (upd s r role gb e) ∧
      (x.2.2.1 = true → ∃ g ∈ x.1.val, g.resource = r ∧ g.role = role))
    (fun y => y.1.val = grants.val.map (upd s r role gb e) ∧
      (y.2.2 = true → ∃ g ∈ y.1.val, g.resource = r ∧ g.role = role)) ?_ _ _ ⟨hinv, hf⟩ hi h
  rintro ⟨o, fr, fd, j⟩ res ⟨h1, h2⟩ hle hr
  simp only at h1 h2 hle hr ⊢
  unfold acl.set_role_loop.body at hr
  h5i_invert hr
  · obtain ⟨hj, rfl⟩ := slice_index_ok hg
    have hb' := post_of_ok (same_key_spec _ _ _) hb
    obtain ⟨out1, i2, found1⟩ := x
    obtain ⟨i3, hi3, hr⟩ := bind_tc_eq_ok.mp hr
    have hi3v : i3.val = j.val + 1 := by have := add_ok_val hi3; simp at this; omega
    have := Result.ok.inj hr; subst this
    simp only
    have htake : (grants.val.take (j.val + 1)) = grants.val.take j.val ++ [grants.val[j.val]] := by
      rw [List.take_add_one, List.getElem?_eq_getElem hj]; rfl
    split at hx
    · rename_i hbt
      obtain ⟨out2, hp, hx⟩ := bind_tc_eq_ok.mp hx
      have := Result.ok.inj hx; simp only [Prod.mk.injEq] at this
      obtain ⟨rfl, rfl, rfl⟩ := this
      have hp' := push_ok hp
      subst hbt
      have hk : grants.val[j.val].subject = s ∧ grants.val[j.val].resource = r := by simpa using hb'
      refine ⟨⟨?_, fun _ => ⟨{ id := grants.val[j.val].id, subject := s, resource := r, role, granted_by := gb, expires_at := e }, by rw [hp']; simp, rfl, rfl⟩⟩, by scalar_tac, by scalar_tac⟩
      rw [hp', hi3v, htake, h1, List.map_append]; simp only [List.map_cons, List.map_nil, upd, hk]; simp
    · rename_i hbt
      obtain ⟨out2, hp, hx⟩ := bind_tc_eq_ok.mp hx
      have := Result.ok.inj hx; simp only [Prod.mk.injEq] at this
      obtain ⟨rfl, rfl, rfl⟩ := this
      have hp' := push_ok hp
      have hk : ¬ (grants.val[j.val].subject = s ∧ grants.val[j.val].resource = r) := by
        simp at hbt; simpa [hbt] using hb'
      refine ⟨⟨?_, fun hf => ?_⟩, by scalar_tac, by scalar_tac⟩
      · rw [hp', hi3v, htake, h1, List.map_append]; simp only [List.map_cons, List.map_nil, upd, hk]; simp
      · obtain ⟨g, hg, hg'⟩ := h2 hf; exact ⟨g, by rw [hp']; simp [hg], hg'⟩
  · have hlen : grants.val.length ≤ j.val := by scalar_tac
    simp only
    rw [List.take_of_length_le hlen] at h1
    exact ⟨h1, h2⟩

theorem set_role_ok (grants : Slice model.Grant) (gb : U64) (s : model.Subject)
    (role : model.Role) (r : model.Resource) (e : Option I64) (fresh : U64) out res
    (h : acl.set_role grants gb s role r e fresh = ok (out, res)) :
    (∃ extra : List model.Grant, out.val = grants.val.map (upd s r role gb e) ++ extra ∧
      ∀ g ∈ extra, g.role = role) ∧ (∃ g ∈ out.val, g.resource = r ∧ g.role = role) := by
  unfold acl.set_role at h
  h5i_invert h
  obtain ⟨o, i, found⟩ := x
  have hl := set_role_loop_ok _ _ _ _ _ _ _ _ _ _ _ _ _ hx (by simp) (by simp) (by simp)
  obtain ⟨hl1, hl2⟩ := hl
  cases found
  · simp at h
    obtain ⟨o2, hp, h⟩ := bind_tc_eq_ok.mp h
    simp only [Result.ok.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, rfl⟩ := h
    rw [push_ok hp, hl1]
    exact ⟨⟨_, rfl, by simp⟩, { id := i, subject := s, resource := r, role, granted_by := gb, expires_at := e },
      by simp, rfl, rfl⟩
  · simp at h
    obtain ⟨rfl, rfl⟩ := h
    exact ⟨⟨[], by simp [hl1], by simp⟩, hl2 rfl⟩

def isOwnerOn (d : U64) (g : model.Grant) : Bool := decide (g.resource = .Drive d ∧ g.role = .Owner)

def isOwnerAs (d : U64) (s : model.Subject) (g : model.Grant) : Bool :=
  decide (g.resource = .Drive d ∧ g.subject = s ∧ g.role = .Owner)


theorem ownerCount_eq (db : model.Db) (d : U64) :
    ownerCount db d = db.grants.val.countP (isOwnerOn d) := by
  rw [ownerCount, List.countP_eq_length_filter]; rfl
theorem count_upd (l : List model.Grant) (d : U64) (s : model.Subject) (role : model.Role) (gb : U64)
    (e : Option I64) (hrole : role ≠ .Owner) :
    (l.map (upd s (.Drive d) role gb e)).countP (isOwnerOn d) + l.countP (isOwnerAs d s) =
      l.countP (isOwnerOn d) := by
  induction l with
  | nil => simp
  | cons a l ih =>
    simp only [List.map_cons, List.countP_cons]
    by_cases hk : a.subject = s ∧ a.resource = .Drive d
    · simp [upd, hk, isOwnerOn, isOwnerAs, hrole, -List.countP_map]; omega
    · simp only [upd, hk, if_false]
      have : isOwnerAs d s a = false := by
        simp only [isOwnerAs, decide_eq_false_iff_not]; tauto
      simp [this, -List.countP_map]; omega

theorem count_as_le (l : List model.Grant) (d : U64) (s : model.Subject)
    (hu : (l.map (fun g => (g.subject, g.resource))).Nodup) : l.countP (isOwnerAs d s) ≤ 1 := by
  induction l with
  | nil => simp
  | cons a l ih =>
    simp only [List.map_cons, List.nodup_cons, List.mem_map] at hu
    rw [List.countP_cons]
    by_cases ha : isOwnerAs d s a = true
    · have : l.countP (isOwnerAs d s) = 0 := by
        rw [List.countP_eq_zero]
        intro x hx hx'
        simp only [isOwnerAs, decide_eq_true_eq] at ha hx'
        exact hu.1 ⟨x, hx, by rw [ha.1, ha.2.1, hx'.1, hx'.2.1]⟩
      simp [ha, this]
    · simp [ha]; exact ih hu.2

theorem last_owner_ok (db : model.Db) (d : U64) (s : model.Subject)
    (h : grantapi.refuse_if_last_owner_change db d s = ok (.Ok ())) :
    db.grants.val.countP (isOwnerAs d s) = 0 ∨ 2 ≤ ownerCount db d := by
  unfold grantapi.refuse_if_last_owner_change at h
  h5i_invert h
  · have := post_of_ok (owner_count_spec db d) hi
    right; rw [← this]; scalar_tac
  · have hb' := post_of_ok (subject_is_owner_spec db d s) hb
    left; rw [List.countP_eq_zero]; intro x hx hx'
    apply hc; rw [hb']; exact List.any_eq_true.mpr ⟨x, hx, by simpa [isOwnerAs] using hx'⟩

theorem set_member_role_keeps (db db' : model.Db) (env : grantapi.Env) (caller d : U64)
    (s : model.Subject) (role : model.Role) (e : Option I64) (rep : grantapi.Reply)
    (hu : GrantsUnique db) (ho : 0 < ownerCount db d)
    (h : grantapi.set_member_role db env caller d s role e = ok (db', .Ok rep)) :
    0 < ownerCount db' d := by
  unfold grantapi.set_member_role grantapi.with_grants at h
  h5i_invert h
  · h5i_invert hgates
    all_goals
      obtain ⟨grants, g⟩ := x
      simp at h
      obtain ⟨_, _, h⟩ := bind_tc_eq_ok.mp h
      obtain ⟨_, _, h⟩ := bind_tc_eq_ok.mp h
      obtain ⟨_, _, h⟩ := bind_tc_eq_ok.mp h
      obtain ⟨_, _, h⟩ := bind_tc_eq_ok.mp h
      obtain ⟨_, _, h⟩ := bind_tc_eq_ok.mp h
      simp only [Result.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, -⟩ := h
      obtain ⟨⟨extra, hex, hexr⟩, ⟨g0, hg0, hg0r, hg0role⟩⟩ := set_role_ok _ _ _ _ _ _ _ _ _ hx
      have hb' := post_of_ok (core.cmp.PartialEq.ne.default.spec _ _ _
        (by apply WP.spec_mono (role_eq_spec _ _); intro r hr; simp [hr])) hb
    · have hro : role ≠ .Owner := hb'.mp hc
      cases a
      have hl := last_owner_ok db d s hgates
      have hd : (db.grants.deref).val = db.grants.val := by simp [alloc.vec.Vec.deref]
      rw [hd] at hex
      rw [ownerCount_eq] at ho ⊢
      simp only [hex, List.countP_append]
      have hc := count_upd db.grants.val d s role caller e hro
      rcases hl with hl | hl
      · omega
      · rw [ownerCount_eq] at hl
        have := count_as_le db.grants.val d s hu
        omega
    · have hro : role = .Owner := by simpa using mt hb'.mpr hc
      rw [ownerCount_eq]
      exact List.countP_pos_iff.mpr ⟨g0, hg0, by simp [isOwnerOn, hg0r, hg0role, hro]⟩
  · exact h.2.elim
theorem drive_keeps_an_owner (db db' : model.Db) (env : grantapi.Env) (caller d : U64) (s : model.Subject)
    (role : model.Role) (e : Option I64) (req : grantapi.Request) (rep : grantapi.Reply)
    (hq : req = .CreateGrant (.Drive d) s role e ∨ req = .SetRole (.Drive d) s role e)
    (hu : GrantsUnique db)
    (ho : 0 < ownerCount db d) (h : grantapi.transition db env caller req = ok (db', .Ok rep)) :
    0 < ownerCount db' d := by
  rcases hq with rfl | rfl
  · unfold grantapi.transition grantapi.create_grant at h
    h5i_invert h
    all_goals first | exact h.2.elim | exact set_member_role_keeps _ _ _ _ _ _ _ _ _ hu ho h
  · unfold grantapi.transition grantapi.set_role_handler at h
    h5i_invert h
    all_goals first | exact h.2.elim | exact set_member_role_keeps _ _ _ _ _ _ _ _ _ hu ho h

end oxicloud_kernel.Verified.OxicloudKeepsOwner
