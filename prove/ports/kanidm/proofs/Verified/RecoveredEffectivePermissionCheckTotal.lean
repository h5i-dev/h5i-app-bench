import Verified.MigrationBounds
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
namespace kanidm_kernel.Verified.RecoveredEffectivePermissionCheckTotal
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096
@[step] theorem migration_migration_entry_attrs_total
  (classes : Slice (alloc.vec.Vec Std.U8))  :
  migration.migration_entry_attrs classes ⦃ r => r.1.val.length ≤ 73 ∧ r.2.val.length ≤ 73 ⦄ := by
  unfold migration.migration_entry_attrs
  total_steps

@[step] theorem modify_acc_modify_migration_attrs_total
  (ident : Identity) (entry : Entry)  :
  modify_acc.modify_migration_attrs ident entry ⦃ r => ModBound 73 r ⦄ := by
  unfold modify_acc.modify_migration_attrs
  bounded_steps

@[step] theorem modify_acc_modify_protected_entry_attrs_total
  (classes : Slice (alloc.vec.Vec Std.U8))  :
  modify_acc.modify_protected_entry_attrs classes ⦃ r => ModBound 40 r ⦄ := by
  unfold modify_acc.modify_protected_entry_attrs
  literal_steps

@[step] theorem modify_acc_modify_protected_attrs_total
  (ident : Identity) (entry : Entry)  :
  modify_acc.modify_protected_attrs ident entry ⦃ r => ModBound 40 r ⦄ := by
  unfold modify_acc.modify_protected_attrs
  bounded_steps

abbrev Attrs := alloc.vec.Vec (alloc.vec.Vec U8)

def FourBound (n : Nat) (r : Bool × Attrs × Attrs × Attrs × Attrs) : Prop :=
  r.2.1.val.length ≤ n ∧ r.2.2.1.val.length ≤ n ∧
  r.2.2.2.1.val.length ≤ n ∧ r.2.2.2.2.val.length ≤ n

attribute [simp, step_pre_simps, step_post_simps] FourBound

theorem modify_start_spec (amr : AccessModResult) (n : Nat) (hb : ModBound n amr)
    (denied : Bool) (hcap : n ≤ Usize.max) :
    (match amr with
    | .Deny => ok (true, alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8), alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8))
    | .Ignore | .Constrain _ _ _ _ => ok (denied, alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8), alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8))
    | .Allow p r pc rc => do
        let p ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) p.deref
        let r ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) r.deref
        let pc ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) pc.deref
        let rc ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) rc.deref
        ok (denied, p, r, pc, rc))
    ⦃ r => FourBound n r ⦄ := by
  cases amr <;> bounded_steps

theorem modify_protected_spec (amr : AccessModResult) (n : Nat) (hb : ModBound n amr)
    (denied : Bool) (hcap : n ≤ Usize.max) :
    (match amr with
    | .Deny => ok (true, alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8), alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8))
    | .Ignore | .Allow _ _ _ _ => ok (denied, alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8), alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8))
    | .Constrain p r pc rc => do
        let r ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) r.deref
        let p ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) p.deref
        let pc ← match pc with
          | none => ok (alloc.vec.Vec.new (alloc.vec.Vec U8))
          | some pc => bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) pc.deref
        let rc ← match rc with
          | none => ok (alloc.vec.Vec.new (alloc.vec.Vec U8))
          | some rc => bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) rc.deref
        ok (denied, p, r, pc, rc))
    ⦃ r => FourBound n r ⦄ := by
  cases amr <;> bounded_steps

theorem modify_sync_spec (amr : AccessModResult) (n : Nat) (hb : ModBound n amr)
    (p r : Attrs)
    (hcapP : p.val.length + n ≤ Usize.max)
    (hcapR : r.val.length + n ≤ Usize.max) :
    (match amr with
    | .Deny => ok (true, p, r)
    | .Ignore | .Allow _ _ _ _ => ok (false, p, r)
    | .Constrain pa ra _ _ => do
        let r ← bset.extend r ra.deref
        let p ← bset.extend p pa.deref
        ok (false, p, r))
    ⦃ x => x.2.1.val.length ≤ p.val.length + n ∧
      x.2.2.val.length ≤ r.val.length + n ⦄ := by
  cases amr <;> bounded_steps

theorem modify_allow_spec (amr : AccessModResult) (n : Nat) (hb : ModBound n amr)
    (denied : Bool) (p r pc rc : Attrs)
    (hp : p.val.length + n ≤ Usize.max) (hr : r.val.length + n ≤ Usize.max)
    (hpc : pc.val.length + n ≤ Usize.max) (hrc : rc.val.length + n ≤ Usize.max) :
    (match amr with
    | .Deny => ok (true, p, r, pc, rc)
    | .Ignore | .Constrain _ _ _ _ => ok (denied, p, r, pc, rc)
    | .Allow pa ra pca rca => do
        let p ← bset.extend p pa.deref
        let r ← bset.extend r ra.deref
        let pc ← bset.extend pc pca.deref
        let rc ← bset.extend rc rca.deref
        ok (denied, p, r, pc, rc))
    ⦃ x => x.2.1.val.length ≤ p.val.length + n ∧
      x.2.2.1.val.length ≤ r.val.length + n ∧
      x.2.2.2.1.val.length ≤ pc.val.length + n ∧
      x.2.2.2.2.val.length ≤ rc.val.length + n ⦄ := by
  cases amr <;> bounded_steps

@[step] theorem modify_acc_apply_modify_access_total
  (ident : Identity) (related_acp : Slice profiles.AccessControlModifyResolved)
  (sync_agreements : Slice SyncAgreement) (entry : Entry) (hcap : cost resolvedModifyWeight related_acp.val + cost syncWeight sync_agreements.val + 73 < Usize.max) :
  modify_acc.apply_modify_access ident related_acp sync_agreements entry ⦃ r => True ⦄ := by
  unfold modify_acc.apply_modify_access
  step
  step
  step as ⟨abr⟩
  apply WP.spec_bind (Pₘ := fun _ => True)
  · cases abr <;> simp
  rintro ⟨denied, grant⟩ _
  step as ⟨amr, hamr⟩
  apply WP.spec_bind (modify_start_spec amr 73 hamr denied (by omega))
  rintro ⟨denied1, ap, ar, apc, arc⟩ hallow
  simp only [FourBound, Prod.fst, Prod.snd] at hallow
  step as ⟨amr1, hamr1⟩
  have hprot := modify_protected_spec amr1 40 hamr1 denied1 (by omega)
  apply WP.spec_bind (Pₘ := FourBound 40)
  · cases amr1 <;> exact hprot
  rintro ⟨denied2, cp, cr, cpc, crc⟩ hconstrain
  simp only [FourBound, Prod.fst, Prod.snd] at hconstrain
  apply WP.spec_bind (Pₘ := fun x : Bool × Attrs × Attrs × Attrs × Attrs × Attrs × Attrs =>
    x.2.1.val.length ≤ cost syncWeight sync_agreements.val + 44 ∧
    x.2.2.2.1.val.length ≤ cost syncWeight sync_agreements.val + 44 ∧
    x.2.2.1.val.length ≤ cost resolvedModifyWeight related_acp.val + 73 ∧
    x.2.2.2.2.1.val.length ≤ cost resolvedModifyWeight related_acp.val + 73 ∧
    x.2.2.2.2.2.1.val.length ≤ cost resolvedModifyWeight related_acp.val + 73 ∧
    x.2.2.2.2.2.2.val.length ≤ cost resolvedModifyWeight related_acp.val + 73)
  · by_cases hg : grant = true
    · simp only [hg, if_true]
      simp only [WP.spec_ok, Prod.fst, Prod.snd]
      omega
    · simp only [hg, if_false]
      by_cases hd : denied2 = true
      · simp only [hd, if_true]
        simp only [WP.spec_ok, Prod.fst, Prod.snd]
        omega
      · simp only [hd, if_false]
        step as ⟨amr2, hamr2⟩
        apply WP.spec_bind (modify_sync_spec amr2 _ hamr2 cp cr (by omega) (by omega))
        rintro ⟨denied4, cp2, cr2⟩ hsync
        simp only [Prod.fst, Prod.snd] at hsync
        step as ⟨scopedResult, hscopedResult⟩
        step as ⟨amr3, hamr3⟩
        apply WP.spec_bind (modify_allow_spec amr3 _ hamr3 denied4 ap ar apc arc
          (by omega) (by omega) (by omega) (by omega))
        rintro ⟨b, p, r, pc, rc⟩ hallowed
        simp only [Prod.fst, Prod.snd] at hallowed
        simp only [WP.spec_ok, Prod.fst, Prod.snd]
        omega
  · rintro ⟨denied3, cp1, ap1, cr1, ar1, apc1, arc1⟩ hbounds
    bounded_steps

@[step] theorem access_entry_effective_permission_check_total
  (ident : Identity) (entry : Entry)
  (search_related_acp : Slice profiles.AccessControlSearchResolved)
  (modify_related_acp : Slice profiles.AccessControlModifyResolved)
  (delete_related_acp : Slice profiles.AccessControlDeleteResolved)
  (sync_agmts : Slice SyncAgreement) (hcap : cost resolvedSearchWeight search_related_acp.val + cost resolvedModifyWeight modify_related_acp.val + cost syncWeight sync_agmts.val + 73 < Usize.max) :
  access.entry_effective_permission_check ident entry search_related_acp modify_related_acp delete_related_acp sync_agmts ⦃ r => True ⦄ := by
  unfold access.entry_effective_permission_check
  total_steps

@[step] theorem access_effective_permission_check_loop_total
  (ident : Identity) (entries : Slice Entry)
  (search_related_acp : alloc.vec.Vec profiles.AccessControlSearchResolved)
  (modify_related_acp : alloc.vec.Vec profiles.AccessControlModifyResolved)
  (delete_related_acp : alloc.vec.Vec profiles.AccessControlDeleteResolved)
  (sync_agmts : alloc.vec.Vec SyncAgreement)
  (effective_permissions : alloc.vec.Vec AccessEffectivePermission)
  (i : Std.Usize) (hi : i.val ≤ entries.length) (hcap : effective_permissions.val.length + (entries.length - i.val) ≤ Usize.max) (hpermissions : cost resolvedSearchWeight search_related_acp.val + cost resolvedModifyWeight modify_related_acp.val + cost syncWeight sync_agmts.val + 73 < Usize.max) :
  access.effective_permission_check_loop ident entries search_related_acp modify_related_acp delete_related_acp sync_agmts effective_permissions i ⦃ r => r.val.length ≤ effective_permissions.val.length + (entries.length - i.val) ⦄ := by
  unfold access.effective_permission_check_loop
  apply loop.spec_decr_nat (measure := fun x => entries.length - x.2.val)
    (inv := fun x => x.2.val ≤ entries.length ∧ x.1.val.length + (entries.length - x.2.val) ≤ effective_permissions.val.length + (entries.length - i.val))
  · rintro ⟨s, j⟩ ⟨hj, hs⟩
    h5i_unfold_body
    total_steps
  · exact ⟨hi, by simp⟩

theorem effective_permission_check_total (ctl : AccessControlsInner) (ident : Identity)
    (attrs : Option (alloc.vec.Vec (alloc.vec.Vec U8))) (es : Slice Entry)
    (hcap : (ctl.acps_search.val.map (·.attrs.length)).sum +
      (ctl.acps_modify.val.map (fun m => m.presattrs.length + m.remattrs.length +
        m.pres_classes.length + m.rem_classes.length)).sum +
      (ctl.sync_agreements.val.map (·.attrs.length)).sum + 73 < Usize.max) :
    ∃ y, access.effective_permission_check ctl ident attrs es = ok y := by
  apply ok_of (P := fun _ => True)
  change cost searchWeight ctl.acps_search.val + cost modifyWeight ctl.acps_modify.val +
    cost syncWeight ctl.sync_agreements.val + 73 < Usize.max at hcap
  unfold access.effective_permission_check
  total_steps

end kanidm_kernel.Verified.RecoveredEffectivePermissionCheckTotal
