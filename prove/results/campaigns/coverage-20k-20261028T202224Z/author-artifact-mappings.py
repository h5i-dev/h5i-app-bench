import sys,json,gzip,hashlib,subprocess
from pathlib import Path
sys.path.insert(0,'prove/harness')
from dashboard import generated_decls
root=Path('prove');app='artifactkeeper';base='backend/src/'
rev=subprocess.check_output(['git','-C',str(root/'results/upstream/artifactkeeper.git'),'rev-parse','7c42891'],text=True).strip()
items=[json.loads(l) for l in gzip.open(root/'results/source-coverage/kernel-ceiling-items.jsonl.gz','rt') if json.loads(l)['app']==app]
gen=generated_decls(root/'ports/artifactkeeper/proofs/generated/ArtifactkeeperKernel.lean'); mappings={};texts={}
def add(decl,file,ty,name):
 assert decl in gen,decl
 found=[x for x in items if x['file']==base+file and x['self_ty']==ty and x['name']==name and x['kind'] in ('fn','method')]
 assert len(found)==1,(decl,file,ty,name,found)
 x=found[0];path=x['file']
 if path not in texts:texts[path]=subprocess.check_output(['git','-C',str(root/'results/upstream/artifactkeeper.git'),'show',rev+':'+path],text=True)
 fragment='\n'.join(texts[path].splitlines()[x['start']-1:x['end']])
 mappings.setdefault(decl,[]).append({k:x[k] for k in ('file','self_ty','name','kind','start','end')}|{'sha256':hashlib.sha256(fragment.encode()).hexdigest()})
def group(module,file,ty,entries):
 for entry in entries.split():
  decl,sep,name=entry.partition('=');add(module+'.'+decl,file,ty,name if sep else decl)
auth='api/middleware/auth.rs'
group('middleware',auth,'','repo_visibility_middleware auth_middleware optional_auth_middleware admin_middleware csrf_guard')
group('middleware','api/middleware/guest_access.rs','','guest_access_guard')
group('paths','api/middleware/guest_access.rs','','is_allowlisted')
group('paths','api/middleware/oci_errors.rs','','is_oci_v2_path')
group('paths',auth,'','percent_hex_val percent_decode_path_segment extract_repo_key extract_conda_url_token is_nuget_push_path is_non_mutating_format_post is_pypi_xmlrpc_tail is_anonymous_readable_format_post should_allow_repo_access is_write_method action_for_method public_read_satisfies_acl authenticated_read_satisfies_acl extract_ticket_from_query ticket_method_allowed ticket_path_allowed path_exempt_from_password_change')
group('http',auth,'','extract_token_from_auth_header extract_token session_cookie_token has_header_credential credential_is_session_cookie is_state_changing_method violates_csrf_contract declares_same_origin is_browser_request extract_nuget_push_api_key extract_visibility_token')
group('resolve',auth,'','try_resolve_auth_outcome validate_api_token_with_scopes classify_token_validation_err decode_basic_credentials try_resolve_ticket_auth principal_must_change_password')
group('resolve','services/auth_config_service.rs','AuthConfigService','validate_download_ticket')
group('token_scope.AuthExtension',auth,'AuthExtension','has_scope access_scope can_access_repo require_scope with_scope_gated_admin require_admin')
group('handlers',auth,'','require_auth_basic require_auth_basic_scope require_scope_response')
group('handlers','api/handlers/permissions.rs','','create_permission validate_anonymous_rule require_auth')
group('token_scope','services/token_service.rs','','validate_scopes_pure enforce_admin_only_scopes scopes_grant_access')
group('AccessScope','models/access_scope.rs','AccessScope','grants')
group('Visibility','models/repository.rs','RepositoryVisibility','allows_anonymous_read allows_authenticated_read')
group('Claims','services/auth_service.rs','Claims','effective_iat_ms')
group('permission','services/permission_service.rs','PermissionService','check_permission query_actions check_repository_action check_anonymous_repository_action has_any_rules_for_target validate_principal')
group('permission','services/permission_service.rs','PermissionConditions','validate_conditions=validate')
group('net.CidrRange','api/middleware/rate_limit.rs','CidrRange','parse contains')
group('net','api/middleware/rate_limit.rs','','first_xff_token_in normalize_xff_token rightmost_untrusted_xff_token resolve_client_ip_addr')
group('token_expiry','services/token_expiry_policy.rs','ApiTokenExpiryPolicy','default_policy=default validate')
group('token_expiry','services/token_expiry_policy.rs','','resolve_expiry')
group('totp_policy','services/totp_policy.rs','TotpPolicy','is_enforcing')
group('totp_policy','services/totp_policy.rs','','totp_login_requirement policy_requires_totp strictness is_tightening check_policy_activation')
out={'upstream_revision':rev,'meaning':'Exact qualified item attribution; SQL, framework and trusted-input abstractions remain as documented in DEVIATIONS.md. Reach is not complete equivalence. Unmapped helpers and ambiguous conversion implementations excluded.','declarations':dict(sorted(mappings.items()))}
(root/'harness/source-mappings/artifactkeeper.json').write_text(json.dumps(out,indent=2)+'\n')
print(len(mappings))
