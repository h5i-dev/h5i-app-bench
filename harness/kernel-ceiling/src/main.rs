//! List the functions and data items of a Rust source tree with the facts
//! harness/kernel_ceiling.py needs to decide which could be an h5i-app kernel.
//!
//!   kernel-ceiling <dir>   # one JSON object per item on stdout
//!
//! Test code (`#[test]`, `#[cfg(test)]` modules) is reported with `test: true`.

use proc_macro2::{TokenStream, TokenTree};
use serde_json::{json, Value};
use std::collections::BTreeSet;
use syn::spanned::Spanned;
use syn::visit::{self, Visit};

#[derive(Default)]
struct Facts {
    idents: BTreeSet<String>,
    calls: BTreeSet<(String, String)>,
    methods: BTreeSet<String>,
    awaits: bool,
    unsafe_: bool,
}

fn tokens(ts: &TokenStream, out: &mut BTreeSet<String>) {
    for t in ts.clone() {
        match t {
            TokenTree::Ident(i) => {
                out.insert(i.to_string());
            }
            TokenTree::Group(g) => tokens(&g.stream(), out),
            _ => {}
        }
    }
}

impl<'a> Visit<'a> for Facts {
    fn visit_ident(&mut self, i: &'a syn::Ident) {
        self.idents.insert(i.to_string());
    }
    fn visit_macro(&mut self, m: &'a syn::Macro) {
        tokens(&m.tokens, &mut self.idents);
        visit::visit_macro(self, m);
    }
    fn visit_expr_call(&mut self, c: &'a syn::ExprCall) {
        if let syn::Expr::Path(p) = &*c.func {
            let segs: Vec<String> = p.path.segments.iter().map(|s| s.ident.to_string()).collect();
            let name = segs.last().cloned().unwrap_or_default();
            let ty = if segs.len() >= 2 { segs[segs.len() - 2].clone() } else { String::new() };
            self.calls.insert((ty, name));
        }
        visit::visit_expr_call(self, c);
    }
    fn visit_expr_method_call(&mut self, m: &'a syn::ExprMethodCall) {
        self.methods.insert(m.method.to_string());
        visit::visit_expr_method_call(self, m);
    }
    fn visit_expr_await(&mut self, a: &'a syn::ExprAwait) {
        self.awaits = true;
        visit::visit_expr_await(self, a);
    }
    fn visit_expr_unsafe(&mut self, u: &'a syn::ExprUnsafe) {
        self.unsafe_ = true;
        visit::visit_expr_unsafe(self, u);
    }
    // Nested items are reported on their own.
    fn visit_item(&mut self, _: &'a syn::Item) {}
}

fn is_test(attrs: &[syn::Attribute]) -> bool {
    attrs.iter().any(|a| {
        let p = a.path();
        let last = p.segments.last().map(|s| s.ident.to_string()).unwrap_or_default();
        if last == "test" || last == "bench" {
            return true;
        }
        if p.is_ident("cfg") {
            let mut s = BTreeSet::new();
            if let syn::Meta::List(l) = &a.meta {
                tokens(&l.tokens, &mut s);
            }
            return s.contains("test") && !s.contains("not");
        }
        false
    })
}

struct Walker<'f> {
    file: &'f str,
    out: Vec<Value>,
    test: bool,
}

impl Walker<'_> {
    fn emit(&mut self, kind: &str, name: String, self_ty: String, span: proc_macro2::Span, sig_async: bool,
            sig_unsafe: bool, test: bool, facts: Facts) {
        self.out.push(json!({
            "file": self.file, "kind": kind, "name": name, "self_ty": self_ty,
            "start": span.start().line, "end": span.end().line,
            "async": sig_async, "unsafe": sig_unsafe || facts.unsafe_, "await": facts.awaits,
            "test": test || self.test,
            "idents": facts.idents.into_iter().collect::<Vec<_>>(),
            "calls": facts.calls.into_iter().map(|(t, n)| vec![t, n]).collect::<Vec<_>>(),
            "methods": facts.methods.into_iter().collect::<Vec<_>>(),
        }));
    }

    fn data<T: Spanned>(&mut self, kind: &str, name: String, attrs: &[syn::Attribute], node: &T,
                        visit_fn: impl FnOnce(&mut Facts)) {
        let mut f = Facts::default();
        visit_fn(&mut f);
        self.emit(kind, name, String::new(), node.span(), false, false, is_test(attrs), f);
    }

    fn items(&mut self, items: &[syn::Item]) {
        for item in items {
            self.item(item);
        }
    }

    fn item(&mut self, item: &syn::Item) {
        match item {
            syn::Item::Fn(f) => {
                let mut facts = Facts::default();
                facts.visit_block(&f.block);
                facts.visit_signature(&f.sig);
                self.emit("fn", f.sig.ident.to_string(), String::new(), f.span(), f.sig.asyncness.is_some(),
                          f.sig.unsafety.is_some(), is_test(&f.attrs), facts);
            }
            syn::Item::Impl(i) => {
                let test = is_test(&i.attrs);
                let ty = match &*i.self_ty {
                    syn::Type::Path(p) => p.path.segments.last().map(|s| s.ident.to_string()).unwrap_or_default(),
                    _ => String::new(),
                };
                let trait_ = i.trait_.as_ref().and_then(|t| t.1.segments.last()).map(|s| s.ident.to_string());
                for it in &i.items {
                    if let syn::ImplItem::Fn(m) = it {
                        let mut facts = Facts::default();
                        facts.visit_block(&m.block);
                        facts.visit_signature(&m.sig);
                        if let Some(t) = &trait_ {
                            facts.idents.insert(t.clone());
                        }
                        self.emit("method", m.sig.ident.to_string(), ty.clone(), m.span(), m.sig.asyncness.is_some(),
                                  m.sig.unsafety.is_some() || i.unsafety.is_some(), test || is_test(&m.attrs), facts);
                    }
                }
            }
            syn::Item::Trait(t) => {
                for it in &t.items {
                    if let syn::TraitItem::Fn(m) = it {
                        if let Some(b) = &m.default {
                            let mut facts = Facts::default();
                            facts.visit_block(b);
                            facts.visit_signature(&m.sig);
                            self.emit("method", m.sig.ident.to_string(), t.ident.to_string(), m.span(),
                                      m.sig.asyncness.is_some(), m.sig.unsafety.is_some(), is_test(&t.attrs), facts);
                        }
                    }
                }
            }
            syn::Item::Mod(m) => {
                if let Some((_, items)) = &m.content {
                    let saved = self.test;
                    self.test = self.test || is_test(&m.attrs);
                    self.items(items);
                    self.test = saved;
                }
            }
            syn::Item::Struct(s) => self.data("struct", s.ident.to_string(), &s.attrs, s, |f| f.visit_item_struct(s)),
            syn::Item::Enum(e) => self.data("enum", e.ident.to_string(), &e.attrs, e, |f| f.visit_item_enum(e)),
            syn::Item::Type(t) => self.data("type", t.ident.to_string(), &t.attrs, t, |f| f.visit_item_type(t)),
            syn::Item::Const(c) => self.data("const", c.ident.to_string(), &c.attrs, c, |f| f.visit_item_const(c)),
            syn::Item::Static(s) => {
                let kind = if matches!(s.mutability, syn::StaticMutability::Mut(_)) { "static_mut" } else { "static" };
                self.data(kind, s.ident.to_string(), &s.attrs, s, |f| f.visit_item_static(s))
            }
            _ => {}
        }
    }
}

fn main() {
    let dir = std::env::args().nth(1).expect("usage: kernel-ceiling <dir>");
    let mut failed = 0;
    for entry in walkdir::WalkDir::new(&dir).sort_by_file_name() {
        let entry = entry.expect("walk");
        let path = entry.path();
        if path.extension().map_or(true, |e| e != "rs") {
            continue;
        }
        let text = std::fs::read_to_string(path).expect("read");
        let rel = path.strip_prefix(&dir).unwrap().to_string_lossy().to_string();
        match syn::parse_file(&text) {
            Ok(file) => {
                let mut w = Walker { file: &rel, out: vec![], test: is_test(&file.attrs) };
                w.items(&file.items);
                for v in w.out {
                    println!("{v}");
                }
            }
            Err(e) => {
                failed += 1;
                println!("{}", json!({"file": rel, "kind": "parse_error", "error": e.to_string()}));
            }
        }
    }
    eprintln!("{failed} files failed to parse");
}
