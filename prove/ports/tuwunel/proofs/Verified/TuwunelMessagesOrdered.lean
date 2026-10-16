import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit

namespace tuwunel_kernel.Verified.TuwunelMessagesOrdered

theorem push_ok {α} {v w : alloc.vec.Vec α} {x : α} (h : v.push x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  simp only at h
  split at h
  · simp only [ok.injEq] at h; subst h; simp [alloc.vec.Vec.from_val]
  · simp at h

/-- Index `j` names a timeline row of `room` whose count satisfies `C`. -/
def RowAt (s : Snapshot) (room : U64) (C : I64 → Prop) (j : Usize) : Prop :=
  ∃ p, s.pdus.val[j.val]? = some p ∧ p.outlier = false ∧ p.room = room ∧ C p.count

theorem pdus_loop_ok (s : Snapshot) (room : U64) (frm : I64) (out : alloc.vec.Vec Usize) (i : Usize)
    (r : alloc.vec.Vec Usize)
    (hout : ∀ j ∈ out.val, j.val < i.val ∧ RowAt s room (frm < ·) j)
    (hord : out.val.Pairwise (fun a b => a.val < b.val))
    (hi : i.val ≤ s.pdus.val.length)
    (h : svc_timeline.pdus_loop s room frm out i = ok r) :
    (∀ j ∈ r.val, RowAt s room (frm < ·) j) ∧ r.val.Pairwise (fun a b => a.val < b.val) := by
  unfold svc_timeline.pdus_loop at h
  refine loop_idx_ok _ (fun x => x.2) s.pdus.val.length
    (fun x => (∀ j ∈ x.1.val, j.val < x.2.val ∧ RowAt s room (frm < ·) j) ∧ x.1.val.Pairwise (fun a b => a.val < b.val))
    (fun r => (∀ j ∈ r.val, RowAt s room (frm < ·) j) ∧ r.val.Pairwise (fun a b => a.val < b.val))
    ?_ (out, i) r ⟨hout, hord⟩ hi h
  rintro ⟨o, k⟩ x ⟨ho, hp⟩ hk hx
  simp only [svc_timeline.pdus_loop.body] at hx
  h5i_invert hx
  · clear h
    simp only at ho hp hk ⊢
    h5i_ok_facts
    simp only [svc_timeline.in_timeline] at hb
    refine ⟨?_, by scalar_tac, by scalar_tac⟩
    by_cases hc1 : b = true ∧ p.count > frm
    · obtain ⟨hb1, hc2⟩ := hc1
      simp only [hb1, hc2, if_true] at hout1
      have hv := push_ok hout1
      have hrow : RowAt s room (frm < ·) k := by
        split at hb
        · simp_all
        · simp only [ok.injEq] at hb
          exact ⟨p, hp_1_val, by simp_all, by simp_all, hc2⟩
      rw [hv]
      refine ⟨?_, ?_⟩
      · intro j hj
        simp only [List.mem_append, List.mem_singleton] at hj
        rcases hj with hj | rfl
        · exact ⟨by have := (ho j hj).1; scalar_tac, (ho j hj).2⟩
        · exact ⟨by scalar_tac, hrow⟩
      · rw [List.pairwise_append]
        refine ⟨hp, by simp, ?_⟩
        intro a ha b hb'
        simp only [List.mem_singleton] at hb'
        subst hb'
        exact (ho a ha).1
    · have : out1 = o := by
        by_cases hb1 : b = true
        · have hc2 : ¬ p.count > frm := fun h => hc1 ⟨hb1, h⟩
          simp only [hb1, hc2, if_true, if_false, ok.injEq] at hout1; exact hout1.symm
        · simp only [hb1, if_false, ok.injEq, Bool.false_eq_true] at hout1; exact hout1.symm
      subst this
      exact ⟨fun j hj => ⟨by have := (ho j hj).1; scalar_tac, (ho j hj).2⟩, hp⟩
  · exact ⟨fun j hj => (ho j hj).2, hp⟩

theorem pdus_rev_loop_ok (s : Snapshot) (room : U64) (unt : I64) (out : alloc.vec.Vec Usize) (i : Usize)
    (r : alloc.vec.Vec Usize)
    (hout : ∀ j ∈ out.val, i.val ≤ j.val ∧ RowAt s room (· < unt) j)
    (hord : out.val.Pairwise (fun a b => b.val < a.val))
    (h : svc_timeline.pdus_rev_loop s.pdus room unt out i = ok r) :
    (∀ j ∈ r.val, RowAt s room (· < unt) j) ∧ r.val.Pairwise (fun a b => b.val < a.val) := by
  unfold svc_timeline.pdus_rev_loop at h
  refine loop_ok _
    (fun x => (∀ j ∈ x.1.val, x.2.val ≤ j.val ∧ RowAt s room (· < unt) j) ∧ x.1.val.Pairwise (fun a b => b.val < a.val))
    (fun r => (∀ j ∈ r.val, RowAt s room (· < unt) j) ∧ r.val.Pairwise (fun a b => b.val < a.val))
    (fun x => x.2.val) ?_ (out, i) r ⟨hout, hord⟩ h
  rintro ⟨o, k⟩ x ⟨ho, hp⟩ hx
  simp only [svc_timeline.pdus_rev_loop.body] at hx
  h5i_invert hx
  · clear h
    simp only at ho hp ⊢
    h5i_ok_facts
    simp only [svc_timeline.in_timeline] at hb
    have hrow : p.count < unt → RowAt s room (· < unt) i1 := by
      intro hc2
      split at hb
      · simp_all
      · simp only [ok.injEq] at hb
        exact ⟨p, hp_1_val, by simp_all, by simp_all, hc2⟩
    have hle : ∀ j ∈ o.val, i1.val < j.val := fun j hj => by have := (ho j hj).1; scalar_tac
    refine ⟨?_, by scalar_tac⟩
    rw [push_ok hout1]
    refine ⟨?_, ?_⟩
    · intro j hj
      simp only [List.mem_append, List.mem_singleton] at hj
      rcases hj with hj | rfl
      · exact ⟨by have := hle j hj; scalar_tac, (ho j hj).2⟩
      · exact ⟨le_refl _, hrow ‹_›⟩
    · rw [List.pairwise_append]
      refine ⟨hp, by simp, ?_⟩
      intro a ha b hb'
      simp only [List.mem_singleton] at hb'
      subst hb'
      exact hle a ha
  · clear h
    simp only at ho hp ⊢
    h5i_ok_facts
    exact ⟨⟨fun j hj => ⟨by have := (ho j hj).1; scalar_tac, (ho j hj).2⟩, hp⟩, by scalar_tac⟩
  · clear h
    simp only at ho hp ⊢
    h5i_ok_facts
    exact ⟨⟨fun j hj => ⟨by have := (ho j hj).1; scalar_tac, (ho j hj).2⟩, hp⟩, by scalar_tac⟩
  · exact ⟨fun j hj => (ho j hj).2, hp⟩

theorem pdus_ok (s : Snapshot) (room : U64) (frm : I64) (v : alloc.vec.Vec Usize)
    (h : svc_timeline.pdus s room frm = ok (.Ok v)) :
    (∀ j ∈ v.val, RowAt s room (frm < ·) j) ∧ v.val.Pairwise (fun a b => a.val < b.val) := by
  unfold svc_timeline.pdus at h
  h5i_invert h
  exact pdus_loop_ok s room frm _ _ _ (by simp) (by simp) (by simp) hout

theorem pdus_rev_ok (s : Snapshot) (room : U64) (unt : I64) (v : alloc.vec.Vec Usize)
    (h : svc_timeline.pdus_rev s room unt = ok (.Ok v)) :
    (∀ j ∈ v.val, RowAt s room (· < unt) j) ∧ v.val.Pairwise (fun a b => b.val < a.val) := by
  unfold svc_timeline.pdus_rev at h
  h5i_invert h
  exact pdus_rev_loop_ok s room unt _ _ _ (by simp) (by simp) hout

/-- Count `c` lies strictly before the `to` bound in the direction of travel. -/
def BeforeTo (tob : Option I64) (dir : Dir) (c : I64) : Prop :=
  ∀ t, tob = some t → (dir = .Forward → c.val < t.val) ∧ (dir = .Backward → t.val < c.val)

theorem reached_to_false {tob : Option I64} {dir : Dir} {c : I64}
    (h : api_message.reached_to tob dir c = ok false) : BeforeTo tob dir c := by
  intro t ht
  subst ht
  cases dir <;> simp [api_message.reached_to] at h <;> scalar_tac

/-- What the scan keeps: events read off `it` in order, each with its row's
count and before `to`. -/
def ScanOk (s : Snapshot) (it : List Usize) (tob : Option I64) (dir : Dir) (limit : U64)
    (ev : List (I64 × Usize)) : Prop :=
  (ev.map Prod.snd).Sublist it ∧ ev.length ≤ limit.val ∧
    ∀ e ∈ ev, ∃ p, s.pdus.val[e.2.val]? = some p ∧ e.1 = p.count ∧ BeforeTo tob dir e.1

theorem scan_loop_ok (s : Snapshot) (user : U64) (it : Slice Usize) (tob : Option I64) (dir : Dir)
    (limit : U64) (filter : Filter) (short : U64) (bv : Bool)
    (ev : alloc.vec.Vec (I64 × Usize)) (sc : Option I64) (dn : Bool) (i : Usize)
    (ev' : alloc.vec.Vec (I64 × Usize)) (sc' : Option I64)
    (hinv : ScanOk s (it.val.take i.val) tob dir limit ev.val)
    (h : api_message.scan_loop s user it tob dir limit filter short bv ev sc dn i = ok (ev', sc')) :
    ScanOk s it.val tob dir limit ev'.val := by
  unfold api_message.scan_loop at h
  refine loop_ok _
    (fun x => ScanOk s (it.val.take x.2.2.2.val) tob dir limit x.1.val)
    (fun r => ScanOk s it.val tob dir limit r.1.val)
    (fun x => 2 * (it.val.length - x.2.2.2.val) + (if x.2.2.1 then 0 else 1))
    ?_ (ev, sc, dn, i) (ev', sc') hinv h
  rintro ⟨e, c, d, k⟩ x hI hx
  simp only at hI
  have hdone : ScanOk s it.val tob dir limit e.val :=
    ⟨hI.1.trans (List.take_sublist _ _), hI.2.1, hI.2.2⟩
  simp only [api_message.scan_loop.body] at hx
  h5i_invert hx
  all_goals clear h
  · exact hdone
  · exact ⟨hI, by simp [hc]⟩
  · have hbt := reached_to_false (by simpa [hc_3] using hb)
    obtain ⟨hkl, hpk⟩ := slice_index_ok hp
    have hp1v := vec_index_slice_ok_get? hp1
    have hi3v : i3.val = e.val.length := by
      simp only [lift, ok.injEq] at hi3; subst hi3; simp
    have hkl' : k.val < it.val.length := by scalar_tac
    have hi4v : i4.val = k.val + 1 := by h5i_ok_facts; scalar_tac
    have htake : it.val.take i4.val = it.val.take k.val ++ [p] := by
      rw [hi4v, List.take_add_one, List.getElem?_eq_getElem hkl', hpk]; rfl
    simp only [hi4v]
    refine ⟨?_, by simp; omega⟩
    by_cases hb1' : b1 = true
    · simp only [hb1', if_true] at hevents1
      rw [push_ok hevents1, ← hi4v, htake]
      refine ⟨?_, ?_, ?_⟩
      · simpa using hI.1.append (List.Sublist.refl [p])
      · have := hI.2.1; simp; scalar_tac
      · intro x hx
        simp only [List.mem_append, List.mem_singleton] at hx
        rcases hx with hx | rfl
        · exact hI.2.2 x hx
        · exact ⟨p1, hp1v, rfl, hbt⟩
    · simp only [hb1', if_false, Bool.false_eq_true, ok.injEq] at hevents1
      subst hevents1
      rw [← hi4v, htake]
      exact ⟨hI.1.trans (List.sublist_append_left _ _), hI.2.1, hI.2.2⟩
  · exact hdone
  · exact hdone


/-- The event id `event_ids` reads for an event. -/
def evid (s : Snapshot) (e : I64 × Usize) : U64 :=
  match s.pdus.val[e.2.val]? with
  | some p => p.event_id
  | none => 0#u64

theorem event_ids_loop_ok (s : Snapshot) (ev : Slice (I64 × Usize)) (out : alloc.vec.Vec U64) (i : Usize)
    (r : alloc.vec.Vec U64)
    (hout : out.val = (ev.val.take i.val).map (evid s))
    (hi : i.val ≤ ev.val.length)
    (h : api_message.event_ids_loop s ev out i = ok r) :
    r.val = ev.val.map (evid s) := by
  unfold api_message.event_ids_loop at h
  refine loop_idx_ok _ (fun x => x.2) ev.val.length
    (fun x => x.1.val = (ev.val.take x.2.val).map (evid s))
    (fun r => r.val = ev.val.map (evid s))
    ?_ (out, i) r hout hi h
  rintro ⟨o, k⟩ x ho hk hx
  simp only [api_message.event_ids_loop.body] at hx
  h5i_invert hx
  · clear h
    simp only at ho hk ⊢
    obtain ⟨hkl, hpk⟩ := slice_index_ok hx_1
    obtain ⟨c0, j⟩ := x_1
    change (do let p ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice Pdu) s.pdus j; let out1 ← o.push p.event_id; let i3 ← k + 1#usize; ok (ControlFlow.cont (out1, i3))) = ok x at hx
    h5i_invert hx
    have hpv := vec_index_slice_ok_get? hp
    have hi3v : i3.val = k.val + 1 := by h5i_ok_facts; scalar_tac
    try simp only
    refine ⟨?_, by omega, by omega⟩
    rw [push_ok hout1, ho, hi3v, List.take_add_one, List.getElem?_eq_getElem hkl, hpk]
    simp [evid, hpv]
  · clear h
    simp only at ho hk ⊢
    rw [ho, List.take_of_length_le (by scalar_tac)]


theorem countOf_row {s : Snapshot} {j : Nat} {p : Pdu} (hk : Keys s) (hp : s.pdus.val[j]? = some p)
    (ho : p.outlier = false) : countOf s p.event_id.val = some p.count.val := by
  have hpm : p ∈ s.pdus.val := List.mem_of_getElem? hp
  have hpt : p ∈ timeline s := by simp [timeline, hpm, ho]
  unfold countOf
  cases hf : (timeline s).find? (fun q => q.event_id.val = p.event_id.val) with
  | none =>
    rw [List.find?_eq_none] at hf
    exact absurd (by simp) (hf p hpt)
  | some q =>
    obtain ⟨hq, hqe⟩ := find?_mem hf
    have hqm : q ∈ s.pdus.val := (List.mem_filter.1 hq).1
    have : q = p := List.inj_on_of_nodup_map hk.1 hqm hpm (by simpa using hqe)
    simp [this]

theorem sorted_idx {s : Snapshot} {a b : Nat} {p q : Pdu} (hs : Sorted s)
    (ha : s.pdus.val[a]? = some p) (hb : s.pdus.val[b]? = some q) (hab : a < b)
    (hpo : p.outlier = false) (hqo : q.outlier = false) : p.count.val < q.count.val := by
  unfold Sorted timeline at hs
  rw [List.pairwise_filter, List.pairwise_iff_getElem] at hs
  rw [List.getElem?_eq_some_iff] at ha hb
  obtain ⟨ha1, rfl⟩ := ha
  obtain ⟨hb1, rfl⟩ := hb
  exact hs a b ha1 hb1 hab (by simp [hpo]) (by simp [hqo])


theorem deref_val {T : Type} (v : alloc.vec.Vec T) : (alloc.vec.Vec.deref v).val = v.val := by
  simp [alloc.vec.Vec.deref]

/-- The rows `pdus`/`pdus_rev` return, by direction. -/
def ItOk (s : Snapshot) (room : U64) (dir : Dir) (frm : I64) (it : List Usize) : Prop :=
  (dir = .Forward → (∀ j ∈ it, RowAt s room (frm < ·) j) ∧ it.Pairwise (fun a b => a.val < b.val)) ∧
  (dir = .Backward → (∀ j ∈ it, RowAt s room (· < frm) j) ∧ it.Pairwise (fun a b => b.val < a.val))

theorem messages_core (s : Snapshot) (hk : Keys s) (hs : Sorted s) (user room : U64) (dir : Dir)
    (frm : I64) (tob : Option I64) (limit : U64) (filter : Filter) (short : U64) (bv : Bool)
    (it : alloc.vec.Vec Usize) (events : alloc.vec.Vec (I64 × Usize)) (scanned : Option I64)
    (chunk : alloc.vec.Vec U64)
    (hit : ItOk s room dir frm it.val)
    (hscan : api_message.scan s user (alloc.vec.Vec.deref it) tob dir limit filter short bv = ok (events, scanned))
    (hids : api_message.event_ids s (alloc.vec.Vec.deref events) = ok chunk) :
    ∃ cs : List Int, chunk.val.map (fun e => countOf s e.val) = cs.map some ∧
      (dir = .Forward → cs.Pairwise (· < ·) ∧ ∀ c ∈ cs, frm.val < c ∧ ∀ t, tob = some t → c < t.val) ∧
      (dir = .Backward → cs.Pairwise (· > ·) ∧ ∀ c ∈ cs, c < frm.val ∧ ∀ t, tob = some t → t.val < c) ∧
      chunk.val.length ≤ limit.val := by
  have hsc : ScanOk s it.val tob dir limit events.val := by
    have := scan_loop_ok s user (alloc.vec.Vec.deref it) tob dir limit filter short bv
      (alloc.vec.Vec.new _) none false 0#usize events scanned (by simp [ScanOk]) hscan
    rwa [deref_val] at this
  have hch : chunk.val = events.val.map (evid s) := by
    have := event_ids_loop_ok s (alloc.vec.Vec.deref events) (alloc.vec.Vec.new _) 0#usize chunk
      (by simp) (by simp) hids
    rwa [deref_val] at this
  have hfacts : ∀ e ∈ events.val, ∃ p, s.pdus.val[e.2.val]? = some p ∧ e.1 = p.count ∧
      BeforeTo tob dir e.1 ∧ p.outlier = false ∧ (dir = .Forward → frm < p.count) ∧
      (dir = .Backward → p.count < frm) := by
    intro e he
    obtain ⟨p, hp, he1, hbt⟩ := hsc.2.2 e he
    have hmem : e.2 ∈ it.val := hsc.1.subset (List.mem_map_of_mem he)
    cases dir with
    | Forward =>
      obtain ⟨q, hq, hqo, -, hqc⟩ := (hit.1 rfl).1 e.2 hmem
      rw [hp, Option.some.injEq] at hq; subst hq
      exact ⟨p, hp, he1, hbt, hqo, fun _ => hqc, (by intro h; cases h)⟩
    | Backward =>
      obtain ⟨q, hq, hqo, -, hqc⟩ := (hit.2 rfl).1 e.2 hmem
      rw [hp, Option.some.injEq] at hq; subst hq
      exact ⟨p, hp, he1, hbt, hqo, (by intro h; cases h), fun _ => hqc⟩
  refine ⟨events.val.map (fun e => e.1.val), ?_, ?_, ?_, ?_⟩
  · rw [hch, List.map_map, List.map_map]
    apply List.map_congr_left
    intro e he
    obtain ⟨p, hp, he1, -, ho, -⟩ := hfacts e he
    simp [evid, hp, countOf_row hk hp ho, he1]
  · intro hd
    subst hd
    refine ⟨?_, ?_⟩
    · rw [List.pairwise_map]
      have hP := (hit.1 rfl).2.sublist hsc.1
      rw [List.pairwise_map] at hP
      refine hP.imp_of_mem ?_
      intro a b ha hb hab
      obtain ⟨p, hp, ha1, -, hpo, -⟩ := hfacts a ha
      obtain ⟨q, hq, hb1, -, hqo, -⟩ := hfacts b hb
      rw [ha1, hb1]
      exact sorted_idx hs hp hq hab hpo hqo
    · simp only [List.mem_map]
      rintro c ⟨e, he, rfl⟩
      obtain ⟨p, hp, he1, hbt, -, hlt, -⟩ := hfacts e he
      have := hlt rfl
      exact ⟨by rw [he1]; scalar_tac, fun t ht => (hbt t ht).1 rfl⟩
  · intro hd
    subst hd
    refine ⟨?_, ?_⟩
    · rw [List.pairwise_map]
      have hP := (hit.2 rfl).2.sublist hsc.1
      rw [List.pairwise_map] at hP
      refine hP.imp_of_mem ?_
      intro a b ha hb hab
      obtain ⟨p, hp, ha1, -, hpo, -⟩ := hfacts a ha
      obtain ⟨q, hq, hb1, -, hqo, -⟩ := hfacts b hb
      rw [ha1, hb1]
      exact sorted_idx hs hq hp hab hqo hpo
    · simp only [List.mem_map]
      rintro c ⟨e, he, rfl⟩
      obtain ⟨p, hp, he1, hbt, -, -, hlt⟩ := hfacts e he
      have := hlt rfl
      exact ⟨by rw [he1]; scalar_tac, fun t ht => (hbt t ht).2 rfl⟩
  · rw [hch, List.length_map]
    exact hsc.2.1

theorem bounded_le {lim l : U64}
    (h : api_message.bounded (some lim) api_message.LIMIT_DEFAULT api_message.LIMIT_MAX = ok l) :
    l.val ≤ min lim.val 1000 := by
  simp only [api_message.bounded] at h
  have hm : api_message.LIMIT_MAX.val = 1000 := by simp [api_message.LIMIT_MAX]
  split at h <;> simp only [ok.injEq] at h <;> subst h <;> scalar_tac

theorem itok_nil (s : Snapshot) (room : U64) (dir : Dir) (frm : I64) : ItOk s room dir frm [] := by
  simp [ItOk]

theorem itok_fwd {s : Snapshot} {room : U64} {frm : I64} {it} {it1 : alloc.vec.Vec Usize}
    (hit1 : (match it with
      | core.result.Result.Ok v => ok v
      | core.result.Result.Err _ => ok (alloc.vec.Vec.new Usize)) = ok it1)
    (hit : svc_timeline.pdus s room frm = ok it)
    :
    ItOk s room .Forward frm it1.val := by
  cases it with
  | Ok w =>
    simp only [ok.injEq] at hit1; subst hit1
    have := pdus_ok s room frm _ hit
    simp only [ItOk, reduceCtorEq, false_implies, and_true]
    exact fun _ => this
  | Err _ => simp only [ok.injEq] at hit1; subst hit1; exact itok_nil s room _ frm

theorem itok_bwd {s : Snapshot} {room : U64} {frm : I64} {it} {it1 : alloc.vec.Vec Usize}
    (hit1 : (match it with
      | core.result.Result.Ok v => ok v
      | core.result.Result.Err _ => ok (alloc.vec.Vec.new Usize)) = ok it1)
    (hit : svc_timeline.pdus_rev s room frm = ok it)
    :
    ItOk s room .Backward frm it1.val := by
  cases it with
  | Ok w =>
    simp only [ok.injEq] at hit1; subst hit1
    have := pdus_rev_ok s room frm _ hit
    simp only [ItOk, reduceCtorEq, false_implies, true_and]
    exact fun _ => this
  | Err _ => simp only [ok.injEq] at hit1; subst hit1; exact itok_nil s room _ frm

theorem finish {cs : List Int} {dir : Dir} {frm : I64} {tob : Option I64} {upto : Token} {limit lim : U64}
    {n : Nat} (hto : ∀ t, upto = .At t → tob = some t) (hl : limit.val ≤ min lim.val 1000)
    {P : Prop} (h1 : P)
    (h2 : dir = .Forward → cs.Pairwise (· < ·) ∧ ∀ c ∈ cs, frm.val < c ∧ ∀ t, tob = some t → c < t.val)
    (h3 : dir = .Backward → cs.Pairwise (· > ·) ∧ ∀ c ∈ cs, c < frm.val ∧ ∀ t, tob = some t → t.val < c)
    (h4 : n ≤ limit.val) :
    P ∧ (dir = .Forward → cs.Pairwise (· < ·) ∧ ∀ c ∈ cs, frm.val < c ∧ ∀ t, upto = .At t → c < t.val) ∧
      (dir = .Backward → cs.Pairwise (· > ·) ∧ ∀ c ∈ cs, c < frm.val ∧ ∀ t, upto = .At t → t.val < c) ∧
      n ≤ min lim.val 1000 := by
  refine ⟨h1, fun hd => ?_, fun hd => ?_, by omega⟩
  · obtain ⟨hp, hc⟩ := h2 hd
    exact ⟨hp, fun c hc' => ⟨(hc c hc').1, fun t ht => (hc c hc').2 t (hto t ht)⟩⟩
  · obtain ⟨hp, hc⟩ := h3 hd
    exact ⟨hp, fun c hc' => ⟨(hc c hc').1, fun t ht => (hc c hc').2 t (hto t ht)⟩⟩

theorem messages_ordered (s : Snapshot) (u room : U64) (frm upto : Token) (dir : Dir) (lim : U64) (f : Filter)
    (st : I64) (en : Option I64) (chunk : alloc.vec.Vec U64)
    (h : transition s ⟨u, .Messages room frm upto dir lim f⟩ = ok (.Ok (.Messages st en chunk)))
    (hk : Keys s) (hs : Sorted s) :
    ∃ cs : List Int, chunk.val.map (fun e => countOf s e.val) = cs.map some ∧
      (dir = .Forward → cs.Pairwise (· < ·) ∧ ∀ c ∈ cs, st.val < c ∧ ∀ t, upto = .At t → c < t.val) ∧
      (dir = .Backward → cs.Pairwise (· > ·) ∧ ∀ c ∈ cs, c < st.val ∧ ∀ t, upto = .At t → t.val < c) ∧
      chunk.val.length ≤ min lim.val 1000 := by
  simp only [transition, api_message.get_message_events_route, api_message.get_messages] at h
  h5i_invert h
  all_goals (obtain ⟨events, scanned⟩ := x_2; simp only [uncurry_apply_pair] at h; h5i_invert h)
  all_goals (try simp only at hfrom1); all_goals (try simp only at hit)
  all_goals
    simp only [Reply.Messages.injEq] at h
    obtain ⟨rfl, rfl, rfl⟩ := h
    have hlim := bounded_le hlimit1
    first | have hI := itok_fwd hit1 hit | have hI := itok_bwd hit1 hit
    obtain ⟨cs, h1, h2, h3, h4⟩ := messages_core s hk hs _ _ _ _ _ _ _ _ _ _ _ _ _ hI hx_2 hv
    refine ⟨cs, finish ?_ hlim h1 h2 h3 h4⟩
    intro t ht; cases ht <;> rfl

end tuwunel_kernel.Verified.TuwunelMessagesOrdered
