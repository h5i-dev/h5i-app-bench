import KanidmKernel
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel
open Aeneas.Std.WP H5iAppLib
namespace kanidm_kernel.Verified.EntryValidation
set_option maxHeartbeats 600000
set_option maxRecDepth 4096

@[simp, step_pre_simps, step_post_simps, scalar_tac_simps]
theorem deref_val {α : Type} (v : alloc.vec.Vec α) : v.deref.val = v.val := by
  simp [alloc.vec.Vec.deref]

@[step] theorem contains_loop_spec (xs : Slice U16) (key : U16) (i : Usize)
    (hi : i.val ≤ xs.length) :
    entry_validation.contains_loop xs key i ⦃ r => r = decide (key ∈ xs.val.drop i.val) ⦄ := by
  unfold entry_validation.contains_loop
  apply loop.spec_decr_nat (measure := fun j => xs.length - j.val)
    (inv := fun j => j.val ≤ xs.length ∧
      (key ∈ xs.val.drop j.val ↔ key ∈ xs.val.drop i.val))
  · intro j hj
    by_cases hlt : j.val < xs.length
    · have hmem : key ∈ xs.val.drop i.val ↔ key = xs.val[j.val] ∨ key ∈ xs.val.drop (j.val+1) := by
        rw [← hj.2, List.drop_eq_getElem_cons hlt]
        simp only [List.mem_cons]
      rcases hj with ⟨hj, _⟩
      h5i_unfold_body
      h5i_steps
      all_goals try simp_all
      all_goals try scalar_tac
    · change ¬j.val < xs.val.length at hlt
      have hnone : ¬key ∈ xs.val.drop i.val := by
        rw [← hj.2, List.drop_eq_nil_iff.mpr (by omega : xs.val.length ≤ j.val)]
        simp
      h5i_unfold_body
      h5i_steps
      all_goals try simp_all
      all_goals try scalar_tac
  · exact ⟨hi, Iff.rfl⟩

@[step] theorem contains_spec (xs : Slice U16) (key : U16) :
    entry_validation.contains xs key ⦃ r => r = decide (key ∈ xs.val) ⦄ := by
  unfold entry_validation.contains
  h5i_steps
  simp_all

@[step] theorem attribute_index_loop_spec (xs : Slice entry_validation.AttributeSchema)
    (key : U16) (i : Usize) (hi : i.val ≤ xs.length) :
    entry_validation.attribute_index_loop xs key i ⦃ r =>
      (∀ j, r = some j → j.val < xs.length) ∧
      r.bind (fun j => xs.val[j.val]?) = (xs.val.drop i.val).find? (fun a => a.key == key) ⦄ := by
  unfold entry_validation.attribute_index_loop
  apply loop.spec_decr_nat (measure := fun j => xs.length - j.val)
    (inv := fun j => j.val ≤ xs.length ∧
      (xs.val.drop j.val).find? (fun a => a.key == key) =
      (xs.val.drop i.val).find? (fun a => a.key == key))
  · intro j hj
    by_cases hlt : j.val < xs.length
    · have hfind : (xs.val.drop i.val).find? (fun a => a.key == key) =
          if xs.val[j.val].key == key then some xs.val[j.val] else
          (xs.val.drop (j.val+1)).find? (fun a => a.key == key) := by
        rw [← hj.2, List.drop_eq_getElem_cons hlt]
        simp only [List.find?_cons]
        split <;> simp_all
      rcases hj with ⟨hj, _⟩
      h5i_unfold_body
      h5i_steps
      all_goals try simp_all
      all_goals try scalar_tac
    · change ¬j.val < xs.val.length at hlt
      have hnone : (xs.val.drop i.val).find? (fun a => a.key == key) = none := by
        rw [← hj.2, List.drop_eq_nil_iff.mpr (by omega : xs.val.length ≤ j.val)]
        simp
      h5i_unfold_body
      h5i_steps
      constructor
      · intro j h; cases h
      · exact hnone.symm
  · exact ⟨hi, rfl⟩

theorem index_isSome (xs : Slice entry_validation.AttributeSchema) (o : Option Usize)
    (hb : ∀ j, o = some j → j.val < xs.length) :
    (o.bind (fun j => xs.val[j.val]?)).isSome = o.isSome := by
  cases o with
  | none => rfl
  | some j => simp [List.getElem?_eq_getElem (hb j rfl)]

@[step] theorem attribute_index_spec (xs : Slice entry_validation.AttributeSchema) (key : U16) :
    entry_validation.attribute_index xs key ⦃ r =>
      (∀ j, r = some j → j.val < xs.length) ∧
      r.bind (fun j => xs.val[j.val]?) = xs.val.find? (fun a => a.key == key) ∧
      r.isSome = (xs.val.find? (fun a => a.key == key)).isSome ⦄ := by
  unfold entry_validation.attribute_index
  apply WP.spec_mono (attribute_index_loop_spec xs key 0#usize (by simp))
  intro r hr
  have hs := congrArg Option.isSome hr.2
  rw [index_isSome xs r hr.1] at hs
  simpa using And.intro hr.1 (And.intro hr.2 hs)
def attributeModel (ava : entry_validation.Attribute)
    (attrs : List entry_validation.AttributeSchema) (may : List U16) (extensible : Bool) :
    core.result.Result Unit entry_validation.Error :=
  if extensible = false ∧ ava.key ∉ may then
    .Err (.AttributeNotValidForClass ava.key)
  else match attrs.find? (fun a => a.key == ava.key) with
    | none => .Err (if extensible then .InvalidAttribute ava.key else .Corrupted)
    | some a =>
      if extensible && a.phantom then .Err (.PhantomAttribute ava.key)
      else if (a.multi = true ∨ ava.count.val ≤ 1) ∧ a.syntax = ava.syntax ∧ ava.valid = true then
        .Ok () else .Err (.InvalidAttributeSyntax ava.key)

@[step] theorem ava_spec (multi : Bool) (count : Usize) (expected actual : U16) (valid : Bool) :
    schema_tags.ava_accepts multi count expected actual valid ⦃ r =>
      r = decide ((multi = true ∨ count.val ≤ 1) ∧ expected = actual ∧ valid = true) ⦄ := by
  cases multi <;> cases valid <;> by_cases hc : count > 1#usize <;> by_cases he : expected = actual <;>
    simp_all [schema_tags.ava_accepts] <;> (try simp_all) <;> (try split) <;> (try simp_all) <;> (try omega)

/-- Complete attribute decision, including first matching schema and error precedence. -/
@[step] theorem validate_attribute_spec (ava : entry_validation.Attribute)
    (attrs : Slice entry_validation.AttributeSchema) (may : Slice U16) (extensible : Bool) :
    entry_validation.validate_attribute ava attrs may extensible ⦃ r =>
      r = attributeModel ava attrs.val may.val extensible ⦄ := by
  unfold entry_validation.validate_attribute
  cases extensible <;> h5i_steps
  all_goals try simp_all [attributeModel]
  all_goals (rw [←o_post1] <;> simp_all)
def attributesModel (avas : List entry_validation.Attribute)
    (attrs : List entry_validation.AttributeSchema) (may : List U16) (extensible : Bool) :
    core.result.Result Unit entry_validation.Error :=
  match avas with
  | [] => .Ok ()
  | a::rest => match attributeModel a attrs may extensible with
      | .Ok () => attributesModel rest attrs may extensible
      | .Err e => .Err e

@[step] theorem validate_attributes_loop_spec (entry : entry_validation.Entry)
    (attrs : Slice entry_validation.AttributeSchema) (may : Slice U16) (extensible : Bool)
    (i : Usize) (hi : i.val ≤ entry.attrs.val.length) :
    entry_validation.validate_attributes_loop entry attrs may extensible i ⦃ r =>
      r = attributesModel (entry.attrs.val.drop i.val) attrs.val may.val extensible ⦄ := by
  unfold entry_validation.validate_attributes_loop
  apply loop.spec_decr_nat (measure := fun j => entry.attrs.val.length - j.val)
    (inv := fun j => j.val ≤ entry.attrs.val.length ∧
      attributesModel (entry.attrs.val.drop j.val) attrs.val may.val extensible =
      attributesModel (entry.attrs.val.drop i.val) attrs.val may.val extensible)
  · intro j hj
    by_cases hlt : j.val < entry.attrs.val.length
    · have hstep : attributesModel (entry.attrs.val.drop i.val) attrs.val may.val extensible =
          match attributeModel entry.attrs.val[j.val] attrs.val may.val extensible with
          | .Ok () => attributesModel (entry.attrs.val.drop (j.val+1)) attrs.val may.val extensible
          | .Err e => .Err e := by
        rw [←hj.2, List.drop_eq_getElem_cons hlt]
        rfl
      rcases hj with ⟨hj,_⟩
      h5i_unfold_body
      h5i_steps
      all_goals cases hm : attributeModel entry.attrs.val[j.val] attrs.val may.val extensible
      all_goals simp only [hm] at *
      all_goals simp_all
      all_goals try scalar_tac
    · have hnone : attributesModel (entry.attrs.val.drop i.val) attrs.val may.val extensible = .Ok () := by
        rw [←hj.2, List.drop_eq_nil_iff.mpr (by omega)]
        rfl
      h5i_unfold_body
      h5i_steps
      all_goals try simp_all
      all_goals try scalar_tac
  · exact ⟨hi,rfl⟩

/-- Every attribute is checked in upstream order, returning the first complete error. -/
@[step] theorem validate_attributes_spec (entry : entry_validation.Entry)
    (attrs : Slice entry_validation.AttributeSchema) (may : Slice U16) (extensible : Bool) :
    entry_validation.validate_attributes entry attrs may extensible ⦃ r =>
      r = attributesModel entry.attrs.val attrs.val may.val extensible ⦄ := by
  unfold entry_validation.validate_attributes
  h5i_steps
  simp_all
def schemaComplete (attrs : List entry_validation.AttributeSchema) (names : List U16) : Bool :=
  names.all (fun key => (attrs.find? (fun a => a.key == key)).isSome)

@[step] theorem schema_complete_loop_spec (attrs : Slice entry_validation.AttributeSchema)
    (names : Slice U16) (i : Usize) (hi : i.val ≤ names.val.length) :
    entry_validation.schema_complete_loop attrs names i ⦃ r =>
      r = schemaComplete attrs.val (names.val.drop i.val) ⦄ := by
  unfold entry_validation.schema_complete_loop
  apply loop.spec_decr_nat (measure := fun j => names.val.length - j.val)
    (inv := fun j => j.val ≤ names.val.length ∧
      schemaComplete attrs.val (names.val.drop j.val) = schemaComplete attrs.val (names.val.drop i.val))
  · intro j hj
    by_cases hlt : j.val < names.val.length
    · have hstep : schemaComplete attrs.val (names.val.drop i.val) =
          ((attrs.val.find? (fun a => a.key == names.val[j.val])).isSome &&
          schemaComplete attrs.val (names.val.drop (j.val+1))) := by
        rw [←hj.2, List.drop_eq_getElem_cons hlt]
        rfl
      rcases hj with ⟨hj,_⟩
      h5i_unfold_body
      h5i_steps
      all_goals try simp_all [Option.isSome_iff_ne_none, Option.isSome_eq_isSome]
      all_goals try scalar_tac
    · have hnone : schemaComplete attrs.val (names.val.drop i.val) = true := by
        rw [←hj.2, List.drop_eq_nil_iff.mpr (by omega)]
        rfl
      h5i_unfold_body
      h5i_steps
      all_goals try simp_all
      all_goals try scalar_tac
  · exact ⟨hi,rfl⟩

@[step] theorem schema_complete_spec (attrs : Slice entry_validation.AttributeSchema) (names : Slice U16) :
    entry_validation.schema_complete attrs names ⦃ r => r = schemaComplete attrs.val names.val ⦄ := by
  unfold entry_validation.schema_complete
  h5i_steps
  simp_all
@[step] theorem append_loop_spec (out : alloc.vec.Vec U16) (xs : Slice U16) (i : Usize)
    (hi : i.val ≤ xs.val.length)
    (hcap : out.val.length + (xs.val.length-i.val) ≤ Usize.max) :
    entry_validation.append_loop out xs i ⦃ r => r.val = out.val ++ xs.val.drop i.val ⦄ := by
  unfold entry_validation.append_loop
  apply loop.spec_decr_nat (measure := fun x => xs.val.length - x.2.val)
    (inv := fun x => x.2.val ≤ xs.val.length ∧
      x.1.val ++ xs.val.drop x.2.val = out.val ++ xs.val.drop i.val ∧
      x.1.val.length + (xs.val.length-x.2.val) ≤ Usize.max)
  · rintro ⟨o,j⟩ ⟨hj,heq,hc⟩
    by_cases hlt : j.val < xs.val.length
    · have hstep : out.val ++ xs.val.drop i.val =
          (o.val ++ [xs.val[j.val]]) ++ xs.val.drop (j.val+1) := by
        rw [←heq, List.drop_eq_getElem_cons hlt]
        simp only [List.append_assoc, List.singleton_append]
      h5i_unfold_body
      h5i_steps
      all_goals try simp_all
      all_goals try scalar_tac
    · have hnone : xs.val.drop j.val = [] := List.drop_eq_nil_iff.mpr (by omega)
      h5i_unfold_body
      h5i_steps
      all_goals try simp_all
      all_goals try scalar_tac
  · exact ⟨hi,rfl,hcap⟩

@[step] theorem append_spec (out : alloc.vec.Vec U16) (xs : Slice U16)
    (hcap : out.val.length + xs.val.length ≤ Usize.max) :
    entry_validation.append out xs ⦃ r => r.val = out.val ++ xs.val ⦄ := by
  unfold entry_validation.append
  h5i_steps
  simp_all
def classModel (c : entry_validation.ClassSchema) (kind : U8) : List U16 :=
  if kind = 0#u8 then c.systemsupplements.val ++ c.supplements.val
  else if kind = 1#u8 then c.systemexcludes.val ++ c.excludes.val
  else c.systemmust.val ++ c.must.val ++
    (if kind = 3#u8 then c.systemmay.val ++ c.may.val else [])

def classWeight (c : entry_validation.ClassSchema) : Nat :=
  c.systemsupplements.val.length + c.supplements.val.length +
  c.systemexcludes.val.length + c.excludes.val.length +
  c.systemmust.val.length + c.must.val.length + c.systemmay.val.length + c.may.val.length

@[step] theorem class_constraints_spec (c : entry_validation.ClassSchema) (kind : U8)
    (hcap : classWeight c ≤ Usize.max) :
    entry_validation.class_constraints c kind ⦃ r => r.val = classModel c kind ⦄ := by
  unfold entry_validation.class_constraints
  unfold classWeight at hcap
  h5i_steps
  all_goals try simp_all [classModel, List.append_assoc]
  all_goals try scalar_tac
@[step] theorem class_index_loop_spec (xs : Slice entry_validation.ClassSchema)
    (key : U16) (i : Usize) (hi : i.val ≤ xs.length) :
    entry_validation.class_index_loop xs key i ⦃ r =>
      (∀ j, r = some j → j.val < xs.length) ∧
      r.bind (fun j => xs.val[j.val]?) = (xs.val.drop i.val).find? (fun a => a.key == key) ⦄ := by
  unfold entry_validation.class_index_loop
  apply loop.spec_decr_nat (measure := fun j => xs.length - j.val)
    (inv := fun j => j.val ≤ xs.length ∧
      (xs.val.drop j.val).find? (fun a => a.key == key) =
      (xs.val.drop i.val).find? (fun a => a.key == key))
  · intro j hj
    by_cases hlt : j.val < xs.length
    · have hfind : (xs.val.drop i.val).find? (fun a => a.key == key) =
          if xs.val[j.val].key == key then some xs.val[j.val] else
          (xs.val.drop (j.val+1)).find? (fun a => a.key == key) := by
        rw [← hj.2, List.drop_eq_getElem_cons hlt]
        simp only [List.find?_cons]
        split <;> simp_all
      rcases hj with ⟨hj, _⟩
      h5i_unfold_body
      h5i_steps
      all_goals try simp_all
      all_goals try scalar_tac
    · change ¬j.val < xs.val.length at hlt
      have hnone : (xs.val.drop i.val).find? (fun a => a.key == key) = none := by
        rw [← hj.2, List.drop_eq_nil_iff.mpr (by omega : xs.val.length ≤ j.val)]
        simp
      h5i_unfold_body
      h5i_steps
      constructor
      · intro j h; cases h
      · exact hnone.symm
  · exact ⟨hi, rfl⟩

theorem classIndex_isSome (xs : Slice entry_validation.ClassSchema) (o : Option Usize)
    (hb : ∀ j, o = some j → j.val < xs.length) :
    (o.bind (fun j => xs.val[j.val]?)).isSome = o.isSome := by
  cases o with
  | none => rfl
  | some j => simp [List.getElem?_eq_getElem (hb j rfl)]

@[step] theorem class_index_spec (xs : Slice entry_validation.ClassSchema) (key : U16) :
    entry_validation.class_index xs key ⦃ r =>
      (∀ j, r = some j → j.val < xs.length) ∧
      r.bind (fun j => xs.val[j.val]?) = xs.val.find? (fun a => a.key == key) ∧
      r.isSome = (xs.val.find? (fun a => a.key == key)).isSome ⦄ := by
  unfold entry_validation.class_index
  apply WP.spec_mono (class_index_loop_spec xs key 0#usize (by simp))
  intro r hr
  have hs := congrArg Option.isSome hr.2
  rw [classIndex_isSome xs r hr.1] at hs
  simpa using And.intro hr.1 (And.intro hr.2 hs)
def invalidClasses (classes : List entry_validation.ClassSchema) (names : List U16) : List U16 :=
  names.filter (fun key => (classes.find? (fun c => c.key == key)).isNone)

@[step] theorem invalid_classes_loop_spec (classes : Slice entry_validation.ClassSchema)
    (names : Slice U16) (out : alloc.vec.Vec U16) (i : Usize)
    (hi : i.val ≤ names.val.length)
    (hcap : out.val.length + (names.val.length-i.val) ≤ Usize.max) :
    entry_validation.invalid_classes_loop classes names out i ⦃ r =>
      r.val = out.val ++ invalidClasses classes.val (names.val.drop i.val) ⦄ := by
  unfold entry_validation.invalid_classes_loop
  apply loop.spec_decr_nat (measure := fun x => names.val.length-x.2.val)
    (inv := fun x => x.2.val ≤ names.val.length ∧
      x.1.val ++ invalidClasses classes.val (names.val.drop x.2.val) =
        out.val ++ invalidClasses classes.val (names.val.drop i.val) ∧
      x.1.val.length + (names.val.length-x.2.val) ≤ Usize.max)
  · rintro ⟨o,j⟩ ⟨hj,heq,hc⟩
    by_cases hlt : j.val < names.val.length
    · have hstep : out.val ++ invalidClasses classes.val (names.val.drop i.val) =
          if (classes.val.find? (fun c => c.key == names.val[j.val])).isNone then
            (o.val ++ [names.val[j.val]]) ++ invalidClasses classes.val (names.val.drop (j.val+1))
          else o.val ++ invalidClasses classes.val (names.val.drop (j.val+1)) := by
        rw [←heq, List.drop_eq_getElem_cons hlt]
        simp only [invalidClasses, List.filter_cons]
        split <;> simp_all [List.append_assoc]
      h5i_unfold_body
      h5i_steps
      all_goals try simp_all [Option.isSome_eq_isSome, Option.isSome_iff_ne_none]
      all_goals try scalar_tac
    · have hnone : names.val.drop j.val = [] := List.drop_eq_nil_iff.mpr (by omega)
      h5i_unfold_body
      h5i_steps
      all_goals try simp_all [invalidClasses]
      all_goals try scalar_tac
  · exact ⟨hi,rfl,hcap⟩

@[step] theorem invalid_classes_spec (classes : Slice entry_validation.ClassSchema) (names : Slice U16) :
    entry_validation.invalid_classes classes names ⦃ r => r.val = invalidClasses classes.val names.val ⦄ := by
  unfold entry_validation.invalid_classes
  have hlen := names.property
  h5i_steps
  simp_all
end kanidm_kernel.Verified.EntryValidation
