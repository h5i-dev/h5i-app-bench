import Verified.RustfsIpLookup
import Verified.RustfsIpNetworks
import Verified.RustfsOperatorLookup
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsIpDecision
set_option maxHeartbeats 2000000

theorem key_ok (requests : Slice (alloc.vec.Vec U8))
    (networks : Slice (condfuncs.IpAddr × U8)) (env : condfuncs.Env) (out : Option Bool)
    (h : condfuncs.addr_key requests networks env = ok out) :
    out = AddressDecision (env.ips.val.map (fun e => (e.1.val,e.2)))
      networks.val (requests.val.map (·.val)) := by
  unfold condfuncs.addr_key condfuncs.addr_key_loop at h
  refine loop_ok _ (fun i : Usize => i.val ≤ requests.val.length ∧
      AddressDecision (env.ips.val.map (fun e => (e.1.val,e.2))) networks.val
        ((requests.val.drop i.val).map (·.val)) =
      AddressDecision (env.ips.val.map (fun e => (e.1.val,e.2))) networks.val
        (requests.val.map (·.val)))
    (fun out => out = AddressDecision (env.ips.val.map (fun e => (e.1.val,e.2)))
      networks.val (requests.val.map (·.val)))
    (fun i => requests.val.length-i.val) ?_ _ out (by simp) h
  · intro i result ⟨hi,he⟩ hr
    unfold condfuncs.addr_key_loop.body at hr
    h5i_invert hr
    all_goals
      try
        have hn : requests.val.length ≤ i.val := by scalar_tac
        rw [List.drop_of_length_le hn] at he
        simpa only [List.map_nil,AddressDecision] using he
    all_goals
      obtain ⟨hlt,hv'⟩ := slice_index_ok hv
      have hdrop : requests.val.drop i.val = v :: requests.val.drop (i.val+1) := by
        rw [List.drop_eq_getElem_cons hlt,hv']
      rw [hdrop,List.map_cons,AddressDecision] at he
      have hp := RustfsIpLookup.parse_ip_ok env _ _ ho
      simp only [RustfsForceDelete.deref_val] at hp
    · rw [← hp] at he
      exact he
    · have hm := (RustfsIpNetworks.any_net_ok networks ip b hb).mp hc_1
      rw [← hp] at he
      simp only [if_pos hm] at he
      exact he
    · have hm : ¬AnyNetwork networks.val ip := by
        intro hh
        exact hc_1 ((RustfsIpNetworks.any_net_ok networks ip b hb).mpr hh)
      rw [← hp] at he
      simp only [if_neg hm] at he
      have hadd : i2.val = i.val+1 := by have := add_ok_val hi2; scalar_tac
      refine ⟨⟨by omega,?_⟩,by omega⟩
      simpa only [hadd] using he

theorem conditions_ok (funcs : Slice (condfuncs.Key × alloc.vec.Vec (condfuncs.IpAddr × U8)))
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (env : condfuncs.Env) (b : Bool) (h : condfuncs.addr_func funcs values env = ok b) :
    b = AddressConditions (env.ips.val.map (fun e => (e.1.val,e.2)))
      (RequestValueLists values.val) (funcs.val.map (fun e => (e.1,e.2.val))) := by
  unfold condfuncs.addr_func condfuncs.addr_func_loop at h
  let P := fun es : List (condfuncs.Key × alloc.vec.Vec (condfuncs.IpAddr × U8)) =>
    AddressConditions (env.ips.val.map (fun e => (e.1.val,e.2)))
      (RequestValueLists values.val) (es.map (fun e => (e.1,e.2.val)))
  change b = P funcs.val
  refine loop_ok _ (fun i : Usize => i.val ≤ funcs.val.length ∧ P (funcs.val.drop i.val) = P funcs.val)
    (fun b => b = P funcs.val) (fun i => funcs.val.length-i.val) ?_ _ b (by simp) h
  intro i result ⟨hi,he⟩ hr
  unfold condfuncs.addr_func_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨key,networks⟩
    change (do
      let n ← condfuncs.key_lookup_name key
      let o ← condfuncs.get_value values n.deref
      let requests ← match o with
        | none => ok (alloc.vec.Vec.new (alloc.vec.Vec U8))
        | some v => ok v
      let answer ← condfuncs.addr_key requests.deref networks.deref env
      match answer with
      | none => do
        let next ← i+1#usize
        ok (ControlFlow.cont next)
      | some b => ok (ControlFlow.done b)) = ok result at hr
    obtain ⟨hlt,hx'⟩ := slice_index_ok hx
    have hd : funcs.val.drop i.val = (key,networks) :: funcs.val.drop (i.val+1) := by
      rw [List.drop_eq_getElem_cons hlt,hx']
    change AddressConditions _ _ ((funcs.val.drop i.val).map _) = P funcs.val at he
    rw [hd,List.map_cons,AddressConditions] at he
    h5i_invert hr
    all_goals
      have hn' := RustfsConditionEval.lookup_name_ok key n hn
      have hl := RustfsOperatorLookup.lookup_ok values _ _ ho
      simp only [RustfsForceDelete.deref_val, hn'] at hl
      have hreq : requests.val.map (·.val) =
          ((ConditionValues (RequestValueLists values.val) (LookupName key)).getD []) := by
        rw [← hl]
        cases o with
        | none => simp only [Option.map_none,Option.getD_none] at *
                  h5i_invert hrequests
                  rfl
        | some v => simp only [Option.map_some,Option.getD_some] at *
                    h5i_invert hrequests
                    rfl
      have hk := key_ok _ _ _ _ hanswer
      simp only [RustfsForceDelete.deref_val,hreq] at hk
      rw [← hk] at he
    · have hadd : next.val = i.val+1 := by have := add_ok_val hnext; scalar_tac
      refine ⟨⟨by omega,?_⟩,by omega⟩
      simpa only [hadd] using he
    · exact he
  · have hn : funcs.val.length ≤ i.val := by scalar_tac
    rw [List.drop_of_length_le hn] at he
    exact he

end rustfs_kernel.Verified.RustfsIpDecision
