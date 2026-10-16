import SpecKernel

namespace rustfs_kernel.Spec
/-- Search backward to the nearest slash, stopping at the barrier lower bound. -/
def PreviousSlash (text : List Nat) (floor : Nat) : Nat → Nat
  | 0 => 0
  | n+1 => if n+1 ≤ floor ∨ text[n+1]?=some 47 then n+1 else PreviousSlash text floor n
/-- Parent traversal preserves the barrier prefix of relative parent components. -/
def ParentPath (root : Bool) (barrier : Nat) (out : List Nat) : List Nat × Nat :=
  if out.length > barrier then (out.take (PreviousSlash out barrier (out.length-1)),barrier)
  else if root then (out,barrier)
  else let extended := out ++ (if out=[] then [] else [47]) ++ [46,46]
       (extended,extended.length)
/-- Normalize remaining path components, retaining bytes within ordinary components. -/
def NormalizeTail (root : Bool) (barrier : Nat) (out : List Nat) : List Nat → List Nat
  | [] => out
  | 47::rest => NormalizeTail root barrier out rest
  | [46] => out
  | 46::47::rest => NormalizeTail root barrier out (47::rest)
  | [46,46] => (ParentPath root barrier out).1
  | 46::46::47::rest =>
    let parent := ParentPath root barrier out
    NormalizeTail root parent.2 parent.1 (47::rest)
  | c::rest => NormalizeTail root barrier
      (out ++ (if out.length=(if root then 1 else 0) then [] else [47]) ++
        (c::rest.takeWhile (fun x => x != 47)))
      (rest.dropWhile (fun x => x != 47))
termination_by input => input.length
decreasing_by
  all_goals simp_wf
  all_goals first | omega | exact List.length_dropWhile_le _ _
/-- Absolute paths retain their leading slash; an empty normalized path is a dot. -/
def NormalizedPath (path : List Nat) : List Nat :=
  let root := decide (path.head?=some 47)
  let out := NormalizeTail root (if root then 1 else 0) (if root then [47] else [])
    (if root then path.drop 1 else path)
  out
/-- The empty normalized path is represented by a single dot byte. -/
def CleanPath (path : List Nat) : List Nat :=
  let out := NormalizedPath path
  if out=[] then [46] else out
end rustfs_kernel.Spec
