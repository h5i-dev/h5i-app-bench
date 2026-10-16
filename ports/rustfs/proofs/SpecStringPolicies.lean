import SpecCommonSubstitution
import SpecAwsResolution
import SpecOperators
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
/-- Resolve context variables before common-key substitution. Without a context,
the policy text supplies its sole alternative. -/
def ResolvedPolicy (ctx : Option AwsValueContext) (text : List Nat) : List (List Nat) :=
  match ctx with | none => [text] | some c => ExpandVariables c 0 text
/-- String candidates use the first eligible common-key replacement and then
ASCII lowercase conversion when requested. Alternative order is retained. -/
def PolicyValueTransform (values : List (List U8 × List (List U8)))
    (ignoreCase : Bool) (text : List Nat) : List Nat :=
  let replaced := nats (SubstituteFirstCommon (BytesOfNats text) values)
  if ignoreCase then replaced.map asciiLower else replaced

def PolicyCandidates (ctx : Option AwsValueContext) (values : List (List U8 × List (List U8)))
    (ignoreCase : Bool) (policy : List (List Nat)) : List (List Nat) :=
  (policy.flatMap (ResolvedPolicy ctx)).map (PolicyValueTransform values ignoreCase)
/-- Missing request keys supply an empty value list. Universal matching accepts
that list; existential matching rejects it. -/
def StringEqualityEval (ctx : Option AwsValueContext)
    (values : List (List U8 × List (List U8))) (key : condfuncs.Key)
    (policy : List (List Nat)) (q : condfuncs.Quantifier) (ignoreCase negate : Bool) : Bool :=
  EqualityDecision q ignoreCase negate (PolicyCandidates ctx values ignoreCase policy)
    (((ConditionValues values (LookupName key)).getD []).map nats)
def StringLikeEval (ctx : Option AwsValueContext)
    (values : List (List U8 × List (List U8))) (key : condfuncs.Key)
    (policy : List (List Nat)) (q : condfuncs.Quantifier) (negate : Bool) : Prop :=
  QuantifiedLike q negate ((PolicyCandidates ctx values false policy).map BytesOfNats)
    ((ConditionValues values (LookupName key)).getD [])
/-- Unquantified negation complements the whole existential result. Quantified
negation applies within each request-value comparison. -/
def StringEntryHolds (ctx : Option AwsValueContext)
    (values : List (List U8 × List (List U8))) (key : condfuncs.Key)
    (policy : List (List Nat)) (q : condfuncs.Quantifier) (ignoreCase like negate : Bool) : Prop :=
  let innerNeg := match q with | .None => false | _ => negate
  let matched := if like then StringLikeEval ctx values key policy q innerNeg
    else StringEqualityEval ctx values key policy q ignoreCase innerNeg=true
  match q with | .None => if negate then ¬matched else matched | _ => matched
end rustfs_kernel.Spec
