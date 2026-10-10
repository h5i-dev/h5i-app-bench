import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Solution

theorem bytes_eq_ok {a b : Slice U8} {r : Bool} (h : strs.bytes_eq a b = ok r) :
    (r = true ↔ a.val = b.val) := by
  unfold strs.bytes_eq at h
  h5i_invert h
  · simp only [bne_iff_ne, ne_eq] at hc
    simp only [Bool.false_eq_true, false_iff]
    intro hab; apply hc; simp [Slice.len, hab]
  · simp only [bne_iff_ne, ne_eq, not_not] at hc
    have hlen : a.val.length = b.val.length := by
      have := congrArg (·.val) hc; simpa [Slice.len] using this
    refine loop_ok _ (fun i => i.val ≤ a.val.length ∧ a.val.take i.val = b.val.take i.val)
      (fun r => r = true ↔ a.val = b.val) (fun i => a.val.length - i.val) ?_ _ _ ⟨by simp, by simp⟩ h
    intro i res ⟨hi, ht⟩ hb
    unfold strs.bytes_eq_loop.body at hb
    h5i_invert hb with hcc
    · obtain ⟨h1, rfl⟩ := slice_index_ok hi2
      obtain ⟨h2, rfl⟩ := slice_index_ok hi3
      simp only [bne_iff_ne, ne_eq] at hcc_1
      simp only [Bool.false_eq_true, false_iff]
      intro hab; apply hcc_1; simp [hab]
    · obtain ⟨h1, rfl⟩ := slice_index_ok hi2
      obtain ⟨h2, rfl⟩ := slice_index_ok hi3
      simp only [bne_iff_ne, ne_eq, not_not] at hcc_1
      have h4 : i4.val = i.val + 1 := by have := add_ok_val hi4; simpa using this
      refine ⟨⟨by omega, ?_⟩, by omega⟩
      rw [h4, List.take_add_one, List.take_add_one, ht]
      simp [List.getElem?_eq_getElem h1, List.getElem?_eq_getElem h2, hcc_1]
    · have hge : a.val.length ≤ i.val := by
        have : ¬ (i.val < a.val.length) := fun hh => hcc (by scalar_tac)
        omega
      simp only [true_iff]
      have e1 : a.val.take i.val = a.val := List.take_of_length_le (by omega)
      have e2 : b.val.take i.val = b.val := List.take_of_length_le (by omega)
      rw [← e1, ← e2, ht]

theorem find?_at {α} (l : List α) (P : α → Bool) (i : Nat) (hi : i < l.length)
    (hpre : ∀ x ∈ l.take i, P x = false) (hp : P l[i] = true) : l.find? P = some l[i] := by
  have e : l = l.take i ++ l.drop i := (List.take_append_drop i l).symm
  have : (l.take i ++ l.drop i).find? P = some l[i] := by
    rw [List.find?_append, List.find?_eq_none.2 (by simpa using hpre),
      Option.none_or, List.drop_eq_getElem_cons hi, List.find?_cons_of_pos hp]
  rwa [← e] at this

theorem lookup_repo_ok (db : tables.Db) (s : Slice U8) (id : U64) (v : Visibility)
    (h : middleware.lookup_repo db s = ok (some (id, v))) :
    ∃ x, db.repositories.val.find? (fun x => decide (x.key.val = s.val)) = some x ∧
      id = x.id ∧ v = x.visibility.getD .Private := by
  unfold middleware.lookup_repo middleware.lookup_repo_loop at h
  h5i_invert h
  refine loop_ok _ (fun i => i.val ≤ db.repositories.val.length ∧
      ∀ x ∈ db.repositories.val.take i.val, decide (x.key.val = s.val) = false)
    (fun res => ∀ id v, res = some (id, v) → ∃ x, db.repositories.val.find? (fun x => decide (x.key.val = s.val)) = some x ∧
      id = x.id ∧ v = x.visibility.getD .Private)
    (fun i => db.repositories.val.length - i.val) ?_ _ _ ⟨by simp, by simp⟩ h id v rfl
  intro i res ⟨hi, ht⟩ hb
  unfold middleware.lookup_repo_loop.body at hb
  have hlt : i < alloc.vec.Vec.len db.repositories → i.val < db.repositories.val.length := fun hh => by scalar_tac
  h5i_invert hb with hcc
  all_goals first
    | (intro id' v' he; simp at he; done)
    | skip
  · have hget := vec_index_slice_ok_get? hr
    have hlen := hlt hcc
    rw [List.getElem?_eq_getElem hlen, Option.some.injEq] at hget
    subst hget
    have hk := (bytes_eq_ok hb_1).1 hcc_1
    rw [vec_deref_val] at hk
    intro id' v' he
    simp only [Option.some.injEq, Prod.mk.injEq] at he
    obtain ⟨rfl, rfl⟩ := he
    refine ⟨_, find?_at _ _ _ hlen ht (by simpa using hk), rfl, ?_⟩
    simp [*]
  · have hget := vec_index_slice_ok_get? hr
    have hlen := hlt hcc
    rw [List.getElem?_eq_getElem hlen, Option.some.injEq] at hget
    subst hget
    have hk := (bytes_eq_ok hb_1).1 hcc_1
    rw [vec_deref_val] at hk
    intro id' v' he
    simp only [Option.some.injEq, Prod.mk.injEq] at he
    obtain ⟨rfl, rfl⟩ := he
    refine ⟨_, find?_at _ _ _ hlen ht (by simpa using hk), rfl, ?_⟩
    simp [*]
  · have hget := vec_index_slice_ok_get? hr
    have hlen := hlt hcc
    rw [List.getElem?_eq_getElem hlen, Option.some.injEq] at hget
    subst hget
    have hk : ¬ (db.repositories.val[i.val].key.val = s.val) := fun hh => hcc_1 ((bytes_eq_ok hb_1).2 (by rw [vec_deref_val]; exact hh))
    have h4 : i2.val = i.val + 1 := by have := add_ok_val hi2; simpa using this
    refine ⟨⟨by omega, ?_⟩, by omega⟩
    rw [h4, List.take_add_one, List.getElem?_eq_getElem hlen]
    intro x hx
    simp only [Option.toList_some, List.mem_append, List.mem_singleton] at hx
    rcases hx with hx | rfl
    · exact ht x hx
    · simpa using hk

theorem contains_ok {c : net.CidrRange} {a : net.IpAddr} (h : net.CidrRange.contains c a = ok true) :
    inCidr c a = true := by
  unfold net.CidrRange.contains at h
  h5i_invert h
  · simp only [lift, ok.injEq] at hi hi1
    subst hi hi1
    simp only [decide_eq_true_eq] at h
    simp only [inCidr, hc, beq_iff_eq]
    by_cases h0 : c.prefix_len = 0#u8
    · have hz : c.prefix_len.val = 0 := by simp [h0]
      rw [hz, show 32 - min 0 32 = 32 by rfl, Nat.div_eq_of_lt (by scalar_tac), Nat.div_eq_of_lt (by scalar_tac)]
    rw [if_neg h0] at hmask
    by_cases h32 : c.prefix_len ≥ 32#u8
    · rw [if_pos h32] at hmask
      have := result_ok_inj hmask; subst this
      have h32' : 32 ≤ c.prefix_len.val := by scalar_tac
      have := (u32_masked_eq_iff a_1 a core.num.U32.MAX 0 (by simp)).1 h
      rw [show 32 - min c.prefix_len.val 32 = 0 by omega]
      exact this
    · rw [if_neg h32] at hmask
      h5i_invert hmask
      have h32' : c.prefix_len.val < 32 := by scalar_tac
      have h0' : c.prefix_len.val ≠ 0 := fun hh => h0 (by scalar_tac)
      have hcast : i.val = c.prefix_len.val := by
        simp only [lift, ok.injEq] at hi; subst hi; simp
      have hi1v := sub_ok_val hi1
      have hb := post_of_ok (U32.ShiftLeft_spec core.num.U32.MAX i1 (by scalar_tac)) hmask
      have := (u32_masked_eq_iff a_1 a mask i1.val hb.2).1 h
      rw [show 32 - min c.prefix_len.val 32 = i1.val by simp at hi1v; omega]
      exact this
  · simp only [lift, ok.injEq] at hi hi1
    subst hi hi1
    simp only [decide_eq_true_eq] at h
    simp only [inCidr, hc, beq_iff_eq]
    by_cases h0 : c.prefix_len = 0#u8
    · have hz : c.prefix_len.val = 0 := by simp [h0]
      rw [hz, show 128 - min 0 128 = 128 by rfl, Nat.div_eq_of_lt (by scalar_tac), Nat.div_eq_of_lt (by scalar_tac)]
    rw [if_neg h0] at hmask
    by_cases h32 : c.prefix_len ≥ 128#u8
    · rw [if_pos h32] at hmask
      have := result_ok_inj hmask; subst this
      have h32' : 128 ≤ c.prefix_len.val := by scalar_tac
      have := (masked_eq_iff (ty := .U128) a_1 a core.num.U128.MAX 0 (u128_max_bv.trans (BitVec.shiftLeft_zero _).symm)).1 h
      rw [show 128 - min c.prefix_len.val 128 = 0 by omega]
      exact this
    · rw [if_neg h32] at hmask
      h5i_invert hmask
      have h32' : c.prefix_len.val < 128 := by scalar_tac
      have h0' : c.prefix_len.val ≠ 0 := fun hh => h0 (by scalar_tac)
      have hcast : i.val = c.prefix_len.val := by
        simp only [lift, ok.injEq] at hi; subst hi; simp
      have hi1v := sub_ok_val hi1
      have hb := post_of_ok (U128.ShiftLeft_spec core.num.U128.MAX i1 (by scalar_tac)) hmask
      have := (masked_eq_iff (ty := .U128) a_1 a mask i1.val (by rw [hb.2, u128_max_bv])).1 h
      rw [show 128 - min c.prefix_len.val 128 = i1.val by simp at hi1v; omega]
      exact this

theorem bytes_lit {v : alloc.vec.Vec U8} {n : Usize} {l : List U8} {hl} {s : Slice U8} {b : Bool}
    (hs : lift (Array.to_slice (Array.make n l hl)) = ok s) (h : strs.bytes_eq (alloc.vec.Vec.deref v) s = ok b)
    (hb : b = true) : nats v.val = nats l := by
  subst hb
  simp only [lift, ok.injEq] at hs; subst hs
  rw [← vec_deref_val, (bytes_eq_ok h).1 rfl, array_to_slice_val, Array.make_val]

theorem search_true {body : Usize → Result (ControlFlow Usize Bool)} (n : Nat) (P : Prop)
    (hstep : ∀ i r, body i = ok r → match r with
      | .done b => b = true → P
      | .cont j => i.val < n ∧ j.val = i.val + 1)
    (i0 : Usize) (h : loop body i0 = ok true) : P :=
  loop_true_witness body (fun _ => True) (fun i => n - i.val) P (fun x r _ hr => by
    have := hstep x r hr
    cases r with
    | done b => exact this
    | cont j => exact ⟨trivial, by omega⟩) i0 trivial h

set_option hygiene false in
macro "loop_step" : tactic => `(tactic| first
  | (simp; done)
  | (dsimp only; exact ⟨by scalar_tac, by h5i_ok_facts; scalar_tac⟩))

theorem is_member_ok {db : tables.Db} {u g : U64} (h : permission.is_member db u g = ok true) :
    (u, g) ∈ db.members.val := by
  unfold permission.is_member permission.is_member_loop at h
  refine search_true db.members.val.length _ ?_ _ h
  intro i r hb
  unfold permission.is_member_loop.body at hb
  h5i_invert hb with hcc
  · have hm := vec_index_slice_ok_mem hx
    obtain ⟨i2, i3⟩ := x
    simp only [Aeneas.Std.uncurry] at hb
    h5i_invert hb with hcc'
    all_goals first | loop_step | (dsimp only; intro _; subst_vars; exact hm)
  · loop_step

theorem any_eq_ok {l : Slice (alloc.vec.Vec U8)} {s : Slice U8} (h : strs.any_eq l s = ok true) :
    l.val ≠ [] := by
  unfold strs.any_eq strs.any_eq_loop at h
  refine search_true l.val.length _ ?_ _ h
  intro i r hb
  unfold strs.any_eq_loop.body at hb
  h5i_invert hb with hcc
  all_goals first | loop_step | (dsimp only; intro _; exact List.ne_nil_of_mem (slice_index_ok_mem hv))

theorem role_grant_ok {db : tables.Db} {u rid : U64}
    (h : middleware.role_grant_exists_loop db u rid 0#usize = ok true) :
    ∃ ra ∈ db.role_assignments.val, ra.user_id = u ∧
      (ra.repository_id = some rid ∨ ra.repository_id = none) := by
  unfold middleware.role_grant_exists_loop at h
  refine search_true db.role_assignments.val.length _ ?_ _ h
  intro i r hb
  unfold middleware.role_grant_exists_loop.body at hb
  h5i_invert hb with hcc
  all_goals first | loop_step | (dsimp only; intro _; refine ⟨ra, vec_index_slice_ok_mem hra, hcc_1, ?_⟩; subst hcc_2; rcases hrr : ra.repository_id with _ | r0 <;> rw [hrr] at hscoped <;> simp_all)

theorem assigned_role_ok {db : tables.Db} {u rid : U64} {perm : Slice U8}
    (h : permission.assigned_role_has db u rid perm = ok true) :
    ∃ ra ∈ db.role_assignments.val, ra.user_id = u ∧
      (ra.repository_id = some rid ∨ ra.repository_id = none) := by
  unfold permission.assigned_role_has permission.assigned_role_has_loop at h
  refine search_true db.role_assignments.val.length _ ?_ _ h
  intro i r hb
  unfold permission.assigned_role_has_loop.body at hb
  h5i_invert hb with hcc
  all_goals first | loop_step | (dsimp only; intro _; refine ⟨ra, vec_index_slice_ok_mem hra, hcc_1, ?_⟩; subst hcc_2; rcases hrr : ra.repository_id with _ | r0 <;> rw [hrr] at hscoped <;> simp_all)

theorem any_contains_ok {cs : Slice net.CidrRange} {a : net.IpAddr} (h : net.any_contains cs a = ok true) :
    ∃ c ∈ cs.val, inCidr c a = true := by
  unfold net.any_contains net.any_contains_loop at h
  refine search_true cs.val.length _ ?_ _ h
  intro i r hb
  unfold net.any_contains_loop.body at hb
  h5i_invert hb with hcc
  all_goals first | loop_step | (dsimp only; intro _; exact ⟨cr, slice_index_ok_mem hcr, contains_ok (hcc_1 ▸ hb_1)⟩)

theorem ip_condition_ok {p : tables.Permission} {ip : Option net.IpAddr}
    (h : permission.ip_condition p ip = ok true) : IpOk p ip := by
  unfold permission.ip_condition at h
  h5i_invert h
  · exact Or.inl hc
  · obtain ⟨c, hc', hin⟩ := any_contains_ok h
    rw [vec_deref_val] at hc'
    exact Or.inr ⟨cidrs, ip, hc, rfl, c, hc', hin⟩

theorem project_of_ok {db : tables.Db} {rid : U64} {o : Option U64}
    (h : permission.project_of db rid = ok o) :
    (db.repositories.val.find? (fun r => r.id = rid)).bind (·.project_id) = o := by
  unfold permission.project_of permission.project_of_loop at h
  refine loop_ok _ (fun i => i.val ≤ db.repositories.val.length ∧
      ∀ x ∈ db.repositories.val.take i.val, decide (x.id = rid) = false)
    (fun res => (db.repositories.val.find? (fun r => r.id = rid)).bind (·.project_id) = res)
    (fun i => db.repositories.val.length - i.val) ?_ _ _ ⟨by simp, by simp⟩ h
  intro i res ⟨hi, ht⟩ hb
  unfold permission.project_of_loop.body at hb
  have hlt : i < alloc.vec.Vec.len db.repositories → i.val < db.repositories.val.length := fun hh => by scalar_tac
  h5i_invert hb with hcc
  · have hget := vec_index_slice_ok_get? hr
    have hlen := hlt hcc
    rw [List.getElem?_eq_getElem hlen, Option.some.injEq] at hget
    subst hget
    dsimp only
    rw [find?_at _ _ _ hlen ht (by simpa using hcc_1)]
    rfl
  · have hget := vec_index_slice_ok_get? hr
    have hlen := hlt hcc
    rw [List.getElem?_eq_getElem hlen, Option.some.injEq] at hget
    subst hget
    have h4 : i2.val = i.val + 1 := by have := add_ok_val hi2; simpa using this
    refine ⟨⟨by omega, ?_⟩, by omega⟩
    rw [h4, List.take_add_one, List.getElem?_eq_getElem hlen]
    intro x hx
    simp only [Option.toList_some, List.mem_append, List.mem_singleton] at hx
    rcases hx with hx | rfl
    · exact ht x hx
    · simpa using hcc_1
  · have hge : db.repositories.val.length ≤ i.val := by
      have : ¬ (i.val < db.repositories.val.length) := fun hh => hcc (by scalar_tac)
      omega
    rw [List.take_of_length_le hge] at ht
    dsimp only
    rw [List.find?_eq_none.2 (by simpa using ht)]
    rfl

theorem project_is_ok {db : tables.Db} {rid tid : U64} (h : permission.project_is db rid tid = ok true) :
    ProjectOf db rid tid := by
  unfold permission.project_is at h
  h5i_invert h
  have := project_of_ok ho
  unfold ProjectOf
  rw [this]
  simp_all
theorem principal_matches_ok {db : tables.Db} {p : tables.Permission} {u : U64}
    (h : permission.principal_matches db p u = ok true) : PrincipalMatches db p u := by
  unfold permission.principal_matches at h
  h5i_invert h
  · exact Or.inl ⟨Or.inl ((bytes_lit hs1 hb hc).trans (by decide +kernel)), hc_1⟩
  · exact Or.inr ⟨(bytes_lit hs3 hb1 hc_2).trans (by decide +kernel), is_member_ok h⟩
  · exact Or.inl ⟨Or.inr ((bytes_lit hs3 hb1 hc_1).trans (by decide +kernel)), hc_2⟩
  · exact Or.inr ⟨(bytes_lit hs3_1 hb1_1 hc_3).trans (by decide +kernel), is_member_ok h⟩
  · exact Or.inr ⟨(bytes_lit hs3_1 hb1_1 hc_2).trans (by decide +kernel), is_member_ok h⟩

theorem repo_target_matches_ok {db : tables.Db} {p : tables.Permission} {rid : U64}
    (h : permission.repo_target_matches db p rid = ok true) : OnRepo db p rid := by
  unfold permission.repo_target_matches at h
  h5i_invert h
  · exact Or.inl ⟨(bytes_lit hs1 hb hc).trans (by decide +kernel), hc_1⟩
  · exact Or.inr ⟨(bytes_lit hs3 hb1 hc_2).trans (by decide +kernel), project_is_ok h⟩
  · exact Or.inr ⟨(bytes_lit hs3 hb1 hc_1).trans (by decide +kernel), project_is_ok h⟩

theorem target_matches_ok {db : tables.Db} {p : tables.Permission} {rid : U64} {tt : Slice U8} {hl}
    (hs : lift (Array.to_slice (Array.make 10#usize
        [114#u8, 101#u8, 112#u8, 111#u8, 115#u8, 105#u8, 116#u8, 111#u8, 114#u8, 121#u8] hl)) = ok tt)
    (h : permission.target_matches db p tt rid = ok true) : OnRepo db p rid := by
  unfold permission.target_matches at h
  h5i_invert h
  · exact Or.inl ⟨(bytes_lit hs hb hc).trans (by decide +kernel), hc_1⟩
  · exact Or.inr ⟨(bytes_lit hs3 hb2 hc_3).trans (by decide +kernel), project_is_ok h⟩
  · exact Or.inr ⟨(bytes_lit hs3 hb2 hc_2).trans (by decide +kernel), project_is_ok h⟩

theorem applicable_ok {db : tables.Db} {p : tables.Permission} {ip : Option net.IpAddr} {u rid : U64}
    (h : permission.applicable db p ip u rid = ok true) :
    PrincipalMatches db p u ∧ OnRepo db p rid ∧ IpOk p ip := by
  unfold permission.applicable at h
  h5i_invert h
  exact ⟨principal_matches_ok (hc ▸ hb), repo_target_matches_ok (hc_1 ▸ hb1), ip_condition_ok h⟩

theorem any_applicable_ok {db : tables.Db} {ip : Option net.IpAddr} {u rid : U64}
    (h : permission.any_applicable db ip u rid = ok true) : ∃ p, Applicable db ip u rid p := by
  unfold permission.any_applicable permission.any_applicable_loop at h
  refine search_true db.permissions.val.length _ ?_ _ h
  intro i r hb
  unfold permission.any_applicable_loop.body at hb
  h5i_invert hb with hcc
  all_goals first | loop_step | (dsimp only; intro _; exact ⟨p, vec_index_slice_ok_mem hp, applicable_ok (hcc_1 ▸ hb_1)⟩)

theorem check_repository_action_ok {db : tables.Db} {ip : Option net.IpAddr} {u rid : U64} {act : Slice U8}
    (h : permission.check_repository_action db ip u rid act false = ok (.Ok true)) :
    HasGrant db ip u rid := by
  unfold permission.check_repository_action at h
  h5i_invert h
  · obtain ⟨ra, hm, hu, hr⟩ := assigned_role_ok (hc_1 ▸ howner)
    exact Or.inl ⟨ra, hm, hu, hr⟩
  · by_cases hb1' : b1 = true
    · exact Or.inr (any_applicable_ok (hb1' ▸ hb1))
    · rw [if_neg hb1'] at hdecided
      h5i_invert hdecided
      · obtain ⟨ra, hm, hu, hr⟩ := assigned_role_ok (hc_2 ▸ hb2)
        exact Or.inl ⟨ra, hm, hu, hr⟩
      · obtain ⟨ra, hm, hu, hr⟩ := assigned_role_ok hdecided
        exact Or.inl ⟨ra, hm, hu, hr⟩

theorem query_actions_ok {db : tables.Db} {ip : Option net.IpAddr} {u rid : U64} {tt : Slice U8} {hl}
    (hs : lift (Array.to_slice (Array.make 10#usize
        [114#u8, 101#u8, 112#u8, 111#u8, 115#u8, 105#u8, 116#u8, 111#u8, 114#u8, 121#u8] hl)) = ok tt)
    {res : alloc.vec.Vec (alloc.vec.Vec U8)}
    (h : permission.query_actions db ip u tt rid = ok (.Ok res)) (hne : res.val ≠ []) :
    ∃ p, Applicable db ip u rid p := by
  unfold permission.query_actions permission.query_actions_loop at h
  h5i_invert h
  refine loop_ok _ (fun (x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize) =>
      x.2.val ≤ db.permissions.val.length ∧ (x.1.val ≠ [] → ∃ p, Applicable db ip u rid p))
    (fun (res : alloc.vec.Vec (alloc.vec.Vec U8)) => res.val ≠ [] → ∃ p, Applicable db ip u rid p)
    (fun x => db.permissions.val.length - x.2.val) ?_ _ _ ⟨by simp, by simp⟩ hout hne
  rintro ⟨out, i⟩ r ⟨hi, hinv⟩ hb
  unfold permission.query_actions_loop.body at hb
  h5i_invert hb with hcc
  · dsimp only at hi hinv ⊢
    have h4 : i2.val = i.val + 1 := by h5i_ok_facts; scalar_tac
    have hlt : i.val < db.permissions.val.length := by scalar_tac
    refine ⟨⟨by omega, ?_⟩, by omega⟩
    intro hne'
    have hpm := vec_index_slice_ok_mem hp
    by_cases hb1' : b_1 = true
    · rw [if_pos hb1'] at hout1
      h5i_invert hout1 with hq
      · exact ⟨p, hpm, principal_matches_ok (hb1' ▸ hb_1), target_matches_ok hs (hq ▸ hb1),
          ip_condition_ok (hq_1 ▸ hb2)⟩
      all_goals exact hinv hne'
    · rw [if_neg hb1'] at hout1
      have := result_ok_inj hout1; subst this; exact hinv hne'
  · exact hinv

theorem check_permission_ok {db : tables.Db} {ip : Option net.IpAddr} {u rid : U64} {tt act : Slice U8} {hl}
    (hs : lift (Array.to_slice (Array.make 10#usize
        [114#u8, 101#u8, 112#u8, 111#u8, 115#u8, 105#u8, 116#u8, 111#u8, 114#u8, 121#u8] hl)) = ok tt)
    (h : permission.check_permission db ip u tt rid act false = ok (.Ok true)) :
    ∃ p, Applicable db ip u rid p := by
  unfold permission.check_permission at h
  h5i_invert h
  exact query_actions_ok hs hr (by have := any_eq_ok hb; rwa [vec_deref_val] at this)

theorem unwrap_false_ok {E : Type} {r : core.result.Result Bool E} (h : middleware.unwrap_false r = ok true) :
    r = .Ok true := by
  unfold middleware.unwrap_false at h
  h5i_invert h
  all_goals simp_all

theorem auth_read_private (s : Slice U8) : paths.authenticated_read_satisfies_acl .Private s = ok false := by
  simp [paths.authenticated_read_satisfies_acl, Visibility.allows_authenticated_read]

theorem perm_arm_grant (db : tables.Db) (ip : Option net.IpAddr) (ext : AuthExtension) (rid : U64)
    (req : http.Request) (w nmp : Bool)
    (h : middleware.permission_arm db ip ext rid .Private req w nmp = ok none) :
    HasGrant db ip ext.user_id rid := by
  unfold middleware.permission_arm at h
  h5i_invert h
  all_goals subst_vars
  all_goals try (rw [auth_read_private] at hb; simp at hb; done)
  all_goals try (simp [Visibility.allows_authenticated_read] at hb; done)
  all_goals try (exact check_repository_action_ok hr)
  all_goals try (unfold middleware.role_grant_exists at hr1; h5i_invert hr1
                 exact Or.inl (role_grant_ok (by assumption)))
  all_goals
    by_cases hb1' : b1 = true
    · subst hb1'; exact Or.inr (check_permission_ok hs2 (unwrap_false_ok hb1 ▸ hr1))
    · rw [if_neg hb1'] at hallowed
      h5i_invert hallowed
      all_goals subst_vars
      all_goals first
        | exact Or.inr (check_permission_ok hs4 (unwrap_false_ok hb2 ▸ hr2))
        | exact check_repository_action_ok (unwrap_false_ok hallowed ▸ hr3)

theorem allows_anon_private : Visibility.allows_anonymous_read .Private = ok false := rfl
theorem should_allow_private (b : Bool) : paths.should_allow_repo_access .Private b = ok b := by
  simp [paths.should_allow_repo_access, Visibility.allows_anonymous_read]
theorem public_read_private (s : Slice U8) : paths.public_read_satisfies_acl .Private s = ok false := by
  simp [paths.public_read_satisfies_acl, Visibility.allows_anonymous_read]

set_option hygiene false in
macro "close_leaf" : tactic => `(tactic| first
  | exact h.2.elim
  | (simp only [middleware.Outcome.Next.injEq, reduceCtorEq, false_and, and_false] at h; done)
  | (simp only [middleware.Outcome.Next.injEq, Option.some.injEq] at h
     obtain ⟨-, rfl, -⟩ := h
     first
       | exact perm_arm_grant _ _ _ _ _ _ _ (by assumption)
       | (have hadm : ext.is_admin = true := by assumption
          rw [ha] at hadm; cases hadm)))

set_option maxHeartbeats 4000000 in
theorem private_needs_grant (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (e : AuthExtension) (t : Bool)
    (r : tables.Repository)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next (some e) t))
    (ha : e.is_admin = false) (hr : RepoOf db req r)
    (hv : r.visibility ≠ some .Public ∧ r.visibility ≠ some .Internal) :
    HasGrant db ip e.user_id r.id := by
  unfold middleware.repo_visibility_middleware middleware.respond at h
  h5i_invert h
  by_cases hk : repo_key.len = 0#usize
  · rw [if_pos hk] at h; simp at h
  rw [if_neg hk] at h
  h5i_invert h
  · exact h.2.elim
  obtain ⟨repo_id, vis⟩ := r_1
  obtain ⟨x, hx, hid, hvis⟩ := lookup_repo_ok _ _ _ _ ho_1
  obtain ⟨key, hkey, hfind⟩ := hr
  rw [hrepo_key] at hkey
  have := result_ok_inj hkey; subst this
  rw [vec_deref_val] at hx
  rw [hx] at hfind
  cases hfind
  have hvp : vis = .Private := by
    clear h
    rcases hr' : r.visibility with _ | v
    · simp [hr'] at hvis; exact hvis
    · cases v <;> simp_all
  subst hvp hid
  simp (maxSteps := 10000000) only [Aeneas.Std.uncurry, allows_anon_private, should_allow_private, public_read_private,
    bind_ok, ↓reduceIte, Bool.false_eq_true] at h
  h5i_invert h
  by_cases hb2' : b2 = true
  · rw [if_pos hb2'] at h; simp at h
  rw [if_neg hb2'] at h
  h5i_invert h
  obtain ⟨writes, auth_ext1, avt⟩ := x
  simp only [Aeneas.Std.uncurry] at h
  by_cases hci : credential_invalid = true
  · rw [if_pos hci] at h
    h5i_invert h
    all_goals close_leaf
  · rw [if_neg hci] at h
    h5i_invert h
    all_goals close_leaf

end artifactkeeper_kernel.Solution
