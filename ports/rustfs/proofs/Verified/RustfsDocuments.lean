import RustfsKernel
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel
open H5iAppLib
namespace rustfs_kernel.Verified.RustfsDocuments
/-- Revision changes install the supplied policy and time, preserve an existing
creation time, and increment the revision exactly once. -/
theorem update_ok (d : docdata.PolicyDoc) (p : manage.Policy) (t : docdata.Timestamp)
    (out : docdata.PolicyDoc) (h : docdata.update_at d p t = ok out) :
    out.version.val = d.version.val + 1 ∧ out.policy = p ∧
    out.update_date = some t ∧ out.create_date = d.create_date.orElse (fun _ => some t) := by
  unfold docdata.update_at at h
  h5i_invert h
  all_goals have hv := IScalar.add_equiv d.version (1#i64)
  all_goals rw [hi] at hv
  all_goals cases hc : d.create_date <;> simp_all [core.option.Option.is_none]

theorem new_ok (p : manage.Policy) (t : docdata.Timestamp) :
    ∃ out, docdata.new_at p t = ok out ∧ out.version.val = 1 ∧ out.policy = p ∧
      out.create_date = some t ∧ out.update_date = some t := by
  exact ⟨_, rfl, rfl, rfl, rfl, rfl⟩

theorem default_policy_ok (p : manage.Policy) :
    ∃ out, docdata.default_policy p = ok out ∧ out.version.val = 1 ∧ out.policy = p ∧
      out.create_date = none ∧ out.update_date = none := by
  exact ⟨_, rfl, rfl, rfl, rfl, rfl⟩

theorem default_doc_ok :
    ∃ out, docdata.default_doc = ok out ∧ out.version.val = 0 ∧
      out.policy.id.val = [] ∧ out.policy.version.val = [] ∧ out.policy.statements.val = [] ∧
      out.create_date = none ∧ out.update_date = none := by
  exact ⟨_, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
end rustfs_kernel.Verified.RustfsDocuments
