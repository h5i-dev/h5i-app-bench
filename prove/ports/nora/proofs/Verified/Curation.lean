import NoraKernel
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel H5iAppLib
namespace nora_kernel.Verified.Curation
set_option maxHeartbeats 1000000

def isOff : curation.Mode → Bool | .Off => true | _ => false
def isAudit : curation.Mode → Bool | .Audit => true | _ => false
def decisive (f : curation.Filter) : Bool :=
  match f.decision with | .Skip => false | _ => true
def fallback : curation.Evaluation := ⟨.Allow, none, false, .Allowed, false⟩
def selected (mode : curation.Mode) (f : curation.Filter) : curation.Evaluation :=
  match f.decision with
  | .Allow => ⟨.Allow, some f.name, false, .Allowed, false⟩
  | .Block rule reason integrity =>
      ⟨.Block rule reason integrity, some f.name, isAudit mode,
        if isAudit mode then .Allowed else .Blocked, false⟩
  | .Skip => fallback
/-- The first decisive filter controls the payload, attribution, audit bit and counters. -/
def chain (mode : curation.Mode) (filters : List curation.Filter) : curation.Evaluation :=
  ((filters.find? decisive).map (selected mode)).getD fallback

def inflate (r : curation.Decision × Option U64 × Bool × curation.Effect) : curation.Evaluation :=
  ⟨r.1, r.2.1, r.2.2.1, r.2.2.2, false⟩

@[step] theorem chain_loop_spec (mode : curation.Mode) (filters : Slice curation.Filter) :
    curation.evaluate_chain_loop mode filters 0#usize ⦃ r => inflate r = chain mode filters.val ⦄ := by
  unfold curation.evaluate_chain_loop
  apply WP.spec_mono (loop_search filters.val decisive inflate (fun _ f => selected mode f)
    fallback _ ?_ 0#usize (by simp))
  · intro r hr
    simpa [chain, searchFrom_findD] using hr
  · intro i hi
    unfold curation.evaluate_chain_loop.body
    h5i_steps
    all_goals simp_all [SearchStep, decisive, selected, fallback, isAudit, inflate]
    all_goals scalar_tac

@[step] theorem chain_spec (mode : curation.Mode) (filters : Slice curation.Filter) :
    curation.evaluate_chain mode filters ⦃ r => r = chain mode filters.val ⦄ := by
  unfold curation.evaluate_chain
  h5i_steps
  all_goals simp_all [inflate]

def namespaceBlock (ns : Option curation.Filter) : Option curation.Evaluation :=
  match ns with
  | some f => match f.decision with
      | .Block rule reason integrity => some ⟨.Block rule reason integrity, some f.name,
          false, .Blocked, false⟩
      | _ => none
  | none => none

def inner (mode : curation.Mode) (ns : Option curation.Filter) (filters : List curation.Filter)
    (bypass integrity : Bool) (bypassName : U64) : curation.Evaluation :=
  match namespaceBlock ns with
  | some r => r
  | none =>
      if isOff mode then ⟨.Allow, none, false, .None, false⟩ else
      if bypass then ⟨.Allow, some bypassName, false, .Allowed, false⟩ else
      { chain mode filters with without_integrity := !integrity }

@[step] theorem inner_spec (mode : curation.Mode) (ns : Option curation.Filter)
    (filters : Slice curation.Filter) (bypass integrity : Bool) (bypassName : U64) :
    curation.evaluate_inner mode ns filters bypass integrity bypassName ⦃ r =>
      r = inner mode ns filters.val bypass integrity bypassName ⦄ := by
  unfold curation.evaluate_inner
  cases ns with
  | none =>
      cases mode <;> h5i_steps <;> simp_all [inner, namespaceBlock, isOff]
  | some f =>
      cases hd : f.decision <;> cases mode <;> h5i_steps <;>
        simp_all [inner, namespaceBlock, isOff]

def label (r : curation.Evaluation) : U8 :=
  match r.decision with
  | .Allow => 0#u8
  | .Skip => 3#u8
  | .Block .. => if r.audited then 1#u8 else 2#u8

@[step] theorem evaluate_spec (mode : curation.Mode) (ns : Option curation.Filter)
    (filters : Slice curation.Filter) (bypass integrity : Bool) (bypassName : U64) :
    curation.evaluate mode ns filters bypass integrity bypassName ⦃ r =>
      let expected := inner mode ns filters.val bypass integrity bypassName
      r = (expected, label expected) ⦄ := by
  unfold curation.evaluate
  h5i_steps
  all_goals simp_all [label]

@[step] theorem active_spec (mode : curation.Mode) :
    curation.is_active mode ⦃ r => r = !isOff mode ⦄ := by
  unfold curation.is_active
  cases mode <;> h5i_steps <;> rfl

def response (r : curation.Evaluation) : Option (U64 × U64) :=
  match r.decision with
  | .Block rule reason _ => if r.audited then none else some (rule, reason)
  | _ => none

@[step] theorem response_spec (r : curation.Evaluation) :
    curation.download_response r ⦃ x => x = response r ⦄ := by
  unfold curation.download_response
  cases hd : r.decision <;> h5i_steps <;> simp_all [response]

def integrityResponse (r : curation.Evaluation) : Option (U64 × U64) :=
  match r.decision with
  | .Block rule reason integrity => if integrity && !r.audited then some (rule, reason) else none
  | _ => none

@[step] theorem integrity_response_spec (r : curation.Evaluation) :
    curation.integrity_response r ⦃ x => x = integrityResponse r ⦄ := by
  unfold curation.integrity_response
  cases hd : r.decision <;> h5i_steps <;> simp_all [integrityResponse]

theorem namespace_spec (ns : Option curation.Filter) :
    curation.check_namespace_isolation ns ⦃ r =>
      r = match namespaceBlock ns with
      | some e => (response e, curation.Effect.Blocked)
      | none => (none, curation.Effect.None) ⦄ := by
  unfold curation.check_namespace_isolation
  cases ns with
  | none => simp only [namespaceBlock]; h5i_steps
  | some f =>
      cases hd : f.decision <;> simp only [namespaceBlock, hd, response]
      all_goals h5i_steps <;> simp_all

theorem internal_spec (ns : Option curation.Filter) :
    curation.is_internal_namespace ns ⦃ r => r = (namespaceBlock ns).isSome ⦄ := by
  unfold curation.is_internal_namespace
  cases ns with
  | none => h5i_steps; rfl
  | some f => cases hd : f.decision <;> h5i_steps <;> simp_all [namespaceBlock]

theorem namespace_active_spec (ns : Option curation.Filter) :
    curation.namespace_filter_active ns ⦃ r => r = ns.isSome ⦄ := by
  unfold curation.namespace_filter_active
  cases ns <;> h5i_steps


def tokenMatches (configured header : Option U64) : Bool :=
  match configured, header with
  | some a, some b => decide (a.val = b.val)
  | _, _ => false

theorem download_spec (mode : curation.Mode) (ns : Option curation.Filter)
    (filters : Slice curation.Filter) (configured header : Option U64) (bypassName : U64) :
    curation.check_download mode ns filters configured header bypassName ⦃ r =>
      r = response (inner mode ns filters.val (tokenMatches configured header) false bypassName) ⦄ := by
  unfold curation.check_download
  cases configured <;> cases header <;> h5i_steps
  all_goals simp_all [tokenMatches, UScalar.eq_equiv, eq_comm]

def integrityModel (mode : curation.Mode) (ns : Option curation.Filter)
    (filters : List curation.Filter) (bypassName : U64) : Option (U64 × U64) :=
  if isOff mode then none else integrityResponse (inner mode ns filters false true bypassName)

theorem verify_spec (mode : curation.Mode) (ns : Option curation.Filter)
    (filters : Slice curation.Filter) (bypassName : U64) :
    curation.verify_integrity mode ns filters bypassName ⦃ r =>
      r = integrityModel mode ns filters.val bypassName ⦄ := by
  unfold curation.verify_integrity
  h5i_steps
  all_goals simp_all [integrityModel]

theorem verify_hash_spec (mode : curation.Mode) (ns : Option curation.Filter)
    (filters : Slice curation.Filter) (bypassName : U64) (valid : Bool) (hv : valid = true) :
    curation.verify_integrity_by_hash mode ns filters bypassName valid ⦃ r =>
      r = integrityModel mode ns filters.val bypassName ⦄ := by
  unfold curation.verify_integrity_by_hash
  h5i_steps
  all_goals simp_all [integrityModel]

end nora_kernel.Verified.Curation
