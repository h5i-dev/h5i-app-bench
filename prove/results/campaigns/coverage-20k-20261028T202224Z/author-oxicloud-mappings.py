import sys,json,gzip,hashlib,subprocess
from pathlib import Path
sys.path.insert(0,'prove/harness')
from dashboard import generated_decls
root=Path('prove');app='oxicloud';base='src/'
rev=subprocess.check_output(['git','-C',str(root/'results/upstream/oxicloud.git'),'rev-parse','8c0dd33'],text=True).strip()
items=[json.loads(l) for l in gzip.open(root/'results/source-coverage/kernel-ceiling-items.jsonl.gz','rt') if json.loads(l)['app']==app]
gen=generated_decls(root/'ports/oxicloud/proofs/generated/OxicloudKernel.lean'); mappings={};texts={}
def add(decl,file,ty,name):
 assert decl in gen,decl
 found=[x for x in items if x['file']==base+file and x['self_ty']==ty and x['name']==name and x['kind'] in ('fn','method')]
 assert len(found)==1,(decl,file,ty,name,found)
 x=found[0];path=x['file']
 if path not in texts:texts[path]=subprocess.check_output(['git','-C',str(root/'results/upstream/oxicloud.git'),'show',rev+':'+path],text=True)
 fragment='\n'.join(texts[path].splitlines()[x['start']-1:x['end']])
 mappings.setdefault(decl,[]).append({k:x[k] for k in ('file','self_ty','name','kind','start','end')}|{'sha256':hashlib.sha256(fragment.encode()).hexdigest()})
def group(module,file,ty,entries):
 for entry in entries.split():
  decl,sep,name=entry.partition('=');add(module+'.'+decl,file,ty,name if sep else decl)
acl='infrastructure/services/pg_acl_engine.rs'
group('acl',acl,'PgAclEngine','check=check_inner expand_user subject_match_set drive_of direct_grant_exists folder_cascade_grant_exists file_parent_folder=query_parent_point read_only_gate_applies set_role clear_role')
group('acl','domain/services/authorization.rs','Role','role_grants=expand')
group('acl','domain/services/authorization.rs','','role_implies=roles_implying')
group('acl','infrastructure/repositories/pg/subject_group_pg_repository.rs','SubjectGroupPgRepository','groups_for_user')
group('grantapi','application/ports/authorization_ports.rs','AuthorizationEngine','require')
group('grantapi','application/services/drive_management_service.rs','DriveManagementService','set_member_role remove_member refuse_if_personal refuse_if_forbid_external_sharing refuse_if_forbid_owner_role_change refuse_if_last_owner_change')
group('grantapi','domain/entities/drive.rs','DrivePolicies','refuse_external_sharing')
group('grantapi',acl,'PgAclEngine','revoke')
out={'upstream_revision':rev,'meaning':'Exact qualified item reach. Current-table/SQL and non-admin abstractions are documented in DEVIATIONS.md; cache implementation and email/notification handler bodies excluded. Reach is not complete equivalence.','declarations':dict(sorted(mappings.items()))}
(root/'harness/source-mappings/oxicloud.json').write_text(json.dumps(out,indent=2)+'\n')
print(len(mappings))
