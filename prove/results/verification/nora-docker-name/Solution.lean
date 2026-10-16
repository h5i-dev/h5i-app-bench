import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Solution

def allowed (c : Nat) : Bool :=
  (97 ≤ c && c ≤ 122) || (48 ≤ c && c ≤ 57) || c = 46 || c = 95 || c = 45

theorem docker_char_ok (c : U8) (h : validation.is_docker_char c = ok true) :
    allowed c.val ∨ c.val = 47 := by
  unfold validation.is_docker_char at h
  h5i_invert h
  all_goals simp only [allowed, Bool.or_eq_true, Bool.and_eq_true, decide_eq_true_eq]
  all_goals scalar_tac

theorem alnum_ok (c : U8) (h : validation.is_ascii_alphanumeric c = ok true) :
    isAlnum c.val := by
  unfold validation.is_ascii_alphanumeric at h
  h5i_invert h
  all_goals simp only [isAlnum, Bool.or_eq_true, Bool.and_eq_true, decide_eq_true_eq]
  all_goals scalar_tac

theorem chars_ok (n : Slice U8)
    (h : validation.docker_name_chars n = ok (.Ok ())) :
    ∀ c ∈ n.val, allowed c.val ∨ c.val = 47 := by
  unfold validation.docker_name_chars validation.docker_name_chars_loop at h
  have hp := loop_idx_ok
    (validation.docker_name_chars_loop.body n) id n.val.length
    (fun i => ∀ j (hj : j < n.val.length), j < i.val →
      allowed (n.val[j]).val ∨ (n.val[j]).val = 47)
    (fun r => r = .Ok () → ∀ c ∈ n.val, allowed c.val ∨ c.val = 47)
    (by
      intro i r hi hn hr
      unfold validation.docker_name_chars_loop.body at hr
      h5i_invert hr
      all_goals try (simp; done)
      · have hc := docker_char_ok c (by simpa [hc_2] using hb)
        obtain ⟨hidx, hce⟩ := slice_index_ok hc_1
        have hadd := add_ok_val hi2
        refine ⟨?_, ?_, ?_⟩
        · intro j hj hji
          by_cases hji' : j < i.val
          · exact hi j hj hji'
          · have he : j = i.val := by scalar_tac
            subst j
            simpa [hce] using hc
        · dsimp only [id]; scalar_tac
        · dsimp only [id]; scalar_tac
      · intro _ c hc
        obtain ⟨j, hj, he⟩ := List.getElem_of_mem hc
        rw [← he]
        exact hi j hj (by scalar_tac))
    0#usize (.Ok ()) (by simp) (by simp) h
  exact hp rfl

def HeadGood (seg : List Nat) : Prop :=
  ∃ c rest, seg = c :: rest ∧ isAlnum c

def AllHeads (l : List Nat) : Prop := ∀ seg ∈ l.splitOn 47, HeadGood seg

def window (l : List Nat) (s i : Nat) : List Nat := (l.drop s).take (i - s)

noncomputable def pending (l : List Nat) (s i : Nat) : List (List Nat) :=
  List.splitOnPPrepend (· == 47) (l.drop i) (window l s i).reverse

def SegInv (l : List Nat) (s i : Nat) : Prop :=
  s ≤ i ∧ if i ≤ l.length then
    (∀ seg ∈ pending l s i, HeadGood seg) → AllHeads l
  else AllHeads l

theorem window_succ (l : List Nat) (s i : Nat) (hs : s ≤ i) (hi : i < l.length) :
    window l s (i + 1) = window l s i ++ [l[i]] := by
  unfold window
  have he : i + 1 - s = (i - s) + 1 := by omega
  rw [he, List.take_succ_eq_append_getElem (by simp; omega), List.getElem_drop]
  simp only [Nat.add_sub_of_le hs]

theorem window_head (l : List Nat) (s i : Nat) (hs : s < i) (hi : i ≤ l.length)
    (hc : isAlnum l[s]) : HeadGood (window l s i) := by
  unfold window HeadGood
  rw [List.drop_eq_getElem_cons (by omega)]
  obtain ⟨k, hk⟩ : ∃ k, i - s = k + 1 := ⟨i - s - 1, by omega⟩
  rw [hk, List.take_succ_cons]
  exact ⟨_, _, rfl, hc⟩

theorem seginv_skip (l : List Nat) (s i : Nat) (h : SegInv l s i)
    (hi : i < l.length) (hc : l[i] ≠ 47) : SegInv l s (i + 1) := by
  obtain ⟨hs, h⟩ := h
  simp only [if_pos (Nat.le_of_lt hi)] at h
  refine ⟨by omega, ?_⟩
  simp only [if_pos (show i + 1 ≤ l.length by omega)]
  intro hp
  apply h
  have he : pending l s i = pending l s (i + 1) := by
    unfold pending
    rw [List.drop_eq_getElem_cons hi,
      List.splitOnPPrepend_cons_neg (by simpa using hc), window_succ l s i hs hi]
    simp
  simpa [he] using hp

theorem seginv_close (l : List Nat) (s i : Nat) (h : SegInv l s i)
    (hi : i ≤ l.length) (hs : s < i) (hc : isAlnum l[s])
    (hend : i = l.length ∨ ∃ hlt : i < l.length, l[i] = 47) :
    SegInv l (i + 1) (i + 1) := by
  obtain ⟨_, h⟩ := h
  simp only [if_pos hi] at h
  have hg := window_head l s i hs hi hc
  refine ⟨Nat.le_refl _, ?_⟩
  rcases hend with he | ⟨hlt, he⟩
  · subst i
    simp only [show ¬ l.length + 1 ≤ l.length by omega, if_false]
    apply h
    simpa [pending, List.drop_length] using hg
  · simp only [if_pos (show i + 1 ≤ l.length by omega)]
    intro hp
    apply h
    have heq : pending l s i = window l s i :: pending l (i + 1) (i + 1) := by
      unfold pending
      rw [List.drop_eq_getElem_cons hlt,
        List.splitOnPPrepend_cons_pos (by simp [he])]
      simp [window]
    rw [heq]
    intro seg hm
    rcases List.mem_cons.1 hm with rfl | hm
    · exact hg
    · exact hp seg hm

theorem nat_index_ok (n : Slice U8) (i : Usize) (c : U8)
    (h : n.index_usize i = ok c) :
    ∃ hi : i.val < (nats n.val).length, (nats n.val)[i.val] = c.val := by
  obtain ⟨hi, he⟩ := slice_index_ok h
  refine ⟨by simpa [nats] using hi, ?_⟩
  simpa [nats] using congrArg (fun x : U8 => x.val) he

theorem segments_ok (n : Slice U8)
    (h : validation.docker_name_segments n = ok (.Ok ())) : AllHeads (nats n.val) := by
  unfold validation.docker_name_segments validation.docker_name_segments_loop at h
  have hp := loop_idx_ok
    (fun x : Usize × Usize => validation.docker_name_segments_loop.body n x.1 x.2)
    Prod.snd (n.val.length + 1)
    (fun x => SegInv (nats n.val) x.1.val x.2.val)
    (fun r => r = .Ok () → AllHeads (nats n.val))
    (by
      rintro ⟨s, i⟩ r hinv hn hr
      dsimp only [Prod.snd] at hn
      unfold validation.docker_name_segments_loop.body at hr
      h5i_invert hr
      all_goals try (simp; done)
      all_goals dsimp only at hinv ⊢
      · have hs := hinv.1
        have hadd : start1.val = i.val + 1 := by simpa using add_ok_val hstart1
        obtain ⟨hidx, hce⟩ := nat_index_ok n s i3 hi3
        have hal := alnum_ok i3 (by simpa [hc_3] using hb)
        refine ⟨?_, by scalar_tac, by scalar_tac⟩
        rw [hadd]
        apply seginv_close (nats n.val) s.val i.val hinv
          (by simp [nats]; scalar_tac) (by scalar_tac)
          (by simpa [hce] using hal)
        left
        simp [nats]; scalar_tac
      · have hs := hinv.1
        have hadd : start1.val = i.val + 1 := by simpa using add_ok_val hstart1
        obtain ⟨hidx, hce⟩ := nat_index_ok n s i3_1 hi3_1
        obtain ⟨hiidx, hice⟩ := nat_index_ok n i i3 hi3
        have hal := alnum_ok i3_1 (by simpa [hc_4] using hb)
        refine ⟨?_, by scalar_tac, by scalar_tac⟩
        rw [hadd]
        apply seginv_close (nats n.val) s.val i.val hinv
          (by simp [nats]; scalar_tac) (by scalar_tac)
          (by simpa [hce] using hal)
        exact Or.inr ⟨hiidx, by simpa [hc_2] using hice⟩
      · have hadd : i4.val = i.val + 1 := by simpa using add_ok_val hi4
        obtain ⟨hiidx, hice⟩ := nat_index_ok n i i3 hi3
        refine ⟨?_, by scalar_tac, by scalar_tac⟩
        rw [hadd]
        apply seginv_skip (nats n.val) s.val i.val hinv hiidx
        rw [hice]
        scalar_tac
      · intro _
        have hlt : ¬ i.val ≤ (nats n.val).length := by simp [nats]; scalar_tac
        simpa only [if_neg hlt] using hinv.2)
    (0#usize, 0#usize) (.Ok ())
    (by simp [SegInv, pending, window, AllHeads, List.splitOn_eq_splitOnP])
    (by simp) h
  exact hp rfl

theorem split_allowed (l acc : List Nat)
    (hl : ∀ c ∈ l, allowed c ∨ c = 47) (ha : ∀ c ∈ acc, allowed c) :
    ∀ seg ∈ List.splitOnPPrepend (· == 47) l acc, seg.all allowed := by
  induction l generalizing acc with
  | nil =>
    simp only [List.splitOnPPrepend_nil, List.mem_singleton]
    rintro seg rfl
    simpa only [List.all_eq_true, List.mem_reverse] using ha
  | cons c cs ih =>
    have hcs : ∀ x ∈ cs, allowed x ∨ x = 47 := fun x hx => hl x (by simp [hx])
    by_cases hc : c = 47
    · rw [List.splitOnPPrepend_cons_pos (by simp [hc])]
      intro seg hm
      rcases List.mem_cons.1 hm with rfl | hm
      · simpa only [List.all_eq_true, List.mem_reverse] using ha
      · exact ih [] hcs (by simp) seg hm
    · rw [List.splitOnPPrepend_cons_neg (by simpa using hc)]
      apply ih (c :: acc) hcs
      intro x hx
      rcases List.mem_cons.1 hx with rfl | hx
      · exact (hl x (by simp)).resolve_right hc
      · exact ha x hx

theorem docker_name_shape (n : Slice U8) (h : validation.validate_docker_name n = ok (.Ok ())) :
    DockerNameShape (nats n.val) := by
  unfold validation.validate_docker_name at h
  h5i_invert h
  cases v
  have hchars := chars_ok n hr
  have hheads := segments_ok n h
  refine ⟨?_, ?_⟩
  · simp only [nats, List.length_map]
    unfold validation.MAX_DOCKER_NAME_LENGTH at hc_1
    scalar_tac
  · intro seg hm
    obtain ⟨c, rest, he, hc⟩ := hheads seg hm
    refine ⟨c, rest, he, hc, ?_⟩
    change seg.all allowed = true
    apply split_allowed (nats n.val) [] ?_ (by simp) seg hm
    intro c hcm
    obtain ⟨b, hbm, rfl⟩ := List.mem_map.1 hcm
    exact hchars b hbm

end nora_kernel.Solution
