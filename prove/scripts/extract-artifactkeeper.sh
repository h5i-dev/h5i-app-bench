#!/usr/bin/env bash
# Extract the artifact-keeper kernel to Lean: Rust -> LLBC (Charon) -> Lean (Aeneas).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d -p "$root/results")
trap 'rm -rf "$tmp"' EXIT
k=artifactkeeper_kernel
(cd "$root/ports/artifactkeeper/kernel" && charon cargo --preset=aeneas \
  --start-from $k::middleware::repo_visibility_middleware \
  --start-from $k::middleware::auth_middleware \
  --start-from $k::middleware::optional_auth_middleware \
  --start-from $k::middleware::admin_middleware \
  --start-from $k::middleware::guest_access_guard \
  --start-from $k::handlers::create_permission --start-from $k::handlers::require_auth_basic_scope --start-from $k::handlers::require_scope_response \
  --start-from $k::net::resolve_client_ip_addr \
  --start-from $k::token_scope::validate_scopes_pure --start-from $k::token_scope::enforce_admin_only_scopes \
  --start-from $k::net::CidrRange::contains \
  --dest-file "$tmp/$k.llbc")
aeneas -backend lean "$tmp/$k.llbc" -dest "$root/ports/artifactkeeper/proofs/generated"
sed -i "s|Source: '$root/|Source: '|" "$root/ports/artifactkeeper/proofs/generated"/*.lean
