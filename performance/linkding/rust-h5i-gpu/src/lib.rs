//! linkding bookmark-search benchmark: the application predicate and the host
//! packing the GPU kernel reads.
//!
//! * `predicate` — the bounded, allocation-free port of linkding's postfix AST
//!   evaluator. This is the exact source the device kernel compiles, so the
//!   CPU and GPU evaluate identical logic.
//! * `pack` — turns bookmarks and a parsed query into the flat SoA columns,
//!   reusing `linkding-kernel`'s parser and real `bookmark_matches` matcher as
//!   the independent CPU oracle (no copy of the library).
//!
//! The GPU backend is in `backend-nvvm/`; it imports the `h5i-app-gpu` launch
//! shell from the h5i framework. Nothing here depends on CUDA, so this crate
//! builds and its CPU conformance test runs on stable with no GPU.
pub mod predicate;
pub mod pack;
pub use linkding_kernel::BookmarkFacts;

#[cfg(test)]
mod tests {
    use crate::pack::{Query, Rows, benchmark_fixture};
    use linkding_kernel::{bookmark_matches, parse_search};

    // The device predicate (via the packed SoA path) agrees with linkding's
    // real `bookmark_matches` over a spread of queries and representative rows.
    #[test]
    fn packed_predicate_matches_the_real_linkding_matcher() {
        let bookmarks: Vec<_> = (1..=400).map(benchmark_fixture).collect();
        let mut r = Rows::default();
        for b in &bookmarks {
            r.push(b);
        }
        for qs in ["", "alpha", "#tag1", "!unread", "alpha and #tag1", "(alpha or #tag2) and not !unread"] {
            let packed = r.cpu(&Query::new(qs, false), 4);
            let parsed = parse_search(&qs.as_bytes().to_vec());
            for (i, b) in bookmarks.iter().enumerate() {
                assert!(packed[i] <= 1, "query {qs:?} row {i}: error slot");
                assert_eq!(
                    packed[i] == 1,
                    bookmark_matches(&parsed, false, b),
                    "query {qs:?} row {i} disagrees with linkding bookmark_matches"
                );
            }
        }
    }
}
