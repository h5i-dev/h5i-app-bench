// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
use super::academy_models::{user::*, withdrawal::*};

impl UserIdOrSelf {
    pub fn unwrap_or(self, self_user_id: UserId) -> UserId {
        match self {
            UserIdOrSelf::UserId(user_id) => user_id,
            UserIdOrSelf::Slf => self_user_id,
        }
    }
}

pub const WITHDRAWAL_TEXT_VERSION: &str = "2026-09";

impl WithdrawalConsentDeclaration {
    /// Return the accepted text version, or `None` if the declarations have
    /// not been given for the instruction that is currently in force.
    ///
    /// A client that states another version is showing a text that is not the
    /// applicable one, so what it collected is not a declaration for this
    /// order.
    pub fn text_version(&self) -> Option<&WithdrawalTextVersion> {
        self.given
            .then_some(self.text_version.as_ref())
            .flatten()
            .filter(|version| version.as_str() == WITHDRAWAL_TEXT_VERSION)
    }
}
