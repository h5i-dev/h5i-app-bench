import Verified.RustfsManagementViews
import Verified.RustfsConditionCopies
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsManagementCopies
instance {T : Type} (inst : core.clone.Clone T) [CloneLaw inst] :
    CloneLaw (conddata.FuncKeyValue.Insts.CoreCloneClone inst) := ⟨by
  intro e
  simp [conddata.FuncKeyValue.Insts.CoreCloneClone.clone,
    rustfs_kernel.Verified.RustfsConditionCopies.key_clone,CloneLaw.clone_ok]⟩
theorem inner_clone {T : Type} (inst : core.clone.Clone T) [CloneLaw inst]
    (f : conddata.InnerFunc T) : conddata.InnerFunc.Insts.CoreCloneClone.clone inst f = ok f := by
  simp [conddata.InnerFunc.Insts.CoreCloneClone.clone,vec_clone_ok _ _ CloneLaw.clone_ok]
instance : CloneLaw conddata.DateFuncValue.Insts.CoreCloneClone := ⟨by
  intro f; simp [conddata.DateFuncValue.Insts.CoreCloneClone.clone,lift]⟩
instance : CloneLaw conddata.BinaryFuncValue.Insts.CoreCloneClone := ⟨by
  intro f; simp [conddata.BinaryFuncValue.Insts.CoreCloneClone.clone,vec_clone_ok _ _ CloneLaw.clone_ok]⟩
theorem data_clone (d : conddata.Data) : conddata.Data.Insts.CoreCloneClone.clone d = ok d := by
  cases d <;> simp [conddata.Data.Insts.CoreCloneClone.clone,inner_clone]
instance : CloneLaw conddata.Condition.Insts.CoreCloneClone := ⟨by
  intro c
  simp [conddata.Condition.Insts.CoreCloneClone.clone,conddata.Op.Insts.CoreCloneClone.clone,data_clone,lift]⟩
theorem functions_clone (f : conddata.Functions) : conddata.Functions.Insts.CoreCloneClone.clone f = ok f := by
  simp [conddata.Functions.Insts.CoreCloneClone.clone,vec_clone_ok _ _ CloneLaw.clone_ok]
theorem statement_clone (s : manage.Statement) : manage.Statement.Insts.CoreCloneClone.clone s = ok s := by
  simp [manage.Statement.Insts.CoreCloneClone.clone,functions_clone,
    stmts.Effect.Insts.CoreCloneClone.clone,vec_clone_ok _ _ CloneLaw.clone_ok]
end rustfs_kernel.Verified.RustfsManagementCopies
