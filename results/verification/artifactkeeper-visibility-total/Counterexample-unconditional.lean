import Spec
import H5iAppLib
/-!
A counterexample to unrestricted repository-visibility totality.

The request is GET x/r with a Cookie header containing Usize.max semicolons.
The byte vector is permitted by the extracted model, but splitting it requires
Usize.max + 1 segments. The final theorem proves that this request cannot
return ok, for any database, oracle, or client IP.
-/
open Aeneas Aeneas.Std Result ControlFlow artifactkeeper_kernel
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Counterexample
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096

lemma push_size {α : Type} {v v' : alloc.vec.Vec α} {x : α}
    (h : alloc.vec.Vec.push v x = ok v') :
    v'.val.length = v.val.length + 1 ∧ v.val.length < Usize.max := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · h5i_invert h
    constructor
    · simp
    · have hm : U32.max ≤ Usize.max := by
        rw [U32.max_def, Usize.max_def]
        cases System.Platform.numBits_eq <;> simp_all [U32.numBits, Usize.numBits]
      rename_i hc
      simp only [Bool.or_eq_true, decide_eq_true_eq] at hc
      omega
  · simp at h

lemma split_size (s : Slice U8) (sep : U8)
    (hs : ∀ j (hj : j < s.val.length), s.val[j] = sep)
    (v : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : strs.split s sep = ok v) : v.val.length = s.val.length + 1 := by
  unfold strs.split at h
  obtain ⟨⟨out, cur⟩, hloop, hpush⟩ := bind_tc_eq_ok.1 h
  try dsimp only at hpush
  have hi : out.val.length = s.val.length := by
    unfold strs.split_loop at hloop
    apply loop_idx_ok (idx := fun (x : alloc.vec.Vec (alloc.vec.Vec U8) × alloc.vec.Vec U8 × Usize) => x.2.2) (n := s.val.length)
      (Inv := fun x => x.1.val.length = x.2.2.val)
      (Q := fun y => y.1.val.length = s.val.length) _ _ _ _ _ _ hloop
    · rintro ⟨a, b, i⟩ r hI hn hr
      dsimp at hI hn ⊢
      unfold strs.split_loop.body at hr
      h5i_invert hr
      all_goals try scalar_tac
      have hb : i2 = sep := by
        have hv := post_of_ok (Slice.index_usize_spec s i (by scalar_tac)) hi2
        exact hv.trans (hs i.val (by scalar_tac))
      simp only [hb, if_pos rfl] at hx
      h5i_invert hx
      change (do let j ← i + 1#usize; ok (cont (out2, alloc.vec.Vec.new U8, j))) = ok r at hr
      h5i_invert hr
      have hp := push_size hout2
      dsimp only
      h5i_arith
    · simp [alloc.vec.Vec.new]
    · simp
  have hp := push_size hpush
  omega

def cookie : alloc.vec.Vec U8 := vecOf (List.replicate Usize.max 59#u8) (by simp)

lemma cookie_split_ne_ok (v : alloc.vec.Vec (alloc.vec.Vec U8)) :
    strs.split (alloc.vec.Vec.deref cookie) 59#u8 ≠ ok v := by
  intro h
  have hs : ∀ j (hj : j < (alloc.vec.Vec.deref cookie).val.length),
      (alloc.vec.Vec.deref cookie).val[j] = 59#u8 := by
    intros; simp [cookie, vecOf, alloc.vec.Vec.deref]
  have hv := split_size (alloc.vec.Vec.deref cookie) 59#u8 hs v h
  have hbound := v.property
  simp [cookie, vecOf, alloc.vec.Vec.deref] at hv
  omega

lemma cookie_ascii : http.visible_ascii (alloc.vec.Vec.deref cookie) ⦃ b => b = true ⦄ := by
  unfold http.visible_ascii http.visible_ascii_loop
  apply loop_idx_spec _ (fun i => i) Usize.max (fun _ => True) (fun b => b = true) ?_ _ trivial (by simp)
  intro i _ hi
  unfold http.visible_ascii_loop.body
  step*
  all_goals simp_all [cookie, vecOf, alloc.vec.Vec.deref]
  all_goals try scalar_tac

@[step] lemma bytes_eq_self (s : Slice U8) : strs.bytes_eq s s ⦃ b => b = true ⦄ := by
  unfold strs.bytes_eq
  simp only [bne_self_eq_false, Bool.false_eq_true, ↓reduceIte]
  unfold strs.bytes_eq_loop
  apply loop_idx_spec _ (fun i => i) s.val.length (fun _ => True) (fun b => b = true) ?_ _ trivial (by simp)
  intro i _ hi
  unfold strs.bytes_eq_loop.body
  step*
  all_goals try scalar_tac

def cookieName : alloc.vec.Vec U8 := vecOf [99#u8, 111#u8, 111#u8, 107#u8, 105#u8, 101#u8]
def cookieHeaders : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec U8) := vecOf [(cookieName, cookie)]

@[simp] lemma bytes_eq_self_eq (s : Slice U8) : strs.bytes_eq s s = ok true :=
  eq_ok_of_spec (bytes_eq_self s)

lemma header_cookie : http.header_get (alloc.vec.Vec.deref cookieHeaders)
    (alloc.vec.Vec.deref cookieName) = ok (some cookie) := by
  apply eq_ok_of_spec
  unfold http.header_get http.header_get_loop
  rw [loop]
  unfold http.header_get_loop.body
  step*
  all_goals (simp_all [cookieHeaders, cookieName, vecOf, alloc.vec.Vec.deref]; repeat' (step <;> simp_all [cookieHeaders, cookieName, vecOf, alloc.vec.Vec.deref]))
  all_goals try scalar_tac

@[step] lemma bytes_eq_ne_len (a b : Slice U8) (h : a.val.length ≠ b.val.length) :
    strs.bytes_eq a b ⦃ r => r = false ⦄ := by
  unfold strs.bytes_eq
  dsimp only
  split
  · simp
  · exfalso; apply h; scalar_tac

lemma header_miss (nm : Slice U8) (hn : nm.val.length ≠ 6) :
    http.header_get (alloc.vec.Vec.deref cookieHeaders) nm = ok none := by
  apply eq_ok_of_spec
  unfold http.header_get http.header_get_loop
  rw [loop]
  unfold http.header_get_loop.body
  step*
  all_goals (simp_all [cookieHeaders, cookieName, vecOf, alloc.vec.Vec.deref]; repeat' (step <;> simp_all [cookieHeaders, cookieName, vecOf, alloc.vec.Vec.deref]))
  all_goals try scalar_tac
  all_goals rw [loop]
  all_goals (step* <;> simp_all [cookieHeaders, cookieName, vecOf, alloc.vec.Vec.deref])

lemma cookie_str : http.header_str (alloc.vec.Vec.deref cookieHeaders)
    (alloc.vec.Vec.deref cookieName) = ok (some cookie) := by
  simp [http.header_str, header_cookie, eq_ok_of_spec cookie_ascii]

lemma header_str_miss (nm : Slice U8) (hn : nm.val.length ≠ 6) :
    http.header_str (alloc.vec.Vec.deref cookieHeaders) nm = ok none := by
  simp [http.header_str, header_miss nm hn]

lemma cookie_session_ne_ok (v : Option (alloc.vec.Vec U8)) :
    http.session_cookie_token (alloc.vec.Vec.deref cookieHeaders) ≠ ok v := by
  intro h
  unfold http.session_cookie_token at h
  simp only [lift, bind_tc_ok] at h
  h5i_invert h
  all_goals have he := result_ok_inj (cookie_str.symm.trans ho)
  all_goals cases he
  all_goals h5i_invert h
  all_goals exact cookie_split_ne_ok _ hv_2

lemma header_not_some {nm : Slice U8} {v : alloc.vec.Vec U8}
    (h : http.header_str (alloc.vec.Vec.deref cookieHeaders) nm = ok (some v))
    (hn : nm.val.length ≠ 6) : False := by
  have he := result_ok_inj ((header_str_miss nm hn).symm.trans h)
  cases he

lemma cookie_token_ne_ok (req : http.Request) (hh : req.headers = cookieHeaders)
    (v : http.ExtractedToken) : http.extract_token req ≠ ok v := by
  intro h
  unfold http.extract_token at h
  simp only [lift, bind_tc_ok, hh] at h
  h5i_invert h
  all_goals first
    | exact cookie_session_ne_ok _ ho2
    | exact header_not_some ho (by simp [Array.to_slice, Array.make])
    | exact header_not_some ho1 (by simp [Array.to_slice, Array.make])

lemma cookie_visibility_token_ne_ok (req : http.Request) (hh : req.headers = cookieHeaders)
    (v : http.ExtractedToken) : http.extract_visibility_token req ≠ ok v := by
  intro h
  unfold http.extract_visibility_token at h
  obtain ⟨t, ht, _⟩ := bind_tc_eq_ok.1 h
  exact cookie_token_ne_ok req hh t ht

lemma cookie_no_repo_ne_ok (o : trusted.Oracle) (req : http.Request)
    (hh : req.headers = cookieHeaders) (v : middleware.Response) : middleware.no_repo o req ≠ ok v := by
  intro h
  unfold middleware.no_repo at h
  obtain ⟨t, ht, _⟩ := bind_tc_eq_ok.1 h
  exact cookie_visibility_token_ne_ok req hh t ht

def smallPath : alloc.vec.Vec U8 := vecOf [120#u8, 47#u8, 114#u8]
def smallKey : alloc.vec.Vec U8 := vecOf [114#u8]

lemma middleware_cookie_ne_ok (db : tables.Db) (o : trusted.Oracle)
    (ip : Option net.IpAddr) (req : http.Request)
    (hh : req.headers = cookieHeaders)
    (hk : ∀ key, paths.extract_repo_key (alloc.vec.Vec.deref req.path) = ok key →
      alloc.vec.Vec.len key ≠ 0#usize)
    (v : alloc.vec.Vec resolve.Write × middleware.Outcome) :
    middleware.repo_visibility_middleware db o ip req ≠ ok v := by
  intro h
  unfold middleware.repo_visibility_middleware at h
  obtain ⟨key, hkey, hr⟩ := bind_tc_eq_ok.1 h
  have hn := hk key hkey
  simp only [if_neg hn] at hr
  obtain ⟨repository, hrepository, hr⟩ := bind_tc_eq_ok.1 hr
  cases repository with
  | none =>
    obtain ⟨r, hr, _⟩ := bind_tc_eq_ok.1 hr
    exact cookie_no_repo_ne_ok o req hh r hr
  | some repository =>
    rcases repository with ⟨id, visibility⟩
    obtain ⟨nonMutating, _, hr⟩ := bind_tc_eq_ok.1 hr
    obtain ⟨isPost, _, hr⟩ := bind_tc_eq_ok.1 hr
    obtain ⟨anonymousPost, _, hr⟩ := bind_tc_eq_ok.1 hr
    obtain ⟨isWriteMethod, _, hr⟩ := bind_tc_eq_ok.1 hr
    obtain ⟨isWrite, _, hr⟩ := bind_tc_eq_ok.1 hr
    obtain ⟨token, htoken, _⟩ := bind_tc_eq_ok.1 hr
    exact cookie_visibility_token_ne_ok req hh token htoken

@[simp] lemma add01 : 0#usize + 1#usize = ok 1#usize := by
  apply eq_ok_of_spec; step* <;> scalar_tac
@[simp] lemma add11 : 1#usize + 1#usize = ok 2#usize := by
  apply eq_ok_of_spec; step* <;> scalar_tac
@[simp] lemma add21 : 2#usize + 1#usize = ok 3#usize := by
  apply eq_ok_of_spec; step* <;> scalar_tac

@[simp] lemma usize1 : (1#usize).val = 1 := by scalar_tac
@[simp] lemma usize2 : (2#usize).val = 2 := by scalar_tac
@[simp] lemma usize3 : (3#usize).val = 3 := by scalar_tac

macro "small_simp" : tactic => `(tactic| simp [smallPath, smallKey, vecOf,
  alloc.vec.Vec.deref, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.Vec.new, Slice.index_usize, alloc.vec.Vec.push,
  U32.max_def, U32.numBits, lift])

lemma trim0 : strs.trim_start_byte_loop (alloc.vec.Vec.deref smallPath) 47#u8 0#usize = ok 0#usize := by
  unfold strs.trim_start_byte_loop
  rw [loop]
  unfold strs.trim_start_byte_loop.body
  small_simp

lemma subPath : strs.sub (alloc.vec.Vec.deref smallPath) 0#usize 3#usize = ok smallPath := by
  unfold strs.sub strs.sub_loop
  iterate 4 (rw [loop]; simp only [strs.sub_loop.body]; small_simp)

def segments : alloc.vec.Vec (alloc.vec.Vec U8) := vecOf [vecOf [120#u8], smallKey]

lemma trimPath : strs.trim_start_byte (alloc.vec.Vec.deref smallPath) 47#u8 = ok smallPath := by
  have hv : (Slice.len (alloc.vec.Vec.deref smallPath)).val = 3 := by
    simp [smallPath, vecOf, alloc.vec.Vec.deref]
  have hl : Slice.len (alloc.vec.Vec.deref smallPath) = 3#usize := by scalar_tac
  simp [strs.trim_start_byte, trim0, hl, subPath]

lemma splitPath : strs.split (alloc.vec.Vec.deref smallPath) 47#u8 = ok segments := by
  unfold strs.split strs.split_loop
  iterate 4 (rw [loop]; simp only [strs.split_loop.body]; small_simp)
  simp [segments, smallKey, vecOf, alloc.vec.Vec.push, U32.max_def, U32.numBits]
  rfl

lemma containsKey : strs.contains_byte (alloc.vec.Vec.deref smallKey) 37#u8 = ok false := by
  unfold strs.contains_byte strs.contains_byte_loop
  iterate 2 (rw [loop]; try simp only [strs.contains_byte_loop.body]; small_simp)
  simp_scalar
  simp

@[simp] lemma to_vec_u8 (s : Slice U8) :
    alloc.slice.Slice.to_vec core.clone.CloneU8 s = ok { slice := s } := by
  have hc : Slice.clone core.clone.CloneU8.clone s = ok s := by
    apply eq_ok_of_spec
    apply Aeneas.Std.WP.spec_mono (Slice.clone_spec (s := s) (clone := core.clone.CloneU8.clone) (by intros; rfl))
    intro s' h; exact h.symm
  simp [alloc.slice.Slice.to_vec, hc]

lemma smallPath_key : paths.extract_repo_key (alloc.vec.Vec.deref smallPath) = ok smallKey := by
  unfold paths.extract_repo_key
  rw [trimPath]
  simp only [bind_tc_ok, bind_ok]
  rw [splitPath]
  simp only [bind_tc_ok, bind_ok]
  simp [strs.seg_is, strs.bytes_eq,
    segments, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.val, smallKey, Slice.index_usize, alloc.vec.Vec.deref,
    alloc.vec.Vec.index, alloc.vec.Vec.index_usize, core.slice.index.SliceIndexUsizeSlice,
    Array.to_slice, Array.make, lift, u8vec_clone, paths.percent_decode_path_segment, containsKey]
  have hc : strs.contains_byte (Slice.from [114#u8] (by simp; scalar_tac)) 37#u8 = ok false := by
    simpa [smallKey, vecOf, alloc.vec.Vec.deref] using containsKey
  simp [hc]


def badRequest : http.Request := {
  method := Method.Get
  path := smallPath
  query := none
  headers := cookieHeaders
}

theorem repo_visibility_counterexample (db : tables.Db) (o : trusted.Oracle)
    (ip : Option net.IpAddr) :
    ¬ ∃ y, middleware.repo_visibility_middleware db o ip badRequest = ok y := by
  rintro ⟨y, hy⟩
  apply middleware_cookie_ne_ok db o ip badRequest rfl ?_ y hy
  intro key hkey
  have he := result_ok_inj (smallPath_key.symm.trans hkey)
  cases he
  intro hz
  have hval := congrArg UScalar.val hz
  simp [smallKey, vecOf] at hval

def emptyDb : tables.Db := {
  users := vecOf []
  groups := vecOf []
  members := vecOf []
  repositories := vecOf []
  permissions := vecOf []
  roles := vecOf []
  role_assignments := vecOf []
  tickets := vecOf []
  failing := vecOf []
}

def emptyOracle : trusted.Oracle := {
  jwt := vecOf []
  api_tokens := vecOf []
  passwords := vecOf []
  base64 := vecOf []
  ip := vecOf []
}

/-- The exact universal proposition requested by TASK.md is false. -/
theorem repo_visibility_not_total :
    ¬ (∀ (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
        (req : http.Request),
      ∃ y, middleware.repo_visibility_middleware db o ip req = ok y) := by
  intro h
  exact repo_visibility_counterexample emptyDb emptyOracle none
    (h emptyDb emptyOracle none badRequest)

end artifactkeeper_kernel.Counterexample
