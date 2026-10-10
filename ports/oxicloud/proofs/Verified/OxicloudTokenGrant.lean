import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit
namespace oxicloud_kernel.Verified.OxicloudTokenGrant

/-! ## Basic helpers and specifications -/

@[step] theorem contains_u8_spec (xs : Slice U8) (x : U8) :
    acl.contains_u8 xs x ⦃ b => b = true ↔ x ∈ xs.val ⦄ := by
  unfold acl.contains_u8 acl.contains_u8_loop
  apply WP.spec_mono (loop_search xs.val (fun y => decide (y = x)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr; rw [hr, searchFrom_const]; simp
  · intro j hj; unfold acl.contains_u8_loop.body; h5i_step

@[step] theorem contains_spec (ids : Slice U64) (x : U64) :
    acl.contains ids x ⦃ b => b = true ↔ x ∈ ids.val ⦄ := by
  unfold acl.contains acl.contains_loop
  apply WP.spec_mono (loop_search ids.val (fun y => decide (y = x)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr; rw [hr, searchFrom_const]; simp
  · intro j hj; unfold acl.contains_loop.body; h5i_step

theorem subject_matches_token (g : model.Grant) (types : Slice U8) (ids : Slice U64) (t : U64)
    (htypes : types.val = [2#u8]) (hids : ids.val = [t]) :
    acl.subject_matches g types ids ⦃ b => b = true ↔ g.subject = .Token t ⦄ := by
  unfold acl.subject_matches acl.subject_type acl.subject_id
  cases g.subject <;> step* <;> simp_all

@[step] theorem subject_match_set_token_spec (db : model.Db) (t : U64) :
    acl.subject_match_set db (.Token t) ⦃ fun (types, ids) =>
      types.val = [2#u8] ∧ ids.val = [t] ⦄ := by
  unfold acl.subject_match_set
  step*

theorem live_equiv (g : model.Grant) (now : I64) :
    acl.live g now = ok true ↔ Live g now := by
  unfold acl.live Live live
  cases g.expires_at with
  | none => simp
  | some exp => simp only [ok.injEq]; rfl

theorem deref_val {α} (v : alloc.vec.Vec α) : (alloc.vec.Vec.deref v).val = v.val :=
  Slice.from_val v.val v.property

theorem token_grant_of_match (db : model.Db) (t : U64) (now : I64)
    (types : alloc.vec.Vec U8) (ids : alloc.vec.Vec U64)
    (hmatch : acl.subject_match_set db (.Token t) = ok (types, ids))
    (hex : ∃ g ∈ db.grants.val, acl.subject_matches g (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) = ok true ∧ acl.live g now = ok true) :
    ∃ g ∈ db.grants.val, g.subject = .Token t ∧ Live g now := by
  have hspec := subject_match_set_token_spec db t
  have hval := post_of_ok hspec hmatch
  obtain ⟨g, hg_in, hmatch_g, hlive_g⟩ := hex
  have hsubj := subject_matches_token g (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) t
    (by rw [deref_val, hval.1]) (by rw [deref_val, hval.2])
  have hsubj_val := (post_of_ok hsubj hmatch_g).1 rfl
  exact ⟨g, hg_in, hsubj_val, (live_equiv g now).1 hlive_g⟩

theorem add_one_val (i i2 : Usize) (hmax : i.val < Usize.max) (h : i + 1#usize = ok i2) :
    i2.val = i.val + 1 := by
  have hs : i + 1#usize ⦃ z => z.val = i.val + (1#usize : Usize).val ⦄ := by
    apply Usize.add_spec
    simp only [UScalar.ofNatCore_val_eq]
    omega
  have hp := post_of_ok hs h
  simpa only [UScalar.ofNatCore_val_eq] using hp

/-! ## Loop 1: direct_grant_exists -/

theorem direct_step (db : model.Db) (types : Slice U8) (ids : Slice U64)
    (p : model.Permission) (r_res : model.Resource) (now : I64)
    (i : Usize) (res : ControlFlow Usize Bool)
    (_ : i.val ≤ db.grants.val.length)
    (h : acl.direct_grant_exists_loop.body db types ids p r_res now i = ok res) :
    match res with
    | .done true => ∃ g ∈ db.grants.val, acl.subject_matches g types ids = ok true ∧ acl.live g now = ok true
    | .done false => True
    | .cont i' => i'.val ≤ db.grants.val.length ∧ db.grants.val.length - i'.val < db.grants.val.length - i.val := by
  unfold acl.direct_grant_exists_loop.body at h
  dsimp only at h
  split at h
  · rename_i hlt
    have hlt_nat : i.val < db.grants.val.length := by
      have : (alloc.vec.Vec.len db.grants).val = db.grants.val.length := alloc.vec.Vec.len_val db.grants
      scalar_tac
    have himax : i.val < Usize.max := by
      have hp := db.grants.property
      omega
    obtain ⟨g, hg, hrest⟩ := bind_tc_eq_ok.1 h
    have hg_in : g ∈ db.grants.val := by
      rw [alloc.vec.Vec.index_slice_index, alloc.vec.Vec.index_usize] at hg
      split at hg
      · simp at hg
      · rename_i hsome
        simp only [ok.injEq] at hg
        subst hg
        exact List.mem_of_getElem? hsome
    obtain ⟨b, hb, hrest⟩ := bind_tc_eq_ok.1 hrest
    cases b
    · obtain ⟨i2, hi2, hres⟩ := bind_tc_eq_ok.1 hrest
      simp only [ok.injEq] at hres
      subst hres
      have := add_one_val i i2 himax hi2
      exact ⟨by omega, by omega⟩
    · obtain ⟨b1, hb1, hrest⟩ := bind_tc_eq_ok.1 hrest
      cases b1
      · obtain ⟨i2, hi2, hres⟩ := bind_tc_eq_ok.1 hrest
        simp only [ok.injEq] at hres
        subst hres
        have := add_one_val i i2 himax hi2
        exact ⟨by omega, by omega⟩
      · obtain ⟨b2, hb2, hrest⟩ := bind_tc_eq_ok.1 hrest
        cases b2
        · obtain ⟨i2, hi2, hres⟩ := bind_tc_eq_ok.1 hrest
          simp only [ok.injEq] at hres
          subst hres
          have := add_one_val i i2 himax hi2
          exact ⟨by omega, by omega⟩
        · obtain ⟨b3, hb3, hrest⟩ := bind_tc_eq_ok.1 hrest
          cases b3
          · obtain ⟨i2, hi2, hres⟩ := bind_tc_eq_ok.1 hrest
            simp only [ok.injEq] at hres
            subst hres
            have := add_one_val i i2 himax hi2
            exact ⟨by omega, by omega⟩
          · simp at hrest
            subst res
            exact ⟨g, hg_in, hb, hb3⟩
  · simp at h; subst h; simp

theorem direct_loop_ok (db : model.Db) (types : Slice U8) (ids : Slice U64)
    (p : model.Permission) (r_res : model.Resource) (now : I64)
    (i : Usize) (hi : i.val ≤ db.grants.val.length)
    (h : acl.direct_grant_exists_loop db types ids p r_res now i = ok true) :
    ∃ g ∈ db.grants.val, acl.subject_matches g types ids = ok true ∧ acl.live g now = ok true := by
  have := loop_ok (fun i1 => acl.direct_grant_exists_loop.body db types ids p r_res now i1)
    (fun i => i.val ≤ db.grants.val.length)
    (fun b => b = true → ∃ g ∈ db.grants.val, acl.subject_matches g types ids = ok true ∧ acl.live g now = ok true)
    (fun i => db.grants.val.length - i.val)
    (by
      intro x r hinv hr
      have hs := direct_step db types ids p r_res now x r hinv hr
      cases r with
      | done y =>
        cases y
        · intro hy; contradiction
        · intro _; exact hs
      | cont x' => exact hs)
    i true hi h
  exact this rfl

theorem direct_grant_exists_ok (db : model.Db) (types : Slice U8) (ids : Slice U64)
    (p : model.Permission) (r_res : model.Resource) (now : I64)
    (h : acl.direct_grant_exists db types ids p r_res now = ok true) :
    ∃ g ∈ db.grants.val, acl.subject_matches g types ids = ok true ∧ acl.live g now = ok true := by
  unfold acl.direct_grant_exists at h
  exact direct_loop_ok db types ids p r_res now 0#usize (by simp) h

theorem direct_grant_exists_token (db : model.Db) (t : U64) (r : model.Resource)
    (p : model.Permission) (now : I64)
    (types : alloc.vec.Vec U8) (ids : alloc.vec.Vec U64)
    (hmatch : acl.subject_match_set db (.Token t) = ok (types, ids))
    (h : acl.direct_grant_exists db types.deref ids.deref p r now = ok true) :
    ∃ g ∈ db.grants.val, g.subject = .Token t ∧ Live g now := by
  have hex := direct_grant_exists_ok db types.deref ids.deref p r now h
  exact token_grant_of_match db t now types ids hmatch hex

/-! ## Loop 2: folder_cascade_grant_exists -/

theorem folder_cascade_step (db : model.Db) (types : Slice U8) (ids : Slice U64)
    (p : model.Permission) (now : I64) (target : alloc.vec.Vec U64)
    (i : Usize) (res : ControlFlow Usize Bool)
    (_ : i.val ≤ db.grants.val.length)
    (h : acl.folder_cascade_grant_exists_loop.body db types ids p now target i = ok res) :
    match res with
    | .done true => ∃ g ∈ db.grants.val, acl.subject_matches g types ids = ok true ∧ acl.live g now = ok true
    | .done false => True
    | .cont i' => i'.val ≤ db.grants.val.length ∧ db.grants.val.length - i'.val < db.grants.val.length - i.val := by
  unfold acl.folder_cascade_grant_exists_loop.body at h
  dsimp only at h
  split at h
  · rename_i hlt
    have hlt_nat : i.val < db.grants.val.length := by
      have : (alloc.vec.Vec.len db.grants).val = db.grants.val.length := alloc.vec.Vec.len_val db.grants
      scalar_tac
    have himax : i.val < Usize.max := by
      have hp := db.grants.property
      omega
    obtain ⟨g, hg, hrest⟩ := bind_tc_eq_ok.1 h
    have hg_in : g ∈ db.grants.val := by
      rw [alloc.vec.Vec.index_slice_index, alloc.vec.Vec.index_usize] at hg
      split at hg
      · simp at hg
      · rename_i hsome
        simp only [ok.injEq] at hg
        subst hg
        exact List.mem_of_getElem? hsome
    obtain ⟨b, hb, hrest⟩ := bind_tc_eq_ok.1 hrest
    cases b
    · obtain ⟨i2, hi2, hres⟩ := bind_tc_eq_ok.1 hrest
      simp only [ok.injEq] at hres
      subst hres
      have := add_one_val i i2 himax hi2
      exact ⟨by omega, by omega⟩
    · obtain ⟨b1, hb1, hrest⟩ := bind_tc_eq_ok.1 hrest
      cases b1
      · obtain ⟨i2, hi2, hres⟩ := bind_tc_eq_ok.1 hrest
        simp only [ok.injEq] at hres
        subst hres
        have := add_one_val i i2 himax hi2
        exact ⟨by omega, by omega⟩
      · obtain ⟨b2, hb2, hrest⟩ := bind_tc_eq_ok.1 hrest
        cases b2
        · obtain ⟨i2, hi2, hres⟩ := bind_tc_eq_ok.1 hrest
          simp only [ok.injEq] at hres
          subst hres
          have := add_one_val i i2 himax hi2
          exact ⟨by omega, by omega⟩
        · obtain ⟨b3, hb3, hrest⟩ := bind_tc_eq_ok.1 hrest
          cases b3
          · obtain ⟨i2, hi2, hres⟩ := bind_tc_eq_ok.1 hrest
            simp only [ok.injEq] at hres
            subst hres
            have := add_one_val i i2 himax hi2
            exact ⟨by omega, by omega⟩
          · simp at hrest
            subst res
            exact ⟨g, hg_in, hb, hb2⟩
  · simp at h; subst h; simp

theorem folder_cascade_loop_ok (db : model.Db) (types : Slice U8) (ids : Slice U64)
    (p : model.Permission) (now : I64) (target : alloc.vec.Vec U64)
    (i : Usize) (hi : i.val ≤ db.grants.val.length)
    (h : acl.folder_cascade_grant_exists_loop db types ids p now target i = ok true) :
    ∃ g ∈ db.grants.val, acl.subject_matches g types ids = ok true ∧ acl.live g now = ok true := by
  have := loop_ok (fun i1 => acl.folder_cascade_grant_exists_loop.body db types ids p now target i1)
    (fun i => i.val ≤ db.grants.val.length)
    (fun b => b = true → ∃ g ∈ db.grants.val, acl.subject_matches g types ids = ok true ∧ acl.live g now = ok true)
    (fun i => db.grants.val.length - i.val)
    (by
      intro x r hinv hr
      have hs := folder_cascade_step db types ids p now target x r hinv hr
      cases r with
      | done y =>
        cases y
        · intro hy; contradiction
        · intro _; exact hs
      | cont x' => exact hs)
    i true hi h
  exact this rfl

theorem folder_cascade_grant_exists_ok (db : model.Db) (types : Slice U8) (ids : Slice U64)
    (p : model.Permission) (folder_id : U64) (now : I64)
    (h : acl.folder_cascade_grant_exists db types ids p folder_id now = ok true) :
    ∃ g ∈ db.grants.val, acl.subject_matches g types ids = ok true ∧ acl.live g now = ok true := by
  unfold acl.folder_cascade_grant_exists at h
  obtain ⟨o, ho, hrest⟩ := bind_tc_eq_ok.1 h
  cases o with
  | none => simp at hrest
  | some f => exact folder_cascade_loop_ok db types ids p now f.lpath 0#usize (by simp) hrest

theorem cascade_grant_token (db : model.Db) (t : U64) (r : model.Resource)
    (p : model.Permission) (now : I64)
    (h : acl.cascade_grant db (.Token t) r p now = ok true) :
    ∃ g ∈ db.grants.val, g.subject = .Token t ∧ Live g now := by
  unfold acl.cascade_grant at h
  cases r with
  | Drive _ | Calendar _ | AddressBook _ | Playlist _ => simp at h
  | Folder id =>
    obtain ⟨⟨types, ids⟩, hmatch, hfolder⟩ := bind_tc_eq_ok.1 h
    have hex := folder_cascade_grant_exists_ok db types.deref ids.deref p id now hfolder
    exact token_grant_of_match db t now types ids hmatch hex
  | File id =>
    obtain ⟨o, ho, hrest⟩ := bind_tc_eq_ok.1 h
    obtain ⟨folder_allowed, hfa, hrest⟩ := bind_tc_eq_ok.1 hrest
    cases folder_allowed with
    | false =>
      simp only [Bool.false_eq_true, ↓reduceIte] at hrest
      obtain ⟨⟨types, ids⟩, hmatch, hdirect⟩ := bind_tc_eq_ok.1 hrest
      have hex := direct_grant_exists_ok db types.deref ids.deref p (model.Resource.File id) now hdirect
      exact token_grant_of_match db t now types ids hmatch hex
    | true =>
      cases o with
      | none => simp at hfa
      | some parent =>
        obtain ⟨⟨types, ids⟩, hmatch, hfolder⟩ := bind_tc_eq_ok.1 hfa
        have hex := folder_cascade_grant_exists_ok db types.deref ids.deref p parent now hfolder
        exact token_grant_of_match db t now types ids hmatch hex

/-! ## Loop 3: caller_role_on_drive -/

theorem stronger_cases (a : Option model.Role) (b : model.Role) (r : Option model.Role)
    (h : acl.stronger a b = ok r) :
    r = some b ∨ r = a := by
  unfold acl.stronger at h
  cases a with
  | none => simp at h; subst h; left; rfl
  | some x =>
    obtain ⟨i, hi, hrest⟩ := bind_tc_eq_ok.1 h
    obtain ⟨i1, hi1, hrest⟩ := bind_tc_eq_ok.1 hrest
    split at hrest
    · simp at hrest; subst hrest; left; rfl
    · simp at hrest; subst hrest; right; rfl

theorem caller_role_step (db : model.Db) (drive_id : U64) (now : I64)
    (types : alloc.vec.Vec U8) (ids : alloc.vec.Vec U64)
    (best : Option model.Role) (i : Usize)
    (res : ControlFlow ((Option model.Role) × Usize) (Option model.Role))
    (hinv : i.val ≤ db.grants.val.length ∧ (best ≠ none → ∃ g ∈ db.grants.val, acl.subject_matches g (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) = ok true ∧ acl.live g now = ok true))
    (h : acl.caller_role_on_drive_loop.body db drive_id now types ids best i = ok res) :
    match res with
    | .done r => r ≠ none → ∃ g ∈ db.grants.val, acl.subject_matches g (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) = ok true ∧ acl.live g now = ok true
    | .cont (best', i') => (i'.val ≤ db.grants.val.length ∧ (best' ≠ none → ∃ g ∈ db.grants.val, acl.subject_matches g (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) = ok true ∧ acl.live g now = ok true)) ∧
        db.grants.val.length - i'.val < db.grants.val.length - i.val := by
  unfold acl.caller_role_on_drive_loop.body at h
  dsimp only at h
  split at h
  · rename_i hlt
    have hlt_nat : i.val < db.grants.val.length := by
      have : (alloc.vec.Vec.len db.grants).val = db.grants.val.length := alloc.vec.Vec.len_val db.grants
      scalar_tac
    have himax : i.val < Usize.max := by
      have hp := db.grants.property
      omega
    obtain ⟨g, hg, hrest⟩ := bind_tc_eq_ok.1 h
    have hg_in : g ∈ db.grants.val := by
      rw [alloc.vec.Vec.index_slice_index, alloc.vec.Vec.index_usize] at hg
      split at hg
      · simp at hg
      · rename_i hsome
        simp only [ok.injEq] at hg
        subst hg
        exact List.mem_of_getElem? hsome
    obtain ⟨b, hb, hrest⟩ := bind_tc_eq_ok.1 hrest
    obtain ⟨best1, hbest1, hrest⟩ := bind_tc_eq_ok.1 hrest
    obtain ⟨i2, hi2, hres⟩ := bind_tc_eq_ok.1 hrest
    simp only [ok.injEq] at hres
    subst hres
    have hi2_val := add_one_val i i2 himax hi2
    have hbest_cases : best1 ≠ none → ∃ g ∈ db.grants.val, acl.subject_matches g (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) = ok true ∧ acl.live g now = ok true := by
      cases b
      · simp at hbest1; subst hbest1; exact hinv.2
      · obtain ⟨b1, hb1, hbest1⟩ := bind_tc_eq_ok.1 hbest1
        cases b1
        · simp at hbest1; subst hbest1; exact hinv.2
        · obtain ⟨b2, hb2, hbest1⟩ := bind_tc_eq_ok.1 hbest1
          cases b2
          · simp at hbest1; subst hbest1; exact hinv.2
          · rcases stronger_cases best g.role best1 hbest1 with rfl | rfl
            · intro _; exact ⟨g, hg_in, hb, hb2⟩
            · exact hinv.2
    refine ⟨⟨by omega, hbest_cases⟩, by omega⟩
  · simp only [ok.injEq] at h; subst h; exact hinv.2

theorem caller_role_loop_ok (db : model.Db) (drive_id : U64) (now : I64)
    (types : alloc.vec.Vec U8) (ids : alloc.vec.Vec U64)
    (best : Option model.Role) (i : Usize) (role : model.Role)
    (hi : i.val ≤ db.grants.val.length)
    (hbest : best ≠ none → ∃ g ∈ db.grants.val, acl.subject_matches g (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) = ok true ∧ acl.live g now = ok true)
    (h : acl.caller_role_on_drive_loop db drive_id now types ids best i = ok (some role)) :
    ∃ g ∈ db.grants.val, acl.subject_matches g (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) = ok true ∧ acl.live g now = ok true := by
  unfold acl.caller_role_on_drive_loop at h
  have := loop_ok (fun p => acl.caller_role_on_drive_loop.body db drive_id now types ids p.1 p.2)
    (fun p => p.2.val ≤ db.grants.val.length ∧ (p.1 ≠ none → ∃ g ∈ db.grants.val, acl.subject_matches g (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) = ok true ∧ acl.live g now = ok true))
    (fun r => r ≠ none → ∃ g ∈ db.grants.val, acl.subject_matches g (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) = ok true ∧ acl.live g now = ok true)
    (fun p => db.grants.val.length - p.2.val)
    (by
      intro p r hinv hr
      have hs := caller_role_step db drive_id now types ids p.1 p.2 r hinv hr
      cases r with
      | done y => exact hs
      | cont p' => exact hs)
    (best, i) (some role) ⟨hi, hbest⟩ h
  exact this (by simp)

theorem caller_role_on_drive_some (db : model.Db) (s : model.Subject) (drive_id : U64) (now : I64)
    (role : model.Role) (h : acl.caller_role_on_drive db s drive_id now = ok (some role)) :
    ∃ (types : alloc.vec.Vec U8) (ids : alloc.vec.Vec U64),
      acl.subject_match_set db s = ok (types, ids) ∧
      ∃ g ∈ db.grants.val, acl.subject_matches g (alloc.vec.Vec.deref types) (alloc.vec.Vec.deref ids) = ok true ∧ acl.live g now = ok true := by
  unfold acl.caller_role_on_drive at h
  obtain ⟨⟨types, ids⟩, hmatch, hloop⟩ := bind_tc_eq_ok.1 h
  refine ⟨types, ids, hmatch, ?_⟩
  exact caller_role_loop_ok db drive_id now types ids none 0#usize role (by simp) (by simp) hloop

theorem caller_role_on_drive_token (db : model.Db) (drive_id : U64) (now : I64) (t : U64)
    (role : model.Role) (h : acl.caller_role_on_drive db (.Token t) drive_id now = ok (some role)) :
    ∃ g ∈ db.grants.val, g.subject = .Token t ∧ Live g now := by
  obtain ⟨types, ids, hmatch, hex⟩ := caller_role_on_drive_some db (.Token t) drive_id now role h
  exact token_grant_of_match db t now types ids hmatch hex

theorem role_has_some (r : Option model.Role) (p : model.Permission)
    (h : acl.role_has r p = ok true) :
    ∃ role, r = some role := by
  unfold acl.role_has at h
  cases r with
  | none => simp at h
  | some role => exact ⟨role, rfl⟩

/-! ## Main theorem -/

theorem token_needs_its_own_grant (db : model.Db) (ro : Bool) (now : I64) (t : U64)
    (p : model.Permission) (r : model.Resource) (h : acl.check db ro now (.Token t) p r = ok true) :
    ∃ g ∈ db.grants.val, g.subject = .Token t ∧ Live g now := by
  unfold acl.check at h
  dsimp only at h
  obtain ⟨b, hb, hrest⟩ := bind_tc_eq_ok.1 h
  cases r with
  | Calendar id | AddressBook id | Playlist id =>
    split at hrest
    · case isTrue b_true =>
      split at hrest
      · simp at hrest
      · obtain ⟨is_storage, his, hrest⟩ := bind_tc_eq_ok.1 hrest
        simp only [ok.injEq] at his; subst is_storage
        simp only [Bool.false_eq_true, ↓reduceIte] at hrest
        obtain ⟨⟨types, ids⟩, hmatch, hdirect⟩ := bind_tc_eq_ok.1 hrest
        exact direct_grant_exists_token db t _ p now types ids hmatch hdirect
    · case isFalse b_false =>
      obtain ⟨is_storage, his, hrest⟩ := bind_tc_eq_ok.1 hrest
      simp only [ok.injEq] at his; subst is_storage
      simp only [Bool.false_eq_true, ↓reduceIte] at hrest
      obtain ⟨⟨types, ids⟩, hmatch, hdirect⟩ := bind_tc_eq_ok.1 hrest
      exact direct_grant_exists_token db t _ p now types ids hmatch hdirect
  | Drive id =>
    split at hrest
    · case isTrue b_true =>
      split at hrest
      · simp at hrest
      · obtain ⟨is_storage, his, hrest⟩ := bind_tc_eq_ok.1 hrest
        simp only [ok.injEq] at his; subst is_storage
        simp only [Bool.false_eq_true, ↓reduceIte] at hrest
        obtain ⟨dp1, hdp1, hrest⟩ := bind_tc_eq_ok.1 hrest
        split at hrest
        · simp at hrest
        · obtain ⟨o2, ho2, hrole⟩ := bind_tc_eq_ok.1 hrest
          obtain ⟨role, rfl⟩ := role_has_some o2 p hrole
          exact caller_role_on_drive_token db id now t role ho2
    · case isFalse b_false =>
      obtain ⟨is_storage, his, hrest⟩ := bind_tc_eq_ok.1 hrest
      simp only [ok.injEq] at his; subst is_storage
      simp only [Bool.false_eq_true, ↓reduceIte] at hrest
      obtain ⟨o2, ho2, hrole⟩ := bind_tc_eq_ok.1 hrest
      obtain ⟨role, rfl⟩ := role_has_some o2 p hrole
      exact caller_role_on_drive_token db id now t role ho2
  | Folder id | File id =>
    split at hrest
    · case isTrue b_true =>
      split at hrest
      · simp at hrest
      · obtain ⟨is_storage, his, hrest⟩ := bind_tc_eq_ok.1 hrest
        simp only [ok.injEq] at his; subst is_storage
        obtain ⟨o, ho, hrest⟩ := bind_tc_eq_ok.1 hrest
        cases o with
        | none => simp at hrest
        | some d =>
          obtain ⟨dp, hdp, hrest⟩ := bind_tc_eq_ok.1 hrest
          split at hrest
          · simp at hrest
          · obtain ⟨o1, ho1, hrest⟩ := bind_tc_eq_ok.1 hrest
            obtain ⟨b1, hb1, hrest⟩ := bind_tc_eq_ok.1 hrest
            split at hrest
            · rename_i hb1_true; subst b1
              obtain ⟨role, rfl⟩ := role_has_some o1 p hb1
              exact caller_role_on_drive_token db d now t role ho1
            · exact cascade_grant_token db t _ p now hrest
    · case isFalse b_false =>
      obtain ⟨is_storage, his, hrest⟩ := bind_tc_eq_ok.1 hrest
      simp only [ok.injEq] at his; subst is_storage
      obtain ⟨o, ho, hrest⟩ := bind_tc_eq_ok.1 hrest
      cases o with
      | none => simp at hrest
      | some d =>
        obtain ⟨o1, ho1, hrest⟩ := bind_tc_eq_ok.1 hrest
        obtain ⟨b1, hb1, hrest⟩ := bind_tc_eq_ok.1 hrest
        split at hrest
        · rename_i hb1_true; subst b1
          obtain ⟨role, rfl⟩ := role_has_some o1 p hb1
          exact caller_role_on_drive_token db d now t role ho1
        · exact cascade_grant_token db t _ p now hrest

end oxicloud_kernel.Verified.OxicloudTokenGrant
