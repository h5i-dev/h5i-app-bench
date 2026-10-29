"""Reproduce pure references from pinned OxiCloud Git objects, not a checkout.
Entity files are compiled unchanged. Other references select exact bodies and
adapt only the clock or external wrappers as documented below.
"""
from pathlib import Path
import hashlib,json,subprocess,sys,re,os
root=Path(os.environ["PROVE_REPO_ROOT"]) if "PROVE_REPO_ROOT" in os.environ else Path(__file__).resolve().parents[4]
sys.path.insert(0,str(root/'prove/ports/rustfs/difftest'))
from count_loc import item
rev='8c0dd334cf065ad11f60f9be24e2aafd5dda7550'
repo=root/'prove/results/upstream/oxicloud.git'
folder=Path(__file__).resolve().parent/'reference';folder.mkdir(exist_ok=True)
inputs={};outputs={}
def source(path):
 s=subprocess.check_output(['git','-C',str(repo),'show',f'{rev}:{path}'],text=True);inputs[path]=hashlib.sha256(s.encode()).hexdigest();return s

def write(name,text):
 (folder/name).write_text(text);outputs[name]=hashlib.sha256(text.encode()).hexdigest()
for name in ['user','session','share','magic_link_token','subject_group','entity_errors','drive']:
 write(name+'.rs',source('src/domain/entities/'+name+'.rs'))
s=source('src/domain/errors.rs');write('domain_errors.rs','\n'.join(l for l in s.splitlines() if not l.startswith('//!'))+'\n')
s=source('src/domain/services/authorization.rs');reference='use uuid::Uuid;\n'
for ty in ['Subject','Resource','Permission','Role']:
 reference+='#[derive(Clone,Copy,Debug,PartialEq,Eq)]\n'+item(s,r'pub enum '+ty+r'\b')+'\n'+item(s,r'impl '+ty+r'\s*\{')+'\n'
write('authorization.rs',reference)
s=source('src/interfaces/errors.rs');write('app_error.rs','use std::borrow::Cow; use http::StatusCode;\n#[derive(Debug)]\n'+item(s,r'pub struct AppError')+'\nimpl AppError {\n'+item(s,r'    pub fn new\(')+'\n}\n')
s=source('src/common/config.rs');write('config.rs',item(s,r'pub fn is_valid_entry_name\(')+'\n')
s=source('src/application/services/auth_application_service.rs');r=item(s,r'struct EmailVerificationDecision')+item(s,r'fn classify_email_verification\(')+item(s,r'fn validate_dpop_jkt\(');r+='''
pub fn email(claim: Option<bool>, required: bool)->(bool,Option<&'static str>) {let d=classify_email_verification(claim,required);(d.reject,d.reason)}
pub fn jkt(raw:&str)->Result<String,&'static str> {validate_dpop_jkt(raw)}
''';write('auth_oracle.rs',r)
s=source('src/domain/entities/magic_link_token.rs');r='use chrono::{DateTime,Utc}; use oxicloud::domain::entities::magic_link_token::MagicLinkStatus; pub struct Snapshot {pub expires_at:DateTime<Utc>,pub status:MagicLinkStatus} impl Snapshot {'
for name in ['is_expired','is_redeemable']:
 # Only change the clock input; all comparisons and branching are verbatim.
 r+=item(s,r'pub fn '+name+r'\(&self\)').replace('(&self)','(&self, now: DateTime<Utc>)').replace('Utc::now()','now').replace('self.is_expired()','self.is_expired(now)')
write('magic_oracle.rs',r+'}\n')
s=source('src/application/ports/authorization_ports.rs');reason=item(s,r'fn system_admin_denial_reason\(');imports='use oxicloud::domain::{services::authorization::Subject,entities::user::UserRole};\n';write('admin_oracle.rs',imports+reason+"\npub fn reason(s:Subject,r:UserRole,e:bool,a:bool)->Option<&'static str>{system_admin_denial_reason(s,r,e,a)}\n")
# Compile the original default method on a carrier with no additional methods.
r=imports+'use oxicloud::common::errors::DomainError;\n#[derive(Clone,Copy,Debug,PartialEq,Eq)]\n'+item(s,r'pub enum AuthzDenialVisibility')+'\n'+item(s,r'impl AuthzDenialVisibility\s*\{')+'\n'+reason+'\npub trait AuthorizationEngine {'+item(s,r'    fn require_system_admin\(')+'}\npub struct Oracle; impl AuthorizationEngine for Oracle {}\n';write('admin.rs',r)
s=source('src/interfaces/middleware/user.rs');write('live_role.rs','use smol_str::SmolStr;\n#[derive(Debug,Clone,PartialEq,Eq)]\n'+item(s,r'pub enum LiveRole')+'\n');r='use oxicloud::domain::{entities::user::{UserFlags,UserRole},errors::{DomainError,ErrorKind}}; use oxicloud::interfaces::{errors::AppError,middleware::user::LiveRole}; use uuid::Uuid;use http::StatusCode;use smol_str::SmolStr;\n'
for name in ['decide_internal_user','anonymous_live_role','decide_live_role','audit_token_revoked']:r+=item(s,r'fn '+name+r'\(')+'\n'
r+='''pub fn internal(f:Result<UserFlags,DomainError>,id:Uuid)->Result<(),AppError>{decide_internal_user(f,id)}
pub fn anonymous(s:&str)->Option<LiveRole>{anonymous_live_role(s)}
pub fn live(f:Result<UserFlags,DomainError>,id:Uuid,s:&str)->LiveRole{decide_live_role(f,id,s)}
''';write('liveauth_oracle.rs',r)
s=source('src/application/services/drive_policy_defaults_service.rs');r='use oxicloud::{common::errors::{DomainError,ErrorKind},domain::entities::drive::{DriveKind,POLICY_KNOBS,NON_DEFAULTABLE_KNOBS,knob_applies_to_kind}}; struct Oracle; impl Oracle {'+item(s,r'    fn validate\(&self, kind: DriveKind, bag:')+'}\npub fn validate(kind:DriveKind,bag:&serde_json::Value)->Result<(),DomainError>{Oracle.validate(kind,bag)}\n';write('defaults_oracle.rs',r)
(folder/'identity.json').write_text(json.dumps({'revision':rev,'input_sha256':inputs,'reference_sha256':outputs,'boundaries':'Entity files verbatim; original private decision/method bodies in minimal carriers; deterministic magic-link clock input; domain errors retained; HTTP response serialization outside scope.'},indent=2)+'\n')
