import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit
namespace artifactkeeper_kernel.Verified.ArtifactkeeperAdminGate

theorem lit_star : lit "*" = [42] := by
  unfold lit String.toUTF8 ByteArray.toList
  rw [ByteArray.toList.loop, ByteArray.toList.loop]
  decide

theorem lit_admin : lit "admin" = [97, 100, 109, 105, 110] := by
  unfold lit String.toUTF8 ByteArray.toList
  rw [ByteArray.toList.loop, ByteArray.toList.loop, ByteArray.toList.loop,
      ByteArray.toList.loop, ByteArray.toList.loop, ByteArray.toList.loop]
  decide

theorem index_usize_eq {α : Type} (s : Slice α) (i : Usize) (h : i.val < s.length) :
    s.index_usize i = ok s.val[i.val] :=
  H5iAppLib.eq_ok_of_spec (Slice.index_usize_spec s i h)

theorem bytes_eq_spec (a b : Slice Std.U8) (h : strs.bytes_eq a b = ok true) : a.val = b.val := by
  unfold strs.bytes_eq at h
  dsimp only at h
  split at h
  · simp at h
  · rename_i hne
    have heq : Slice.len a = Slice.len b := by
      revert hne
      cases h : (Slice.len a == Slice.len b)
      · simp [bne, h]
      · intro _; exact eq_of_beq h
    have hlen : a.val.length = b.val.length := by
      have := congrArg UScalar.val heq
      simpa [Slice.len_val] using this
    unfold strs.bytes_eq_loop at h
    have hq := loop_ok (body := fun i1 => strs.bytes_eq_loop.body a b i1)
      (Inv := fun (i : Usize) => i.val ≤ a.val.length ∧ a.val.take i.val = b.val.take i.val)
      (Q := fun (y : Bool) => y = true → a.val = b.val)
      (μ := fun (i : Usize) => a.val.length - i.val)
      (by
        intro x r ⟨hx_le, hx_take⟩ hr
        unfold strs.bytes_eq_loop.body at hr
        dsimp only at hr
        split at hr
        · rename_i h_lt
          have h_x_lt : x.val < a.val.length := by
            have := (UScalar.lt_equiv (x:=x) (y:=Slice.len a)).1 h_lt
            simpa [Slice.len_val] using this
          have h_x_lt_b : x.val < b.val.length := by omega
          rw [index_usize_eq a x (by simpa using h_x_lt),
              index_usize_eq b x (by simpa using h_x_lt_b)] at hr
          simp only [bind_ok] at hr
          split at hr
          · rename_i h_bne
            simp only [ok.injEq] at hr
            subst hr
            intro; contradiction
          · rename_i h_bne
            have h_elem_eq : a.val[x.val] = b.val[x.val] := by
              revert h_bne
              cases h_eq : (a.val[x.val] == b.val[x.val]) <;> simp [bne, h_eq]
              exact eq_of_beq h_eq
            obtain ⟨i4, hi4_add, hi4_eq⟩ := bind_tc_eq_ok.1 hr
            simp only [ok.injEq] at hi4_eq
            subst hi4_eq
            have h_max : x.val + (1#usize : Usize).val ≤ Usize.max := by
              have := a.property; scalar_tac
            have h_step_val : i4.val = x.val + 1 := by
              have hsp := (WP.spec_equiv_exists _ _).1 (Usize.add_spec (x:=x) (y:=1#usize) h_max)
              obtain ⟨y, hy, he⟩ := hsp
              rw [hi4_add, ok.injEq] at hy
              subst hy
              simpa using he
            refine ⟨⟨by omega, ?_⟩, by omega⟩
            rw [h_step_val]
            rw [List.take_succ_eq_append_getElem h_x_lt,
                List.take_succ_eq_append_getElem h_x_lt_b,
                hx_take, h_elem_eq]
        · rename_i h_nlt
          have h_ge : x.val ≥ a.val.length := by
            have h1 : ¬ (x.val < a.val.length) := by
              intro hc
              have hlt : x < Slice.len a := by
                rw [UScalar.lt_equiv]
                simpa [Slice.len_val] using hc
              contradiction
            omega
          simp only [ok.injEq] at hr
          subst hr
          intro _
          have h_x_eq : x.val = a.val.length := by omega
          have h_take := hx_take
          rw [h_x_eq, List.take_length, hlen, List.take_length] at h_take
          exact h_take)
      0#usize true
      ⟨by scalar_tac, by simp⟩
      h
    exact hq rfl

theorem any_eq_spec (list : Slice (alloc.vec.Vec Std.U8)) (s : Slice Std.U8)
    (h : strs.any_eq list s = ok true) :
    ∃ x ∈ list.val, x.val = s.val := by
  unfold strs.any_eq at h
  unfold strs.any_eq_loop at h
  have hq := loop_ok (body := fun i1 => strs.any_eq_loop.body list s i1)
    (Inv := fun (_ : Usize) => True)
    (Q := fun (y : Bool) => y = true → ∃ x ∈ list.val, x.val = s.val)
    (μ := fun (i : Usize) => list.val.length - i.val)
    (by
      intro x r _ hr
      unfold strs.any_eq_loop.body at hr
      dsimp only at hr
      split at hr
      · rename_i h_lt
        have h_x_lt : x.val < list.val.length := by
          have := (UScalar.lt_equiv (x:=x) (y:=Slice.len list)).1 h_lt
          simpa [Slice.len_val] using this
        rw [index_usize_eq list x (by simpa using h_x_lt)] at hr
        simp only [bind_ok] at hr
        obtain ⟨b, hb_bytes, hb_rest⟩ := bind_tc_eq_ok.1 hr
        split at hb_rest
        · rename_i hb_true
          simp only [ok.injEq] at hb_rest
          subst hb_rest
          intro _
          have heq_val := bytes_eq_spec (alloc.vec.Vec.deref list.val[x.val]) s
          have h_bytes : strs.bytes_eq (alloc.vec.Vec.deref list.val[x.val]) s = ok true := by
            rwa [hb_true] at hb_bytes
          have heq := heq_val h_bytes
          have h_deref : (alloc.vec.Vec.deref list.val[x.val]).val = list.val[x.val].val := by
            simp [alloc.vec.Vec.deref]
          rw [h_deref] at heq
          exact ⟨list.val[x.val], List.getElem_mem h_x_lt, heq⟩
        · rename_i hb_false
          obtain ⟨i2, hi2_add, hi2_eq⟩ := bind_tc_eq_ok.1 hb_rest
          simp only [ok.injEq] at hi2_eq
          subst hi2_eq
          have h_max : x.val + (1#usize : Usize).val ≤ Usize.max := by
            have := list.property; scalar_tac
          have h_step_val : i2.val = x.val + 1 := by
            have hsp := (WP.spec_equiv_exists _ _).1 (Usize.add_spec (x:=x) (y:=1#usize) h_max)
            obtain ⟨y, hy, he⟩ := hsp
            rw [hi2_add, ok.injEq] at hy
            subst hy
            simpa using he
          refine ⟨trivial, by omega⟩
      · simp only [ok.injEq] at hr
        subst hr
        intro; contradiction)
    0#usize true
    trivial
    h
  exact hq rfl

theorem find_byte_loop_none (s : Slice Std.U8) (b : Std.U8)
    (h_not_mem : ∀ j, (hj : j < s.val.length) → s.val[j] ≠ b)
    (i : Usize) (r : Option Usize)
    (hr : strs.find_byte_loop s b i = ok r) :
    r = none := by
  unfold strs.find_byte_loop at hr
  have hq := loop_ok (body := fun i1 => strs.find_byte_loop.body s b i1)
    (Inv := fun (_ : Usize) => True)
    (Q := fun (y : Option Usize) => y = none)
    (μ := fun (i : Usize) => s.val.length - i.val)
    (by
      intro x res _ h_step
      unfold strs.find_byte_loop.body at h_step
      dsimp only at h_step
      split at h_step
      · rename_i h_lt
        have h_x_lt : x.val < s.val.length := by
          have := (UScalar.lt_equiv (x:=x) (y:=Slice.len s)).1 h_lt
          simpa [Slice.len_val] using this
        rw [index_usize_eq s x (by simpa using h_x_lt)] at h_step
        simp only [bind_ok] at h_step
        split at h_step
        · rename_i h_eq
          have := h_not_mem x.val h_x_lt
          contradiction
        · obtain ⟨i3, hi3_add, hi3_eq⟩ := bind_tc_eq_ok.1 h_step
          simp only [ok.injEq] at hi3_eq
          subst hi3_eq
          have h_max : x.val + (1#usize : Usize).val ≤ Usize.max := by
            have := s.property; scalar_tac
          have h_step_val : i3.val = x.val + 1 := by
            have hsp := (WP.spec_equiv_exists _ _).1 (Usize.add_spec (x:=x) (y:=1#usize) h_max)
            obtain ⟨y, hy, he⟩ := hsp
            rw [hi3_add, ok.injEq] at hy
            subst hy
            simpa using he
          refine ⟨trivial, by omega⟩
      · simp only [ok.injEq] at h_step
        subst h_step
        rfl)
    i r
    trivial
    hr
  exact hq

def s_admin : Slice Std.U8 :=
  Array.to_slice (Array.make 5#usize [ 97#u8, 100#u8, 109#u8, 105#u8, 110#u8 ])

theorem s_admin_val : s_admin.val = [ 97#u8, 100#u8, 109#u8, 105#u8, 110#u8 ] := by
  simp [s_admin, Array.to_slice, Array.make]

theorem slice_admin_eq (p : [ 97#u8, 100#u8, 109#u8, 105#u8, 110#u8 ].length = (5#usize : Usize).val) :
    (Array.make 5#usize [ 97#u8, 100#u8, 109#u8, 105#u8, 110#u8 ] p).to_slice = s_admin :=
  Slice.ext _ _ rfl

theorem s_admin_no_colon (j : Nat) (hj : j < s_admin.val.length) : s_admin.val[j] ≠ 58#u8 := by
  rw [s_admin_val] at *
  revert j hj
  decide

theorem split_once_admin_none (r : Option ((alloc.vec.Vec Std.U8) × (alloc.vec.Vec Std.U8)))
    (h : strs.split_once s_admin 58#u8 = ok r) : r = none := by
  unfold strs.split_once at h
  obtain ⟨o, ho, hrest⟩ := bind_tc_eq_ok.1 h
  have ho_none : o = none := find_byte_loop_none s_admin 58#u8 s_admin_no_colon 0#usize o ho
  subst ho_none
  simp only [ok.injEq] at hrest
  exact hrest.symm

def s_star : Slice Std.U8 :=
  Array.to_slice (Array.make 1#usize [ 42#u8 ])

theorem s_star_val : s_star.val = [ 42#u8 ] := by
  simp [s_star, Array.to_slice, Array.make]

theorem deref_vec_val (v : alloc.vec.Vec (alloc.vec.Vec Std.U8)) :
    (alloc.vec.Vec.deref v).val = v.val := by
  simp [alloc.vec.Vec.deref]

theorem scopes_grant_admin (scopes : alloc.vec.Vec (alloc.vec.Vec Std.U8))
    (h : token_scope.scopes_grant_access (alloc.vec.Vec.deref scopes) s_admin = ok true) :
    Carries scopes.val (lit "admin") ∨ Carries scopes.val (lit "*") := by
  unfold token_scope.scopes_grant_access at h
  dsimp [lift] at h
  obtain ⟨s_star', hs_star, h1⟩ := bind_tc_eq_ok.1 h
  simp only [ok.injEq] at hs_star
  subst hs_star
  obtain ⟨b, hb_any, hb_rest⟩ := bind_tc_eq_ok.1 h1
  split at hb_rest
  · rename_i hb_true
    obtain ⟨b1, hb1_any, hb1_rest⟩ := bind_tc_eq_ok.1 hb_rest
    have h_star_ok : strs.any_eq (alloc.vec.Vec.deref scopes) s_star = ok true := by
      rwa [hb_true] at hb_any
    obtain ⟨x, hx_mem, hx_eq⟩ := any_eq_spec (alloc.vec.Vec.deref scopes) s_star h_star_ok
    rw [deref_vec_val] at hx_mem
    right
    refine ⟨x, hx_mem, ?_⟩
    unfold nats
    rw [hx_eq, s_star_val, lit_star]
    rfl
  · rename_i hb_false
    obtain ⟨has_admin_wildcard, h_admin, h_rest2⟩ := bind_tc_eq_ok.1 hb_rest
    obtain ⟨s_admin', hs_admin, h_admin_any⟩ := bind_tc_eq_ok.1 h_admin
    simp only [ok.injEq] at hs_admin
    subst hs_admin
    rw [slice_admin_eq] at h_admin_any
    obtain ⟨b1, hb1, h_rest3⟩ := bind_tc_eq_ok.1 h_rest2
    split at h_rest3
    · rename_i hb1_true
      have h_admin_ok : strs.any_eq (alloc.vec.Vec.deref scopes) s_admin = ok true := by
        rwa [hb1_true] at hb1
      obtain ⟨x, hx_mem, hx_eq⟩ := any_eq_spec (alloc.vec.Vec.deref scopes) s_admin h_admin_ok
      rw [deref_vec_val] at hx_mem
      left
      refine ⟨x, hx_mem, ?_⟩
      unfold nats
      rw [hx_eq, s_admin_val, lit_admin]
      rfl
    · rename_i hb1_false
      split at h_rest3
      · rename_i h_wildcard_true
        have h_admin_ok : strs.any_eq (alloc.vec.Vec.deref scopes) s_admin = ok true := by
          rwa [h_wildcard_true] at h_admin_any
        obtain ⟨x, hx_mem, hx_eq⟩ := any_eq_spec (alloc.vec.Vec.deref scopes) s_admin h_admin_ok
        rw [deref_vec_val] at hx_mem
        left
        refine ⟨x, hx_mem, ?_⟩
        unfold nats
        rw [hx_eq, s_admin_val, lit_admin]
        rfl
      · rename_i h_wildcard_false
        obtain ⟨o, ho, h_rest4⟩ := bind_tc_eq_ok.1 h_rest3
        have ho_none := split_once_admin_none o ho
        subst ho_none
        simp only [ok.injEq] at h_rest4
        contradiction

theorem has_scope_admin (self : AuthExtension)
    (h : token_scope.AuthExtension.has_scope self s_admin = ok true) :
    AdminScoped self.scopes := by
  unfold token_scope.AuthExtension.has_scope at h
  cases hsc : self.scopes with
  | none =>
    left
    rfl
  | some scopes =>
    rw [hsc] at h
    dsimp only at h
    right
    refine ⟨scopes, rfl, scopes_grant_admin scopes h⟩

theorem with_scope_gated_admin_spec (self ext : AuthExtension)
    (h : token_scope.AuthExtension.with_scope_gated_admin self = ok ext)
    (hadm : ext.is_admin = true) :
    ext.is_admin = true ∧ AdminScoped ext.scopes := by
  unfold token_scope.AuthExtension.with_scope_gated_admin at h
  dsimp [lift] at h
  split at h
  · rename_i h_self_adm
    obtain ⟨s, hs, h1⟩ := bind_tc_eq_ok.1 h
    simp only [ok.injEq] at hs
    have hs_eq : s = s_admin := by rw [← hs]; exact slice_admin_eq _
    subst hs_eq
    obtain ⟨b, hb, h2⟩ := bind_tc_eq_ok.1 h1
    simp only [ok.injEq] at h2
    subst h2
    dsimp only at hadm
    subst hadm
    have h_scoped := has_scope_admin self hb
    exact ⟨rfl, h_scoped⟩
  · simp only [ok.injEq] at h
    subst h
    contradiction

theorem respond_not_next (w : alloc.vec.Vec resolve.Write) (r : middleware.Response)
    (ws : alloc.vec.Vec resolve.Write) (auth : Option AuthExtension) (t : Bool) :
    middleware.respond w r ≠ ok (ws, .Next auth t) := by
  unfold middleware.respond
  simp

theorem from_user_spec (user : User) (ext : AuthExtension)
    (h : token_scope.from_user user = ok ext) :
    AdminScoped ext.scopes := by
  unfold token_scope.from_user at h
  obtain ⟨v, hv, h1⟩ := bind_tc_eq_ok.1 h
  obtain ⟨v1, hv1, h2⟩ := bind_tc_eq_ok.1 h1
  simp only [ok.injEq] at h2
  subst h2
  dsimp only
  left
  rfl

theorem from_claims_spec (claims : Claims) (ext : AuthExtension)
    (h : token_scope.from_claims claims = ok ext)
    (hadm : ext.is_admin = true) :
    AdminScoped ext.scopes := by
  unfold token_scope.from_claims at h
  obtain ⟨i, hi, h1⟩ := bind_tc_eq_ok.1 h
  obtain ⟨v, hv, h2⟩ := bind_tc_eq_ok.1 h1
  obtain ⟨v1, hv1, h3⟩ := bind_tc_eq_ok.1 h2
  obtain ⟨o, ho, h4⟩ := bind_tc_eq_ok.1 h3
  obtain ⟨«as», has, h5⟩ := bind_tc_eq_ok.1 h4
  exact (with_scope_gated_admin_spec _ ext h5 hadm).2

theorem validate_api_token_with_scopes_spec (oracle : trusted.Oracle) (token : Slice Std.U8)
    (ext : AuthExtension)
    (h : resolve.validate_api_token_with_scopes oracle token = ok (.Ok ext))
    (hadm : ext.is_admin = true) :
    AdminScoped ext.scopes := by
  unfold resolve.validate_api_token_with_scopes at h
  obtain ⟨r, hr, h1⟩ := bind_tc_eq_ok.1 h
  split at h1
  · rename_i v hv
    obtain ⟨ae, hae, h2⟩ := bind_tc_eq_ok.1 h1
    simp only [ok.injEq] at h2
    cases h2
    exact (with_scope_gated_admin_spec _ ext hae hadm).2
  · rename_i e he
    obtain ⟨tae, htae, h2⟩ := bind_tc_eq_ok.1 h1
    simp only [ok.injEq] at h2
    contradiction

theorem resolve_bearer_spec (oracle : trusted.Oracle) (token : Slice Std.U8)
    (ext : AuthExtension)
    (h : resolve.resolve_bearer oracle token = ok (resolve.AuthOutcome.Resolved ext))
    (hadm : ext.is_admin = true) :
    AdminScoped ext.scopes := by
  unfold resolve.resolve_bearer at h
  obtain ⟨o, ho, h1⟩ := bind_tc_eq_ok.1 h
  cases ho_cases : o with
  | none =>
    rw [ho_cases] at h1; dsimp only at h1
    obtain ⟨r, hr, h2⟩ := bind_tc_eq_ok.1 h1
    cases hr_cases : r with
    | Ok ext' =>
      rw [hr_cases] at h2; dsimp only at h2
      simp only [ok.injEq] at h2; cases h2
      rw [hr_cases] at hr
      exact validate_api_token_with_scopes_spec oracle token ext hr hadm
    | Err tae =>
      rw [hr_cases] at h2; dsimp only at h2
      cases htae : tae with
      | Invalid =>
        rw [htae] at h2; dsimp only at h2
        obtain ⟨o1, ho1, h3⟩ := bind_tc_eq_ok.1 h2
        cases ho1_cases : o1 with
        | none => rw [ho1_cases] at h3; simp only [ok.injEq] at h3; contradiction
        | some p =>
          rw [ho1_cases] at h3; dsimp only at h3
          obtain ⟨r1, hr1, h4⟩ := bind_tc_eq_ok.1 h3
          cases hr1_cases : r1 with
          | Ok user =>
            rw [hr1_cases] at h4; dsimp only at h4
            obtain ⟨ae, hae, h5⟩ := bind_tc_eq_ok.1 h4
            simp only [ok.injEq] at h5; cases h5
            exact from_user_spec user ext hae
          | Err ae =>
            rw [hr1_cases] at h4; dsimp only at h4
            cases ae <;> (simp only [ok.injEq] at h4; contradiction)
      | Overloaded =>
        rw [htae] at h2; simp only [ok.injEq] at h2; contradiction
  | some claims =>
    rw [ho_cases] at h1; dsimp only at h1
    obtain ⟨ae, hae, h2⟩ := bind_tc_eq_ok.1 h1
    simp only [ok.injEq] at h2; cases h2
    exact from_claims_spec claims ext hae hadm

theorem resolve_basic_spec (oracle : trusted.Oracle) (encoded : Slice Std.U8)
    (allow : Bool) (ext : AuthExtension)
    (h : resolve.resolve_basic oracle encoded allow = ok (resolve.AuthOutcome.Resolved ext))
    (hadm : ext.is_admin = true) :
    AdminScoped ext.scopes := by
  unfold resolve.resolve_basic at h
  obtain ⟨o, ho, h1⟩ := bind_tc_eq_ok.1 h
  cases ho_cases : o with
  | none => rw [ho_cases] at h1; simp only [ok.injEq] at h1; contradiction
  | some c =>
    rw [ho_cases] at h1; dsimp only at h1
    obtain ⟨r, hr, h2⟩ := bind_tc_eq_ok.1 h1
    cases hr_cases : r with
    | Ok user =>
      rw [hr_cases] at h2; dsimp only at h2
      obtain ⟨ae, hae, h3⟩ := bind_tc_eq_ok.1 h2
      simp only [ok.injEq] at h3; cases h3
      exact from_user_spec user ext hae
    | Err ae =>
      rw [hr_cases] at h2; dsimp only at h2
      cases hae_cases : ae with
      | ServiceUnavailable => rw [hae_cases] at h2; simp only [ok.injEq] at h2; contradiction
      | PoolTimeout => rw [hae_cases] at h2; simp only [ok.injEq] at h2; contradiction
      | Other =>
        rw [hae_cases] at h2; dsimp only at h2
        obtain ⟨o1, ho1, h3⟩ := bind_tc_eq_ok.1 h2
        cases ho1_cases : o1 with
        | none =>
          rw [ho1_cases] at h3; dsimp only at h3
          split at h3
          · obtain ⟨r1, hr1, h4⟩ := bind_tc_eq_ok.1 h3
            cases hr1_cases : r1 with
            | Ok ext' =>
              rw [hr1_cases] at h4; dsimp only at h4
              simp only [ok.injEq] at h4; cases h4
              rw [hr1_cases] at hr1
              exact validate_api_token_with_scopes_spec oracle _ ext hr1 hadm
            | Err tae =>
              rw [hr1_cases] at h4; dsimp only at h4
              cases tae <;> (simp only [ok.injEq] at h4; contradiction)
          · simp only [ok.injEq] at h3; contradiction
        | some claims =>
          rw [ho1_cases] at h3; dsimp only at h3
          obtain ⟨ae1, hae1, h4⟩ := bind_tc_eq_ok.1 h3
          simp only [ok.injEq] at h4; cases h4
          exact from_claims_spec claims ext hae1 hadm

theorem try_resolve_auth_outcome_spec (oracle : trusted.Oracle)
    (extracted : http.ExtractedToken) (allow : Bool) (ext : AuthExtension)
    (h : resolve.try_resolve_auth_outcome oracle extracted allow = ok (resolve.AuthOutcome.Resolved ext))
    (hadm : ext.is_admin = true) :
    AdminScoped ext.scopes := by
  unfold resolve.try_resolve_auth_outcome at h
  cases hext : extracted with
  | Bearer token =>
    rw [hext] at h; dsimp only at h
    exact resolve_bearer_spec oracle _ ext h hadm
  | ApiKey token =>
    rw [hext] at h; dsimp only at h
    obtain ⟨r, hr, h1⟩ := bind_tc_eq_ok.1 h
    cases hr_cases : r with
    | Ok ext' =>
      rw [hr_cases] at h1; dsimp only at h1
      simp only [ok.injEq] at h1; cases h1
      rw [hr_cases] at hr
      exact validate_api_token_with_scopes_spec oracle _ ext hr hadm
    | Err tae =>
      rw [hr_cases] at h1; dsimp only at h1
      cases tae <;> (simp only [ok.injEq] at h1; contradiction)
  | Basic encoded =>
    rw [hext] at h; dsimp only at h
    exact resolve_basic_spec oracle _ allow ext h hadm
  | None =>
    rw [hext] at h; simp only [ok.injEq] at h; contradiction
  | Invalid =>
    rw [hext] at h; simp only [ok.injEq] at h; contradiction

theorem admin_gate (db : tables.Db) (o : trusted.Oracle) (req : http.Request)
    (ws : alloc.vec.Vec resolve.Write) (auth : Option AuthExtension) (t : Bool)
    (h : middleware.admin_middleware db o req = ok (ws, .Next auth t)) :
    ∃ e, auth = some e ∧ e.is_admin = true ∧ AdminScoped e.scopes := by
  unfold middleware.admin_middleware at h
  obtain ⟨cg, hcg, h1⟩ := bind_tc_eq_ok.1 h
  cases hcg_cases : cg with
  | some refusal =>
    rw [hcg_cases] at h1; dsimp only at h1
    exact False.elim (respond_not_next _ _ _ _ _ h1)
  | none =>
    rw [hcg_cases] at h1; dsimp only at h1
    obtain ⟨extracted, hextracted, h2⟩ := bind_tc_eq_ok.1 h1
    cases hext_cases : extracted with
    | Bearer token =>
      rw [hext_cases] at h2; dsimp only at h2
      obtain ⟨ao, hao, h3⟩ := bind_tc_eq_ok.1 h2
      cases hao_cases : ao with
      | Resolved ext =>
        rw [hao_cases] at hao
        rw [hao_cases] at h3; dsimp only at h3
        split at h3
        · rename_i h_adm
          obtain ⟨b, hb, h4⟩ := bind_tc_eq_ok.1 h3
          split at h4
          · simp only [ok.injEq] at h4
            injection h4 with _ h_out
            injection h_out with h_auth _
            subst h_auth
            have h_scoped := try_resolve_auth_outcome_spec o _ false ext hao h_adm
            exact ⟨ext, rfl, h_adm, h_scoped⟩
          · obtain ⟨b1, hb1, h5⟩ := bind_tc_eq_ok.1 h4
            split at h5
            · exact False.elim (respond_not_next _ _ _ _ _ h5)
            · simp only [ok.injEq] at h5
              injection h5 with _ h_out
              injection h_out with h_auth _
              subst h_auth
              have h_scoped := try_resolve_auth_outcome_spec o _ false ext hao h_adm
              exact ⟨ext, rfl, h_adm, h_scoped⟩
        · obtain ⟨v, hv, h4⟩ := bind_tc_eq_ok.1 h3
          obtain ⟨writes, hwrites, h5⟩ := bind_tc_eq_ok.1 h4
          exact False.elim (respond_not_next _ _ _ _ _ h5)
      | NoCredential =>
        rw [hao_cases] at h3; dsimp only at h3
        exact False.elim (respond_not_next _ _ _ _ _ h3)
      | InvalidCredential =>
        rw [hao_cases] at h3; dsimp only at h3
        exact False.elim (respond_not_next _ _ _ _ _ h3)
      | Overloaded =>
        rw [hao_cases] at h3; dsimp only at h3
        exact False.elim (respond_not_next _ _ _ _ _ h3)
    | ApiKey token =>
      rw [hext_cases] at h2; dsimp only at h2
      obtain ⟨ao, hao, h3⟩ := bind_tc_eq_ok.1 h2
      cases hao_cases : ao with
      | Resolved ext =>
        rw [hao_cases] at hao
        rw [hao_cases] at h3; dsimp only at h3
        split at h3
        · rename_i h_adm
          obtain ⟨b, hb, h4⟩ := bind_tc_eq_ok.1 h3
          split at h4
          · simp only [ok.injEq] at h4
            injection h4 with _ h_out
            injection h_out with h_auth _
            subst h_auth
            have h_scoped := try_resolve_auth_outcome_spec o _ false ext hao h_adm
            exact ⟨ext, rfl, h_adm, h_scoped⟩
          · obtain ⟨b1, hb1, h5⟩ := bind_tc_eq_ok.1 h4
            split at h5
            · exact False.elim (respond_not_next _ _ _ _ _ h5)
            · simp only [ok.injEq] at h5
              injection h5 with _ h_out
              injection h_out with h_auth _
              subst h_auth
              have h_scoped := try_resolve_auth_outcome_spec o _ false ext hao h_adm
              exact ⟨ext, rfl, h_adm, h_scoped⟩
        · obtain ⟨v, hv, h4⟩ := bind_tc_eq_ok.1 h3
          obtain ⟨writes, hwrites, h5⟩ := bind_tc_eq_ok.1 h4
          exact False.elim (respond_not_next _ _ _ _ _ h5)
      | NoCredential =>
        rw [hao_cases] at h3; dsimp only at h3
        exact False.elim (respond_not_next _ _ _ _ _ h3)
      | InvalidCredential =>
        rw [hao_cases] at h3; dsimp only at h3
        exact False.elim (respond_not_next _ _ _ _ _ h3)
      | Overloaded =>
        rw [hao_cases] at h3; dsimp only at h3
        exact False.elim (respond_not_next _ _ _ _ _ h3)
    | Basic encoded =>
      rw [hext_cases] at h2; dsimp only at h2
      obtain ⟨o1, ho1, h3⟩ := bind_tc_eq_ok.1 h2
      split at h3
      · exact False.elim (respond_not_next _ _ _ _ _ h3)
      · obtain ⟨ao, hao, h4⟩ := bind_tc_eq_ok.1 h3
        cases hao_cases : ao with
        | Resolved ext =>
          rw [hao_cases] at hao
          rw [hao_cases] at h4; dsimp only at h4
          split at h4
          · rename_i h_adm
            obtain ⟨b, hb, h5⟩ := bind_tc_eq_ok.1 h4
            split at h5
            · simp only [ok.injEq] at h5
              injection h5 with _ h_out
              injection h_out with h_auth _
              subst h_auth
              have h_scoped := try_resolve_auth_outcome_spec o _ false ext hao h_adm
              exact ⟨ext, rfl, h_adm, h_scoped⟩
            · obtain ⟨b1, hb1, h6⟩ := bind_tc_eq_ok.1 h5
              split at h6
              · exact False.elim (respond_not_next _ _ _ _ _ h6)
              · simp only [ok.injEq] at h6
                injection h6 with _ h_out
                injection h_out with h_auth _
                subst h_auth
                have h_scoped := try_resolve_auth_outcome_spec o _ false ext hao h_adm
                exact ⟨ext, rfl, h_adm, h_scoped⟩
          · obtain ⟨v, hv, h5⟩ := bind_tc_eq_ok.1 h4
            obtain ⟨writes, hwrites, h6⟩ := bind_tc_eq_ok.1 h5
            exact False.elim (respond_not_next _ _ _ _ _ h6)
        | NoCredential =>
          rw [hao_cases] at h4; dsimp only at h4
          exact False.elim (respond_not_next _ _ _ _ _ h4)
        | InvalidCredential =>
          rw [hao_cases] at h4; dsimp only at h4
          exact False.elim (respond_not_next _ _ _ _ _ h4)
        | Overloaded =>
          rw [hao_cases] at h4; dsimp only at h4
          exact False.elim (respond_not_next _ _ _ _ _ h4)
    | None =>
      rw [hext_cases] at h2; dsimp only at h2
      obtain ⟨ao, hao, h3⟩ := bind_tc_eq_ok.1 h2
      cases hao_cases : ao with
      | Resolved ext =>
        rw [hao_cases] at hao
        rw [hao_cases] at h3; dsimp only at h3
        split at h3
        · rename_i h_adm
          obtain ⟨b, hb, h4⟩ := bind_tc_eq_ok.1 h3
          split at h4
          · simp only [ok.injEq] at h4
            injection h4 with _ h_out
            injection h_out with h_auth _
            subst h_auth
            have h_scoped := try_resolve_auth_outcome_spec o _ false ext hao h_adm
            exact ⟨ext, rfl, h_adm, h_scoped⟩
          · obtain ⟨b1, hb1, h5⟩ := bind_tc_eq_ok.1 h4
            split at h5
            · exact False.elim (respond_not_next _ _ _ _ _ h5)
            · simp only [ok.injEq] at h5
              injection h5 with _ h_out
              injection h_out with h_auth _
              subst h_auth
              have h_scoped := try_resolve_auth_outcome_spec o _ false ext hao h_adm
              exact ⟨ext, rfl, h_adm, h_scoped⟩
        · obtain ⟨v, hv, h4⟩ := bind_tc_eq_ok.1 h3
          obtain ⟨writes, hwrites, h5⟩ := bind_tc_eq_ok.1 h4
          exact False.elim (respond_not_next _ _ _ _ _ h5)
      | NoCredential =>
        rw [hao_cases] at h3; dsimp only at h3
        exact False.elim (respond_not_next _ _ _ _ _ h3)
      | InvalidCredential =>
        rw [hao_cases] at h3; dsimp only at h3
        exact False.elim (respond_not_next _ _ _ _ _ h3)
      | Overloaded =>
        rw [hao_cases] at h3; dsimp only at h3
        exact False.elim (respond_not_next _ _ _ _ _ h3)
    | Invalid =>
      rw [hext_cases] at h2; dsimp only at h2
      obtain ⟨ao, hao, h3⟩ := bind_tc_eq_ok.1 h2
      cases hao_cases : ao with
      | Resolved ext =>
        rw [hao_cases] at hao
        rw [hao_cases] at h3; dsimp only at h3
        split at h3
        · rename_i h_adm
          obtain ⟨b, hb, h4⟩ := bind_tc_eq_ok.1 h3
          split at h4
          · simp only [ok.injEq] at h4
            injection h4 with _ h_out
            injection h_out with h_auth _
            subst h_auth
            have h_scoped := try_resolve_auth_outcome_spec o _ false ext hao h_adm
            exact ⟨ext, rfl, h_adm, h_scoped⟩
          · obtain ⟨b1, hb1, h5⟩ := bind_tc_eq_ok.1 h4
            split at h5
            · exact False.elim (respond_not_next _ _ _ _ _ h5)
            · simp only [ok.injEq] at h5
              injection h5 with _ h_out
              injection h_out with h_auth _
              subst h_auth
              have h_scoped := try_resolve_auth_outcome_spec o _ false ext hao h_adm
              exact ⟨ext, rfl, h_adm, h_scoped⟩
        · obtain ⟨v, hv, h4⟩ := bind_tc_eq_ok.1 h3
          obtain ⟨writes, hwrites, h5⟩ := bind_tc_eq_ok.1 h4
          exact False.elim (respond_not_next _ _ _ _ _ h5)
      | NoCredential =>
        rw [hao_cases] at h3; dsimp only at h3
        exact False.elim (respond_not_next _ _ _ _ _ h3)
      | InvalidCredential =>
        rw [hao_cases] at h3; dsimp only at h3
        exact False.elim (respond_not_next _ _ _ _ _ h3)
      | Overloaded =>
        rw [hao_cases] at h3; dsimp only at h3
        exact False.elim (respond_not_next _ _ _ _ _ h3)

end artifactkeeper_kernel.Verified.ArtifactkeeperAdminGate
