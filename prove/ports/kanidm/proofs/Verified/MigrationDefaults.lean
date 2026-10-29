import Verified.MigrationDefaultsPart0
import Verified.MigrationDefaultsPart1
import Verified.MigrationDefaultsPart2
import Verified.MigrationDefaultsPart3
import Verified.MigrationDefaultsPart4
import Verified.MigrationDefaultsPart5
import Verified.MigrationDefaultsPart6
import Verified.MigrationDefaultsPart7
import Verified.MigrationDefaultsPart8
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.MigrationDefaults
open kanidm_kernel.Verified.RecoveredProtectedClassNeverAdded
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000

def Passwords (r : alloc.vec.Vec (alloc.vec.Vec U8)) (expected : List (List U8)) : Prop :=
 ∀ c, c ∈ names r.val ↔ c ∈ expected.map nats

theorem empty_passwords : Passwords (alloc.vec.Vec.new (alloc.vec.Vec U8)) [] := by
 simp [Passwords, names, alloc.vec.Vec.new]

theorem insert_passwords (xs ys : alloc.vec.Vec (alloc.vec.Vec U8)) (x : Slice U8)
 (expected : List (List U8)) (hx : Passwords xs expected)
 (h : bset.insert xs x = ok ys) : Passwords ys (expected ++ [x.val]) := by
 intro c
 simpa only [List.map_append, List.mem_append, List.map_cons, List.map_nil, List.mem_singleton]
  using (insert_mem xs ys x h c).trans (or_congr (hx c) Iff.rfl)

theorem extend_passwords (xs ys : alloc.vec.Vec (alloc.vec.Vec U8))
 (part : alloc.vec.Vec (alloc.vec.Vec U8)) (expected new : List (List U8))
 (hx : Passwords xs expected) (ht : part.val.map alloc.vec.Vec.val = new)
 (h : bset.extend xs part.deref = ok ys) : Passwords ys (expected ++ new) := by
 have hp : names part.val = new.map nats := by
  rw [← ht]; simp only [names, List.map_map, Function.comp_def]
 intro c
 simpa only [alloc.vec.Vec.deref, Slice.from_val, hp, List.map_append, List.mem_append]
  using (extend_mem xs ys part.deref h c).trans (or_congr (hx c) Iff.rfl)

def description : List U8 := [83#u8, 121#u8, 115#u8, 116#u8, 101#u8, 109#u8, 32#u8, 40#u8, 114#u8, 101#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 101#u8, 100#u8, 41#u8, 32#u8, 99#u8, 111#u8, 110#u8, 102#u8, 105#u8, 103#u8, 117#u8, 114#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 32#u8, 111#u8, 112#u8, 116#u8, 105#u8, 111#u8, 110#u8, 115#u8, 46#u8]
def Complete (second : List U8) (r : migration_defaults.SystemConfig) : Prop :=
 r.object = true ∧ r.system_config = true ∧ r.system = true ∧
 r.uuid = 281474959933479#u128 ∧ r.description.val = description ∧
 Passwords r.badlist_password ([firstPassword, second] ++ commonPasswords)

theorem initialize_complete (second : Slice U8) (r : migration_defaults.SystemConfig)
 (h : migration_defaults.initialize second = ok r) : Complete second.val r := by
 unfold migration_defaults.initialize at h
 h5i_invert h
 have hfirst := insert_passwords _ _ _ [] empty_passwords hpasswords
 have hsecond := insert_passwords _ _ _ _ hfirst hpasswords1
 have ht0 := post_of_ok table_part_0_spec hpart
 have hs0 := extend_passwords _ _ part _ tablePart0 hsecond ht0 hpasswords2
 have ht1 := post_of_ok table_part_1_spec hpart1
 have hs1 := extend_passwords _ _ part1 _ tablePart1 hs0 ht1 hpasswords3
 have ht2 := post_of_ok table_part_2_spec hpart2
 have hs2 := extend_passwords _ _ part2 _ tablePart2 hs1 ht2 hpasswords4
 have ht3 := post_of_ok table_part_3_spec hpart3
 have hs3 := extend_passwords _ _ part3 _ tablePart3 hs2 ht3 hpasswords5
 have ht4 := post_of_ok table_part_4_spec hpart4
 have hs4 := extend_passwords _ _ part4 _ tablePart4 hs3 ht4 hpasswords6
 have ht5 := post_of_ok table_part_5_spec hpart5
 have hs5 := extend_passwords _ _ part5 _ tablePart5 hs4 ht5 hpasswords7
 have ht6 := post_of_ok table_part_6_spec hpart6
 have hs6 := extend_passwords _ _ part6 _ tablePart6 hs5 ht6 hpasswords8
 have ht7 := post_of_ok table_part_7_spec hpart7
 have hs7 := extend_passwords _ _ part7 _ tablePart7 hs6 ht7 hpasswords9
 have ht8 := post_of_ok table_part_8_spec hpart8
 have hs8 := extend_passwords _ _ part8 _ tablePart8 hs7 ht8 hpasswords10
 have ht9 := post_of_ok table_part_9_spec hpart9
 have hs9 := extend_passwords _ _ part9 _ tablePart9 hs8 ht9 hpasswords11
 have ht10 := post_of_ok table_part_10_spec hpart10
 have hs10 := extend_passwords _ _ part10 _ tablePart10 hs9 ht10 hpasswords12
 have ht11 := post_of_ok table_part_11_spec hpart11
 have hs11 := extend_passwords _ _ part11 _ tablePart11 hs10 ht11 hpasswords13
 have ht12 := post_of_ok table_part_12_spec hpart12
 have hs12 := extend_passwords _ _ part12 _ tablePart12 hs11 ht12 hpasswords14
 have ht13 := post_of_ok table_part_13_spec hpart13
 have hs13 := extend_passwords _ _ part13 _ tablePart13 hs12 ht13 hpasswords15
 have ht14 := post_of_ok table_part_14_spec hpart14
 have hs14 := extend_passwords _ _ part14 _ tablePart14 hs13 ht14 hpasswords16
 have ht15 := post_of_ok table_part_15_spec hpart15
 have hs15 := extend_passwords _ _ part15 _ tablePart15 hs14 ht15 hpasswords17
 have ht16 := post_of_ok table_part_16_spec hpart16
 have hs16 := extend_passwords _ _ part16 _ tablePart16 hs15 ht16 hpasswords18
 have ht17 := post_of_ok table_part_17_spec hpart17
 have hs17 := extend_passwords _ _ part17 _ tablePart17 hs16 ht17 hpasswords19
 have ht18 := post_of_ok table_part_18_spec hpart18
 have hs18 := extend_passwords _ _ part18 _ tablePart18 hs17 ht18 hpasswords20
 have ht19 := post_of_ok table_part_19_spec hpart19
 have hs19 := extend_passwords _ _ part19 _ tablePart19 hs18 ht19 hpasswords21
 have ht20 := post_of_ok table_part_20_spec hpart20
 have hs20 := extend_passwords _ _ part20 _ tablePart20 hs19 ht20 hpasswords22
 have ht21 := post_of_ok table_part_21_spec hpart21
 have hs21 := extend_passwords _ _ part21 _ tablePart21 hs20 ht21 hpasswords23
 have ht22 := post_of_ok table_part_22_spec hpart22
 have hs22 := extend_passwords _ _ part22 _ tablePart22 hs21 ht22 hpasswords24
 have ht23 := post_of_ok table_part_23_spec hpart23
 have hs23 := extend_passwords _ _ part23 _ tablePart23 hs22 ht23 hpasswords25
 have ht24 := post_of_ok table_part_24_spec hpart24
 have hs24 := extend_passwords _ _ part24 _ tablePart24 hs23 ht24 hpasswords26
 have ht25 := post_of_ok table_part_25_spec hpart25
 have hs25 := extend_passwords _ _ part25 _ tablePart25 hs24 ht25 hpasswords27
 have ht26 := post_of_ok table_part_26_spec hpart26
 have hs26 := extend_passwords _ _ part26 _ tablePart26 hs25 ht26 hpasswords28
 have hcopy := post_of_ok (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 s28 (fun _ _ => rfl)) hv
 simp only [lift, Array.to_slice, Array.make, Result.ok.injEq] at hs hs28
 have hdesc : v.val = description := by
  rw [alloc.vec.Vec.val, ← hcopy, ← hs28]
  rfl
 refine ⟨rfl, rfl, rfl, rfl, hdesc, ?_⟩
 simpa [List.append_assoc, commonPasswords, firstPassword, ← hs, Array.make] using hs26

theorem dl11_complete (r : migration_defaults.SystemConfig)
 (h : migration_defaults.dl11 = ok r) : Complete longSentinel r := by
 unfold migration_defaults.dl11 at h
 h5i_invert h
 have hi := initialize_complete s r h
 simp only [lift, Array.to_slice, Array.make, Result.ok.injEq] at hs
 simpa [longSentinel, ← hs, Array.make] using hi

theorem dl12_complete (r : migration_defaults.SystemConfig)
 (h : migration_defaults.dl12 = ok r) : Complete longSentinel r := by
 unfold migration_defaults.dl12 at h
 h5i_invert h
 have hi := initialize_complete s r h
 simp only [lift, Array.to_slice, Array.make, Result.ok.injEq] at hs
 simpa [longSentinel, ← hs, Array.make] using hi

theorem dl13_complete (r : migration_defaults.SystemConfig)
 (h : migration_defaults.dl13 = ok r) : Complete longSentinel r := by
 unfold migration_defaults.dl13 at h
 h5i_invert h
 have hi := initialize_complete s r h
 simp only [lift, Array.to_slice, Array.make, Result.ok.injEq] at hs
 simpa [longSentinel, ← hs, Array.make] using hi

theorem dl14_complete (r : migration_defaults.SystemConfig)
 (h : migration_defaults.dl14 = ok r) : Complete longSentinel r := by
 unfold migration_defaults.dl14 at h
 h5i_invert h
 have hi := initialize_complete s r h
 simp only [lift, Array.to_slice, Array.make, Result.ok.injEq] at hs
 simpa [longSentinel, ← hs, Array.make] using hi

theorem dl15_complete (r : migration_defaults.SystemConfig)
 (h : migration_defaults.dl15 = ok r) : Complete shortSentinel r := by
 unfold migration_defaults.dl15 at h
 h5i_invert h
 have hi := initialize_complete s r h
 simp only [lift, Array.to_slice, Array.make, Result.ok.injEq] at hs
 simpa [shortSentinel, ← hs, Array.make] using hi

theorem dl_1_12_complete (r : migration_defaults.SystemConfig)
 (h : migration_defaults.dl_1_12 = ok r) : Complete shortSentinel r := by
 unfold migration_defaults.dl_1_12 at h
 h5i_invert h
 have hi := initialize_complete s r h
 simp only [lift, Array.to_slice, Array.make, Result.ok.injEq] at hs
 simpa [shortSentinel, ← hs, Array.make] using hi

end kanidm_kernel.Verified.MigrationDefaults
