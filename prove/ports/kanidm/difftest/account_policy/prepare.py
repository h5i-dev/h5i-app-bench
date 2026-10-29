"""Extract exact pinned upstream fold_from; payload CA set modeled independently."""
import pathlib,sys,subprocess,hashlib,json
pin='f608c4fe14dfd8d5df8edeed470bf1fb92060abd'
s=subprocess.check_output(['git','--git-dir='+sys.argv[1],'show',pin+':server/lib/src/idm/accountpolicy.rs']).decode()
a=s.index('    pub(crate) fn fold_from'); b=s.index('    pub(crate) fn privilege_expiry',a)
method=s[a:b]
# Wrappers only: exact method body is copied without substitutions.
pre='''#![allow(dead_code)]
use kanidm_kernel::account_policy::{Policy,Resolved};
const MAXIMUM_AUTH_PRIVILEGE_EXPIRY:u32=3600;
const MAXIMUM_AUTH_SESSION_EXPIRY:u32=u32::MAX;
const PW_MFA_MIN_LENGTH:u32=10;
const PW_MAX_LENGTH_NIST:u32=128;
const PW_SFA_MIN_LENGTH_NIST:u32=15;
struct CredentialType;
#[allow(non_upper_case_globals)]
impl CredentialType {const Any:u16=0;const Mfa:u16=10;}
#[derive(Clone)]
struct AttestationCaList(u64);
impl AttestationCaList {fn intersection(&mut self,b:&Self){self.0 &= b.0}}
pub struct AccountPolicy {
 privilege_expiry:u32,authsession_expiry:u32,pw_min_length:u32,credential_policy:u16,
 webauthn_att_ca_list:Option<AttestationCaList>,limit_search_max_filter_test:Option<u64>,
 limit_search_max_results:Option<u64>,allow_primary_cred_fallback:Option<bool>}
pub struct ResolvedAccountPolicy {
 privilege_expiry:u32,authsession_expiry:u32,pw_min_length:u32,pw_max_length:u32,credential_policy:u16,
 webauthn_att_ca_list:Option<AttestationCaList>,limit_search_max_filter_test:Option<u64>,
 limit_search_max_results:Option<u64>,allow_primary_cred_fallback:Option<bool>}
impl ResolvedAccountPolicy {
'''
post='''}
pub fn fold(policies:&[Policy], masks:&[Option<u64>])->Resolved {
 let r=ResolvedAccountPolicy::fold_from(policies.iter().enumerate().map(|(i,p)| AccountPolicy {
 privilege_expiry:p.privilege_expiry,authsession_expiry:p.authsession_expiry,
 pw_min_length:p.pw_min_length,credential_policy:p.credential_policy,
 webauthn_att_ca_list:masks[i].map(AttestationCaList),
 limit_search_max_filter_test:p.limit_search_max_filter_test,limit_search_max_results:p.limit_search_max_results,
 allow_primary_cred_fallback:p.allow_primary_cred_fallback}));
 Resolved {policy: Policy {privilege_expiry:r.privilege_expiry,authsession_expiry:r.authsession_expiry,
 pw_min_length:r.pw_min_length,credential_policy:r.credential_policy,
 limit_search_max_filter_test:r.limit_search_max_filter_test,limit_search_max_results:r.limit_search_max_results,
 allow_primary_cred_fallback:r.allow_primary_cred_fallback},pw_max_length:r.pw_max_length}
}
'''
p=pathlib.Path(__file__).with_name('reference.rs');p.write_text(pre+method+post)
p.with_name('identity.json').write_text(json.dumps({'pin':pin,'source_sha256':hashlib.sha256(s.encode()).hexdigest(),'method_sha256':hashlib.sha256(method.encode()).hexdigest(),'claim':'complete scalar projection, excludes attestation CA payload result'},indent=2)+'\n')
