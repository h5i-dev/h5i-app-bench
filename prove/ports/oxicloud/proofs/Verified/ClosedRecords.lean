import OxicloudKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.ClosedRecords
set_option maxHeartbeats 1000000
@[step] theorem bytes_to_vec (s : Slice U8) :
    alloc.slice.Slice.to_vec core.clone.CloneU8 s ⦃r => r.val = s.val⦄ := by
  apply WP.spec_mono (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 s (by intros; rfl))
  intro r hr
  exact (congrArg Slice.val hr).symm

@[step] theorem cache_config_default_a4fe67b2_complete :
    closed_records.cache_config_default_a4fe67b2.make ⦃r => r.file_ttl_ms.val = 60000 ∧
      r.directory_ttl_ms.val = 120000 ∧
      r.max_entries.val = 10000⦄ := by
  unfold closed_records.cache_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem timeout_config_default_a4fe67b2_complete :
    closed_records.timeout_config_default_a4fe67b2.make ⦃r => r.file_operation_ms.val = 10000 ∧
      r.dir_operation_ms.val = 30000 ∧
      r.lock_acquisition_ms.val = 5000 ∧
      r.network_operation_ms.val = 15000 ∧
      r.thumbnail_generation_ms.val = 30000⦄ := by
  unfold closed_records.timeout_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem resource_config_default_a4fe67b2_complete :
    closed_records.resource_config_default_a4fe67b2.make ⦃r => r.large_file_threshold_mb.val = 100 ∧
      r.large_dir_threshold_entries.val = 1000 ∧
      r.chunk_size_bytes.val = 1048576 ∧
      r.max_in_memory_file_size_mb.val = 50⦄ := by
  unfold closed_records.resource_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem concurrency_config_default_a4fe67b2_complete :
    closed_records.concurrency_config_default_a4fe67b2.make ⦃r => r.max_concurrent_files.val = 10 ∧
      r.max_concurrent_dirs.val = 5 ∧
      r.max_concurrent_io.val = 20 ∧
      r.max_parallel_chunks.val = 8 ∧
      r.min_size_for_parallel_chunks_mb.val = 200 ∧
      r.parallel_chunk_size_bytes.val = 8388608⦄ := by
  unfold closed_records.concurrency_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem blob_cache_config_default_a4fe67b2_complete :
    closed_records.blob_cache_config_default_a4fe67b2.make ⦃r => r.enabled = false ∧
      r.max_size_bytes.val = 53687091200 ∧
      r.cache_path = none⦄ := by
  unfold closed_records.blob_cache_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem encryption_config_default_a4fe67b2_complete :
    closed_records.encryption_config_default_a4fe67b2.make ⦃r => r.enabled = false ∧
      r.key_base64 = none⦄ := by
  unfold closed_records.encryption_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem database_config_default_a4fe67b2_complete :
    closed_records.database_config_default_a4fe67b2.make ⦃r => r.connection_string.val = [112#u8, 111#u8, 115#u8, 116#u8, 103#u8, 114#u8, 101#u8, 115#u8, 58#u8, 47#u8, 47#u8, 112#u8, 111#u8, 115#u8, 116#u8, 103#u8, 114#u8, 101#u8, 115#u8, 58#u8, 112#u8, 111#u8, 115#u8, 116#u8, 103#u8, 114#u8, 101#u8, 115#u8, 64#u8, 108#u8, 111#u8, 99#u8, 97#u8, 108#u8, 104#u8, 111#u8, 115#u8, 116#u8, 58#u8, 53#u8, 52#u8, 51#u8, 50#u8, 47#u8, 111#u8, 120#u8, 105#u8, 99#u8, 108#u8, 111#u8, 117#u8, 100#u8] ∧
      r.max_connections.val = 20 ∧
      r.min_connections.val = 5 ∧
      r.connect_timeout_secs.val = 10 ∧
      r.idle_timeout_secs.val = 300 ∧
      r.max_lifetime_secs.val = 1800 ∧
      r.maintenance_max_connections.val = 5 ∧
      r.maintenance_min_connections.val = 1 ∧
      r.statement_timeout_secs.val = 30 ∧
      r.pool_monitor_interval_secs.val = 30⦄ := by
  unfold closed_records.database_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem rate_limit_config_default_a4fe67b2_complete :
    closed_records.rate_limit_config_default_a4fe67b2.make ⦃r => r.login_max_requests.val = 10 ∧
      r.login_window_secs.val = 60 ∧
      r.register_max_requests.val = 5 ∧
      r.register_window_secs.val = 3600 ∧
      r.refresh_max_requests.val = 20 ∧
      r.refresh_window_secs.val = 60 ∧
      r.lockout_max_failures.val = 5 ∧
      r.lockout_duration_secs.val = 900 ∧
      r.user_profile_max_requests.val = 60 ∧
      r.user_profile_window_secs.val = 60 ∧
      r.delta_upload_max_requests.val = 240 ∧
      r.delta_upload_window_secs.val = 60⦄ := by
  unfold closed_records.rate_limit_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem oidc_config_default_a4fe67b2_complete :
    closed_records.oidc_config_default_a4fe67b2.make ⦃r => r.enabled = false ∧
      r.issuer_url.val = [] ∧
      r.client_id.val = [] ∧
      r.client_secret.val = [] ∧
      r.redirect_uri.val = [104#u8, 116#u8, 116#u8, 112#u8, 58#u8, 47#u8, 47#u8, 108#u8, 111#u8, 99#u8, 97#u8, 108#u8, 104#u8, 111#u8, 115#u8, 116#u8, 58#u8, 56#u8, 48#u8, 56#u8, 54#u8, 47#u8, 97#u8, 112#u8, 105#u8, 47#u8, 97#u8, 117#u8, 116#u8, 104#u8, 47#u8, 111#u8, 105#u8, 100#u8, 99#u8, 47#u8, 99#u8, 97#u8, 108#u8, 108#u8, 98#u8, 97#u8, 99#u8, 107#u8] ∧
      r.scopes.val = [111#u8, 112#u8, 101#u8, 110#u8, 105#u8, 100#u8, 32#u8, 112#u8, 114#u8, 111#u8, 102#u8, 105#u8, 108#u8, 101#u8, 32#u8, 101#u8, 109#u8, 97#u8, 105#u8, 108#u8] ∧
      r.frontend_url.val = [104#u8, 116#u8, 116#u8, 112#u8, 58#u8, 47#u8, 47#u8, 108#u8, 111#u8, 99#u8, 97#u8, 108#u8, 104#u8, 111#u8, 115#u8, 116#u8, 58#u8, 56#u8, 48#u8, 56#u8, 54#u8] ∧
      r.auto_provision = true ∧
      r.admin_groups.val = [] ∧
      r.disable_password_login = false ∧
      r.provider_name.val = [83#u8, 83#u8, 79#u8] ∧
      r.auto_link_email_match = true⦄ := by
  unfold closed_records.oidc_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem smtp_config_default_a4fe67b2_complete :
    closed_records.smtp_config_default_a4fe67b2.make ⦃r => r.host.val = [] ∧
      r.port.val = 587 ∧
      r.user.val = [] ∧
      r.pass.val = [] ∧
      r.from.val = [] ∧
      r.tls = .Starttls ∧
      r.mock = false⦄ := by
  unfold closed_records.smtp_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem magic_link_config_default_a4fe67b2_complete :
    closed_records.magic_link_config_default_a4fe67b2.make ⦃r => r.login_ttl_minutes.val = 10 ∧
      r.invite_ttl_hours.val = 24 ∧
      r.allow_external_users = true ∧
      r.allowed_email_domains.val = [] ∧
      r.invite_per_caller_per_hour.val = 50 ∧
      r.send_per_email_per_hour.val = 5 ∧
      r.send_per_ip_per_hour.val = 200 ∧
      r.open_to_password_users = false ∧
      r.notify_internal_users_on_share = true⦄ := by
  unfold closed_records.magic_link_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem grant_cleanup_config_default_a4fe67b2_complete :
    closed_records.grant_cleanup_config_default_a4fe67b2.make ⦃r => r.enabled = true ∧
      r.grace_days.val = 15 ∧
      r.interval_hours.val = 24⦄ := by
  unfold closed_records.grant_cleanup_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem search_cache_config_default_a4fe67b2_complete :
    closed_records.search_cache_config_default_a4fe67b2.make ⦃r => r.max_bytes.val = 33554432⦄ := by
  unfold closed_records.search_cache_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem i18n_config_default_a4fe67b2_complete :
    closed_records.i18n_config_default_a4fe67b2.make ⦃r => r.default_locale.val = [101#u8, 110#u8]⦄ := by
  unfold closed_records.i18n_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem video_thumbnail_config_default_a4fe67b2_complete :
    closed_records.video_thumbnail_config_default_a4fe67b2.make ⦃r => r.ffmpeg_path.val = [102#u8, 102#u8, 109#u8, 112#u8, 101#u8, 103#u8] ∧
      r.concurrency = none ∧
      r.timeout_secs.val = 30 ∧
      r.max_mb.val = 2048⦄ := by
  unfold closed_records.video_thumbnail_config_default_a4fe67b2.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem file_content_cache_config_default_28be87aa_complete :
    closed_records.file_content_cache_config_default_28be87aa.make ⦃r => r.max_file_size.val = 10485760 ∧
      r.max_total_size.val = 536870912 ∧
      r.max_entries.val = 10000⦄ := by
  unfold closed_records.file_content_cache_config_default_28be87aa.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

end oxicloud_kernel.Verified.ClosedRecords
