use syn::{visit::{self,Visit},spanned::Spanned};use quote::ToTokens;use serde_json::json;
fn attrs(a:&[syn::Attribute])->Vec<String>{a.iter().map(|x|x.to_token_stream().to_string()).collect()}
#[derive(Default)]struct Walk{context:Vec<String>,rows:Vec<serde_json::Value>}
impl<'ast> Visit<'ast> for Walk{
fn visit_item_mod(&mut self,x:&'ast syn::ItemMod){let n=self.context.len();self.context.extend(attrs(&x.attrs));visit::visit_item_mod(self,x);self.context.truncate(n);}
fn visit_item_impl(&mut self,x:&'ast syn::ItemImpl){let n=self.context.len();self.context.extend(attrs(&x.attrs));visit::visit_item_impl(self,x);self.context.truncate(n);}
fn visit_impl_item_fn(&mut self,x:&'ast syn::ImplItemFn){self.rows.push(json!({"name":x.sig.ident.to_string(),"start":x.span().start().line,"end":x.span().end().line,"context":self.context,"attrs":attrs(&x.attrs)}));}
}
fn main(){for p in std::env::args().skip(1){let f=syn::parse_file(&std::fs::read_to_string(&p).unwrap()).unwrap();let mut w=Walk::default();w.context=attrs(&f.attrs);w.visit_file(&f);println!("{}",json!({"file":p,"methods":w.rows}));}}
