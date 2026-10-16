import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

namespace oxicloud_kernel.Verified.OxicloudMigrationReadonly

theorem migration_readonly_blocks_mutations (db : model.Db) (now : I64) (s : model.Subject)
    (p : model.Permission) (r : model.Resource) (hp : p ≠ .Read) :
    acl.check db true now s p r = ok false := by
  cases p <;> simp_all [acl.check, acl.read_only_gate_applies,
    core.cmp.PartialEq.ne.trait_default,
    core.cmp.PartialEq.ne.default,
    model.Permission.Insts.CoreCmpPartialEqPermission,
    model.Permission.Insts.CoreCmpPartialEqPermission.eq, model.Permission.read_discriminant]

end oxicloud_kernel.Verified.OxicloudMigrationReadonly
