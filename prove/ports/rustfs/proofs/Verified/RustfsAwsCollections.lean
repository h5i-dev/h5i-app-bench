import Verified.RustfsAwsValues
import Verified.RustfsCondData
import SpecAwsExpansion
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsAwsCollections
set_option maxHeartbeats 2000000
set_option linter.unusedSimpArgs false

def pending (p : awsvars.Pending) : List U8 × Nat := (p.text.val,p.resume.val)
theorem pending_clone_ok (p : awsvars.Pending) : awsvars.pending_clone p = ok p := by
  simp [awsvars.pending_clone,u8vec_clone]

theorem extend_ok (acc out : alloc.vec.Vec (alloc.vec.Vec U8))
    (more : Slice (alloc.vec.Vec U8)) (h : awsvars.extend acc more = ok out) :
    out.val = acc.val++more.val := by
  unfold awsvars.extend awsvars.extend_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
      x.2.val ≤ more.val.length ∧ x.1.val=acc.val++more.val.take x.2.val)
    (fun out => out.val=acc.val++more.val) (fun x => more.val.length-x.2.val)
    ?_ _ out (by simp) h
  rintro ⟨buf,i⟩ r ⟨hi,ha⟩ hr
  unfold awsvars.extend_loop.body at hr
  simp only [u8vec_clone,bind_tc_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hv1
    have hp := RustfsBytes.push_ok hacc1
    have hadd := add_ok_val hj1
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    rw [hp,ha,show j1.val=i.val+1 by scalar_tac,List.take_add_one,List.getElem?_eq_getElem hlt,he]
    simp [List.append_assoc]
  · simpa only [List.take_of_length_le (by scalar_tac : more.val.length ≤ i.val)] using ha

theorem texts_ok (xs : Slice awsvars.Pending) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : awsvars.texts xs = ok out) : out.val = xs.val.map awsvars.Pending.text := by
  unfold awsvars.texts awsvars.texts_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
      x.2.val ≤ xs.val.length ∧ x.1.val=(xs.val.take x.2.val).map awsvars.Pending.text)
    (fun out => out.val=xs.val.map awsvars.Pending.text) (fun x => xs.val.length-x.2.val)
    ?_ _ out (by simp) h
  rintro ⟨buf,i⟩ r ⟨hi,ha⟩ hr
  unfold awsvars.texts_loop.body at hr
  simp only [u8vec_clone,bind_tc_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hp
    have hpush := RustfsBytes.push_ok hout1
    have hadd := add_ok_val hk1
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    rw [hpush,ha,show k1.val=i.val+1 by scalar_tac,List.take_add_one,List.getElem?_eq_getElem hlt,he]
    simp
  · simpa only [List.take_of_length_le (by scalar_tac : xs.val.length ≤ i.val)] using ha

theorem wrap_ok (pre post : Slice U8) (values : Slice (alloc.vec.Vec U8))
    (offset : Usize) (out : alloc.vec.Vec awsvars.Pending)
    (h : awsvars.wrap_all pre values post offset = ok out) :
    out.val.map pending = WrappedValues pre.val (values.val.map (·.val)) post.val offset.val := by
  unfold awsvars.wrap_all awsvars.wrap_all_loop at h
  let F := fun v : alloc.vec.Vec U8 => (pre.val++v.val++post.val,offset.val+v.val.length)
  simp only [WrappedValues,List.map_map]
  change out.val.map pending = values.val.map F
  refine loop_ok _ (fun x : alloc.vec.Vec awsvars.Pending × Usize =>
      x.2.val ≤ values.val.length ∧ x.1.val.map pending=(values.val.take x.2.val).map F)
    (fun out => out.val.map pending=values.val.map F) (fun x => values.val.length-x.2.val)
    ?_ _ out (by simp) h
  rintro ⟨buf,i⟩ r ⟨hi,ha⟩ hr
  unfold awsvars.wrap_all_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hv
    have h1 := RustfsConditionEval.concat_ok _ _ _ hv1
    have h2 := RustfsConditionEval.concat_ok _ _ _ hv2
    simp only [RustfsForceDelete.deref_val] at h1 h2
    have hpush := RustfsBytes.push_ok hout1
    have hresume := add_ok_val hi3
    have hadd := add_ok_val hi4
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    rw [hpush,List.map_append,ha,show i4.val=i.val+1 by scalar_tac,
      List.take_add_one,List.getElem?_eq_getElem hlt,he,List.map_append]
    simp only [List.map_cons,List.map_nil,List.append_cancel_left_eq,pending,F,List.cons.injEq,Prod.mk.injEq,and_true]
    rw [h2,h1]
    simp only [Option.toList_some,List.map_cons,List.map_nil,List.cons.injEq,Prod.mk.injEq,and_true]
    scalar_tac
  · simpa only [List.take_of_length_le (by scalar_tac : values.val.length ≤ i.val)] using ha
theorem dedup_ok (xs : Slice (alloc.vec.Vec U8)) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : awsvars.dedup xs = ok out) : out.val.map (·.val) = UniqueBytes (xs.val.map (·.val)) := by
  unfold awsvars.dedup awsvars.dedup_loop at h
  let F := fun acc : List (List U8) => fun text => if text ∈ acc then acc else acc++[text]
  change out.val.map (·.val) = (xs.val.map (·.val)).foldl F []
  refine loop_ok _ (fun x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
      x.2.val ≤ xs.val.length ∧ x.1.val.map (·.val)=((xs.val.take x.2.val).map (·.val)).foldl F [])
    (fun out => out.val.map (·.val)=(xs.val.map (·.val)).foldl F [])
    (fun x => xs.val.length-x.2.val) ?_ _ out (by simp) h
  rintro ⟨buf,i⟩ r ⟨hi,ha⟩ hr
  unfold awsvars.dedup_loop.body at hr
  simp only [u8vec_clone,bind_tc_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hx
    have hm := RustfsCondData.member_ok _ _ _ hb
    simp only [RustfsForceDelete.deref_val] at hm
    have hm' : b=true ↔ x.val ∈ buf.val.map (·.val) := by
      rw [hm]
      simp only [List.mem_map]
    have hs : out1.val.map (·.val) = F (buf.val.map (·.val)) x.val := by
      cases b with
      | true =>
        simp only [ite_true,Result.ok.injEq] at hout1
        subst out1
        simp only [F,if_pos (hm'.mp rfl)]
      | false =>
        simp only [Bool.false_eq_true,ite_false] at hout1
        have hp := RustfsBytes.push_ok hout1
        have hn : x.val ∉ buf.val.map (·.val) := fun hh => Bool.false_ne_true (hm'.mpr hh)
        simp only [F,if_neg hn,hp,List.map_append,List.map_cons,List.map_nil]
    have hadd := add_ok_val hi2
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    rw [hs,ha,show i2.val=i.val+1 by scalar_tac,List.take_add_one,
      List.getElem?_eq_getElem hlt,he,List.map_append,List.foldl_append]
    rfl
  · simpa only [List.take_of_length_le (by scalar_tac : xs.val.length ≤ i.val)] using ha
theorem copy_tail_ok (xs : Slice awsvars.Pending) (acc out : alloc.vec.Vec awsvars.Pending)
    (start : Usize) (h : awsvars.splice_loop2 xs acc start = ok out) :
    out.val = acc.val++xs.val.drop start.val := by
  unfold awsvars.splice_loop2 at h
  refine loop_ok _ (fun x : alloc.vec.Vec awsvars.Pending × Usize =>
      x.1.val++xs.val.drop x.2.val=acc.val++xs.val.drop start.val)
    (fun out => out.val=acc.val++xs.val.drop start.val)
    (fun x => xs.val.length-x.2.val) ?_ _ out rfl h
  rintro ⟨buf,k⟩ r hi hr
  unfold awsvars.splice_loop2.body at hr
  simp only [pending_clone_ok,bind_tc_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hp1
    have hpush := RustfsBytes.push_ok hout1
    have hadd := add_ok_val hk21
    refine ⟨?_,by scalar_tac⟩
    rw [List.drop_eq_getElem_cons hlt,he] at hi
    rw [hpush,show k21.val=k.val+1 by scalar_tac]
    simpa only [List.append_assoc,List.singleton_append] using hi
  · rw [List.drop_of_length_le (by scalar_tac),List.append_nil] at hi
    exact hi

theorem copy_prefix_ok (xs : Slice awsvars.Pending) (stop : Usize)
    (out : alloc.vec.Vec awsvars.Pending)
    (h : awsvars.splice_loop0 xs stop (alloc.vec.Vec.new _) 0#usize = ok out) :
    stop.val ≤ xs.val.length ∧ out.val=xs.val.take stop.val := by
  unfold awsvars.splice_loop0 at h
  refine loop_ok _ (fun x : alloc.vec.Vec awsvars.Pending × Usize =>
      x.2.val ≤ stop.val ∧ x.2.val ≤ xs.val.length ∧ x.1.val=xs.val.take x.2.val)
    (fun out => stop.val ≤ xs.val.length ∧ out.val=xs.val.take stop.val)
    (fun x => stop.val-x.2.val) ?_ _ out (by simp) h
  rintro ⟨buf,k⟩ r ⟨hk,hlen,hi⟩ hr
  unfold awsvars.splice_loop0.body at hr
  simp only [pending_clone_ok,bind_tc_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hp1
    have hpush := RustfsBytes.push_ok hout1
    have hadd := add_ok_val hk1
    refine ⟨⟨by scalar_tac,by scalar_tac,?_⟩,by scalar_tac⟩
    rw [hpush,hi,show k1.val=k.val+1 by scalar_tac,List.take_add_one,
      List.getElem?_eq_getElem hlt,he]
    rfl
  · have heq : k.val=stop.val := by scalar_tac
    exact ⟨by scalar_tac,by simpa only [heq] using hi⟩

theorem splice_ok (xs new : Slice awsvars.Pending) (idx : Usize)
    (out : alloc.vec.Vec awsvars.Pending) (h : awsvars.splice xs idx new = ok out) :
    out.val=xs.val.take idx.val++new.val++xs.val.drop (idx.val+1) := by
  unfold awsvars.splice at h
  h5i_invert h
  obtain ⟨hi,hpre⟩ := copy_prefix_ok xs idx out_1 (by assumption)
  have hmid := copy_tail_ok new out_1 out1 0#usize hout1
  have hend := copy_tail_ok xs out1 out k2 h
  have hadd := add_ok_val hk2
  simpa only [show k2.val=idx.val+1 by scalar_tac,hpre,hmid,UScalar.ofNatCore_val_eq,List.drop_zero] using hend
end rustfs_kernel.Verified.RustfsAwsCollections
