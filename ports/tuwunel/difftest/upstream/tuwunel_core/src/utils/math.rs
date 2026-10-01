// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
/// Converts a Matrix unsigned integer to a bounded `usize`.
///
/// Conversion failure uses `fallback`. The result is limited to `max` after
/// either conversion path.

#[inline]
#[must_use]
pub fn usize_from_ruma_bounded(val: ruma::UInt, fallback: usize, max: usize) -> usize {
	usize::try_from(val).unwrap_or(fallback).min(max)
}

