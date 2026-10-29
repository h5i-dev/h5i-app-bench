// Pinned outbound domain policy. Parsed URL hosts/schemes enter as bytes;
// endpoint identity is an index, so URL parsing and proxy I/O stay external.
#[derive(Clone,Debug,PartialEq,Eq)]
pub enum Domain { WildCard, WildCarded(Vec<u8>), Exact(Vec<u8>) }
pub fn bytes_eq(a:&[u8],b:&[u8])->bool {
    if a.len()!=b.len(){return false;}
    let mut i=0; while i<a.len(){if a[i]!=b[i]{return false;}i+=1;} true
}
pub fn ends_with(a:&[u8],b:&[u8])->bool {
    if a.len()<b.len(){return false;}
    let off=a.len()-b.len(); let mut i=0;
    while i<b.len(){if a[off+i]!=b[i]{return false;} i+=1;} true
}
pub fn matches(p:&Domain,host:&[u8])->bool {
    match p {Domain::WildCard=>true,Domain::WildCarded(d)=>ends_with(host,d),Domain::Exact(d)=>bytes_eq(host,d)}
}
pub fn more_specific(a:&Domain,b:&Domain)->bool {
    match (a,b) {
        (Domain::WildCard,Domain::WildCard)=>false,
        (_,Domain::WildCard)=>true,
        (Domain::Exact(x),Domain::WildCarded(_))=>matches(b,x),
        (Domain::WildCarded(x),Domain::WildCarded(y))=>!bytes_eq(x,y)&&ends_with(x,y),
        _=>false,
    }
}
pub fn parse(s:&[u8])->Domain {
    if s.len()>=2&&s[0]==b'*'&&s[1]==b'.' {
        let mut d=Vec::new(); let mut i=1; while i<s.len(){d.push(s[i]);i+=1;} Domain::WildCarded(d)
    }else if s.len()==1&&s[0]==b'*'{Domain::WildCarded(Vec::new())}
    else {let mut d=Vec::new();let mut i=0;while i<s.len(){d.push(s[i]);i+=1;}Domain::Exact(d)}
}
#[derive(Clone,Debug)]
pub struct Rule { pub include:Vec<Domain>,pub exclude:Vec<Domain> }
pub fn strongest(patterns:&[Domain],host:&[u8],initial:Option<usize>)->Option<usize>{
    let mut best=initial;let mut i=0;
    while i<patterns.len(){
        if matches(&patterns[i],host){
            match best {Some(prev)=>{if more_specific(&patterns[i],&patterns[prev]){best=Some(i);}},None=>best=Some(i)}
        }
        i+=1;
    }best
}
/// The implicit empty include is WildCard, distinct from parsing the string "*".
pub fn for_host(rule:&Rule,host:Option<&[u8]>)->bool {
    let host=match host {Some(h)=>h,None=>return false};
    let inc=strongest(&rule.include,host,None);
    let exc=strongest(&rule.exclude,host,None);
    match (inc,exc){
        (Some(a),Some(b))=>more_specific(&rule.include[a],&rule.exclude[b]),
        (Some(_),None)=>true,
        (None,Some(b)) if rule.include.is_empty()=>more_specific(&Domain::WildCard,&rule.exclude[b]),
        (None,None)=>rule.include.is_empty(),
        _=>false,
    }
}
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Scheme {Http,Https,Socks4,Socks4a,Socks5,Socks5h}
pub fn parse_scheme(s:&[u8])->Option<Scheme>{
    if bytes_eq(s,b"http"){Some(Scheme::Http)}
    else if bytes_eq(s,b"https"){Some(Scheme::Https)}
    else if bytes_eq(s,b"socks4"){Some(Scheme::Socks4)}
    else if bytes_eq(s,b"socks4a"){Some(Scheme::Socks4a)}
    else if bytes_eq(s,b"socks5"){Some(Scheme::Socks5)}
    else if bytes_eq(s,b"socks5h"){Some(Scheme::Socks5h)}
    else{None}
}
#[derive(Clone,Debug)]
pub struct EndpointRule {pub policy:Rule,pub scheme:Vec<u8>}
#[derive(Clone,Debug)]
pub enum Config {None,Global(Vec<u8>),ByDomain(Vec<EndpointRule>)}
/// The first matching rule wins BEFORE endpoint scheme validation.
/// Therefore an invalid selected proxy never falls through to later rules.
pub fn proxy_for(config:&Config,scheme:&[u8],host:Option<&[u8]>)->Option<usize>{
    if !bytes_eq(scheme,b"http")&&!bytes_eq(scheme,b"https"){return None;}
    match config {
        Config::None=>None,
        Config::Global(s)=>if parse_scheme(s).is_some(){Some(0)}else{None},
        Config::ByDomain(rules)=>{
            let mut i=0;
            while i<rules.len(){
                if for_host(&rules[i].policy,host){
                    return if parse_scheme(&rules[i].scheme).is_some(){Some(i)}else{None};
                }
                i+=1;
            }None
        }
    }
}
