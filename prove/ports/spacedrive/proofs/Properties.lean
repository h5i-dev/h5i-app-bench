import Verified.Archive
/-!
# Security properties of Spacedrive's archive-extraction landing

`core/src/ops/files/archive/directory.rs` `ArchiveEntry::landing(strip)` decides,
for each entry an archive names, the path it lands at beneath the extraction
destination (or `None` to reject it). These theorems are about the extracted
`archive.landing`; each holds for every entry name and `strip`, and each is
falsifiable by removing one of the four guards `components` applies.

The companion finding (FINDINGS F1) shows these segment-level guarantees do not
by themselves stop a tar symlink entry from redirecting a later write outside
the destination; that is outside `landing`'s contract and is demonstrated with
upstream's own extractor in the differential test.
-/
open Aeneas Aeneas.Std Result spacedrive_kernel spacedrive_kernel.Spec
open spacedrive_kernel.Verified

namespace spacedrive_kernel.Properties

variable {nm : Slice Std.U8} {strip : Std.U32} {kept : alloc.vec.Vec (alloc.vec.Vec Std.U8)}

/-- S: no kept segment is `..`, so an accepted entry can never climb to a
parent of the destination. Falsified by keeping `..` segments. -/
theorem landing_rejects_parent (h : archive.landing nm strip = ok (some kept)) :
    ∀ s ∈ kept.val, nats s.val ≠ dotdot :=
  fun s hs => (landing_safe h s hs).2.2.1

/-- S: no kept segment contains a NUL byte, which a path join could otherwise
reinterpret or truncate. Falsified by keeping NUL segments. -/
theorem landing_rejects_nul (h : archive.landing nm strip = ok (some kept)) :
    ∀ s ∈ kept.val, 0 ∉ nats s.val :=
  fun s hs => (landing_safe h s hs).2.2.2

/-- S: every kept segment is non-empty, so a landing path has no empty
component. Falsified by keeping empty segments. -/
theorem landing_rejects_empty (h : archive.landing nm strip = ok (some kept)) :
    ∀ s ∈ kept.val, nats s.val ≠ [] :=
  fun s hs => (landing_safe h s hs).1

/-- S: no kept segment is `.`, so a landing path does not re-enter the current
directory. Falsified by keeping `.` segments. -/
theorem landing_rejects_curdir (h : archive.landing nm strip = ok (some kept)) :
    ∀ s ∈ kept.val, nats s.val ≠ dot :=
  fun s hs => (landing_safe h s hs).2.1

/-- C: the full landing invariant these four draw on. -/
theorem landing_safe_all (h : archive.landing nm strip = ok (some kept)) :
    ∀ s ∈ kept.val, SafeSeg (nats s.val) :=
  landing_safe h

/-- C: the same safety already holds of every segment `components` keeps,
before `skip` and the non-empty-result check. -/
theorem components_safe_all {normalized : Slice Std.U8}
    {out : alloc.vec.Vec (alloc.vec.Vec Std.U8)}
    (h : archive.components normalized = ok (some out)) :
    ∀ s ∈ out.val, SafeSeg (nats s.val) :=
  components_safe h

end spacedrive_kernel.Properties
