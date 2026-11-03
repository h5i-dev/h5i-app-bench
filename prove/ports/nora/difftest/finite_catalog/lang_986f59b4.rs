#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Lang {En,Ru,Zh}
impl Lang {
    pub fn code(&self) -> &'static str {
        match self {
            Lang::En => "en",
            Lang::Ru => "ru",
            Lang::Zh => "zh",
        }
    }
}
fn main(){
println!("code/En\t{:?}",Lang::En.code().as_bytes());
println!("code/Ru\t{:?}",Lang::Ru.code().as_bytes());
println!("code/Zh\t{:?}",Lang::Zh.code().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(Lang::En.code().as_bytes(),nora_kernel::finite_catalog::lang_986f59b4::Lang::En.code(),"lang_986f59b4/code/En");
assert_eq!(Lang::Ru.code().as_bytes(),nora_kernel::finite_catalog::lang_986f59b4::Lang::Ru.code(),"lang_986f59b4/code/Ru");
assert_eq!(Lang::Zh.code().as_bytes(),nora_kernel::finite_catalog::lang_986f59b4::Lang::Zh.code(),"lang_986f59b4/code/Zh");
}
