import Lean
import Properties
open Lean

/-!
Which extracted kernel definitions do the project's theorems constrain?

For every theorem in `<ns>.Properties`, collect the constants its statement
mentions, then close over the bodies of the kernel definitions they reach
(definitions in `<ns>` outside `Properties`, `Spec`, `SpecKernel`, `Verified`). Prints one
line per kernel definition: `reached <name>` or `unreached <name>`.

  lake env lean ../../../harness/lean/KernelReach.lean <ns>
-/

def isKernel (ns : Name) (n : Name) : Bool :=
  ns.isPrefixOf n && !(`Properties).isPrefixOf (n.replacePrefix ns .anonymous)
    && !(`Spec).isPrefixOf (n.replacePrefix ns .anonymous)
    && !(`SpecKernel).isPrefixOf (n.replacePrefix ns .anonymous)
    && !(`Verified).isPrefixOf (n.replacePrefix ns .anonymous)
    && !n.isInternal

partial def closure (env : Environment) (ns : Name) (todo : List Name) (seen : NameSet) : NameSet :=
  match todo with
  | [] => seen
  | n :: rest =>
    if seen.contains n then closure env ns rest seen else
    let seen := seen.insert n
    match env.find? n with
    | some ci =>
      let next := match ci with
        | .defnInfo d => d.value.getUsedConstants.toList ++ d.type.getUsedConstants.toList
        | .opaqueInfo d => d.value.getUsedConstants.toList
        | _ => ci.type.getUsedConstants.toList
      closure env ns (next.filter (fun m => isKernel ns m || !ns.isPrefixOf m) ++ rest) seen
    | none => closure env ns rest seen

def main (args : List String) : IO Unit := pure ()

elab "#kernel_reach " ns:ident : command => do
  let env ← getEnv
  let ns := ns.getId
  let props := ns ++ `Properties
  let mut seeds : List Name := []
  for (n, ci) in env.constants.toList do
    if props.isPrefixOf n then
      if let .thmInfo t := ci then seeds := seeds ++ t.type.getUsedConstants.toList
  let reached := closure env ns seeds {}
  let mut kernel : Array Name := #[]
  for (n, ci) in env.constants.toList do
    if isKernel ns n then
      if let .defnInfo _ := ci then kernel := kernel.push n
  for n in kernel.qsort Name.lt do
    IO.println s!"{if reached.contains n then "reached" else "unreached"} {n}"
