import Verified.RustfsManagementCopies
import Verified.RustfsManagementQueries
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsStatementRetention
open rustfs_kernel.Verified.RustfsManagementCopies (statement_clone)
open rustfs_kernel.Verified.RustfsManagementQueries (index_member_ok)
open rustfs_kernel.Verified.RustfsBytes (push_ok)
theorem append_ok (initial : alloc.vec.Vec manage.Statement) (ss : Slice manage.Statement)
    (out : alloc.vec.Vec manage.Statement) (h : manage.append_statements initial ss = ok out) :
    out.val = initial.val ++ ss.val := by
  unfold manage.append_statements manage.append_statements_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec manage.Statement × Usize =>
      x.2.val ≤ ss.val.length ∧ x.1.val = initial.val ++ ss.val.take x.2.val)
    (fun out => out.val = initial.val ++ ss.val) (fun x => ss.val.length - x.2.val)
    ?_ _ out ⟨by simp,by simp⟩ h
  rintro ⟨acc,i⟩ r ⟨hi,ha⟩ hr
  unfold manage.append_statements_loop.body at hr
  simp only [statement_clone,bind_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hs1
    have hadd := add_ok_val hi2
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    dsimp only at ha ⊢
    rw [push_ok hout1,ha,show i2.val = i.val + 1 by scalar_tac,List.take_add_one,
      List.getElem?_eq_getElem hlt,he]
    simp only [Option.toList_some,List.append_assoc]
  · dsimp only at ha ⊢
    rwa [List.take_of_length_le (by scalar_tac)] at ha
theorem index_val_mem (ds : List Usize) (i : Usize) :
    i ∈ ds ↔ i.val ∈ ds.map (fun k => k.val) := by
  constructor
  · exact fun h => List.mem_map.2 ⟨i,h,rfl⟩
  · intro h
    obtain ⟨k,hk,he⟩ := List.mem_map.1 h
    have hk' : k = i := UScalar.eq_of_val_eq he
    simpa [hk'] using hk

theorem retain_ok (ss : Slice manage.Statement) (ds : Slice Usize)
    (out : alloc.vec.Vec manage.Statement) (h : manage.retained_statements ss ds = ok out) :
    out.val = RetainStatements ss.val (ds.val.map (fun k => k.val)) := by
  unfold manage.retained_statements manage.retained_statements_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec manage.Statement × Usize =>
      x.2.val ≤ ss.val.length ∧ x.1.val =
        ((ss.val.zipIdx.take x.2.val).filter (fun e => !decide (e.2 ∈ ds.val.map (fun k => k.val)))).map Prod.fst)
    (fun out => out.val = RetainStatements ss.val (ds.val.map (fun k => k.val)))
    (fun x => ss.val.length - x.2.val) ?_ _ out ⟨by simp,by simp⟩ h
  rintro ⟨acc,i⟩ r ⟨hi,ha⟩ hr
  dsimp only at hi ha ⊢
  unfold manage.retained_statements_loop.body at hr
  h5i_invert hr
  · have hlt : i.val < ss.val.length := by scalar_tac
    have hm := index_member_ok ds i b hb
    have hadd := add_ok_val hi2
    have htake : ss.val.zipIdx.take i2.val = ss.val.zipIdx.take i.val ++ [(ss.val[i.val],i.val)] := by
      rw [show i2.val = i.val + 1 by scalar_tac,List.take_add_one,
        List.getElem?_eq_getElem (by simpa using hlt)]
      simp only [List.getElem_zipIdx,Option.toList_some,Nat.zero_add]
    simp only [statement_clone,bind_ok] at hout1
    h5i_invert hout1
    · have hin := (index_val_mem ds.val i).1 (hm.1 hc_1)
      dsimp only
      refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
      rw [htake,List.filter_append,List.map_append]
      simpa only [List.filter_cons,List.filter_nil,Prod.snd,hin,decide_true,Bool.not_true,Bool.false_eq_true,ite_false,List.map_nil,List.append_nil] using ha
    · obtain ⟨_,he⟩ := slice_index_ok hs1
      have hin : i.val ∉ ds.val.map (fun k => k.val) := by
        intro hh; exact hc_1 (hm.2 ((index_val_mem ds.val i).2 hh))
      dsimp only
      refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
      rw [push_ok hout1,ha,htake,List.filter_append,List.map_append]
      simp only [List.filter_cons,List.filter_nil,Prod.snd,hin,decide_false,Bool.not_false,ite_true,List.map_cons,List.map_nil,Prod.fst,List.append_nil,he]
  · dsimp only
    unfold RetainStatements
    rw [List.take_of_length_le (by simpa using (show ss.val.length ≤ i.val by scalar_tac))] at ha
    exact ha
end rustfs_kernel.Verified.RustfsStatementRetention
