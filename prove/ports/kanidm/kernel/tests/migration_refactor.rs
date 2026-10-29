#[path="../../difftest/migration_before_refactor.rs"] mod before;
#[test]
fn all_class_combinations_preserve_exact_vectors(){
 let keys:[&[u8];6]=[b"domain_info",b"group",b"person",b"service_account",b"account_policy",b"oauth2_resource_server"];
 for mask in 0..64 {let classes:Vec<Vec<u8>>=keys.iter().enumerate().filter(|(i,_)|mask&(1<<i)!=0).map(|(_,x)|x.to_vec()).collect();
  assert_eq!(kanidm_kernel::migration::migration_entry_attrs(&classes),before::migration_entry_attrs(&classes));
 }
 println!("64 exhaustive class predicates preserve complete ordered attribute/class vectors");
}
