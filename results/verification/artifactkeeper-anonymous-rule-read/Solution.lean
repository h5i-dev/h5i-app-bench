import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Solution

@[simp] theorem lit_read : lit "read" = [114, 101, 97, 100] := by unfold lit; decide +kernel
@[simp] theorem lit_anonymous : lit "anonymous" = [97, 110, 111, 110, 121, 109, 111, 117, 115] := by unfold lit; decide +kernel
@[simp] theorem lit_repository : lit "repository" = [114, 101, 112, 111, 115, 105, 116, 111, 114, 121] := by unfold lit; decide +kernel
@[simp] theorem lit_project : lit "project" = [112, 114, 111, 106, 101, 99, 116] := by unfold lit; decide +kernel

theorem bytes_eq_raw_spec (a b : Slice U8) :
    strs.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold strs.bytes_eq
  dsimp only
  split
  · rename_i hn
    have hne : a.val ≠ b.val := by
      intro he
      simp [Slice.len, he] at hn
    simp [hne]
  · rename_i hn
    have hlen : a.val.length = b.val.length := by simpa [Slice.len] using hn
    unfold strs.bytes_eq_loop
    apply loop_idx_spec _ id a.val.length
      (fun i => ∀ k, k < i.val → a.val[k]? = b.val[k]?)
      (fun r => r = decide (a.val = b.val))
    · intro i hI hi
      unfold strs.bytes_eq_loop.body
      dsimp only
      step*
      · have he : i2 = i3 := by scalar_tac
        have hbound : i.val < a.val.length := by scalar_tac
        refine ⟨?_, ?_, ?_⟩
        · intro k hk
          by_cases hki : k < i.val
          · exact hI k hki
          · have hki : k = i.val := by omega
            subst k
            simp_all
        · dsimp; omega
        · dsimp; omega
      · rename_i hend
        have he : a.val = b.val := by
          apply List.ext_getElem?
          intro k
          by_cases hk : k < i.val
          · exact hI k hk
          · have hbound : a.val.length ≤ i.val := by scalar_tac
            simp [List.getElem?_eq_none (by omega : a.val.length ≤ k),
              List.getElem?_eq_none (by omega : b.val.length ≤ k)]
        simp [he]
    · simp
    · simp

theorem nats_eq_iff (xs ys : List U8) : nats xs = nats ys ↔ xs = ys := by
  unfold nats
  induction xs generalizing ys with
  | nil => cases ys <;> simp
  | cons x xs ih => cases ys <;> simp_all [← u8_eq_iff]

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    strs.bytes_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  simpa only [nats_eq_iff] using bytes_eq_raw_spec a b

@[step] theorem any_not_read_spec (actions : Slice (alloc.vec.Vec U8)) :
    handlers.any_not_read actions ⦃ r =>
      r = actions.val.any (fun x => decide (nats x.val ≠ lit "read")) ⦄ := by
  unfold handlers.any_not_read handlers.any_not_read_loop
  h5i_search_any actions.val (fun x => decide (nats x.val ≠ lit "read"))
  all_goals refine ⟨by scalar_tac, ?_⟩
  all_goals simpa [alloc.vec.Vec.deref, nats] using b_post

theorem any_not_read_eq (actions : Slice (alloc.vec.Vec U8)) :
    handlers.any_not_read actions =
      ok (actions.val.any (fun x => decide (nats x.val ≠ lit "read"))) :=
  eq_ok_of_spec (any_not_read_spec actions)

theorem bytes_eq_eq (a b : Slice U8) :
    strs.bytes_eq a b = ok (decide (nats a.val = nats b.val)) :=
  eq_ok_of_spec (bytes_eq_spec a b)

theorem anonymous_validation (p : handlers.CreatePermissionRequest)
    (ha : nats p.principal_type.val = lit "anonymous")
    (h : handlers.validate_anonymous_rule p = ok (.Ok ())) :
    (nats p.target_type.val = lit "repository" ∨ nats p.target_type.val = lit "project") ∧
    ∀ x ∈ p.actions.val, nats x.val = lit "read" := by
  unfold handlers.validate_anonymous_rule at h
  h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars
  all_goals simp_all [bytes_eq_eq, any_not_read_eq, alloc.vec.Vec.deref,
    Array.to_slice, Array.make, nats]

theorem anonymous_principal (db : tables.Db) (p : handlers.CreatePermissionRequest)
    (ha : nats p.principal_type.val = lit "anonymous")
    (h : permission.validate_principal db p.principal_type.deref p.principal_id =
      ok (.Ok ())) : p.principal_id = 0#u64 := by
  unfold permission.validate_principal at h
  h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars
  all_goals simp_all [bytes_eq_eq, alloc.vec.Vec.deref, Array.to_slice, Array.make, nats]
  all_goals scalar_tac

theorem gates_validate (db : tables.Db) (o : trusted.Oracle) (auth : Option AuthExtension)
    (p : handlers.CreatePermissionRequest)
    (h : handlers.create_permission_gates db o auth p = ok (.Ok ())) :
    permission.validate_principal db p.principal_type.deref p.principal_id = ok (.Ok ()) ∧
    handlers.validate_anonymous_rule p = ok (.Ok ()) := by
  unfold handlers.create_permission_gates at h
  h5i_invert h
  · exact ⟨hr3, hr4⟩
  · exact ⟨hr3, hr4_1⟩

theorem actions_clone (actions : alloc.vec.Vec (alloc.vec.Vec U8)) :
    alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) actions =
      ok actions := by
  apply vec_clone_eq
  intro x
  exact u8vec_clone x

theorem anonymous_rule_read_only (db : tables.Db) (o : trusted.Oracle) (auth : Option AuthExtension)
    (p : handlers.CreatePermissionRequest) (ws : alloc.vec.Vec resolve.Write) (r : core.result.Result Unit AppError)
    (row : tables.Permission)
    (h : handlers.create_permission db o auth p = ok (ws, r)) (hw : resolve.Write.InsertPermission row ∈ ws.val)
    (ha : nats row.principal_type.val = lit "anonymous") :
    row.principal_id = 0#u64 ∧
    (nats row.target_type.val = lit "repository" ∨ nats row.target_type.val = lit "project") ∧
    ∀ x ∈ row.actions.val, nats x.val = lit "read" := by
  unfold handlers.create_permission at h
  simp only [u8vec_clone, actions_clone, bind_ok] at h
  h5i_invert h
  all_goals rcases h with ⟨rfl, rfl⟩
  all_goals try simp only [vec_new_val, List.not_mem_nil] at hw
  have hws := post_of_ok
    (alloc.vec.Vec.push_spec (alloc.vec.Vec.new resolve.Write) _
      (by simpa only [vec_new_val, List.length_nil] using usize_lt_max (n := 0) (by decide)))
    hwrites
  simp only [vec_new_val, List.nil_append] at hws
  rw [hws] at hw
  simp only [List.mem_singleton, resolve.Write.InsertPermission.injEq] at hw
  subst row
  obtain ⟨hp, hv⟩ := gates_validate db o auth p hr_1
  exact ⟨anonymous_principal db p ha hp, anonymous_validation p ha hv⟩

end artifactkeeper_kernel.Solution
