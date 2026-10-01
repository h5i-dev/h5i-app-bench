// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
//! Additional combinators for futures and optional futures.
//!
//! The extensions compose Boolean, optional, and fallible outputs without
//! awaiting them early. Comparison and selection helpers are included.

pub use self::{
	bool_ext::{BoolExt, and, and4, and5, and6, and7, or},
	ext_ext::ExtExt,
	option_ext::OptionFutureExt,
	option_stream::OptionStream,
	ready_bool_ext::ReadyBoolExt,
	ready_eq_ext::ReadyEqExt,
	try_ext_ext::TryExtExt,
};
mod bool_ext;
mod ext_ext;
mod option_ext;
mod option_stream;
mod ready_bool_ext;
mod ready_eq_ext;
mod try_ext_ext;


/// Unwrap the value from a `Poll<Option<T>>`, early-returning from the
/// enclosing function on `Ready(None)` or `Pending`.
///
/// Must be invoked inside a function returning `Poll<Option<_>>`, such as a
/// `Stream::poll_next` impl; the `return` arms otherwise produce a type
/// mismatch at the enclosing function's return.
#[macro_export]
macro_rules! ready_some {
	($e:expr) => {
		match $e {
			| std::task::Poll::Ready(Some(v)) => v,
			| std::task::Poll::Ready(None) => return std::task::Poll::Ready(None),
			| std::task::Poll::Pending => return std::task::Poll::Pending,
		}
	};
}
