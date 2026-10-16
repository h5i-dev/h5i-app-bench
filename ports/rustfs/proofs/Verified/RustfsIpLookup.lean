import SpecOperators
import Verified.RustfsConditionEval
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (bytes_eq_ok deref_val)
namespace rustfs_kernel.Verified.RustfsIpLookup

theorem parse_ip_ok (env : condfuncs.Env) (text : Slice U8) (out : Option condfuncs.IpAddr)
    (h : condfuncs.parse_ip env text = ok out) :
    out = ParsedAddress (env.ips.val.map (fun e => (e.1.val,e.2))) text.val := by
  unfold condfuncs.parse_ip condfuncs.parse_ip_loop at h
  let P := fun es : List (alloc.vec.Vec U8 × Option condfuncs.IpAddr) =>
    ParsedAddress (es.map (fun e => (e.1.val,e.2))) text.val
  change out = P env.ips.val
  refine loop_ok _ (fun i : Usize => i.val ≤ env.ips.val.length ∧
      P env.ips.val = P (env.ips.val.drop i.val))
    (fun o => o = P env.ips.val) (fun i => env.ips.val.length - i.val)
    ?_ _ out ⟨by simp,by simp⟩ h
  rintro i r ⟨hi,hm⟩ hr
  unfold condfuncs.parse_ip_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨keyBytes,parsed⟩
    obtain ⟨hlt,he⟩ := vec_index_ok hx
    change (do
      let equal ← bytes.eq keyBytes.deref text
      if equal then ok (ControlFlow.done parsed)
      else let next ← i + 1#usize
           ok (ControlFlow.cont next)) = ok r at hr
    h5i_invert hr
    · have hb := (bytes_eq_ok _ _ _ hequal).1 hc_1
      simp only [deref_val] at hb
      rw [hm,List.drop_eq_getElem_cons hlt,he]
      simp [P,ParsedAddress,hb]
    · have hn : keyBytes.val ≠ text.val := by
        intro hh; exact hc_1 ((bytes_eq_ok _ _ _ hequal).2 (by simpa [deref_val] using hh))
      have ha := add_ok_val hnext
      refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
      rw [hm,List.drop_eq_getElem_cons hlt,he]
      simp only [P,List.map_cons,ParsedAddress,List.find?_cons,hn,decide_false,
        Bool.false_eq_true,ite_false]
      congr 4
      scalar_tac
  · rw [hm,List.drop_of_length_le (by scalar_tac)]
    rfl
end rustfs_kernel.Verified.RustfsIpLookup
