//! `#[implement(Path)] fn f(..)` becomes `impl Path { fn f(..) }`, as
//! tuwunel's `implement`. `ctor` and `instrument` leave the item unchanged.
use proc_macro::{Delimiter, Group, Ident, Span, TokenStream, TokenTree};

#[proc_macro_attribute]
pub fn implement(args: TokenStream, item: TokenStream) -> TokenStream {
    let mut out: Vec<TokenTree> = vec![TokenTree::Ident(Ident::new("impl", Span::call_site()))];
    out.extend(args);
    out.push(TokenTree::Group(Group::new(Delimiter::Brace, item)));
    out.into_iter().collect()
}

#[proc_macro_attribute]
pub fn ctor(_args: TokenStream, item: TokenStream) -> TokenStream {
    item
}

#[proc_macro_attribute]
pub fn instrument(_args: TokenStream, item: TokenStream) -> TokenStream {
    item
}
