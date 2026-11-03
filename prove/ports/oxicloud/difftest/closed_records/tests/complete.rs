#[path="../../../kernel/src/closed_records.rs"]
mod kernel;
#[test]
fn cache_config_default_a4fe67b2_complete() {let r=kernel::cache_config_default_a4fe67b2::make();
assert_eq!(r.file_ttl_ms,60000);
assert_eq!(r.directory_ttl_ms,120000);
assert_eq!(r.max_entries,10000);
}
#[test]
fn timeout_config_default_a4fe67b2_complete() {let r=kernel::timeout_config_default_a4fe67b2::make();
assert_eq!(r.file_operation_ms,10000);
assert_eq!(r.dir_operation_ms,30000);
assert_eq!(r.lock_acquisition_ms,5000);
assert_eq!(r.network_operation_ms,15000);
assert_eq!(r.thumbnail_generation_ms,30000);
}
#[test]
fn resource_config_default_a4fe67b2_complete() {let r=kernel::resource_config_default_a4fe67b2::make();
assert_eq!(r.large_file_threshold_mb,100);
assert_eq!(r.large_dir_threshold_entries,1000);
assert_eq!(r.chunk_size_bytes,1048576);
assert_eq!(r.max_in_memory_file_size_mb,50);
}
#[test]
fn concurrency_config_default_a4fe67b2_complete() {let r=kernel::concurrency_config_default_a4fe67b2::make();
assert_eq!(r.max_concurrent_files,10);
assert_eq!(r.max_concurrent_dirs,5);
assert_eq!(r.max_concurrent_io,20);
assert_eq!(r.max_parallel_chunks,8);
assert_eq!(r.min_size_for_parallel_chunks_mb,200);
assert_eq!(r.parallel_chunk_size_bytes,8388608);
}
#[test]
fn blob_cache_config_default_a4fe67b2_complete() {let r=kernel::blob_cache_config_default_a4fe67b2::make();
assert_eq!(r.enabled,false);
assert_eq!(r.max_size_bytes,53687091200);
assert!(r.cache_path.is_none());
}
#[test]
fn encryption_config_default_a4fe67b2_complete() {let r=kernel::encryption_config_default_a4fe67b2::make();
assert_eq!(r.enabled,false);
assert!(r.key_base64.is_none());
}
#[test]
fn database_config_default_a4fe67b2_complete() {let r=kernel::database_config_default_a4fe67b2::make();
assert_eq!(r.connection_string,&[112u8,111u8,115u8,116u8,103u8,114u8,101u8,115u8,58u8,47u8,47u8,112u8,111u8,115u8,116u8,103u8,114u8,101u8,115u8,58u8,112u8,111u8,115u8,116u8,103u8,114u8,101u8,115u8,64u8,108u8,111u8,99u8,97u8,108u8,104u8,111u8,115u8,116u8,58u8,53u8,52u8,51u8,50u8,47u8,111u8,120u8,105u8,99u8,108u8,111u8,117u8,100u8]);
assert_eq!(r.max_connections,20);
assert_eq!(r.min_connections,5);
assert_eq!(r.connect_timeout_secs,10);
assert_eq!(r.idle_timeout_secs,300);
assert_eq!(r.max_lifetime_secs,1800);
assert_eq!(r.maintenance_max_connections,5);
assert_eq!(r.maintenance_min_connections,1);
assert_eq!(r.statement_timeout_secs,30);
assert_eq!(r.pool_monitor_interval_secs,30);
}
#[test]
fn rate_limit_config_default_a4fe67b2_complete() {let r=kernel::rate_limit_config_default_a4fe67b2::make();
assert_eq!(r.login_max_requests,10);
assert_eq!(r.login_window_secs,60);
assert_eq!(r.register_max_requests,5);
assert_eq!(r.register_window_secs,3600);
assert_eq!(r.refresh_max_requests,20);
assert_eq!(r.refresh_window_secs,60);
assert_eq!(r.lockout_max_failures,5);
assert_eq!(r.lockout_duration_secs,900);
assert_eq!(r.user_profile_max_requests,60);
assert_eq!(r.user_profile_window_secs,60);
assert_eq!(r.delta_upload_max_requests,240);
assert_eq!(r.delta_upload_window_secs,60);
}
#[test]
fn oidc_config_default_a4fe67b2_complete() {let r=kernel::oidc_config_default_a4fe67b2::make();
assert_eq!(r.enabled,false);
assert_eq!(r.issuer_url,&[]);
assert_eq!(r.client_id,&[]);
assert_eq!(r.client_secret,&[]);
assert_eq!(r.redirect_uri,&[104u8,116u8,116u8,112u8,58u8,47u8,47u8,108u8,111u8,99u8,97u8,108u8,104u8,111u8,115u8,116u8,58u8,56u8,48u8,56u8,54u8,47u8,97u8,112u8,105u8,47u8,97u8,117u8,116u8,104u8,47u8,111u8,105u8,100u8,99u8,47u8,99u8,97u8,108u8,108u8,98u8,97u8,99u8,107u8]);
assert_eq!(r.scopes,&[111u8,112u8,101u8,110u8,105u8,100u8,32u8,112u8,114u8,111u8,102u8,105u8,108u8,101u8,32u8,101u8,109u8,97u8,105u8,108u8]);
assert_eq!(r.frontend_url,&[104u8,116u8,116u8,112u8,58u8,47u8,47u8,108u8,111u8,99u8,97u8,108u8,104u8,111u8,115u8,116u8,58u8,56u8,48u8,56u8,54u8]);
assert_eq!(r.auto_provision,true);
assert_eq!(r.admin_groups,&[]);
assert_eq!(r.disable_password_login,false);
assert_eq!(r.provider_name,&[83u8,83u8,79u8]);
assert_eq!(r.auto_link_email_match,true);
}
#[test]
fn smtp_config_default_a4fe67b2_complete() {let r=kernel::smtp_config_default_a4fe67b2::make();
assert_eq!(r.host,&[]);
assert_eq!(r.port,587);
assert_eq!(r.user,&[]);
assert_eq!(r.pass,&[]);
assert_eq!(r.from,&[]);
assert!(matches!(r.tls,kernel::smtp_config_default_a4fe67b2::SmtpTlsMode::Starttls));
assert_eq!(r.mock,false);
}
#[test]
fn magic_link_config_default_a4fe67b2_complete() {let r=kernel::magic_link_config_default_a4fe67b2::make();
assert_eq!(r.login_ttl_minutes,10);
assert_eq!(r.invite_ttl_hours,24);
assert_eq!(r.allow_external_users,true);
assert!(r.allowed_email_domains.is_empty());
assert_eq!(r.invite_per_caller_per_hour,50);
assert_eq!(r.send_per_email_per_hour,5);
assert_eq!(r.send_per_ip_per_hour,200);
assert_eq!(r.open_to_password_users,false);
assert_eq!(r.notify_internal_users_on_share,true);
}
#[test]
fn grant_cleanup_config_default_a4fe67b2_complete() {let r=kernel::grant_cleanup_config_default_a4fe67b2::make();
assert_eq!(r.enabled,true);
assert_eq!(r.grace_days,15);
assert_eq!(r.interval_hours,24);
}
#[test]
fn search_cache_config_default_a4fe67b2_complete() {let r=kernel::search_cache_config_default_a4fe67b2::make();
assert_eq!(r.max_bytes,33554432);
}
#[test]
fn i18n_config_default_a4fe67b2_complete() {let r=kernel::i18n_config_default_a4fe67b2::make();
assert_eq!(r.default_locale,&[101u8,110u8]);
}
#[test]
fn video_thumbnail_config_default_a4fe67b2_complete() {let r=kernel::video_thumbnail_config_default_a4fe67b2::make();
assert_eq!(r.ffmpeg_path,&[102u8,102u8,109u8,112u8,101u8,103u8]);
assert!(r.concurrency.is_none());
assert_eq!(r.timeout_secs,30);
assert_eq!(r.max_mb,2048);
}
#[test]
fn file_content_cache_config_default_28be87aa_complete() {let r=kernel::file_content_cache_config_default_28be87aa::make();
assert_eq!(r.max_file_size,10485760);
assert_eq!(r.max_total_size,536870912);
assert_eq!(r.max_entries,10000);
}
