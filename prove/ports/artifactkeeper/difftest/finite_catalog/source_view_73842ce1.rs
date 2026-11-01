#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum SourceView {Partial,Complete}
impl SourceView {
    /// Whether a write in this view is allowed to overwrite the row outright.
    fn overwrites(self) -> bool {
        matches!(self, SourceView::Complete)
    }
}
fn main(){
println!("overwrites/Partial\t{:?}",SourceView::Partial.overwrites());
println!("overwrites/Complete\t{:?}",SourceView::Complete.overwrites());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(SourceView::Partial.overwrites(),artifactkeeper_kernel::finite_catalog::source_view_73842ce1::SourceView::Partial.overwrites(),"source_view_73842ce1/overwrites/Partial");
assert_eq!(SourceView::Complete.overwrites(),artifactkeeper_kernel::finite_catalog::source_view_73842ce1::SourceView::Complete.overwrites(),"source_view_73842ce1/overwrites/Complete");
}
