import SpecVariables
import Verified.RustfsClaimLookup
import Verified.RustfsBytes
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Verified.RustfsVariableScalars

theorem clone_ok (v o : Option (alloc.vec.Vec U8))
    (h : varctx.clone_option v = ok o) : o = v := by
  unfold varctx.clone_option at h
  cases v <;> simp only [u8vec_clone] at h <;> h5i_invert h
  all_goals rfl

theorem username_ok (r : varctx.VariableResolver) (o : Option (alloc.vec.Vec U8))
    (h : varctx.resolve_username r = ok o) : o = r.context.username := clone_ok _ _ h

theorem account_ok (r : varctx.VariableResolver) (o : Option (alloc.vec.Vec U8))
    (h : varctx.resolve_account_id r = ok o) : o = r.context.account_id := clone_ok _ _ h

theorem region_ok (r : varctx.VariableResolver) (o : Option (alloc.vec.Vec U8))
    (h : varctx.resolve_region r = ok o) : o = r.context.region := clone_ok _ _ h

theorem source_ok (r : varctx.VariableResolver) (o : Option (alloc.vec.Vec U8))
    (h : varctx.resolve_source_ip r = ok o) : o = r.context.source_ip := clone_ok _ _ h

theorem scalar_ok (v : claims.Value) (o : Option (alloc.vec.Vec U8))
    (h : varctx.scalar_string v = ok o) : o.map (fun s => nats s.val) = VariableScalar v := by
  unfold varctx.scalar_string at h
  cases v <;> simp only [u8vec_clone] at h <;> h5i_invert h
  case Null | Number | String | Array | Object => rfl
  case isTrue =>
    simp only [Option.map_some,VariableScalar,hc,ite_true,Option.some.injEq]
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ hv]
    rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]
    decide +kernel
  case isFalse =>
    simp only [Option.map_some,VariableScalar,hc,ite_false,Option.some.injEq]
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ hv]
    rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]
    decide +kernel
theorem array_ok (array : Slice claims.Value) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : varctx.array_strings array = ok out) :
    out.val.map (fun s => nats s.val) = array.val.filterMap VariableScalar := by
  unfold varctx.array_strings varctx.array_strings_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
    x.2.val ≤ array.val.length ∧
    x.1.val.map (fun s => nats s.val) = (array.val.take x.2.val).filterMap VariableScalar)
    (fun out => out.val.map (fun s => nats s.val) = array.val.filterMap VariableScalar)
    (fun x => array.val.length-x.2.val) ?_ _ out (by simp) h
  rintro ⟨out,i⟩ r ⟨hi,ho⟩ hr
  unfold varctx.array_strings_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hv
    have hs := scalar_ok v o ho_1
    have hadd := add_ok_val hj1
    have hj : j1.val = i.val+1 := by scalar_tac
    have ht : array.val.take j1.val = array.val.take i.val ++ [v] := by
      rw [hj,List.take_add_one,List.getElem?_eq_getElem hlt,he]
      rfl
    cases o with
    | none =>
      h5i_invert hstrings1
      refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
      rw [ht,List.filterMap_append,← ho]
      simp only [List.filterMap_cons,List.filterMap_nil,← hs]
      simp
    | some s =>
      h5i_invert hstrings1
      have hp := rustfs_kernel.Verified.RustfsBytes.push_ok hstrings1
      refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
      rw [hp,List.map_append,ht,List.filterMap_append,← ho]
      simp only [List.filterMap_cons,List.filterMap_nil,← hs]
      rfl
  · have hle : array.val.length ≤ i.val := by scalar_tac
    simpa only [List.take_of_length_le hle] using ho
theorem first_value (table : List (alloc.vec.Vec U8 × claims.Value)) (needle : List U8)
    (i : Nat) (hi : FirstNamedClaim table needle i) :
    NamedClaimValue table (nats needle) = some (table[i]'hi.1).2 := by
  rcases hi with ⟨hlt,he,hfirst⟩
  have hf : table.find? (fun e => decide (nats e.1.val = nats needle)) = some table[i] := by
    apply List.find?_eq_some_iff_append.mpr
    refine ⟨by simpa using congrArg nats he,table.take i,table.drop (i+1),?_,?_⟩
    · rw [← List.drop_eq_getElem_cons hlt]
      exact (List.take_append_drop i table).symm
    · intro e hm
      obtain ⟨j,hj,heq⟩ := List.mem_take_iff_getElem.mp hm
      have hji : j < i := lt_of_lt_of_le hj (Nat.min_le_left _ _)
      have hne := hfirst j hji
      have hn : nats table[j].1.val ≠ nats needle :=
        fun he => hne (rustfs_kernel.Verified.RustfsForceDelete.nats_inj he)
      simp [← heq,hn]
  simp only [NamedClaimValue,hf,Option.map_some]

theorem context_empty (c : varctx.VariableContext) (h : varctx.context_new = ok c) :
    c.is_https = false ∧ c.source_ip = none ∧ c.account_id = none ∧ c.region = none ∧
    c.username = none ∧ c.claims = none ∧ c.conditions.val = [] ∧ c.custom_variables.val = [] := by
  unfold varctx.context_new at h
  h5i_invert h
  decide +kernel

theorem resolver_context (c : varctx.VariableContext) (r : varctx.VariableResolver)
    (h : varctx.resolver_new c = ok r) : r.context = c := by
  unfold varctx.resolver_new at h
  h5i_invert h
  rfl

theorem secure_ok (r : varctx.VariableResolver) (v : alloc.vec.Vec U8)
    (h : varctx.resolve_secure_transport r = ok v) :
    nats v.val = if r.context.is_https then lit "true" else lit "false" := by
  unfold varctx.resolve_secure_transport at h
  h5i_invert h
  all_goals
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]
    simp only [hc,ite_true,ite_false]
    decide +kernel

theorem claim_strings_ok (r : varctx.VariableResolver) (needle : Slice U8)
    (o : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (h : varctx.get_claim_as_strings r needle = ok o) :
    o.map (fun vs => vs.val.map (fun v => nats v.val)) = ResolverStrings r (nats needle.val) := by
  unfold varctx.get_claim_as_strings at h
  cases hctx : r.context.claims with
  | none =>
    simp only [hctx] at h
    h5i_invert h
    simp [ResolverStrings,hctx]
  | some table =>
    simp only [hctx] at h
    h5i_invert h
    · have hn := rustfs_kernel.Verified.RustfsClaimLookup.find_ok table needle none ho_1
      change ∀ e ∈ table.val, e.1.val ≠ needle.val at hn
      have hnv : NamedClaimValue table.val (nats needle.val) = none := by
        have hn1 : table.val.find? (fun e => decide (nats e.1.val = nats needle.val)) = none :=
          List.find?_eq_none.mpr (by
            intro e he
            have hne : nats e.1.val ≠ nats needle.val :=
              fun hh => hn e he (rustfs_kernel.Verified.RustfsForceDelete.nats_inj hh)
            simpa using hne)
        simp only [NamedClaimValue,hn1,Option.map_none]
      simp only [ResolverStrings,hctx,Option.bind_some,hnv,Option.bind_none,Option.map_none]
    · obtain ⟨hlt,he⟩ := vec_index_ok hx
      have hf := rustfs_kernel.Verified.RustfsClaimLookup.find_ok table needle (some val) ho_1
      have hnv := first_value table.val needle.val val.val hf
      rw [he] at hnv
      rcases x with ⟨key,value⟩
      simp only [ResolverStrings,hctx,Option.bind_some,hnv]
      change (match (generalizing := false) value with
        | .Null => do
          let s ← varctx.scalar_string .Null
          match s with
          | none => ok none
          | some s => do
            let vs ← alloc.vec.Vec.push (alloc.vec.Vec.new (alloc.vec.Vec U8)) s
            ok (some vs)
        | .Bool _ => do
          let s ← varctx.scalar_string value
          match s with
          | none => ok none
          | some s => do
            let vs ← alloc.vec.Vec.push (alloc.vec.Vec.new (alloc.vec.Vec U8)) s
            ok (some vs)
        | .Number _ => do
          let s ← varctx.scalar_string value
          match s with
          | none => ok none
          | some s => do
            let vs ← alloc.vec.Vec.push (alloc.vec.Vec.new (alloc.vec.Vec U8)) s
            ok (some vs)
        | .String _ => do
          let s ← varctx.scalar_string value
          match s with
          | none => ok none
          | some s => do
            let vs ← alloc.vec.Vec.push (alloc.vec.Vec.new (alloc.vec.Vec U8)) s
            ok (some vs)
        | .Array array => do
          let vs ← varctx.array_strings array.deref
          ok (some vs)
        | .Object _ => do
          let s ← varctx.scalar_string value
          match s with
          | none => ok none
          | some s => do
            let vs ← alloc.vec.Vec.push (alloc.vec.Vec.new (alloc.vec.Vec U8)) s
            ok (some vs)) = ok o at h
      cases value <;> h5i_invert h
      case Array =>
        have ha := array_ok _ _ hvs
        rw [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at ha
        exact congrArg some ha
      all_goals
        have hh := congrArg (Option.map (fun s : List Nat => [s])) (scalar_ok _ _ hs)
      all_goals first
        | exact hh
        | simp only [Option.map_some]
          rw [rustfs_kernel.Verified.RustfsBytes.push_ok hvs]
          exact hh
end rustfs_kernel.Verified.RustfsVariableScalars
