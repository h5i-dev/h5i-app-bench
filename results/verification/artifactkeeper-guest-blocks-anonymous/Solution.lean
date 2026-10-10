import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Solution

set_option maxHeartbeats 2000000
set_option maxRecDepth 4096

theorem bytes_eq_true (a b : Slice U8) (h : strs.bytes_eq a b = ok true) :
    a.val = b.val := by
  unfold strs.bytes_eq at h
  h5i_invert h with hcond
  have hlen : a.val.length = b.val.length := by scalar_tac
  unfold strs.bytes_eq_loop at h
  have hs := loop_idx_ok (strs.bytes_eq_loop.body a b) id a.val.length
    (fun i => ∀ j (hj : j < i.val) (ha : j < a.val.length), a.val[j] = b.val[j]'(by omega))
    (fun r => r = true → a.val = b.val) ?_ 0#usize true (by simp) (by simp) h
  · exact hs rfl
  · intro i r hi hn hr
    dsimp only [id] at *
    unfold strs.bytes_eq_loop.body at hr
    h5i_invert hr with hcond
    · simp
    · have ⟨ha, hea⟩ := slice_index_ok hi2
      have ⟨hb, heb⟩ := slice_index_ok hi3
      have he : i2 = i3 := by scalar_tac
      have hadd := add_ok_val hi4
      simp only [UScalar.ofNatCore_val_eq] at hadd
      refine ⟨?_, ?_, ?_⟩
      · intro j hj hja
        by_cases hj' : j < i.val
        · exact hi j hj' hja
        · have : j = i.val := by scalar_tac
          subst j
          exact hea.trans (he.trans heb.symm)
      · scalar_tac
      · scalar_tac
    · intro _
      apply List.ext_getElem hlen
      intro j ha hb
      exact hi j (by scalar_tac) ha

theorem starts_with_true (s p : Slice U8) (h : strs.starts_with s p = ok true) :
    p.val <+: s.val := by
  unfold strs.starts_with strs.starts_with_at at h
  h5i_invert h with hcond
  have hlen : p.val.length ≤ s.val.length := by
    have := sub_ok_val hi2
    scalar_tac
  unfold strs.starts_with_at_loop at h
  have hs := loop_idx_ok (strs.starts_with_at_loop.body s 0#usize p) id p.val.length
    (fun i => ∀ j (hj : j < i.val) (hp : j < p.val.length), p.val[j] = s.val[j]'(by omega))
    (fun r => r = true → p.val <+: s.val) ?_ 0#usize true (by simp) (by simp) h
  · exact hs rfl
  · intro i r hi hn hr
    dsimp only [id] at *
    unfold strs.starts_with_at_loop.body at hr
    h5i_invert hr with hcond
    · simp
    · have hidx := add_ok_val hi2_1
      simp only [UScalar.ofNatCore_val_eq, Nat.zero_add] at hidx
      have ⟨hs, hes⟩ := slice_index_ok hi3
      have ⟨hp, hep⟩ := slice_index_ok hi4
      have he : i3 = i4 := by scalar_tac
      have hadd := add_ok_val hi5
      simp only [UScalar.ofNatCore_val_eq] at hadd
      refine ⟨?_, by omega, by omega⟩
      intro j hj hjp
      by_cases hj' : j < i.val
      · exact hi j hj' hjp
      · have : j = i.val := by omega
        subst j
        simpa [hidx] using hep.trans (he.symm.trans hes.symm)
    · intro _
      rw [prefix_iff_take]
      refine ⟨hlen, ?_⟩
      apply List.ext_getElem (by simp; omega)
      intro j hjs hjp
      simp only [List.getElem_take]
      exact (hi j (by scalar_tac) hjp).symm

theorem header_get_absent (headers : Slice ((alloc.vec.Vec U8) × (alloc.vec.Vec U8)))
    («name» : Slice U8) (ha : ∀ x ∈ headers.val, x.1.val ≠ «name».val)
    (v : Option (alloc.vec.Vec U8)) (h : http.header_get headers «name» = ok v) : v = none := by
  unfold http.header_get http.header_get_loop at h
  apply loop_idx_ok (http.header_get_loop.body headers «name») id headers.val.length
    (fun _ => True) (fun v => v = none) ?_ 0#usize v trivial (by simp) h
  intro i r _ hn hr
  dsimp only [id] at *
  unfold http.header_get_loop.body at hr
  h5i_invert hr with hcond
  · obtain ⟨key, value⟩ := x
    obtain ⟨b, hb, hr⟩ := bind_tc_eq_ok.1 hr
    cases b
    · simp only [Bool.false_eq_true, ↓reduceIte] at hr
      h5i_invert hr
      have hadd := add_ok_val hi2
      have ⟨hlt, _⟩ := slice_index_ok hx
      simp only [UScalar.ofNatCore_val_eq] at hadd
      exact ⟨trivial, by omega, by omega⟩
    · have he := bytes_eq_true _ _ hb
      exact False.elim (ha (key, value) (slice_index_ok_mem hx)
        (by simpa [alloc.vec.Vec.deref] using he))
  · rfl

theorem header_str_absent (headers : Slice ((alloc.vec.Vec U8) × (alloc.vec.Vec U8)))
    («name» : Slice U8) (ha : ∀ x ∈ headers.val, x.1.val ≠ «name».val)
    (v : Option (alloc.vec.Vec U8)) (h : http.header_str headers «name» = ok v) : v = none := by
  unfold http.header_str at h
  obtain ⟨x, hx, h⟩ := bind_tc_eq_ok.1 h
  have := header_get_absent headers «name» ha x hx
  subst x
  exact (result_ok_inj h).symm

theorem allowlisted_true (path : Slice U8) (h : paths.is_allowlisted path = ok true) :
    Allowlisted (nats path.val) := by
  unfold paths.is_allowlisted at h
  simp only [lift, bind_ok] at h
  repeat' (obtain ⟨b, hb, h⟩ := bind_tc_eq_ok.1 h
           cases b <;> simp only [Bool.false_eq_true, ↓reduceIte] at h)
  all_goals
    try
      have he := congrArg nats (bytes_eq_true _ _ hb)
      simp [nats, Array.to_slice, Array.make] at he
      unfold Allowlisted
      left
      simp only [nats]
      rw [he]
      decide +kernel
  all_goals
    try
      have he := congrArg nats (bytes_eq_true _ _ h)
      simp [nats, Array.to_slice, Array.make] at he
      unfold Allowlisted
      left
      simp only [nats]
      rw [he]
      decide +kernel
  all_goals
    have he := (starts_with_true _ _ hb).map (fun x => x.val)
    simp [Array.to_slice, Array.make] at he
    unfold Allowlisted
    right
    first
    | (left; convert he using 1 <;> first | rfl | decide +kernel)
    | (right; convert he using 1 <;> first | rfl | decide +kernel)

theorem push_val {α} (v w : alloc.vec.Vec α) (x : α)
    (h : alloc.vec.Vec.push v x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  dsimp +zeta only at h
  split at h
  · have he := result_ok_inj h
    subst w
    simp
  · simp at h

theorem sub_tail (s : Slice U8) (a : Usize) (ha : a.val ≤ s.val.length)
    (v : alloc.vec.Vec U8) (h : strs.sub s a (Slice.len s) = ok v) :
    v.val = s.val.drop a.val := by
  unfold strs.sub strs.sub_loop at h
  apply loop_idx_ok (fun (out, i) => strs.sub_loop.body s (Slice.len s) out i)
    Prod.snd s.val.length (fun (out, i) => out.val ++ s.val.drop i.val = s.val.drop a.val)
    (fun v => v.val = s.val.drop a.val) ?_ (alloc.vec.Vec.new U8, a) v
    (by simp [alloc.vec.Vec.new]) ha h
  rintro ⟨out, i⟩ r hi hn hr
  dsimp only at hi hn ⊢
  unfold strs.sub_loop.body at hr
  h5i_invert hr with hcond
  · have ⟨hlt, he⟩ := slice_index_ok hi2
    have hp := push_val _ _ _ hout1
    have hadd := add_ok_val hi3
    simp only [UScalar.ofNatCore_val_eq] at hadd
    refine ⟨?_, by simpa using (show i.val < i3.val by omega),
      by simpa using (show i3.val ≤ s.val.length by omega)⟩
    dsimp only
    rw [hp, hadd, List.append_assoc]
    simpa [List.drop_eq_getElem_cons hlt, he] using hi
  · have hend : s.val.length ≤ i.val := by scalar_tac
    simpa [List.drop_eq_nil_of_le hend] using hi

theorem trim_index (s : Slice U8) (c : U8) (a : Usize)
    (h : strs.trim_start_byte_loop s c 0#usize = ok a) :
    a.val ≤ s.val.length ∧ s.val.drop a.val = s.val.dropWhile (fun x => decide (x = c)) := by
  unfold strs.trim_start_byte_loop at h
  apply loop_idx_ok (strs.trim_start_byte_loop.body s c) id s.val.length
    (fun i => (s.val.drop i.val).dropWhile (fun x => decide (x = c)) =
      s.val.dropWhile (fun x => decide (x = c)))
    (fun a => a.val ≤ s.val.length ∧ s.val.drop a.val = s.val.dropWhile (fun x => decide (x = c)))
    ?_ 0#usize a (by simp) (by simp) h
  intro i r hi hn hr
  dsimp only [id] at *
  unfold strs.trim_start_byte_loop.body at hr
  h5i_invert hr with hcond
  · have ⟨hlt, he⟩ := slice_index_ok hi1
    have hadd := add_ok_val ha1
    simp only [UScalar.ofNatCore_val_eq] at hadd
    refine ⟨?_, by omega, by omega⟩
    rw [hadd]
    simpa [List.drop_eq_getElem_cons hlt, he, hcond_1] using hi
  · have ⟨hlt, he⟩ := slice_index_ok hi1
    exact ⟨hn, by simpa [List.drop_eq_getElem_cons hlt, he, hcond_1] using hi⟩
  · have hend : s.val.length ≤ i.val := by scalar_tac
    exact ⟨hn, by simpa [List.drop_eq_nil_of_le hend] using hi⟩

theorem trim_start_val (s : Slice U8) (c : U8) (v : alloc.vec.Vec U8)
    (h : strs.trim_start_byte s c = ok v) :
    v.val = s.val.dropWhile (fun x => decide (x = c)) := by
  unfold strs.trim_start_byte at h
  obtain ⟨a, ha, h⟩ := bind_tc_eq_ok.1 h
  have ⟨hle, he⟩ := trim_index s c a ha
  exact (sub_tail s a hle v h).trans he

theorem split_val (s : Slice U8) (sep : U8) (v : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : strs.split s sep = ok v) :
    v.val.map (·.val) = s.val.splitOnP (fun x => decide (x = sep)) := by
  unfold strs.split at h
  obtain ⟨pair, hp, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨out, cur⟩ := pair
  have hv := push_val _ _ _ h
  rw [hv, List.map_append, List.map_cons, List.map_nil]
  unfold strs.split_loop at hp
  apply loop_idx_ok (fun (out, cur, i) => strs.split_loop.body s sep out cur i)
    (fun x => x.2.2) s.val.length
    (fun (out, cur, i) => out.val.map (·.val) ++
      List.splitOnPPrepend (fun x => decide (x = sep)) (s.val.drop i.val) cur.val.reverse =
      s.val.splitOnP (fun x => decide (x = sep)))
    (fun (out, cur) => out.val.map (·.val) ++ [cur.val] = s.val.splitOnP (fun x => decide (x = sep)))
    ?_ (alloc.vec.Vec.new _, alloc.vec.Vec.new _, 0#usize) (out, cur)
    (by simp [alloc.vec.Vec.new]) (by simp) hp
  rintro ⟨out, cur, i⟩ r hi hn hr
  dsimp only at hi hn ⊢
  unfold strs.split_loop.body at hr
  h5i_invert hr with hcond
  · have ⟨hlt, he⟩ := slice_index_ok hi2
    rw [List.drop_eq_getElem_cons hlt, he, List.splitOnPPrepend_cons_eq_if] at hi
    by_cases heq : i2 = sep
    · simp only [heq, ↓reduceIte] at hx
      obtain ⟨out2, hout2, hx⟩ := bind_tc_eq_ok.1 hx
      have hepair := result_ok_inj hx
      subst x
      obtain ⟨i3, hi3, hr⟩ := bind_tc_eq_ok.1 hr
      have her := result_ok_inj hr
      subst r
      have hadd := add_ok_val hi3
      simp only [UScalar.ofNatCore_val_eq] at hadd
      dsimp only
      refine ⟨?_, by omega, by omega⟩
      have hp := push_val _ _ _ hout2
      simpa [hp, hadd, heq, alloc.vec.Vec.new, List.append_assoc] using hi
    · simp only [heq, ↓reduceIte] at hx
      obtain ⟨cur2, hcur2, hx⟩ := bind_tc_eq_ok.1 hx
      have hepair := result_ok_inj hx
      subst x
      obtain ⟨i3, hi3, hr⟩ := bind_tc_eq_ok.1 hr
      have her := result_ok_inj hr
      subst r
      have hadd := add_ok_val hi3
      simp only [UScalar.ofNatCore_val_eq] at hadd
      dsimp only
      refine ⟨?_, by omega, by omega⟩
      have hp := push_val _ _ _ hcur2
      simpa [hp, hadd, heq] using hi
  · have hend : s.val.length ≤ i.val := by scalar_tac
    simpa [List.drop_eq_nil_of_le hend] using hi

theorem split_join (l : List U8) (sep : U8) :
    [sep].intercalate (l.splitOnP (fun x => decide (x = sep))) = l := by
  have he : (fun x : U8 => x == sep) = (fun x => decide (x = sep)) := by
    funext x
    by_cases h : x = sep <;> simp [h]
  simpa only [List.splitOn_eq_splitOnP, he] using (List.intercalate_splitOn (xs := l) sep)

theorem seg_is_true (segs : Slice (alloc.vec.Vec U8)) (i : Usize) (p : Slice U8)
    (h : strs.seg_is segs i p = ok true) :
    ∃ v, segs.val[i.val]? = some v ∧ v.val = p.val := by
  unfold strs.seg_is at h
  h5i_invert h
  have ⟨hi, he⟩ := slice_index_ok hv
  refine ⟨v, by simp only [List.getElem?_eq_getElem hi, he], ?_⟩
  simpa [alloc.vec.Vec.deref] using (bytes_eq_true _ _ h)

theorem conda_some_prefix (path : Slice U8) (token : alloc.vec.Vec U8)
    (h : paths.extract_conda_url_token path = ok (some token)) :
    lit "conda/" <+: (nats path.val).dropWhile (· = 47) := by
  unfold paths.extract_conda_url_token at h
  simp only [lift, bind_ok] at h
  obtain ⟨trimmed, ht, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨segments, hs, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨b, hb, h⟩ := bind_tc_eq_ok.1 h
  cases b
  · simp at h
  · simp only [↓reduceIte] at h
    have hlen : 2 ≤ segments.val.length := by
      by_contra hn
      have hlt : alloc.vec.Vec.len segments < 2#usize := by scalar_tac
      simp only [hlt, ↓reduceIte] at h
      simp at h
    have ⟨head, hhead, he⟩ := seg_is_true _ _ _ hb
    simp [Array.to_slice, Array.make, alloc.vec.Vec.deref] at he hhead
    have hsplit := split_val _ _ _ hs
    simp [alloc.vec.Vec.deref] at hsplit
    have hjoin := split_join trimmed.val 47#u8
    rw [← hsplit] at hjoin
    obtain ⟨head', rest, hseg⟩ := List.exists_cons_of_ne_nil (show segments.val ≠ [] by
      intro hh; simp [hh] at hlen)
    rw [hseg] at hhead hjoin hlen
    have hhe : head' = head := by simpa using hhead
    subst head'
    obtain ⟨second, rest', hrest⟩ := List.exists_cons_of_ne_nil (show rest ≠ [] by
      intro hh; simp [hh] at hlen)
    rw [hrest] at hjoin
    have hpre : head.val ++ [47#u8] <+: trimmed.val := by
      rw [← hjoin]
      simp only [List.map_cons, List.intercalate_cons_cons]
      exact List.prefix_append _ _
    have hn := hpre.map (fun x : U8 => x.val)
    have htrim := trim_start_val path 47#u8 trimmed ht
    rw [htrim] at hn
    have hpred : (fun x : U8 => decide (x = 47#u8)) =
        (fun x => decide (x.val = 47)) := by
      funext x
      congr 1
      exact propext (by rw [u8_eq_iff]; rfl)
    rw [hpred] at hn
    have hm : ((path.val.map (fun x => x.val)).dropWhile (fun x => decide (x = 47))) =
        (path.val.dropWhile (fun x => decide (x.val = 47))).map (fun x => x.val) :=
      List.dropWhile_map
    rw [← hm] at hn
    simp [he] at hn
    convert hn using 1 <;> first | rfl | decide +kernel

theorem no_credential_header (req : http.Request) (hc : NoCredential req) (p : Slice U8)
    (hn : nats p.val ∈ [lit "authorization", lit "x-api-key", lit "cookie", lit "x-nuget-apikey"])
    (v : Option (alloc.vec.Vec U8)) (h : http.header_str (alloc.vec.Vec.deref req.headers) p = ok v) :
    v = none := by
  apply header_str_absent _ p ?_ v h
  intro x hx he
  apply hc.1 x (by simpa [alloc.vec.Vec.deref] using hx)
  rw [he]
  exact hn

theorem session_cookie_none (req : http.Request) (hc : NoCredential req)
    (v : Option (alloc.vec.Vec U8))
    (h : http.session_cookie_token (alloc.vec.Vec.deref req.headers) = ok v) : v = none := by
  unfold http.session_cookie_token at h
  simp only [lift, bind_ok] at h
  obtain ⟨o, ho, h⟩ := bind_tc_eq_ok.1 h
  have he := no_credential_header req hc _ (by
    simp [nats, Array.to_slice, Array.make]
    decide +kernel) o ho
  subst o
  exact (result_ok_inj h).symm

theorem extract_token_none (req : http.Request) (hc : NoCredential req)
    (v : http.ExtractedToken) (h : http.extract_token req = ok v) : v = .None := by
  unfold http.extract_token at h
  simp only [lift, bind_ok] at h
  obtain ⟨o, ho, h⟩ := bind_tc_eq_ok.1 h
  have he := no_credential_header req hc _ (by
    simp [nats, Array.to_slice, Array.make]
    decide +kernel) o ho
  subst o
  obtain ⟨o, ho, h⟩ := bind_tc_eq_ok.1 h
  have he := no_credential_header req hc _ (by
    simp [nats, Array.to_slice, Array.make]
    decide +kernel) o ho
  subst o
  obtain ⟨o, ho, h⟩ := bind_tc_eq_ok.1 h
  have he := session_cookie_none req hc o ho
  subst o
  exact (result_ok_inj h).symm

theorem nuget_key_none (req : http.Request) (hc : NoCredential req)
    (v : Option (alloc.vec.Vec U8)) (h : http.extract_nuget_push_api_key req = ok v) : v = none := by
  unfold http.extract_nuget_push_api_key at h
  simp only [lift, bind_ok] at h
  obtain ⟨b, hb, h⟩ := bind_tc_eq_ok.1 h
  cases b
  · simp only [Bool.false_eq_true, ↓reduceIte] at h
    obtain ⟨b, hb, h⟩ := bind_tc_eq_ok.1 h
    cases b
    · simp only [Bool.false_eq_true, ↓reduceIte] at h
      exact (result_ok_inj h).symm
    · simp only [↓reduceIte] at h
      obtain ⟨o, ho, h⟩ := bind_tc_eq_ok.1 h
      have he := no_credential_header req hc _ (by
        simp [nats, Array.to_slice, Array.make]
        decide +kernel) o ho
      subst o
      exact (result_ok_inj h).symm
  · simp only [↓reduceIte] at h
    exact (result_ok_inj h).symm

theorem conda_token_none (req : http.Request) (hc : NoCredential req)
    (v : Option (alloc.vec.Vec U8))
    (h : paths.extract_conda_url_token (alloc.vec.Vec.deref req.path) = ok v) : v = none := by
  cases v with
  | none => rfl
  | some token =>
    exact False.elim (hc.2 (by
      simpa [alloc.vec.Vec.deref] using conda_some_prefix _ token h))

theorem visibility_token_none (req : http.Request) (hc : NoCredential req)
    (v : http.ExtractedToken) (h : http.extract_visibility_token req = ok v) : v = .None := by
  unfold http.extract_visibility_token at h
  obtain ⟨extracted, he, h⟩ := bind_tc_eq_ok.1 h
  have hn := extract_token_none req hc extracted he
  subst extracted
  simp only [bind_ok, ↓reduceIte] at h
  obtain ⟨o, ho, h⟩ := bind_tc_eq_ok.1 h
  have he := conda_token_none req hc o ho
  subst o
  obtain ⟨o, ho, h⟩ := bind_tc_eq_ok.1 h
  have he := nuget_key_none req hc o ho
  subst o
  exact (result_ok_inj h).symm

theorem guest_blocks_anonymous (o : trusted.Oracle) (req : http.Request) (auth : Option AuthExtension)
    (t : Bool) (h : middleware.guest_access_guard false o req = ok (.Next auth t))
    (hc : NoCredential req) :
    Allowlisted (nats req.path.val) := by
  unfold middleware.guest_access_guard at h
  simp only [Bool.false_eq_true, ↓reduceIte] at h
  obtain ⟨allowed, ha, h⟩ := bind_tc_eq_ok.1 h
  cases allowed
  · simp only [Bool.false_eq_true, ↓reduceIte] at h
    obtain ⟨oci, hoci, h⟩ := bind_tc_eq_ok.1 h
    obtain ⟨extracted, he, h⟩ := bind_tc_eq_ok.1 h
    have hn := visibility_token_none req hc extracted he
    subst extracted
    simp only [resolve.try_resolve_auth_outcome, bind_ok] at h
    obtain ⟨for_browser, hb, h⟩ := bind_tc_eq_ok.1 h
    cases oci <;> simp at h
  · exact (by simpa [alloc.vec.Vec.deref] using allowlisted_true _ ha)

end artifactkeeper_kernel.Solution
