#![allow(dead_code)]
trait Wire { fn wire(&self) -> String; }
macro_rules! scalar { ($($t:ty),*) => {$(impl Wire for $t {fn wire(&self)->String{self.to_string()}})*}; }
scalar!(bool,u8,u16,u32,u64,usize);
impl Wire for String { fn wire(&self)->String {format!("{:?}",self.as_bytes())} }
impl<T:Wire> Wire for Vec<T> { fn wire(&self)->String {format!("[{}]",self.iter().map(Wire::wire).collect::<Vec<_>>().join(","))} }
impl<T:Wire> Wire for Option<T> {fn wire(&self)->String {match self {None=>"null".into(),Some(x)=>x.wire()}}}
mod cache_config_default_a4fe67b2 {
use super::Wire;
pub struct CacheConfig{pub file_ttl_ms:u64,pub directory_ttl_ms:u64,pub max_entries:usize}
impl Default for CacheConfig {
    fn default() -> Self {
        Self {
            file_ttl_ms: 60_000,       // 1 minute
            directory_ttl_ms: 120_000, // 2 minutes
            max_entries: 10_000,       // 10,000 entries
        }
    }
}
pub fn emit() {let x = CacheConfig::default();
println!("cache_config_default_a4fe67b2.file_ttl_ms\t{}",x.file_ttl_ms.wire());
println!("cache_config_default_a4fe67b2.directory_ttl_ms\t{}",x.directory_ttl_ms.wire());
println!("cache_config_default_a4fe67b2.max_entries\t{}",x.max_entries.wire());
}
}
mod timeout_config_default_a4fe67b2 {
use super::Wire;
pub struct TimeoutConfig{pub file_operation_ms:u64,pub dir_operation_ms:u64,pub lock_acquisition_ms:u64,pub network_operation_ms:u64,pub thumbnail_generation_ms:u64}
impl Default for TimeoutConfig {
    fn default() -> Self {
        Self {
            file_operation_ms: 10000,       // 10 seconds
            dir_operation_ms: 30000,        // 30 seconds
            lock_acquisition_ms: 5000,      // 5 seconds
            network_operation_ms: 15000,    // 15 seconds
            thumbnail_generation_ms: 30000, // 30 seconds
        }
    }
}
pub fn emit() {let x = TimeoutConfig::default();
println!("timeout_config_default_a4fe67b2.file_operation_ms\t{}",x.file_operation_ms.wire());
println!("timeout_config_default_a4fe67b2.dir_operation_ms\t{}",x.dir_operation_ms.wire());
println!("timeout_config_default_a4fe67b2.lock_acquisition_ms\t{}",x.lock_acquisition_ms.wire());
println!("timeout_config_default_a4fe67b2.network_operation_ms\t{}",x.network_operation_ms.wire());
println!("timeout_config_default_a4fe67b2.thumbnail_generation_ms\t{}",x.thumbnail_generation_ms.wire());
}
}
mod resource_config_default_a4fe67b2 {
use super::Wire;
pub struct ResourceConfig{pub large_file_threshold_mb:u64,pub large_dir_threshold_entries:usize,pub chunk_size_bytes:usize,pub max_in_memory_file_size_mb:u64}
impl Default for ResourceConfig {
    fn default() -> Self {
        Self {
            large_file_threshold_mb: 100,      // 100 MB
            large_dir_threshold_entries: 1000, // 1000 entries
            chunk_size_bytes: 1024 * 1024,     // 1 MB
            max_in_memory_file_size_mb: 50,    // 50 MB
        }
    }
}
pub fn emit() {let x = ResourceConfig::default();
println!("resource_config_default_a4fe67b2.large_file_threshold_mb\t{}",x.large_file_threshold_mb.wire());
println!("resource_config_default_a4fe67b2.large_dir_threshold_entries\t{}",x.large_dir_threshold_entries.wire());
println!("resource_config_default_a4fe67b2.chunk_size_bytes\t{}",x.chunk_size_bytes.wire());
println!("resource_config_default_a4fe67b2.max_in_memory_file_size_mb\t{}",x.max_in_memory_file_size_mb.wire());
}
}
mod concurrency_config_default_a4fe67b2 {
use super::Wire;
pub struct ConcurrencyConfig{pub max_concurrent_files:usize,pub max_concurrent_dirs:usize,pub max_concurrent_io:usize,pub max_parallel_chunks:usize,pub min_size_for_parallel_chunks_mb:u64,pub parallel_chunk_size_bytes:usize}
impl Default for ConcurrencyConfig {
    fn default() -> Self {
        Self {
            max_concurrent_files: 10,
            max_concurrent_dirs: 5,
            max_concurrent_io: 20,
            max_parallel_chunks: 8,
            min_size_for_parallel_chunks_mb: 200,       // 200 MB
            parallel_chunk_size_bytes: 8 * 1024 * 1024, // 8 MB
        }
    }
}
pub fn emit() {let x = ConcurrencyConfig::default();
println!("concurrency_config_default_a4fe67b2.max_concurrent_files\t{}",x.max_concurrent_files.wire());
println!("concurrency_config_default_a4fe67b2.max_concurrent_dirs\t{}",x.max_concurrent_dirs.wire());
println!("concurrency_config_default_a4fe67b2.max_concurrent_io\t{}",x.max_concurrent_io.wire());
println!("concurrency_config_default_a4fe67b2.max_parallel_chunks\t{}",x.max_parallel_chunks.wire());
println!("concurrency_config_default_a4fe67b2.min_size_for_parallel_chunks_mb\t{}",x.min_size_for_parallel_chunks_mb.wire());
println!("concurrency_config_default_a4fe67b2.parallel_chunk_size_bytes\t{}",x.parallel_chunk_size_bytes.wire());
}
}
mod blob_cache_config_default_a4fe67b2 {
use super::Wire;
pub struct BlobCacheConfig{pub enabled:bool,pub max_size_bytes:u64,pub cache_path:Option<String>}
impl Default for BlobCacheConfig {
    fn default() -> Self {
        Self {
            enabled: false,
            max_size_bytes: 50 * 1024 * 1024 * 1024, // 50 GB
            cache_path: None,
        }
    }
}
pub fn emit() {let x = BlobCacheConfig::default();
println!("blob_cache_config_default_a4fe67b2.enabled\t{}",x.enabled.wire());
println!("blob_cache_config_default_a4fe67b2.max_size_bytes\t{}",x.max_size_bytes.wire());
println!("blob_cache_config_default_a4fe67b2.cache_path\t{}",x.cache_path.wire());
}
}
mod encryption_config_default_a4fe67b2 {
use super::Wire;
pub struct EncryptionConfig{pub enabled:bool,pub key_base64:Option<String>}
impl Default for EncryptionConfig {
    #[allow(clippy::derivable_impls)]
    fn default() -> Self {
        Self {
            enabled: false,
            key_base64: None,
        }
    }
}
pub fn emit() {let x = EncryptionConfig::default();
println!("encryption_config_default_a4fe67b2.enabled\t{}",x.enabled.wire());
println!("encryption_config_default_a4fe67b2.key_base64\t{}",x.key_base64.wire());
}
}
mod database_config_default_a4fe67b2 {
use super::Wire;
pub struct DatabaseConfig{pub connection_string:String,pub max_connections:u32,pub min_connections:u32,pub connect_timeout_secs:u64,pub idle_timeout_secs:u64,pub max_lifetime_secs:u64,pub maintenance_max_connections:u32,pub maintenance_min_connections:u32,pub statement_timeout_secs:u64,pub pool_monitor_interval_secs:u64}
impl Default for DatabaseConfig {
    fn default() -> Self {
        Self {
            // Updated connection string with default credentials that PostgreSQL often uses
            connection_string: "postgres://postgres:postgres@localhost:5432/oxicloud".to_string(),
            max_connections: 20,
            min_connections: 5,
            connect_timeout_secs: 10,
            idle_timeout_secs: 300,
            max_lifetime_secs: 1800,
            maintenance_max_connections: 5,
            maintenance_min_connections: 1,
            statement_timeout_secs: 30,
            pool_monitor_interval_secs: 30,
        }
    }
}
pub fn emit() {let x = DatabaseConfig::default();
println!("database_config_default_a4fe67b2.connection_string\t{}",x.connection_string.wire());
println!("database_config_default_a4fe67b2.max_connections\t{}",x.max_connections.wire());
println!("database_config_default_a4fe67b2.min_connections\t{}",x.min_connections.wire());
println!("database_config_default_a4fe67b2.connect_timeout_secs\t{}",x.connect_timeout_secs.wire());
println!("database_config_default_a4fe67b2.idle_timeout_secs\t{}",x.idle_timeout_secs.wire());
println!("database_config_default_a4fe67b2.max_lifetime_secs\t{}",x.max_lifetime_secs.wire());
println!("database_config_default_a4fe67b2.maintenance_max_connections\t{}",x.maintenance_max_connections.wire());
println!("database_config_default_a4fe67b2.maintenance_min_connections\t{}",x.maintenance_min_connections.wire());
println!("database_config_default_a4fe67b2.statement_timeout_secs\t{}",x.statement_timeout_secs.wire());
println!("database_config_default_a4fe67b2.pool_monitor_interval_secs\t{}",x.pool_monitor_interval_secs.wire());
}
}
mod rate_limit_config_default_a4fe67b2 {
use super::Wire;
pub struct RateLimitConfig{pub login_max_requests:u32,pub login_window_secs:u64,pub register_max_requests:u32,pub register_window_secs:u64,pub refresh_max_requests:u32,pub refresh_window_secs:u64,pub lockout_max_failures:u32,pub lockout_duration_secs:u64,pub user_profile_max_requests:u32,pub user_profile_window_secs:u64,pub delta_upload_max_requests:u32,pub delta_upload_window_secs:u64}
impl Default for RateLimitConfig {
    fn default() -> Self {
        Self {
            login_max_requests: 10,
            login_window_secs: 60,
            register_max_requests: 5,
            register_window_secs: 3600,
            refresh_max_requests: 20,
            refresh_window_secs: 60,
            lockout_max_failures: 5,
            lockout_duration_secs: 900,
            // Unchanged from the literals these replaced in `di.rs`, so
            // an operator who sets nothing sees no behaviour change.
            user_profile_max_requests: 60,
            user_profile_window_secs: 60,
            delta_upload_max_requests: 240,
            delta_upload_window_secs: 60,
        }
    }
}
pub fn emit() {let x = RateLimitConfig::default();
println!("rate_limit_config_default_a4fe67b2.login_max_requests\t{}",x.login_max_requests.wire());
println!("rate_limit_config_default_a4fe67b2.login_window_secs\t{}",x.login_window_secs.wire());
println!("rate_limit_config_default_a4fe67b2.register_max_requests\t{}",x.register_max_requests.wire());
println!("rate_limit_config_default_a4fe67b2.register_window_secs\t{}",x.register_window_secs.wire());
println!("rate_limit_config_default_a4fe67b2.refresh_max_requests\t{}",x.refresh_max_requests.wire());
println!("rate_limit_config_default_a4fe67b2.refresh_window_secs\t{}",x.refresh_window_secs.wire());
println!("rate_limit_config_default_a4fe67b2.lockout_max_failures\t{}",x.lockout_max_failures.wire());
println!("rate_limit_config_default_a4fe67b2.lockout_duration_secs\t{}",x.lockout_duration_secs.wire());
println!("rate_limit_config_default_a4fe67b2.user_profile_max_requests\t{}",x.user_profile_max_requests.wire());
println!("rate_limit_config_default_a4fe67b2.user_profile_window_secs\t{}",x.user_profile_window_secs.wire());
println!("rate_limit_config_default_a4fe67b2.delta_upload_max_requests\t{}",x.delta_upload_max_requests.wire());
println!("rate_limit_config_default_a4fe67b2.delta_upload_window_secs\t{}",x.delta_upload_window_secs.wire());
}
}
mod oidc_config_default_a4fe67b2 {
use super::Wire;
pub struct OidcConfig{pub enabled:bool,pub issuer_url:String,pub client_id:String,pub client_secret:String,pub redirect_uri:String,pub scopes:String,pub frontend_url:String,pub auto_provision:bool,pub admin_groups:String,pub disable_password_login:bool,pub provider_name:String,pub auto_link_email_match:bool}
impl Default for OidcConfig {
    fn default() -> Self {
        Self {
            enabled: false,
            issuer_url: String::new(),
            client_id: String::new(),
            client_secret: String::new(),
            redirect_uri: "http://localhost:8086/api/auth/oidc/callback".to_string(),
            scopes: "openid profile email".to_string(),
            frontend_url: "http://localhost:8086".to_string(),
            auto_provision: true,
            admin_groups: String::new(),
            disable_password_login: false,
            provider_name: "SSO".to_string(),
            auto_link_email_match: true,
        }
    }
}
pub fn emit() {let x = OidcConfig::default();
println!("oidc_config_default_a4fe67b2.enabled\t{}",x.enabled.wire());
println!("oidc_config_default_a4fe67b2.issuer_url\t{}",x.issuer_url.wire());
println!("oidc_config_default_a4fe67b2.client_id\t{}",x.client_id.wire());
println!("oidc_config_default_a4fe67b2.client_secret\t{}",x.client_secret.wire());
println!("oidc_config_default_a4fe67b2.redirect_uri\t{}",x.redirect_uri.wire());
println!("oidc_config_default_a4fe67b2.scopes\t{}",x.scopes.wire());
println!("oidc_config_default_a4fe67b2.frontend_url\t{}",x.frontend_url.wire());
println!("oidc_config_default_a4fe67b2.auto_provision\t{}",x.auto_provision.wire());
println!("oidc_config_default_a4fe67b2.admin_groups\t{}",x.admin_groups.wire());
println!("oidc_config_default_a4fe67b2.disable_password_login\t{}",x.disable_password_login.wire());
println!("oidc_config_default_a4fe67b2.provider_name\t{}",x.provider_name.wire());
println!("oidc_config_default_a4fe67b2.auto_link_email_match\t{}",x.auto_link_email_match.wire());
}
}
mod smtp_config_default_a4fe67b2 {
use super::Wire;
pub enum SmtpTlsMode {Starttls,Tls,None}
impl Wire for SmtpTlsMode {fn wire(&self)->String {match self {Self::Starttls=>"\"Starttls\"".into(),Self::Tls=>"\"Tls\"".into(),Self::None=>"\"None\"".into()}}}
pub struct SmtpConfig{pub host:String,pub port:u16,pub user:String,pub pass:String,pub from:String,pub tls:SmtpTlsMode,pub mock:bool}
impl Default for SmtpConfig {
    fn default() -> Self {
        Self {
            host: String::new(),
            port: 587,
            user: String::new(),
            pass: String::new(),
            from: String::new(),
            tls: SmtpTlsMode::Starttls,
            mock: false,
        }
    }
}
pub fn emit() {let x = SmtpConfig::default();
println!("smtp_config_default_a4fe67b2.host\t{}",x.host.wire());
println!("smtp_config_default_a4fe67b2.port\t{}",x.port.wire());
println!("smtp_config_default_a4fe67b2.user\t{}",x.user.wire());
println!("smtp_config_default_a4fe67b2.pass\t{}",x.pass.wire());
println!("smtp_config_default_a4fe67b2.from\t{}",x.from.wire());
println!("smtp_config_default_a4fe67b2.tls\t{}",x.tls.wire());
println!("smtp_config_default_a4fe67b2.mock\t{}",x.mock.wire());
}
}
mod magic_link_config_default_a4fe67b2 {
use super::Wire;
pub struct MagicLinkConfig{pub login_ttl_minutes:u64,pub invite_ttl_hours:u64,pub allow_external_users:bool,pub allowed_email_domains:Vec<String>,pub invite_per_caller_per_hour:u32,pub send_per_email_per_hour:u32,pub send_per_ip_per_hour:u32,pub open_to_password_users:bool,pub notify_internal_users_on_share:bool}
impl Default for MagicLinkConfig {
    fn default() -> Self {
        Self {
            login_ttl_minutes: 10,
            invite_ttl_hours: 24,
            allow_external_users: true,
            allowed_email_domains: Vec::new(),
            invite_per_caller_per_hour: 50,
            send_per_email_per_hour: 5,
            send_per_ip_per_hour: 200,
            open_to_password_users: false,
            notify_internal_users_on_share: true,
        }
    }
}
pub fn emit() {let x = MagicLinkConfig::default();
println!("magic_link_config_default_a4fe67b2.login_ttl_minutes\t{}",x.login_ttl_minutes.wire());
println!("magic_link_config_default_a4fe67b2.invite_ttl_hours\t{}",x.invite_ttl_hours.wire());
println!("magic_link_config_default_a4fe67b2.allow_external_users\t{}",x.allow_external_users.wire());
println!("magic_link_config_default_a4fe67b2.allowed_email_domains\t{}",x.allowed_email_domains.wire());
println!("magic_link_config_default_a4fe67b2.invite_per_caller_per_hour\t{}",x.invite_per_caller_per_hour.wire());
println!("magic_link_config_default_a4fe67b2.send_per_email_per_hour\t{}",x.send_per_email_per_hour.wire());
println!("magic_link_config_default_a4fe67b2.send_per_ip_per_hour\t{}",x.send_per_ip_per_hour.wire());
println!("magic_link_config_default_a4fe67b2.open_to_password_users\t{}",x.open_to_password_users.wire());
println!("magic_link_config_default_a4fe67b2.notify_internal_users_on_share\t{}",x.notify_internal_users_on_share.wire());
}
}
mod grant_cleanup_config_default_a4fe67b2 {
use super::Wire;
pub struct GrantCleanupConfig{pub enabled:bool,pub grace_days:u32,pub interval_hours:u64}
impl Default for GrantCleanupConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            grace_days: 15,
            interval_hours: 24,
        }
    }
}
pub fn emit() {let x = GrantCleanupConfig::default();
println!("grant_cleanup_config_default_a4fe67b2.enabled\t{}",x.enabled.wire());
println!("grant_cleanup_config_default_a4fe67b2.grace_days\t{}",x.grace_days.wire());
println!("grant_cleanup_config_default_a4fe67b2.interval_hours\t{}",x.interval_hours.wire());
}
}
mod search_cache_config_default_a4fe67b2 {
use super::Wire;
pub struct SearchCacheConfig{pub max_bytes:u64}
impl Default for SearchCacheConfig {
    fn default() -> Self {
        Self {
            max_bytes: 32 * 1024 * 1024,
        }
    }
}
pub fn emit() {let x = SearchCacheConfig::default();
println!("search_cache_config_default_a4fe67b2.max_bytes\t{}",x.max_bytes.wire());
}
}
mod i18n_config_default_a4fe67b2 {
use super::Wire;
pub struct I18nConfig{pub default_locale:String}
impl Default for I18nConfig {
    fn default() -> Self {
        Self {
            default_locale: "en".to_string(),
        }
    }
}
pub fn emit() {let x = I18nConfig::default();
println!("i18n_config_default_a4fe67b2.default_locale\t{}",x.default_locale.wire());
}
}
mod video_thumbnail_config_default_a4fe67b2 {
use super::Wire;
pub struct VideoThumbnailConfig{pub ffmpeg_path:String,pub concurrency:Option<usize>,pub timeout_secs:u64,pub max_mb:u64}
impl Default for VideoThumbnailConfig {
    fn default() -> Self {
        Self {
            ffmpeg_path: "ffmpeg".to_string(),
            concurrency: None,
            timeout_secs: 30,
            max_mb: 2048,
        }
    }
}
pub fn emit() {let x = VideoThumbnailConfig::default();
println!("video_thumbnail_config_default_a4fe67b2.ffmpeg_path\t{}",x.ffmpeg_path.wire());
println!("video_thumbnail_config_default_a4fe67b2.concurrency\t{}",x.concurrency.wire());
println!("video_thumbnail_config_default_a4fe67b2.timeout_secs\t{}",x.timeout_secs.wire());
println!("video_thumbnail_config_default_a4fe67b2.max_mb\t{}",x.max_mb.wire());
}
}
mod file_content_cache_config_default_28be87aa {
use super::Wire;
pub struct FileContentCacheConfig{pub max_file_size:usize,pub max_total_size:usize,pub max_entries:usize}
impl Default for FileContentCacheConfig {
    fn default() -> Self {
        Self {
            max_file_size: 10 * 1024 * 1024,   // 10MB max per file
            max_total_size: 512 * 1024 * 1024, // 512MB total cache
            max_entries: 10000,                // Max 10k files
        }
    }
}
pub fn emit() {let x = FileContentCacheConfig::default();
println!("file_content_cache_config_default_28be87aa.max_file_size\t{}",x.max_file_size.wire());
println!("file_content_cache_config_default_28be87aa.max_total_size\t{}",x.max_total_size.wire());
println!("file_content_cache_config_default_28be87aa.max_entries\t{}",x.max_entries.wire());
}
}
fn main(){cache_config_default_a4fe67b2::emit();timeout_config_default_a4fe67b2::emit();resource_config_default_a4fe67b2::emit();concurrency_config_default_a4fe67b2::emit();blob_cache_config_default_a4fe67b2::emit();encryption_config_default_a4fe67b2::emit();database_config_default_a4fe67b2::emit();rate_limit_config_default_a4fe67b2::emit();oidc_config_default_a4fe67b2::emit();smtp_config_default_a4fe67b2::emit();magic_link_config_default_a4fe67b2::emit();grant_cleanup_config_default_a4fe67b2::emit();search_cache_config_default_a4fe67b2::emit();i18n_config_default_a4fe67b2::emit();video_thumbnail_config_default_a4fe67b2::emit();file_content_cache_config_default_28be87aa::emit();}
