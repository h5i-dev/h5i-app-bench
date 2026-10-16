import Verified.RustfsDuplicateSelection
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsPolicyMerge
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)
theorem version_append (ps : List manage.Policy) (p : manage.Policy) :
    FirstPolicyVersion (ps ++ [p]) =
      if FirstPolicyVersion ps = [] then p.version.val else FirstPolicyVersion ps := by
  induction ps with
  | nil => by_cases hp : p.version.val = [] <;> simp [FirstPolicyVersion,hp]
  | cons q qs ih =>
    by_cases hq : q.version.val = [] <;> simp [FirstPolicyVersion,hq,ih]

theorem merge_loop_ok (ps : Slice manage.Policy) (v : alloc.vec.Vec U8)
    (ss : alloc.vec.Vec manage.Statement)
    (h : manage.merge_policies_loop ps (alloc.vec.Vec.new _) (alloc.vec.Vec.new _) 0#usize = ok (v,ss)) :
    v.val = FirstPolicyVersion ps.val ∧ ss.val = (ps.val.map (fun p => p.statements.val)).flatten := by
  unfold manage.merge_policies_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec U8 × alloc.vec.Vec manage.Statement × Usize =>
      x.2.2.val ≤ ps.val.length ∧ x.1.val = FirstPolicyVersion (ps.val.take x.2.2.val) ∧
        x.2.1.val = ((ps.val.take x.2.2.val).map (fun p => p.statements.val)).flatten)
    (fun r => r.1.val = FirstPolicyVersion ps.val ∧ r.2.val = (ps.val.map (fun p => p.statements.val)).flatten)
    (fun x => ps.val.length - x.2.2.val) ?_ _ (v,ss) ⟨by simp,by simp [FirstPolicyVersion],by simp⟩ h
  rintro ⟨ver,acc,i⟩ r ⟨hi,hv,ha⟩ hr
  dsimp only at hi hv ha ⊢
  unfold manage.merge_policies_loop.body at hr
  simp only [u8vec_clone,bind_ok] at hr
  h5i_invert hr
  · have ⟨hlt,he⟩ := slice_index_ok hp
    have hadd := add_ok_val hi3
    have he3 : i3.val = i.val + 1 := by scalar_tac
    have ht : ps.val.take i3.val = ps.val.take i.val ++ [p] := by
      rw [he3,List.take_add_one,List.getElem?_eq_getElem hlt]
      simp only [Option.toList_some,he]
    have hv2' : v2.val = if ver.val = [] then p.version.val else ver.val := by
      simp only [rustfs_kernel.Verified.RustfsValids.len_zero] at hv2
      split at hv2
      · obtain ⟨q,hq,hv2⟩ := bind_tc_eq_ok.1 hv2
        rw [hp] at hq
        cases Result.ok.inj hq
        cases Result.ok.inj hv2
        simp_all
      · cases Result.ok.inj hv2
        simp_all
    have hv3' := rustfs_kernel.Verified.RustfsStatementRetention.append_ok _ _ _ hv3
    simp only [deref_val] at hv3'
    dsimp only
    refine ⟨⟨by scalar_tac,?_,?_⟩,by scalar_tac⟩
    · rw [ht,version_append,← hv]
      exact hv2'
    · rw [ht,List.map_append,List.flatten_append]
      simpa only [List.map_cons,List.map_nil,List.flatten_cons,List.flatten_nil,List.append_nil,← ha] using hv3'
  · dsimp only
    have he : i.val = ps.val.length := by scalar_tac
    simpa only [he,List.take_length] using And.intro hv ha
theorem merge_ok (ps : Slice manage.Policy) (out : manage.Policy)
    (h : manage.merge_policies ps = ok out) :
    out.id.val = [] ∧ out.version.val = FirstPolicyVersion ps.val ∧
      DeduplicatedStatements ((ps.val.map (fun p => p.statements.val)).flatten) out.statements.val := by
  unfold manage.merge_policies at h
  obtain ⟨⟨v,ss⟩,hr,h⟩ := bind_tc_eq_ok.1 h
  have ⟨hv,hs⟩ := merge_loop_ok ps v ss hr
  change manage.drop_duplicate_statements
    { id := alloc.vec.Vec.new _, version := v, statements := ss } = ok out at h
  have ⟨hid,hver,hd⟩ := rustfs_kernel.Verified.RustfsDuplicateSelection.drop_ok _ _ h
  exact ⟨by rw [hid]; rfl, by rw [hver]; exact hv, by simpa only [hs] using hd⟩
end rustfs_kernel.Verified.RustfsPolicyMerge
