//! Complete closed defaults; String fields preserve their UTF-8 bytes.
pub mod cache_config_default_a4fe67b2 {
pub struct CacheConfig{pub file_ttl_ms:u64,pub directory_ttl_ms:u64,pub max_entries:usize}
pub fn make() -> CacheConfig { CacheConfig {file_ttl_ms: 60_000,directory_ttl_ms: 120_000,max_entries: 10_000} }
}
pub mod timeout_config_default_a4fe67b2 {
pub struct TimeoutConfig{pub file_operation_ms:u64,pub dir_operation_ms:u64,pub lock_acquisition_ms:u64,pub network_operation_ms:u64,pub thumbnail_generation_ms:u64}
pub fn make() -> TimeoutConfig { TimeoutConfig {file_operation_ms: 10000,dir_operation_ms: 30000,lock_acquisition_ms: 5000,network_operation_ms: 15000,thumbnail_generation_ms: 30000} }
}
pub mod resource_config_default_a4fe67b2 {
pub struct ResourceConfig{pub large_file_threshold_mb:u64,pub large_dir_threshold_entries:usize,pub chunk_size_bytes:usize,pub max_in_memory_file_size_mb:u64}
pub fn make() -> ResourceConfig { ResourceConfig {large_file_threshold_mb: 100,large_dir_threshold_entries: 1000,chunk_size_bytes: 1024 * 1024,max_in_memory_file_size_mb: 50} }
}
pub mod concurrency_config_default_a4fe67b2 {
pub struct ConcurrencyConfig{pub max_concurrent_files:usize,pub max_concurrent_dirs:usize,pub max_concurrent_io:usize,pub max_parallel_chunks:usize,pub min_size_for_parallel_chunks_mb:u64,pub parallel_chunk_size_bytes:usize}
pub fn make() -> ConcurrencyConfig { ConcurrencyConfig {max_concurrent_files: 10,max_concurrent_dirs: 5,max_concurrent_io: 20,max_parallel_chunks: 8,min_size_for_parallel_chunks_mb: 200,parallel_chunk_size_bytes: 8 * 1024 * 1024} }
}
pub mod blob_cache_config_default_a4fe67b2 {
pub struct BlobCacheConfig{pub enabled:bool,pub max_size_bytes:u64,pub cache_path:Option<Vec<u8>>}
pub fn make() -> BlobCacheConfig { BlobCacheConfig {enabled: false,max_size_bytes: 50 * 1024 * 1024 * 1024,cache_path: None} }
}
pub mod encryption_config_default_a4fe67b2 {
pub struct EncryptionConfig{pub enabled:bool,pub key_base64:Option<Vec<u8>>}
pub fn make() -> EncryptionConfig { EncryptionConfig {enabled: false,key_base64: None} }
}
pub mod database_config_default_a4fe67b2 {
pub struct DatabaseConfig{pub connection_string:Vec<u8>,pub max_connections:u32,pub min_connections:u32,pub connect_timeout_secs:u64,pub idle_timeout_secs:u64,pub max_lifetime_secs:u64,pub maintenance_max_connections:u32,pub maintenance_min_connections:u32,pub statement_timeout_secs:u64,pub pool_monitor_interval_secs:u64}
pub fn make() -> DatabaseConfig { DatabaseConfig {connection_string: b"postgres://postgres:postgres@localhost:5432/oxicloud".to_vec(),max_connections: 20,min_connections: 5,connect_timeout_secs: 10,idle_timeout_secs: 300,max_lifetime_secs: 1800,maintenance_max_connections: 5,maintenance_min_connections: 1,statement_timeout_secs: 30,pool_monitor_interval_secs: 30} }
}
pub mod rate_limit_config_default_a4fe67b2 {
pub struct RateLimitConfig{pub login_max_requests:u32,pub login_window_secs:u64,pub register_max_requests:u32,pub register_window_secs:u64,pub refresh_max_requests:u32,pub refresh_window_secs:u64,pub lockout_max_failures:u32,pub lockout_duration_secs:u64,pub user_profile_max_requests:u32,pub user_profile_window_secs:u64,pub delta_upload_max_requests:u32,pub delta_upload_window_secs:u64}
pub fn make() -> RateLimitConfig { RateLimitConfig {login_max_requests: 10,login_window_secs: 60,register_max_requests: 5,register_window_secs: 3600,refresh_max_requests: 20,refresh_window_secs: 60,lockout_max_failures: 5,lockout_duration_secs: 900,user_profile_max_requests: 60,user_profile_window_secs: 60,delta_upload_max_requests: 240,delta_upload_window_secs: 60} }
}
pub mod oidc_config_default_a4fe67b2 {
pub struct OidcConfig{pub enabled:bool,pub issuer_url:Vec<u8>,pub client_id:Vec<u8>,pub client_secret:Vec<u8>,pub redirect_uri:Vec<u8>,pub scopes:Vec<u8>,pub frontend_url:Vec<u8>,pub auto_provision:bool,pub admin_groups:Vec<u8>,pub disable_password_login:bool,pub provider_name:Vec<u8>,pub auto_link_email_match:bool}
pub fn make() -> OidcConfig { OidcConfig {enabled: false,issuer_url: Vec::new(),client_id: Vec::new(),client_secret: Vec::new(),redirect_uri: b"http://localhost:8086/api/auth/oidc/callback".to_vec(),scopes: b"openid profile email".to_vec(),frontend_url: b"http://localhost:8086".to_vec(),auto_provision: true,admin_groups: Vec::new(),disable_password_login: false,provider_name: b"SSO".to_vec(),auto_link_email_match: true} }
}
pub mod smtp_config_default_a4fe67b2 {
pub enum SmtpTlsMode {Starttls,Tls,None}
pub struct SmtpConfig{pub host:Vec<u8>,pub port:u16,pub user:Vec<u8>,pub pass:Vec<u8>,pub from:Vec<u8>,pub tls:SmtpTlsMode,pub mock:bool}
pub fn make() -> SmtpConfig { SmtpConfig {host: Vec::new(),port: 587,user: Vec::new(),pass: Vec::new(),from: Vec::new(),tls: SmtpTlsMode::Starttls,mock: false} }
}
pub mod magic_link_config_default_a4fe67b2 {
pub struct MagicLinkConfig{pub login_ttl_minutes:u64,pub invite_ttl_hours:u64,pub allow_external_users:bool,pub allowed_email_domains:Vec<Vec<u8>>,pub invite_per_caller_per_hour:u32,pub send_per_email_per_hour:u32,pub send_per_ip_per_hour:u32,pub open_to_password_users:bool,pub notify_internal_users_on_share:bool}
pub fn make() -> MagicLinkConfig { MagicLinkConfig {login_ttl_minutes: 10,invite_ttl_hours: 24,allow_external_users: true,allowed_email_domains: Vec::new(),invite_per_caller_per_hour: 50,send_per_email_per_hour: 5,send_per_ip_per_hour: 200,open_to_password_users: false,notify_internal_users_on_share: true} }
}
pub mod grant_cleanup_config_default_a4fe67b2 {
pub struct GrantCleanupConfig{pub enabled:bool,pub grace_days:u32,pub interval_hours:u64}
pub fn make() -> GrantCleanupConfig { GrantCleanupConfig {enabled: true,grace_days: 15,interval_hours: 24} }
}
pub mod search_cache_config_default_a4fe67b2 {
pub struct SearchCacheConfig{pub max_bytes:u64}
pub fn make() -> SearchCacheConfig { SearchCacheConfig {max_bytes: 32 * 1024 * 1024} }
}
pub mod i18n_config_default_a4fe67b2 {
pub struct I18nConfig{pub default_locale:Vec<u8>}
pub fn make() -> I18nConfig { I18nConfig {default_locale: b"en".to_vec()} }
}
pub mod video_thumbnail_config_default_a4fe67b2 {
pub struct VideoThumbnailConfig{pub ffmpeg_path:Vec<u8>,pub concurrency:Option<usize>,pub timeout_secs:u64,pub max_mb:u64}
pub fn make() -> VideoThumbnailConfig { VideoThumbnailConfig {ffmpeg_path: b"ffmpeg".to_vec(),concurrency: None,timeout_secs: 30,max_mb: 2048} }
}
pub mod file_content_cache_config_default_28be87aa {
pub struct FileContentCacheConfig{pub max_file_size:usize,pub max_total_size:usize,pub max_entries:usize}
pub fn make() -> FileContentCacheConfig { FileContentCacheConfig {max_file_size: 10 * 1024 * 1024,max_total_size: 512 * 1024 * 1024,max_entries: 10000} }
}
