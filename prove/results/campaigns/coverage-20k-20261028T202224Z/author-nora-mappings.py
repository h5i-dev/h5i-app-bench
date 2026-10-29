import sys,json,gzip,hashlib,subprocess
from pathlib import Path
sys.path.insert(0,'prove/harness')
from dashboard import generated_decls
root=Path('prove');app='nora';base='nora-registry/src/'
rev=subprocess.check_output(['git','-C',str(root/'results/upstream/nora.git'),'rev-parse','f864a9a'],text=True).strip()
items=[json.loads(l) for l in gzip.open(root/'results/source-coverage/kernel-ceiling-items.jsonl.gz','rt') if json.loads(l)['app']==app]
gen=generated_decls(root/'ports/nora/proofs/generated/NoraKernel.lean'); mappings={};texts={}
def add(decl,file,ty,name):
 assert decl in gen,decl
 found=[x for x in items if x['file']==base+file and x['self_ty']==ty and x['name']==name and x['kind'] in ('fn','method')]
 assert len(found)==1,(decl,file,ty,name,found)
 x=found[0];path=x['file']
 if path not in texts:texts[path]=subprocess.check_output(['git','-C',str(root/'results/upstream/nora.git'),'show',rev+':'+path],text=True)
 fragment='\n'.join(texts[path].splitlines()[x['start']-1:x['end']])
 mappings.setdefault(decl,[]).append({k:x[k] for k in ('file','self_ty','name','kind','start','end')}|{'sha256':hashlib.sha256(fragment.encode()).hexdigest()})
def group(module,file,ty,entries):
 for entry in entries.split():
  decl,sep,name=entry.partition('=');add(module+'.'+decl,file,ty,name if sep else decl)
group('Role','tokens.rs','Role','can_write can_admin')
add('glob_match','auth/oidc.rs','','glob_match')
add('match_role','auth/oidc.rs','OidcValidator','match_role')
add('from_oidc_scopes','auth/namespace.rs','NamespaceAuthority','from_oidc_scopes')
add('enforce_namespace_scope','auth/namespace.rs','','enforce_namespace_scope')
for n in ['segment_glob','segments_match','namespace_match']:add(n,'validation.rs','',n)
group('validation','validation.rs','','ends_with_ci validate_storage_key validate_docker_name validate_digest validate_docker_reference')
group('middleware','auth/mod.rs','','is_public_path is_web_surface is_docker_path is_admin_path auth_middleware')
group('lockout.AuthFailureTracker','auth/mod.rs','AuthFailureTracker','check_blocked')
group('net.TrustedProxies','config/auth.rs','TrustedProxies','contains')
group('net','auth/mod.rs','','resolve_client_ip')
group('tokens','tokens.rs','TokenStore','verify_token invalidate_cache revoke_token revoke_all_for_user')
group('tokens','tokens.rs','','is_valid_hash_prefix')
# validate_token's JWT/crypto half is outside the claims kernel. Exact pinned
# fragment attribution begins at the lifetime ceiling, never the whole item.
f='nora-registry/src/auth/oidc.rs'
t=subprocess.check_output(['git','-C',str(root/'results/upstream/nora.git'),'show',rev+':'+f],text=True)
a=t.index('        // Enforce token lifetime ceiling');z='namespace_scope_enforcement: provider.namespace_scope_enforcement,\n        })';b=t.index(z,a)+len(z)
start=t.count('\n',0,a)+1;end=t.count('\n',0,b)+1
fragment='\n'.join(t.splitlines()[start-1:end])
mappings['validate_claims']=[{'file':f,'self_ty':'OidcValidator','name':'validate_token','kind':'method-fragment','start':start,'end':end,'sha256':hashlib.sha256(fragment.encode()).hexdigest()}]
# New permission mapper is added after its extracted declarations exist.
if 'permission_import.map_to_proposal' in gen:
 group('permission_import','import/permissions.rs','','map_to_proposal narrow_admin')
out={'upstream_revision':rev,'meaning':'Exact pinned item/fragment reach. JWT validation is excluded; only claims fragment mapped. Crypto, caches, identifiers and I/O boundaries remain documented in DEVIATIONS.md. Reach is not complete equivalence.','declarations':dict(sorted(mappings.items()))}
(root/'harness/source-mappings/nora.json').write_text(json.dumps(out,indent=2)+'\n')
print(len(mappings))
