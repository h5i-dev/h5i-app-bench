import SpecManagement
import Verified.RustfsVariableDynamic
import Verified.RustfsConditionViews
import Verified.RustfsValids
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Verified.RustfsManagementViews
instance : CloneLaw acts.Action.Insts.CoreCloneClone := ⟨by
  intro x
  simp [acts.Action.Insts.CoreCloneClone.clone,
    acts.Family.Insts.CoreCloneClone.clone,u8vec_clone]⟩
instance : CloneLaw rsrc.Resource.Insts.CoreCloneClone := ⟨by
  intro x; cases x <;> simp [
    rsrc.Resource.Insts.CoreCloneClone.clone,u8vec_clone]⟩

theorem statement_view_ok (st : manage.Statement) (out : stmts.Statement)
    (h : manage.statement_view st = ok out) :
    out.effect = st.effect ∧ out.actions = st.actions ∧ out.not_actions = st.not_actions ∧
    out.resources = st.resources ∧ out.not_resources = st.not_resources ∧
    (StatementOK out ↔ MetadataStatementOK st) := by
  unfold manage.statement_view at h
  simp only [vec_clone_ok _ _ CloneLaw.clone_ok,bind_ok] at h
  h5i_invert h
  simp [StatementOK,MetadataStatementOK]

theorem principal_clone_ok (p : stmts.Principal) :
    stmts.Principal.Insts.CoreCloneClone.clone p = ok p := by
  simp [stmts.Principal.Insts.CoreCloneClone.clone,
    vec_clone_ok _ _ CloneLaw.clone_ok]

theorem bp_view_ok (st : manage.BPStatement) (out : stmts.BPStatement)
    (h : manage.bp_statement_view st = ok out) :
    out.effect = st.effect ∧ out.principal = st.principal ∧ out.actions = st.actions ∧
    out.not_actions = st.not_actions ∧ out.resources = st.resources ∧
    out.not_resources = st.not_resources ∧ (BPStatementOK out ↔ MetadataBPStatementOK st) := by
  unfold manage.bp_statement_view at h
  simp only [principal_clone_ok,vec_clone_ok _ _ CloneLaw.clone_ok,bind_ok] at h
  h5i_invert h
  simp [BPStatementOK,MetadataBPStatementOK]
theorem default_version_ok (v : alloc.vec.Vec U8) (h : defaults.default_version = ok v) :
    nats v.val = lit "2012-10-17" := by
  unfold defaults.default_version at h
  h5i_invert h
  rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h,
    rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]
  decide +kernel

theorem version_ok (v : Slice U8) (out : core.result.Result Unit valids.ValidationError)
    (h : manage.version_is_valid v = ok out) :
    (out = .Ok () ↔ v.val = [] ∨ nats v.val = lit "2012-10-17") := by
  unfold manage.version_is_valid at h
  h5i_invert h
  all_goals try (
    have hv := default_version_ok _ hv_1
    have he := rustfs_kernel.Verified.RustfsVariableDynamic.equal_nats _ _ _ hb
    rw [rustfs_kernel.Verified.RustfsForceDelete.deref_val,hv] at he)
  all_goals simp_all [usize_ofNatCore_eq_zero]
theorem statements_ok (v : alloc.vec.Vec manage.Statement)
    (out : core.result.Result Unit valids.ValidationError)
    (h : manage.is_valid_loop v 0#usize = ok out) :
    (out = .Ok () ↔ ∀ st ∈ v.val, MetadataStatementOK st) := by
  unfold manage.is_valid_loop at h
  refine loop_ok _ (fun i : Usize => i.val ≤ v.val.length ∧
      ∀ st ∈ v.val.take i.val, MetadataStatementOK st)
    (fun o => o = .Ok () ↔ ∀ st ∈ v.val, MetadataStatementOK st)
    (fun i : Usize => v.val.length - i.val) ?_ _ out ⟨by simp,by simp⟩ h
  rintro i o ⟨hi,hx⟩ hbody
  unfold manage.is_valid_loop.body at hbody
  h5i_invert hbody
  · obtain ⟨h1,h2⟩ := vec_index_ok hst
    have h3 := rustfs_kernel.Verified.RustfsValids.statement_ok _ _ _ hr
    have hv := (statement_view_ok _ _ hs).2.2.2.2.2
    have := add_ok_val hi2
    refine ⟨⟨by scalar_tac, fun x hx' => ?_⟩, by scalar_tac⟩
    rw [show i2.val = i.val + 1 by scalar_tac,List.take_add_one,List.getElem?_eq_getElem h1] at hx'
    simp only [Option.toList_some,List.mem_append,List.mem_singleton] at hx'
    rcases hx' with hh | rfl
    · exact hx x hh
    · rw [h2]; exact hv.1 (h3.1 rfl)
  · obtain ⟨h1,h2⟩ := vec_index_ok hst
    have h3 := rustfs_kernel.Verified.RustfsValids.statement_ok _ _ _ hr
    have hv := (statement_view_ok _ _ hs).2.2.2.2.2
    simp only [reduceCtorEq,false_iff,not_forall] at h3 ⊢
    exact ⟨st, by rw [← h2]; exact List.getElem_mem h1, fun hh => h3 (hv.2 hh)⟩
  · simp only [true_iff]
    rw [List.take_of_length_le (by scalar_tac)] at hx
    exact hx
theorem bp_statements_ok (v : alloc.vec.Vec manage.BPStatement)
    (out : core.result.Result Unit valids.ValidationError)
    (h : manage.bucket_is_valid_loop v 0#usize = ok out) :
    (out = .Ok () ↔ ∀ st ∈ v.val, MetadataBPStatementOK st) := by
  unfold manage.bucket_is_valid_loop at h
  refine loop_ok _ (fun i : Usize => i.val ≤ v.val.length ∧
      ∀ st ∈ v.val.take i.val, MetadataBPStatementOK st)
    (fun o => o = .Ok () ↔ ∀ st ∈ v.val, MetadataBPStatementOK st)
    (fun i : Usize => v.val.length - i.val) ?_ _ out ⟨by simp,by simp⟩ h
  rintro i o ⟨hi,hx⟩ hbody
  unfold manage.bucket_is_valid_loop.body at hbody
  h5i_invert hbody
  · obtain ⟨h1,h2⟩ := vec_index_ok hst
    have h3 := rustfs_kernel.Verified.RustfsValids.bp_statement_ok _ _ _ hr
    have hv := (bp_view_ok _ _ hb).2.2.2.2.2.2
    have := add_ok_val hi2
    refine ⟨⟨by scalar_tac, fun x hx' => ?_⟩, by scalar_tac⟩
    rw [show i2.val = i.val + 1 by scalar_tac,List.take_add_one,List.getElem?_eq_getElem h1] at hx'
    simp only [Option.toList_some,List.mem_append,List.mem_singleton] at hx'
    rcases hx' with hh | rfl
    · exact hx x hh
    · rw [h2]; exact hv.1 (h3.1 rfl)
  · obtain ⟨h1,h2⟩ := vec_index_ok hst
    have h3 := rustfs_kernel.Verified.RustfsValids.bp_statement_ok _ _ _ hr
    have hv := (bp_view_ok _ _ hb).2.2.2.2.2.2
    simp only [reduceCtorEq,false_iff,not_forall] at h3 ⊢
    exact ⟨st, by rw [← h2]; exact List.getElem_mem h1, fun hh => h3 (hv.2 hh)⟩
  · simp only [true_iff]
    rw [List.take_of_length_le (by scalar_tac)] at hx
    exact hx
theorem policy_ok (p : manage.Policy) (out : core.result.Result Unit valids.ValidationError)
    (h : manage.is_valid p = ok out) : (out = .Ok () ↔ MetadataPolicyOK p) := by
  unfold manage.is_valid at h
  h5i_invert h
  · have hv := (version_ok _ _ hr).1 rfl
    rw [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hv
    have hs := statements_ok p.statements out h
    simpa [MetadataPolicyOK,rustfs_kernel.Verified.RustfsForceDelete.deref_val,hv] using hs
  · have hv := version_ok _ _ hr
    simp only [reduceCtorEq,false_iff] at hv
    rw [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hv
    simp only [MetadataPolicyOK,reduceCtorEq,false_iff]
    exact fun hh => hv hh.1

theorem bucket_policy_ok (p : manage.BucketPolicy) (out : core.result.Result Unit valids.ValidationError)
    (h : manage.bucket_is_valid p = ok out) : (out = .Ok () ↔ MetadataBucketPolicyOK p) := by
  unfold manage.bucket_is_valid at h
  h5i_invert h
  · have hv := (version_ok _ _ hr).1 rfl
    rw [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hv
    have hs := bp_statements_ok p.statements out h
    simpa [MetadataBucketPolicyOK,rustfs_kernel.Verified.RustfsForceDelete.deref_val,hv] using hs
  · have hv := version_ok _ _ hr
    simp only [reduceCtorEq,false_iff] at hv
    rw [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hv
    simp only [MetadataBucketPolicyOK,reduceCtorEq,false_iff]
    exact fun hh => hv hh.1
end rustfs_kernel.Verified.RustfsManagementViews
