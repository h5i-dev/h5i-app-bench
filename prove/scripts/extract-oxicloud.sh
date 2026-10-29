#!/usr/bin/env bash
# Extract the oxicloud kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d -p "$root/results")
trap 'rm -rf "$tmp"' EXIT
(cd "$root/ports/oxicloud/kernel" && charon cargo --preset=aeneas \
  --start-from oxicloud_kernel::grantapi::transition \
  --start-from oxicloud_kernel::drivepolicy::resolve \
  --start-from oxicloud_kernel::drivepolicy::refuse_public_links \
  --start-from oxicloud_kernel::drivepolicy::refuse_sharing \
  --start-from oxicloud_kernel::drivepolicy::refuse_owner_role_change \
  --start-from oxicloud_kernel::drivepolicy::refuse_cross_drive_move \
  --start-from oxicloud_kernel::drivepolicy::refuse_external_sharing \
  --start-from oxicloud_kernel::policycompare::policy_knobs \
  --start-from oxicloud_kernel::policycompare::non_defaultable_knobs \
  --start-from oxicloud_kernel::policycompare::knob_applies_to_kind \
  --start-from oxicloud_kernel::policycompare::knob_strictness \
  --start-from oxicloud_kernel::policycompare::knob_value \
  --start-from oxicloud_kernel::policycompare::knob_bool \
  --start-from oxicloud_kernel::policycompare::at_least_as_strict_on \
  --start-from oxicloud_kernel::policycompare::weaker_than \
  --dest-file "$tmp/oxicloud_kernel.llbc")
mkdir -p "$root/ports/oxicloud/proofs/generated"
aeneas -backend lean "$tmp/oxicloud_kernel.llbc" -dest "$root/ports/oxicloud/proofs/generated"
sed -i "s|Source: '$root/|Source: '|" "$root/ports/oxicloud/proofs/generated"/*.lean
if grep -q '^axiom' "$root/ports/oxicloud/proofs/generated"/*.lean; then
  grep -n '^axiom' "$root/ports/oxicloud/proofs/generated"/*.lean; exit 1
fi
