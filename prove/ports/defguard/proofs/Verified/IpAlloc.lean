import Verified.Lockout
/-!
# Device address assignment
-/
open Aeneas Aeneas.Std Result defguard_kernel defguard_kernel.Spec
open H5iAppLib

namespace defguard_kernel.Verified

deriving instance DecidableEq for ipalloc.Ip

theorem host_bits_ok {n : ipalloc.Net} {h : U32} (hh : ipalloc.host_bits n = ok h) : h.val = hostBits n := by
  unfold ipalloc.host_bits at hh
  unfold hostBits
  h5i_invert hh
  all_goals (have hpv : p.val = n.prefix.val := (by
    simp only [lift] at hp; have := (H5iAppLib.Result.ok.inj hp); subst this; simp))
  all_goals (try have := H5iAppLib.sub_ok_val ‹_ - _ = ok _›)
  all_goals (simp_all; try omega)

theorem hostBits_le (n : ipalloc.Net) : hostBits n ≤ 128 := by
  unfold hostBits; split <;> omega

theorem shl_one_ok {h : U32} {b : U128} (hh : h.val < 128) (hb : 1#u128 <<< h = ok b) : b.val = 2 ^ h.val := by
  have hs := U128.ShiftLeft_spec 1#u128 h hh
  have hv := (post_of_ok hs hb).1
  rw [hv, Nat.shiftLeft_eq]
  simp only [U128.size, UScalar.ofNatCore_val_eq, one_mul]
  have : 2 ^ h.val < 2 ^ 128 := Nat.pow_lt_pow_right (by norm_num) hh
  apply Nat.mod_eq_of_lt
  first | omega | simpa using this | (norm_num at this ⊢; omega) | (simp [U128.numBits]; omega)

theorem network_ok {n : ipalloc.Net} {x : U128} (h : ipalloc.network n = ok x) : x.val = netLo n := by
  unfold ipalloc.network at h
  obtain ⟨hb, hhb, h2⟩ := H5iAppLib.bind_tc_eq_ok.1 h
  have hv := host_bits_ok hhb
  unfold netLo; rw [← hv]
  split at h2
  · have := (H5iAppLib.Result.ok.inj h2).symm; subst this
    have h128 : hb.val = 128 := by have := hostBits_le n; scalar_tac
    rw [h128]
    simp
    scalar_tac
  · rename_i hlt
    have hlt' : hb.val < 128 := by scalar_tac
    obtain ⟨bl, hbl, h3⟩ := H5iAppLib.bind_tc_eq_ok.1 h2
    obtain ⟨r, hr, h4⟩ := H5iAppLib.bind_tc_eq_ok.1 h3
    have e1 := shl_one_ok hlt' hbl
    have e2 := H5iAppLib.rem_ok_val hr
    have e3 := H5iAppLib.sub_ok_val h4
    rw [e3.1, e2.1, e1]
    have := Nat.mod_add_div n.ip.val (2 ^ hb.val)
    rw [Nat.mul_comm] at this
    omega

theorem broadcast_ok {n : ipalloc.Net} {x : U128} (h : ipalloc.broadcast n = ok x) : x.val = netHi n := by
  unfold ipalloc.broadcast at h
  obtain ⟨hb, hhb, h2⟩ := H5iAppLib.bind_tc_eq_ok.1 h
  have hv := host_bits_ok hhb
  unfold netHi
  split at h2
  · have := (H5iAppLib.Result.ok.inj h2).symm; subst this
    have h128 : hostBits n = 128 := by have := hostBits_le n; scalar_tac
    have hlo : netLo n = 0 := by
      unfold netLo; rw [h128]
      have : n.ip.val < 2 ^ 128 := by scalar_tac
      rw [Nat.div_eq_of_lt this]; simp
    rw [hlo, h128]; simp
  · rename_i hlt
    have hlt' : hb.val < 128 := by scalar_tac
    obtain ⟨bl, hbl, h3⟩ := H5iAppLib.bind_tc_eq_ok.1 h2
    obtain ⟨nw, hnw, h4⟩ := H5iAppLib.bind_tc_eq_ok.1 h3
    obtain ⟨m1, hm1, h5⟩ := H5iAppLib.bind_tc_eq_ok.1 h4
    have e1 := shl_one_ok hlt' hbl
    have e2 := network_ok hnw
    have e3 := H5iAppLib.sub_ok_val hm1
    have e4 := H5iAppLib.add_ok_val h5
    have hx : x.val = netLo n + (2 ^ hb.val - 1) := by rw [e4, e3.1, e2, e1]; simp
    rw [hx, ← hv]
    have : 1 ≤ 2 ^ hb.val := Nat.one_le_two_pow
    omega

instance (n : ipalloc.Net) (ip : ipalloc.Ip) : Decidable (InNet n ip) := by unfold InNet; infer_instance

theorem contains_ok {n : ipalloc.Net} {ip : ipalloc.Ip} {b : Bool} (h : ipalloc.contains n ip = ok b) :
    b = decide (InNet n ip) := by
  unfold ipalloc.contains at h
  unfold InNet
  h5i_invert h
  all_goals (try have e1 := network_ok ‹ipalloc.network n = ok _›)
  all_goals (try have e2 := broadcast_ok ‹ipalloc.broadcast n = ok _›)
  all_goals (simp_all; try scalar_tac)

theorem ip_in_ok {v : alloc.vec.Vec ipalloc.Ip} {ip : ipalloc.Ip} {b : Bool} (h : ipalloc.ip_in v ip = ok b) :
    b = decide (ip ∈ v.val) := by
  have hs : ipalloc.ip_in v ip ⦃ b => b = v.val.any (fun x => decide (x.v4 = ip.v4) && decide (x.bits = ip.bits)) ⦄ := by
    unfold ipalloc.ip_in ipalloc.ip_in_loop
    h5i_search_any v.val (fun (x : ipalloc.Ip) => decide (x.v4 = ip.v4) && decide (x.bits = ip.bits))
  have h' := post_of_ok hs h
  rw [h']
  have e : ∀ x : ipalloc.Ip, (decide (x.v4 = ip.v4) && decide (x.bits = ip.bits)) = decide (x = ip) := by
    intro x; cases x; cases ip; simp
  simp only [e]
  rw [Bool.eq_iff_iff]; simp

/-- The kernel's test for one address, on numbers. -/
def AssignableAt (n : ipalloc.Net) (used reserved : List ipalloc.Ip) (x : U128) : Prop :=
  x.val ≠ netLo n ∧ x.val ≠ netHi n ∧ x ≠ n.ip ∧ (⟨n.v4, x⟩ : ipalloc.Ip) ∉ used ∧ (⟨n.v4, x⟩ : ipalloc.Ip) ∉ reserved

instance (n : ipalloc.Net) (used reserved : List ipalloc.Ip) (x : U128) : Decidable (AssignableAt n used reserved x) := by
  unfold AssignableAt; infer_instance

theorem assignable_ok {n : ipalloc.Net} {x : U128} {used reserved : alloc.vec.Vec ipalloc.Ip} {b : Bool}
    (h : ipalloc.assignable n x used reserved = ok b) : b = decide (AssignableAt n used.val reserved.val x) := by
  unfold ipalloc.assignable at h
  unfold AssignableAt
  h5i_invert h
  all_goals (try have e1 := network_ok ‹ipalloc.network n = ok _›)
  all_goals (try have e2 := broadcast_ok ‹ipalloc.broadcast n = ok _›)
  all_goals (try have e3 := ip_in_ok hb)
  all_goals (try have e5 := ip_in_ok hb_1)
  all_goals (try have e4 := ip_in_ok hb1)
  all_goals (simp_all; try scalar_tac)
  all_goals (try (intro; simp_all))

/-- The first assignable address of the subnet, or (only if there is none) nothing. -/
def FirstFree (n : ipalloc.Net) (used reserved : List ipalloc.Ip) : Option ipalloc.Ip → Prop
  | some ip => ip.v4 = n.v4 ∧ netLo n ≤ ip.bits.val ∧ ip.bits.val ≤ netHi n ∧
      AssignableAt n used reserved ip.bits ∧
      ∀ y : U128, netLo n ≤ y.val → y.val < ip.bits.val → ¬ AssignableAt n used reserved y
  | none => ∀ y : U128, netLo n ≤ y.val → y.val ≤ netHi n → ¬ AssignableAt n used reserved y

theorem first_free_ok {n : ipalloc.Net} {used reserved : alloc.vec.Vec ipalloc.Ip} {o : Option ipalloc.Ip}
    (h : ipalloc.first_free n used reserved = ok o) : FirstFree n used.val reserved.val o := by
  unfold ipalloc.first_free at h
  obtain ⟨last, hl, h2⟩ := H5iAppLib.bind_tc_eq_ok.1 h
  obtain ⟨x0, hx0, h3⟩ := H5iAppLib.bind_tc_eq_ok.1 h2
  have elast := broadcast_ok hl
  have ex0 := network_ok hx0
  unfold ipalloc.first_free_loop at h3
  refine H5iAppLib.loop_ok _
    (fun x => netLo n ≤ x.val ∧ ∀ y : U128, netLo n ≤ y.val → y.val < x.val → ¬ AssignableAt n used.val reserved.val y)
    (FirstFree n used.val reserved.val) (fun x => 2 ^ 128 - x.val) ?_ x0 o ⟨by omega, fun y h1 h2 => by omega⟩ h3
  intro x r ⟨hlo, hbelow⟩ hb
  unfold ipalloc.first_free_loop.body at hb
  h5i_invert hb
  · -- found
    have ea := assignable_ok hb_1
    simp only [hc_1, true_eq_decide_iff] at ea
    exact ⟨rfl, hlo, by simp only []; scalar_tac, ea, hbelow⟩
  · -- the last address: none of them is assignable
    have ea := assignable_ok hb_1
    intro y h1 h2
    rcases Nat.lt_or_ge y.val x.val with hy | hy
    · exact hbelow y h1 hy
    · have : y = x := by scalar_tac
      subst this; simp_all
  · -- next address
    have ea := assignable_ok hb_1
    have hv := H5iAppLib.add_ok_val hx1
    refine ⟨⟨by omega, fun y h1 h2 => ?_⟩, by scalar_tac⟩
    rcases Nat.lt_or_ge y.val x.val with hy | hy
    · exact hbelow y h1 hy
    · have : y = x := by scalar_tac
      subst this; simp_all
  · -- past the end
    intro y h1 h2; exact hbelow y h1 (by scalar_tac)

theorem find_current_ok {c : alloc.vec.Vec ipalloc.Ip} {n : ipalloc.Net} {o : Option ipalloc.Ip}
    (h : ipalloc.find_current c n = ok o) : o = c.val.find? (fun ip => decide (InNet n ip)) := by
  unfold ipalloc.find_current ipalloc.find_current_loop at h
  refine H5iAppLib.loop_idx_ok _ (fun i => i) c.val.length
    (fun i => ∀ j < i.val, ∀ hj : j < c.val.length, ¬ InNet n c.val[j])
    (fun o => o = c.val.find? (fun ip => decide (InNet n ip))) ?_ 0#usize o (by simp) (by simp) h
  intro i r hinv hi hb
  unfold ipalloc.find_current_loop.body at hb
  h5i_invert hb
  · have hl : i.val < c.val.length := by scalar_tac
    rw [vec_index_eq _ _ hl] at hi2
    have e := (H5iAppLib.Result.ok.inj hi2); subst e
    have hc := contains_ok hb_1
    simp only [hc_1, true_eq_decide_iff] at hc
    simp only []
    symm; rw [List.find?_eq_some_iff_getElem]
    exact ⟨by simpa using hc, i.val, hl, rfl, fun j hj => by simpa using hinv j hj (by omega)⟩
  · have hl : i.val < c.val.length := by scalar_tac
    rw [vec_index_eq _ _ hl] at hi2
    have e := (H5iAppLib.Result.ok.inj hi2); subst e
    have hc := contains_ok hb_1
    simp only [hc_1, false_eq_decide_iff] at hc
    have hv := H5iAppLib.add_ok_val hi3
    simp only [UScalar.ofNatCore_val_eq] at hv
    refine ⟨fun j hj hjl => ?_, by scalar_tac, by scalar_tac⟩
    rcases Nat.lt_or_ge j i.val with hji | hji
    · exact hinv j hji hjl
    · have : j = i.val := by scalar_tac
      subst this; exact hc
  · simp only []
    symm; rw [List.find?_eq_none]
    intro x hx hxin
    obtain ⟨j, hj, rfl⟩ := List.getElem_of_mem hx
    exact hinv j (by scalar_tac) hj (by simpa using hxin)

/-- What `pick` returns for one subnet. -/
def PickOk (n : ipalloc.Net) (used reserved : List ipalloc.Ip) (current : Option (alloc.vec.Vec ipalloc.Ip))
    (o : Option ipalloc.Ip) : Prop :=
  match current with
  | none => FirstFree n used reserved o
  | some c => (∃ ip, c.val.find? (fun ip => decide (InNet n ip)) = some ip ∧ o = some ip) ∨
      (c.val.find? (fun ip => decide (InNet n ip)) = none ∧ FirstFree n used reserved o)

theorem pick_ok {n : ipalloc.Net} {used reserved : alloc.vec.Vec ipalloc.Ip} {current : Option (alloc.vec.Vec ipalloc.Ip)}
    {o : Option ipalloc.Ip} (h : ipalloc.pick n used reserved current = ok o) : PickOk n used.val reserved.val current o := by
  unfold ipalloc.pick at h
  unfold PickOk
  cases current with
  | none => exact first_free_ok h
  | some c =>
    simp only [] at h ⊢
    obtain ⟨o1, h1, h2⟩ := H5iAppLib.bind_tc_eq_ok.1 h
    have e := find_current_ok h1
    cases o1 with
    | none => exact Or.inr ⟨e.symm, first_free_ok h2⟩
    | some ip =>
      simp only [] at h2
      have := (H5iAppLib.Result.ok.inj h2).symm; subst this
      exact Or.inl ⟨ip, e.symm, rfl⟩

/-- What `assign_next_network_ip` returns. -/
def AssignOk (nets : List ipalloc.Net) (used reserved : List ipalloc.Ip) (current : Option (alloc.vec.Vec ipalloc.Ip)) :
    core.result.Result (alloc.vec.Vec ipalloc.Ip) Usize → Prop
  | .Ok ips => ips.val.length = nets.length ∧
      ∀ k (h1 : k < nets.length) (h2 : k < ips.val.length), PickOk nets[k] used reserved current (some ips.val[k])
  | .Err k => ∃ hk : k.val < nets.length, PickOk nets[k.val] used reserved current none

theorem assign_ok {nets : alloc.vec.Vec ipalloc.Net} {used reserved : alloc.vec.Vec ipalloc.Ip}
    {current : Option (alloc.vec.Vec ipalloc.Ip)} {r : core.result.Result (alloc.vec.Vec ipalloc.Ip) Usize}
    (h : ipalloc.assign_next_network_ip nets used reserved current = ok r) :
    AssignOk nets.val used.val reserved.val current r := by
  unfold ipalloc.assign_next_network_ip ipalloc.assign_next_network_ip_loop at h
  refine H5iAppLib.loop_idx_ok _ (fun x => x.2) nets.val.length
    (fun x => x.1.val.length = x.2.val ∧ ∀ j < x.2.val, ∀ (h1 : j < nets.val.length) (h2 : j < x.1.val.length),
      PickOk nets.val[j] used.val reserved.val current (some x.1.val[j]))
    (AssignOk nets.val used.val reserved.val current) ?_ (alloc.vec.Vec.new ipalloc.Ip, 0#usize) r
    ⟨by simp, fun j hj => by simp at hj⟩ (by simp) h
  rintro ⟨ips, k⟩ r ⟨hlen, hall⟩ hk hb
  simp only [] at hlen hall hk
  unfold ipalloc.assign_next_network_ip_loop.body at hb
  h5i_invert hb
  · -- full
    have hl : k.val < nets.val.length := by scalar_tac
    rw [vec_index_eq _ _ hl] at hn
    have e := (H5iAppLib.Result.ok.inj hn); subst e
    exact ⟨hl, pick_ok ho⟩
  · -- one more address
    have hl : k.val < nets.val.length := by scalar_tac
    rw [vec_index_eq _ _ hl] at hn
    have e := (H5iAppLib.Result.ok.inj hn); subst e
    have hp := pick_ok ho
    have hv := push_ok_val hips1
    have hk1 := H5iAppLib.add_ok_val hk1
    simp only [UScalar.ofNatCore_val_eq] at hk1
    refine ⟨⟨by simp [hv]; omega, fun j hj h1 h2 => ?_⟩, by simp only []; omega, by simp only []; scalar_tac⟩
    dsimp only at hj h2 ⊢
    simp only [hv] at h2 ⊢
    rcases Nat.lt_or_ge j k.val with hjk | hjk
    · rw [List.getElem_append_left (by omega)]
      exact hall j hjk h1 (by omega)
    · have : j = k.val := by omega
      subst this
      rw [List.getElem_append_right (by omega)]
      simp only [hlen, Nat.sub_self, List.getElem_cons_zero]
      exact hp
  · -- done
    have hk' : k.val = nets.val.length := by scalar_tac
    exact ⟨by omega, fun j h1 h2 => hall j (by omega) h1 h2⟩

instance (n : ipalloc.Net) (u r : List ipalloc.Ip) (ip : ipalloc.Ip) : Decidable (Assignable n u r ip) := by
  unfold Assignable; infer_instance

theorem ip_eta {ip : ipalloc.Ip} {v : Bool} (h : ip.v4 = v) : (⟨v, ip.bits⟩ : ipalloc.Ip) = ip := by
  cases ip; simp_all

theorem first_free_some {n : ipalloc.Net} {u r : List ipalloc.Ip} {ip : ipalloc.Ip} (h : FirstFree n u r (some ip)) :
    Assignable n u r ip ∧ ∀ ip', Assignable n u r ip' → ip.bits.val ≤ ip'.bits.val := by
  obtain ⟨hv, hlo, hhi, ⟨a1, a2, a3, a4, a5⟩, hmin⟩ := h
  rw [ip_eta hv] at a4 a5
  refine ⟨⟨⟨hv, hlo, hhi⟩, a1, a2, fun e => a3 (UScalar.eq_of_val_eq e), a4, a5⟩, fun ip' ha' => ?_⟩
  obtain ⟨⟨hv', hlo', hhi'⟩, b1, b2, b3, b4, b5⟩ := ha'
  by_contra hlt
  apply hmin ip'.bits hlo' (by omega)
  unfold AssignableAt; rw [ip_eta hv']
  exact ⟨b1, b2, fun e => b3 (by rw [e]), b4, b5⟩

theorem first_free_none {n : ipalloc.Net} {u r : List ipalloc.Ip} (h : FirstFree n u r none) :
    ∀ ip, ¬ Assignable n u r ip := by
  rintro ip ⟨⟨hv, hlo, hhi⟩, b1, b2, b3, b4, b5⟩
  apply h ip.bits hlo hhi
  unfold AssignableAt; rw [ip_eta hv]
  exact ⟨b1, b2, fun e => b3 (by rw [e]), b4, b5⟩

theorem gateway_in_net (n : ipalloc.Net) : InNet n ⟨n.v4, n.ip⟩ := by
  refine ⟨rfl, ?_, ?_⟩
  · unfold netLo; exact Nat.div_mul_le_self _ _
  · unfold netHi netLo
    have := Nat.lt_div_mul_add (a := n.ip.val) (Nat.two_pow_pos (hostBits n))
    simp only []
    omega

/-- A fresh assignment (no current addresses) gives each subnet its lowest
assignable address: inside it, not its network, broadcast or gateway
address, neither used nor reserved. -/
theorem fresh_addresses_valid {nets : alloc.vec.Vec ipalloc.Net} {used reserved : alloc.vec.Vec ipalloc.Ip}
    {ips : alloc.vec.Vec ipalloc.Ip}
    (h : ipalloc.assign_next_network_ip nets used reserved none = ok (.Ok ips)) :
    ips.val.length = nets.val.length ∧ ∀ k (h1 : k < nets.val.length) (h2 : k < ips.val.length),
      Assignable nets.val[k] used.val reserved.val ips.val[k] ∧
      ∀ ip', Assignable nets.val[k] used.val reserved.val ip' → ips.val[k].bits.val ≤ ip'.bits.val := by
  obtain ⟨hl, hall⟩ := assign_ok h
  exact ⟨hl, fun k h1 h2 => first_free_some (hall k h1 h2)⟩

/-- `NetworkFull` only when the subnet has no assignable address left. -/
theorem full_only_when_full {nets : alloc.vec.Vec ipalloc.Net} {used reserved : alloc.vec.Vec ipalloc.Ip} {k : Usize}
    (h : ipalloc.assign_next_network_ip nets used reserved none = ok (.Err k)) :
    ∃ hk : k.val < nets.val.length, ∀ ip, ¬ Assignable nets.val[k.val] used.val reserved.val ip := by
  obtain ⟨hk, hp⟩ := assign_ok h
  exact ⟨hk, first_free_none hp⟩

/-- Finding: on reassignment an address the device already has inside the
subnet is kept as it is, without the checks a fresh address gets. -/
theorem kept_address_unchecked {nets : alloc.vec.Vec ipalloc.Net} {used reserved c : alloc.vec.Vec ipalloc.Ip}
    {ips : alloc.vec.Vec ipalloc.Ip} {ip : ipalloc.Ip} (k : Nat) (h1 : k < nets.val.length) (h2 : k < ips.val.length)
    (h : ipalloc.assign_next_network_ip nets used reserved (some c) = ok (.Ok ips))
    (hc : c.val.find? (fun x => decide (InNet nets.val[k] x)) = some ip) :
    ips.val[k] = ip := by
  obtain ⟨_, hall⟩ := assign_ok h
  rcases hall k h1 h2 with ⟨ip', he, ho⟩ | ⟨hn, _⟩
  · rw [hc] at he; cases he; exact (Option.some.inj ho)
  · rw [hc] at hn; cases hn

/-- Finding, concretely: a device whose current address is now the subnet's
gateway address keeps it, although a fresh assignment would never give it. -/
theorem keeps_gateway_address {nets : alloc.vec.Vec ipalloc.Net} {used reserved c : alloc.vec.Vec ipalloc.Ip}
    {ips : alloc.vec.Vec ipalloc.Ip} (k : Nat) (h1 : k < nets.val.length) (h2 : k < ips.val.length)
    (hc : c.val = [⟨nets.val[k].v4, nets.val[k].ip⟩])
    (h : ipalloc.assign_next_network_ip nets used reserved (some c) = ok (.Ok ips)) :
    ips.val[k] = ⟨nets.val[k].v4, nets.val[k].ip⟩ ∧ ¬ Assignable nets.val[k] used.val reserved.val ips.val[k] := by
  have hf : c.val.find? (fun x => decide (InNet nets.val[k] x)) = some ⟨nets.val[k].v4, nets.val[k].ip⟩ := by
    rw [hc]; simp [gateway_in_net]
  have e := kept_address_unchecked k h1 h2 h hf
  refine ⟨e, ?_⟩
  rw [e]; rintro ⟨_, _, _, h3, _⟩; exact h3 rfl

end defguard_kernel.Verified
