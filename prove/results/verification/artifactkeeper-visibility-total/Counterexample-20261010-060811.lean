import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace VisibilityCounterexample

/- Two matching permission rows can collectively carry Usize.max + 1 distinct
actions, even though each individual vector meets its size bound. The scan
fails while collecting their union. The private-read permission branch calls
this scan; the request-length assumptions do not bound the database. -/

@[step] theorem bytes_eq_different_lengths (a b : Slice U8)
    (h : a.val.length ≠ b.val.length) : strs.bytes_eq a b ⦃ r => r = false ⦄ := by
  unfold strs.bytes_eq
  have hn : Slice.len a ≠ Slice.len b := by
    intro he; apply h; have := congrArg UScalar.val he; simpa using this
  simp [hn]

@[step] theorem any_eq_different_lengths (xs : Slice (alloc.vec.Vec U8)) (s : Slice U8)
    (h : ∀ v ∈ xs.val, v.val.length ≠ s.val.length) :
    strs.any_eq xs s ⦃ r => r = false ⦄ := by
  unfold strs.any_eq strs.any_eq_loop
  apply loop_idx_spec _ (fun i => i) xs.val.length (fun _ => True) _ ?_ _ trivial (by simp)
  intro i _ hi
  unfold strs.any_eq_loop.body
  step*
  all_goals try simp_all
  have hm := h _ (List.getElem_mem (l := xs.val) (n := i.val) (by scalar_tac))
  simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using hm

@[step] theorem clone_bytes (v : alloc.vec.Vec U8) :
    alloc.vec.CloneVec.clone core.clone.CloneU8 v ⦃ r => r = v ⦄ := by
  rw [vec_clone_eq _ _ (by simp)]
  simp

theorem push_distinct_prefix (xs : Slice (alloc.vec.Vec U8))
    (hlen : ∀ j (hj : j < xs.val.length), xs.val[j].val.length = j) :
    permission.push_distinct (alloc.vec.Vec.new _) xs ⦃ r => r.val = xs.val ⦄ := by
  unfold permission.push_distinct permission.push_distinct_loop
  apply loop_idx_spec _ (fun s => s.2) xs.val.length
    (fun s => s.1.val = xs.val.take s.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨out, i⟩ hI hi
  dsimp only at hI hi
  unfold permission.push_distinct_loop.body
  h5i_steps
  all_goals try simp_all [alloc.vec.Vec.deref, alloc.vec.Vec.val]
  all_goals try scalar_tac

  intro v hv he
  obtain ⟨j, hj, heq⟩ := List.getElem_of_mem hv
  have hjx : j < xs.val.length := by simp only [List.length_take] at hj; omega
  simp only [List.getElem_take] at heq
  have hh := hlen j hjx
  rw [heq] at hh
  have : j = i.val := by simpa [alloc.vec.Vec.val] using hh.symm.trans he
  simp only [List.length_take] at hj
  omega


def word (n : Nat) (h : n ≤ Usize.max) : alloc.vec.Vec U8 :=
  alloc.vec.Vec.from (List.replicate n 0#u8) (by simpa)

def full : alloc.vec.Vec (alloc.vec.Vec U8) :=
  alloc.vec.Vec.from (List.ofFn fun i : Fin Usize.max => word i.val (by omega)) (by simp)

def extra : alloc.vec.Vec U8 := word Usize.max (by omega)

def singleton : Slice (alloc.vec.Vec U8) :=
  Slice.from [extra] (by simp; have := usize_max_ge; omega)

theorem fill_to_capacity :
    permission.push_distinct (alloc.vec.Vec.new _) full.deref = ok full := by
  apply eq_ok_of_spec
  apply WP.spec_mono (push_distinct_prefix full.deref ?_)
  · intro r hr
    apply alloc.vec.Vec.ext
    simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using hr
  · intro j hj
    simp [full, alloc.vec.Vec.deref, word, List.getElem_ofFn]

theorem extra_is_absent : strs.any_eq full.deref extra.deref = ok false := by
  apply eq_ok_of_spec
  apply any_eq_different_lengths
  intro v hv
  simp only [full, alloc.vec.Vec.deref, alloc.vec.Vec.from, alloc.vec.Vec.val, Slice.from_val] at hv
  obtain ⟨i, rfl⟩ := List.mem_ofFn.mp hv
  simp [word, extra, alloc.vec.Vec.deref, alloc.vec.Vec.val, alloc.vec.Vec.from]
  exact Nat.ne_of_lt i.isLt

theorem push_beyond_capacity :
    permission.push_distinct full singleton = fail .maximumSizeExceeded := by
  unfold permission.push_distinct permission.push_distinct_loop
  rw [loop]
  unfold permission.push_distinct_loop.body
  have hpos : (0#usize : Usize) < singleton.len := by
    simp [singleton, Slice.len]
  simp only [hpos, if_true]
  have hidx : singleton.index_usize 0#usize = ok extra := by
    apply eq_ok_of_spec
    step*
    simpa [singleton] using x_post
  rw [hidx]
  simp only [bind_ok]
  rw [extra_is_absent]
  simp only [bind_ok, Bool.false_eq_true, if_false]
  rw [vec_clone_eq _ _ (by simp)]
  simp only [bind_ok]
  have hp : full.push extra = fail .maximumSizeExceeded := by
    have h32 : U32.max ≤ Usize.max := by
      simpa [U32.max_def, U32.numBits] using usize_max_ge
    simp [alloc.vec.Vec.push, full]
    omega
  rw [hp]
  simp


@[step] theorem bytes_eq_same (a : Slice U8) : strs.bytes_eq a a ⦃ r => r = true ⦄ := by
  unfold strs.bytes_eq
  simp only [bne_self_eq_false, Bool.false_eq_true, if_false]
  unfold strs.bytes_eq_loop
  h5i_total (fun i => i) a.val.length

@[step] theorem bytes_eq_equal (a b : Slice U8) (h : a = b) :
    strs.bytes_eq a b ⦃ r => r = true ⦄ := by
  subst b
  exact bytes_eq_same a

def permissionRow (actions : alloc.vec.Vec (alloc.vec.Vec U8)) : tables.Permission := {
  principal_type := alloc.vec.Vec.from [117#u8, 115#u8, 101#u8, 114#u8] (by have := usize_max_ge; simp; omega)
  principal_id := 0#u64
  target_type := alloc.vec.Vec.from [114#u8, 101#u8, 112#u8, 111#u8, 115#u8, 105#u8, 116#u8, 111#u8, 114#u8, 121#u8] (by have := usize_max_ge; simp; omega)
  target_id := 0#u64
  actions := actions
  allowed_cidrs := none
}

def overflowDb : tables.Db := {
  users := alloc.vec.Vec.new _
  groups := alloc.vec.Vec.new _
  members := alloc.vec.Vec.new _
  repositories := alloc.vec.Vec.from [{
    id := 0#u64
    key := alloc.vec.Vec.from [120#u8] (by have := usize_max_ge; simp; omega)
    visibility := some .Private
    project_id := none
  }] (by have := usize_max_ge; simp; omega)
  permissions := alloc.vec.Vec.from
    [permissionRow full, permissionRow (alloc.vec.Vec.from [extra] (by have := usize_max_ge; simp; omega))]
    (by have := usize_max_ge; simp; omega)
  roles := alloc.vec.Vec.new _
  role_assignments := alloc.vec.Vec.new _
  tickets := alloc.vec.Vec.new _
  failing := alloc.vec.Vec.new _
}

@[step] theorem row_principal (actions : alloc.vec.Vec (alloc.vec.Vec U8)) :
    permission.principal_matches overflowDb (permissionRow actions) 0#u64 ⦃ r => r = true ⦄ := by
  unfold permission.principal_matches permissionRow
  h5i_steps
  all_goals simp_all [alloc.vec.Vec.deref, alloc.vec.Vec.from, alloc.vec.Vec.val, Array.to_slice, Slice.eq_iff]

@[step] theorem row_target (actions : alloc.vec.Vec (alloc.vec.Vec U8)) :
    permission.target_matches overflowDb (permissionRow actions) (permissionRow actions).target_type.deref 0#u64
      ⦃ r => r = true ⦄ := by
  unfold permission.target_matches
  simp only [permissionRow]
  h5i_steps


@[step] theorem fill_spec :
    permission.push_distinct (alloc.vec.Vec.new _) full.deref ⦃ r => r = full ⦄ := by
  rw [fill_to_capacity]
  simp

@[step] theorem row_ip (actions : alloc.vec.Vec (alloc.vec.Vec U8)) (ip : Option net.IpAddr) :
    permission.ip_condition (permissionRow actions) ip ⦃ r => r = true ⦄ := by
  simp [permission.ip_condition, permissionRow]


theorem first_row :
    permission.query_actions_loop.body overflowDb none 0#u64 (permissionRow full).target_type.deref
      0#u64 (alloc.vec.Vec.new _) 0#usize = ok (.cont (full, 1#usize)) := by
  have hidx : overflowDb.permissions.index_usize 0#usize = ok (permissionRow full) := by
    apply eq_ok_of_spec
    step*
    · simp [overflowDb]
    · simpa [overflowDb] using x_post
  have hlt : (0#usize : Usize) < overflowDb.permissions.len := by simp [overflowDb, alloc.vec.Vec.len]
  unfold permission.query_actions_loop.body
  simp only [hlt, if_true]
  simp only [alloc.vec.Vec.index_slice_index]
  rw [hidx]
  simp only [bind_ok]
  rw [eq_ok_of_spec (row_principal full)]
  simp only [bind_ok, if_true]
  rw [eq_ok_of_spec (row_target full)]
  simp only [bind_ok, if_true]
  rw [eq_ok_of_spec (row_ip full none)]
  simp only [bind_ok, if_true, permissionRow]
  rw [fill_to_capacity]
  simp only [bind_ok]
  apply eq_ok_of_spec
  step*
  have he : i2 = 1#usize := by scalar_tac
  rw [he]


def extraVec : alloc.vec.Vec (alloc.vec.Vec U8) :=
  alloc.vec.Vec.from [extra] (by have := usize_max_ge; simp; omega)

theorem second_row :
    permission.query_actions_loop.body overflowDb none 0#u64 (permissionRow full).target_type.deref
      0#u64 full 1#usize = fail .maximumSizeExceeded := by
  have hidx : overflowDb.permissions.index_usize 1#usize = ok (permissionRow extraVec) := by
    apply eq_ok_of_spec
    step*
    · simp [overflowDb]
    · simpa [overflowDb, extraVec] using x_post
  have hlt : (1#usize : Usize) < overflowDb.permissions.len := by simp [overflowDb, alloc.vec.Vec.len]
  unfold permission.query_actions_loop.body
  simp only [hlt, if_true, alloc.vec.Vec.index_slice_index]
  rw [hidx]
  simp only [bind_ok]
  rw [eq_ok_of_spec (row_principal extraVec)]
  simp only [bind_ok, if_true]
  have ht := eq_ok_of_spec (row_target extraVec)
  change permission.target_matches overflowDb (permissionRow extraVec) (permissionRow full).target_type.deref 0#u64 = ok true at ht
  rw [ht]
  simp only [bind_ok, if_true]
  rw [eq_ok_of_spec (row_ip extraVec none)]
  simp only [bind_ok, if_true, permissionRow]
  have hp : permission.push_distinct full extraVec.deref = fail .maximumSizeExceeded := push_beyond_capacity
  rw [hp]
  simp

theorem query_actions_overflow :
    permission.query_actions overflowDb none 0#u64 (permissionRow full).target_type.deref 0#u64 =
      fail .maximumSizeExceeded := by
  have hf : tables.Db.fails overflowDb tables.Query.QueryActions = ok false := by
    unfold tables.Db.fails tables.Db.fails_loop
    rw [loop]
    simp [tables.Db.fails_loop.body, overflowDb]
  unfold permission.query_actions
  rw [hf]
  simp only [bind_ok, Bool.false_eq_true, if_false]
  unfold permission.query_actions_loop
  rw [loop]
  dsimp only
  rw [first_row]
  simp only [bind_ok]
  rw [loop]
  dsimp only
  rw [second_row]
  simp


theorem db_fails_eq (q : tables.Query) : tables.Db.fails overflowDb q = ok false := by
  unfold tables.Db.fails tables.Db.fails_loop
  rw [loop]
  simp [tables.Db.fails_loop.body, overflowDb]

theorem any_rules_eq :
    permission.has_any_rules_for_target overflowDb (permissionRow full).target_type.deref 0#u64 =
      ok (.Ok true) := by
  have hidx : overflowDb.permissions.index_usize 0#usize = ok (permissionRow full) := by
    apply eq_ok_of_spec
    step*
    · simp [overflowDb]
    · simpa [overflowDb] using x_post
  have hlt : (0#usize : Usize) < overflowDb.permissions.len := by simp [overflowDb, alloc.vec.Vec.len]
  unfold permission.has_any_rules_for_target
  rw [db_fails_eq]
  simp only [bind_ok, Bool.false_eq_true, if_false]
  unfold permission.has_any_rules_for_target_loop
  rw [loop]
  unfold permission.has_any_rules_for_target_loop.body
  simp only [hlt, if_true, alloc.vec.Vec.index_slice_index]
  rw [hidx]
  simp only [bind_ok]
  rw [eq_ok_of_spec (row_target full)]
  simp

theorem check_permission_overflow (action : Slice U8) :
    permission.check_permission overflowDb none 0#u64 (permissionRow full).target_type.deref 0#u64 action false =
      fail .maximumSizeExceeded := by
  unfold permission.check_permission
  simp only [Bool.false_eq_true, if_false]
  rw [query_actions_overflow]
  simp

theorem repository_literal :
    (Array.to_slice (Array.make 10#usize
      [114#u8, 101#u8, 112#u8, 111#u8, 115#u8, 105#u8, 116#u8, 111#u8, 114#u8, 121#u8])) =
      (permissionRow full).target_type.deref := by
  apply Slice.ext
  simp [Array.to_slice, permissionRow, alloc.vec.Vec.deref, alloc.vec.Vec.from, alloc.vec.Vec.val]

theorem permission_arm_not_total (ext : AuthExtension) (req : http.Request)
    (hu : ext.user_id = 0#u64) (y : Option middleware.Response) :
    middleware.permission_arm overflowDb none ext 0#u64 .Private req false false ≠ ok y := by
  intro h
  unfold middleware.permission_arm at h
  h5i_invert h
  all_goals try simp_all [paths.authenticated_read_satisfies_acl, Visibility.allows_authenticated_read]
  all_goals simp_all [lift, repository_literal]
  all_goals subst_vars
  all_goals simp_all [any_rules_eq, check_permission_overflow]

def x : alloc.vec.Vec U8 :=
  alloc.vec.Vec.from [120#u8] (by have := usize_max_ge; simp; omega)

def shortPath : alloc.vec.Vec U8 :=
  alloc.vec.Vec.from [114#u8, 47#u8, 120#u8] (by have := usize_max_ge; simp; omega)

@[step] theorem sub_whole (s : Slice U8) :
    strs.sub s 0#usize s.len ⦃ r => r.val = s.val ⦄ := by
  unfold strs.sub strs.sub_loop
  apply loop_idx_spec _ (fun st => st.2) s.val.length
    (fun st => st.1.val = s.val.take st.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨out, i⟩ hI hi
  dsimp only at hI hi
  unfold strs.sub_loop.body
  h5i_steps
  all_goals simp_all
  all_goals scalar_tac

theorem trim_path : strs.trim_start_byte shortPath.deref 47#u8 = ok shortPath := by
  unfold strs.trim_start_byte strs.trim_start_byte_loop
  rw [loop]
  unfold strs.trim_start_byte_loop.body
  have hi : (0#usize : Usize) < shortPath.deref.len := by simp [shortPath, Slice.len, alloc.vec.Vec.deref]
  simp only [hi, if_true]
  have hx : shortPath.deref.index_usize 0#usize = ok 114#u8 := by
    apply eq_ok_of_spec
    step*
    simpa [shortPath, alloc.vec.Vec.deref] using x_post
  rw [hx]
  simp only [bind_ok]
  norm_num
  apply eq_ok_of_spec
  apply WP.spec_mono (sub_whole shortPath.deref)
  intro r hr
  apply alloc.vec.Vec.ext
  exact hr

def rbyte : alloc.vec.Vec U8 :=
  alloc.vec.Vec.from [114#u8] (by have := usize_max_ge; simp; omega)

def shortSegments : alloc.vec.Vec (alloc.vec.Vec U8) :=
  alloc.vec.Vec.from [rbyte, x] (by have := usize_max_ge; simp; omega)

theorem split_path : strs.split shortPath.deref 47#u8 = ok shortSegments := by
  apply eq_ok_of_spec
  unfold strs.split strs.split_loop
  let abs := fun (out : alloc.vec.Vec (alloc.vec.Vec U8)) (cur : alloc.vec.Vec U8) =>
    (out.val.map (·.val), cur.val)
  let g := fun (st : List (List U8) × List U8) (c : U8) =>
    if c = 47#u8 then (st.1 ++ [st.2], []) else (st.1, st.2 ++ [c])
  have hf := loop_fold2 shortPath.deref.val abs g
    (fun out cur i => out.val.length ≤ i ∧ cur.val.length ≤ i)
    (fun (out, cur, i) => strs.split_loop.body shortPath.deref 47#u8 out cur i) ?_
    (alloc.vec.Vec.new _) (alloc.vec.Vec.new _) 0#usize (by simp) (by simp)
  · apply WP.spec_bind hf
    rintro ⟨out, cur⟩ ⟨hr, hi⟩
    have hvals : out.val.map (·.val) = [[114#u8]] ∧ cur.val = [120#u8] := by
      simpa [shortPath, alloc.vec.Vec.deref, abs, g] using hr
    step*
    · have hl : out.val.length = 1 := by
        have := congrArg List.length hvals.1
        simpa using this
      have := usize_max_ge
      scalar_tac
    · apply alloc.vec.Vec.ext
      have hout : out.val = [rbyte] := by
        have : out.val.map (·.val) = [rbyte.val] := by simpa [rbyte] using hvals.1
        apply (List.map_inj_right (fun _ _ h => by apply alloc.vec.Vec.ext; exact h)).mp
        exact this
      have hcur : cur = VisibilityCounterexample.x := by
        apply alloc.vec.Vec.ext
        exact hvals.2
      simp_all [shortSegments]
  · intro out cur i hi hI
    unfold strs.split_loop.body
    h5i_steps
    all_goals simp_all [FoldStep2, abs, g]
    all_goals scalar_tac

@[step] theorem trim_path_spec :
    strs.trim_start_byte shortPath.deref 47#u8 ⦃ r => r = shortPath ⦄ := by
  rw [trim_path]; simp

@[step] theorem split_path_spec :
    strs.split shortPath.deref 47#u8 ⦃ r => r = shortSegments ⦄ := by
  rw [split_path]; simp

@[step] theorem short_segment_not_literal (lit : Slice U8) (h : lit.val.length ≠ 1) :
    strs.seg_is shortSegments.deref 0#usize lit ⦃ r => r = false ⦄ := by
  unfold strs.seg_is
  have hi : (0#usize : Usize) < shortSegments.deref.len := by simp [shortSegments, Slice.len, alloc.vec.Vec.deref]
  simp only [hi, if_true]
  step
  step with bytes_eq_different_lengths
  all_goals simp_all [shortSegments, rbyte, alloc.vec.Vec.deref]

@[simp] theorem short_segment_not_literal_eq (lit : Slice U8) (h : lit.val.length ≠ 1) :
    strs.seg_is shortSegments.deref 0#usize lit = ok false :=
  eq_ok_of_spec (short_segment_not_literal lit h)

@[step] theorem contains_byte_absent (s : Slice U8) (c : U8) (h : c ∉ s.val) :
    strs.contains_byte s c ⦃ r => r = false ⦄ := by
  unfold strs.contains_byte strs.contains_byte_loop
  h5i_total (fun i => i) s.val.length

theorem decode_x : paths.percent_decode_path_segment x.deref = ok (some x) := by
  unfold paths.percent_decode_path_segment
  rw [eq_ok_of_spec (contains_byte_absent x.deref 37#u8 (by simp [x, alloc.vec.Vec.deref]))]
  simp only [bind_ok, Bool.false_eq_true, if_false]
  apply eq_ok_of_spec
  step*
  have he : v = x := by
    apply alloc.vec.Vec.ext
    have := congrArg Slice.val v_post
    change x.val = v.val at this
    exact this.symm
  simp_all

theorem extract_key : paths.extract_repo_key shortPath.deref = ok x := by
  unfold paths.extract_repo_key
  rw [trim_path]
  simp only [bind_ok]
  rw [split_path]
  simp [lift, Array.to_slice]
  apply eq_ok_of_spec
  h5i_steps
  all_goals simp_all [shortSegments, decode_x]

theorem non_mutating_path : paths.is_non_mutating_format_post shortPath.deref = ok false := by
  unfold paths.is_non_mutating_format_post
  rw [trim_path]
  simp only [bind_ok]
  rw [split_path]
  simp [lift, Array.to_slice]

def apiHeader : alloc.vec.Vec U8 :=
  alloc.vec.Vec.from [120#u8, 45#u8, 97#u8, 112#u8, 105#u8, 45#u8, 107#u8, 101#u8, 121#u8]
    (by have := usize_max_ge; simp; omega)

def shortRequest : http.Request := {
  method := .Get
  path := shortPath
  query := none
  headers := alloc.vec.Vec.from [(apiHeader, x)] (by have := usize_max_ge; simp; omega)
}

theorem header_index : shortRequest.headers.deref.index_usize 0#usize = ok (apiHeader, x) := by
  apply eq_ok_of_spec
  step*
  all_goals simp_all [shortRequest, alloc.vec.Vec.deref]

theorem header_get_different (nm : Slice U8) (h : nm.val.length ≠ 9) :
    http.header_get shortRequest.headers.deref nm = ok none := by
  unfold http.header_get http.header_get_loop
  rw [loop]
  unfold http.header_get_loop.body
  have hi : (0#usize : Usize) < shortRequest.headers.deref.len := by
    simp [shortRequest, alloc.vec.Vec.deref, Slice.len]
  simp only [hi, if_true]
  rw [header_index]
  simp only [bind_ok, uncurry]
  try dsimp only
  rw [eq_ok_of_spec (bytes_eq_different_lengths apiHeader.deref nm (by simp_all [apiHeader, alloc.vec.Vec.deref]))]
  simp only [bind_ok, Bool.false_eq_true, if_false]
  have hadd : (0#usize : Usize) + 1#usize = ok 1#usize := by
    apply eq_ok_of_spec
    step*
  rw [hadd]
  simp only [bind_ok]
  rw [loop]
  simp [shortRequest, alloc.vec.Vec.deref]

theorem header_get_present : http.header_get shortRequest.headers.deref apiHeader.deref = ok (some x) := by
  unfold http.header_get http.header_get_loop
  rw [loop]
  unfold http.header_get_loop.body
  have hi : (0#usize : Usize) < shortRequest.headers.deref.len := by
    simp [shortRequest, alloc.vec.Vec.deref, Slice.len]
  simp only [hi, if_true]
  rw [header_index]
  simp only [bind_ok, uncurry]
  try dsimp only
  rw [eq_ok_of_spec (bytes_eq_same apiHeader.deref)]
  simp only [bind_ok, if_true]
  rw [vec_clone_eq _ _ (by simp)]
  simp

theorem visible_x : http.visible_ascii x.deref = ok true := by
  have hn : x.deref.len = 1#usize := by
    simp [x, alloc.vec.Vec.deref, Slice.len]
    scalar_tac
  apply eq_ok_of_spec
  unfold http.visible_ascii http.visible_ascii_loop
  h5i_total (fun i => i) x.val.length
  all_goals simp_all [x, alloc.vec.Vec.deref]
  all_goals scalar_tac

theorem extract_token_eq : http.extract_visibility_token shortRequest = ok (.ApiKey x) := by
  have ha : http.header_str shortRequest.headers.deref
      (Array.to_slice (Array.make 13#usize [97#u8, 117#u8, 116#u8, 104#u8, 111#u8,
        114#u8, 105#u8, 122#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8])) = ok none := by
    unfold http.header_str
    rw [header_get_different _ (by simp [Array.to_slice])]
    simp
  have hb : http.header_str shortRequest.headers.deref apiHeader.deref = ok (some x) := by
    unfold http.header_str
    rw [header_get_present]
    simp only [bind_ok]
    rw [visible_x]
    simp
  have hlit : Array.to_slice (Array.make 9#usize
      [120#u8, 45#u8, 97#u8, 112#u8, 105#u8, 45#u8, 107#u8, 101#u8, 121#u8]) = apiHeader.deref := by
    apply Slice.ext
    simp [Array.to_slice, apiHeader, alloc.vec.Vec.deref]
  unfold http.extract_visibility_token http.extract_token
  simp only [lift, bind_ok]
  rw [ha]
  simp only [bind_ok]
  rw [hlit, hb]
  simp

h5i_derive_clone User User.Insts.CoreCloneClone.clone
h5i_derive_clone AccessScope AccessScope.Insts.CoreCloneClone.clone
h5i_derive_clone trusted.ApiTokenValidation trusted.ApiTokenValidation.Insts.CoreCloneClone.clone

def tokenUser : User := {
  id := 0#u64
  username := alloc.vec.Vec.new _
  email := alloc.vec.Vec.new _
  is_active := true
  is_admin := false
  is_service_account := false
  must_change_password := false
}

def validation : trusted.ApiTokenValidation := {
  user := tokenUser
  scopes := alloc.vec.Vec.new _
  allowed_repo_ids := .Admin
}

def shortOracle : trusted.Oracle := {
  jwt := alloc.vec.Vec.new _
  api_tokens := alloc.vec.Vec.from [(x, .Ok validation)] (by have := usize_max_ge; simp; omega)
  passwords := alloc.vec.Vec.new _
  base64 := alloc.vec.Vec.new _
  ip := alloc.vec.Vec.new _
}

def tokenExt : AuthExtension := {
  user_id := 0#u64
  username := alloc.vec.Vec.new _
  email := alloc.vec.Vec.new _
  is_admin := false
  is_api_token := true
  is_service_account := false
  scopes := some (alloc.vec.Vec.new _)
  allowed_repo_ids := .Admin
  iat_ms := none
}

theorem oracle_validates : trusted.Oracle.validate_api_token shortOracle x.deref = ok (.Ok validation) := by
  apply eq_ok_of_spec
  unfold trusted.Oracle.validate_api_token trusted.Oracle.validate_api_token_loop
  rw [loop]
  unfold trusted.Oracle.validate_api_token_loop.body
  h5i_steps
  all_goals simp_all [shortOracle, alloc.vec.Vec.deref]
  all_goals h5i_steps

theorem resolves_token : resolve.try_resolve_auth_outcome shortOracle (.ApiKey x) true =
    ok (.Resolved tokenExt) := by
  simp [resolve.try_resolve_auth_outcome, resolve.validate_api_token_with_scopes,
    oracle_validates, token_scope.AuthExtension.with_scope_gated_admin, validation, tokenUser, tokenExt]

theorem lookup_x : middleware.lookup_repo overflowDb x.deref = ok (some (0#u64, .Private)) := by
  unfold middleware.lookup_repo
  rw [db_fails_eq]
  simp only [bind_ok, Bool.false_eq_true, if_false]
  apply eq_ok_of_spec
  unfold middleware.lookup_repo_loop
  rw [loop]
  unfold middleware.lookup_repo_loop.body
  h5i_steps
  all_goals simp_all [overflowDb, VisibilityCounterexample.x, alloc.vec.Vec.deref]

theorem middleware_not_total (y : alloc.vec.Vec resolve.Write × middleware.Outcome) :
    middleware.repo_visibility_middleware overflowDb shortOracle none shortRequest ≠ ok y := by
  intro h
  unfold middleware.repo_visibility_middleware at h
  simp only [show shortRequest.path = shortPath from rfl] at h
  rw [extract_key] at h
  simp only [bind_ok] at h
  have hnonempty : x.len ≠ 0#usize := by simp [x]
  simp only [hnonempty, if_false] at h
  rw [lookup_x] at h
  simp only [bind_ok, uncurry] at h
  rw [non_mutating_path] at h
  simp only [bind_ok, show shortRequest.method = Method.Get from rfl] at h
  simp [Method.Insts.CoreCmpPartialEqMethod.eq, paths.is_write_method] at h
  rw [extract_token_eq] at h
  simp only [bind_ok] at h
  rw [resolves_token] at h
  simp [paths.should_allow_repo_access, paths.public_read_satisfies_acl,
    Visibility.allows_anonymous_read, token_scope.AuthExtension.can_access_repo,
    token_scope.AuthExtension.access_scope, AccessScope.Insts.CoreCloneClone.clone,
    AccessScope.grants, tokenExt] at h
  h5i_invert h
  all_goals exact permission_arm_not_total tokenExt shortRequest rfl _ ho1

theorem request_bounds :
    shortRequest.path.length < Usize.max ∧
    (∀ q, shortRequest.query = some q → 2 * q.length < Usize.max) ∧
    ∀ h ∈ shortRequest.headers.val, h.1.length < Usize.max ∧ h.2.length < Usize.max := by
  have := usize_max_ge
  simp [shortRequest, shortPath, apiHeader, x]
  omega

theorem totality_statement_is_false :
    ¬ (∀ (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr) (req : http.Request),
      (req.path.length < Usize.max ∧
        (∀ q, req.query = some q → 2 * q.length < Usize.max) ∧
        ∀ h ∈ req.headers.val, h.1.length < Usize.max ∧ h.2.length < Usize.max) →
      ∃ y, middleware.repo_visibility_middleware db o ip req = ok y) := by
  intro h
  obtain ⟨y, hy⟩ := h overflowDb shortOracle none shortRequest request_bounds
  exact middleware_not_total y hy

end VisibilityCounterexample

#print axioms VisibilityCounterexample.totality_statement_is_false
