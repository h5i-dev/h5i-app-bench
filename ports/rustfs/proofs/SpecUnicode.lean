import SpecKernel
open Aeneas Aeneas.Std rustfs_kernel
namespace rustfs_kernel.Spec
set_option maxRecDepth 8192
set_option maxHeartbeats 2000000
/-! Table characterizations of the pinned scalar lowercase data. -/
abbrev LowerRange := Nat × Nat × Nat × Int
/-- Inclusive bounds, optionally restricted to one parity. -/
def LowerRangeApplies (cp : Nat) (r : LowerRange) : Prop :=
  r.1 ≤ cp ∧ cp ≤ r.2.1 ∧ (r.2.2.1 = 0 ∨ cp % 2 = r.2.2.1 - 1)
instance (cp : Nat) (r : LowerRange) : Decidable (LowerRangeApplies cp r) := inferInstanceAs (Decidable (_ ∧ _ ∧ _))
def LowerRangeValue (cp : Nat) (r : LowerRange) : Nat :=
  if r.2.2.2 < 0 then cp - (-r.2.2.2).toNat else cp + r.2.2.2.toNat
def LookupLowerRanges (cp : Nat) : List LowerRange → Option (Nat × Nat × Nat)
  | [] => none
  | r :: rs => if LowerRangeApplies cp r then some (LowerRangeValue cp r,0,1) else LookupLowerRanges cp rs
def LowerRanges0 : List LowerRange :=
  [(65,90,0,32),
   (192,214,0,32),
   (216,222,0,32),
   (256,302,1,1),
   (306,310,1,1),
   (313,327,2,1),
   (330,374,1,1),
   (377,381,2,1),
   (386,388,1,1),
   (393,394,0,205)]
def LowerRanges1 : List LowerRange :=
  [(416,420,1,1),
   (433,434,0,217),
   (435,437,2,1),
   (459,475,2,1),
   (478,494,1,1),
   (498,500,1,1),
   (504,542,1,1),
   (546,562,1,1),
   (582,590,1,1),
   (880,882,1,1)]
def LowerRanges2 : List LowerRange :=
  [(904,906,0,37),
   (910,911,0,63),
   (913,929,0,32),
   (931,939,0,32),
   (984,1006,1,1),
   (1021,1023,0,-130),
   (1024,1039,0,80),
   (1040,1071,0,32),
   (1120,1152,1,1),
   (1162,1214,1,1)]
def LowerRanges3 : List LowerRange :=
  [(1217,1229,2,1),
   (1232,1326,1,1),
   (1329,1366,0,48),
   (4256,4293,0,7264),
   (5024,5103,0,38864),
   (5104,5109,0,8),
   (7312,7354,0,-3008),
   (7357,7359,0,-3008),
   (7680,7828,1,1),
   (7840,7934,1,1)]
def LowerRanges4 : List LowerRange :=
  [(7944,7951,0,-8),
   (7960,7965,0,-8),
   (7976,7983,0,-8),
   (7992,7999,0,-8),
   (8008,8013,0,-8),
   (8025,8031,2,-8),
   (8040,8047,0,-8),
   (8072,8079,0,-8),
   (8088,8095,0,-8),
   (8104,8111,0,-8)]
def LowerRanges5 : List LowerRange :=
  [(8120,8121,0,-8),
   (8122,8123,0,-74),
   (8136,8139,0,-86),
   (8152,8153,0,-8),
   (8154,8155,0,-100),
   (8168,8169,0,-8),
   (8170,8171,0,-112),
   (8184,8185,0,-128),
   (8186,8187,0,-126),
   (8544,8559,0,16)]
def LowerRanges6 : List LowerRange :=
  [(9398,9423,0,26),
   (11264,11311,0,48),
   (11367,11371,2,1),
   (11390,11391,0,-10815),
   (11392,11490,1,1),
   (11499,11501,2,1),
   (42560,42604,1,1),
   (42624,42650,1,1),
   (42786,42798,1,1),
   (42802,42862,1,1)]
def LowerRanges7 : List LowerRange :=
  [(42873,42875,2,1),
   (42878,42886,1,1),
   (42896,42898,1,1),
   (42902,42920,1,1),
   (42932,42946,1,1),
   (42951,42953,2,1),
   (42956,42970,1,1),
   (65313,65338,0,32),
   (66560,66599,0,40),
   (66736,66771,0,40)]
def LowerRanges8 : List LowerRange :=
  [(66928,66938,0,39),
   (66940,66954,0,39),
   (66956,66962,0,39),
   (66964,66965,0,39),
   (68736,68786,0,64),
   (68944,68965,0,32),
   (71840,71871,0,32),
   (93760,93791,0,32),
   (93856,93880,0,27),
   (125184,125217,0,34)]
def LowerSingletonEntries : List (Nat × Nat × Nat × Nat) :=
  [(304,105,775,2),
   (376,255,0,1),
   (385,595,0,1),
   (390,596,0,1),
   (391,392,0,1),
   (395,396,0,1),
   (398,477,0,1),
   (399,601,0,1),
   (400,603,0,1),
   (401,402,0,1),
   (403,608,0,1),
   (404,611,0,1),
   (406,617,0,1),
   (407,616,0,1),
   (408,409,0,1),
   (412,623,0,1),
   (413,626,0,1),
   (415,629,0,1),
   (422,640,0,1),
   (423,424,0,1),
   (425,643,0,1),
   (428,429,0,1),
   (430,648,0,1),
   (431,432,0,1),
   (439,658,0,1),
   (440,441,0,1),
   (444,445,0,1),
   (452,454,0,1),
   (453,454,0,1),
   (455,457,0,1),
   (456,457,0,1),
   (458,460,0,1),
   (497,499,0,1),
   (502,405,0,1),
   (503,447,0,1),
   (544,414,0,1),
   (570,11365,0,1),
   (571,572,0,1),
   (573,410,0,1),
   (574,11366,0,1),
   (577,578,0,1),
   (579,384,0,1),
   (580,649,0,1),
   (581,652,0,1),
   (886,887,0,1),
   (895,1011,0,1),
   (902,940,0,1),
   (908,972,0,1),
   (975,983,0,1),
   (1012,952,0,1),
   (1015,1016,0,1),
   (1017,1010,0,1),
   (1018,1019,0,1),
   (1216,1231,0,1),
   (4295,11559,0,1),
   (4301,11565,0,1),
   (7305,7306,0,1),
   (7838,223,0,1),
   (8124,8115,0,1),
   (8140,8131,0,1),
   (8172,8165,0,1),
   (8188,8179,0,1),
   (8486,969,0,1),
   (8490,107,0,1),
   (8491,229,0,1),
   (8498,8526,0,1),
   (8579,8580,0,1),
   (11360,11361,0,1),
   (11362,619,0,1),
   (11363,7549,0,1),
   (11364,637,0,1),
   (11373,593,0,1),
   (11374,625,0,1),
   (11375,592,0,1),
   (11376,594,0,1),
   (11378,11379,0,1),
   (11381,11382,0,1),
   (11506,11507,0,1),
   (42877,7545,0,1),
   (42891,42892,0,1),
   (42893,613,0,1),
   (42922,614,0,1),
   (42923,604,0,1),
   (42924,609,0,1),
   (42925,620,0,1),
   (42926,618,0,1),
   (42928,670,0,1),
   (42929,647,0,1),
   (42930,669,0,1),
   (42931,43859,0,1),
   (42948,42900,0,1),
   (42949,642,0,1),
   (42950,7566,0,1),
   (42955,612,0,1),
   (42972,411,0,1),
   (42997,42998,0,1)]
def LowerSingleton (cp : Nat) : Nat × Nat × Nat :=
  match cp with
  | 304 => (105,775,2)
  | 376 => (255,0,1)
  | 385 => (595,0,1)
  | 390 => (596,0,1)
  | 391 => (392,0,1)
  | 395 => (396,0,1)
  | 398 => (477,0,1)
  | 399 => (601,0,1)
  | 400 => (603,0,1)
  | 401 => (402,0,1)
  | 403 => (608,0,1)
  | 404 => (611,0,1)
  | 406 => (617,0,1)
  | 407 => (616,0,1)
  | 408 => (409,0,1)
  | 412 => (623,0,1)
  | 413 => (626,0,1)
  | 415 => (629,0,1)
  | 422 => (640,0,1)
  | 423 => (424,0,1)
  | 425 => (643,0,1)
  | 428 => (429,0,1)
  | 430 => (648,0,1)
  | 431 => (432,0,1)
  | 439 => (658,0,1)
  | 440 => (441,0,1)
  | 444 => (445,0,1)
  | 452 => (454,0,1)
  | 453 => (454,0,1)
  | 455 => (457,0,1)
  | 456 => (457,0,1)
  | 458 => (460,0,1)
  | 497 => (499,0,1)
  | 502 => (405,0,1)
  | 503 => (447,0,1)
  | 544 => (414,0,1)
  | 570 => (11365,0,1)
  | 571 => (572,0,1)
  | 573 => (410,0,1)
  | 574 => (11366,0,1)
  | 577 => (578,0,1)
  | 579 => (384,0,1)
  | 580 => (649,0,1)
  | 581 => (652,0,1)
  | 886 => (887,0,1)
  | 895 => (1011,0,1)
  | 902 => (940,0,1)
  | 908 => (972,0,1)
  | 975 => (983,0,1)
  | 1012 => (952,0,1)
  | 1015 => (1016,0,1)
  | 1017 => (1010,0,1)
  | 1018 => (1019,0,1)
  | 1216 => (1231,0,1)
  | 4295 => (11559,0,1)
  | 4301 => (11565,0,1)
  | 7305 => (7306,0,1)
  | 7838 => (223,0,1)
  | 8124 => (8115,0,1)
  | 8140 => (8131,0,1)
  | 8172 => (8165,0,1)
  | 8188 => (8179,0,1)
  | 8486 => (969,0,1)
  | 8490 => (107,0,1)
  | 8491 => (229,0,1)
  | 8498 => (8526,0,1)
  | 8579 => (8580,0,1)
  | 11360 => (11361,0,1)
  | 11362 => (619,0,1)
  | 11363 => (7549,0,1)
  | 11364 => (637,0,1)
  | 11373 => (593,0,1)
  | 11374 => (625,0,1)
  | 11375 => (592,0,1)
  | 11376 => (594,0,1)
  | 11378 => (11379,0,1)
  | 11381 => (11382,0,1)
  | 11506 => (11507,0,1)
  | 42877 => (7545,0,1)
  | 42891 => (42892,0,1)
  | 42893 => (613,0,1)
  | 42922 => (614,0,1)
  | 42923 => (604,0,1)
  | 42924 => (609,0,1)
  | 42925 => (620,0,1)
  | 42926 => (618,0,1)
  | 42928 => (670,0,1)
  | 42929 => (647,0,1)
  | 42930 => (669,0,1)
  | 42931 => (43859,0,1)
  | 42948 => (42900,0,1)
  | 42949 => (642,0,1)
  | 42950 => (7566,0,1)
  | 42955 => (612,0,1)
  | 42972 => (411,0,1)
  | 42997 => (42998,0,1)
  | _ => (cp,0,1)
def UnicodeWhitespace : List Nat :=
  [9,10,11,12,13,32,133,160,5760,8192,8193,8194,8195,8196,8197,8198,8199,8200,8201,8202,8232,8233,8239,8287,12288]
/-- All range entries, in lookup priority order. -/
def LowerRangeEntries : List LowerRange :=
  LowerRanges0 ++ LowerRanges1 ++ LowerRanges2 ++ LowerRanges3 ++ LowerRanges4 ++
  LowerRanges5 ++ LowerRanges6 ++ LowerRanges7 ++ LowerRanges8
/-- Singleton exception lookup, with identity for unlisted scalars. -/
def LookupLowerSingleton (cp : Nat) : Nat × Nat × Nat :=
  ((LowerSingletonEntries.find? (fun r => r.1 == cp)).map
    (fun r => (r.2.1,r.2.2.1,r.2.2.2))).getD (cp,0,1)
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- First applicable lowercase range; otherwise a singleton exception or identity.
The triple records the first scalar, optional second scalar, and output count.
U+0130 has the two-scalar image U+0069 U+0307. -/
def LowercaseScalar (cp : Nat) : Nat × Nat × Nat :=
  (LookupLowerRanges cp LowerRangeEntries).getD (LookupLowerSingleton cp)
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- Scalar encoding expressed as numeric UTF-8 octets. The branches also
specify the arithmetic behavior for inputs outside the Unicode scalar range. -/
def EncodeScalar (cp : Nat) : List Nat :=
  if cp < 128 then [cp % 256]
  else if cp < 2048 then
    [(192 ||| (cp >>> 6)) % 256, (128 ||| (cp &&& 63)) % 256]
  else if cp < 65536 then
    [(224 ||| (cp >>> 12)) % 256, (128 ||| ((cp >>> 6) &&& 63)) % 256,
     (128 ||| (cp &&& 63)) % 256]
  else
    [(240 ||| (cp >>> 18)) % 256, (128 ||| ((cp >>> 12) &&& 63)) % 256,
     (128 ||| ((cp >>> 6) &&& 63)) % 256, (128 ||| (cp &&& 63)) % 256]
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- Numeric decoding at a byte offset, with unavailable input represented by
zero. Successful extracted calls establish that all consumed bytes exist. -/
def DecodeScalar (bytes : List Nat) (offset : Nat) : Nat × Nat :=
  let a := (bytes[offset]?).getD 0
  let b := ((bytes[offset+1]?).getD 0) &&& 63
  let c := ((bytes[offset+2]?).getD 0) &&& 63
  let d := ((bytes[offset+3]?).getD 0) &&& 63
  if a < 128 then (a,offset+1)
  else if a < 224 then (((a &&& 31) <<< 6) ||| b,offset+2)
  else if a < 240 then (((a &&& 15) <<< 12) ||| (b <<< 6) ||| c,offset+3)
  else (((a &&& 7) <<< 18) ||| (b <<< 12) ||| (c <<< 6) ||| d,offset+4)
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- Every decoded unit consumes one to four octets. -/
theorem decodeScalar_advances (bytes : List Nat) (offset : Nat) :
    offset < (DecodeScalar bytes offset).2 := by
  unfold DecodeScalar
  dsimp only
  split_ifs <;> simp only [Prod.snd] <;> omega

/-- Lowercase byte output for one scalar, using only the mapping tables. -/
def LowerScalarBytes (cp : Nat) : List Nat :=
  let image := LowercaseScalar cp
  EncodeScalar image.1 ++ if image.2.2 = 2 then EncodeScalar image.2.1 else []

/-- Decode the input in order and concatenate each scalar's table image.
The byte offset advances according to the numeric UTF-8 decoder. -/
def LowerSuffix (bytes : List Nat) (offset : Nat) : List Nat :=
  if h : offset < bytes.length then
    let unit := DecodeScalar bytes offset
    LowerScalarBytes unit.1 ++ LowerSuffix bytes unit.2
  else []
termination_by bytes.length - offset
decreasing_by
  have := decodeScalar_advances bytes offset
  omega

def LowerBytes (bytes : List Nat) : List Nat := LowerSuffix bytes 0
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- A decoded scalar together with its start and end byte offsets. -/
abbrev ScalarSpan := Nat × Nat × Nat

/-- The input's ordered scalar spans, obtained solely from its numeric bytes. -/
def ScalarSpans (bytes : List Nat) (offset : Nat) : List ScalarSpan :=
  if h : offset < bytes.length then
    let unit := DecodeScalar bytes offset
    (offset,unit.1,unit.2) :: ScalarSpans bytes unit.2
  else []
termination_by bytes.length - offset
decreasing_by
  have := decodeScalar_advances bytes offset
  omega

/-- Non-whitespace scalars determine the retained endpoints. Interior scalars,
including whitespace, are retained byte for byte. An all-whitespace input
retains the empty byte list. -/
def TrimBytes (bytes : List Nat) : List Nat :=
  let retained := (ScalarSpans bytes 0).filter (fun span => span.2.1 ∉ UnicodeWhitespace)
  match retained.head?, retained.getLast? with
  | some first, some last => (bytes.take last.2.2).drop first.1
  | _, _ => []
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec

def ExtendBounds (limit : Nat) (bounds : Nat × Nat) (span : ScalarSpan) : Nat × Nat :=
  (if bounds.1 = limit then span.1 else bounds.1, span.2.2)

def SpanBounds (limit : Nat) (bounds : Nat × Nat) (spans : List ScalarSpan) : Nat × Nat :=
  (spans.filter (fun span => span.2.1 ∉ UnicodeWhitespace)).foldl (ExtendBounds limit) bounds

theorem bounds_fold (limit first last : Nat) (spans : List ScalarSpan)
    (h : ∀ span ∈ spans, span.1 < limit) :
    spans.foldl (ExtendBounds limit) (first,last) =
      match spans.head?,spans.getLast? with
      | some a,some b => (if first=limit then a.1 else first,b.2.2)
      | _,_ => (first,last) := by
  induction spans generalizing first last with
  | nil => rfl
  | cons a spans ih =>
    rw [List.foldl_cons, ih _ _ (by intro s hs; exact h s (by simp [hs]))]
    have ha : a.1 < limit := h a (by simp)
    cases spans with
    | nil => simp [ExtendBounds]
    | cons b rest =>
      simp only [List.head?_cons, List.getLast?_cons, ExtendBounds]
      by_cases hf : first = limit
      · simp [hf, show a.1 ≠ limit by omega]
      · simp [hf]

theorem spans_start_lt (bytes : List Nat) (offset : Nat) :
    ∀ span ∈ ScalarSpans bytes offset, span.1 < bytes.length := by
  rw [ScalarSpans]
  split
  · rename_i h
    intro span hs
    simp only [List.mem_cons] at hs
    rcases hs with rfl | hs
    · exact h
    · exact spans_start_lt bytes _ span hs
  · simp
termination_by bytes.length - offset
decreasing_by
  have := decodeScalar_advances bytes offset
  omega

theorem spanBounds_cons (limit : Nat) (bounds : Nat × Nat) (span : ScalarSpan)
    (rest : List ScalarSpan) :
    SpanBounds limit bounds (span :: rest) =
      if span.2.1 ∈ UnicodeWhitespace then SpanBounds limit bounds rest
      else SpanBounds limit (ExtendBounds limit bounds span) rest := by
  by_cases h : span.2.1 ∈ UnicodeWhitespace
  · simp [SpanBounds,h]
  · simp [SpanBounds,h]

end rustfs_kernel.Spec
