include!("UPSTREAM");
mod port { include!("PORT"); }
fn pd(p:&WildCardedDomain)->port::Domain {match p {WildCardedDomain::WildCard=>port::Domain::WildCard,WildCardedDomain::WildCarded(s)=>port::Domain::WildCarded(s.as_bytes().to_vec()),WildCardedDomain::Exact(s)=>port::Domain::Exact(s.as_bytes().to_vec())}}
fn rng(s:&mut u64)->usize{*s^=*s<<13;*s^=*s>>7;*s^=*s<<17;*s as usize}
fn main(){
 let names=["","*","*.","*.example.org","example.org","a.example.org","badexample.org","EXAMPLE.ORG","a..org","..","localhost","é.example.org","é","a/host",".example.org"];
 let mut patterns=vec![WildCardedDomain::WildCard];
 for n in names {let d:WildCardedDomain=n.parse().unwrap();assert_eq!(pd(&d),port::parse(n.as_bytes()));patterns.push(d);}
 let mut count=names.len();
 for a in &patterns{for b in &patterns {assert_eq!(a.more_specific_than(b),port::more_specific(&pd(a),&pd(b)));count+=1;}}
 for a in &patterns{for n in names {assert_eq!(a.matches(n),port::matches(&pd(a),n.as_bytes()));count+=1;}}
 let mut seed=0x5e130428193u64;
 for _ in 0..200000 {
  let mut include=vec![];let mut exclude=vec![];
  let ni=rng(&mut seed)%12;let ne=rng(&mut seed)%12;
  for _ in 0..ni {include.push(patterns[rng(&mut seed)%patterns.len()].clone());}
  for _ in 0..ne {exclude.push(patterns[rng(&mut seed)%patterns.len()].clone());}
  let host=if rng(&mut seed)%8==0 {None}else{Some(names[rng(&mut seed)%names.len()].to_string())};
  let rule=port::Rule{include:include.iter().map(pd).collect(),exclude:exclude.iter().map(pd).collect()};
  let proxy=PartialProxyConfig{url:Url{host:Some("proxy.example".into()),scheme:"http".into(),id:0},include,exclude};
  assert_eq!(proxy.for_url(&Url{host:host.clone(),scheme:"https".into(),id:0}).is_some(),port::for_host(&rule,host.as_deref().map(str::as_bytes)),"{rule:?} {host:?}");count+=1;
 }
 let schemes=["http","https","socks4","socks4a","socks5","socks5h","HTTP","ftp","","://"];
 for _ in 0..100000 {
  let host=if rng(&mut seed)%7==0{None}else{Some(names[rng(&mut seed)%names.len()].to_string())};
  let request=Url{host:host.clone(),scheme:schemes[rng(&mut seed)%schemes.len()].into(),id:0};
  let mut rr=vec![];let mut pp=vec![];
  for id in 0..rng(&mut seed)%8 {
   let mut include=vec![];let mut exclude=vec![];
   for _ in 0..rng(&mut seed)%5{include.push(patterns[rng(&mut seed)%patterns.len()].clone());}
   for _ in 0..rng(&mut seed)%5{exclude.push(patterns[rng(&mut seed)%patterns.len()].clone());}
   let scheme=schemes[rng(&mut seed)%schemes.len()].to_string();
   pp.push(port::EndpointRule{policy:port::Rule{include:include.iter().map(pd).collect(),exclude:exclude.iter().map(pd).collect()},scheme:scheme.as_bytes().to_vec()});
   rr.push(PartialProxyConfig{url:Url{host:Some("proxy".into()),scheme,id},include,exclude});
  }
  let (original,ported)=match rng(&mut seed)%3 {
   0=>(ProxyConfig::None,port::Config::None),
   1=>{let scheme=schemes[rng(&mut seed)%schemes.len()].to_string();(ProxyConfig::Global{url:Url{host:None,scheme:scheme.clone(),id:0}},port::Config::Global(scheme.into_bytes()))},
   _=>(ProxyConfig::ByDomain(rr),port::Config::ByDomain(pp))
  };
  assert_eq!(original.proxy_for(&request).map(|u|u.id),port::proxy_for(&ported,request.scheme.as_bytes(),host.as_deref().map(str::as_bytes)));count+=1;
 }
 println!("PASS {count} exact domain parse/match/specificity and ordered proxy rule decisions");
}
