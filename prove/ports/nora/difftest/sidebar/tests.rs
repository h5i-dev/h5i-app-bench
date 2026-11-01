#![allow(dead_code)]
#[path="../../kernel/src/sidebar.rs"] mod kernel;
include!("reference.rs");
fn decode(out: kernel::Output) -> Vec<u8> { let mut bytes=Vec::new();
for piece in out.frame_0 { bytes.extend(piece); }
for piece in out.row_0 { bytes.extend(piece); }
for piece in out.frame_1 { bytes.extend(piece); }
for piece in out.registry_heading { bytes.extend(piece); }
for piece in out.row_1 { bytes.extend(piece); }
for piece in out.row_2 { bytes.extend(piece); }
for piece in out.row_3 { bytes.extend(piece); }
for piece in out.row_4 { bytes.extend(piece); }
for piece in out.row_5 { bytes.extend(piece); }
for piece in out.row_6 { bytes.extend(piece); }
for piece in out.row_7 { bytes.extend(piece); }
for piece in out.row_8 { bytes.extend(piece); }
for piece in out.row_9 { bytes.extend(piece); }
for piece in out.row_10 { bytes.extend(piece); }
for piece in out.row_11 { bytes.extend(piece); }
for piece in out.row_12 { bytes.extend(piece); }
for piece in out.row_13 { bytes.extend(piece); }
for piece in out.row_14 { bytes.extend(piece); }
for piece in out.row_15 { bytes.extend(piece); }
for piece in out.row_16 { bytes.extend(piece); }
for piece in out.registry_tail { bytes.extend(piece); }
for piece in out.frame_2 { bytes.extend(piece); }
for piece in out.admin { bytes.extend(piece); }
for piece in out.frame_3 { bytes.extend(piece); }
bytes.extend(out.version);
for piece in out.frame_4 { bytes.extend(piece); }
bytes }
fn compare(active: Option<&str>, auth: bool, mask: Option<u32>, labels: [&str;3]) {
use registry_type::RegistryType::*; let variants=[Docker,Maven,Npm,Cargo,PyPI,Go,Raw,Gems,Terraform,Ansible,Nuget,PubDart,Conan,Rpm,Deb,Cpan];
let set:std::collections::HashSet<_>=variants.into_iter().enumerate().filter_map(|(i,v)| if mask.unwrap_or(65535)&(1<<i)!=0 {Some(v)} else {None}).collect();
let t=Translations{nav_dashboard:labels[0],nav_registries:labels[1],nav_tokens:labels[2]};
let expected=sidebar_dark_with_registries(active,&t,auth,mask.map(|_| &set));
let kt=kernel::Translations{nav_dashboard:labels[0].as_bytes().to_vec(),nav_registries:labels[1].as_bytes().to_vec(),nav_tokens:labels[2].as_bytes().to_vec()};
let e=kernel::Enabled{docker:set.contains(&Docker),maven:set.contains(&Maven),npm:set.contains(&Npm),cargo:set.contains(&Cargo),pypi:set.contains(&PyPI),raw:set.contains(&Raw),go:set.contains(&Go),gems:set.contains(&Gems),terraform:set.contains(&Terraform),ansible:set.contains(&Ansible),nuget:set.contains(&Nuget),pub_dart:set.contains(&PubDart),conan:set.contains(&Conan),rpm:set.contains(&Rpm),deb:set.contains(&Deb),cpan:set.contains(&Cpan)};
assert_eq!(decode(kernel::sidebar(active.unwrap_or("").as_bytes(),&kt,auth,&e,VERSION.as_bytes())),expected.as_bytes(),"active={active:?} auth={auth} mask={mask:?}");
}
#[test] fn complete_outputs_all_registry_subsets() { let ids=[None,Some("dashboard"),Some("docker"),Some("maven"),Some("npm"),Some("cargo"),Some("pypi"),Some("raw"),Some("go"),Some("gems"),Some("terraform"),Some("ansible"),Some("nuget"),Some("pub"),Some("conan"),Some("rpm"),Some("deb"),Some("cpan"),Some("tokens"),Some(""),Some("unknown"),Some("DOCKER")];
for mask in 0..65536 { for auth in [false,true] { compare(ids[(mask as usize)%ids.len()],auth,Some(mask),["Dashboard","Registries","Tokens"]); } }
for id in ids { for auth in [false,true] { compare(id,auth,None,["","\u{0}<&>","日本語 🦀"]); compare(id,auth,Some(0),[" ","\t\r\n","{}"]); } }
}
fn text(mut n:u64) -> String { let chars=['\0','<','>','&','"','\'','{','}',' ', '\n','é','界','🦀']; let mut s=String::new(); for _ in 0..((n%29)+1) { n=n.wrapping_mul(6364136223846793005).wrapping_add(1); s.push(chars[(n as usize)%chars.len()]); } s }
#[test] fn complete_arbitrary_text_fields() { for n in 0..4000u64 { let active=text(n+17); let d=text(n*3+11); let r=text(n*7+101); let t=text(n*11+1001); compare(Some(&active),n%2==0,Some((n.wrapping_mul(17973)&65535) as u32),[&d,&r,&t]); } }
