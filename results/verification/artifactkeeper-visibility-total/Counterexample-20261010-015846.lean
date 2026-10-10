import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit
namespace artifactkeeper_kernel.Counterexample

@[simp] lemma deref_val {α : Type} (v : alloc.vec.Vec α) : v.deref.val = v.val := by
  simp [alloc.vec.Vec.deref, alloc.vec.Vec.val]

lemma bytes_eq_self (s : Slice U8) : strs.bytes_eq s s = ok true := by
  apply eq_ok_of_spec
  unfold strs.bytes_eq
  simp only [bne_self_eq_false, Bool.false_eq_true, if_false]
  unfold strs.bytes_eq_loop
  apply loop_idx_spec _ id s.length (fun _ => True) (fun b => b = true) ?_
    0#usize trivial (by simp)
  intro i _ hi
  unfold strs.bytes_eq_loop.body
  step* <;> (repeat' (first | step | split)) <;> simp_all <;> scalar_tac

lemma bytes_eq_same (a b : Slice U8) (h : a.val = b.val) : strs.bytes_eq a b = ok true := by
  have := Slice.ext a b h
  subst b
  exact bytes_eq_self a

@[step] lemma find_byte_spec (s : Slice U8) (b : U8) :
    strs.find_byte s b ⦃ o => o.map (fun i => i.val) = s.val.findIdx? (fun x => x == b) ⦄ := by
  unfold strs.find_byte strs.find_byte_loop
  apply WP.spec_mono (loop_search s.val (fun x => x == b)
    (fun (o : Option Usize) => o.map (fun i => i.val)) (fun i _ => some i)
    none _ ?_ 0#usize (by simp))
  · intro o ho
    exact search_findIdx _ _ _ ho
  · intro i hi
    unfold strs.find_byte_loop.body
    h5i_step

@[step] lemma sub_spec (s : Slice U8) (a b : Usize)
    (hab : a.val ≤ b.val) (hb : b.val ≤ s.length) :
    strs.sub s a b ⦃ v => v.val = (s.val.take b.val).drop a.val ⦄ := by
  unfold strs.sub strs.sub_loop
  apply WP.spec_mono (loop_fold (s.val.take b.val)
    (fun (v : alloc.vec.Vec U8) => v.val) (fun v x => v ++ [x])
    (fun v i => v.length ≤ i) _ ?_ (alloc.vec.Vec.new U8) a ?_ ?_)
  · intro v hv
    rw [foldl_snoc] at hv
    simpa only [vec_new_val, List.nil_append] using hv
  · intro v i hi hI
    unfold strs.sub_loop.body
    dsimp only
    have hn : (s.val.take b.val).length = b.val := by simp [Nat.min_eq_left hb]
    rw [hn] at hi
    step* <;> (repeat' (first | step | split))
    all_goals simp only [FoldStep]
    all_goals try (simp_all [List.getElem_take]; scalar_tac)
    all_goals scalar_tac

  · simpa only [List.length_take, Nat.min_eq_left hb] using hab
  · simp [alloc.vec.Vec.new]

lemma push_length {α : Type} {v w : alloc.vec.Vec α} {x : α}
    (h : alloc.vec.Vec.push v x = ok w) : w.length = v.length + 1 := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · have he := result_ok_inj h
    subst w
    simp
  · simp at h

lemma latin1_length {v w : alloc.vec.Vec U8}
    (h : strs.push_latin1 v 128#u8 = ok w) : w.length = v.length + 2 := by
  unfold strs.push_latin1 at h
  simp only [show ¬ (128#u8 < 128#u8) from by decide, if_false] at h
  h5i_invert h
  have h1 := push_length hout1
  have h2 := push_length h
  omega

lemma decode_length (s : Slice U8) (n : Nat) (hs : s.val = List.replicate n 128#u8)
    {out : alloc.vec.Vec U8} (h : paths.decode_ticket s = ok out) : out.length = 2 * n := by
  unfold paths.decode_ticket paths.decode_ticket_loop at h
  apply loop_ok
    (fun ((v, i) : alloc.vec.Vec U8 × Usize) => paths.decode_ticket_loop.body s v i)
    (fun ((v, i) : alloc.vec.Vec U8 × Usize) => i.val ≤ n ∧ v.length = 2 * i.val)
    (fun (v : alloc.vec.Vec U8) => v.length = 2 * n)
    (fun ((_, i) : alloc.vec.Vec U8 × Usize) => n - i.val) ?_ _ _ ?_ h
  · rintro ⟨v, i⟩ r ⟨hi, hv⟩ hr
    unfold paths.decode_ticket_loop.body at hr
    dsimp only at hr
    split at hr
    · rename_i hc
      obtain ⟨b, hb, hr⟩ := bind_eq_ok.mp hr
      have hm := slice_index_ok_mem hb
      rw [hs] at hm
      have hb' : b = 128#u8 := (List.mem_replicate.mp hm).2
      subst b
      simp only [show ¬(128#u8 = 43#u8) from by decide,
        show ¬(128#u8 = 37#u8) from by decide, if_false] at hr
      h5i_invert hr
      have ho := latin1_length hout1
      have ha := add_ok_val hi2
      have hn : s.length = n := by simp [hs]
      simp only
      scalar_tac
    · rename_i hc
      have he := result_ok_inj hr
      subst r
      have hn : s.length = n := by simp [hs]
      simp only
      scalar_tac
  · simp [alloc.vec.Vec.new]

def oversizedTicketLength : Nat := Usize.max / 2 + 1

lemma ticket_input_fits : oversizedTicketLength + 7 < Usize.max := by
  have := usize_max_ge
  unfold oversizedTicketLength
  omega

def oversizedTicket : Slice U8 :=
  Slice.from (List.replicate oversizedTicketLength 128#u8)
    (by simp only [List.length_replicate]; have := ticket_input_fits; omega)

def oversizedQuery : alloc.vec.Vec U8 :=
  vecOf ([116#u8, 105#u8, 99#u8, 107#u8, 101#u8, 116#u8, 61#u8] ++
    List.replicate oversizedTicketLength 128#u8)
    (by simp only [List.length_append, List.length_cons, List.length_nil,
        List.length_replicate]; have := ticket_input_fits; omega)

/-- GET /v2/r, no credentials, and a query consisting of `ticket=` and the long ticket. -/
def oversizedRequest : http.Request := {
  method := .Get
  path := vecOf [47#u8, 118#u8, 50#u8, 47#u8, 114#u8]
  query := some oversizedQuery
  headers := alloc.vec.Vec.new _
}

theorem request_meets_precondition :
    oversizedRequest.path.length < Usize.max ∧
    (∀ q, oversizedRequest.query = some q → q.length < Usize.max) ∧
    ∀ h ∈ oversizedRequest.headers.val,
      h.1.length < Usize.max ∧ h.2.length < Usize.max := by
  refine ⟨?_, ?_, ?_⟩
  · simp only [oversizedRequest, alloc.vec.Vec.length, vecOf_val,
      List.length_cons, List.length_nil]
    exact usize_lt_max (by decide)
  · intro q h
    have hq : q = oversizedQuery := (Option.some.inj h).symm
    subst q
    simpa [oversizedQuery, alloc.vec.Vec.length, Nat.add_comm, Nat.add_left_comm,
      Nat.add_assoc] using ticket_input_fits
  · simp [oversizedRequest, alloc.vec.Vec.new]

lemma query_find_equals (s : Slice U8) (hs : s.val = oversizedQuery.val) :
    strs.find_byte s 61#u8 = ok (some 6#usize) := by
  apply eq_ok_of_spec
  apply WP.spec_mono (find_byte_spec s 61#u8)
  intro o ho
  rw [hs] at ho
  have he : o.map (fun i => i.val) = some 6 := by
    simpa [oversizedQuery, List.findIdx?_cons] using ho
  cases o with
  | none => simp at he
  | some i =>
    simp only [Option.map_some, Option.some.injEq] at he
    have : i = 6#usize := by scalar_tac
    simp [this]

lemma query_no_ampersand : ∀ b ∈ oversizedQuery.val, b ≠ 38#u8 := by
  intro b hb
  simp only [oversizedQuery, vecOf_val, List.mem_append, List.mem_cons,
    List.not_mem_nil, or_false, List.mem_replicate] at hb
  rcases hb with hb | ⟨_, hb⟩
  · rcases hb with rfl | rfl | rfl | rfl | rfl | rfl | rfl <;> decide
  · subst b; decide

lemma query_pair_at_end :
    paths.find_ticket_pair_loop.body (alloc.vec.Vec.deref oversizedQuery)
      0#usize (alloc.vec.Vec.len oversizedQuery) =
      ok (ControlFlow.done (some (0#usize, alloc.vec.Vec.len oversizedQuery))) := by
  apply eq_ok_of_spec
  unfold paths.find_ticket_pair_loop.body
  have hlen : oversizedQuery.deref.len = oversizedQuery.len := by
    apply UScalar.eq_of_val_eq
    simp [deref_val]
  simp only [hlen, le_refl, if_true]
  step
  have hp : pair.val = oversizedQuery.val := by
    simpa [deref_val] using pair_post
  rw [query_find_equals pair.deref (by simpa only [deref_val] using hp)]
  simp only [bind_tc_ok, bind_ok]
  step
  · change 6 ≤ pair.deref.val.length
    simp only [deref_val, hp]
    have hn : oversizedQuery.length = oversizedTicketLength + 7 := by
      simp [oversizedQuery, Nat.add_comm, Nat.add_left_comm, Nat.add_assoc]
    change 6 ≤ oversizedQuery.length
    rw [hn]
    omega
  step
  rw [bytes_eq_same key.deref s2 (by
    simp only [deref_val, hp] at key_post
    simp [key_post, s2_post, oversizedQuery, deref_val,
      Array.to_slice, Array.make])]
  simp [hlen]

lemma query_pair_found :
    paths.find_ticket_pair oversizedQuery.deref =
      ok (some (0#usize, oversizedQuery.len)) := by
  apply eq_ok_of_spec
  unfold paths.find_ticket_pair paths.find_ticket_pair_loop
  apply loop_idx_spec _ (fun (p : Usize × Usize) => p.2) oversizedQuery.length
    (fun p => p.1 = 0#usize)
    (fun o => o = some (0#usize, oversizedQuery.len)) ?_ (0#usize, 0#usize)
    rfl (by simp)
  rintro ⟨start, i⟩ hstart hi
  dsimp only at hstart hi ⊢
  subst start
  by_cases he : i = oversizedQuery.len
  · subst i
    rw [query_pair_at_end]
    simp
  · have hlen : oversizedQuery.deref.len = oversizedQuery.len := by
      apply UScalar.eq_of_val_eq; simp
    have hlt : i < oversizedQuery.len := by scalar_tac
    unfold paths.find_ticket_pair_loop.body
    simp only [hlen, show i ≤ oversizedQuery.len from le_of_lt hlt, if_true, he, if_false]
    step as ⟨b, hb⟩
    simp only [deref_val] at hb
    have hmem : b ∈ oversizedQuery.val := by
      rw [hb]
      exact List.getElem_mem _
    have hne := query_no_ampersand b hmem
    simp only [hne, if_false]
    step
    scalar_tac

/-- The query can fit the stated input bound while ticket decoding cannot succeed. -/
theorem ticket_decoding_not_total :
    oversizedTicket.length + 7 < Usize.max ∧
    ¬ ∃ out, paths.decode_ticket oversizedTicket = ok out := by
  constructor
  · simpa [oversizedTicket] using ticket_input_fits
  · rintro ⟨out, h⟩
    have hl := decode_length oversizedTicket oversizedTicketLength (by simp [oversizedTicket]) h
    have hb := out.property
    unfold oversizedTicketLength at hl
    dsimp only [alloc.vec.Vec.length] at hl
    omega

theorem ticket_extraction_not_total :
    ¬ ∃ t, paths.extract_ticket_from_query (some oversizedQuery) = ok t := by
  rintro ⟨t, h⟩
  unfold paths.extract_ticket_from_query at h
  simp only [query_pair_found, bind_tc_ok, bind_ok] at h
  obtain ⟨pair, hp, h⟩ := bind_eq_ok.mp h
  have hpval : pair.val = oversizedQuery.val := by
    have hs := post_of_ok (sub_spec oversizedQuery.deref 0#usize oversizedQuery.len
      (by scalar_tac) (by simp)) hp
    simpa using hs
  rw [query_find_equals pair.deref (by simpa using hpval)] at h
  have hadd : 6#usize + 1#usize = ok 7#usize := by
    apply eq_ok_of_spec
    step*
  simp only [bind_tc_ok, bind_ok, hadd] at h
  obtain ⟨raw, hraw, h⟩ := bind_eq_ok.mp h
  have hplen : pair.length = oversizedTicketLength + 7 := by
    simp [alloc.vec.Vec.length, hpval, oversizedQuery, Nat.add_comm, Nat.add_left_comm,
      Nat.add_assoc]
  have hrval : raw.val = List.replicate oversizedTicketLength 128#u8 := by
    have hs := post_of_ok (sub_spec pair.deref 7#usize pair.len
      (by simp only [alloc.vec.Vec.len_val]; change 7 ≤ pair.length; rw [hplen]; omega)
      (by simp)) hraw
    simpa [hpval, oversizedQuery] using hs
  have hrlen : raw.length = oversizedTicketLength := by simp [alloc.vec.Vec.length, hrval]
  have hnz : raw.len ≠ 0#usize := by
    intro he
    have heval := congrArg UScalar.val he
    simp only [alloc.vec.Vec.len_val] at heval
    have hn : 0 < oversizedTicketLength := by unfold oversizedTicketLength; omega
    scalar_tac
  simp only [hnz, if_false] at h
  obtain ⟨decoded, hd, _⟩ := bind_eq_ok.mp h
  have hl := decode_length raw.deref oversizedTicketLength (by simpa using hrval) hd
  have hb := decoded.property
  dsimp only [alloc.vec.Vec.length] at hl
  unfold oversizedTicketLength at hl
  omega

def trimmedPath : alloc.vec.Vec U8 := vecOf [118#u8, 50#u8, 47#u8, 114#u8]

@[step] lemma trim_loop_spec (s : Slice U8) (c : U8) :
    strs.trim_start_byte_loop s c 0#usize ⦃ a =>
      a.val = (s.val.takeWhile (fun x => x == c)).length ∧ a.val ≤ s.length ⦄ := by
  unfold strs.trim_start_byte_loop
  apply WP.spec_mono (loop_search s.val (fun x => !(x == c))
    (fun (a : Usize) => a.val) (fun i _ => i) s.length _ ?_ 0#usize (by simp))
  · intro a ha
    rw [searchFrom_index] at ha
    simp only [UScalar.ofNatCore_val_eq, Nat.zero_min, List.drop_zero, Bool.not_not,
      Nat.zero_add] at ha
    refine ⟨ha, ?_⟩
    rw [ha]
    exact (List.takeWhile_prefix _).length_le
  · intro i hi
    unfold strs.trim_start_byte_loop.body
    h5i_step

lemma trim_path : strs.trim_start_byte oversizedRequest.path.deref 47#u8 = ok trimmedPath := by
  apply eq_ok_of_spec
  unfold strs.trim_start_byte
  step*
  simp_all [oversizedRequest, trimmedPath, alloc.vec.Vec.eq_iff]

@[step] lemma split_loop_spec (s : Slice U8) (sep : U8) :
    strs.split_loop s sep (alloc.vec.Vec.new _) (alloc.vec.Vec.new _) 0#usize ⦃ p =>
      (p.1.val.map (fun v => v.val), p.2.val) = s.val.foldl (splitStep sep) ([], []) ∧
      p.1.length + p.2.length ≤ s.length ⦄ := by
  unfold strs.split_loop
  apply WP.spec_mono (loop_fold2 s.val
    (fun (o : alloc.vec.Vec (alloc.vec.Vec U8)) (c : alloc.vec.Vec U8) =>
      (o.val.map (fun v => v.val), c.val)) (splitStep sep)
    (fun o c i => o.length + c.length ≤ i) _ ?_ (alloc.vec.Vec.new _)
    (alloc.vec.Vec.new _) 0#usize (by simp) (by simp [alloc.vec.Vec.new]))
  · intro p hp
    simp only [vec_new_val, List.map_nil, List.drop_zero] at hp
    exact hp
  · intro o c i hi hI
    unfold strs.split_loop.body
    dsimp only
    h5i_steps
    all_goals simp only [FoldStep2, splitStep]
    all_goals try simp_all [alloc.vec.Vec.new]
    all_goals scalar_tac

def pathSegments : alloc.vec.Vec (alloc.vec.Vec U8) :=
  vecOf [vecOf [118#u8, 50#u8], vecOf [114#u8]]

lemma vec_list_ext {xs ys : List (alloc.vec.Vec U8)}
    (h : xs.map (fun v => v.val) = ys.map (fun v => v.val)) : xs = ys := by
  induction xs generalizing ys with
  | nil => cases ys <;> simp_all
  | cons x xs ih =>
    cases ys with
    | nil => simp at h
    | cons y ys =>
      simp only [List.map_cons, List.cons.injEq] at h
      have hxy := (alloc.vec.Vec.eq_iff x y).mpr h.1
      subst y
      rw [ih h.2]

lemma split_path : strs.split trimmedPath.deref 47#u8 = ok pathSegments := by
  apply eq_ok_of_spec
  have hg := usize_max_ge
  unfold strs.split
  step*
  all_goals try (simp_all [trimmedPath]; scalar_tac)
  apply (alloc.vec.Vec.eq_iff _ _).mpr
  apply vec_list_ext
  simp_all [trimmedPath, pathSegments, splitStep]
  obtain ⟨v, hv, hval⟩ := out_post.1
  simp [hv, hval]

@[step] lemma bytes_eq_ne_length_spec (a b : Slice U8) (h : a.length ≠ b.length) :
    strs.bytes_eq a b ⦃ r => r = false ⦄ := by
  unfold strs.bytes_eq
  have hn : a.len ≠ b.len := by
    intro he
    apply h
    simpa using congrArg UScalar.val he
  simp [hn]

@[step] lemma seg0_spec (p : Slice U8) (hp : p.length ≠ 2) :
    strs.seg_is pathSegments.deref 0#usize p ⦃ b => b = false ⦄ := by
  unfold strs.seg_is
  step* <;> (repeat' (first | step | split))
  all_goals simp_all [pathSegments, hp]
  all_goals scalar_tac

@[step] lemma contains_byte_spec (s : Slice U8) (b : U8) :
    strs.contains_byte s b ⦃ r => r = s.val.any (fun x => x == b) ⦄ := by
  unfold strs.contains_byte strs.contains_byte_loop
  h5i_search_any s.val (fun x => x == b)

def repoKey : alloc.vec.Vec U8 := vecOf [114#u8]

lemma repo_key_eq : paths.extract_repo_key oversizedRequest.path.deref = ok repoKey := by
  apply eq_ok_of_spec
  unfold paths.extract_repo_key
  rw [trim_path]
  simp only [bind_ok]
  rw [split_path]
  simp only [bind_ok]
  h5i_steps
  all_goals try simp_all [pathSegments, repoKey, Array.to_slice, Array.make]
  all_goals try scalar_tac
  unfold paths.percent_decode_path_segment
  step as ⟨b, hb⟩
  simp at hb
  simp only [hb, Bool.false_eq_true, if_false]
  step*
  simp_all [alloc.vec.Vec.eq_iff, alloc.vec.Vec.val, alloc.vec.Vec.deref, vecOf]
  apply WP.spec_mono (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 _ (by intros; rfl))
  intro v hv
  rw [← hv]

@[step] lemma header_str_empty_spec
    (headers : Slice (alloc.vec.Vec U8 × alloc.vec.Vec U8)) (key : Slice U8)
    (h : headers.val = []) : http.header_str headers key ⦃ o => o = none ⦄ := by
  unfold http.header_str http.header_get http.header_get_loop
  rw [loop]
  unfold http.header_get_loop.body
  have hn : headers.len = 0#usize := by
    apply UScalar.eq_of_val_eq
    simp [h]
  simp [hn]

lemma no_conda_token : paths.extract_conda_url_token oversizedRequest.path.deref = ok none := by
  apply eq_ok_of_spec
  unfold paths.extract_conda_url_token
  rw [trim_path]
  simp only [bind_ok]
  rw [split_path]
  simp only [bind_ok]
  h5i_steps
  all_goals simp_all [pathSegments, Array.to_slice, Array.make]
  all_goals scalar_tac

h5i_derive_eq Method Method.Insts.CoreCmpPartialEqMethod.eq

lemma no_header_token : http.extract_token oversizedRequest = ok http.ExtractedToken.None := by
  apply eq_ok_of_spec
  unfold http.extract_token
  step*
  all_goals try simp [oversizedRequest, alloc.vec.Vec.new]
  unfold http.session_cookie_token
  step*
  all_goals simp_all [oversizedRequest, alloc.vec.Vec.new]

lemma no_visibility_token :
    http.extract_visibility_token oversizedRequest = ok http.ExtractedToken.None := by
  unfold http.extract_visibility_token
  rw [no_header_token]
  simp only [bind_ok]
  rw [no_conda_token]
  simp only [bind_ok]
  have hnuget : http.extract_nuget_push_api_key oversizedRequest = ok none := by
    simp [http.extract_nuget_push_api_key, oversizedRequest,
      core.cmp.PartialEq.ne.trait_default, Method.Insts.CoreCmpPartialEqMethod,
      core.cmp.PartialEq.ne.default,
      Method.Insts.CoreCmpPartialEqMethod.eq, Method.read_discriminant]
  rw [hnuget]
  simp

def counterexampleRepo : tables.Repository := {
  id := 1#u64
  key := repoKey
  visibility := some Visibility.Public
  project_id := none
}

def counterexampleDb : tables.Db := {
  users := alloc.vec.Vec.new _
  groups := alloc.vec.Vec.new _
  members := alloc.vec.Vec.new _
  repositories := vecOf [counterexampleRepo]
  permissions := alloc.vec.Vec.new _
  roles := alloc.vec.Vec.new _
  role_assignments := alloc.vec.Vec.new _
  tickets := alloc.vec.Vec.new _
  failing := alloc.vec.Vec.new _
}

lemma db_fails_false (q : tables.Query) : tables.Db.fails counterexampleDb q = ok false := by
  unfold tables.Db.fails tables.Db.fails_loop
  rw [loop]
  unfold tables.Db.fails_loop.body
  have hn : counterexampleDb.failing.len = 0#usize := by
    apply UScalar.eq_of_val_eq
    simp [counterexampleDb, alloc.vec.Vec.new]
  simp [hn]

lemma lookup_repo_eq : middleware.lookup_repo counterexampleDb repoKey.deref =
    ok (some (1#u64, Visibility.Public)) := by
  have hindex : counterexampleDb.repositories.index_usize 0#usize = ok counterexampleRepo := by
    apply eq_ok_of_spec
    step*
    all_goals simp_all [counterexampleDb]
  have hn : counterexampleDb.repositories.len = 1#usize := by
    apply UScalar.eq_of_val_eq
    simp [counterexampleDb]
  apply eq_ok_of_spec
  unfold middleware.lookup_repo
  rw [db_fails_false]
  simp only [bind_ok, Bool.false_eq_true, if_false]
  unfold middleware.lookup_repo_loop
  rw [loop]
  unfold middleware.lookup_repo_loop.body
  dsimp only
  simp only [hn, show 0#usize < 1#usize from by decide, if_true]
  simp only [alloc.vec.Vec.index_slice_index]
  rw [hindex]
  simp only [bind_ok, counterexampleRepo]
  rw [bytes_eq_self]
  simp

theorem middleware_not_total (o : trusted.Oracle) (ip : Option net.IpAddr) :
    ¬ ∃ y, middleware.repo_visibility_middleware counterexampleDb o ip oversizedRequest = ok y := by
  rintro ⟨y, h⟩
  unfold middleware.repo_visibility_middleware at h
  dsimp only at h
  rw [repo_key_eq] at h
  have hk : repoKey.len ≠ 0#usize := by
    intro he
    have := congrArg UScalar.val he
    simp [repoKey] at this
  simp only [bind_ok, hk, if_false] at h
  rw [lookup_repo_eq] at h
  simp only [bind_ok] at h
  obtain ⟨non_mutating, hnon_mutating, h⟩ := bind_eq_ok.mp h
  have hpost : Method.Insts.CoreCmpPartialEqMethod.eq oversizedRequest.method Method.Post = ok false := by
    simp [oversizedRequest, Method.Insts.CoreCmpPartialEqMethod.eq, Method.read_discriminant]
  rw [hpost] at h
  simp only [bind_ok, Bool.false_eq_true, if_false] at h
  have hwrite : paths.is_write_method oversizedRequest.method = ok false := by
    simp [paths.is_write_method, oversizedRequest]
  rw [hwrite] at h
  simp only [bind_ok, Bool.false_eq_true, if_false] at h
  rw [no_visibility_token] at h
  simp only [bind_ok, resolve.try_resolve_auth_outcome, Bool.false_eq_true, if_false,
    core.option.Option.is_none] at h
  obtain ⟨r, hr, _⟩ := bind_eq_ok.mp h
  obtain ⟨ticketResult, hticket, _⟩ := bind_eq_ok.mp hr
  unfold resolve.try_ticket at hticket
  obtain ⟨t, ht, _⟩ := bind_eq_ok.mp hticket
  exact ticket_extraction_not_total ⟨t, ht⟩

/-- The universal statement requested in `Solution.lean` is false. -/
theorem repo_visibility_total_is_false :
    ¬ (∀ (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
      (req : http.Request),
      (req.path.length < Usize.max ∧
        (∀ q, req.query = some q → q.length < Usize.max) ∧
        ∀ h ∈ req.headers.val,
          h.1.length < Usize.max ∧ h.2.length < Usize.max) →
      ∃ y, middleware.repo_visibility_middleware db o ip req = ok y) := by
  intro total
  let o : trusted.Oracle := {
    jwt := alloc.vec.Vec.new _
    api_tokens := alloc.vec.Vec.new _
    passwords := alloc.vec.Vec.new _
    base64 := alloc.vec.Vec.new _
    ip := alloc.vec.Vec.new _
  }
  exact middleware_not_total o none
    (total counterexampleDb o none oversizedRequest request_meets_precondition)

#print axioms repo_visibility_total_is_false

end artifactkeeper_kernel.Counterexample
