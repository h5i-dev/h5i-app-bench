import Spec
open Aeneas Aeneas.Std Result synctv_kernel synctv_kernel.Spec H5iAppLib

namespace synctv_kernel.Properties

theorem creator_role_never_assignable :
    policy.validate_role_can_be_assigned perms.Role.Creator = ok (.Err .InvalidInput) := by
  simp [policy.validate_role_can_be_assigned]

end synctv_kernel.Properties
