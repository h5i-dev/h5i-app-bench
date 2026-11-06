import Verified.OrgConsistency
/-! The gRPC interceptor (`kernel/src/grpc.rs`): what an accepted request establishes. -/
open Aeneas Aeneas.Std Result openobserve_kernel openobserve_kernel.Spec openobserve_kernel.Verified
open H5iAppLib hiding lit

namespace openobserve_kernel.Verified

theorem push_ok {α} {v : alloc.vec.Vec α} {x : α} {w : alloc.vec.Vec α} (h : v.push x = ok w) :
    w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · simp at h; subst h; simp
  · simp at h

/-- A loop that pushes `s[i]` (or `f s[i]`) for each remaining index. -/
theorem push_loop_ok (s : Slice U8) (f : U8 → U8) (acc : List U8)
    (body : alloc.vec.Vec U8 × Usize → Result (ControlFlow (alloc.vec.Vec U8 × Usize) (alloc.vec.Vec U8)))
    (hbody : ∀ o j r, body (o, j) = ok r →
      (j.val < s.length → ∃ o' j', r = .cont (o', j') ∧ o'.val = o.val ++ [f (s.val[j.val]!)] ∧ j'.val = j.val + 1) ∧
      (¬ j.val < s.length → r = .done o))
    (out : alloc.vec.Vec U8) (i : Usize) (y : alloc.vec.Vec U8)
    (hinv : out.val = acc ++ (s.val.take i.val).map f ∧ i.val ≤ s.length)
    (h : loop body (out, i) = ok y) : y.val = acc ++ s.val.map f := by
  refine H5iAppLib.loop_ok body (fun x => x.1.val = acc ++ (s.val.take x.2.val).map f ∧ x.2.val ≤ s.length)
    (fun y => y.val = acc ++ s.val.map f) (fun x => s.length - x.2.val) ?_ (out, i) y hinv h
  rintro ⟨o, j⟩ r ⟨h1, h2⟩ hb
  obtain ⟨hc, hd⟩ := hbody o j r hb
  simp only at h1 h2
  by_cases hj : j.val < s.length
  · obtain ⟨o', j', rfl, ho', hj'⟩ := hc hj
    refine ⟨⟨?_, by simp only; omega⟩, by simp only; omega⟩
    simp only [ho', h1, hj']
    rw [take_succ_eq s.val j.val (by simpa using hj)]
    simp [List.getElem!_eq_getElem?_getD, List.getElem?_eq_getElem (show j.val < s.val.length by simpa using hj)]
    rw [take_succ_eq (s.val.map f) j.val (by simpa using hj)]
    simp
  · rw [hd hj]
    simp only [h1]
    rw [List.take_of_length_le (by simp at hj ⊢; omega)]

theorem join_key_ok {a b : Slice U8} {v : alloc.vec.Vec U8} (h : grpc.join_key a b = ok v) :
    nats v.val = joinKey (nats a.val) (nats b.val) := by
  unfold grpc.join_key at h
  h5i_invert h
  have hb0 : ∀ (s : Slice U8) o j r, grpc.join_key_loop0.body s o j = ok r →
      (j.val < s.length → ∃ o' j', r = .cont (o', j') ∧ o'.val = o.val ++ [_root_.id (s.val[j.val]!)] ∧ j'.val = j.val + 1) ∧
      (¬ j.val < s.length → r = .done o) := by
    intro s o j r hb
    unfold grpc.join_key_loop0.body at hb
    h5i_invert hb
    · obtain ⟨_, hx⟩ := H5iAppLib.slice_index_ok ‹Slice.index_usize _ _ = ok _›
      h5i_ok_facts
      refine ⟨fun _ => ⟨_, _, rfl, by rw [push_ok ‹_›, ← hx]; simp [List.getElem!_eq_getElem?_getD, List.getElem?_eq_getElem (by scalar_tac : j.val < s.val.length)], by scalar_tac⟩,
        fun h => absurd (by scalar_tac) h⟩
    · exact ⟨fun h => absurd (by scalar_tac) ‹¬ _›, fun _ => rfl⟩
  have hb1 : ∀ (s : Slice U8) o j r, grpc.join_key_loop1.body s o j = ok r →
      (j.val < s.length → ∃ o' j', r = .cont (o', j') ∧ o'.val = o.val ++ [_root_.id (s.val[j.val]!)] ∧ j'.val = j.val + 1) ∧
      (¬ j.val < s.length → r = .done o) := by
    intro s o j r hb
    unfold grpc.join_key_loop1.body at hb
    h5i_invert hb
    · obtain ⟨_, hx⟩ := H5iAppLib.slice_index_ok ‹Slice.index_usize _ _ = ok _›
      h5i_ok_facts
      refine ⟨fun _ => ⟨_, _, rfl, by rw [push_ok ‹_›, ← hx]; simp [List.getElem!_eq_getElem?_getD, List.getElem?_eq_getElem (by scalar_tac : j.val < s.val.length)], by scalar_tac⟩,
        fun h => absurd (by scalar_tac) h⟩
    · exact ⟨fun h => absurd (by scalar_tac) ‹¬ _›, fun _ => rfl⟩
  have h0 := push_loop_ok a _root_.id [] _ (fun o j r hb => hb0 a o j r hb) _ _ _ ⟨by simp, by simp⟩ hout
  have h1 := push_ok hout1
  have h2 := push_loop_ok b _root_.id (a.val ++ [47#u8]) _ (fun o j r hb => hb1 b o j r hb) _ _ _
    ⟨by simp [h1, h0], by simp⟩ h
  rw [h2]; simp [joinKey, nats]

theorem push_loop_ok_nats (s : Slice U8) (g : Nat → Nat) (acc : List Nat)
    (body : alloc.vec.Vec U8 × Usize → Result (ControlFlow (alloc.vec.Vec U8 × Usize) (alloc.vec.Vec U8)))
    (hbody : ∀ o j r, body (o, j) = ok r →
      (j.val < s.length → ∃ o' j', r = .cont (o', j') ∧ nats o'.val = nats o.val ++ [g (s.val[j.val]!).val] ∧ j'.val = j.val + 1) ∧
      (¬ j.val < s.length → r = .done o))
    (out : alloc.vec.Vec U8) (i : Usize) (y : alloc.vec.Vec U8)
    (hinv : nats out.val = acc ++ (s.val.take i.val).map (fun c => g c.val) ∧ i.val ≤ s.length)
    (h : loop body (out, i) = ok y) : nats y.val = acc ++ s.val.map (fun c => g c.val) := by
  refine H5iAppLib.loop_ok body (fun x => nats x.1.val = acc ++ (s.val.take x.2.val).map (fun c => g c.val) ∧ x.2.val ≤ s.length)
    (fun y => nats y.val = acc ++ s.val.map (fun c => g c.val)) (fun x => s.length - x.2.val) ?_ (out, i) y hinv h
  rintro ⟨o, j⟩ r ⟨h1, h2⟩ hb
  obtain ⟨hc, hd⟩ := hbody o j r hb
  simp only at h1 h2
  by_cases hj : j.val < s.length
  · obtain ⟨o', j', rfl, ho', hj'⟩ := hc hj
    refine ⟨⟨?_, by simp only; omega⟩, by simp only; omega⟩
    simp only [ho', h1, hj']
    rw [take_succ_eq s.val j.val (by simpa using hj)]
    simp [List.getElem!_eq_getElem?_getD, List.getElem?_eq_getElem (show j.val < s.val.length by simpa using hj)]
    rw [take_succ_eq (s.val.map (fun c => g c.val)) j.val (by simpa using hj)]
    simp
  · rw [hd hj]
    simp only [h1]
    rw [List.take_of_length_le (by simp at hj ⊢; omega)]

theorem ascii_lower_ok {s : Slice U8} {v : alloc.vec.Vec U8} (h : grpc.ascii_lower s = ok v) :
    nats v.val = asciiLower (nats s.val) := by
  unfold grpc.ascii_lower grpc.ascii_lower_loop at h
  have hb : ∀ o j r, grpc.ascii_lower_loop.body s o j = ok r →
      (j.val < s.length → ∃ o' j', r = .cont (o', j') ∧
        nats o'.val = nats o.val ++ [(fun c => if 65 ≤ c ∧ c ≤ 90 then c + 32 else c) (s.val[j.val]!).val] ∧ j'.val = j.val + 1) ∧
      (¬ j.val < s.length → r = .done o) := by
    intro o j r hb
    unfold grpc.ascii_lower_loop.body at hb
    h5i_invert hb
    · obtain ⟨_, hx⟩ := H5iAppLib.slice_index_ok ‹Slice.index_usize _ _ = ok _›
      h5i_ok_facts
      refine ⟨fun _ => ⟨_, _, rfl, ?_, by scalar_tac⟩, fun h => absurd (by scalar_tac) h⟩
      have hsj : s.val[j.val]! = c := by
        rw [← hx]; simp [List.getElem!_eq_getElem?_getD, List.getElem?_eq_getElem (by scalar_tac : j.val < s.val.length)]
      rw [hsj]
      split at hout1
      · split at hout1
        · obtain ⟨d, hd, hp⟩ := H5iAppLib.bind_eq_ok.1 hout1
          have hdv := (H5iAppLib.add_ok_val hd)
          rw [push_ok hp]
          have : 65 ≤ c.val ∧ c.val ≤ 90 := ⟨by scalar_tac, by scalar_tac⟩
          simp [nats, this]; scalar_tac
        · rw [push_ok hout1]
          have : ¬ (65 ≤ c.val ∧ c.val ≤ 90) := fun h => by scalar_tac
          simp [nats, this]
      · rw [push_ok hout1]
        have : ¬ (65 ≤ c.val ∧ c.val ≤ 90) := fun h => by scalar_tac
        simp [nats, this]
    · exact ⟨fun h => absurd (by scalar_tac) ‹¬ _›, fun _ => rfl⟩
  have := push_loop_ok_nats s (fun c => if 65 ≤ c ∧ c ≤ 90 then c + 32 else c) [] _ (fun o j r h => hb o j r h) _ _ _ ⟨by simp [nats], by simp⟩ h
  rw [this]; simp [nats, asciiLower]

open openobserve_kernel.grpc in
h5i_derive_clone grpc.OrgUserRow grpc.OrgUserRow.Insts.CoreCloneClone.clone
h5i_derive_clone grpc.UserRow grpc.UserRow.Insts.CoreCloneClone.clone
h5i_derive_clone grpc.User grpc.User.Insts.CoreCloneClone.clone

@[step] theorem find_org_user_spec (rows : Slice grpc.OrgUserRow) (key : Slice U8) :
    grpc.find_org_user rows key ⦃ o => o = rows.val.find? (fun r => decide (nats r.key.val = nats key.val)) ⦄ := by
  unfold grpc.find_org_user grpc.find_org_user_loop
  apply WP.spec_mono (loop_search rows.val (fun r => decide (nats r.key.val = nats key.val)) _root_.id
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro i hi
    unfold grpc.find_org_user_loop.body; simp only []
    step*
    · left; exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], by simp_all⟩
    · exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], by scalar_tac⟩
    · right; exact ⟨by scalar_tac, rfl⟩

@[step] theorem find_user_spec (rows : Slice grpc.UserRow) (key : Slice U8) :
    grpc.find_user rows key ⦃ o => o = rows.val.find? (fun r => decide (nats r.key.val = nats key.val)) ⦄ := by
  unfold grpc.find_user grpc.find_user_loop
  apply WP.spec_mono (loop_search rows.val (fun r => decide (nats r.key.val = nats key.val)) _root_.id
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro i hi
    unfold grpc.find_user_loop.body; simp only []
    step*
    · left; exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], by simp_all⟩
    · exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], by scalar_tac⟩
    · right; exact ⟨by scalar_tac, rfl⟩

def hashP (pw salt : List Nat) (r : grpc.HashRow) : Bool :=
  decide (nats r.password.val = pw) && decide (nats r.salt.val = salt)

@[step] theorem try_get_hash_spec (env : grpc.GrpcEnv) (pw salt : Slice U8) :
    grpc.try_get_hash env pw salt ⦃ o =>
      o = ((env.hashes.val.find? (hashP (nats pw.val) (nats salt.val))).map (·.hash)).getD none ⦄ := by
  unfold grpc.try_get_hash grpc.try_get_hash_loop
  apply WP.spec_mono (loop_search env.hashes.val (hashP (nats pw.val) (nats salt.val)) _root_.id
    (fun _ x => x.hash) none _ ?_ 0#usize (by simp))
  · intro r hr
    rw [_root_.id, searchFrom_findD] at hr
    simpa using hr
  · intro i hi
    unfold grpc.try_get_hash_loop.body; simp only []
    step*
    all_goals first
      | (left; exact ⟨by scalar_tac, by simp_all [hashP, alloc.vec.Vec.deref], by simp_all⟩)
      | (exact ⟨by scalar_tac, by simp_all [hashP, alloc.vec.Vec.deref], by scalar_tac⟩)
      | (right; exact ⟨by scalar_tac, rfl⟩)

/-- `is_root_user(uid)`: the cache row for `default/{uid}` has role Root. -/
def IsRoot (env : grpc.GrpcEnv) (uid : List Nat) : Prop :=
  ∃ r, env.org_users.val.find? (fun r => decide (nats r.key.val = joinKey [100, 101, 102, 97, 117, 108, 116] uid)) = some r ∧
    r.is_root = true

/-- What a found user record is, in terms of the tables. -/
def UserFacts (env : grpc.GrpcEnv) (org uid : List Nat) (u : grpc.User) : Prop :=
  (IsRoot env uid ∧ env.root_user = some u) ∨
  (¬ IsRoot env uid ∧
    ∃ ou ∈ env.org_users.val, nats ou.key.val = joinKey org (asciiLower uid) ∧
    ∃ ur ∈ env.users.val, nats ur.key.val = asciiLower uid ∧
      u = { email := ur.email, token := ou.token, password := ur.password, salt := ur.salt })

theorem default_org_val : nats (grpc.DEFAULT_ORG).val = [100, 101, 102, 97, 117, 108, 116] := by
  simp [grpc.DEFAULT_ORG, nats]

theorem is_root_user_ok {env : grpc.GrpcEnv} {uid : Slice U8} {b : Bool}
    (h : grpc.is_root_user env uid = ok b) : b = true ↔ IsRoot env (nats uid.val) := by
  unfold grpc.is_root_user at h
  h5i_invert h
  all_goals (have hk := join_key_ok ‹grpc.join_key _ _ = ok _›
             have hf := post_of_ok (find_org_user_spec _ _) ‹grpc.find_org_user _ _ = ok _›
             rw [default_org_val] at hk
             simp [alloc.vec.Vec.deref] at hf
             rw [hk] at hf)
  all_goals (simp only [IsRoot]; rw [← hf]; simp)

theorem get_cached_user_org_ok {env : grpc.GrpcEnv} {org uid : Slice U8} {u : grpc.User}
    (h : grpc.get_cached_user_org env org uid = ok (some u)) :
    ∃ ou ∈ env.org_users.val, nats ou.key.val = joinKey (nats org.val) (asciiLower (nats uid.val)) ∧
    ∃ ur ∈ env.users.val, nats ur.key.val = asciiLower (nats uid.val) ∧
      u = { email := ur.email, token := ou.token, password := ur.password, salt := ur.salt } := by
  unfold grpc.get_cached_user_org at h
  h5i_invert h
  have hl := ascii_lower_ok ‹grpc.ascii_lower _ = ok _›
  have hk := join_key_ok ‹grpc.join_key _ _ = ok _›
  have hf := post_of_ok (find_org_user_spec _ _) ‹grpc.find_org_user _ _ = ok _›
  have hu := post_of_ok (find_user_spec _ _) ‹grpc.find_user _ _ = ok _›
  simp [alloc.vec.Vec.deref] at hf hu hk
  rw [hl] at hk
  rw [hk] at hf
  rw [hl] at hu
  refine ⟨_, List.mem_of_find?_eq_some hf.symm, by simpa using List.find?_some hf.symm,
    _, List.mem_of_find?_eq_some hu.symm, by simpa using List.find?_some hu.symm, ?_⟩
  simp_all

theorem lookup_user_ok {env : grpc.GrpcEnv} {org uid : Slice U8} {u : grpc.User}
    (h : grpc.lookup_user env org uid = ok (some u)) : UserFacts env (nats org.val) (nats uid.val) u := by
  unfold grpc.lookup_user at h
  h5i_invert h
  · left; refine ⟨(is_root_user_ok hb).1 hc, ?_⟩
    have : u1 = u_1 := by simpa using hu1.symm
    simp_all
  · right; exact ⟨fun hr => hc ((is_root_user_ok hb).2 hr), get_cached_user_org_ok h⟩

theorem auth_token_ok {tok : Option (alloc.vec.Vec U8)} {t : alloc.vec.Vec U8}
    (h : grpc.auth_token tok = ok (.Ok t)) : tok = some t ∧ t.val ≠ [] := by
  unfold grpc.auth_token at h
  h5i_invert h
  rw [u8vec_clone] at hv
  have := Result.ok.inj hv; subst this
  refine ⟨rfl, fun he => hc ?_⟩
  apply UScalar.eq_of_val_eq; simp [he]

theorem token_matches_ok {t i : Slice U8} {s : Option (alloc.vec.Vec U8)}
    (h : grpc.token_matches t i s = ok true) :
    nats t.val = nats i.val ∨ ∃ x, s = some x ∧ nats x.val = nats t.val := by
  unfold grpc.token_matches at h
  h5i_invert h
  · have := post_of_ok (bytes_eq_spec _ _) hb
    subst hc; exact Or.inl (by simpa using this)
  · have := post_of_ok (bytes_eq_spec _ _) h
    exact Or.inr ⟨rest, rfl, by simpa [alloc.vec.Vec.deref] using this⟩

theorem attach_user_id_ok {uid : Slice U8} {a : grpc.Accept}
    (h : grpc.attach_user_id uid = ok (.Ok a)) : ∃ v, a = .User v ∧ nats v.val = nats uid.val := by
  unfold grpc.attach_user_id at h
  h5i_invert h
  have hs : alloc.slice.Slice.to_vec core.clone.CloneU8 uid ⦃ w => nats w.val = nats uid.val ⦄ := by
    step*; subst_vars; rfl
  have := post_of_ok hs hv
  exact ⟨v, rfl, this⟩

theorem password_matches_ok {env : grpc.GrpcEnv} {u : grpc.User} {c : grpc.Credentials}
    (h : grpc.password_matches env u c = ok true) :
    nats c.user_id.val = nats u.email.val ∧ ∃ hv,
      ((env.hashes.val.find? (hashP (nats c.password.val) (nats u.salt.val))).map (·.hash)).getD none = some hv ∧
      nats hv.val = nats u.password.val := by
  unfold grpc.password_matches at h
  h5i_invert h
  have h1 := post_of_ok (bytes_eq_spec _ _) hb
  have h2 := post_of_ok (try_get_hash_spec _ _ _) ho
  have h3 := post_of_ok (bytes_eq_spec _ _) h
  subst hc
  simp only [alloc.vec.Vec.deref] at h1 h2 h3
  refine ⟨by simpa using h1, rest, by simpa using h2.symm, by simpa using h3⟩

theorem ingest_prefix_val : nats (grpc.ORG_INGESTION_TOKEN_PREFIX).val = [111, 50, 111, 105, 95] := by
  simp [grpc.ORG_INGESTION_TOKEN_PREFIX, nats]

/-- The password path of a user credential. -/
def CredentialOk (env : grpc.GrpcEnv) (u : grpc.User) (c : grpc.Credentials) : Prop :=
  nats u.token.val = nats c.password.val ∨
    (nats c.user_id.val = nats u.email.val ∧ ∃ hv,
      ((env.hashes.val.find? (hashP (nats c.password.val) (nats u.salt.val))).map (·.hash)).getD none = some hv ∧
      nats hv.val = nats u.password.val)

def InternalToken (env : grpc.GrpcEnv) (t : alloc.vec.Vec U8) : Prop :=
  nats t.val = nats env.internal_token.val ∨ ∃ x, env.super_cluster_token = some x ∧ nats x.val = nats t.val

theorem check_auth_inner_user {env : grpc.GrpcEnv} {tok : Option (alloc.vec.Vec U8)} {org : grpc.OrgHeader}
    {creds : Option grpc.Credentials} {allow : Bool} {uid : alloc.vec.Vec U8}
    (h : grpc.check_auth_inner env tok org creds allow = ok (.Ok (.User uid))) :
    ∃ t o c, tok = some t ∧ t.val ≠ [] ∧ org = .Value o ∧ creds = some c ∧ c.password.val ≠ [] ∧
      nats uid.val = nats c.user_id.val ∧
      ((allow = true ∧ [111, 50, 111, 105, 95] <+: nats c.password.val ∧
          joinKey (nats o.val) (nats c.password.val) ∈ env.ingestion_keys.val.map (fun k => nats k.val)) ∨
       ((allow = true → ¬ [111, 50, 111, 105, 95] <+: nats c.password.val) ∧
          ∃ u, UserFacts env (nats o.val) (nats c.user_id.val) u ∧ CredentialOk env u c)) := by
  unfold grpc.check_auth_inner at h
  h5i_invert h
  all_goals
    obtain ⟨htok, hne⟩ := auth_token_ok hr
    obtain ⟨v', hv', hvn⟩ := attach_user_id_ok h
    cases hv'
    refine ⟨t, _, c, htok, hne, rfl, rfl,
      fun he => ‹¬ c.password.len = 0#usize› (by apply UScalar.eq_of_val_eq; simp [he]),
      by simpa [alloc.vec.Vec.deref] using hvn, ?_⟩
  · left
    have hp := post_of_ok (starts_with_spec _ _) hb1
    rw [ingest_prefix_val] at hp
    have hk := join_key_ok hv
    have hcn := post_of_ok (contains_spec _ _) hb2
    simp [alloc.vec.Vec.deref] at hp hk hcn
    refine ⟨hc_2, by simpa [hc_3] using hp, ?_⟩
    rw [← hk]; simpa [hc_4] using hcn
  all_goals right
  all_goals
    have hu := lookup_user_ok ho1
    refine ⟨?_, u, by simpa [alloc.vec.Vec.deref] using hu, ?_⟩
  all_goals first
    | (intro ha; exact absurd ha ‹¬ allow = true›)
    | (intro _; have hp := post_of_ok (starts_with_spec _ _) hb1; rw [ingest_prefix_val] at hp
       simp [alloc.vec.Vec.deref] at hp; simp_all; done)
    | (left; have := post_of_ok (bytes_eq_spec _ _) hb2; simp [alloc.vec.Vec.deref] at this; simp_all; done)
    | (right; subst_vars; have := password_matches_ok ‹grpc.password_matches _ _ _ = ok true›; simpa using this)

theorem check_auth_inner_internal {env : grpc.GrpcEnv} {tok : Option (alloc.vec.Vec U8)} {org : grpc.OrgHeader}
    {creds : Option grpc.Credentials} {allow : Bool}
    (h : grpc.check_auth_inner env tok org creds allow = ok (.Ok .Internal)) :
    ∃ t, tok = some t ∧ t.val ≠ [] ∧ InternalToken env t := by
  unfold grpc.check_auth_inner at h
  h5i_invert h
  all_goals first
    | (obtain ⟨v', hv', -⟩ := attach_user_id_ok h; cases hv')
    | (obtain ⟨htok, hne⟩ := auth_token_ok hr
       subst hc
       have := token_matches_ok hb
       exact ⟨t, htok, hne, by simpa [InternalToken, alloc.vec.Vec.deref] using this⟩)

theorem check_internal_auth_ok {env : grpc.GrpcEnv} {tok : Option (alloc.vec.Vec U8)} {a : grpc.Accept}
    (h : grpc.check_internal_auth env tok = ok (.Ok a)) :
    a = .Internal ∧ ∃ t, tok = some t ∧ t.val ≠ [] ∧ InternalToken env t := by
  unfold grpc.check_internal_auth at h
  h5i_invert h
  obtain ⟨htok, hne⟩ := auth_token_ok hr
  subst hc
  have := token_matches_ok hb
  exact ⟨rfl, t, htok, hne, by simpa [InternalToken, alloc.vec.Vec.deref] using this⟩

end openobserve_kernel.Verified
