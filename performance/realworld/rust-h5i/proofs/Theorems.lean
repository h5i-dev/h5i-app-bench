import ConduitKernel
import H5iAppLib
open Aeneas Aeneas.Std Result Aeneas.Std.WP H5iAppLib

h5i_derive_all

namespace conduit_kernel

set_option maxHeartbeats 40000000

def bytes (l : List Std.U8) (h : l.length ≤ Std.Usize.max) : alloc.vec.Vec Std.U8 :=
  alloc.vec.Vec.from l h

def oneByte : alloc.vec.Vec Std.U8 := bytes [97#u8] (by scalar_tac)
def sevenBytes : alloc.vec.Vec Std.U8 :=
  bytes [1#u8, 1#u8, 1#u8, 1#u8, 1#u8, 1#u8, 1#u8] (by scalar_tac)
def emptyBytes : alloc.vec.Vec Std.U8 := bytes [] (by scalar_tac)

theorem empty_len : alloc.vec.Vec.len emptyBytes = 0#usize := by
  apply UScalar.eq_of_val_eq
  simp [emptyBytes, bytes, alloc.vec.Vec.from_val]
theorem one_len : alloc.vec.Vec.len oneByte = 1#usize := by
  apply UScalar.eq_of_val_eq
  simp [oneByte, bytes, alloc.vec.Vec.from_val]
theorem seven_len : alloc.vec.Vec.len sevenBytes = 7#usize := by
  apply UScalar.eq_of_val_eq
  simp [sevenBytes, bytes, alloc.vec.Vec.from_val]

abbrev R := core.result.Result Reply Error

def errAuth : R := .Err .Unauthenticated
def err (e : Error) : R := .Err e
def allow : R := .Ok .Allow

/-- Commands that change or reveal a user's own data. Guests are refused. -/
def Mutating : Command → Prop
  | .UpdateUser _ _ _ _ _ => True
  | .CreateArticle _ _ _ _ => True
  | .UpdateArticle _ _ _ _ => True
  | .DeleteArticle => True
  | .CreateComment _ => True
  | .DeleteComment => True
  | .Follow => True
  | .Unfollow => True
  | .Favorite => True
  | .Unfavorite => True
  | .CurrentUser => True
  | .Feed => True
  | _ => False

theorem guest_cannot_mutate (v : View) (c : Command) (ha : v.actor = 0#u64) (hm : Mutating c) :
    transition v c ⦃ r => r = errAuth ⦄ := by
  cases c
  case Register => simp [Mutating] at hm
  case Login => simp [Mutating] at hm
  case Page => simp [Mutating] at hm
  case Slug => simp [Mutating] at hm
  all_goals (unfold transition authed; simp [ha, errAuth])

/-- An article update is `Ok` only for the article's author. Field validation is
irrelevant: every `Ok` arm sits under the same ownership test. -/
theorem only_author_updates_article
    (v : View) (title description body : RawText) (tags : TagInput) :
    transition v (.UpdateArticle title description body tags) ⦃ r =>
      ∀ a b c d, r = .Ok (.ArticleUpdate a b c d) →
        v.actor ≠ 0#u64 ∧ v.article_exists = true ∧ v.article_author = v.actor ⦄ := by
  unfold transition authed update_article optional_required tags_of
  h5i_steps

theorem only_author_deletes_article (v : View) :
    transition v .DeleteArticle ⦃ r =>
      (r = allow → v.actor ≠ 0#u64 ∧ v.article_exists = true ∧ v.article_author = v.actor) ∧
      (v.actor ≠ 0#u64 → v.article_exists = true → v.article_author ≠ v.actor →
        r = err .ForbiddenArticle) ⦄ := by
  unfold transition authed delete_article
  h5i_steps
  all_goals (simp_all [allow, err, ↓reduceCtorEq])

theorem only_author_deletes_comment (v : View) :
    transition v .DeleteComment ⦃ r =>
      (r = allow →
        v.actor ≠ 0#u64 ∧ v.article_exists = true ∧ v.comment_exists = true ∧
          v.comment_author = v.actor) ∧
      (v.actor ≠ 0#u64 → v.article_exists = true → v.comment_exists = true →
        v.comment_author ≠ v.actor → r = err .ForbiddenComment) ⦄ := by
  unfold transition authed delete_comment
  h5i_steps
  all_goals (simp_all [allow, err, ↓reduceCtorEq])

theorem favorite_consistent (v : View) (ha : v.actor ≠ 0#u64) (hx : v.article_exists = true) :
    (v.already = true →
      transition v .Favorite ⦃ r => r = .Ok (.Favorite true .Same) ⦄) ∧
    (v.already = false →
      transition v .Favorite ⦃ r => r = .Ok (.Favorite true .Up) ⦄) := by
  constructor
  · intro hb
    unfold transition authed favorite
    simp [ha, hx, hb]
  · intro hb
    unfold transition authed favorite
    simp [ha, hx, hb]

theorem unfavorite_consistent (v : View) (ha : v.actor ≠ 0#u64) (hx : v.article_exists = true) :
    (v.already = true →
      transition v .Unfavorite ⦃ r => r = .Ok (.Favorite false .Down) ⦄) ∧
    (v.already = false →
      transition v .Unfavorite ⦃ r => r = .Ok (.Favorite false .Same) ⦄) := by
  constructor
  · intro hb
    unfold transition authed favorite
    simp [ha, hx, hb]
  · intro hb
    unfold transition authed favorite
    simp [ha, hx, hb]

theorem follow_consistent (v : View) (ha : v.actor ≠ 0#u64) (hp : v.profile_exists = true) :
    transition v .Follow ⦃ r => r = .Ok (.Follow true (¬ v.already)) ⦄ := by
  unfold transition authed follow
  simp [ha, hp]

theorem unfollow_consistent (v : View) (ha : v.actor ≠ 0#u64) (hp : v.profile_exists = true) :
    transition v .Unfollow ⦃ r => r = .Ok (.Follow false v.already) ⦄ := by
  unfold transition authed follow
  simp [ha, hp]

theorem register_rejects_blanks (v : View) (email password : RawText) :
    (transition v (.Register .Absent email password) ⦃ r => r = err .BlankUsername ⦄) ∧
    (transition v (.Register .Null email password) ⦃ r => r = err .BlankUsername ⦄) ∧
    (transition v (.Register .Invalid email password) ⦃ r => r = err .InvalidUsername ⦄) ∧
    (transition v (.Register (.Text oneByte) .Absent password) ⦃ r => r = err .BlankEmail ⦄) ∧
    (transition v (.Register (.Text oneByte) (.Text oneByte) .Absent) ⦃ r =>
      r = err .BlankPassword ⦄) ∧
    (transition v (.Register (.Text oneByte) (.Text oneByte) (.Text emptyBytes)) ⦃ r =>
      r = err .BlankPassword ⦄) := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;>
    (unfold transition authed register require_text password_new;
      simp [one_len, empty_len]; rfl)

theorem register_rejects_short_password (v : View) :
    transition v (.Register (.Text oneByte) (.Text oneByte) (.Text sevenBytes)) ⦃ r =>
      r = err .ShortPassword ⦄ := by
  unfold transition authed register require_text password_new
  simp [one_len, seven_len]
  rfl

theorem login_rejects_blank_password (v : View) :
    (transition v (.Login (.Text oneByte) .Absent) ⦃ r => r = err .BlankPassword ⦄) ∧
    (transition v (.Login (.Text oneByte) .Null) ⦃ r => r = err .BlankPassword ⦄) ∧
    (transition v (.Login (.Text oneByte) (.Text emptyBytes)) ⦃ r => r = err .BlankPassword ⦄) ∧
    (transition v (.Login (.Text oneByte) (.Text sevenBytes)) ⦃ r => r = allow ⦄) := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;>
    (unfold transition authed login require_text password_login;
      simp [one_len, empty_len, seven_len]; rfl)

theorem update_user_rejects_nulls_and_short_password (v : View) (ha : v.actor ≠ 0#u64) :
    (transition v (.UpdateUser .Null .Absent .Absent .Absent .Absent) ⦃ r =>
      r = err .BlankUsername ⦄) ∧
    (transition v (.UpdateUser .Absent .Null .Absent .Absent .Absent) ⦃ r =>
      r = err .BlankEmail ⦄) ∧
    (transition v (.UpdateUser .Absent .Absent .Null .Absent .Absent) ⦃ r =>
      r = err .BlankPassword ⦄) ∧
    (transition v (.UpdateUser .Absent .Absent (.Text emptyBytes) .Absent .Absent) ⦃ r =>
      r = err .BlankPassword ⦄) ∧
    (transition v (.UpdateUser .Absent .Absent (.Text sevenBytes) .Absent .Absent) ⦃ r =>
      r = err .ShortPassword ⦄) := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;>
    (unfold transition authed update_user optional_required password_update optional_clear;
      simp [ha, empty_len, seven_len]; rfl)

theorem article_rejects_blank_and_null_tags
    (v : View) (description body : RawText) (tags : TagInput) (ha : v.actor ≠ 0#u64) :
    (transition v (.CreateArticle .Absent description body tags) ⦃ r => r = err .BlankTitle ⦄) ∧
    (transition v (.CreateArticle .Null description body tags) ⦃ r => r = err .BlankTitle ⦄) ∧
    (transition v (.CreateArticle (.Text oneByte) (.Text oneByte) .Absent .List) ⦃ r =>
      r = err .BlankBody ⦄) ∧
    (transition v (.CreateArticle (.Text oneByte) (.Text oneByte) (.Text oneByte) .Null) ⦃ r =>
      r = err .InvalidTags ⦄) ∧
    (transition v (.UpdateArticle .Absent .Absent .Absent .Null) ⦃ r => r = err .InvalidTags ⦄) ∧
    (transition v (.UpdateArticle .Absent .Absent .Absent .Invalid) ⦃ r =>
      r = err .InvalidTags ⦄) ∧
    (transition v (.UpdateArticle (.Text emptyBytes) .Absent .Absent .Absent) ⦃ r =>
      r = err .BlankTitle ⦄) := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;>
    (unfold transition authed create_article update_article require_text optional_required tags_of;
      simp [ha, one_len, empty_len]; rfl)

theorem delete_unknown_before_forbidden (v : View) (ha : v.actor ≠ 0#u64)
    (hx : v.article_exists = false) :
    (transition v .DeleteArticle ⦃ r => r = err .ArticleNotFound ⦄) ∧
    (transition v (.UpdateArticle .Absent .Absent (.Text oneByte) .Absent) ⦃ r =>
      r = err .ArticleNotFound ⦄) := by
  constructor
  · unfold transition authed delete_article; simp [ha, hx]; rfl
  · unfold transition authed update_article optional_required tags_of
    simp [ha, hx, one_len]
    h5i_steps
    all_goals rfl

theorem comment_delete_checks_article_first (v : View) (ha : v.actor ≠ 0#u64) :
    (v.article_exists = false →
      transition v .DeleteComment ⦃ r => r = err .ArticleNotFound ⦄) ∧
    (v.article_exists = true → v.comment_exists = false →
      transition v .DeleteComment ⦃ r => r = err .CommentNotFound ⦄) := by
  constructor
  · intro hx
    unfold transition authed delete_comment
    simp [ha, hx]
    rfl
  · intro hx hc
    unfold transition authed delete_comment
    simp [ha, hx, hc]
    rfl

theorem page_rejects_bad_limit (v : View) (offset : RawNum) :
    (transition v (.Page .Invalid offset) ⦃ r => r = err .InvalidLimit ⦄) ∧
    (transition v (.Page (.Value 0#u64) offset) ⦃ r => r = err .InvalidLimit ⦄) ∧
    (transition v (.Page (.Value 101#u64) .Absent) ⦃ r => r = .Ok (.Page 100#u64 0#u64) ⦄) := by
  refine ⟨?_, ?_, ?_⟩
  · unfold transition authed page; step*; rfl
  · unfold transition authed page; step*; rfl
  · unfold transition authed page
    have hcap : (101#u64 > 100#u64) = true := by decide
    simp [hcap]

theorem shows_body_list : shows_body .List ⦃ r => r = false ⦄ := by
  unfold shows_body
  step*

theorem shows_body_detail : shows_body .Detail ⦃ r => r = true ⦄ := by
  unfold shows_body
  step*

theorem login_success_iff (found matched : Bool) :
    authenticate_login found matched ⦃ r =>
      (r = .Ok () ↔ found = true ∧ matched = true) ∧
      (r = .Err .InvalidCredentials ↔ ¬ (found = true ∧ matched = true)) ⦄ := by
  cases found <;> cases matched <;> simp [authenticate_login]

theorem token_missing_guest (now : Std.U64) (found : Bool) :
    token_actor .Missing now found ⦃ r => r = .Ok 0#i64 ⦄ := by
  simp [token_actor]

theorem token_claims_exact (id : Std.I64) (exp now : Std.U64) (found : Bool) :
    token_actor (.Claims (.Parsed id) exp) now found ⦃ r =>
      (r = .Ok id ↔ ¬ exp ≤ now ∧ ¬ id ≤ 0#i64 ∧ found = true) ∧
      (r = .Err .InvalidToken ↔ exp ≤ now ∨ id ≤ 0#i64 ∨ found = false) ⦄ := by
  simp only [token_actor, token_user_exists]
  split <;> simp_all
  split <;> simp_all
  cases found <;> simp_all

theorem token_actor_safe (token : TokenInput) (now : Std.U64) (found : Bool) :
    token_actor token now found ⦃ r =>
      ∀ id, r = .Ok id → id ≠ 0#i64 →
        ∃ exp, token = .Claims (.Parsed id) exp ∧
          ¬ exp ≤ now ∧ ¬ id ≤ 0#i64 ∧ found = true ⦄ := by
  cases token with
  | Missing => simp [token_actor]
  | Invalid => simp [token_actor]
  | Claims sub exp =>
    cases sub with
    | Invalid =>
      simp only [token_actor]
      split <;> simp_all
    | Parsed id =>
      simp only [token_actor, token_user_exists]
      split <;> simp_all
      split <;> simp_all
      cases found <;> simp_all

theorem token_rejects_invalid (sub : Subject) (exp now : Std.U64) (found : Bool) :
    token_actor (.Claims sub exp) now found ⦃ r =>
      (exp ≤ now ∨ sub = .Invalid ∨
        (∃ id, sub = .Parsed id ∧ id ≤ 0#i64) ∨ found = false) →
      r = .Err .InvalidToken ⦄ := by
  cases sub with
  | Invalid =>
    simp only [token_actor]
    split <;> simp_all
  | Parsed id =>
    simp only [token_actor, token_user_exists]
    split <;> simp_all
    split <;> simp_all
    cases found <;> simp_all

theorem user_conflicts_exact (username email : Bool) :
    user_conflicts username email ⦃ r =>
      (r = .Ok () ↔ username = false ∧ email = false) ∧
      (r = .Err .UsernameTaken ↔ username = true) ∧
      (r = .Err .EmailTaken ↔ username = false ∧ email = true) ⦄ := by
  cases username <;> cases email <;> simp [user_conflicts]

theorem user_fields_exact (viewer subject : Std.U64) :
    user_fields viewer subject .User ⦃ fields =>
      (fields.email = true ↔ viewer ≠ 0#u64 ∧ viewer = subject) ∧
      fields.token = fields.email ⦄ := by
  by_cases guest : viewer = 0#u64 <;> simp [user_fields, guest]

theorem other_user_no_private_fields (viewer subject : Std.U64) (view : UserView)
    (different : viewer ≠ subject) :
    user_fields viewer subject view ⦃ fields =>
      fields.email = false ∧ fields.token = false ⦄ := by
  cases view <;> simp [user_fields, different]

theorem profile_no_private_fields (viewer subject : Std.U64) :
    user_fields viewer subject .Profile ⦃ fields =>
      fields.email = false ∧ fields.token = false ⦄ := by
  simp [user_fields]

end conduit_kernel
