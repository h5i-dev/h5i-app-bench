import Verified.Authn
import Verified.Rights
/-!
# Publish authorization (`controllers/krate/publish.rs`)
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec
open H5iAppLib hiding Covers
open Aeneas.Std.WP
open cratesio_kernel.Verified.Bytes cratesio_kernel.Verified.Auth cratesio_kernel.Verified.Scopes
  cratesio_kernel.Verified.Check cratesio_kernel.Verified.Authn cratesio_kernel.Verified.Rights

namespace cratesio_kernel.Verified.Publish

/-- An unexpired Trusted Publishing token row with this raw secret. -/
def TpLive (t : publish.TrustpubToken) (raw : List U8) (now : Int) : Prop :=
  now < t.expires_at.val ∧ t.raw.val = raw

instance (t : publish.TrustpubToken) (raw : List U8) (now : Int) : Decidable (TpLive t raw now) := by
  unfold TpLive; infer_instance

@[step] theorem find_tp_token_spec (tokens : alloc.vec.Vec publish.TrustpubToken) (s : Slice U8) (now : I64) :
    publish.find_tp_token tokens s now ⦃ o =>
      tokens.val.findIdx? (fun t => decide (TpLive t s.val now.val)) = o.map (·.val) ∧
      ∀ i, o = some i → i.val < tokens.val.length ⦄ := by
  unfold publish.find_tp_token publish.find_tp_token_loop
  apply WP.spec_mono (loop_search tokens.val (fun t => decide (TpLive t s.val now.val))
    (fun o : Option Usize => (o.map (·.val) : Option Nat)) (fun k _ => some k) none _ ?_ 0#usize (by simp))
  · intro r hr
    have := search_findIdx _ _ _ hr
    refine ⟨this.symm, fun i hi => ?_⟩
    rw [hi] at this
    simp only [Option.map_some] at this
    exact (List.findIdx?_eq_some_iff_findIdx_eq.1 this.symm).1
  · intro j hj; unfold publish.find_tp_token_loop.body
    simp only [bind_ite]
    step*
    all_goals simp_all [SearchStep, TpLive]
    all_goals scalar_tac

@[step] theorem is_id_spec (o : Option I32) (id : I32) : publish.is_id o id ⦃ b => decide (o = some id) = b ⦄ := by
  unfold publish.is_id; cases o <;> simp

@[step] theorem has_crate_spec (ids : Slice (Option I32)) (id : I32) :
    publish.has_crate ids id ⦃ b => decide (some id ∈ ids.val) = b ⦄ := by
  unfold publish.has_crate publish.has_crate_loop
  apply WP.spec_mono (loop_search ids.val (fun o => decide (o = some id)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    rw [search_any _ _ _ hr, eq_comm, Bool.eq_iff_iff]
    simp [List.any_eq_true]
  · intro j hj; unfold publish.has_crate_loop.body; h5i_step

theorem find_tp_some {tokens : alloc.vec.Vec publish.TrustpubToken} {s : Slice U8} {now : I64} {i : Usize}
    (h : publish.find_tp_token tokens s now = ok (some i)) :
    ∃ hi : i.val < tokens.val.length, TpLive (tokens.val[i.val]) s.val now.val := by
  have hp := post_of_ok (find_tp_token_spec tokens s now) h
  obtain ⟨h1, h2⟩ := hp
  refine ⟨h2 i rfl, ?_⟩
  simp only [Option.map_some] at h1
  simpa using (List.findIdx?_eq_some_iff_getElem.1 h1).2.1

/-- The Trusted Publishing branch accepts only an existing crate and an
unexpired token row, matching the presented token, that lists the crate. -/
theorem trustpub_auth_ok {existing : Option publish.Crate} {tp : alloc.vec.Vec publish.TrustpubToken}
    {token : Slice U8} {now : I64} {p : publish.Publisher}
    (h : publish.trustpub_auth existing tp token now = ok (.Ok p)) :
    ∃ k raw, existing = some k ∧ p = .TrustPub k.id ∧ publish.parse_access_token token = ok (some raw) ∧
      ∃ i, ∃ hi : i < tp.val.length, TpLive (tp.val[i]) raw.val now.val ∧ some k.id ∈ (tp.val[i]).crate_ids.val := by
  unfold publish.trustpub_auth at h
  h5i_invert h
  obtain ⟨hi, hl⟩ := find_tp_some ‹_›
  obtain ⟨hidx, hte⟩ := vec_index_ok htt
  have hc' := post_of_ok (has_crate_spec _ _) hb
  rw [hc] at hc'
  refine ⟨k, h_1, rfl, rfl, ho, i.val, hi, by simpa using hl, ?_⟩
  rw [hte]; simpa using hc'

/-- The user an authentication names. -/
def userOf : auth.Authentication → auth.User
  | .Cookie u => u
  | .Token _ u => u

theorem auth_user_eq (a : auth.Authentication) : publish.auth_user a = ok (userOf a) := by
  cases a <;> rfl

theorem rank_ge {r : rights.Rights} {i : U8} (h : rights.rank r = ok i) (hi : ¬ i < 1#u8) : r ≠ .None := by
  intro e; subst e; simp [rights.rank] at h; subst h; simp at hi

/-- What a granted publish establishes. -/
theorem publish_ok {name : Slice U8} {existing : Option publish.Crate} {ow : Option (alloc.vec.Vec rights.Owner)}
    {allowed : Slice U64} {users : Slice auth.User} {tokens : alloc.vec.Vec auth.ApiToken}
    {tp : alloc.vec.Vec publish.TrustpubToken} {req : auth.Request} {now : I64} {gh : Option Bool × Bool}
    {answers : Slice (I64 × rights.Membership)} {p : publish.Publisher}
    (h : publish.publish_auth name existing ow allowed users tokens tp req now gh answers = ok (.Ok p)) :
    match p with
    | .TrustPub id => ∃ hd t, req.authorization = some hd ∧ auth.parse_auth_header hd.deref = ok (.Ok t) ∧
        ∃ k raw, existing = some k ∧ id = k.id ∧ publish.parse_access_token t.deref = ok (some raw) ∧
          ∃ i, ∃ hi : i < tp.val.length, TpLive (tp.val[i]) raw.val now.val ∧ some k.id ∈ (tp.val[i]).crate_ids.val
    | .User uid => ∃ v a, v.val = name.val ∧
        auth.check { allow_token := true,
          endpoint_scope := some (match existing with | none => .PublishNew | some _ => .PublishUpdate),
          crate_name := some v, allow_any_crate_scope := false } allowed users tokens req now = ok (.Ok a) ∧
        uid = (userOf a).id ∧ (∀ k, existing = some k → k.trustpub_only = false) ∧
        (∀ owners, ow = some owners → rights.Owner.User uid ∈ owners.val ∨
          ∃ t, rights.Owner.Team t ∈ owners.val ∧ answerOf answers.val t = .Active ∧
            gh.1 = some true ∧ gh.2 = true) := by
  unfold publish.publish_auth at h
  h5i_invert h
  all_goals done

end cratesio_kernel.Verified.Publish
