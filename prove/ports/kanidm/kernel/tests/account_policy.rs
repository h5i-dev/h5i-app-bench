#[path="../../difftest/account_policy/reference.rs"] mod reference;
use kanidm_kernel::account_policy::{self,Policy};
fn next(seed:&mut u64)->u64 {*seed=seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);*seed}
#[test]
fn pinned_policy_resolution() {
 let mut seed=0x4b616e69646d_u64;
 let mut comparisons=0;
 for len in 0..40 { for _ in 0..500 {
  let mut policies=Vec::new(); let mut masks=Vec::new();
  for _ in 0..len {
   let mut p=account_policy::initial();
   p.privilege_expiry=next(&mut seed) as u32;
   p.authsession_expiry=next(&mut seed) as u32;
   p.pw_min_length=(next(&mut seed)%200) as u32;
   p.credential_policy=[0,5,10,20,30,40,u16::MAX][(next(&mut seed)%7) as usize];
   p.limit_search_max_results=if next(&mut seed)%3==0 {None} else {Some(next(&mut seed))};
   p.limit_search_max_filter_test=if next(&mut seed)%3==0 {None} else {Some(next(&mut seed))};
   p.allow_primary_cred_fallback=match next(&mut seed)%3 {0=>None,1=>Some(false),_=>Some(true)};
   masks.push(if next(&mut seed)%3==0 {None} else {Some(next(&mut seed))});
   policies.push(p);
  }
  assert_eq!(account_policy::fold_from(&policies),reference::fold(&policies,&masks)); comparisons+=1;
 }}
 for rank in [0,5,10,20,30,40,u16::MAX] {for length in [0,9,10,14,15,16,u32::MAX] {
  let p=Policy {credential_policy:rank,pw_min_length:length,..account_policy::initial()};
  assert_eq!(account_policy::fold_from(&[p]),reference::fold(&[p],&[None]));comparisons+=1;
 }}
 println!("{comparisons} full scalar-resolution comparisons with independent CA masks");
}
