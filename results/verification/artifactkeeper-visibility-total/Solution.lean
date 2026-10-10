import Spec
import H5iAppLib
import Mathlib.Tactic.CasesM
import Mathlib.Tactic.FailIfNoProgress
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace artifactkeeper_kernel.Solution
set_option maxHeartbeats 40000000
set_option maxRecDepth 4096
set_option linter.unusedTactic false
set_option linter.unreachableTactic false
set_option linter.unusedSimpArgs false

h5i_derive_all

@[local simp, local scalar_tac_simps] theorem deref_val {α : Type} (v : alloc.vec.Vec α) :
    (alloc.vec.Vec.deref v).val = v.val := by simp [alloc.vec.Vec.deref]

@[local simp, local scalar_tac_simps] theorem vec_slice_val {α : Type} (v : alloc.vec.Vec α) :
    v.slice.val = v.val := by unfold alloc.vec.Vec.val; rfl

theorem bytes_eq_total (a b : Slice U8) : strs.bytes_eq a b ⦃ _ => True ⦄ := by
  unfold strs.bytes_eq
  step*
  unfold strs.bytes_eq_loop
  h5i_total (fun i => i) a.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] bytes_eq_total

theorem any_eq_total (l : Slice (alloc.vec.Vec U8)) (s : Slice U8) :
    strs.any_eq l s ⦃ _ => True ⦄ := by
  unfold strs.any_eq strs.any_eq_loop
  h5i_total (fun i => i) l.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] any_eq_total

theorem find_byte_total (s : Slice U8) (b : U8) :
    strs.find_byte s b ⦃ r => ∀ i, r = some i → i.val < s.val.length ⦄ := by
  unfold strs.find_byte strs.find_byte_loop
  h5i_total (fun i => i) s.val.length
  all_goals simp_all [or_imp, forall_and]

attribute [local step] find_byte_total

theorem sub_total (s : Slice U8) (a b : Usize) :
    strs.sub s a b ⦃ r => r.val.length ≤ s.val.length ⦄ := by
  unfold strs.sub strs.sub_loop
  apply loop.spec_decr_nat (measure := fun x => s.val.length - x.2.val)
    (inv := fun x => x.1.val.length ≤ x.2.val ∧ x.1.val.length ≤ s.val.length)
  · rintro ⟨out, i⟩ ⟨h1, h2⟩
    unfold strs.sub_loop.body
    h5i_steps
    all_goals simp_all [or_imp, forall_and]
    all_goals scalar_tac
  · simp


attribute [local step] sub_total

theorem split_once_total (s : Slice U8) (b : U8) :
    strs.split_once s b ⦃ r => ∀ p, r = some p →
      p.1.val.length ≤ s.val.length ∧ p.2.val.length ≤ s.val.length ⦄ := by
  unfold strs.split_once
  h5i_steps
  all_goals simp_all [or_imp, forall_and]

attribute [local step] split_once_total

theorem starts_with_at_total (s p : Slice U8) (a : Usize) :
    strs.starts_with_at s a p ⦃ _ => True ⦄ := by
  unfold strs.starts_with_at
  step*
  unfold strs.starts_with_at_loop
  h5i_total (fun i => i) p.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] starts_with_at_total

theorem starts_with_total (s p : Slice U8) :
    strs.starts_with s p ⦃ _ => True ⦄ := by
  unfold strs.starts_with
  step*

attribute [local step] starts_with_total

theorem strip_prefix_total (s p : Slice U8) :
    strs.strip_prefix s p ⦃ r => ∀ v, r = some v → v.val.length ≤ s.val.length ⦄ := by
  unfold strs.strip_prefix
  h5i_steps
  all_goals simp_all [or_imp, forall_and]

attribute [local step] strip_prefix_total

theorem is_ws_total (b : U8) : strs.is_ws b ⦃ _ => True ⦄ := by
  unfold strs.is_ws
  h5i_steps

attribute [local step] is_ws_total

theorem trim_total (s : Slice U8) :
    strs.trim s ⦃ r => r.val.length ≤ s.val.length ⦄ := by
  have h0 : strs.trim_loop0 s 0#usize ⦃ _ => True ⦄ := by
    unfold strs.trim_loop0
    h5i_total (fun i => i) s.val.length
  have h1 (a : Usize) : strs.trim_loop1 s a (Slice.len s) ⦃ _ => True ⦄ := by
    unfold strs.trim_loop1
    apply loop.spec_decr_nat (measure := fun b => b.val)
      (inv := fun b => b.val ≤ s.val.length)
    · intro b hb
      unfold strs.trim_loop1.body
      h5i_steps
      all_goals scalar_tac
    · scalar_tac
  unfold strs.trim
  step with h0
  step with h1
  step*

attribute [local step] trim_total

theorem trim_start_byte_total (s : Slice U8) (b : U8) :
    strs.trim_start_byte s b ⦃ r => r.val.length ≤ s.val.length ⦄ := by
  have h : strs.trim_start_byte_loop s b 0#usize ⦃ _ => True ⦄ := by
    unfold strs.trim_start_byte_loop
    h5i_total (fun i => i) s.val.length
  unfold strs.trim_start_byte
  step with h
  step*

attribute [local step] trim_start_byte_total

theorem split_total (s : Slice U8) (b : U8) (hs : s.val.length < Usize.max) :
    strs.split s b ⦃ r => r.val.length ≤ s.val.length + 1 ∧
      ∀ v ∈ r.val, v.val.length ≤ s.val.length ⦄ := by
  have h : strs.split_loop s b (alloc.vec.Vec.new _) (alloc.vec.Vec.new _) 0#usize
      ⦃ r => r.1.val.length ≤ s.val.length ∧ r.2.val.length ≤ s.val.length ∧
        ∀ v ∈ r.1.val, v.val.length ≤ s.val.length ⦄ := by
    unfold strs.split_loop
    apply loop.spec_decr_nat (measure := fun x => s.val.length - x.2.2.val)
      (inv := fun x => x.1.val.length ≤ x.2.2.val ∧ x.2.1.val.length ≤ x.2.2.val ∧
        x.2.2.val ≤ s.val.length ∧ ∀ v ∈ x.1.val, v.val.length ≤ s.val.length)
    · rintro ⟨out, cur, i⟩ ⟨ho, hc, hi, hv⟩
      unfold strs.split_loop.body
      h5i_steps
      all_goals simp_all [or_imp, forall_and]
      all_goals scalar_tac
    · simp
  unfold strs.split
  step with h
  step*
  all_goals simp_all [or_imp, forall_and]
  all_goals omega

attribute [local step] split_total

theorem is_cont_byte_total (b : U8) : strs.is_cont_byte b ⦃ _ => True ⦄ := by
  unfold strs.is_cont_byte
  h5i_steps

attribute [local step] is_cont_byte_total

theorem utf8_seq_total (s : Slice U8) (i : Usize) (hi : i.val < s.val.length) :
    strs.utf8_seq s i ⦃ k => i.val + k.val ≤ s.val.length ⦄ := by
  unfold strs.utf8_seq
  h5i_steps
  all_goals scalar_tac

attribute [local step] utf8_seq_total

theorem is_utf8_total (s : Slice U8) : strs.is_utf8 s ⦃ _ => True ⦄ := by
  unfold strs.is_utf8 strs.is_utf8_loop
  h5i_total (fun i => i) s.val.length


attribute [local step] is_utf8_total

theorem tot_Visibility_allows_anonymous_read (self : Visibility) :
    Visibility.allows_anonymous_read self ⦃ _ => True ⦄ := by
  unfold Visibility.allows_anonymous_read
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_Visibility_allows_anonymous_read

theorem tot_http_header_get_loop
    (headers : Slice ((alloc.vec.Vec U8) × (alloc.vec.Vec U8))) («name» : Slice U8)
    (i : Usize) (hh : ∀ h ∈ headers.val, h.2.val.length < Usize.max)
    (hi : i.val ≤ headers.val.length) :
    http.header_get_loop headers «name» i ⦃ r => ∀ v, r = some v → v.val.length < Usize.max ⦄ := by
  unfold http.header_get_loop
  apply loop_idx_spec _ id headers.val.length (fun _ => True) _ ?_ _ trivial hi
  intro j _ hj
  by_cases hlt : j.val < headers.val.length
  · have hv := hh headers.val[j.val] (List.getElem_mem hlt)
    unfold http.header_get_loop.body
    h5i_steps
    all_goals (simp_all<;> scalar_tac)
  · unfold http.header_get_loop.body
    h5i_steps
    all_goals (simp_all<;> scalar_tac)
attribute [local step] tot_http_header_get_loop

theorem tot_http_header_get
    (headers : Slice ((alloc.vec.Vec U8) × (alloc.vec.Vec U8))) («name» : Slice U8)
    (hh : ∀ h ∈ headers.val, h.2.val.length < Usize.max) :
    http.header_get headers «name» ⦃ r => ∀ v, r = some v → v.val.length < Usize.max ⦄ := by
  unfold http.header_get
  h5i_steps
attribute [local step] tot_http_header_get

theorem tot_http_visible_ascii_loop (v : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ v.val.length) :
    http.visible_ascii_loop v i ⦃ _ => True ⦄ := by
  unfold http.visible_ascii_loop
  h5i_total (fun i => i) v.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_http_visible_ascii_loop

theorem tot_http_visible_ascii (v : Slice Std.U8) :
    http.visible_ascii v ⦃ _ => True ⦄ := by
  unfold http.visible_ascii
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_http_visible_ascii

theorem tot_http_header_str
    (headers : Slice ((alloc.vec.Vec U8) × (alloc.vec.Vec U8))) («name» : Slice U8)
    (hh : ∀ h ∈ headers.val, h.2.val.length < Usize.max) :
    http.header_str headers «name» ⦃ r => ∀ v, r = some v → v.val.length < Usize.max ⦄ := by
  unfold http.header_str
  h5i_steps
  all_goals simp_all
attribute [local step] tot_http_header_str

theorem tot_strs_seg_is (segs : Slice (alloc.vec.Vec Std.U8)) (i : Std.Usize) (lit : Slice Std.U8) :
    strs.seg_is segs i lit ⦃ _ => True ⦄ := by
  unfold strs.seg_is
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_strs_seg_is

theorem tot_strs_seg_nonempty (segs : Slice (alloc.vec.Vec Std.U8)) (i : Std.Usize) :
    strs.seg_nonempty segs i ⦃ _ => True ⦄ := by
  unfold strs.seg_nonempty
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_strs_seg_nonempty

theorem tot_paths_is_nuget_push_path (path : Slice Std.U8) (hs : path.val.length < Usize.max) :
    paths.is_nuget_push_path path ⦃ _ => True ⦄ := by
  unfold paths.is_nuget_push_path
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_is_nuget_push_path

theorem tot_http_extract_nuget_push_api_key (req : http.Request) (hp : req.path.val.length < Usize.max) (hh : ∀ h ∈ req.headers.val, h.2.val.length < Usize.max) :
    http.extract_nuget_push_api_key req ⦃ _ => True ⦄ := by
  unfold http.extract_nuget_push_api_key
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_http_extract_nuget_push_api_key

theorem tot_strs_contains_byte_loop (s : Slice Std.U8) (b : Std.U8) (i : Std.Usize) (hi : i.val ≤ s.val.length) :
    strs.contains_byte_loop s b i ⦃ _ => True ⦄ := by
  unfold strs.contains_byte_loop
  h5i_total (fun i => i) s.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_strs_contains_byte_loop

theorem tot_strs_contains_byte (s : Slice Std.U8) (b : Std.U8) :
    strs.contains_byte s b ⦃ _ => True ⦄ := by
  unfold strs.contains_byte
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_strs_contains_byte

theorem tot_http_extract_token_from_auth_header (auth_header : Slice Std.U8) :
    http.extract_token_from_auth_header auth_header ⦃ _ => True ⦄ := by
  unfold http.extract_token_from_auth_header
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_http_extract_token_from_auth_header

theorem tot_http_find_session_cookie_loop (pieces : Slice (alloc.vec.Vec Std.U8)) (i : Std.Usize) (hi : i.val ≤ pieces.val.length) :
    http.find_session_cookie_loop pieces i ⦃ _ => True ⦄ := by
  unfold http.find_session_cookie_loop
  h5i_total (fun i => i) pieces.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_http_find_session_cookie_loop

theorem tot_http_find_session_cookie (pieces : Slice (alloc.vec.Vec Std.U8)) :
    http.find_session_cookie pieces ⦃ _ => True ⦄ := by
  unfold http.find_session_cookie
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_http_find_session_cookie

theorem tot_http_session_cookie_token (headers : Slice ((alloc.vec.Vec Std.U8) × (alloc.vec.Vec Std.U8))) (hh : ∀ h ∈ headers.val, h.2.val.length < Usize.max) :
    http.session_cookie_token headers ⦃ _ => True ⦄ := by
  unfold http.session_cookie_token
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_http_session_cookie_token

theorem tot_http_extract_token (req : http.Request) (hp : req.path.val.length < Usize.max) (hh : ∀ h ∈ req.headers.val, h.2.val.length < Usize.max) :
    http.extract_token req ⦃ _ => True ⦄ := by
  unfold http.extract_token
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_http_extract_token

theorem tot_paths_extract_conda_url_token (path : Slice Std.U8) (hs : path.val.length < Usize.max) :
    paths.extract_conda_url_token path ⦃ _ => True ⦄ := by
  unfold paths.extract_conda_url_token
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_extract_conda_url_token

theorem tot_http_extract_visibility_token (req : http.Request) (hp : req.path.val.length < Usize.max) (hh : ∀ h ∈ req.headers.val, h.2.val.length < Usize.max) :
    http.extract_visibility_token req ⦃ _ => True ⦄ := by
  unfold http.extract_visibility_token
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_http_extract_visibility_token

theorem tot_tables_Db_fails_loop (self : tables.Db) (q : tables.Query) (i : Std.Usize) (hi : i.val ≤ self.failing.val.length) :
    tables.Db.fails_loop self q i ⦃ _ => True ⦄ := by
  unfold tables.Db.fails_loop
  h5i_total (fun i => i) self.failing.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_tables_Db_fails_loop

theorem tot_tables_Db_fails (self : tables.Db) (q : tables.Query) :
    tables.Db.fails self q ⦃ _ => True ⦄ := by
  unfold tables.Db.fails
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_tables_Db_fails

theorem tot_middleware_lookup_repo_loop (db : tables.Db) (repo_key : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ db.repositories.val.length) :
    middleware.lookup_repo_loop db repo_key i ⦃ _ => True ⦄ := by
  unfold middleware.lookup_repo_loop
  h5i_total (fun i => i) db.repositories.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_middleware_lookup_repo_loop

theorem tot_middleware_lookup_repo (db : tables.Db) (repo_key : Slice Std.U8) :
    middleware.lookup_repo db repo_key ⦃ _ => True ⦄ := by
  unfold middleware.lookup_repo
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_middleware_lookup_repo

theorem tot_trusted_Oracle_base64_decode_loop (self : trusted.Oracle) (input : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ self.base64.val.length) :
    trusted.Oracle.base64_decode_loop self input i ⦃ _ => True ⦄ := by
  unfold trusted.Oracle.base64_decode_loop
  h5i_total (fun i => i) self.base64.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_trusted_Oracle_base64_decode_loop

theorem tot_trusted_Oracle_base64_decode (self : trusted.Oracle) (input : Slice Std.U8) :
    trusted.Oracle.base64_decode self input ⦃ _ => True ⦄ := by
  unfold trusted.Oracle.base64_decode
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_trusted_Oracle_base64_decode

theorem tot_resolve_decode_basic_credentials (oracle : trusted.Oracle) (encoded : Slice Std.U8) :
    resolve.decode_basic_credentials oracle encoded ⦃ _ => True ⦄ := by
  unfold resolve.decode_basic_credentials
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_resolve_decode_basic_credentials

theorem tot_resolve_classify_token_validation_err (err : trusted.AuthErr) :
    resolve.classify_token_validation_err err ⦃ _ => True ⦄ := by
  unfold resolve.classify_token_validation_err
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_resolve_classify_token_validation_err

theorem tot_token_scope_scopes_grant_access (scopes : Slice (alloc.vec.Vec Std.U8)) (required_scope : Slice Std.U8) :
    token_scope.scopes_grant_access scopes required_scope ⦃ _ => True ⦄ := by
  unfold token_scope.scopes_grant_access
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_token_scope_scopes_grant_access

theorem tot_token_scope_AuthExtension_has_scope (self : AuthExtension) (scope : Slice Std.U8) :
    token_scope.AuthExtension.has_scope self scope ⦃ _ => True ⦄ := by
  unfold token_scope.AuthExtension.has_scope
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_token_scope_AuthExtension_has_scope

theorem tot_token_scope_AuthExtension_with_scope_gated_admin (self : AuthExtension) :
    token_scope.AuthExtension.with_scope_gated_admin self ⦃ _ => True ⦄ := by
  unfold token_scope.AuthExtension.with_scope_gated_admin
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_token_scope_AuthExtension_with_scope_gated_admin

theorem tot_trusted_Oracle_validate_api_token_loop (self : trusted.Oracle) (token : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ self.api_tokens.val.length) :
    trusted.Oracle.validate_api_token_loop self token i ⦃ _ => True ⦄ := by
  unfold trusted.Oracle.validate_api_token_loop
  h5i_total (fun i => i) self.api_tokens.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_trusted_Oracle_validate_api_token_loop

theorem tot_trusted_Oracle_validate_api_token (self : trusted.Oracle) (token : Slice Std.U8) :
    trusted.Oracle.validate_api_token self token ⦃ _ => True ⦄ := by
  unfold trusted.Oracle.validate_api_token
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_trusted_Oracle_validate_api_token

theorem tot_resolve_validate_api_token_with_scopes (oracle : trusted.Oracle) (token : Slice Std.U8) :
    resolve.validate_api_token_with_scopes oracle token ⦃ _ => True ⦄ := by
  unfold resolve.validate_api_token_with_scopes
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_resolve_validate_api_token_with_scopes

theorem tot_AccessScope_from_option (value : Option (alloc.vec.Vec Std.U64)) :
    AccessScope.from_option value ⦃ _ => True ⦄ := by
  unfold AccessScope.from_option
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_AccessScope_from_option

theorem tot_Claims_effective_iat_ms (self : Claims) :
    Claims.effective_iat_ms self ⦃ _ => True ⦄ := by
  unfold Claims.effective_iat_ms
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (simp_all only [I64.rMax, I64.rMin, Int.reduceTDiv]<;> scalar_tac)

attribute [local step] tot_Claims_effective_iat_ms

theorem tot_clone_opt_scopes (s : Option (alloc.vec.Vec (alloc.vec.Vec Std.U8))) :
    clone_opt_scopes s ⦃ _ => True ⦄ := by
  unfold clone_opt_scopes
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_clone_opt_scopes

theorem tot_token_scope_from_claims (claims : Claims) :
    token_scope.from_claims claims ⦃ _ => True ⦄ := by
  unfold token_scope.from_claims
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_token_scope_from_claims

theorem tot_token_scope_from_user (user : User) :
    token_scope.from_user user ⦃ _ => True ⦄ := by
  unfold token_scope.from_user
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_token_scope_from_user

theorem tot_trusted_Oracle_authenticate_loop (self : trusted.Oracle) (username : Slice Std.U8) (password : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ self.passwords.val.length) :
    trusted.Oracle.authenticate_loop self username password i ⦃ _ => True ⦄ := by
  unfold trusted.Oracle.authenticate_loop
  h5i_total (fun i => i) self.passwords.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_trusted_Oracle_authenticate_loop

theorem tot_trusted_Oracle_authenticate (self : trusted.Oracle) (username : Slice Std.U8) (password : Slice Std.U8) :
    trusted.Oracle.authenticate self username password ⦃ _ => True ⦄ := by
  unfold trusted.Oracle.authenticate
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_trusted_Oracle_authenticate

theorem tot_clone_opt_i64 (v : Option Std.I64) :
    clone_opt_i64 v ⦃ _ => True ⦄ := by
  unfold clone_opt_i64
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_clone_opt_i64

theorem tot_clone_opt_ids (v : Option (alloc.vec.Vec Std.U64)) :
    clone_opt_ids v ⦃ _ => True ⦄ := by
  unfold clone_opt_ids
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_clone_opt_ids

theorem tot_Claims_duplicate (self : Claims) :
    Claims.duplicate self ⦃ _ => True ⦄ := by
  unfold Claims.duplicate
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_Claims_duplicate

theorem tot_trusted_Oracle_validate_access_token_loop (self : trusted.Oracle) (token : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ self.jwt.val.length) :
    trusted.Oracle.validate_access_token_loop self token i ⦃ _ => True ⦄ := by
  unfold trusted.Oracle.validate_access_token_loop
  h5i_total (fun i => i) self.jwt.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_trusted_Oracle_validate_access_token_loop

theorem tot_trusted_Oracle_validate_access_token (self : trusted.Oracle) (token : Slice Std.U8) :
    trusted.Oracle.validate_access_token self token ⦃ _ => True ⦄ := by
  unfold trusted.Oracle.validate_access_token
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_trusted_Oracle_validate_access_token

theorem tot_resolve_resolve_basic (oracle : trusted.Oracle) (encoded : Slice Std.U8) (allow_basic_api_token : Bool) :
    resolve.resolve_basic oracle encoded allow_basic_api_token ⦃ _ => True ⦄ := by
  unfold resolve.resolve_basic
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_resolve_resolve_basic

theorem tot_resolve_resolve_bearer (oracle : trusted.Oracle) (token : Slice Std.U8) :
    resolve.resolve_bearer oracle token ⦃ _ => True ⦄ := by
  unfold resolve.resolve_bearer
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_resolve_resolve_bearer

theorem tot_resolve_try_resolve_auth_outcome (oracle : trusted.Oracle) (extracted : http.ExtractedToken) (allow_basic_api_token : Bool) :
    resolve.try_resolve_auth_outcome oracle extracted allow_basic_api_token ⦃ _ => True ⦄ := by
  unfold resolve.try_resolve_auth_outcome
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_resolve_try_resolve_auth_outcome

theorem tot_middleware_no_repo (oracle : trusted.Oracle) (req : http.Request) (hp : req.path.val.length < Usize.max) (hh : ∀ h ∈ req.headers.val, h.2.val.length < Usize.max) :
    middleware.no_repo oracle req ⦃ _ => True ⦄ := by
  unfold middleware.no_repo
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_middleware_no_repo

theorem tot_Visibility_allows_authenticated_read (self : Visibility) :
    Visibility.allows_authenticated_read self ⦃ _ => True ⦄ := by
  unfold Visibility.allows_authenticated_read
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_Visibility_allows_authenticated_read

theorem tot_middleware_role_grant_exists_loop (db : tables.Db) (user_id : Std.U64) (repo_id : Std.U64) (i : Std.Usize) (hi : i.val ≤ db.role_assignments.val.length) :
    middleware.role_grant_exists_loop db user_id repo_id i ⦃ _ => True ⦄ := by
  unfold middleware.role_grant_exists_loop
  h5i_total (fun i => i) db.role_assignments.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_middleware_role_grant_exists_loop

theorem tot_middleware_role_grant_exists (db : tables.Db) (user_id : Std.U64) (repo_id : Std.U64) :
    middleware.role_grant_exists db user_id repo_id ⦃ _ => True ⦄ := by
  unfold middleware.role_grant_exists
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_middleware_role_grant_exists

theorem tot_middleware_unwrap_false {E : Type} (r : core.result.Result Bool E) :
    middleware.unwrap_false r ⦃ _ => True ⦄ := by
  unfold middleware.unwrap_false
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_middleware_unwrap_false

theorem tot_paths_action_for_method (method : Method) :
    paths.action_for_method method ⦃ _ => True ⦄ := by
  unfold paths.action_for_method
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_action_for_method

theorem tot_paths_authenticated_read_satisfies_acl (visibility : Visibility) (action : Slice Std.U8) :
    paths.authenticated_read_satisfies_acl visibility action ⦃ _ => True ⦄ := by
  unfold paths.authenticated_read_satisfies_acl
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_authenticated_read_satisfies_acl

theorem tot_net_CidrRange_contains (self : net.CidrRange) (ip : net.IpAddr) :
    net.CidrRange.contains self ip ⦃ _ => True ⦄ := by
  unfold net.CidrRange.contains
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_net_CidrRange_contains

theorem tot_net_any_contains_loop (ranges : Slice net.CidrRange) (ip : net.IpAddr) (i : Std.Usize) (hi : i.val ≤ ranges.val.length) :
    net.any_contains_loop ranges ip i ⦃ _ => True ⦄ := by
  unfold net.any_contains_loop
  h5i_total (fun i => i) ranges.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_net_any_contains_loop

theorem tot_net_any_contains (ranges : Slice net.CidrRange) (ip : net.IpAddr) :
    net.any_contains ranges ip ⦃ _ => True ⦄ := by
  unfold net.any_contains
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_net_any_contains

theorem tot_permission_ip_condition (p : tables.Permission) (client_ip : Option net.IpAddr) :
    permission.ip_condition p client_ip ⦃ _ => True ⦄ := by
  unfold permission.ip_condition
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_ip_condition

theorem tot_permission_is_member_loop (db : tables.Db) (user_id : Std.U64) (group_id : Std.U64) (i : Std.Usize) (hi : i.val ≤ db.members.val.length) :
    permission.is_member_loop db user_id group_id i ⦃ _ => True ⦄ := by
  unfold permission.is_member_loop
  h5i_total (fun i => i) db.members.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_permission_is_member_loop

theorem tot_permission_is_member (db : tables.Db) (user_id : Std.U64) (group_id : Std.U64) :
    permission.is_member db user_id group_id ⦃ _ => True ⦄ := by
  unfold permission.is_member
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_is_member

theorem tot_permission_principal_matches (db : tables.Db) (p : tables.Permission) (user_id : Std.U64) :
    permission.principal_matches db p user_id ⦃ _ => True ⦄ := by
  unfold permission.principal_matches
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_principal_matches

theorem tot_permission_push_distinct
    (out : alloc.vec.Vec (alloc.vec.Vec U8)) (actions : Slice (alloc.vec.Vec U8))
    (ho : out.val.length + actions.val.length ≤ Usize.max) :
    permission.push_distinct out actions ⦃ r => r.val.length ≤ out.val.length + actions.val.length ⦄ := by
  unfold permission.push_distinct permission.push_distinct_loop
  apply loop_idx_spec _ (fun x => x.2) actions.val.length
    (fun x => x.1.val.length + (actions.val.length - x.2.val) ≤ out.val.length + actions.val.length)
    _ ?_ _ (by simp) (by simp)
  rintro ⟨acc, j⟩ hacc hj
  unfold permission.push_distinct_loop.body
  h5i_steps
  all_goals (simp_all<;> scalar_tac)
attribute [local step] tot_permission_push_distinct

theorem tot_permission_project_of_loop (db : tables.Db) (repo_id : Std.U64) (i : Std.Usize) (hi : i.val ≤ db.repositories.val.length) :
    permission.project_of_loop db repo_id i ⦃ _ => True ⦄ := by
  unfold permission.project_of_loop
  h5i_total (fun i => i) db.repositories.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_permission_project_of_loop

theorem tot_permission_project_of (db : tables.Db) (repo_id : Std.U64) :
    permission.project_of db repo_id ⦃ _ => True ⦄ := by
  unfold permission.project_of
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_project_of

theorem tot_permission_project_is (db : tables.Db) (repo_id : Std.U64) (target_id : Std.U64) :
    permission.project_is db repo_id target_id ⦃ _ => True ⦄ := by
  unfold permission.project_is
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_project_is

theorem tot_permission_target_matches (db : tables.Db) (p : tables.Permission) (target_type : Slice Std.U8) (target_id : Std.U64) :
    permission.target_matches db p target_type target_id ⦃ _ => True ⦄ := by
  unfold permission.target_matches
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_target_matches

theorem tot_permission_query_actions
    (db : tables.Db) (client_ip : Option net.IpAddr) (user_id : U64)
    (target_type : Slice U8) (target_id : U64)
    (hd : (db.permissions.val.map (·.actions.val.length)).sum < Usize.max) :
    permission.query_actions db client_ip user_id target_type target_id ⦃ _ => True ⦄ := by
  let budget (i : Nat) := ((db.permissions.val.drop i).map (·.actions.val.length)).sum
  have hl : permission.query_actions_loop db client_ip user_id target_type target_id
      (alloc.vec.Vec.new _) 0#usize ⦃ _ => True ⦄ := by
    unfold permission.query_actions_loop
    apply loop_idx_spec _ (fun x => x.2) db.permissions.val.length
      (fun x => x.1.val.length + budget x.2.val ≤ budget 0) _ ?_ _ (by simp [budget]) (by simp)
    rintro ⟨acc, i⟩ hacc hi
    by_cases hlt : i.val < db.permissions.val.length
    · have hzero : budget 0 = (db.permissions.val.map (·.actions.val.length)).sum := by simp [budget]
      have hsum : budget i.val = db.permissions.val[i.val].actions.val.length + budget (i.val + 1) := by
        simp only [budget, List.drop_eq_getElem_cons hlt, List.map_cons, List.sum_cons]
      unfold permission.query_actions_loop.body
      h5i_steps
      all_goals (try dsimp only; h5i_steps)
      all_goals (try (cases_type* Prod; h5i_steps))
      all_goals (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac)
    · dsimp only
      unfold permission.query_actions_loop.body
      h5i_steps
      all_goals scalar_tac
  unfold permission.query_actions
  h5i_steps
attribute [local step] tot_permission_query_actions

theorem tot_permission_check_permission (db : tables.Db) (client_ip : Option net.IpAddr) (user_id : Std.U64) (target_type : Slice Std.U8) (target_id : Std.U64) (action : Slice Std.U8) (is_admin : Bool) (hd : (db.permissions.val.map (·.actions.val.length)).sum < Usize.max) :
    permission.check_permission db client_ip user_id target_type target_id action is_admin ⦃ _ => True ⦄ := by
  unfold permission.check_permission
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_check_permission

theorem tot_permission_repo_target_matches (db : tables.Db) (p : tables.Permission) (repo_id : Std.U64) :
    permission.repo_target_matches db p repo_id ⦃ _ => True ⦄ := by
  unfold permission.repo_target_matches
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_repo_target_matches

theorem tot_permission_applicable (db : tables.Db) (p : tables.Permission) (client_ip : Option net.IpAddr) (user_id : Std.U64) (repo_id : Std.U64) :
    permission.applicable db p client_ip user_id repo_id ⦃ _ => True ⦄ := by
  unfold permission.applicable
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_applicable

theorem tot_permission_any_applicable_loop (db : tables.Db) (client_ip : Option net.IpAddr) (user_id : Std.U64) (repo_id : Std.U64) (i : Std.Usize) (hi : i.val ≤ db.permissions.val.length) :
    permission.any_applicable_loop db client_ip user_id repo_id i ⦃ _ => True ⦄ := by
  unfold permission.any_applicable_loop
  h5i_total (fun i => i) db.permissions.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_permission_any_applicable_loop

theorem tot_permission_any_applicable (db : tables.Db) (client_ip : Option net.IpAddr) (user_id : Std.U64) (repo_id : Std.U64) :
    permission.any_applicable db client_ip user_id repo_id ⦃ _ => True ⦄ := by
  unfold permission.any_applicable
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_any_applicable

theorem tot_permission_any_applicable_grants_loop (db : tables.Db) (client_ip : Option net.IpAddr) (user_id : Std.U64) (repo_id : Std.U64) (action : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ db.permissions.val.length) :
    permission.any_applicable_grants_loop db client_ip user_id repo_id action i ⦃ _ => True ⦄ := by
  unfold permission.any_applicable_grants_loop
  h5i_total (fun i => i) db.permissions.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_permission_any_applicable_grants_loop

theorem tot_permission_any_applicable_grants (db : tables.Db) (client_ip : Option net.IpAddr) (user_id : Std.U64) (repo_id : Std.U64) (action : Slice Std.U8) :
    permission.any_applicable_grants db client_ip user_id repo_id action ⦃ _ => True ⦄ := by
  unfold permission.any_applicable_grants
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_any_applicable_grants

theorem tot_permission_role_has_loop (db : tables.Db) (role_id : Std.U64) (perm : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ db.roles.val.length) :
    permission.role_has_loop db role_id perm i ⦃ _ => True ⦄ := by
  unfold permission.role_has_loop
  h5i_total (fun i => i) db.roles.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_permission_role_has_loop

theorem tot_permission_role_has (db : tables.Db) (role_id : Std.U64) (perm : Slice Std.U8) :
    permission.role_has db role_id perm ⦃ _ => True ⦄ := by
  unfold permission.role_has
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_role_has

theorem tot_permission_assigned_role_has_loop (db : tables.Db) (user_id : Std.U64) (repo_id : Std.U64) (perm : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ db.role_assignments.val.length) :
    permission.assigned_role_has_loop db user_id repo_id perm i ⦃ _ => True ⦄ := by
  unfold permission.assigned_role_has_loop
  h5i_total (fun i => i) db.role_assignments.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_permission_assigned_role_has_loop

theorem tot_permission_assigned_role_has (db : tables.Db) (user_id : Std.U64) (repo_id : Std.U64) (perm : Slice Std.U8) :
    permission.assigned_role_has db user_id repo_id perm ⦃ _ => True ⦄ := by
  unfold permission.assigned_role_has
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_assigned_role_has

theorem tot_permission_check_repository_action (db : tables.Db) (client_ip : Option net.IpAddr) (user_id : Std.U64) (repository_id : Std.U64) (action : Slice Std.U8) (is_admin : Bool) :
    permission.check_repository_action db client_ip user_id repository_id action is_admin ⦃ _ => True ⦄ := by
  unfold permission.check_repository_action
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_check_repository_action

theorem tot_permission_has_any_rules_for_target_loop (db : tables.Db) (target_type : Slice Std.U8) (target_id : Std.U64) (i : Std.Usize) (hi : i.val ≤ db.permissions.val.length) :
    permission.has_any_rules_for_target_loop db target_type target_id i ⦃ _ => True ⦄ := by
  unfold permission.has_any_rules_for_target_loop
  h5i_total (fun i => i) db.permissions.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_permission_has_any_rules_for_target_loop

theorem tot_permission_has_any_rules_for_target (db : tables.Db) (target_type : Slice Std.U8) (target_id : Std.U64) :
    permission.has_any_rules_for_target db target_type target_id ⦃ _ => True ⦄ := by
  unfold permission.has_any_rules_for_target
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_has_any_rules_for_target

theorem tot_middleware_permission_arm (db : tables.Db) (client_ip : Option net.IpAddr) (ext : AuthExtension) (repo_id : Std.U64) (visibility : Visibility) (req : http.Request) (is_write : Bool) (non_mutating_post : Bool) (hd : (db.permissions.val.map (·.actions.val.length)).sum < Usize.max) :
    middleware.permission_arm db client_ip ext repo_id visibility req is_write non_mutating_post ⦃ _ => True ⦄ := by
  unfold middleware.permission_arm
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_middleware_permission_arm

theorem tot_middleware_respond (writes : alloc.vec.Vec resolve.Write) (r : middleware.Response) :
    middleware.respond writes r ⦃ _ => True ⦄ := by
  unfold middleware.respond
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_middleware_respond

theorem tot_paths_percent_hex_val (b : U8) :
    paths.percent_hex_val b ⦃ r => ∀ v, r = some v → v.val < 16 ⦄ := by
  unfold paths.percent_hex_val
  h5i_steps
  all_goals (simp_all<;> scalar_tac)
attribute [local step] tot_paths_percent_hex_val

theorem tot_paths_percent_decode_bytes (bytes : Slice U8) (hs : bytes.val.length < Usize.max) :
    paths.percent_decode_bytes bytes ⦃ r => ∀ v, r = some v → v.val.length ≤ bytes.val.length ⦄ := by
  unfold paths.percent_decode_bytes paths.percent_decode_bytes_loop
  apply loop_idx_spec _ (fun x => x.2) bytes.val.length
    (fun x => x.1.val.length ≤ x.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨acc, i⟩ ha hi
  unfold paths.percent_decode_bytes_loop.body
  h5i_steps
  all_goals (simp_all<;> scalar_tac)
attribute [local step] tot_paths_percent_decode_bytes

theorem tot_paths_percent_decode_path_segment (segment : Slice U8)
    (hs : segment.val.length < Usize.max) :
    paths.percent_decode_path_segment segment ⦃ _ => True ⦄ := by
  unfold paths.percent_decode_path_segment
  h5i_steps
attribute [local step] tot_paths_percent_decode_path_segment

theorem tot_paths_extract_repo_key (path : Slice Std.U8) (hs : path.val.length < Usize.max) :
    paths.extract_repo_key path ⦃ _ => True ⦄ := by
  unfold paths.extract_repo_key
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

  all_goals
    have hm : raw ∈ segments.val := by
      rw [raw_post, x_post]
      exact List.getElem_mem (by scalar_tac)
    have hv := segments_post1 raw hm
    simp only [deref_val] at *
    omega
attribute [local step] tot_paths_extract_repo_key

theorem tot_paths_is_pypi_xmlrpc_tail (segments : Slice (alloc.vec.Vec Std.U8)) :
    paths.is_pypi_xmlrpc_tail segments ⦃ _ => True ⦄ := by
  unfold paths.is_pypi_xmlrpc_tail
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_is_pypi_xmlrpc_tail

theorem tot_paths_is_anonymous_readable_format_post (path : Slice Std.U8) (hs : path.val.length < Usize.max) :
    paths.is_anonymous_readable_format_post path ⦃ _ => True ⦄ := by
  unfold paths.is_anonymous_readable_format_post
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_is_anonymous_readable_format_post

theorem tot_paths_is_non_mutating_format_post (path : Slice Std.U8) (hs : path.val.length < Usize.max) :
    paths.is_non_mutating_format_post path ⦃ _ => True ⦄ := by
  unfold paths.is_non_mutating_format_post
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_is_non_mutating_format_post

theorem tot_paths_is_write_method (method : Method) :
    paths.is_write_method method ⦃ _ => True ⦄ := by
  unfold paths.is_write_method
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_is_write_method

theorem tot_paths_public_read_satisfies_acl (visibility : Visibility) (action : Slice Std.U8) :
    paths.public_read_satisfies_acl visibility action ⦃ _ => True ⦄ := by
  unfold paths.public_read_satisfies_acl
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_public_read_satisfies_acl

theorem tot_paths_should_allow_repo_access (visibility : Visibility) (has_auth : Bool) :
    paths.should_allow_repo_access visibility has_auth ⦃ _ => True ⦄ := by
  unfold paths.should_allow_repo_access
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_should_allow_repo_access

theorem tot_permission_check_anonymous_repository_action_loop (db : tables.Db) (client_ip : Option net.IpAddr) (repository_id : Std.U64) (action : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ db.permissions.val.length) :
    permission.check_anonymous_repository_action_loop db client_ip repository_id action i ⦃ _ => True ⦄ := by
  unfold permission.check_anonymous_repository_action_loop
  h5i_total (fun i => i) db.permissions.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_permission_check_anonymous_repository_action_loop

theorem tot_permission_check_anonymous_repository_action (db : tables.Db) (client_ip : Option net.IpAddr) (repository_id : Std.U64) (action : Slice Std.U8) :
    permission.check_anonymous_repository_action db client_ip repository_id action ⦃ _ => True ⦄ := by
  unfold permission.check_anonymous_repository_action
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_permission_check_anonymous_repository_action

theorem tot_paths_hex_digit (b : U8) :
    paths.hex_digit b ⦃ r => ∀ v, r = some v → v.val < 16 ⦄ := by
  unfold paths.hex_digit
  h5i_steps
  all_goals (simp_all<;> scalar_tac)
attribute [local step] tot_paths_hex_digit

theorem tot_strs_push_latin1 (out : alloc.vec.Vec Std.U8) (b : Std.U8) (ho : out.val.length + 2 ≤ Usize.max) :
    strs.push_latin1 out b ⦃ r => r.val.length ≤ out.val.length + 2 ⦄ := by
  unfold strs.push_latin1
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_strs_push_latin1

theorem tot_paths_decode_ticket (bytes : Slice U8) (hs : 2 * bytes.val.length < Usize.max) :
    paths.decode_ticket bytes ⦃ _ => True ⦄ := by
  unfold paths.decode_ticket paths.decode_ticket_loop
  apply loop_idx_spec _ (fun x => x.2) bytes.val.length
    (fun x => x.1.val.length ≤ 2 * x.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨acc, i⟩ ha hi
  unfold paths.decode_ticket_loop.body
  h5i_steps
  all_goals (simp_all<;> scalar_tac)
attribute [local step] tot_paths_decode_ticket

theorem tot_paths_find_ticket_pair (q : Slice U8) (hq : q.val.length < Usize.max) :
    paths.find_ticket_pair q ⦃ _ => True ⦄ := by
  unfold paths.find_ticket_pair paths.find_ticket_pair_loop
  apply loop_idx_spec _ (fun x => x.2) (q.val.length + 1) (fun _ => True) _ ?_ _ trivial (by simp)
  rintro ⟨start, i⟩ _ hi
  unfold paths.find_ticket_pair_loop.body
  h5i_steps
  all_goals (simp_all<;> scalar_tac)
attribute [local step] tot_paths_find_ticket_pair

theorem tot_paths_extract_ticket_from_query (query : Option (alloc.vec.Vec Std.U8)) (hq : ∀ q, query = some q → 2 * q.val.length < Usize.max) :
    paths.extract_ticket_from_query query ⦃ _ => True ⦄ := by
  unfold paths.extract_ticket_from_query
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_extract_ticket_from_query

theorem tot_paths_ticket_method_allowed (method : Method) :
    paths.ticket_method_allowed method ⦃ _ => True ⦄ := by
  unfold paths.ticket_method_allowed
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_ticket_method_allowed

theorem tot_paths_ticket_path_allowed (bound_path : Option (alloc.vec.Vec Std.U8)) (request_path : Slice Std.U8) :
    paths.ticket_path_allowed bound_path request_path ⦃ _ => True ⦄ := by
  unfold paths.ticket_path_allowed
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_ticket_path_allowed

theorem tot_resolve_active_user_loop (db : tables.Db) (user_id : Std.U64) (i : Std.Usize) (hi : i.val ≤ db.users.val.length) :
    resolve.active_user_loop db user_id i ⦃ _ => True ⦄ := by
  unfold resolve.active_user_loop
  h5i_total (fun i => i) db.users.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_resolve_active_user_loop

theorem tot_resolve_active_user (db : tables.Db) (user_id : Std.U64) :
    resolve.active_user db user_id ⦃ _ => True ⦄ := by
  unfold resolve.active_user
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_resolve_active_user

theorem tot_paths_clone_path (p : Option (alloc.vec.Vec Std.U8)) :
    paths.clone_path p ⦃ _ => True ⦄ := by
  unfold paths.clone_path
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_paths_clone_path

theorem tot_resolve_validate_download_ticket_loop (db : tables.Db) (writes : alloc.vec.Vec resolve.Write) (ticket : Slice Std.U8) (i : Std.Usize) (hw : writes.val.length < Usize.max) (hi : i.val ≤ db.tickets.val.length) :
    resolve.validate_download_ticket_loop db writes ticket i ⦃ _ => True ⦄ := by
  unfold resolve.validate_download_ticket_loop
  h5i_total (fun i => i) db.tickets.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_resolve_validate_download_ticket_loop

theorem tot_resolve_validate_download_ticket (db : tables.Db) (writes : alloc.vec.Vec resolve.Write) (ticket : Slice Std.U8) (hw : writes.val.length < Usize.max) :
    resolve.validate_download_ticket db writes ticket ⦃ _ => True ⦄ := by
  unfold resolve.validate_download_ticket
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_resolve_validate_download_ticket

theorem tot_resolve_try_resolve_ticket_auth (db : tables.Db) (writes : alloc.vec.Vec resolve.Write) (ticket : Slice Std.U8) (method : Method) (request_path : Slice Std.U8) (hw : writes.val.length < Usize.max) :
    resolve.try_resolve_ticket_auth db writes ticket method request_path ⦃ _ => True ⦄ := by
  unfold resolve.try_resolve_ticket_auth
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_resolve_try_resolve_ticket_auth

theorem tot_resolve_try_ticket (db : tables.Db) (writes : alloc.vec.Vec resolve.Write) (req : http.Request) (hw : writes.val.length < Usize.max) (hq : ∀ q, req.query = some q → 2 * q.val.length < Usize.max) :
    resolve.try_ticket db writes req ⦃ _ => True ⦄ := by
  unfold resolve.try_ticket
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_resolve_try_ticket

theorem tot_strs_contains_id_loop (list : Slice Std.U64) (x : Std.U64) (i : Std.Usize) (hi : i.val ≤ list.val.length) :
    strs.contains_id_loop list x i ⦃ _ => True ⦄ := by
  unfold strs.contains_id_loop
  h5i_total (fun i => i) list.val.length
  all_goals h5i_steps
  all_goals (try (simp_all -failIfUnchanged<;> scalar_tac))

attribute [local step] tot_strs_contains_id_loop

theorem tot_strs_contains_id (list : Slice Std.U64) (x : Std.U64) :
    strs.contains_id list x ⦃ _ => True ⦄ := by
  unfold strs.contains_id
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_strs_contains_id

theorem tot_AccessScope_grants (self : AccessScope) (repo_id : Std.U64) :
    AccessScope.grants self repo_id ⦃ _ => True ⦄ := by
  unfold AccessScope.grants
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_AccessScope_grants

theorem tot_token_scope_AuthExtension_access_scope (self : AuthExtension) :
    token_scope.AuthExtension.access_scope self ⦃ _ => True ⦄ := by
  unfold token_scope.AuthExtension.access_scope
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_token_scope_AuthExtension_access_scope

theorem tot_token_scope_AuthExtension_can_access_repo (self : AuthExtension) (repo_id : Std.U64) :
    token_scope.AuthExtension.can_access_repo self repo_id ⦃ _ => True ⦄ := by
  unfold token_scope.AuthExtension.can_access_repo
  h5i_steps
  all_goals (try dsimp only; h5i_steps)
  all_goals (try (cases_type* Prod; h5i_steps))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

attribute [local step] tot_token_scope_AuthExtension_can_access_repo


theorem total_bind {α β : Type} (m : Result α) (k : α → Result β)
    (hm : m ⦃ _ => True ⦄) (hk : ∀ x, k x ⦃ _ => True ⦄) :
    (do let x ← m; k x) ⦃ _ => True ⦄ := by
  apply WP.spec_bind hm
  intro x _
  exact hk x

open Lean Meta Elab Tactic in
elab "separate_bind" : tactic => withMainContext do
  let prog ← Aeneas.Step.getSpecProgram (← getMainTarget)
  unless prog.isAppOf ``Bind.bind || prog.isAppOf ``Aeneas.Std.bind do
    throwError "not a bind"
  evalTactic (← `(tactic| (apply total_bind; on_goal 2 => intro x)))

open Lean Meta Elab Tactic in
elab "split_product" : tactic => liftMetaTactic fun g => g.withContext do
  for d in ← getLCtx do
    if (← whnf d.type).isAppOf ``Prod then
      return (← g.cases d.fvarId).toList.map (·.mvarId)
  throwError "no product"

open Lean Meta Elab Tactic in
elab "reduce_program" : tactic => withMainContext do
  let g ← getMainGoal
  let ty ← getMainTarget
  let (info, args) ← Aeneas.Step.getSpecInfoArgs ty
  let prog := args[info.program_index]!
  let reduced ← if prog.isAppOf ``Aeneas.Std.uncurry then do
      let pa := prog.getAppArgs
      let a ← whnf (mkProj ``Prod 0 pa[4]!)
      let b ← whnf (mkProj ``Prod 1 pa[4]!)
      pure (mkApp2 pa[3]! a b).headBeta
    else
    match prog.consumeMData with
      | .letE _ _ v body _ => pure (body.instantiate1 v)
      | _ => match ← reduceMatcher? prog with
        | .reduced e => pure e
        | _ => throwError "no head reduction"
  replaceMainGoal [← g.replaceTargetDefEq (mkAppN ty.getAppFn (args.set! info.program_index reduced))]

theorem repo_visibility_total (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request)
    (hreq : req.path.length < Usize.max ∧ (∀ q, req.query = some q → 2 * q.length < Usize.max) ∧
      ∀ h ∈ req.headers.val, h.1.length < Usize.max ∧ h.2.length < Usize.max)
    (hdb : (db.permissions.val.map (·.actions.length)).sum < Usize.max) :
    ∃ y, middleware.repo_visibility_middleware db o ip req = ok y := by
  have hp : req.path.val.length < Usize.max := hreq.1
  have hq : ∀ q, req.query = some q → 2 * q.val.length < Usize.max := hreq.2.1
  have hh : ∀ h ∈ req.headers.val, h.2.val.length < Usize.max := fun h hm => (hreq.2.2 h hm).2
  apply ok_of (P := fun _ => True)
  unfold middleware.repo_visibility_middleware
  repeat' (first
    | (simp only [WP.spec_ok])
    | reduce_program
    | step -grind
    | spec_split
    | separate_bind
    | split_product
    | (fail_if_no_progress dsimp only))
  all_goals (try (simp_all -failIfUnchanged [alloc.vec.Vec.deref]<;> scalar_tac))

end artifactkeeper_kernel.Solution
