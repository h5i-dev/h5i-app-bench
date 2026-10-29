//! Differential filter-chain semantics against verbatim pinned CurationEngine.
#![allow(dead_code)]
extern crate self as tracing;
#[macro_export] macro_rules! info { ($($tt:tt)*) => {{}} }
#[macro_export] macro_rules! warn { ($($tt:tt)*) => {{}} }
use nora_kernel::curation as c;
use std::sync::atomic::Ordering;
#[derive(Clone,Copy,Debug)] pub enum RegistryType { Npm }
impl RegistryType {fn as_str(&self)-> &str {"npm"}}
impl std::fmt::Display for RegistryType {
    fn fmt(&self,f:&mut std::fmt::Formatter<'_>)->std::fmt::Result {write!(f,"npm")}
}
mod config {
    #[derive(Clone,Copy,PartialEq)] pub enum CurationMode {Off,Audit,Enforce}
    pub struct CurationConfig {pub mode:CurationMode}
}
mod metrics {
    pub fn record_namespace_isolation_refused(_:&str){}
    pub static LAST:std::sync::atomic::AtomicU8=std::sync::atomic::AtomicU8::new(255);
    pub struct Metric;
    pub static CURATION_DECISIONS_TOTAL:Metric=Metric;
    impl Metric {pub fn with_label_values(&self,labels:&[&str])->&Self {
        LAST.store(match labels[0] {"allow"=>0,"audit"=>1,"block"=>2,"skip"=>3,_=>255},std::sync::atomic::Ordering::Relaxed);self} pub fn inc(&self){}}
}
mod axum {
    pub mod http {
        pub type HeaderMap=std::collections::BTreeMap<String,HeaderValue>;
        pub struct HeaderValue(pub Option<String>);
        impl HeaderValue {pub fn to_str(&self)->Result<&str,()> {self.0.as_deref().ok_or(())}}
    }
    pub mod response {pub type Response=(String,String);pub trait IntoResponse {fn into_response(self)->Response;}}
}
trait ConstantTimeEq {fn ct_eq(&self,other:&Self)->bool;}
impl ConstantTimeEq for [u8] {fn ct_eq(&self,other:&Self)->bool {self==other}}
mod sha2 {
    pub trait Digest {fn digest(data:&[u8])->Vec<u8>;}
    pub struct Sha256;
    impl Digest for Sha256 {fn digest(_:&[u8])->Vec<u8> {vec![0;32]}}
}
mod hex {pub fn encode(_:Vec<u8>)->String {"0".repeat(64)}}
mod reference {
    include!("../../difftest/curation/reference.rs");
    pub fn inner(e:&CurationEngine,r:&FilterRequest)->EvaluationResult {e.evaluate_inner(r)}
}
struct Filter(c::Filter);
fn name(n:u64)-> &'static str {match n {0=>"bypass",1=>"namespace",2=>"filter2",_=>"filter3"}}
fn rule(n:u64,integrity:bool)->String {format!("rule-{n}{}",if integrity {":integrity"} else {""})}
impl reference::ProxyFilter for Filter {
    fn name(&self)-> &'static str {name(self.0.name)}
    fn evaluate(&self,_:&reference::FilterRequest)->reference::Decision {
        match self.0.decision {
            c::Decision::Allow=>reference::Decision::Allow,
            c::Decision::Skip=>reference::Decision::Skip,
            c::Decision::Block{rule:r,reason,integrity_rule}=>reference::Decision::Block {
                rule:rule(r,integrity_rule),reason:format!("reason-{reason}")},
        }
    }
}
fn compare(mode:c::Mode,ns:Option<c::Filter>,chain:&[c::Filter],bypass:bool,integrity:bool) {
    let mut engine=reference::CurationEngine::new(config::CurationConfig{mode:match mode {
        c::Mode::Off=>config::CurationMode::Off,c::Mode::Audit=>config::CurationMode::Audit,
        c::Mode::Enforce=>config::CurationMode::Enforce}});
    if let Some(x)=ns {engine.set_namespace_filter(Box::new(Filter(x)));}
    for x in chain {engine.add_filter(Box::new(Filter(*x)));}
    let request=reference::FilterRequest{registry:RegistryType::Npm,upstream:None,name:"p".into(),
        version:Some("v".into()),integrity:integrity.then(||"sha256:abc".into()),bypass,publish_date:None};
    let expected=engine.evaluate(&request);
    let expected_label=metrics::LAST.load(Ordering::Relaxed);
    let (got,label)=c::evaluate(mode,ns,chain,bypass,integrity,0);
    assert_eq!(label,expected_label);
    assert_eq!(got.decided_by.map(|n|name(n).to_owned()),expected.decided_by);
    assert_eq!(got.audited,expected.audited);
    match (got.decision,expected.decision) {
        (c::Decision::Allow,reference::Decision::Allow)|(c::Decision::Skip,reference::Decision::Skip)=>{},
        (c::Decision::Block{rule:r,reason,integrity_rule},reference::Decision::Block{rule:r1,reason:r2})=>{
            assert_eq!(rule(r,integrity_rule),r1);assert_eq!(format!("reason-{reason}"),r2);},
        x=>panic!("decision mismatch {x:?}"),
    }
    assert_eq!(matches!(got.effect,c::Effect::Allowed) as u64,engine.metrics().allowed.load(Ordering::Relaxed));
    assert_eq!(matches!(got.effect,c::Effect::Blocked) as u64,engine.metrics().blocked.load(Ordering::Relaxed));
    assert_eq!(got.without_integrity as u64,engine.metrics().without_integrity.load(Ordering::Relaxed));
    assert_eq!(label,match got.decision {c::Decision::Allow=>0,c::Decision::Skip=>3,
        c::Decision::Block{..}=>if got.audited {1} else {2}});
    fn payload(actual:Option<(u64,u64)>,dec:c::Decision)->Option<(String,String)> {
        actual.map(|(r,reason)|{
            let integrity=matches!(dec,c::Decision::Block{integrity_rule:true,..});
            (rule(r,integrity),format!("reason-{reason}"))
        })
    }
    for token in [None,Some(10),Some(11)] {for header in [None,Some(10),Some(11)] {
        let mut headers=axum::http::HeaderMap::new();
        if let Some(h)=header {headers.insert("x-nora-bypass-token".into(),axum::http::HeaderValue(Some(format!("{h}"))));}
        let token_text=token.map(|t|format!("{t}"));
        let actual=c::check_download(mode,ns,chain,token,header,0);
        let expected=reference::check_download(&engine,token_text.as_deref(),&headers,RegistryType::Npm,"p",Some("v"),None);
        let dec=c::evaluate_inner(mode,ns,chain,token.is_some() && token==header,false,0).decision;
        assert_eq!(payload(actual,dec),expected);
        headers.insert("x-nora-bypass-token".into(),axum::http::HeaderValue(None));
        let actual=c::check_download(mode,ns,chain,token,None,0);
        let expected=reference::check_download(&engine,token_text.as_deref(),&headers,RegistryType::Npm,"p",Some("v"),None);
        let dec=c::evaluate_inner(mode,ns,chain,false,false,0).decision;
        assert_eq!(payload(actual,dec),expected);
    }}
    let expected=reference::verify_integrity(&engine,RegistryType::Npm,"p",Some("v"),b"data");
    let actual=c::verify_integrity(mode,ns,chain,0);
    let dec=c::evaluate_inner(mode,ns,chain,false,true,0).decision;
    assert_eq!(payload(actual,dec),expected);
    let hash=format!("sha256:{}","0".repeat(64));
    let expected=reference::verify_integrity_by_hash(&engine,RegistryType::Npm,"p",Some("v"),&hash);
    assert_eq!(payload(c::verify_integrity_by_hash(mode,ns,chain,0,true),dec),expected);
    assert_eq!(c::is_internal_namespace(ns),reference::is_internal_namespace(&engine,RegistryType::Npm,"p"));
    assert_eq!(c::namespace_filter_active(ns),reference::namespace_filter_active(&engine));
    let expected=reference::check_namespace_isolation(&engine,RegistryType::Npm,"p");
    assert_eq!(payload(c::check_namespace_isolation(ns).0,ns.map(|n|n.decision).unwrap_or(c::Decision::Skip)),expected);

}
#[test]
fn pinned_curation_chain() {
    use c::Decision::*;
    let ds=[Skip,Allow,Block{rule:11,reason:12,integrity_rule:false},Block{rule:21,reason:22,integrity_rule:true}];
    let mut count=0;
    // Every chain up to length five; first/last wins, namespace precedence,
    // Off/Audit/Enforce, bypass, integrity presence, and identity preservation.
    for len in 0..=5 {
        for mut code in 0..4usize.pow(len) {
            let mut chain=vec![];
            for i in 0..len {chain.push(c::Filter{name:2+i as u64%2,decision:ds[code%4]});code/=4;}
            for ns in [None,Some(c::Filter{name:1,decision:Allow}),Some(c::Filter{name:1,decision:Skip}),
                Some(c::Filter{name:1,decision:ds[2]}),Some(c::Filter{name:1,decision:ds[3]})] {
                for mode in [c::Mode::Off,c::Mode::Audit,c::Mode::Enforce] {
                    for bypass in [false,true] {for integrity in [false,true] {
                        compare(mode,ns,&chain,bypass,integrity);count+=1;
                    }}
                }
            }
        }
    }
    println!("{count} directed pinned curation comparisons");
}
