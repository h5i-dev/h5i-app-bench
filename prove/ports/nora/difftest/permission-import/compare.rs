#[path=UPSTREAM_PATH] mod upstream;
#[path=PORT_PATH] mod port;
fn name(id:u64)->String { format!("id{id:03}") }
fn verb(v:port::Verb)->upstream::Verb { match v { port::Verb::Read=>upstream::Verb::Read, port::Verb::Write=>upstream::Verb::Write, port::Verb::Admin=>upstream::Verb::Admin } }
fn role(v:port::Verb)->String { match v { port::Verb::Read=>"read",port::Verb::Write=>"write",port::Verb::Admin=>"admin" }.into() }
fn audit(a:port::Audit)->String {
 match a {
 port::Audit::GroupFlattened{group,verb,members}=>format!("group {:?} ({} verb) flattened to {} member(s); group discarded",name(group),role(verb),members),
 port::Audit::AdminNarrowed{user}=>format!("user {:?} admin → write (least privilege; promote manually)",name(user)),
 port::Audit::ScopeWidened{user,role:v}=>format!("user {:?} had per-repo scope → global {} (nra_ tokens cannot be repo-scoped)",name(user),role(v)),
 port::Audit::WriteWithheld{user,role:v}=>format!("user {:?} would get {} — withheld to read (pass --grant-write to propose it)",name(user),role(v)),
 }
}
fn check(ps:&[port::Principal],grant_write:bool){
 let originals:Vec<_>=ps.iter().map(|p|upstream::SourcePrincipal{name:name(p.name),is_group:p.is_group,members:p.members.iter().map(|&x|name(x)).collect(),repos:p.repos.iter().map(|&x|name(x)).collect(),verb:verb(p.verb)}).collect();
 let expected=upstream::map_to_proposal("source",&originals,upstream::PermOpts{grant_write});
 let out=port::map_to_proposal(ps,grant_write);
 let mut warnings=Vec::new();
 if out.warn_oidc {warnings.push("OIDC suggestions require the operator to wire an IdP; they are not mintable tokens.".into());}
 if out.warn_global_write {warnings.push("Proposed non-read tokens grant GLOBAL write across all namespaces (no per-repo scope for nra_ tokens).".into());}
 let actual=upstream::PermissionsReport{
 source:"source".into(),note:"INERT PROPOSAL — no credentials were created. Review and apply manually (ADR-5 file-first).".into(),
 proposed_tokens:out.proposed_tokens.iter().map(|t|upstream::TokenProposal{user:name(t.user),role:role(t.role),provenance:if t.from_group{"imported from source (via group membership)".into()}else{"imported from source".into()}}).collect(),
 oidc_scope_suggestions:out.oidc.iter().map(|o|upstream::OidcSuggestion{identity:name(o.identity),namespace_scope:o.repos.iter().map(|&r|format!("{}/**",name(r))).collect(),role:role(o.role)}).collect(),
 widened:out.widened.into_iter().map(audit).collect(),narrowed:out.narrowed.into_iter().map(audit).collect(),warnings};
 assert_eq!(actual,expected,"principals={ps:?} grant_write={grant_write}");
}
fn next(s:&mut u64)->u64{*s^=*s<<13;*s^=*s>>7;*s^=*s<<17;*s}
fn main(){
 let mut seed=0x431f81295a672be;
 let vs=[port::Verb::Read,port::Verb::Write,port::Verb::Admin];
 let mut cases=0;
 for mask in 0..256 {
  let ps:Vec<_>=(0..4).map(|i|port::Principal{name:i%2,is_group:mask&(1<<i)!=0,members:if mask&(1<<(i+4))!=0{vec![0,1,0]}else{vec![]},repos:if i%2==0{vec![0,1]}else{vec![]},verb:vs[i as usize%3]}).collect();
  for grant in [false,true]{check(&ps,grant);cases+=1;}
 }
 for _ in 0..100000 {
  let len=next(&mut seed)%18;
  let ps:Vec<_>=(0..len).map(|_|{
   let n=next(&mut seed)%7;let is_group=next(&mut seed)&1!=0;let verb=vs[(next(&mut seed)%3) as usize];
   let members=(0..next(&mut seed)%8).map(|_|next(&mut seed)%7).collect();
   let repos=(0..next(&mut seed)%4).map(|_|next(&mut seed)%6).collect();
   port::Principal{name:n,is_group,members,repos,verb}
  }).collect();
  for grant in [false,true]{check(&ps,grant);cases+=1;}
 }
 println!("PASS {cases} complete permission reports (ordered tokens, OIDC scopes, audit events and warnings)");
}
