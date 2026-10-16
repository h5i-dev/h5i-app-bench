import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Solution

set_option maxRecDepth 4096
set_option maxHeartbeats 2000000

h5i_derive_clone Role Role.Insts.CoreCloneClone.clone
h5i_derive_clone tokens.CachedToken tokens.CachedToken.Insts.CoreCloneClone.clone
h5i_derive_clone tokens.TokenInfo tokens.TokenInfo.Insts.CoreCloneClone.clone
h5i_derive_clone tokens.TokenWrite tokens.TokenWrite.Insts.CoreCloneClone.clone
h5i_derive_eq middleware.HttpMethod middleware.HttpMethod.Insts.CoreCmpPartialEqHttpMethod.eq

@[step] theorem sat_sub_total (a b : U64) : lift (core.num.U64.saturating_sub a b)
    ⦃ r => r.val = a.val - b.val ⦄ := by
  simp [lift, core.num.U64.saturating_sub, saturating_sub_val]

@[step] theorem star_total (p : Slice U8) : is_star p ⦃ _ => True ⦄ := by
  unfold is_star
  step*

@[step] theorem bytes_total (a b : Slice U8) : bytes_eq a b ⦃ _ => True ⦄ := by
  unfold bytes_eq
  step*
  unfold bytes_eq_loop
  h5i_total (fun i => i) a.val.length

@[step] theorem oracle_bytes_total (a b : Slice U8) : oracle.bytes_eq a b ⦃ _ => True ⦄ := by
  unfold oracle.bytes_eq
  step*
  unfold oracle.bytes_eq_loop
  h5i_total (fun i => i) a.val.length

@[step] theorem starts_total (s p : Slice U8) : middleware.starts_with s p
    ⦃ b => b = true → p.val.length ≤ s.val.length ⦄ := by
  unfold middleware.starts_with
  step*
  unfold middleware.starts_with_loop
  h5i_total (fun i => i) p.val.length

@[step] theorem token_starts_total (s p : Slice U8) : tokens.starts_with s p
    ⦃ _ => True ⦄ := by
  unfold tokens.starts_with
  step*
  unfold tokens.starts_with_loop
  h5i_total (fun i => i) p.val.length

@[step] theorem ends_total (s p : Slice U8) : middleware.ends_with s p ⦃ _ => True ⦄ := by
  unfold middleware.ends_with
  step*
  unfold middleware.ends_with_loop
  h5i_total (fun i => i) p.val.length

@[step] theorem pair_total (t : Slice ((alloc.vec.Vec U8) × (alloc.vec.Vec U8)))
    (a b : Slice U8) : oracle.has_pair t a b ⦃ _ => True ⦄ := by
  unfold oracle.has_pair oracle.has_pair_loop
  h5i_total (fun i => i) t.val.length

@[step] theorem bcrypt_total (cr : oracle.Crypto) (a b : Slice U8) :
    oracle.Crypto.bcrypt_verify cr a b ⦃ _ => True ⦄ := by
  unfold oracle.Crypto.bcrypt_verify
  step*

@[step] theorem argon_total (cr : oracle.Crypto) (a b : Slice U8) :
    oracle.Crypto.argon2_verify cr a b ⦃ _ => True ⦄ := by
  unfold oracle.Crypto.argon2_verify
  step*

@[step] theorem authenticate_total (u : Slice ((alloc.vec.Vec U8) × (alloc.vec.Vec U8)))
    (cr : oracle.Crypto) (a b : Slice U8) : middleware.authenticate u cr a b ⦃ _ => True ⦄ := by
  unfold middleware.authenticate middleware.authenticate_loop
  h5i_total (fun i => i) u.val.length

@[step] theorem utf8_total (cr : oracle.Crypto) (s : Slice U8) :
    oracle.Crypto.is_utf8 cr s ⦃ _ => True ⦄ := by
  unfold oracle.Crypto.is_utf8 oracle.Crypto.is_utf8_loop
  h5i_total (fun i => i) cr.utf8_ok.val.length

@[step] theorem base64_total (cr : oracle.Crypto) (s : Slice U8) :
    oracle.Crypto.base64_decode cr s ⦃ _ => True ⦄ := by
  unfold oracle.Crypto.base64_decode oracle.Crypto.base64_decode_loop
  h5i_total (fun i => i) cr.base64.val.length

@[step] theorem sha_total (cr : oracle.Crypto) (s : Slice U8) :
    oracle.Crypto.sha256_hex cr s ⦃ _ => True ⦄ := by
  unfold oracle.Crypto.sha256_hex oracle.Crypto.sha256_hex_loop
  h5i_total (fun i => i) cr.sha256.val.length

@[step] theorem cached_total (s : Slice tokens.CachedToken) (k : Slice U8) :
    tokens.find_cached s k ⦃ _ => True ⦄ := by
  unfold tokens.find_cached tokens.find_cached_loop
  h5i_total (fun i => i) s.val.length

@[step] theorem file_total (s : Slice tokens.TokenFile) (k : Slice U8) :
    tokens.find_file s k ⦃ o => ∀ i, o = some i → i.val < s.val.length ⦄ := by
  unfold tokens.find_file tokens.find_file_loop
  h5i_total (fun i => i) s.val.length

-- Copying loops keep the output length below the current input index.
@[step] theorem copy_tail_total (s : Slice U8) (o : alloc.vec.Vec U8) (i : Usize)
    (hi : i.val ≤ s.val.length) (ho : o.val.length ≤ i.val) :
    middleware.strip_prefix_loop s o i ⦃ v => v.val.length ≤ s.val.length ⦄ := by
  unfold middleware.strip_prefix_loop
  apply loop_idx_spec _ (fun x => x.2) s.val.length
    (fun x => x.1.val.length ≤ x.2.val) _ ?_ _ ho hi
  rintro ⟨o, j⟩ ho hj
  unfold middleware.strip_prefix_loop.body
  h5i_step

@[step] theorem strip_total (s p : Slice U8) : middleware.strip_prefix s p ⦃ _ => True ⦄ := by
  unfold middleware.strip_prefix
  step*

@[step] theorem colon_left_total (s : Slice U8) (i : Usize) (a : alloc.vec.Vec U8)
    (j : Usize) (hi : i.val ≤ s.val.length) (hj : j.val ≤ i.val)
    (ha : a.val.length ≤ j.val) :
    middleware.split_once_colon_loop0_loop0 s i a j ⦃ _ => True ⦄ := by
  unfold middleware.split_once_colon_loop0_loop0
  apply loop_idx_spec _ (fun x => x.2) i.val
    (fun x => x.1.val.length ≤ x.2.val) _ ?_ _ ha hj
  rintro ⟨a, k⟩ ha hk
  unfold middleware.split_once_colon_loop0_loop0.body
  h5i_step

@[step] theorem colon_right_total (s : Slice U8) (b : alloc.vec.Vec U8) (k : Usize)
    (hk : k.val ≤ s.val.length) (hb : b.val.length ≤ k.val) :
    middleware.split_once_colon_loop0_loop1 s b k ⦃ _ => True ⦄ := by
  apply WP.spec_mono (copy_tail_total s b k hk hb)
  · exact fun _ _ => trivial

@[step] theorem colon_total (s : Slice U8) : middleware.split_once_colon s ⦃ _ => True ⦄ := by
  unfold middleware.split_once_colon middleware.split_once_colon_loop0
  h5i_total (fun i => i) s.val.length

@[step] theorem try_basic_total (s : Slice U8)
    (u : Option (alloc.vec.Vec ((alloc.vec.Vec U8) × (alloc.vec.Vec U8)))) (cr : oracle.Crypto) :
    middleware.try_basic_auth s u cr ⦃ _ => True ⦄ := by
  unfold middleware.try_basic_auth
  h5i_steps
  all_goals rcases p with ⟨username, password⟩; step*

@[step] theorem anonymous_total : middleware.anonymous ⦃ _ => True ⦄ := by
  unfold middleware.anonymous
  step*

@[step] theorem prefix_total (s : Slice U8) : tokens.prefix16 s ⦃ _ => True ⦄ := by
  unfold tokens.prefix16 tokens.prefix16_loop
  apply loop_idx_spec _ (fun x => x.2) 16
    (fun x => x.1.val.length ≤ x.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨o, i⟩ ho hi
  unfold tokens.prefix16_loop.body
  h5i_step

@[step] theorem verify_total (st : tokens.TokenStore) (cr : oracle.Crypto) (s : Slice U8)
    (now mono : U64) : tokens.verify_token st cr s now mono
      ⦃ r => r.1.val.length ≤ 3 ⦄ := by
  unfold tokens.verify_token
  h5i_steps <;> simp_all [alloc.vec.Vec.deref]

@[step] theorem ip_eq_total (a b : net.IpAddr) :
    net.IpAddr.Insts.CoreCmpPartialEqIpAddr.eq a b ⦃ _ => True ⦄ := by
  cases a <;> cases b <;> simp [net.IpAddr.Insts.CoreCmpPartialEqIpAddr.eq,
    net.IpAddr.read_discriminant, lift]

@[step] theorem failure_find_total (s : Slice lockout.FailureEntry) (ip : net.IpAddr) :
    lockout.find s ip ⦃ o => ∀ e, o = some e → e ∈ s.val ⦄ := by
  unfold lockout.find lockout.find_loop
  h5i_total (fun i => i) s.val.length

@[step] theorem failure_total (s : Slice lockout.FailureEntry) (ip : net.IpAddr) (now : U64)
    (hf : ∀ e ∈ s.val, e.failures.val < U32.max) :
    lockout.after_failure s ip now ⦃ _ => True ⦄ := by
  unfold lockout.after_failure
  h5i_steps

@[step] theorem blocked_total (tr : lockout.AuthFailureTracker)
    (s : Slice lockout.FailureEntry) (ip : net.IpAddr) (now : U64) :
    lockout.AuthFailureTracker.check_blocked tr s ip now ⦃ _ => True ⦄ := by
  unfold lockout.AuthFailureTracker.check_blocked
  h5i_steps <;> try scalar_tac
  all_goals unfold lockout.NANOS_PER_SEC; decide

@[step] theorem entry_total (nw ip : net.IpAddr) (p : U8) :
    net.entry_contains nw p ip ⦃ _ => True ⦄ := by
  unfold net.entry_contains
  h5i_steps

@[step] theorem proxies_total (tr : net.TrustedProxies) (ip : net.IpAddr) :
    net.TrustedProxies.contains tr ip ⦃ _ => True ⦄ := by
  unfold net.TrustedProxies.contains net.TrustedProxies.contains_loop
  h5i_total (fun i => i) tr.entries.val.length

@[step] theorem resolve_total (peer : net.IpAddr) (xff real : Option net.IpAddr)
    (tr : net.TrustedProxies) : net.resolve_client_ip peer xff real tr ⦃ _ => True ⦄ := by
  unfold net.resolve_client_ip
  h5i_steps

@[step] theorem start_at_total (s p : Slice U8) (f : Usize)
    (hf : f.val ≤ s.val.length) : starts_with_at s f p
      ⦃ b => b = true → f.val + p.val.length ≤ s.val.length ⦄ := by
  unfold starts_with_at
  step*
  unfold starts_with_at_loop
  h5i_total (fun i => i) p.val.length

@[step] theorem find_from_total (s p : Slice U8) (f : Usize)
    (hf : f.val ≤ s.val.length) (hp : 0 < p.val.length) :
    find_from s f p ⦃ o => ∀ k, o = some k → k.val + p.val.length ≤ s.val.length ⦄ := by
  unfold find_from find_from_loop
  h5i_total (fun i => i) s.val.length

-- The strict input bound leaves room to push the final piece after the loop.
@[step] theorem split_total (s : Slice U8) (sep : U8)
    (hs : s.val.length < Usize.max) : split s sep ⦃ _ => True ⦄ := by
  unfold split split_loop
  have hloop : loop (fun (o, c, i) => split_loop.body s sep o c i)
      (alloc.vec.Vec.new (alloc.vec.Vec U8), alloc.vec.Vec.new U8, 0#usize)
      ⦃ r => r.1.val.length ≤ s.val.length ⦄ := by
    apply loop_idx_spec _ (fun x => x.2.2) s.val.length
      (fun x => x.1.val.length ≤ x.2.2.val ∧ x.2.1.val.length ≤ x.2.2.val) _
      ?_ _ (by simp) (by simp)
    rintro ⟨o, c, i⟩ ⟨ho, hc⟩ hi
    unfold split_loop.body
    h5i_step
  step*

-- Each matched part preserves an offset within the subject's byte length.
@[step] theorem parts_total (ps : Slice (alloc.vec.Vec U8)) (s : Slice U8) :
    glob_parts ps s ⦃ _ => True ⦄ := by
  unfold glob_parts glob_parts_loop
  apply loop_idx_spec _ (fun x => x.2) ps.val.length
    (fun x => x.1.val ≤ s.val.length) _ ?_ _ (by simp) (by simp)
  rintro ⟨rem, i⟩ hr hi
  unfold glob_parts_loop.body
  h5i_steps <;> try simp_all [alloc.vec.Vec.deref]
    <;> try scalar_tac
  all_goals exact List.length_pos_iff.mpr (by assumption)

@[step] theorem glob_total (p s : Slice U8) (hp : p.val.length < Usize.max) :
    glob_match p s ⦃ _ => True ⦄ := by
  unfold glob_match
  h5i_steps

@[step] theorem match_role_total (p : OidcProvider) (s : Slice U8)
    (hp : ∀ r ∈ p.role_rules.val, r.pattern.val.length < Usize.max) :
    match_role p s ⦃ _ => True ⦄ := by
  unfold match_role match_role_loop
  h5i_total (fun i => i) p.role_rules.val.length
  simp only [alloc.vec.Vec.deref, Slice.from_val]
  apply hp
  apply List.getElem_mem

@[step] theorem claims_total (p : OidcProvider) (c : Claims)
    (hp : ∀ r ∈ p.role_rules.val, r.pattern.val.length < Usize.max) :
    validate_claims p c ⦃ _ => True ⦄ := by
  unfold validate_claims
  h5i_steps
  all_goals rcases x with ⟨role, scope⟩; step*

@[step] theorem has_star_total (s : Slice (alloc.vec.Vec U8)) : has_star s ⦃ _ => True ⦄ := by
  unfold has_star has_star_loop
  h5i_total (fun i => i) s.val.length

@[step] theorem scopes_total (s : Slice (alloc.vec.Vec U8))
    (r : Option (alloc.vec.Vec (alloc.vec.Vec U8))) (m : ScopeEnforcement) :
    from_oidc_scopes s r m ⦃ _ => True ⦄ := by
  unfold from_oidc_scopes
  h5i_steps
  intro x _
  exact vec_clone_eq _ x (fun _ => rfl)

@[step] theorem write_method_total (m : middleware.HttpMethod) :
    middleware.is_write_method m ⦃ _ => True ⦄ := by
  cases m <;> simp [middleware.is_write_method]

@[step] theorem can_write_total (r : Role) : Role.can_write r ⦃ _ => True ⦄ := by
  cases r <;> simp [Role.can_write]

@[step] theorem can_admin_total (r : Role) : Role.can_admin r ⦃ _ => True ⦄ := by
  cases r <;> simp [Role.can_admin]

@[step] theorem token_writes_total (ws : alloc.vec.Vec tokens.TokenWrite) :
    middleware.token_writes ws ⦃ out => out.val.length ≤ ws.val.length ⦄ := by
  unfold middleware.token_writes middleware.token_writes_loop
  apply loop_idx_spec _ (fun x => x.2) ws.val.length
    (fun x => x.1.val.length ≤ x.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨o, i⟩ ho hi
  unfold middleware.token_writes_loop.body
  h5i_step

@[step] theorem success_total (ws : alloc.vec.Vec middleware.Write) (ip : Option net.IpAddr)
    (hw : ws.val.length < Usize.max) : middleware.record_success ws ip
      ⦃ _ => True ⦄ := by
  unfold middleware.record_success
  h5i_steps

@[step] theorem token_identity_total (ws : alloc.vec.Vec middleware.Write)
    (ip : Option net.IpAddr) (m : middleware.HttpMethod) (a : Bool)
    (u : alloc.vec.Vec U8) (r : Role) (hw : ws.val.length < Usize.max) :
    middleware.token_identity ws ip m a u r ⦃ _ => True ⦄ := by
  unfold middleware.token_identity
  h5i_steps

@[step] theorem public_total (s : Slice U8) : middleware.is_public_path s ⦃ _ => True ⦄ := by
  unfold middleware.is_public_path
  h5i_steps

@[step] theorem web_total (s : Slice U8) : middleware.is_web_surface s ⦃ _ => True ⦄ := by
  unfold middleware.is_web_surface
  h5i_steps

@[step] theorem docker_total (s : Slice U8) : middleware.is_docker_path s ⦃ _ => True ⦄ := by
  unfold middleware.is_docker_path
  h5i_steps

@[step] theorem admin_total (s : Slice U8) : middleware.is_admin_path s ⦃ _ => True ⦄ := by
  unfold middleware.is_admin_path
  h5i_steps

@[step] theorem open_total (cfg : middleware.Config) (cr : oracle.Crypto)
    (req : middleware.Request) : middleware.open_path cfg cr req ⦃ _ => True ⦄ := by
  unfold middleware.open_path
  h5i_steps
  rcases p with ⟨user, role⟩
  step*

@[step] theorem oidc_total (jwt : Option middleware.Jwt) (s : Slice U8) :
    middleware.oidc_claims jwt s ⦃ _ => True ⦄ := by
  unfold middleware.oidc_claims
  h5i_steps

@[step] theorem bearer_total (cfg : middleware.Config) (cr : oracle.Crypto)
    (fs : Slice lockout.FailureEntry) (jwt : Option middleware.Jwt)
    (req : middleware.Request) (s : Slice U8) (ip : Option net.IpAddr) (a : Bool)
    (hf : ∀ e ∈ fs.val, e.failures.val < U32.max)
    (hp : ∀ p b, cfg.oidc = some (p, b) →
      ∀ r ∈ p.role_rules.val, r.pattern.val.length < Usize.max) :
    middleware.bearer cfg cr fs jwt req s ip a ⦃ _ => True ⦄ := by
  unfold middleware.bearer
  h5i_steps
  all_goals try rcases p with ⟨first, second⟩
  all_goals h5i_steps

@[step] theorem basic_total (cfg : middleware.Config) (cr : oracle.Crypto)
    (fs : Slice lockout.FailureEntry) (req : middleware.Request) (s : Slice U8)
    (ip : Option net.IpAddr) (a : Bool)
    (hf : ∀ e ∈ fs.val, e.failures.val < U32.max) :
    middleware.basic cfg cr fs req s ip a ⦃ _ => True ⦄ := by
  unfold middleware.basic
  h5i_steps
  all_goals try rcases p with ⟨username, password⟩
  all_goals h5i_steps
  all_goals try rcases p1 with ⟨user, role⟩
  all_goals h5i_steps

set_option maxHeartbeats 12000000 in
theorem middleware_total (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
    (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request)
    (hf : ∀ e ∈ fs.val, e.failures.val < U32.max)
    (hpat : ∀ p b, cfg.oidc = some (p, b) → ∀ rule ∈ p.role_rules.val, rule.pattern.length < Usize.max) :
    ∃ y, middleware.auth_middleware cfg fs cr jw req = ok y := by
  apply ok_of (P := fun _ => True)
  unfold middleware.auth_middleware
  h5i_steps
  all_goals try simp_all [alloc.vec.Vec.deref]
    <;> try (apply usize_lt_max; omega) <;> try scalar_tac

end nora_kernel.Solution
