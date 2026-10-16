import SpecAwsValues
namespace rustfs_kernel.Spec
/-- Identity-policy variables use the parent string as username when present,
and retain all claim lists, flags, and the two environment time strings. -/
def PolicyContext (args : stmts.Args) (env : condfuncs.Env) : AwsValueContext :=
  ⟨nats ((args.claims.parent_str.getD args.account).val),nats args.account.val,
    args.claims.sub.map (fun v=>v.val.map (fun s=>nats s.val)),
    args.claims.parent.map (fun v=>v.val.map (fun s=>nats s.val)),
    args.claims.has_parent,args.claims.has_role_arn,args.claims.has_sa_policy,
    nats env.now_rfc3339.val,nats env.now_epoch.val⟩
end rustfs_kernel.Spec
