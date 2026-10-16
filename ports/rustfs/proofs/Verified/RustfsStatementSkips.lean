import Verified.RustfsStatementResources
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete
namespace rustfs_kernel.Verified.RustfsStatementSkips
set_option maxHeartbeats 4000000
set_option linter.unusedSimpArgs false

theorem table_ok (a : acts.Action) (b : Bool)
    (h : acts.is_table_resource_scoped a = ok b) : b=true ↔ TableResourceAction a := by
  unfold acts.is_table_resource_scoped core.cmp.PartialEq.ne.trait_default core.cmp.PartialEq.ne.default at h
  simp only [family_eq_ok] at h
  by_cases hf : a.family = .Admin
  · simp only [hf,decide_true,bind_tc_ok,bind_ok,Bool.true_eq_false,not_true_eq_false,decide_false,Bool.false_eq_true,ite_false] at h
    bcase s1 with hs1 at h
    have l1 := lift_slice hs1
    bcase x1 with hx1 at h
    have e1 := bytes_eq_ok _ _ _ hx1
    simp only [deref_val] at e1
    have en1 := e1.trans (show a.name.val=s1.val ↔ nats a.name.val=nats s1.val from ⟨congrArg nats,nats_inj⟩)
    rw [l1] at en1
    by_cases hm1 : x1=true <;> simp only [hm1,ite_true,ite_false] at h
    · have hb := Result.ok.inj h; subst b
      simp only [true_iff,TableResourceAction]
      refine ⟨hf, ?_⟩
      simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
      exact Or.inl (en1.mp hm1)
    ·
      bcase s2 with hs2 at h
      have l2 := lift_slice hs2
      bcase x2 with hx2 at h
      have e2 := bytes_eq_ok _ _ _ hx2
      simp only [deref_val] at e2
      have en2 := e2.trans (show a.name.val=s2.val ↔ nats a.name.val=nats s2.val from ⟨congrArg nats,nats_inj⟩)
      rw [l2] at en2
      by_cases hm2 : x2=true <;> simp only [hm2,ite_true,ite_false] at h
      · have hb := Result.ok.inj h; subst b
        simp only [true_iff,TableResourceAction]
        refine ⟨hf, ?_⟩
        simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
        exact Or.inr (Or.inl (en2.mp hm2))
      ·
        bcase s3 with hs3 at h
        have l3 := lift_slice hs3
        bcase x3 with hx3 at h
        have e3 := bytes_eq_ok _ _ _ hx3
        simp only [deref_val] at e3
        have en3 := e3.trans (show a.name.val=s3.val ↔ nats a.name.val=nats s3.val from ⟨congrArg nats,nats_inj⟩)
        rw [l3] at en3
        by_cases hm3 : x3=true <;> simp only [hm3,ite_true,ite_false] at h
        · have hb := Result.ok.inj h; subst b
          simp only [true_iff,TableResourceAction]
          refine ⟨hf, ?_⟩
          simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
          exact Or.inr (Or.inr (Or.inl (en3.mp hm3)))
        ·
          bcase s4 with hs4 at h
          have l4 := lift_slice hs4
          bcase x4 with hx4 at h
          have e4 := bytes_eq_ok _ _ _ hx4
          simp only [deref_val] at e4
          have en4 := e4.trans (show a.name.val=s4.val ↔ nats a.name.val=nats s4.val from ⟨congrArg nats,nats_inj⟩)
          rw [l4] at en4
          by_cases hm4 : x4=true <;> simp only [hm4,ite_true,ite_false] at h
          · have hb := Result.ok.inj h; subst b
            simp only [true_iff,TableResourceAction]
            refine ⟨hf, ?_⟩
            simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
            exact Or.inr (Or.inr (Or.inr (Or.inl (en4.mp hm4))))
          ·
            bcase s5 with hs5 at h
            have l5 := lift_slice hs5
            bcase x5 with hx5 at h
            have e5 := bytes_eq_ok _ _ _ hx5
            simp only [deref_val] at e5
            have en5 := e5.trans (show a.name.val=s5.val ↔ nats a.name.val=nats s5.val from ⟨congrArg nats,nats_inj⟩)
            rw [l5] at en5
            by_cases hm5 : x5=true <;> simp only [hm5,ite_true,ite_false] at h
            · have hb := Result.ok.inj h; subst b
              simp only [true_iff,TableResourceAction]
              refine ⟨hf, ?_⟩
              simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
              exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en5.mp hm5)))))
            ·
              bcase s6 with hs6 at h
              have l6 := lift_slice hs6
              bcase x6 with hx6 at h
              have e6 := bytes_eq_ok _ _ _ hx6
              simp only [deref_val] at e6
              have en6 := e6.trans (show a.name.val=s6.val ↔ nats a.name.val=nats s6.val from ⟨congrArg nats,nats_inj⟩)
              rw [l6] at en6
              by_cases hm6 : x6=true <;> simp only [hm6,ite_true,ite_false] at h
              · have hb := Result.ok.inj h; subst b
                simp only [true_iff,TableResourceAction]
                refine ⟨hf, ?_⟩
                simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en6.mp hm6))))))
              ·
                bcase s7 with hs7 at h
                have l7 := lift_slice hs7
                bcase x7 with hx7 at h
                have e7 := bytes_eq_ok _ _ _ hx7
                simp only [deref_val] at e7
                have en7 := e7.trans (show a.name.val=s7.val ↔ nats a.name.val=nats s7.val from ⟨congrArg nats,nats_inj⟩)
                rw [l7] at en7
                by_cases hm7 : x7=true <;> simp only [hm7,ite_true,ite_false] at h
                · have hb := Result.ok.inj h; subst b
                  simp only [true_iff,TableResourceAction]
                  refine ⟨hf, ?_⟩
                  simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                  exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en7.mp hm7)))))))
                ·
                  bcase s8 with hs8 at h
                  have l8 := lift_slice hs8
                  bcase x8 with hx8 at h
                  have e8 := bytes_eq_ok _ _ _ hx8
                  simp only [deref_val] at e8
                  have en8 := e8.trans (show a.name.val=s8.val ↔ nats a.name.val=nats s8.val from ⟨congrArg nats,nats_inj⟩)
                  rw [l8] at en8
                  by_cases hm8 : x8=true <;> simp only [hm8,ite_true,ite_false] at h
                  · have hb := Result.ok.inj h; subst b
                    simp only [true_iff,TableResourceAction]
                    refine ⟨hf, ?_⟩
                    simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                    exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en8.mp hm8))))))))
                  ·
                    bcase s9 with hs9 at h
                    have l9 := lift_slice hs9
                    bcase x9 with hx9 at h
                    have e9 := bytes_eq_ok _ _ _ hx9
                    simp only [deref_val] at e9
                    have en9 := e9.trans (show a.name.val=s9.val ↔ nats a.name.val=nats s9.val from ⟨congrArg nats,nats_inj⟩)
                    rw [l9] at en9
                    by_cases hm9 : x9=true <;> simp only [hm9,ite_true,ite_false] at h
                    · have hb := Result.ok.inj h; subst b
                      simp only [true_iff,TableResourceAction]
                      refine ⟨hf, ?_⟩
                      simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                      exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en9.mp hm9)))))))))
                    ·
                      bcase s10 with hs10 at h
                      have l10 := lift_slice hs10
                      bcase x10 with hx10 at h
                      have e10 := bytes_eq_ok _ _ _ hx10
                      simp only [deref_val] at e10
                      have en10 := e10.trans (show a.name.val=s10.val ↔ nats a.name.val=nats s10.val from ⟨congrArg nats,nats_inj⟩)
                      rw [l10] at en10
                      by_cases hm10 : x10=true <;> simp only [hm10,ite_true,ite_false] at h
                      · have hb := Result.ok.inj h; subst b
                        simp only [true_iff,TableResourceAction]
                        refine ⟨hf, ?_⟩
                        simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                        exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en10.mp hm10))))))))))
                      ·
                        bcase s11 with hs11 at h
                        have l11 := lift_slice hs11
                        bcase x11 with hx11 at h
                        have e11 := bytes_eq_ok _ _ _ hx11
                        simp only [deref_val] at e11
                        have en11 := e11.trans (show a.name.val=s11.val ↔ nats a.name.val=nats s11.val from ⟨congrArg nats,nats_inj⟩)
                        rw [l11] at en11
                        by_cases hm11 : x11=true <;> simp only [hm11,ite_true,ite_false] at h
                        · have hb := Result.ok.inj h; subst b
                          simp only [true_iff,TableResourceAction]
                          refine ⟨hf, ?_⟩
                          simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                          exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en11.mp hm11)))))))))))
                        ·
                          bcase s12 with hs12 at h
                          have l12 := lift_slice hs12
                          bcase x12 with hx12 at h
                          have e12 := bytes_eq_ok _ _ _ hx12
                          simp only [deref_val] at e12
                          have en12 := e12.trans (show a.name.val=s12.val ↔ nats a.name.val=nats s12.val from ⟨congrArg nats,nats_inj⟩)
                          rw [l12] at en12
                          by_cases hm12 : x12=true <;> simp only [hm12,ite_true,ite_false] at h
                          · have hb := Result.ok.inj h; subst b
                            simp only [true_iff,TableResourceAction]
                            refine ⟨hf, ?_⟩
                            simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                            exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en12.mp hm12))))))))))))
                          ·
                            bcase s13 with hs13 at h
                            have l13 := lift_slice hs13
                            bcase x13 with hx13 at h
                            have e13 := bytes_eq_ok _ _ _ hx13
                            simp only [deref_val] at e13
                            have en13 := e13.trans (show a.name.val=s13.val ↔ nats a.name.val=nats s13.val from ⟨congrArg nats,nats_inj⟩)
                            rw [l13] at en13
                            by_cases hm13 : x13=true <;> simp only [hm13,ite_true,ite_false] at h
                            · have hb := Result.ok.inj h; subst b
                              simp only [true_iff,TableResourceAction]
                              refine ⟨hf, ?_⟩
                              simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                              exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en13.mp hm13)))))))))))))
                            ·
                              bcase s14 with hs14 at h
                              have l14 := lift_slice hs14
                              bcase x14 with hx14 at h
                              have e14 := bytes_eq_ok _ _ _ hx14
                              simp only [deref_val] at e14
                              have en14 := e14.trans (show a.name.val=s14.val ↔ nats a.name.val=nats s14.val from ⟨congrArg nats,nats_inj⟩)
                              rw [l14] at en14
                              by_cases hm14 : x14=true <;> simp only [hm14,ite_true,ite_false] at h
                              · have hb := Result.ok.inj h; subst b
                                simp only [true_iff,TableResourceAction]
                                refine ⟨hf, ?_⟩
                                simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                                exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en14.mp hm14))))))))))))))
                              ·
                                bcase s15 with hs15 at h
                                have l15 := lift_slice hs15
                                bcase x15 with hx15 at h
                                have e15 := bytes_eq_ok _ _ _ hx15
                                simp only [deref_val] at e15
                                have en15 := e15.trans (show a.name.val=s15.val ↔ nats a.name.val=nats s15.val from ⟨congrArg nats,nats_inj⟩)
                                rw [l15] at en15
                                by_cases hm15 : x15=true <;> simp only [hm15,ite_true,ite_false] at h
                                · have hb := Result.ok.inj h; subst b
                                  simp only [true_iff,TableResourceAction]
                                  refine ⟨hf, ?_⟩
                                  simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                                  exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en15.mp hm15)))))))))))))))
                                ·
                                  bcase s16 with hs16 at h
                                  have l16 := lift_slice hs16
                                  bcase x16 with hx16 at h
                                  have e16 := bytes_eq_ok _ _ _ hx16
                                  simp only [deref_val] at e16
                                  have en16 := e16.trans (show a.name.val=s16.val ↔ nats a.name.val=nats s16.val from ⟨congrArg nats,nats_inj⟩)
                                  rw [l16] at en16
                                  by_cases hm16 : x16=true <;> simp only [hm16,ite_true,ite_false] at h
                                  · have hb := Result.ok.inj h; subst b
                                    simp only [true_iff,TableResourceAction]
                                    refine ⟨hf, ?_⟩
                                    simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                                    exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en16.mp hm16))))))))))))))))
                                  ·
                                    bcase s17 with hs17 at h
                                    have l17 := lift_slice hs17
                                    bcase x17 with hx17 at h
                                    have e17 := bytes_eq_ok _ _ _ hx17
                                    simp only [deref_val] at e17
                                    have en17 := e17.trans (show a.name.val=s17.val ↔ nats a.name.val=nats s17.val from ⟨congrArg nats,nats_inj⟩)
                                    rw [l17] at en17
                                    by_cases hm17 : x17=true <;> simp only [hm17,ite_true,ite_false] at h
                                    · have hb := Result.ok.inj h; subst b
                                      simp only [true_iff,TableResourceAction]
                                      refine ⟨hf, ?_⟩
                                      simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                                      exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en17.mp hm17)))))))))))))))))
                                    ·
                                      bcase s18 with hs18 at h
                                      have l18 := lift_slice hs18
                                      bcase x18 with hx18 at h
                                      have e18 := bytes_eq_ok _ _ _ hx18
                                      simp only [deref_val] at e18
                                      have en18 := e18.trans (show a.name.val=s18.val ↔ nats a.name.val=nats s18.val from ⟨congrArg nats,nats_inj⟩)
                                      rw [l18] at en18
                                      by_cases hm18 : x18=true <;> simp only [hm18,ite_true,ite_false] at h
                                      · have hb := Result.ok.inj h; subst b
                                        simp only [true_iff,TableResourceAction]
                                        refine ⟨hf, ?_⟩
                                        simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                                        exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en18.mp hm18))))))))))))))))))
                                      ·
                                        bcase s19 with hs19 at h
                                        have l19 := lift_slice hs19
                                        bcase x19 with hx19 at h
                                        have e19 := bytes_eq_ok _ _ _ hx19
                                        simp only [deref_val] at e19
                                        have en19 := e19.trans (show a.name.val=s19.val ↔ nats a.name.val=nats s19.val from ⟨congrArg nats,nats_inj⟩)
                                        rw [l19] at en19
                                        by_cases hm19 : x19=true <;> simp only [hm19,ite_true,ite_false] at h
                                        · have hb := Result.ok.inj h; subst b
                                          simp only [true_iff,TableResourceAction]
                                          refine ⟨hf, ?_⟩
                                          simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                                          exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl (en19.mp hm19)))))))))))))))))))
                                        ·
                                          bcase s20 with hs20 at h
                                          have l20 := lift_slice hs20
                                          have e20 := bytes_eq_ok _ _ _ h
                                          simp only [deref_val] at e20
                                          have en20 := e20.trans (show a.name.val=s20.val ↔ nats a.name.val=nats s20.val from ⟨congrArg nats,nats_inj⟩)
                                          rw [l20] at en20
                                          constructor
                                          · intro hb
                                            refine ⟨hf, ?_⟩
                                            simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false]
                                            exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (en20.mp hb)))))))))))))))))))
                                          · rintro ⟨_,hm⟩
                                            simp only [TableResourceNames,List.mem_cons,List.not_mem_nil,or_false] at hm
                                            rcases hm with h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20
                                            · exact False.elim (hm1 (en1.mpr h1))
                                            · exact False.elim (hm2 (en2.mpr h2))
                                            · exact False.elim (hm3 (en3.mpr h3))
                                            · exact False.elim (hm4 (en4.mpr h4))
                                            · exact False.elim (hm5 (en5.mpr h5))
                                            · exact False.elim (hm6 (en6.mpr h6))
                                            · exact False.elim (hm7 (en7.mpr h7))
                                            · exact False.elim (hm8 (en8.mpr h8))
                                            · exact False.elim (hm9 (en9.mpr h9))
                                            · exact False.elim (hm10 (en10.mpr h10))
                                            · exact False.elim (hm11 (en11.mpr h11))
                                            · exact False.elim (hm12 (en12.mpr h12))
                                            · exact False.elim (hm13 (en13.mpr h13))
                                            · exact False.elim (hm14 (en14.mpr h14))
                                            · exact False.elim (hm15 (en15.mpr h15))
                                            · exact False.elim (hm16 (en16.mpr h16))
                                            · exact False.elim (hm17 (en17.mpr h17))
                                            · exact False.elim (hm18 (en18.mpr h18))
                                            · exact False.elim (hm19 (en19.mpr h19))
                                            · exact en20.mpr h20
  · simp only [hf,decide_false,bind_tc_ok,bind_ok,Bool.false_eq_true,not_false_eq_true,decide_true,ite_true] at h
    have hb := Result.ok.inj h
    subst b
    simp [TableResourceAction,hf]
 theorem family_ok (actions : Slice acts.Action) (family : acts.Family) (b : Bool)
    (h : stmts.has_family actions family = ok b) :
    b=true ↔ ∃ a ∈ actions.val, a.family=family := by
  unfold stmts.has_family stmts.has_family_loop at h
  refine RustfsValids.any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold stmts.has_family_loop.body at hr
  simp only [family_eq_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok ha
    exact .inl ⟨hlt, by rw [he]; simpa using hc_1, rfl⟩
  · obtain ⟨hlt,he⟩ := slice_index_ok ha
    refine ⟨hlt,?_,by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    simpa using hc_1
  · exact .inr ⟨by scalar_tac,rfl⟩

theorem skip_ok (st : stmts.Statement) (args : stmts.Args) (b : Bool)
    (h : stmts.skips_resource_match st args = ok b) :
    b=true ↔ SkipResourceMatch st.actions.val args.action := by
  unfold stmts.skips_resource_match at h
  simp only [family_eq_ok] at h
  h5i_invert h
  all_goals
    have hs := family_ok _ _ _ hb_1
    simp only [deref_val] at hs
  · simp [SkipResourceMatch,hs.mp hc]
  · have hn : ¬ ∃ a ∈ st.actions.val, a.family=.Sts := fun hh => hc (hs.mpr hh)
    have ha := (family_ok _ _ _ hb1).mp hc_1
    simp only [deref_val] at ha
    by_cases he : args.action.family=.Admin
    · simp only [he,decide_true,ite_true] at hb3
      have ht := table_ok _ _ hb3
      simpa only [decide_eq_true_eq,SkipResourceMatch,hn,ha,false_or,true_and,not_congr ht]
    · simp only [he,decide_false,Bool.false_eq_true,ite_false,Result.ok.injEq] at hb3
      subst b3
      simp [SkipResourceMatch,hn,ha,TableResourceAction,he]
  · have hn : ¬ ∃ a ∈ st.actions.val, a.family=.Sts := fun hh => hc (hs.mpr hh)
    have ha := family_ok _ _ _ hb1
    simp only [deref_val] at ha
    have hn' : ¬ ∃ a ∈ st.actions.val, a.family=.Admin := fun hh => hc_1 (ha.mpr hh)
    simp [SkipResourceMatch,hn,hn']
end rustfs_kernel.Verified.RustfsStatementSkips
