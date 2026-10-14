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
  --dest-file "$tmp/oxicloud_kernel.llbc")
mkdir -p "$root/ports/oxicloud/proofs/generated"
aeneas -backend lean "$tmp/oxicloud_kernel.llbc" -dest "$root/ports/oxicloud/proofs/generated"
sed -i "s|Source: '$root/|Source: '|" "$root/ports/oxicloud/proofs/generated"/*.lean
if grep -q '^axiom' "$root/ports/oxicloud/proofs/generated"/*.lean; then
  grep -n '^axiom' "$root/ports/oxicloud/proofs/generated"/*.lean; exit 1
fi
