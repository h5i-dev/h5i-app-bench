//! Stubs for what the copied upstream code uses: the models (only the fields
//! and conversions the services touch), the repository and finance traits
//! (only the methods called, signatures as upstream), `academy_utils` patches,
//! and `tracing`. Everything else under this directory is copied verbatim.
#![allow(dead_code, unused_imports, clippy::all)]

pub mod academy_auth_contracts;
pub mod academy_auth_impl;
pub mod academy_cache_contracts;
pub mod academy_core_coin_contracts;
pub mod academy_core_coin_impl;
pub mod academy_core_heart_contracts;
pub mod academy_core_heart_impl;
pub mod academy_core_mfa_contracts;
pub mod academy_core_mfa_impl;
pub mod academy_core_session_contracts;
pub mod academy_core_session_impl;
pub mod academy_core_withdrawal_contracts;
pub mod academy_core_withdrawal_impl;
pub mod academy_shared_contracts;
pub mod models_verbatim;

pub mod tracing {
    macro_rules! trace_ {
        ($($t:tt)*) => {
            ()
        };
    }
    pub(crate) use trace_ as trace;
}

pub mod uuid {
    /// Ids are numbers in the test.
    #[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Serialize, serde::Deserialize)]
    #[serde(transparent)]
    pub struct Uuid(pub u64);
    impl std::fmt::Display for Uuid {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            write!(f, "{}", self.0)
        }
    }
}

pub mod academy_di {
    pub struct Build;
}

pub mod academy_utils {
    pub fn trace_instrument() {}

    pub mod patch {
        /// `academy_utils::patch::PatchValue`.
        #[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
        pub enum PatchValue<T> {
            #[default]
            Unchanged,
            Update(T),
        }
        impl<T> PatchValue<T> {
            pub fn update(&self) -> Option<&T> {
                match self {
                    PatchValue::Update(x) => Some(x),
                    PatchValue::Unchanged => None,
                }
            }
        }
        pub trait Patch {
            type Patch;
            fn update(self, patch: Self::Patch) -> Self;
        }
    }
}

pub mod academy_core_finance_contracts {
    pub mod coin {
        pub type Decimal = i64;
        pub trait FinanceCoinService: Send + Sync + 'static {
            fn vat_percent(&self) -> Decimal;
            fn coins_per_euro(&self) -> u64;
        }
    }
}

pub mod academy_models {
    use std::ops::Deref;

    use serde::{Deserialize, Serialize};

    use super::uuid::Uuid;

    macro_rules! id {
        ($($n:ident),*) => {$(
            #[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
            #[serde(transparent)]
            pub struct $n(pub Uuid);
            impl Deref for $n {
                type Target = Uuid;
                fn deref(&self) -> &Uuid {
                    &self.0
                }
            }
            impl From<Uuid> for $n {
                fn from(u: Uuid) -> Self {
                    Self(u)
                }
            }
        )*};
    }

    macro_rules! string {
        ($($n:ident),*) => {$(
            #[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
            #[serde(transparent)]
            pub struct $n(pub String);
            impl $n {
                pub fn into_inner(self) -> String {
                    self.0
                }
            }
            impl Deref for $n {
                type Target = String;
                fn deref(&self) -> &String {
                    &self.0
                }
            }
            impl From<String> for $n {
                fn from(s: String) -> Self {
                    Self(s)
                }
            }
            impl From<&str> for $n {
                fn from(s: &str) -> Self {
                    Self(s.into())
                }
            }
            impl AsRef<[u8]> for $n {
                fn as_ref(&self) -> &[u8] {
                    self.0.as_bytes()
                }
            }
        )*};
    }

    macro_rules! sha256hash {
        ($($n:ident),*) => {$(
            #[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
            #[serde(transparent)]
            pub struct $n(Sha256Hash);
            impl Deref for $n {
                type Target = Sha256Hash;
                fn deref(&self) -> &Sha256Hash {
                    &self.0
                }
            }
            impl From<Sha256Hash> for $n {
                fn from(h: Sha256Hash) -> Self {
                    Self(h)
                }
            }
            impl std::fmt::Display for $n {
                fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                    write!(f, "{}", hex::encode(self.0.0))
                }
            }
        )*};
    }

    #[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
    pub struct Sha256Hash(pub [u8; 32]);

    #[derive(Debug, Clone, PartialEq, Eq)]
    pub struct Sensitive<T>(pub T);
    impl<T> From<T> for Sensitive<T> {
        fn from(value: T) -> Self {
            Self(value)
        }
    }
    impl<T> Deref for Sensitive<T> {
        type Target = T;
        fn deref(&self) -> &T {
            &self.0
        }
    }

    string!(RecaptchaResponse, VerificationCode);

    pub mod user {
        use super::*;
        use chrono::{DateTime, Utc};

        use crate::upstream::academy_utils::patch::{Patch, PatchValue};

        id!(UserId);
        string!(UserName, EmailAddress, UserPassword);

        impl EmailAddress {
            pub fn as_str(&self) -> &str {
                &self.0
            }
        }

        #[derive(Debug, Clone, Copy, PartialEq, Eq)]
        pub enum UserIdOrSelf {
            UserId(UserId),
            Slf,
        }

        #[derive(Debug, Clone, PartialEq, Eq)]
        pub struct User {
            pub id: UserId,
            pub name: UserName,
            pub email: Option<EmailAddress>,
            pub email_verified: bool,
            pub last_login: Option<DateTime<Utc>>,
            pub enabled: bool,
            pub admin: bool,
        }

        #[derive(Debug, Clone, PartialEq, Eq)]
        pub struct UserDetails {
            pub mfa_enabled: bool,
        }

        #[derive(Debug, Clone, PartialEq, Eq)]
        pub struct UserComposite {
            pub user: User,
            pub details: UserDetails,
        }

        #[derive(Debug, Clone, PartialEq, Eq)]
        pub enum UserNameOrEmailAddress {
            Name(UserName),
            Email(EmailAddress),
        }

        /// The `last_login` part of the derived `UserPatch`.
        #[derive(Debug, Clone, Default)]
        pub struct UserPatch {
            pub last_login: PatchValue<Option<DateTime<Utc>>>,
        }
        #[derive(Debug, Clone, Default)]
        pub struct UserPatchRef<'a> {
            pub last_login: PatchValue<&'a Option<DateTime<Utc>>>,
        }
        impl UserPatch {
            pub fn new() -> Self {
                Self::default()
            }
            pub fn update_last_login(mut self, v: Option<DateTime<Utc>>) -> Self {
                self.last_login = PatchValue::Update(v);
                self
            }
            pub fn as_ref(&self) -> UserPatchRef<'_> {
                UserPatchRef {
                    last_login: match &self.last_login {
                        PatchValue::Update(x) => PatchValue::Update(x),
                        PatchValue::Unchanged => PatchValue::Unchanged,
                    },
                }
            }
        }
        impl Patch for User {
            type Patch = UserPatch;
            fn update(mut self, patch: UserPatch) -> Self {
                if let PatchValue::Update(x) = patch.last_login {
                    self.last_login = x;
                }
                self
            }
        }
    }

    pub mod auth {
        use thiserror::Error;

        use super::*;
        use super::{session::Session, user::UserComposite};

        string!(AccessToken, RefreshToken);

        #[derive(Debug, Clone, PartialEq, Eq)]
        pub struct Login {
            pub user_composite: UserComposite,
            pub session: Session,
            pub access_token: AccessToken,
            pub refresh_token: RefreshToken,
        }

        #[derive(Debug, Error)]
        pub enum AuthError {
            #[error(transparent)]
            Authenticate(#[from] AuthenticateError),
            #[error(transparent)]
            Authorize(#[from] AuthorizeError),
        }

        #[derive(Debug, Error)]
        pub enum AuthenticateError {
            #[error("The access token is invalid or has expired.")]
            InvalidToken,
            #[error(transparent)]
            Other(#[from] anyhow::Error),
        }

        #[derive(Debug, Error)]
        pub enum AuthorizeError {
            #[error("The user is not an administrator.")]
            Admin,
            #[error("The session of the administrator was not authenticated with a second factor.")]
            AdminMfa,
            #[error("The user's email address is not verified.")]
            EmailVerified,
        }
    }

    pub mod session {
        use chrono::{DateTime, Utc};

        use super::*;
        use super::user::UserId;
        use crate::upstream::academy_utils::patch::{Patch, PatchValue};

        id!(SessionId);
        string!(DeviceName);
        sha256hash!(SessionRefreshTokenHash);

        #[derive(Debug, Clone, PartialEq, Eq)]
        pub struct Session {
            pub id: SessionId,
            pub user_id: UserId,
            pub device_name: Option<DeviceName>,
            pub created_at: DateTime<Utc>,
            pub updated_at: DateTime<Utc>,
            pub mfa_verified: bool,
        }

        /// The derived `SessionPatch`.
        #[derive(Debug, Clone, Default)]
        pub struct SessionPatch {
            pub device_name: PatchValue<Option<DeviceName>>,
            pub updated_at: PatchValue<DateTime<Utc>>,
        }
        #[derive(Debug, Clone, Default)]
        pub struct SessionPatchRef<'a> {
            pub device_name: PatchValue<&'a Option<DeviceName>>,
            pub updated_at: PatchValue<&'a DateTime<Utc>>,
        }
        impl SessionPatch {
            pub fn new() -> Self {
                Self::default()
            }
            pub fn update_updated_at(mut self, v: DateTime<Utc>) -> Self {
                self.updated_at = PatchValue::Update(v);
                self
            }
            pub fn as_ref(&self) -> SessionPatchRef<'_> {
                SessionPatchRef {
                    device_name: match &self.device_name {
                        PatchValue::Update(x) => PatchValue::Update(x),
                        PatchValue::Unchanged => PatchValue::Unchanged,
                    },
                    updated_at: match &self.updated_at {
                        PatchValue::Update(x) => PatchValue::Update(x),
                        PatchValue::Unchanged => PatchValue::Unchanged,
                    },
                }
            }
        }
        impl Patch for Session {
            type Patch = SessionPatch;
            fn update(mut self, patch: SessionPatch) -> Self {
                if let PatchValue::Update(x) = patch.device_name {
                    self.device_name = x;
                }
                if let PatchValue::Update(x) = patch.updated_at {
                    self.updated_at = x;
                }
                self
            }
        }
    }

    pub mod mfa {
        use chrono::{DateTime, Utc};

        use super::*;
        use super::user::UserId;
        use crate::upstream::academy_utils::patch::{Patch, PatchValue};

        id!(TotpDeviceId);
        string!(TotpCode, TotpSecretBase32, MfaRecoveryCode);
        sha256hash!(MfaRecoveryCodeHash);

        #[derive(Debug, Clone, PartialEq, Eq)]
        pub struct TotpDevice {
            pub id: TotpDeviceId,
            pub user_id: UserId,
            pub enabled: bool,
            pub created_at: DateTime<Utc>,
        }

        #[derive(Debug, Clone, PartialEq, Eq)]
        pub struct TotpSecret(pub Vec<u8>);

        #[derive(Debug, Clone, PartialEq, Eq)]
        pub struct TotpSetup {
            pub secret: TotpSecretBase32,
        }

        #[derive(Debug, Clone, PartialEq, Eq, Default)]
        pub struct MfaAuthentication {
            pub totp_code: Option<TotpCode>,
            pub recovery_code: Option<MfaRecoveryCode>,
        }

        /// The derived `TotpDevicePatch`.
        #[derive(Debug, Clone, Default)]
        pub struct TotpDevicePatch {
            pub enabled: PatchValue<bool>,
        }
        #[derive(Debug, Clone, Default)]
        pub struct TotpDevicePatchRef<'a> {
            pub enabled: PatchValue<&'a bool>,
        }
        impl TotpDevicePatch {
            pub fn new() -> Self {
                Self::default()
            }
            pub fn update_enabled(mut self, v: bool) -> Self {
                self.enabled = PatchValue::Update(v);
                self
            }
            pub fn as_ref(&self) -> TotpDevicePatchRef<'_> {
                TotpDevicePatchRef {
                    enabled: match &self.enabled {
                        PatchValue::Update(x) => PatchValue::Update(x),
                        PatchValue::Unchanged => PatchValue::Unchanged,
                    },
                }
            }
        }
        impl<'a> TotpDevicePatchRef<'a> {
            pub fn new() -> Self {
                Self::default()
            }
            pub fn update_enabled(mut self, v: &'a bool) -> Self {
                self.enabled = PatchValue::Update(v);
                self
            }
        }
        impl Patch for TotpDevice {
            type Patch = TotpDevicePatch;
            fn update(mut self, patch: TotpDevicePatch) -> Self {
                if let PatchValue::Update(x) = patch.enabled {
                    self.enabled = x;
                }
                self
            }
        }
    }

    pub mod coin {
        use chrono::{DateTime, Utc};

        use super::*;
        use super::user::UserId;
        use crate::upstream::academy_core_finance_contracts::coin::Decimal;

        id!(TransactionId);
        string!(TransactionDescription);

        #[derive(Debug, Clone, Copy, PartialEq, Eq)]
        pub struct CoinConfig {
            pub coins_per_euro: u64,
            pub vat_percent: Decimal,
        }

        #[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
        pub struct Balance {
            pub coins: u64,
            pub withheld_coins: u64,
        }

        #[derive(Debug, Clone, PartialEq, Eq)]
        pub struct Transaction {
            pub id: TransactionId,
            pub user_id: UserId,
            pub coins: i64,
            pub description: Option<TransactionDescription>,
            pub created_at: DateTime<Utc>,
            pub include_in_credit_note: bool,
        }
    }

    pub mod heart {
        use chrono::{DateTime, Utc};

        #[derive(Debug, Clone, Copy, PartialEq, Eq)]
        pub struct HeartConfig {
            pub hearts_max: u64,
            pub hearts_refill_price: u64,
        }

        #[derive(Debug, Clone, Copy, PartialEq, Eq)]
        pub struct Hearts {
            pub hearts: u64,
            pub last_refill: DateTime<Utc>,
        }
    }

    pub mod withdrawal {
        use chrono::{DateTime, Utc};

        use super::*;
        use super::user::UserId;

        id!(WithdrawalConsentId);
        string!(WithdrawalTextVersion, WithdrawalReference);

        impl WithdrawalTextVersion {
            pub fn as_str(&self) -> &str {
                &self.0
            }
        }

        #[derive(Debug, Clone, Copy, PartialEq, Eq)]
        pub enum WithdrawalSubject {
            Coins,
            Premium,
            Hearts,
            Course,
            Webinar,
        }

        #[derive(Debug, Clone, PartialEq, Eq)]
        pub struct WithdrawalConsentDeclaration {
            pub given: bool,
            pub text_version: Option<WithdrawalTextVersion>,
        }

        #[derive(Debug, Clone, PartialEq, Eq)]
        pub struct WithdrawalConsent {
            pub id: WithdrawalConsentId,
            pub user_id: UserId,
            pub subject: WithdrawalSubject,
            pub reference: Option<WithdrawalReference>,
            pub text_version: WithdrawalTextVersion,
            pub consented_at: DateTime<Utc>,
        }
    }
}

pub mod academy_persistence_contracts {
    use std::future::Future;

    pub trait Database: Send + Sync + 'static {
        type Transaction: Transaction;
        fn begin_transaction(&self) -> impl Future<Output = anyhow::Result<Self::Transaction>> + Send;
    }

    pub trait Transaction: Send + Sync + 'static {
        fn commit(self) -> impl Future<Output = anyhow::Result<()>> + Send;
    }

    pub mod user {
        use std::future::Future;

        use thiserror::Error;

        use crate::upstream::academy_models::user::{
            EmailAddress, UserComposite, UserId, UserName, UserNameOrEmailAddress, UserPatchRef,
        };

        #[derive(Debug, Error)]
        pub enum UserRepoError {
            #[error(transparent)]
            Other(#[from] anyhow::Error),
        }

        pub trait UserRepository<Txn: Send + Sync + 'static>: Send + Sync + 'static {
            fn exists(&self, txn: &mut Txn, user_id: UserId) -> impl Future<Output = anyhow::Result<bool>> + Send;
            fn get_composite(
                &self,
                txn: &mut Txn,
                user_id: UserId,
            ) -> impl Future<Output = anyhow::Result<Option<UserComposite>>> + Send;
            fn get_composite_by_name(
                &self,
                txn: &mut Txn,
                name: &UserName,
            ) -> impl Future<Output = anyhow::Result<Option<UserComposite>>> + Send;
            fn get_composite_by_email(
                &self,
                txn: &mut Txn,
                email: &EmailAddress,
            ) -> impl Future<Output = anyhow::Result<Option<UserComposite>>> + Send;
            /// Upstream's provided method, as in `persistence/contracts/src/user.rs`.
            fn get_composite_by_name_or_email(
                &self,
                txn: &mut Txn,
                name_or_email: &UserNameOrEmailAddress,
            ) -> impl Future<Output = anyhow::Result<Option<UserComposite>>> + Send {
                async move {
                    match name_or_email {
                        UserNameOrEmailAddress::Name(name) => self.get_composite_by_name(txn, name).await,
                        UserNameOrEmailAddress::Email(email) => self.get_composite_by_email(txn, email).await,
                    }
                }
            }
            fn update<'a>(
                &self,
                txn: &mut Txn,
                user_id: UserId,
                patch: UserPatchRef<'a>,
            ) -> impl Future<Output = Result<bool, UserRepoError>> + Send;
            fn get_password_hash(
                &self,
                txn: &mut Txn,
                user_id: UserId,
            ) -> impl Future<Output = anyhow::Result<Option<String>>> + Send;
        }
    }

    pub mod session {
        use std::future::Future;

        use crate::upstream::academy_models::{
            session::{Session, SessionId, SessionPatchRef, SessionRefreshTokenHash},
            user::UserId,
        };

        pub trait SessionRepository<Txn: Send + Sync + 'static>: Send + Sync + 'static {
            fn get(&self, txn: &mut Txn, session_id: SessionId) -> impl Future<Output = anyhow::Result<Option<Session>>> + Send;
            fn get_by_refresh_token_hash(
                &self,
                txn: &mut Txn,
                refresh_token_hash: SessionRefreshTokenHash,
            ) -> impl Future<Output = anyhow::Result<Option<Session>>> + Send;
            fn list_by_user(&self, txn: &mut Txn, user_id: UserId) -> impl Future<Output = anyhow::Result<Vec<Session>>> + Send;
            fn create(&self, txn: &mut Txn, session: &Session) -> impl Future<Output = anyhow::Result<()>> + Send;
            fn update<'a>(
                &self,
                txn: &mut Txn,
                session_id: SessionId,
                patch: SessionPatchRef<'a>,
            ) -> impl Future<Output = anyhow::Result<bool>> + Send;
            fn clear_mfa_verified_by_user(&self, txn: &mut Txn, user_id: UserId) -> impl Future<Output = anyhow::Result<()>> + Send;
            fn delete(&self, txn: &mut Txn, session_id: SessionId) -> impl Future<Output = anyhow::Result<bool>> + Send;
            fn delete_by_user(&self, txn: &mut Txn, user_id: UserId) -> impl Future<Output = anyhow::Result<()>> + Send;
            fn list_refresh_token_hashes_by_user(
                &self,
                txn: &mut Txn,
                user_id: UserId,
            ) -> impl Future<Output = anyhow::Result<Vec<SessionRefreshTokenHash>>> + Send;
            fn get_refresh_token_hash(
                &self,
                txn: &mut Txn,
                session_id: SessionId,
            ) -> impl Future<Output = anyhow::Result<Option<SessionRefreshTokenHash>>> + Send;
            fn save_refresh_token_hash(
                &self,
                txn: &mut Txn,
                session_id: SessionId,
                refresh_token_hash: SessionRefreshTokenHash,
            ) -> impl Future<Output = anyhow::Result<()>> + Send;
        }
    }

    pub mod mfa {
        use std::future::Future;

        use crate::upstream::academy_models::{
            mfa::{MfaRecoveryCodeHash, TotpDevice, TotpDeviceId, TotpDevicePatchRef, TotpSecret},
            user::UserId,
        };

        pub trait MfaRepository<Txn: Send + Sync + 'static>: Send + Sync + 'static {
            fn list_totp_devices_by_user(&self, txn: &mut Txn, user_id: UserId) -> impl Future<Output = anyhow::Result<Vec<TotpDevice>>> + Send;
            fn create_totp_device(
                &self,
                txn: &mut Txn,
                totp_device: &TotpDevice,
                secret: &TotpSecret,
            ) -> impl Future<Output = anyhow::Result<()>> + Send;
            fn update_totp_device<'a>(
                &self,
                txn: &mut Txn,
                totp_device_id: TotpDeviceId,
                patch: TotpDevicePatchRef<'a>,
            ) -> impl Future<Output = anyhow::Result<bool>> + Send;
            fn delete_totp_devices_by_user(&self, txn: &mut Txn, user_id: UserId) -> impl Future<Output = anyhow::Result<()>> + Send;
            fn list_enabled_totp_device_secrets_by_user(
                &self,
                txn: &mut Txn,
                user_id: UserId,
            ) -> impl Future<Output = anyhow::Result<Vec<TotpSecret>>> + Send;
            fn get_totp_device_secret(
                &self,
                txn: &mut Txn,
                totp_device_id: TotpDeviceId,
            ) -> impl Future<Output = anyhow::Result<TotpSecret>> + Send;
            fn save_totp_device_secret(
                &self,
                txn: &mut Txn,
                totp_device_id: TotpDeviceId,
                secret: &TotpSecret,
            ) -> impl Future<Output = anyhow::Result<()>> + Send;
            fn get_mfa_recovery_code_hash(
                &self,
                txn: &mut Txn,
                user_id: UserId,
            ) -> impl Future<Output = anyhow::Result<Option<MfaRecoveryCodeHash>>> + Send;
            fn save_mfa_recovery_code_hash(
                &self,
                txn: &mut Txn,
                user_id: UserId,
                recovery_code_hash: MfaRecoveryCodeHash,
            ) -> impl Future<Output = anyhow::Result<()>> + Send;
            fn delete_mfa_recovery_code_hash(&self, txn: &mut Txn, user_id: UserId) -> impl Future<Output = anyhow::Result<()>> + Send;
        }
    }

    pub mod coin {
        use std::future::Future;

        use thiserror::Error;

        use crate::upstream::academy_models::{
            coin::{Balance, Transaction},
            user::UserId,
        };

        pub trait CoinRepository<Txn: Send + Sync + 'static>: Send + Sync + 'static {
            fn get_balance(&self, txn: &mut Txn, user_id: UserId) -> impl Future<Output = anyhow::Result<Balance>> + Send;
            fn add_coins(
                &self,
                txn: &mut Txn,
                user_id: UserId,
                coins: i64,
                withhold: bool,
            ) -> impl Future<Output = Result<Balance, CoinRepoAddCoinsError>> + Send;
            fn create_transaction(&self, txn: &mut Txn, transaction: &Transaction) -> impl Future<Output = anyhow::Result<()>> + Send;
        }

        #[derive(Debug, Error)]
        pub enum CoinRepoAddCoinsError {
            #[error("The user does not have enough coins.")]
            NotEnoughCoins,
            #[error(transparent)]
            Other(#[from] anyhow::Error),
        }
    }

    pub mod heart {
        use std::future::Future;

        use crate::upstream::academy_models::{heart::Hearts, user::UserId};

        pub trait HeartRepository<Txn: Send + Sync + 'static>: Send + Sync + 'static {
            fn get(&self, txn: &mut Txn, user_id: UserId) -> impl Future<Output = anyhow::Result<Option<Hearts>>> + Send;
            fn set(&self, txn: &mut Txn, user_id: UserId, hearts: Hearts) -> impl Future<Output = anyhow::Result<()>> + Send;
        }
    }

    pub mod withdrawal {
        use std::future::Future;

        use crate::upstream::academy_models::withdrawal::WithdrawalConsent;

        pub trait WithdrawalRepository<Txn: Send + Sync + 'static>: Send + Sync + 'static {
            fn create(&self, txn: &mut Txn, consent: &WithdrawalConsent) -> impl Future<Output = anyhow::Result<()>> + Send;
        }
    }
}
