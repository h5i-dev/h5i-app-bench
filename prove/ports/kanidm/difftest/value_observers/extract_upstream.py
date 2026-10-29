"""Reproduce the reference from pinned upstream items; no method-body edits.
Run from any directory after fetching prove/results/upstream/kanidm.git.
"""
from pathlib import Path
import hashlib,json,subprocess,sys,re
root=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(root/'prove/ports/rustfs/difftest'))
from count_loc import item
rev='f608c4fe14dfd8d5df8edeed470bf1fb92060abd'
file='server/lib/src/value.rs'
s=subprocess.check_output(['git','-C',str(root/'prove/results/upstream/kanidm.git'),'show',f'{rev}:{file}'],text=True)
folder=Path(__file__).resolve().parent
prelude='use super::{Norm,Payload,Text};\npub type String=Text;\npub type str=Text;\npub type Vec<T>=Payload<T>;\npub type BTreeSet<T>=Payload<T>;\npub type Zeroizing<T>=Payload<T>;\npub type Box<T>=Payload<T>;\npub type Uuid=u128;\n#[derive(Clone,Copy,Debug)] pub struct Oauth2Session {pub rs_uuid:u128,pub payload:u64}\npub type SyntaxType=u64;\npub type IndexType=u64;\npub type ProtoFilter=u64;\npub type Credential=u64;\npub type SshPublicKey=u64;\npub type Cid=u64;\npub type OffsetDateTime=u64;\npub type Address=u64;\npub type Url=u64;\npub type IntentTokenState=u64;\npub type PasskeyV4=u64;\npub type AttestedPasskeyV4=u64;\npub type Session=u64;\npub type ApiToken=u64;\npub type JwsEs256Signer=u64;\npub type JwsRs256Signer=u64;\npub type UiHint=u64;\npub type Totp=u64;\npub type ImageValue=u64;\npub type CredentialType=u64;\npub type AttestationCaList=u64;\npub type OauthClaimMapJoin=u64;\npub type KeyId=u64;\npub type KeyUsage=u64;\npub type KeyStatus=u64;\npub type JsonValue=u64;\npub type Sha256Output=u64;\npub type ApplicationPassword=u64;\npub type Certificate=u64;\n'
selected={'Value': ['is_utf8', 'is_iutf8', 'is_insensitive_utf8', 'is_iname', 'is_uuid', 'is_bool', 'is_syntax', 'is_index', 'is_refer', 'is_json_filter', 'is_credential', 'is_secret_string', 'is_sshkey', 'is_spn', 'is_uint32', 'is_cid', 'is_nsuniqueid', 'is_datetime', 'is_email_address', 'is_url', 'is_oauthscope', 'is_oauthscopemap', 'is_privatebinary', 'as_json_filter', 'to_credential', 'get_secret_str', 'to_privatebinary', 'to_str', 'to_url', 'as_string', 'to_ref_uuid', 'to_uuid', 'to_indextype', 'to_syntaxtype', 'to_bool', 'to_uint32', 'to_utf8', 'to_iutf8', 'to_iname', 'to_jsonfilt', 'to_cred', 'to_spn', 'to_cid', 'to_nsuniqueid', 'to_emailaddress', 'to_oauthscope', 'to_oauthscopemap', 'to_restrictedstring', 'to_phonenumber', 'to_publicbinary', 'to_address', 'to_intenttoken', 'to_session', 'migrate_iutf8_iname'], 'PartialValue': ['is_utf8', 'is_iutf8', 'is_iname', 'is_bool', 'is_uuid', 'is_refer', 'is_index', 'is_syntax', 'is_json_filter', 'is_credential', 'is_secret_string', 'is_sshkey', 'is_spn', 'is_uint32', 'is_cid', 'is_nsuniqueid', 'is_datetime', 'is_email_address', 'is_url', 'is_oauthscope', 'is_privatebinary', 'to_str']}
reference=prelude+'#[derive(Clone,Debug)]\n'+item(s,r'^pub enum Value \{')+'\n#[derive(Clone,Debug)]\n'+item(s,r'^pub enum PartialValue \{')+'\n'
for typ,names in selected.items():
    chunk=s[s.index('impl '+typ+' {'):]
    reference+='impl '+typ+' {\n'+'\n'.join(item(chunk,r'    pub (?:const )?fn '+n+r'\(') for n in names)+'\n}\n'
(folder/'reference.rs').write_text(reference)
identity=json.loads((folder/'identity.json').read_text())
identity.update(file_sha256=hashlib.sha256(s.encode()).hexdigest(),reference_sha256=hashlib.sha256(reference.encode()).hexdigest(),selected_methods=selected)
(folder/'identity.json').write_text(json.dumps(identity,indent=2)+'\n')
