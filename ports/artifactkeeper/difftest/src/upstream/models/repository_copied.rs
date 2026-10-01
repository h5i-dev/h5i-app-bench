// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
impl RepositoryVisibility {
    /// Return the lowercase string representation matching the database enum.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Public => "public",
            Self::Internal => "internal",
            Self::Private => "private",
        }
    }

    /// Parse the lowercase database representation back into a variant, the
    /// inverse of [`RepositoryVisibility::as_str`].
    ///
    /// Returns `None` for anything unrecognised so a caller reading a raw
    /// `visibility` string fails closed rather than defaulting to a wider
    /// audience.
    pub fn from_db_str(s: &str) -> Option<Self> {
        match s {
            "public" => Some(Self::Public),
            "internal" => Some(Self::Internal),
            "private" => Some(Self::Private),
            _ => None,
        }
    }

    /// Whether an unauthenticated caller may read this repository.
    ///
    /// This is exactly the meaning of the deprecated `is_public` mirror column,
    /// and the predicate the OCI anonymous gates and the anonymous listing and
    /// search filters ask.
    pub fn allows_anonymous_read(&self) -> bool {
        matches!(self, Self::Public)
    }

    /// Whether a caller whose credentials resolved to some principal may read
    /// this repository without holding any grant on it.
    ///
    /// True for `public` as well as `internal`: an authenticated caller must
    /// never end up with less read access than an anonymous one would have on
    /// the same repository.
    pub fn allows_authenticated_read(&self) -> bool {
        matches!(self, Self::Public | Self::Internal)
    }
}
