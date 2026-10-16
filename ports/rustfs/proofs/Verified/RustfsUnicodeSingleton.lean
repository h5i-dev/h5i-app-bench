import SpecUnicode
import Verified.RustfsValids
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsUnicodeSingleton
set_option maxRecDepth 8192
set_option maxHeartbeats 0

theorem rec_const {α β : Sort _} {a b : α} (h : a = b) (x : β) :
    @Eq.ndrec α a (fun _ => β) x b h = x := by cases h; rfl

theorem singleton_ok (cp : U32) (out : U32 × U32 × Usize)
    (h : unicode.singleton cp = ok out) :
    (out.1.val,out.2.1.val,out.2.2.val) = LookupLowerSingleton cp.val := by
  cases cp with
  | mk bv =>
    delta unicode.singleton unicode.singleton.match_1 at h
    dsimp only at h
    simp only [rec_const] at h
    simp only [← BitVec.toNat_inj] at h
    by_cases h0 : bv.toNat = (304#32).toNat
    · simp only [*, ↓reduceDIte] at h
      cases Result.ok.inj h
      change (105,775,2) = LookupLowerSingleton bv.toNat
      rw [h0]
      rfl
    ·
      by_cases h1 : bv.toNat = (376#32).toNat
      · simp only [*, ↓reduceDIte] at h
        cases Result.ok.inj h
        change (255,0,1) = LookupLowerSingleton bv.toNat
        rw [h1]
        rfl
      ·
        by_cases h2 : bv.toNat = (385#32).toNat
        · simp only [*, ↓reduceDIte] at h
          cases Result.ok.inj h
          change (595,0,1) = LookupLowerSingleton bv.toNat
          rw [h2]
          rfl
        ·
          by_cases h3 : bv.toNat = (390#32).toNat
          · simp only [*, ↓reduceDIte] at h
            cases Result.ok.inj h
            change (596,0,1) = LookupLowerSingleton bv.toNat
            rw [h3]
            rfl
          ·
            by_cases h4 : bv.toNat = (391#32).toNat
            · simp only [*, ↓reduceDIte] at h
              cases Result.ok.inj h
              change (392,0,1) = LookupLowerSingleton bv.toNat
              rw [h4]
              rfl
            ·
              by_cases h5 : bv.toNat = (395#32).toNat
              · simp only [*, ↓reduceDIte] at h
                cases Result.ok.inj h
                change (396,0,1) = LookupLowerSingleton bv.toNat
                rw [h5]
                rfl
              ·
                by_cases h6 : bv.toNat = (398#32).toNat
                · simp only [*, ↓reduceDIte] at h
                  cases Result.ok.inj h
                  change (477,0,1) = LookupLowerSingleton bv.toNat
                  rw [h6]
                  rfl
                ·
                  by_cases h7 : bv.toNat = (399#32).toNat
                  · simp only [*, ↓reduceDIte] at h
                    cases Result.ok.inj h
                    change (601,0,1) = LookupLowerSingleton bv.toNat
                    rw [h7]
                    rfl
                  ·
                    by_cases h8 : bv.toNat = (400#32).toNat
                    · simp only [*, ↓reduceDIte] at h
                      cases Result.ok.inj h
                      change (603,0,1) = LookupLowerSingleton bv.toNat
                      rw [h8]
                      rfl
                    ·
                      by_cases h9 : bv.toNat = (401#32).toNat
                      · simp only [*, ↓reduceDIte] at h
                        cases Result.ok.inj h
                        change (402,0,1) = LookupLowerSingleton bv.toNat
                        rw [h9]
                        rfl
                      ·
                        by_cases h10 : bv.toNat = (403#32).toNat
                        · simp only [*, ↓reduceDIte] at h
                          cases Result.ok.inj h
                          change (608,0,1) = LookupLowerSingleton bv.toNat
                          rw [h10]
                          rfl
                        ·
                          by_cases h11 : bv.toNat = (404#32).toNat
                          · simp only [*, ↓reduceDIte] at h
                            cases Result.ok.inj h
                            change (611,0,1) = LookupLowerSingleton bv.toNat
                            rw [h11]
                            rfl
                          ·
                            by_cases h12 : bv.toNat = (406#32).toNat
                            · simp only [*, ↓reduceDIte] at h
                              cases Result.ok.inj h
                              change (617,0,1) = LookupLowerSingleton bv.toNat
                              rw [h12]
                              rfl
                            ·
                              by_cases h13 : bv.toNat = (407#32).toNat
                              · simp only [*, ↓reduceDIte] at h
                                cases Result.ok.inj h
                                change (616,0,1) = LookupLowerSingleton bv.toNat
                                rw [h13]
                                rfl
                              ·
                                by_cases h14 : bv.toNat = (408#32).toNat
                                · simp only [*, ↓reduceDIte] at h
                                  cases Result.ok.inj h
                                  change (409,0,1) = LookupLowerSingleton bv.toNat
                                  rw [h14]
                                  rfl
                                ·
                                  by_cases h15 : bv.toNat = (412#32).toNat
                                  · simp only [*, ↓reduceDIte] at h
                                    cases Result.ok.inj h
                                    change (623,0,1) = LookupLowerSingleton bv.toNat
                                    rw [h15]
                                    rfl
                                  ·
                                    by_cases h16 : bv.toNat = (413#32).toNat
                                    · simp only [*, ↓reduceDIte] at h
                                      cases Result.ok.inj h
                                      change (626,0,1) = LookupLowerSingleton bv.toNat
                                      rw [h16]
                                      rfl
                                    ·
                                      by_cases h17 : bv.toNat = (415#32).toNat
                                      · simp only [*, ↓reduceDIte] at h
                                        cases Result.ok.inj h
                                        change (629,0,1) = LookupLowerSingleton bv.toNat
                                        rw [h17]
                                        rfl
                                      ·
                                        by_cases h18 : bv.toNat = (422#32).toNat
                                        · simp only [*, ↓reduceDIte] at h
                                          cases Result.ok.inj h
                                          change (640,0,1) = LookupLowerSingleton bv.toNat
                                          rw [h18]
                                          rfl
                                        ·
                                          by_cases h19 : bv.toNat = (423#32).toNat
                                          · simp only [*, ↓reduceDIte] at h
                                            cases Result.ok.inj h
                                            change (424,0,1) = LookupLowerSingleton bv.toNat
                                            rw [h19]
                                            rfl
                                          ·
                                            by_cases h20 : bv.toNat = (425#32).toNat
                                            · simp only [*, ↓reduceDIte] at h
                                              cases Result.ok.inj h
                                              change (643,0,1) = LookupLowerSingleton bv.toNat
                                              rw [h20]
                                              rfl
                                            ·
                                              by_cases h21 : bv.toNat = (428#32).toNat
                                              · simp only [*, ↓reduceDIte] at h
                                                cases Result.ok.inj h
                                                change (429,0,1) = LookupLowerSingleton bv.toNat
                                                rw [h21]
                                                rfl
                                              ·
                                                by_cases h22 : bv.toNat = (430#32).toNat
                                                · simp only [*, ↓reduceDIte] at h
                                                  cases Result.ok.inj h
                                                  change (648,0,1) = LookupLowerSingleton bv.toNat
                                                  rw [h22]
                                                  rfl
                                                ·
                                                  by_cases h23 : bv.toNat = (431#32).toNat
                                                  · simp only [*, ↓reduceDIte] at h
                                                    cases Result.ok.inj h
                                                    change (432,0,1) = LookupLowerSingleton bv.toNat
                                                    rw [h23]
                                                    rfl
                                                  ·
                                                    by_cases h24 : bv.toNat = (439#32).toNat
                                                    · simp only [*, ↓reduceDIte] at h
                                                      cases Result.ok.inj h
                                                      change (658,0,1) = LookupLowerSingleton bv.toNat
                                                      rw [h24]
                                                      rfl
                                                    ·
                                                      by_cases h25 : bv.toNat = (440#32).toNat
                                                      · simp only [*, ↓reduceDIte] at h
                                                        cases Result.ok.inj h
                                                        change (441,0,1) = LookupLowerSingleton bv.toNat
                                                        rw [h25]
                                                        rfl
                                                      ·
                                                        by_cases h26 : bv.toNat = (444#32).toNat
                                                        · simp only [*, ↓reduceDIte] at h
                                                          cases Result.ok.inj h
                                                          change (445,0,1) = LookupLowerSingleton bv.toNat
                                                          rw [h26]
                                                          rfl
                                                        ·
                                                          by_cases h27 : bv.toNat = (452#32).toNat
                                                          · simp only [*, ↓reduceDIte] at h
                                                            cases Result.ok.inj h
                                                            change (454,0,1) = LookupLowerSingleton bv.toNat
                                                            rw [h27]
                                                            rfl
                                                          ·
                                                            by_cases h28 : bv.toNat = (453#32).toNat
                                                            · simp only [*, ↓reduceDIte] at h
                                                              cases Result.ok.inj h
                                                              change (454,0,1) = LookupLowerSingleton bv.toNat
                                                              rw [h28]
                                                              rfl
                                                            ·
                                                              by_cases h29 : bv.toNat = (455#32).toNat
                                                              · simp only [*, ↓reduceDIte] at h
                                                                cases Result.ok.inj h
                                                                change (457,0,1) = LookupLowerSingleton bv.toNat
                                                                rw [h29]
                                                                rfl
                                                              ·
                                                                by_cases h30 : bv.toNat = (456#32).toNat
                                                                · simp only [*, ↓reduceDIte] at h
                                                                  cases Result.ok.inj h
                                                                  change (457,0,1) = LookupLowerSingleton bv.toNat
                                                                  rw [h30]
                                                                  rfl
                                                                ·
                                                                  by_cases h31 : bv.toNat = (458#32).toNat
                                                                  · simp only [*, ↓reduceDIte] at h
                                                                    cases Result.ok.inj h
                                                                    change (460,0,1) = LookupLowerSingleton bv.toNat
                                                                    rw [h31]
                                                                    rfl
                                                                  ·
                                                                    by_cases h32 : bv.toNat = (497#32).toNat
                                                                    · simp only [*, ↓reduceDIte] at h
                                                                      cases Result.ok.inj h
                                                                      change (499,0,1) = LookupLowerSingleton bv.toNat
                                                                      rw [h32]
                                                                      rfl
                                                                    ·
                                                                      by_cases h33 : bv.toNat = (502#32).toNat
                                                                      · simp only [*, ↓reduceDIte] at h
                                                                        cases Result.ok.inj h
                                                                        change (405,0,1) = LookupLowerSingleton bv.toNat
                                                                        rw [h33]
                                                                        rfl
                                                                      ·
                                                                        by_cases h34 : bv.toNat = (503#32).toNat
                                                                        · simp only [*, ↓reduceDIte] at h
                                                                          cases Result.ok.inj h
                                                                          change (447,0,1) = LookupLowerSingleton bv.toNat
                                                                          rw [h34]
                                                                          rfl
                                                                        ·
                                                                          by_cases h35 : bv.toNat = (544#32).toNat
                                                                          · simp only [*, ↓reduceDIte] at h
                                                                            cases Result.ok.inj h
                                                                            change (414,0,1) = LookupLowerSingleton bv.toNat
                                                                            rw [h35]
                                                                            rfl
                                                                          ·
                                                                            by_cases h36 : bv.toNat = (570#32).toNat
                                                                            · simp only [*, ↓reduceDIte] at h
                                                                              cases Result.ok.inj h
                                                                              change (11365,0,1) = LookupLowerSingleton bv.toNat
                                                                              rw [h36]
                                                                              rfl
                                                                            ·
                                                                              by_cases h37 : bv.toNat = (571#32).toNat
                                                                              · simp only [*, ↓reduceDIte] at h
                                                                                cases Result.ok.inj h
                                                                                change (572,0,1) = LookupLowerSingleton bv.toNat
                                                                                rw [h37]
                                                                                rfl
                                                                              ·
                                                                                by_cases h38 : bv.toNat = (573#32).toNat
                                                                                · simp only [*, ↓reduceDIte] at h
                                                                                  cases Result.ok.inj h
                                                                                  change (410,0,1) = LookupLowerSingleton bv.toNat
                                                                                  rw [h38]
                                                                                  rfl
                                                                                ·
                                                                                  by_cases h39 : bv.toNat = (574#32).toNat
                                                                                  · simp only [*, ↓reduceDIte] at h
                                                                                    cases Result.ok.inj h
                                                                                    change (11366,0,1) = LookupLowerSingleton bv.toNat
                                                                                    rw [h39]
                                                                                    rfl
                                                                                  ·
                                                                                    by_cases h40 : bv.toNat = (577#32).toNat
                                                                                    · simp only [*, ↓reduceDIte] at h
                                                                                      cases Result.ok.inj h
                                                                                      change (578,0,1) = LookupLowerSingleton bv.toNat
                                                                                      rw [h40]
                                                                                      rfl
                                                                                    ·
                                                                                      by_cases h41 : bv.toNat = (579#32).toNat
                                                                                      · simp only [*, ↓reduceDIte] at h
                                                                                        cases Result.ok.inj h
                                                                                        change (384,0,1) = LookupLowerSingleton bv.toNat
                                                                                        rw [h41]
                                                                                        rfl
                                                                                      ·
                                                                                        by_cases h42 : bv.toNat = (580#32).toNat
                                                                                        · simp only [*, ↓reduceDIte] at h
                                                                                          cases Result.ok.inj h
                                                                                          change (649,0,1) = LookupLowerSingleton bv.toNat
                                                                                          rw [h42]
                                                                                          rfl
                                                                                        ·
                                                                                          by_cases h43 : bv.toNat = (581#32).toNat
                                                                                          · simp only [*, ↓reduceDIte] at h
                                                                                            cases Result.ok.inj h
                                                                                            change (652,0,1) = LookupLowerSingleton bv.toNat
                                                                                            rw [h43]
                                                                                            rfl
                                                                                          ·
                                                                                            by_cases h44 : bv.toNat = (886#32).toNat
                                                                                            · simp only [*, ↓reduceDIte] at h
                                                                                              cases Result.ok.inj h
                                                                                              change (887,0,1) = LookupLowerSingleton bv.toNat
                                                                                              rw [h44]
                                                                                              rfl
                                                                                            ·
                                                                                              by_cases h45 : bv.toNat = (895#32).toNat
                                                                                              · simp only [*, ↓reduceDIte] at h
                                                                                                cases Result.ok.inj h
                                                                                                change (1011,0,1) = LookupLowerSingleton bv.toNat
                                                                                                rw [h45]
                                                                                                rfl
                                                                                              ·
                                                                                                by_cases h46 : bv.toNat = (902#32).toNat
                                                                                                · simp only [*, ↓reduceDIte] at h
                                                                                                  cases Result.ok.inj h
                                                                                                  change (940,0,1) = LookupLowerSingleton bv.toNat
                                                                                                  rw [h46]
                                                                                                  rfl
                                                                                                ·
                                                                                                  by_cases h47 : bv.toNat = (908#32).toNat
                                                                                                  · simp only [*, ↓reduceDIte] at h
                                                                                                    cases Result.ok.inj h
                                                                                                    change (972,0,1) = LookupLowerSingleton bv.toNat
                                                                                                    rw [h47]
                                                                                                    rfl
                                                                                                  ·
                                                                                                    by_cases h48 : bv.toNat = (975#32).toNat
                                                                                                    · simp only [*, ↓reduceDIte] at h
                                                                                                      cases Result.ok.inj h
                                                                                                      change (983,0,1) = LookupLowerSingleton bv.toNat
                                                                                                      rw [h48]
                                                                                                      rfl
                                                                                                    ·
                                                                                                      by_cases h49 : bv.toNat = (1012#32).toNat
                                                                                                      · simp only [*, ↓reduceDIte] at h
                                                                                                        cases Result.ok.inj h
                                                                                                        change (952,0,1) = LookupLowerSingleton bv.toNat
                                                                                                        rw [h49]
                                                                                                        rfl
                                                                                                      ·
                                                                                                        by_cases h50 : bv.toNat = (1015#32).toNat
                                                                                                        · simp only [*, ↓reduceDIte] at h
                                                                                                          cases Result.ok.inj h
                                                                                                          change (1016,0,1) = LookupLowerSingleton bv.toNat
                                                                                                          rw [h50]
                                                                                                          rfl
                                                                                                        ·
                                                                                                          by_cases h51 : bv.toNat = (1017#32).toNat
                                                                                                          · simp only [*, ↓reduceDIte] at h
                                                                                                            cases Result.ok.inj h
                                                                                                            change (1010,0,1) = LookupLowerSingleton bv.toNat
                                                                                                            rw [h51]
                                                                                                            rfl
                                                                                                          ·
                                                                                                            by_cases h52 : bv.toNat = (1018#32).toNat
                                                                                                            · simp only [*, ↓reduceDIte] at h
                                                                                                              cases Result.ok.inj h
                                                                                                              change (1019,0,1) = LookupLowerSingleton bv.toNat
                                                                                                              rw [h52]
                                                                                                              rfl
                                                                                                            ·
                                                                                                              by_cases h53 : bv.toNat = (1216#32).toNat
                                                                                                              · simp only [*, ↓reduceDIte] at h
                                                                                                                cases Result.ok.inj h
                                                                                                                change (1231,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                rw [h53]
                                                                                                                rfl
                                                                                                              ·
                                                                                                                by_cases h54 : bv.toNat = (4295#32).toNat
                                                                                                                · simp only [*, ↓reduceDIte] at h
                                                                                                                  cases Result.ok.inj h
                                                                                                                  change (11559,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                  rw [h54]
                                                                                                                  rfl
                                                                                                                ·
                                                                                                                  by_cases h55 : bv.toNat = (4301#32).toNat
                                                                                                                  · simp only [*, ↓reduceDIte] at h
                                                                                                                    cases Result.ok.inj h
                                                                                                                    change (11565,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                    rw [h55]
                                                                                                                    rfl
                                                                                                                  ·
                                                                                                                    by_cases h56 : bv.toNat = (7305#32).toNat
                                                                                                                    · simp only [*, ↓reduceDIte] at h
                                                                                                                      cases Result.ok.inj h
                                                                                                                      change (7306,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                      rw [h56]
                                                                                                                      rfl
                                                                                                                    ·
                                                                                                                      by_cases h57 : bv.toNat = (7838#32).toNat
                                                                                                                      · simp only [*, ↓reduceDIte] at h
                                                                                                                        cases Result.ok.inj h
                                                                                                                        change (223,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                        rw [h57]
                                                                                                                        rfl
                                                                                                                      ·
                                                                                                                        by_cases h58 : bv.toNat = (8124#32).toNat
                                                                                                                        · simp only [*, ↓reduceDIte] at h
                                                                                                                          cases Result.ok.inj h
                                                                                                                          change (8115,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                          rw [h58]
                                                                                                                          rfl
                                                                                                                        ·
                                                                                                                          by_cases h59 : bv.toNat = (8140#32).toNat
                                                                                                                          · simp only [*, ↓reduceDIte] at h
                                                                                                                            cases Result.ok.inj h
                                                                                                                            change (8131,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                            rw [h59]
                                                                                                                            rfl
                                                                                                                          ·
                                                                                                                            by_cases h60 : bv.toNat = (8172#32).toNat
                                                                                                                            · simp only [*, ↓reduceDIte] at h
                                                                                                                              cases Result.ok.inj h
                                                                                                                              change (8165,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                              rw [h60]
                                                                                                                              rfl
                                                                                                                            ·
                                                                                                                              by_cases h61 : bv.toNat = (8188#32).toNat
                                                                                                                              · simp only [*, ↓reduceDIte] at h
                                                                                                                                cases Result.ok.inj h
                                                                                                                                change (8179,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                rw [h61]
                                                                                                                                rfl
                                                                                                                              ·
                                                                                                                                by_cases h62 : bv.toNat = (8486#32).toNat
                                                                                                                                · simp only [*, ↓reduceDIte] at h
                                                                                                                                  cases Result.ok.inj h
                                                                                                                                  change (969,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                  rw [h62]
                                                                                                                                  rfl
                                                                                                                                ·
                                                                                                                                  by_cases h63 : bv.toNat = (8490#32).toNat
                                                                                                                                  · simp only [*, ↓reduceDIte] at h
                                                                                                                                    cases Result.ok.inj h
                                                                                                                                    change (107,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                    rw [h63]
                                                                                                                                    rfl
                                                                                                                                  ·
                                                                                                                                    by_cases h64 : bv.toNat = (8491#32).toNat
                                                                                                                                    · simp only [*, ↓reduceDIte] at h
                                                                                                                                      cases Result.ok.inj h
                                                                                                                                      change (229,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                      rw [h64]
                                                                                                                                      rfl
                                                                                                                                    ·
                                                                                                                                      by_cases h65 : bv.toNat = (8498#32).toNat
                                                                                                                                      · simp only [*, ↓reduceDIte] at h
                                                                                                                                        cases Result.ok.inj h
                                                                                                                                        change (8526,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                        rw [h65]
                                                                                                                                        rfl
                                                                                                                                      ·
                                                                                                                                        by_cases h66 : bv.toNat = (8579#32).toNat
                                                                                                                                        · simp only [*, ↓reduceDIte] at h
                                                                                                                                          cases Result.ok.inj h
                                                                                                                                          change (8580,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                          rw [h66]
                                                                                                                                          rfl
                                                                                                                                        ·
                                                                                                                                          by_cases h67 : bv.toNat = (11360#32).toNat
                                                                                                                                          · simp only [*, ↓reduceDIte] at h
                                                                                                                                            cases Result.ok.inj h
                                                                                                                                            change (11361,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                            rw [h67]
                                                                                                                                            rfl
                                                                                                                                          ·
                                                                                                                                            by_cases h68 : bv.toNat = (11362#32).toNat
                                                                                                                                            · simp only [*, ↓reduceDIte] at h
                                                                                                                                              cases Result.ok.inj h
                                                                                                                                              change (619,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                              rw [h68]
                                                                                                                                              rfl
                                                                                                                                            ·
                                                                                                                                              by_cases h69 : bv.toNat = (11363#32).toNat
                                                                                                                                              · simp only [*, ↓reduceDIte] at h
                                                                                                                                                cases Result.ok.inj h
                                                                                                                                                change (7549,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                rw [h69]
                                                                                                                                                rfl
                                                                                                                                              ·
                                                                                                                                                by_cases h70 : bv.toNat = (11364#32).toNat
                                                                                                                                                · simp only [*, ↓reduceDIte] at h
                                                                                                                                                  cases Result.ok.inj h
                                                                                                                                                  change (637,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                  rw [h70]
                                                                                                                                                  rfl
                                                                                                                                                ·
                                                                                                                                                  by_cases h71 : bv.toNat = (11373#32).toNat
                                                                                                                                                  · simp only [*, ↓reduceDIte] at h
                                                                                                                                                    cases Result.ok.inj h
                                                                                                                                                    change (593,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                    rw [h71]
                                                                                                                                                    rfl
                                                                                                                                                  ·
                                                                                                                                                    by_cases h72 : bv.toNat = (11374#32).toNat
                                                                                                                                                    · simp only [*, ↓reduceDIte] at h
                                                                                                                                                      cases Result.ok.inj h
                                                                                                                                                      change (625,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                      rw [h72]
                                                                                                                                                      rfl
                                                                                                                                                    ·
                                                                                                                                                      by_cases h73 : bv.toNat = (11375#32).toNat
                                                                                                                                                      · simp only [*, ↓reduceDIte] at h
                                                                                                                                                        cases Result.ok.inj h
                                                                                                                                                        change (592,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                        rw [h73]
                                                                                                                                                        rfl
                                                                                                                                                      ·
                                                                                                                                                        by_cases h74 : bv.toNat = (11376#32).toNat
                                                                                                                                                        · simp only [*, ↓reduceDIte] at h
                                                                                                                                                          cases Result.ok.inj h
                                                                                                                                                          change (594,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                          rw [h74]
                                                                                                                                                          rfl
                                                                                                                                                        ·
                                                                                                                                                          by_cases h75 : bv.toNat = (11378#32).toNat
                                                                                                                                                          · simp only [*, ↓reduceDIte] at h
                                                                                                                                                            cases Result.ok.inj h
                                                                                                                                                            change (11379,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                            rw [h75]
                                                                                                                                                            rfl
                                                                                                                                                          ·
                                                                                                                                                            by_cases h76 : bv.toNat = (11381#32).toNat
                                                                                                                                                            · simp only [*, ↓reduceDIte] at h
                                                                                                                                                              cases Result.ok.inj h
                                                                                                                                                              change (11382,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                              rw [h76]
                                                                                                                                                              rfl
                                                                                                                                                            ·
                                                                                                                                                              by_cases h77 : bv.toNat = (11506#32).toNat
                                                                                                                                                              · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                cases Result.ok.inj h
                                                                                                                                                                change (11507,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                rw [h77]
                                                                                                                                                                rfl
                                                                                                                                                              ·
                                                                                                                                                                by_cases h78 : bv.toNat = (42877#32).toNat
                                                                                                                                                                · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                  cases Result.ok.inj h
                                                                                                                                                                  change (7545,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                  rw [h78]
                                                                                                                                                                  rfl
                                                                                                                                                                ·
                                                                                                                                                                  by_cases h79 : bv.toNat = (42891#32).toNat
                                                                                                                                                                  · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                    cases Result.ok.inj h
                                                                                                                                                                    change (42892,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                    rw [h79]
                                                                                                                                                                    rfl
                                                                                                                                                                  ·
                                                                                                                                                                    by_cases h80 : bv.toNat = (42893#32).toNat
                                                                                                                                                                    · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                      cases Result.ok.inj h
                                                                                                                                                                      change (613,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                      rw [h80]
                                                                                                                                                                      rfl
                                                                                                                                                                    ·
                                                                                                                                                                      by_cases h81 : bv.toNat = (42922#32).toNat
                                                                                                                                                                      · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                        cases Result.ok.inj h
                                                                                                                                                                        change (614,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                        rw [h81]
                                                                                                                                                                        rfl
                                                                                                                                                                      ·
                                                                                                                                                                        by_cases h82 : bv.toNat = (42923#32).toNat
                                                                                                                                                                        · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                          cases Result.ok.inj h
                                                                                                                                                                          change (604,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                          rw [h82]
                                                                                                                                                                          rfl
                                                                                                                                                                        ·
                                                                                                                                                                          by_cases h83 : bv.toNat = (42924#32).toNat
                                                                                                                                                                          · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                            cases Result.ok.inj h
                                                                                                                                                                            change (609,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                            rw [h83]
                                                                                                                                                                            rfl
                                                                                                                                                                          ·
                                                                                                                                                                            by_cases h84 : bv.toNat = (42925#32).toNat
                                                                                                                                                                            · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                              cases Result.ok.inj h
                                                                                                                                                                              change (620,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                              rw [h84]
                                                                                                                                                                              rfl
                                                                                                                                                                            ·
                                                                                                                                                                              by_cases h85 : bv.toNat = (42926#32).toNat
                                                                                                                                                                              · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                                cases Result.ok.inj h
                                                                                                                                                                                change (618,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                                rw [h85]
                                                                                                                                                                                rfl
                                                                                                                                                                              ·
                                                                                                                                                                                by_cases h86 : bv.toNat = (42928#32).toNat
                                                                                                                                                                                · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                                  cases Result.ok.inj h
                                                                                                                                                                                  change (670,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                                  rw [h86]
                                                                                                                                                                                  rfl
                                                                                                                                                                                ·
                                                                                                                                                                                  by_cases h87 : bv.toNat = (42929#32).toNat
                                                                                                                                                                                  · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                                    cases Result.ok.inj h
                                                                                                                                                                                    change (647,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                                    rw [h87]
                                                                                                                                                                                    rfl
                                                                                                                                                                                  ·
                                                                                                                                                                                    by_cases h88 : bv.toNat = (42930#32).toNat
                                                                                                                                                                                    · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                                      cases Result.ok.inj h
                                                                                                                                                                                      change (669,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                                      rw [h88]
                                                                                                                                                                                      rfl
                                                                                                                                                                                    ·
                                                                                                                                                                                      by_cases h89 : bv.toNat = (42931#32).toNat
                                                                                                                                                                                      · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                                        cases Result.ok.inj h
                                                                                                                                                                                        change (43859,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                                        rw [h89]
                                                                                                                                                                                        rfl
                                                                                                                                                                                      ·
                                                                                                                                                                                        by_cases h90 : bv.toNat = (42948#32).toNat
                                                                                                                                                                                        · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                                          cases Result.ok.inj h
                                                                                                                                                                                          change (42900,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                                          rw [h90]
                                                                                                                                                                                          rfl
                                                                                                                                                                                        ·
                                                                                                                                                                                          by_cases h91 : bv.toNat = (42949#32).toNat
                                                                                                                                                                                          · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                                            cases Result.ok.inj h
                                                                                                                                                                                            change (642,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                                            rw [h91]
                                                                                                                                                                                            rfl
                                                                                                                                                                                          ·
                                                                                                                                                                                            by_cases h92 : bv.toNat = (42950#32).toNat
                                                                                                                                                                                            · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                                              cases Result.ok.inj h
                                                                                                                                                                                              change (7566,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                                              rw [h92]
                                                                                                                                                                                              rfl
                                                                                                                                                                                            ·
                                                                                                                                                                                              by_cases h93 : bv.toNat = (42955#32).toNat
                                                                                                                                                                                              · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                                                cases Result.ok.inj h
                                                                                                                                                                                                change (612,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                                                rw [h93]
                                                                                                                                                                                                rfl
                                                                                                                                                                                              ·
                                                                                                                                                                                                by_cases h94 : bv.toNat = (42972#32).toNat
                                                                                                                                                                                                · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                                                  cases Result.ok.inj h
                                                                                                                                                                                                  change (411,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                                                  rw [h94]
                                                                                                                                                                                                  rfl
                                                                                                                                                                                                ·
                                                                                                                                                                                                  by_cases h95 : bv.toNat = (42997#32).toNat
                                                                                                                                                                                                  · simp only [*, ↓reduceDIte] at h
                                                                                                                                                                                                    cases Result.ok.inj h
                                                                                                                                                                                                    change (42998,0,1) = LookupLowerSingleton bv.toNat
                                                                                                                                                                                                    rw [h95]
                                                                                                                                                                                                    rfl
                                                                                                                                                                                                  ·
                                                                                                                                                                                                    simp only [*, ↓reduceDIte] at h
                                                                                                                                                                                                    cases Result.ok.inj h
                                                                                                                                                                                                    simp_all [LookupLowerSingleton, LowerSingletonEntries, UScalar.val]
end rustfs_kernel.Verified.RustfsUnicodeSingleton
