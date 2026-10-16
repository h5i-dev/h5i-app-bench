import SpecStringPolicies
import SpecConditionKeys
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
def StringFlags : condfuncs.StrOp → Bool × Bool × Bool
  | .StringEquals | .ArnEquals => (false,false,false)
  | .StringNotEquals | .ArnNotEquals => (false,false,true)
  | .StringEqualsIgnoreCase => (true,false,false)
  | .StringNotEqualsIgnoreCase => (true,false,true)
  | .StringLike | .ArnLike => (false,true,false)
  | .StringNotLike | .ArnNotLike => (false,true,true)
/-- Operator meanings over request lists and numeric address prefixes. IP negation
complements the ordered address decision across all entries. -/
def OperatorHolds (ctx : Option AwsValueContext)
    (values : List (List U8 × List (List U8)))
    (ips : List (List U8 × Option condfuncs.IpAddr)) (q : condfuncs.Quantifier) :
    condfuncs.Cond → Prop
  | .Str op fs => ∀ e ∈ fs.val, StringEntryHolds ctx values e.1 (e.2.val.map (fun v => nats v.val))
      q (StringFlags op).1 (StringFlags op).2.1 (StringFlags op).2.2
  | .Ip neg fs => (if neg then !(AddressConditions ips values (fs.val.map (fun e => (e.1,e.2.val))))
      else AddressConditions ips values (fs.val.map (fun e => (e.1,e.2.val))))=true
  | .Null fs => NullConditions fs.val values
  | .Bool fs => BoolConditions fs.val values
  | .Num op ie fs => NumericConditions op ie values (fs.val.map (fun e => (e.1,e.2.val)))
/-- IfExists accepts immediately when none of the operator's keys is present.
When at least one key is present, the entire operator is evaluated. -/
def ConditionHolds (ctx : Option AwsValueContext)
    (values : List (List U8 × List (List U8)))
    (ips : List (List U8 × Option condfuncs.IpAddr)) (q : condfuncs.Quantifier)
    (c : condfuncs.Condition) : Prop :=
  (c.if_exists=true ∧ ¬OperatorKeyPresent c.cond values) ∨ OperatorHolds ctx values ips q c.cond
/-- All three condition groups must hold, with their respective value quantifiers. -/
def FunctionsHold (ctx : Option AwsValueContext)
    (values : List (List U8 × List (List U8)))
    (ips : List (List U8 × Option condfuncs.IpAddr)) (f : condfuncs.Functions) : Prop :=
  (∀ c ∈ f.for_any_value.val, ConditionHolds ctx values ips .ForAnyValue c) ∧
  (∀ c ∈ f.for_all_values.val, ConditionHolds ctx values ips .ForAllValues c) ∧
  (∀ c ∈ f.for_normal.val, ConditionHolds ctx values ips .None c)
end rustfs_kernel.Spec
