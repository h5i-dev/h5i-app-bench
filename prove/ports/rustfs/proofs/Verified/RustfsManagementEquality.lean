import SpecManagement
import Verified.RustfsManagementViews
import Verified.RustfsManagementDecisions
import Verified.RustfsActionSets
import Verified.RustfsResourceSets
import Verified.RustfsConditionGroups
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsManagementEquality
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)
theorem statement_eq_ok (a c : manage.Statement) (b : Bool)
    (h : manage.statement_eq a c = ok b) : (b = true ↔ MetadataStatementEquivalent a c) := by
  unfold manage.statement_eq at h
  simp only [rustfs_kernel.Verified.RustfsForceDelete.effect_eq_ok,bind_ok] at h
  h5i_invert h
  all_goals
    try have ha := rustfs_kernel.Verified.RustfsActionSets.eq_ok _ _ _ hb1
    try have hna := rustfs_kernel.Verified.RustfsActionSets.eq_ok _ _ _ hb2
    try have hr := rustfs_kernel.Verified.RustfsResourceSets.eq_ok _ _ _ hb3
    try have hnr := rustfs_kernel.Verified.RustfsResourceSets.eq_ok _ _ _ hb4
    try have hconds := rustfs_kernel.Verified.RustfsConditionGroups.functions_eq_ok _ _ _ h
    simp_all [MetadataStatementEquivalent,deref_val]
end rustfs_kernel.Verified.RustfsManagementEquality
