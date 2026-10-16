import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Verified.NoraReadOnly

theorem bytes_eq_true (a b : Slice U8) (h : bytes_eq a b = ok true) : a.val = b.val := by
  unfold bytes_eq bytes_eq_loop at h
  simp only at h
  split at h
  · simp at h
  · rename_i hlen
    have hl : a.val.length = b.val.length := by simp at hlen; scalar_tac
    refine loop_true_witness _ (fun i : Usize => i.val ≤ a.val.length ∧ ∀ k < i.val, a.val[k]? = b.val[k]?)
      (fun i => a.val.length - i.val) _ ?_ _ ⟨by simp, by simp⟩ h
    rintro i r ⟨hi, hk⟩ hr
    unfold bytes_eq_loop.body at hr
    h5i_invert hr
    · simp
    · have h2 := slice_index_ok hi2
      have h3 := slice_index_ok hi3
      have hv := add_ok_val hi4
      simp only [bne_iff_ne, ne_eq, Decidable.not_not] at hc_1
      subst hc_1
      refine ⟨⟨by scalar_tac, fun k hk' => ?_⟩, by scalar_tac⟩
      by_cases hki : k < i.val
      · exact hk k hki
      · have : k = i.val := by scalar_tac
        subst this
        obtain ⟨ha, ea⟩ := h2; obtain ⟨hb, eb⟩ := h3
        rw [List.getElem?_eq_getElem ha, List.getElem?_eq_getElem hb, ea, eb]
    · simp only [forall_const]
      apply List.ext_getElem?
      intro k
      by_cases hki : k < i.val
      · exact hk k hki
      · rw [List.getElem?_eq_none (by scalar_tac), List.getElem?_eq_none (by scalar_tac)]

def RoleOk (p : OidcProvider) (s : Slice U8) (o : Option (Role × Option (alloc.vec.Vec (alloc.vec.Vec U8)))) : Prop :=
  ∀ role sc, o = some (role, sc) → role ≠ .Read →
    ∃ k, ∃ hk : k < p.role_rules.val.length,
      (∀ j (hj : j < k), glob_match (p.role_rules.val[j]).pattern.deref s = ok false) ∧
      glob_match (p.role_rules.val[k]).pattern.deref s = ok true ∧
      ((p.role_rules.val[k]).role.val = [119#u8,114#u8,105#u8,116#u8,101#u8] ∨
       (p.role_rules.val[k]).role.val = [97#u8,100#u8,109#u8,105#u8,110#u8])

theorem match_role_ok (p : OidcProvider) (s : Slice U8) (o) (h : match_role p s = ok o) : RoleOk p s o := by
  unfold match_role match_role_loop at h
  refine loop_idx_ok _ id p.role_rules.val.length
    (fun i => ∀ j (hj : j < i.val) (hj' : j < p.role_rules.val.length),
      glob_match (p.role_rules.val[j]).pattern.deref s = ok false) _ ?_ _ _ (by simp) (by simp) h
  intro i r hk hle hr
  unfold match_role_loop.body at hr
  h5i_invert hr
  all_goals try simp only [alloc.vec.Vec.index_slice_index] at hrule
  all_goals try obtain ⟨hi, rfl⟩ := vec_index_ok hrule
  all_goals first
    | (simp [RoleOk]; done)
    | skip
  case isTrue.isFalse =>
    simp only [Bool.not_eq_true] at hc_1
    subst hc_1
    have hv := add_ok_val hi2
    refine ⟨fun j hj hj' => ?_, by simp; scalar_tac, by simp; scalar_tac⟩
    by_cases hji : j < i.val
    · exact hk j hji hj'
    · have : j = i.val := by scalar_tac
      subst this
      exact hb
  all_goals
    simp only [RoleOk]
    intro role sc _ _
    refine ⟨i.val, hi, fun j hj => hk j hj _, by subst_vars; exact hb, ?_⟩
    first
      | (left
         have := bytes_eq_true _ _ (by subst_vars; exact hb2)
         simp only [lift, Result.ok.injEq] at hs4
         subst hs4
         simpa [alloc.vec.Vec.deref, array_to_slice_val, Array.make] using this)
      | (right
         have := bytes_eq_true _ _ (by subst_vars; exact hb1)
         simp only [lift, Result.ok.injEq] at hs2
         subst hs2
         simpa [alloc.vec.Vec.deref, array_to_slice_val, Array.make] using this)

theorem validate_role (p : OidcProvider) (c : Claims) (idn : OidcIdentity)
    (h : validate_claims p c = ok (.Ok idn)) :
    ∃ v : alloc.vec.Vec U8, v.val = subject c ∧ ∃ sc, match_role p v.deref = ok (some (idn.role, sc)) := by
  unfold validate_claims at h
  h5i_invert h
  all_goals
    refine ⟨subject, ?_, ?_⟩
    · cases hs : c.sub <;> simp only [hs, u8vec_clone, Result.ok.injEq] at hsubject <;>
        subst hsubject <;> simp [Spec.subject, hs]
    · rw [vec_clone_ok _ _ (fun x => u8vec_clone x)] at h
      simp at h
      first | obtain ⟨role, sc⟩ := x_2 | obtain ⟨role, sc⟩ := x_1
      have h1 := Result.ok.inj h
      injection h1 with h2
      subst h2
      exact ⟨sc, ho⟩

theorem lit_write : lit "write" = [119, 114, 105, 116, 101] := by decide +kernel
theorem lit_admin : lit "admin" = [97, 100, 109, 105, 110] := by decide +kernel

theorem first_match_of (p : OidcProvider) (c : Claims) (v : OidcIdentity)
    (hv : validate_claims p c = ok (.Ok v)) (hr : v.role ≠ .Read) :
    ∃ i, ∃ hi : i < p.role_rules.val.length, FirstMatch p (subject c) i ∧
      (nats (p.role_rules.val[i]).role.val = lit "write" ∨
       nats (p.role_rules.val[i]).role.val = lit "admin") := by
  obtain ⟨sv, hsv, sc, hm⟩ := validate_role p c v hv
  obtain ⟨k, hk, hpre, hk1, hrole⟩ := match_role_ok p _ _ hm v.role sc rfl hr
  refine ⟨k, hk, ⟨hk, fun j hj => ?_, ?_⟩, ?_⟩
  · generalize subject c = sub at *
    subst hsv
    exact ⟨_, sv.property, hpre j hj⟩
  · generalize subject c = sub at *
    subst hsv
    exact ⟨_, sv.property, hk1⟩
  · rcases hrole with h | h <;> simp [nats, h, lit_write, lit_admin]

theorem read_only_cannot_write (p : OidcProvider) (c : Claims) (r : Request) (x : Reply)
    (h : transition p c r = ok (.Ok x)) (hw : isWrite r.method) :
    ∃ i, ∃ hi : i < p.role_rules.val.length, FirstMatch p (subject c) i ∧
      (nats (p.role_rules.val[i]).role.val = lit "write" ∨
       nats (p.role_rules.val[i]).role.val = lit "admin") := by
  unfold transition at h
  h5i_invert h
  all_goals first
    | (exact first_match_of p c _ hr_1 (by
        subst_vars; intro hrole; simp [hrole, Role.can_write] at hb))
    | (exfalso; cases hm : r.method <;> simp_all [isWrite])

end nora_kernel.Verified.NoraReadOnly
