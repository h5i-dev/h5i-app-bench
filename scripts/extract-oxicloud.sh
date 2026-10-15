#!/usr/bin/env bash
# Extract the oxicloud kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d -p "$root/results")
trap 'rm -rf "$tmp"' EXIT
(cd "$root/ports/oxicloud/kernel" && charon cargo --preset=aeneas \
  --start-from oxicloud_kernel::grantapi::transition \
  --start-from oxicloud_kernel::userrole::as_bytes \
  --start-from oxicloud_kernel::userrole::from_stored \
  --start-from oxicloud_kernel::userrole::from_session \
  --start-from oxicloud_kernel::userrole::rank \
  --start-from oxicloud_kernel::userrole::at_least \
  --start-from oxicloud_kernel::userrole::outranks \
  --start-from oxicloud_kernel::userrole::is_anonymous \
  --start-from oxicloud_kernel::userrole::str_at_least \
  --start-from oxicloud_kernel::userrole::is_privileged \
  --start-from oxicloud_kernel::authwire::subject_bytes \
  --start-from oxicloud_kernel::authwire::subject_parse \
  --start-from oxicloud_kernel::authwire::subject_id \
  --start-from oxicloud_kernel::authwire::resource_bytes \
  --start-from oxicloud_kernel::authwire::resource_parse \
  --start-from oxicloud_kernel::authwire::resource_id \
  --start-from oxicloud_kernel::authwire::permission_bytes \
  --start-from oxicloud_kernel::authwire::permission_parse \
  --start-from oxicloud_kernel::authwire::permission_all \
  --start-from oxicloud_kernel::authwire::role_bytes \
  --start-from oxicloud_kernel::authwire::role_parse \
  --start-from oxicloud_kernel::authwire::role_all \
  --start-from oxicloud_kernel::authwire::subject_user_id \
  --start-from oxicloud_kernel::authwire::subject_token_id \
  --start-from oxicloud_kernel::drivepolicy::resolve \
  --start-from oxicloud_kernel::drivepolicy::refuse_public_links \
  --start-from oxicloud_kernel::drivepolicy::refuse_sharing \
  --start-from oxicloud_kernel::drivepolicy::refuse_owner_role_change \
  --start-from oxicloud_kernel::drivepolicy::refuse_cross_drive_move \
  --start-from oxicloud_kernel::drivepolicy::refuse_external_sharing \
  --start-from oxicloud_kernel::session::origin_bytes \
  --start-from oxicloud_kernel::session::origin_from_wire \
  --start-from oxicloud_kernel::session::from_raw \
  --start-from oxicloud_kernel::session::with_dpop_jkt \
  --start-from oxicloud_kernel::session::with_oidc_id_token \
  --start-from oxicloud_kernel::session::with_oidc_sid \
  --start-from oxicloud_kernel::session::revoke \
  --start-from oxicloud_kernel::session::id \
  --start-from oxicloud_kernel::session::user_id \
  --start-from oxicloud_kernel::session::refresh_token \
  --start-from oxicloud_kernel::session::expires_at \
  --start-from oxicloud_kernel::session::ip_address \
  --start-from oxicloud_kernel::session::user_agent \
  --start-from oxicloud_kernel::session::created_at \
  --start-from oxicloud_kernel::session::is_revoked \
  --start-from oxicloud_kernel::session::family_id \
  --start-from oxicloud_kernel::session::oidc_id_token \
  --start-from oxicloud_kernel::session::oidc_sid \
  --start-from oxicloud_kernel::session::dpop_jkt \
  --start-from oxicloud_kernel::session::origin \
  --start-from oxicloud_kernel::session::last_seen_at \
  --start-from oxicloud_kernel::validation::classify_email_verification \
  --start-from oxicloud_kernel::validation::is_valid_entry_name \
  --start-from oxicloud_kernel::validation::validate_dpop_jkt \
  --start-from oxicloud_kernel::share::from_raw \
  --start-from oxicloud_kernel::share::with_password \
  --start-from oxicloud_kernel::share::with_token \
  --start-from oxicloud_kernel::share::increment_access_count \
  --start-from oxicloud_kernel::share::has_password \
  --start-from oxicloud_kernel::share::id \
  --start-from oxicloud_kernel::share::item_id \
  --start-from oxicloud_kernel::share::item_name \
  --start-from oxicloud_kernel::share::item_type \
  --start-from oxicloud_kernel::share::token \
  --start-from oxicloud_kernel::share::password_hash \
  --start-from oxicloud_kernel::share::expires_at \
  --start-from oxicloud_kernel::share::created_at \
  --start-from oxicloud_kernel::share::created_by \
  --start-from oxicloud_kernel::share::access_count \
  --start-from oxicloud_kernel::subjectgroup::validate_name \
  --start-from oxicloud_kernel::subjectgroup::is_immutable \
  --dest-file "$tmp/oxicloud_kernel.llbc")
mkdir -p "$root/ports/oxicloud/proofs/generated"
aeneas -backend lean "$tmp/oxicloud_kernel.llbc" -dest "$root/ports/oxicloud/proofs/generated"
sed -i "s|Source: '$root/|Source: '|" "$root/ports/oxicloud/proofs/generated"/*.lean
if grep -q '^axiom' "$root/ports/oxicloud/proofs/generated"/*.lean; then
  grep -n '^axiom' "$root/ports/oxicloud/proofs/generated"/*.lean; exit 1
fi
