import Verified.Derived
import Verified.Auth
/-!
# Lookups over the tables
-/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec
open H5iAppLib hiding lit

namespace atuin_kernel.Verified

@[step] theorem find_session_by_token_spec (ss : alloc.vec.Vec Session) (t : Slice U8) :
    find_session_by_token ss t ⦃ o => o = ss.val.find? (fun x => decide (x.token.val = t.val)) ⦄ := by
  unfold find_session_by_token find_session_by_token_loop
  h5i_search_find ss.val (fun (x : Session) => decide (x.token.val = t.val))

@[step] theorem find_session_by_user_spec (ss : alloc.vec.Vec Session) (uid : U64) :
    find_session_by_user ss uid ⦃ o => o = ss.val.find? (fun x => decide (x.user_id = uid)) ⦄ := by
  unfold find_session_by_user find_session_by_user_loop
  h5i_search_find ss.val (fun (x : Session) => decide (x.user_id = uid))

@[step] theorem find_user_by_id_spec (us : alloc.vec.Vec User) (id : U64) :
    find_user_by_id us id ⦃ o => o = us.val.find? (fun x => decide (x.id = id)) ⦄ := by
  unfold find_user_by_id find_user_by_id_loop
  h5i_search_find us.val (fun (x : User) => decide (x.id = id))

@[step] theorem find_user_by_name_spec (us : alloc.vec.Vec User) (n : Slice U8) :
    find_user_by_name us n ⦃ o => o = us.val.find? (fun x => decide (x.username.val = n.val)) ⦄ := by
  unfold find_user_by_name find_user_by_name_loop
  h5i_search_find us.val (fun (x : User) => decide (x.username.val = n.val))

@[step] theorem verify_spec (c : Crypto) (hash pw : Slice U8) :
    verify c hash pw ⦃ b => b = decide (Verify c hash.val pw.val) ⦄ := by
  unfold verify verify_loop
  apply WP.spec_mono (H5iAppLib.loop_search c.verified.val
    (fun (v : atuin_kernel.Verified) => decide (v.hash.val = hash.val) && decide (v.password.val = pw.val)) id
    (fun _ _ => true) false _ ?step 0#usize (by simp))
  · intro r hr; simp only [id] at hr; rw [hr, H5iAppLib.searchFrom_const]
    simp [Verify]
  case step =>
    intro j hj; unfold verify_loop.body; h5i_step

@[step] theorem user_conflict_spec (us : alloc.vec.Vec User) (n e h : Slice U8) :
    user_conflict us n e h ⦃ b => b = us.val.any (fun x => decide (LowerEq x.username.val n.val) ||
      decide (LowerEq x.email.val e.val) || decide (x.password.val = h.val)) ⦄ := by
  unfold user_conflict user_conflict_loop
  h5i_search_any us.val (fun (x : User) => decide (LowerEq x.username.val n.val) ||
      decide (LowerEq x.email.val e.val) || decide (x.password.val = h.val))

@[step] theorem token_taken_spec (ss : alloc.vec.Vec Session) (t : Slice U8) :
    token_taken ss t ⦃ b => b = ss.val.any (fun x => decide (x.token.val = t.val)) ⦄ := by
  unfold token_taken token_taken_loop
  h5i_search_any ss.val (fun (x : Session) => decide (x.token.val = t.val))

@[step] theorem hash_taken_by_other_spec (us : alloc.vec.Vec User) (id : U64) (h : Slice U8) :
    hash_taken_by_other us id h ⦃ b => b = us.val.any (fun x => decide (x.id ≠ id) && decide (x.password.val = h.val)) ⦄ := by
  unfold hash_taken_by_other hash_taken_by_other_loop
  h5i_search_any us.val (fun (x : User) => decide (x.id ≠ id) && decide (x.password.val = h.val))

@[step] theorem records_fit_spec (rs : alloc.vec.Vec RecordIn) (max : U64) :
    records_fit rs max ⦃ b => b = decide (∀ r ∈ rs.val, Fits max r) ⦄ := by
  unfold records_fit records_fit_loop
  apply WP.spec_mono (H5iAppLib.loop_search rs.val
    (fun (r : RecordIn) => !(decide (r.data.val.length ≤ max.val) || decide (max.val = 0))) id
    (fun _ _ => false) true _ ?step 0#usize (by simp))
  · intro r hr; simp only [id] at hr; rw [hr, H5iAppLib.searchFrom_const]
    simp [Fits]
  case step =>
    intro j hj; unfold records_fit_loop.body; h5i_step

@[step] theorem session_user_spec (s : Snapshot) (t : Slice U8) :
    session_user s t ⦃ o => o = (match s.sessions.val.find? (fun x => decide (x.token.val = t.val)) with
      | none => none
      | some x => s.users.val.find? (fun u => decide (u.id = x.user_id))) ⦄ := by
  unfold session_user
  step*

/-- A successful lookup authenticates (the converse needs unique tokens, which `Inv` gives). -/
@[step] theorem authenticate_spec (s : Snapshot) (h : Option (alloc.vec.Vec U8)) :
    authenticate s h ⦃ r => ∀ u, r = .Ok u → Authenticated s h u ⦄ := by
  unfold authenticate
  apply WP.spec_bind (parse_authorization_spec h); intro r hr
  cases r with
  | Err e => simp
  | Ok t =>
    simp only []
    apply WP.spec_bind (session_user_spec s _); intro o ho
    simp only [vec_deref_val] at ho
    simp only [] at hr ⊢
    cases o with
    | none => simp
    | some u =>
      simp only [WP.spec_ok, core.result.Result.Ok.injEq, forall_eq']
      split at ho
      · cases ho
      · rename_i x hx
        have hx1 := List.mem_of_find?_eq_some hx
        have hx2 := List.find?_some hx
        have hu1 := List.mem_of_find?_eq_some ho.symm
        have hu2 := List.find?_some ho.symm
        exact ⟨t.val, hr, hu1, x, hx1, by simpa using hx2, by simpa using hu2⟩

end atuin_kernel.Verified
