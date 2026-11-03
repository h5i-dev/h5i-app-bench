import NoraKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib nora_kernel
namespace nora_kernel.Verified.Rendering
set_option maxRecDepth 32768
set_option maxHeartbeats 200000

@[simp] private theorem byte_literal_val (n : Nat) :
    (UScalar.mk (BitVec.ofNat 8 n) : U8).val = n % 256 := by rfl

@[step] theorem append_complete (out : alloc.vec.Vec U8) (bytes : Slice U8)
    (h : out.val.length + bytes.val.length ≤ Usize.max) :
    rendering.append out bytes ⦃r => r.val = out.val ++ bytes.val⦄ := by
  unfold rendering.append alloc.vec.Vec.extend_from_slice
  have hc : Slice.clone (liftFun1 core.clone.impls.CloneU8.clone) bytes = ok bytes :=
    eq_ok_of_spec (WP.spec_mono (Slice.clone_spec (s := bytes) (clone := liftFun1 core.clone.impls.CloneU8.clone) (by intros; rfl)) (by intro r hr; exact hr.symm))
  have hh : out.length + bytes.length ≤ Usize.max := h
  simp only [dif_pos hh]
  split
  · rename_i s' hs'
    have he : s' = bytes := by simpa [hc] using hs'.symm
    simp [he]
  · rename_i eff k hs'
    simp [hc] at hs'
  · rename_i hs'
    simp [hc] at hs'

@[step] theorem byte_to_vec (s : Slice U8) :
    alloc.slice.Slice.to_vec core.clone.CloneU8 s ⦃r => r.val = s.val⦄ := by
  apply WP.spec_mono (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 s (by intros; rfl))
  intro r hr
  exact (congrArg Slice.val hr).symm

def html_byte_model (b : U8) : List U8 :=
  if b == 38#u8 then [38#u8,97#u8,109#u8,112#u8,59#u8] else
  if b == 60#u8 then [38#u8,108#u8,116#u8,59#u8] else
  if b == 62#u8 then [38#u8,103#u8,116#u8,59#u8] else
  if b == 34#u8 then [38#u8,113#u8,117#u8,111#u8,116#u8,59#u8] else
  if b == 39#u8 then [38#u8,35#u8,51#u8,57#u8,59#u8] else [b]

@[step] theorem html_byte_complete (b : U8) :
    rendering.html_byte b ⦃r => r.val = html_byte_model b⦄ := by
  unfold rendering.html_byte
  split <;> step*
  all_goals simp_all [html_byte_model, Array.make, alloc.slice.Slice.into_vec, alloc.vec.Vec.val, UScalar.eq_equiv, UScalar.ofNatCore_val_eq, byte_literal_val]

def digits : List U8 := [48#u8,49#u8,50#u8,51#u8,52#u8,53#u8,54#u8,55#u8,56#u8,57#u8,65#u8,66#u8,67#u8,68#u8,69#u8,70#u8]
def uri_allowed (b : U8) : Bool :=
  ((b >= 97#u8 && b <= 122#u8) || (b >= 65#u8 && b <= 90#u8) ||
   (b >= 48#u8 && b <= 57#u8) || b == 45#u8 || b == 95#u8 || b == 46#u8 || b == 126#u8)
def uri_byte_model (b : U8) : List U8 :=
  if uri_allowed b then [b] else [37#u8, digits[b.val / 16]!, digits[b.val % 16]!]

@[step] theorem uri_allowed_complete (b : U8) :
    rendering.uri_allowed b ⦃r => r = uri_allowed b⦄ := by
  unfold rendering.uri_allowed
  step*
  all_goals apply Bool.eq_iff_iff.mpr
  all_goals simp_all [uri_allowed, UScalar.eq_equiv]
  all_goals omega

@[step] theorem uri_byte_complete (b : U8) :
    rendering.uri_byte b ⦃r => r.val = uri_byte_model b⦄ := by
  have hd : b.val / 16 < 16 := by scalar_tac
  have hm : b.val % 16 < 16 := Nat.mod_lt _ (by decide)
  unfold rendering.uri_byte
  step*
  all_goals simp_all [uri_byte_model, digits, Array.make, alloc.slice.Slice.into_vec, alloc.vec.Vec.val]
  all_goals simp_all [List.getElem!_eq_getElem?_getD, List.getElem?_eq_getElem]


def html_model (s : List U8) : List U8 := s.flatMap html_byte_model
def uri_model (s : List U8) : List U8 := s.flatMap uri_byte_model

private theorem prefix_length (f : U8 → List U8) (s : List U8) (i : Nat) :
    ((s.take i).flatMap f).length ≤ (s.flatMap f).length := by
  have h : (s.take i).flatMap f ++ (s.drop i).flatMap f = s.flatMap f := by
    rw [← List.flatMap_append, List.take_append_drop]
  have hh := congrArg List.length h
  simp only [List.length_append] at hh
  omega

private theorem next_prefix (f : U8 → List U8) (s : List U8) (i : Nat) (h : i < s.length) :
    (s.take (i+1)).flatMap f = (s.take i).flatMap f ++ f s[i] := by
  rw [List.take_succ_eq_append_getElem h, List.flatMap_append]
  simp only [List.flatMap_singleton]


@[step] theorem html_escape_loop_complete (s : Slice U8) (out : alloc.vec.Vec U8) (i : Usize)
    (hbound : (html_model s.val).length ≤ Usize.max)
    (hi : i.val ≤ s.val.length)
    (ho : out.val = (s.val.take i.val).flatMap html_byte_model) :
    rendering.html_escape_loop s out i ⦃r => r.val = html_model s.val⦄ := by
  unfold rendering.html_escape_loop
  apply loop_idx_spec _ (fun x => x.2) s.val.length
    (fun x => x.1.val = (s.val.take x.2.val).flatMap html_byte_model) _ ?_ _ ho hi
  rintro ⟨o, j⟩ ho hj
  change j.val ≤ s.val.length at hj
  unfold rendering.html_escape_loop.body
  by_cases hlt : j.val < s.val.length
  · have hcmp : j < Slice.len s := by scalar_tac
    have hp := prefix_length html_byte_model s.val (j.val+1)
    rw [next_prefix html_byte_model s.val j.val hlt, List.length_append] at hp
    have hcap : o.val.length + (html_byte_model s.val[j.val]).length ≤ Usize.max := by
      rw [ho]
      exact le_trans hp hbound
    simp only [hcmp, if_pos]
    step*
    all_goals simp_all only [alloc.vec.Vec.deref, alloc.vec.Vec.val, Slice.from_val]
    all_goals (try exact hcap)
    all_goals (try scalar_tac)
    exact ⟨(next_prefix html_byte_model s.val j.val hlt).symm, by omega, by omega⟩
  · have hcmp : ¬j < Slice.len s := by scalar_tac
    simp only [hcmp, if_neg, WP.spec_ok]
    have he : j.val = s.val.length := by omega
    simpa [he, html_model] using ho

@[step] theorem html_escape_complete (s : Slice U8)
    (hbound : (html_model s.val).length ≤ Usize.max) :
    rendering.html_escape s ⦃r => r.val = html_model s.val⦄ := by
  unfold rendering.html_escape
  apply html_escape_loop_complete s _ _ hbound (by simp) (by simp [alloc.vec.Vec.new])

@[step] theorem encode_uri_component_loop_complete (s : Slice U8) (out : alloc.vec.Vec U8) (i : Usize)
    (hbound : (uri_model s.val).length ≤ Usize.max)
    (hi : i.val ≤ s.val.length)
    (ho : out.val = (s.val.take i.val).flatMap uri_byte_model) :
    rendering.encode_uri_component_loop s out i ⦃r => r.val = uri_model s.val⦄ := by
  unfold rendering.encode_uri_component_loop
  apply loop_idx_spec _ (fun x => x.2) s.val.length
    (fun x => x.1.val = (s.val.take x.2.val).flatMap uri_byte_model) _ ?_ _ ho hi
  rintro ⟨o, j⟩ ho hj
  change j.val ≤ s.val.length at hj
  unfold rendering.encode_uri_component_loop.body
  by_cases hlt : j.val < s.val.length
  · have hcmp : j < Slice.len s := by scalar_tac
    have hp := prefix_length uri_byte_model s.val (j.val+1)
    rw [next_prefix uri_byte_model s.val j.val hlt, List.length_append] at hp
    have hcap : o.val.length + (uri_byte_model s.val[j.val]).length ≤ Usize.max := by
      rw [ho]
      exact le_trans hp hbound
    simp only [hcmp, if_pos]
    step*
    all_goals simp_all only [alloc.vec.Vec.deref, alloc.vec.Vec.val, Slice.from_val]
    all_goals (try exact hcap)
    all_goals (try scalar_tac)
    exact ⟨(next_prefix uri_byte_model s.val j.val hlt).symm, by omega, by omega⟩
  · have hcmp : ¬j < Slice.len s := by scalar_tac
    simp only [hcmp, if_neg, WP.spec_ok]
    have he : j.val = s.val.length := by omega
    simpa [he, uri_model] using ho

@[step] theorem encode_uri_component_complete (s : Slice U8)
    (hbound : (uri_model s.val).length ≤ Usize.max) :
    rendering.encode_uri_component s ⦃r => r.val = uri_model s.val⦄ := by
  unfold rendering.encode_uri_component
  apply encode_uri_component_loop_complete s _ _ hbound (by simp) (by simp [alloc.vec.Vec.new])

-- The upstream implementation composes five replacements. State that
-- independently of the one-pass byte transducer used by the kernel.
def replace_byte (s : List U8) (key : U8) (replacement : List U8) : List U8 :=
  s.flatMap (fun b => if b == key then replacement else [b])
def replacements_model (s : List U8) : List U8 :=
  let a := replace_byte s 38#u8 [38#u8,97#u8,109#u8,112#u8,59#u8]
  let b := replace_byte a 60#u8 [38#u8,108#u8,116#u8,59#u8]
  let c := replace_byte b 62#u8 [38#u8,103#u8,116#u8,59#u8]
  let d := replace_byte c 34#u8 [38#u8,113#u8,117#u8,111#u8,116#u8,59#u8]
  replace_byte d 39#u8 [38#u8,35#u8,51#u8,57#u8,59#u8]

 theorem html_model_replacements (s : List U8) : html_model s = replacements_model s := by
  induction s with
  | nil => simp [html_model, replacements_model, replace_byte]
  | cons b bs ih =>
    simp only [html_model, List.flatMap_cons] at *
    simp only [replacements_model, replace_byte, List.flatMap_cons, List.flatMap_append]
    dsimp only [replacements_model, replace_byte] at ih
    rw [← ih]
    congr 1
    simp [html_byte_model]
    split <;> simp_all [UScalar.eq_equiv, byte_literal_val]
    all_goals split <;> simp_all [UScalar.eq_equiv, byte_literal_val]
    all_goals split <;> simp_all [UScalar.eq_equiv, byte_literal_val]
    all_goals split <;> simp_all [UScalar.eq_equiv, byte_literal_val]
    all_goals split <;> simp_all [UScalar.eq_equiv, byte_literal_val]

def action_color_model (a : List U8) : List U8 :=
  if a = [80#u8,85#u8,76#u8,76#u8] then [116#u8,101#u8,120#u8,116#u8,45#u8,98#u8,108#u8,117#u8,101#u8,45#u8,52#u8,48#u8,48#u8] else
  if a = [80#u8,85#u8,83#u8,72#u8] then [116#u8,101#u8,120#u8,116#u8,45#u8,103#u8,114#u8,101#u8,101#u8,110#u8,45#u8,52#u8,48#u8,48#u8] else
  if a = [67#u8,65#u8,67#u8,72#u8,69#u8] then [116#u8,101#u8,120#u8,116#u8,45#u8,121#u8,101#u8,108#u8,108#u8,111#u8,119#u8,45#u8,52#u8,48#u8,48#u8] else
  if a = [80#u8,82#u8,79#u8,88#u8,89#u8] then [116#u8,101#u8,120#u8,116#u8,45#u8,112#u8,117#u8,114#u8,112#u8,108#u8,101#u8,45#u8,52#u8,48#u8,48#u8] else
  [116#u8,101#u8,120#u8,116#u8,45#u8,115#u8,108#u8,97#u8,116#u8,101#u8,45#u8,52#u8,48#u8,48#u8]

@[step] theorem action_color_complete (a : Slice U8) :
    rendering.action_color a ⦃r => r.val = action_color_model a.val⦄ := by
  unfold rendering.action_color
  step*
  all_goals simp_all [action_color_model, Array.make, Slice.eq_iff]
