import KanidmKernel
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel
namespace kanidm_kernel.Verified.ValueObservers
set_option maxHeartbeats 1000000

def Value_is_utf8_model (v : value_observers.Value) : Bool :=
  match v with
  | .Utf8 _=> true
  | _ => false

theorem Value_is_utf8_spec (v : value_observers.Value) :
    value_observers.Value.is_utf8 v ⦃ r => r = Value_is_utf8_model v ⦄ := by
  unfold value_observers.Value.is_utf8
  cases v <;> h5i_steps <;> rfl

def Value_is_iutf8_model (v : value_observers.Value) : Bool :=
  match v with
  | .Iutf8 _=> true
  | _ => false

theorem Value_is_iutf8_spec (v : value_observers.Value) :
    value_observers.Value.is_iutf8 v ⦃ r => r = Value_is_iutf8_model v ⦄ := by
  unfold value_observers.Value.is_iutf8
  cases v <;> h5i_steps <;> rfl

def Value_is_insensitive_utf8_model (v : value_observers.Value) : Bool :=
  match v with
  | .Iutf8 _=> true
  | _ => false

theorem Value_is_insensitive_utf8_spec (v : value_observers.Value) :
    value_observers.Value.is_insensitive_utf8 v ⦃ r => r = Value_is_insensitive_utf8_model v ⦄ := by
  unfold value_observers.Value.is_insensitive_utf8
  cases v <;> h5i_steps <;> rfl

def Value_is_iname_model (v : value_observers.Value) : Bool :=
  match v with
  | .Iname _=> true
  | _ => false

theorem Value_is_iname_spec (v : value_observers.Value) :
    value_observers.Value.is_iname v ⦃ r => r = Value_is_iname_model v ⦄ := by
  unfold value_observers.Value.is_iname
  cases v <;> h5i_steps <;> rfl

def Value_is_uuid_model (v : value_observers.Value) : Bool :=
  match v with
  | .Uuid _=> true
  | _ => false

theorem Value_is_uuid_spec (v : value_observers.Value) :
    value_observers.Value.is_uuid v ⦃ r => r = Value_is_uuid_model v ⦄ := by
  unfold value_observers.Value.is_uuid
  cases v <;> h5i_steps <;> rfl

def Value_is_bool_model (v : value_observers.Value) : Bool :=
  match v with
  | .Boolean _=> true
  | _ => false

theorem Value_is_bool_spec (v : value_observers.Value) :
    value_observers.Value.is_bool v ⦃ r => r = Value_is_bool_model v ⦄ := by
  unfold value_observers.Value.is_bool
  cases v <;> h5i_steps <;> rfl

def Value_is_syntax_model (v : value_observers.Value) : Bool :=
  match v with
  | .Syntax _=> true
  | _ => false

theorem Value_is_syntax_spec (v : value_observers.Value) :
    value_observers.Value.is_syntax v ⦃ r => r = Value_is_syntax_model v ⦄ := by
  unfold value_observers.Value.is_syntax
  cases v <;> h5i_steps <;> rfl

def Value_is_index_model (v : value_observers.Value) : Bool :=
  match v with
  | .Index _=> true
  | _ => false

theorem Value_is_index_spec (v : value_observers.Value) :
    value_observers.Value.is_index v ⦃ r => r = Value_is_index_model v ⦄ := by
  unfold value_observers.Value.is_index
  cases v <;> h5i_steps <;> rfl

def Value_is_refer_model (v : value_observers.Value) : Bool :=
  match v with
  | .Refer _=> true
  | _ => false

theorem Value_is_refer_spec (v : value_observers.Value) :
    value_observers.Value.is_refer v ⦃ r => r = Value_is_refer_model v ⦄ := by
  unfold value_observers.Value.is_refer
  cases v <;> h5i_steps <;> rfl

def Value_is_json_filter_model (v : value_observers.Value) : Bool :=
  match v with
  | .JsonFilt _=> true
  | _ => false

theorem Value_is_json_filter_spec (v : value_observers.Value) :
    value_observers.Value.is_json_filter v ⦃ r => r = Value_is_json_filter_model v ⦄ := by
  unfold value_observers.Value.is_json_filter
  cases v <;> h5i_steps <;> rfl

def Value_is_credential_model (v : value_observers.Value) : Bool :=
  match v with
  | .Cred _ _=> true
  | _ => false

theorem Value_is_credential_spec (v : value_observers.Value) :
    value_observers.Value.is_credential v ⦃ r => r = Value_is_credential_model v ⦄ := by
  unfold value_observers.Value.is_credential
  cases v <;> h5i_steps <;> rfl

def Value_is_secret_string_model (v : value_observers.Value) : Bool :=
  match v with
  | .SecretValue _=> true
  | _ => false

theorem Value_is_secret_string_spec (v : value_observers.Value) :
    value_observers.Value.is_secret_string v ⦃ r => r = Value_is_secret_string_model v ⦄ := by
  unfold value_observers.Value.is_secret_string
  cases v <;> h5i_steps <;> rfl

def Value_is_sshkey_model (v : value_observers.Value) : Bool :=
  match v with
  | .SshKey _ _=> true
  | _ => false

theorem Value_is_sshkey_spec (v : value_observers.Value) :
    value_observers.Value.is_sshkey v ⦃ r => r = Value_is_sshkey_model v ⦄ := by
  unfold value_observers.Value.is_sshkey
  cases v <;> h5i_steps <;> rfl

def Value_is_spn_model (v : value_observers.Value) : Bool :=
  match v with
  | .Spn _ _=> true
  | _ => false

theorem Value_is_spn_spec (v : value_observers.Value) :
    value_observers.Value.is_spn v ⦃ r => r = Value_is_spn_model v ⦄ := by
  unfold value_observers.Value.is_spn
  cases v <;> h5i_steps <;> rfl

def Value_is_uint32_model (v : value_observers.Value) : Bool :=
  match v with
  | .Uint32 _=> true
  | _ => false

theorem Value_is_uint32_spec (v : value_observers.Value) :
    value_observers.Value.is_uint32 v ⦃ r => r = Value_is_uint32_model v ⦄ := by
  unfold value_observers.Value.is_uint32
  cases v <;> h5i_steps <;> rfl

def Value_is_cid_model (v : value_observers.Value) : Bool :=
  match v with
  | .Cid _=> true
  | _ => false

theorem Value_is_cid_spec (v : value_observers.Value) :
    value_observers.Value.is_cid v ⦃ r => r = Value_is_cid_model v ⦄ := by
  unfold value_observers.Value.is_cid
  cases v <;> h5i_steps <;> rfl

def Value_is_nsuniqueid_model (v : value_observers.Value) : Bool :=
  match v with
  | .Nsuniqueid _=> true
  | _ => false

theorem Value_is_nsuniqueid_spec (v : value_observers.Value) :
    value_observers.Value.is_nsuniqueid v ⦃ r => r = Value_is_nsuniqueid_model v ⦄ := by
  unfold value_observers.Value.is_nsuniqueid
  cases v <;> h5i_steps <;> rfl

def Value_is_datetime_model (v : value_observers.Value) : Bool :=
  match v with
  | .DateTime _=> true
  | _ => false

theorem Value_is_datetime_spec (v : value_observers.Value) :
    value_observers.Value.is_datetime v ⦃ r => r = Value_is_datetime_model v ⦄ := by
  unfold value_observers.Value.is_datetime
  cases v <;> h5i_steps <;> rfl

def Value_is_email_address_model (v : value_observers.Value) : Bool :=
  match v with
  | .EmailAddress _ _=> true
  | _ => false

theorem Value_is_email_address_spec (v : value_observers.Value) :
    value_observers.Value.is_email_address v ⦃ r => r = Value_is_email_address_model v ⦄ := by
  unfold value_observers.Value.is_email_address
  cases v <;> h5i_steps <;> rfl

def Value_is_url_model (v : value_observers.Value) : Bool :=
  match v with
  | .Url _=> true
  | _ => false

theorem Value_is_url_spec (v : value_observers.Value) :
    value_observers.Value.is_url v ⦃ r => r = Value_is_url_model v ⦄ := by
  unfold value_observers.Value.is_url
  cases v <;> h5i_steps <;> rfl

def Value_is_oauthscope_model (v : value_observers.Value) : Bool :=
  match v with
  | .OauthScope _=> true
  | _ => false

theorem Value_is_oauthscope_spec (v : value_observers.Value) :
    value_observers.Value.is_oauthscope v ⦃ r => r = Value_is_oauthscope_model v ⦄ := by
  unfold value_observers.Value.is_oauthscope
  cases v <;> h5i_steps <;> rfl

def Value_is_oauthscopemap_model (v : value_observers.Value) : Bool :=
  match v with
  | .OauthScopeMap _ _=> true
  | _ => false

theorem Value_is_oauthscopemap_spec (v : value_observers.Value) :
    value_observers.Value.is_oauthscopemap v ⦃ r => r = Value_is_oauthscopemap_model v ⦄ := by
  unfold value_observers.Value.is_oauthscopemap
  cases v <;> h5i_steps <;> rfl

def Value_is_privatebinary_model (v : value_observers.Value) : Bool :=
  match v with
  | .PrivateBinary _=> true
  | _ => false

theorem Value_is_privatebinary_spec (v : value_observers.Value) :
    value_observers.Value.is_privatebinary v ⦃ r => r = Value_is_privatebinary_model v ⦄ := by
  unfold value_observers.Value.is_privatebinary
  cases v <;> h5i_steps <;> rfl

def Value_as_json_filter_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .JsonFilt f => some f
  | _  => none

theorem Value_as_json_filter_spec (v : value_observers.Value) :
    value_observers.Value.as_json_filter v ⦃ r => r = Value_as_json_filter_model v ⦄ := by
  unfold value_observers.Value.as_json_filter
  cases v <;> h5i_steps <;> rfl

def Value_to_credential_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .Cred _ cred => some cred
  | _  => none

theorem Value_to_credential_spec (v : value_observers.Value) :
    value_observers.Value.to_credential v ⦃ r => r = Value_to_credential_model v ⦄ := by
  unfold value_observers.Value.to_credential
  cases v <;> h5i_steps <;> rfl

def Value_get_secret_str_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .SecretValue c => some c
  | _  => none

theorem Value_get_secret_str_spec (v : value_observers.Value) :
    value_observers.Value.get_secret_str v ⦃ r => r = Value_get_secret_str_model v ⦄ := by
  unfold value_observers.Value.get_secret_str
  cases v <;> h5i_steps <;> rfl

def Value_to_privatebinary_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .PrivateBinary c => some c
  | _  => none

theorem Value_to_privatebinary_spec (v : value_observers.Value) :
    value_observers.Value.to_privatebinary v ⦃ r => r = Value_to_privatebinary_model v ⦄ := by
  unfold value_observers.Value.to_privatebinary
  cases v <;> h5i_steps <;> rfl

def Value_to_str_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .Utf8 s => some s
  | .Iutf8 s => some s
  | .Iname s => some s
  | _  => none

theorem Value_to_str_spec (v : value_observers.Value) :
    value_observers.Value.to_str v ⦃ r => r = Value_to_str_model v ⦄ := by
  unfold value_observers.Value.to_str
  cases v <;> h5i_steps <;> rfl

def Value_to_url_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .Url u => some u
  | _  => none

theorem Value_to_url_spec (v : value_observers.Value) :
    value_observers.Value.to_url v ⦃ r => r = Value_to_url_model v ⦄ := by
  unfold value_observers.Value.to_url
  cases v <;> h5i_steps <;> rfl

def Value_as_string_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .Utf8 s => some s
  | .Iutf8 s => some s
  | .Iname s => some s
  | _  => none

theorem Value_as_string_spec (v : value_observers.Value) :
    value_observers.Value.as_string v ⦃ r => r = Value_as_string_model v ⦄ := by
  unfold value_observers.Value.as_string
  cases v <;> h5i_steps <;> rfl

def Value_to_ref_uuid_model (v : value_observers.Value) : Option (U128) :=
  match v with
  | .Refer u => some u
  | .OauthScopeMap u _ => some u
  | .Oauth2Session _ m => some m.rs_uuid
  | _  => none

theorem Value_to_ref_uuid_spec (v : value_observers.Value) :
    value_observers.Value.to_ref_uuid v ⦃ r => r = Value_to_ref_uuid_model v ⦄ := by
  unfold value_observers.Value.to_ref_uuid
  cases v <;> h5i_steps <;> rfl

def Value_to_uuid_model (v : value_observers.Value) : Option (U128) :=
  match v with
  | .Uuid u => some u
  | _  => none

theorem Value_to_uuid_spec (v : value_observers.Value) :
    value_observers.Value.to_uuid v ⦃ r => r = Value_to_uuid_model v ⦄ := by
  unfold value_observers.Value.to_uuid
  cases v <;> h5i_steps <;> rfl

def Value_to_indextype_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .Index i => some i
  | _  => none

theorem Value_to_indextype_spec (v : value_observers.Value) :
    value_observers.Value.to_indextype v ⦃ r => r = Value_to_indextype_model v ⦄ := by
  unfold value_observers.Value.to_indextype
  cases v <;> h5i_steps <;> rfl

def Value_to_syntaxtype_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .Syntax s => some s
  | _  => none

theorem Value_to_syntaxtype_spec (v : value_observers.Value) :
    value_observers.Value.to_syntaxtype v ⦃ r => r = Value_to_syntaxtype_model v ⦄ := by
  unfold value_observers.Value.to_syntaxtype
  cases v <;> h5i_steps <;> rfl

def Value_to_bool_model (v : value_observers.Value) : Option (Bool) :=
  match v with
  | .Boolean v => some v
  | _  => none

theorem Value_to_bool_spec (v : value_observers.Value) :
    value_observers.Value.to_bool v ⦃ r => r = Value_to_bool_model v ⦄ := by
  unfold value_observers.Value.to_bool
  cases v <;> h5i_steps <;> rfl

def Value_to_uint32_model (v : value_observers.Value) : Option (U32) :=
  match v with
  | .Uint32 v => some v
  | _  => none

theorem Value_to_uint32_spec (v : value_observers.Value) :
    value_observers.Value.to_uint32 v ⦃ r => r = Value_to_uint32_model v ⦄ := by
  unfold value_observers.Value.to_uint32
  cases v <;> h5i_steps <;> rfl

def Value_to_utf8_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .Utf8 s => some s
  | _  => none

theorem Value_to_utf8_spec (v : value_observers.Value) :
    value_observers.Value.to_utf8 v ⦃ r => r = Value_to_utf8_model v ⦄ := by
  unfold value_observers.Value.to_utf8
  cases v <;> h5i_steps <;> rfl

def Value_to_iutf8_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .Iutf8 s => some s
  | _  => none

theorem Value_to_iutf8_spec (v : value_observers.Value) :
    value_observers.Value.to_iutf8 v ⦃ r => r = Value_to_iutf8_model v ⦄ := by
  unfold value_observers.Value.to_iutf8
  cases v <;> h5i_steps <;> rfl

def Value_to_iname_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .Iname s => some s
  | _  => none

theorem Value_to_iname_spec (v : value_observers.Value) :
    value_observers.Value.to_iname v ⦃ r => r = Value_to_iname_model v ⦄ := by
  unfold value_observers.Value.to_iname
  cases v <;> h5i_steps <;> rfl

def Value_to_jsonfilt_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .JsonFilt f => some f
  | _  => none

theorem Value_to_jsonfilt_spec (v : value_observers.Value) :
    value_observers.Value.to_jsonfilt v ⦃ r => r = Value_to_jsonfilt_model v ⦄ := by
  unfold value_observers.Value.to_jsonfilt
  cases v <;> h5i_steps <;> rfl

def Value_to_cred_model (v : value_observers.Value) : Option (U64 × U64) :=
  match v with
  | .Cred tag c => some (tag, c)
  | _  => none

theorem Value_to_cred_spec (v : value_observers.Value) :
    value_observers.Value.to_cred v ⦃ r => r = Value_to_cred_model v ⦄ := by
  unfold value_observers.Value.to_cred
  cases v <;> h5i_steps <;> rfl

def Value_to_spn_model (v : value_observers.Value) : Option (U64 × U64) :=
  match v with
  | .Spn n d => some (n, d)
  | _  => none

theorem Value_to_spn_spec (v : value_observers.Value) :
    value_observers.Value.to_spn v ⦃ r => r = Value_to_spn_model v ⦄ := by
  unfold value_observers.Value.to_spn
  cases v <;> h5i_steps <;> rfl

def Value_to_cid_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .Cid s => some s
  | _  => none

theorem Value_to_cid_spec (v : value_observers.Value) :
    value_observers.Value.to_cid v ⦃ r => r = Value_to_cid_model v ⦄ := by
  unfold value_observers.Value.to_cid
  cases v <;> h5i_steps <;> rfl

def Value_to_nsuniqueid_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .Nsuniqueid s => some s
  | _  => none

theorem Value_to_nsuniqueid_spec (v : value_observers.Value) :
    value_observers.Value.to_nsuniqueid v ⦃ r => r = Value_to_nsuniqueid_model v ⦄ := by
  unfold value_observers.Value.to_nsuniqueid
  cases v <;> h5i_steps <;> rfl

def Value_to_emailaddress_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .EmailAddress s _ => some s
  | _  => none

theorem Value_to_emailaddress_spec (v : value_observers.Value) :
    value_observers.Value.to_emailaddress v ⦃ r => r = Value_to_emailaddress_model v ⦄ := by
  unfold value_observers.Value.to_emailaddress
  cases v <;> h5i_steps <;> rfl

def Value_to_oauthscope_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .OauthScope s => some s
  | _  => none

theorem Value_to_oauthscope_spec (v : value_observers.Value) :
    value_observers.Value.to_oauthscope v ⦃ r => r = Value_to_oauthscope_model v ⦄ := by
  unfold value_observers.Value.to_oauthscope
  cases v <;> h5i_steps <;> rfl

def Value_to_oauthscopemap_model (v : value_observers.Value) : Option (U128 × U64) :=
  match v with
  | .OauthScopeMap u m => some (u, m)
  | _  => none

theorem Value_to_oauthscopemap_spec (v : value_observers.Value) :
    value_observers.Value.to_oauthscopemap v ⦃ r => r = Value_to_oauthscopemap_model v ⦄ := by
  unfold value_observers.Value.to_oauthscopemap
  cases v <;> h5i_steps <;> rfl

def Value_to_restrictedstring_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .RestrictedString s => some s
  | _  => none

theorem Value_to_restrictedstring_spec (v : value_observers.Value) :
    value_observers.Value.to_restrictedstring v ⦃ r => r = Value_to_restrictedstring_model v ⦄ := by
  unfold value_observers.Value.to_restrictedstring
  cases v <;> h5i_steps <;> rfl

def Value_to_phonenumber_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .PhoneNumber p _b => some p
  | _  => none

theorem Value_to_phonenumber_spec (v : value_observers.Value) :
    value_observers.Value.to_phonenumber v ⦃ r => r = Value_to_phonenumber_model v ⦄ := by
  unfold value_observers.Value.to_phonenumber
  cases v <;> h5i_steps <;> rfl

def Value_to_publicbinary_model (v : value_observers.Value) : Option (U64 × U64) :=
  match v with
  | .PublicBinary t d => some (t, d)
  | _  => none

theorem Value_to_publicbinary_spec (v : value_observers.Value) :
    value_observers.Value.to_publicbinary v ⦃ r => r = Value_to_publicbinary_model v ⦄ := by
  unfold value_observers.Value.to_publicbinary
  cases v <;> h5i_steps <;> rfl

def Value_to_address_model (v : value_observers.Value) : Option (U64) :=
  match v with
  | .Address a => some a
  | _  => none

theorem Value_to_address_spec (v : value_observers.Value) :
    value_observers.Value.to_address v ⦃ r => r = Value_to_address_model v ⦄ := by
  unfold value_observers.Value.to_address
  cases v <;> h5i_steps <;> rfl

def Value_to_intenttoken_model (v : value_observers.Value) : Option (U64 × U64) :=
  match v with
  | .IntentToken u s => some (u, s)
  | _  => none

theorem Value_to_intenttoken_spec (v : value_observers.Value) :
    value_observers.Value.to_intenttoken v ⦃ r => r = Value_to_intenttoken_model v ⦄ := by
  unfold value_observers.Value.to_intenttoken
  cases v <;> h5i_steps <;> rfl

def Value_to_session_model (v : value_observers.Value) : Option (U128 × U64) :=
  match v with
  | .Session u s => some (u, s)
  | _  => none

theorem Value_to_session_spec (v : value_observers.Value) :
    value_observers.Value.to_session v ⦃ r => r = Value_to_session_model v ⦄ := by
  unfold value_observers.Value.to_session
  cases v <;> h5i_steps <;> rfl

def Value_migrate_iutf8_iname_model (v : value_observers.Value) : Option (value_observers.Value) :=
  match v with
  | .Iutf8 v => some (.Iname v)
  | _  => none

theorem Value_migrate_iutf8_iname_spec (v : value_observers.Value) :
    value_observers.Value.migrate_iutf8_iname v ⦃ r => r = Value_migrate_iutf8_iname_model v ⦄ := by
  unfold value_observers.Value.migrate_iutf8_iname
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_utf8_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Utf8 _=> true
  | _ => false

theorem PartialValue_is_utf8_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_utf8 v ⦃ r => r = PartialValue_is_utf8_model v ⦄ := by
  unfold value_observers.PartialValue.is_utf8
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_iutf8_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Iutf8 _=> true
  | _ => false

theorem PartialValue_is_iutf8_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_iutf8 v ⦃ r => r = PartialValue_is_iutf8_model v ⦄ := by
  unfold value_observers.PartialValue.is_iutf8
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_iname_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Iname _=> true
  | _ => false

theorem PartialValue_is_iname_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_iname v ⦃ r => r = PartialValue_is_iname_model v ⦄ := by
  unfold value_observers.PartialValue.is_iname
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_bool_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Boolean _=> true
  | _ => false

theorem PartialValue_is_bool_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_bool v ⦃ r => r = PartialValue_is_bool_model v ⦄ := by
  unfold value_observers.PartialValue.is_bool
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_uuid_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Uuid _=> true
  | _ => false

theorem PartialValue_is_uuid_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_uuid v ⦃ r => r = PartialValue_is_uuid_model v ⦄ := by
  unfold value_observers.PartialValue.is_uuid
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_refer_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Refer _=> true
  | _ => false

theorem PartialValue_is_refer_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_refer v ⦃ r => r = PartialValue_is_refer_model v ⦄ := by
  unfold value_observers.PartialValue.is_refer
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_index_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Index _=> true
  | _ => false

theorem PartialValue_is_index_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_index v ⦃ r => r = PartialValue_is_index_model v ⦄ := by
  unfold value_observers.PartialValue.is_index
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_syntax_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Syntax _=> true
  | _ => false

theorem PartialValue_is_syntax_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_syntax v ⦃ r => r = PartialValue_is_syntax_model v ⦄ := by
  unfold value_observers.PartialValue.is_syntax
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_json_filter_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .JsonFilt _=> true
  | _ => false

theorem PartialValue_is_json_filter_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_json_filter v ⦃ r => r = PartialValue_is_json_filter_model v ⦄ := by
  unfold value_observers.PartialValue.is_json_filter
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_credential_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Cred _=> true
  | _ => false

theorem PartialValue_is_credential_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_credential v ⦃ r => r = PartialValue_is_credential_model v ⦄ := by
  unfold value_observers.PartialValue.is_credential
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_secret_string_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .SecretValue=> true
  | _ => false

theorem PartialValue_is_secret_string_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_secret_string v ⦃ r => r = PartialValue_is_secret_string_model v ⦄ := by
  unfold value_observers.PartialValue.is_secret_string
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_sshkey_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .SshKey _=> true
  | _ => false

theorem PartialValue_is_sshkey_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_sshkey v ⦃ r => r = PartialValue_is_sshkey_model v ⦄ := by
  unfold value_observers.PartialValue.is_sshkey
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_spn_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Spn _  _=> true
  | _ => false

theorem PartialValue_is_spn_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_spn v ⦃ r => r = PartialValue_is_spn_model v ⦄ := by
  unfold value_observers.PartialValue.is_spn
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_uint32_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Uint32 _=> true
  | _ => false

theorem PartialValue_is_uint32_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_uint32 v ⦃ r => r = PartialValue_is_uint32_model v ⦄ := by
  unfold value_observers.PartialValue.is_uint32
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_cid_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Cid _=> true
  | _ => false

theorem PartialValue_is_cid_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_cid v ⦃ r => r = PartialValue_is_cid_model v ⦄ := by
  unfold value_observers.PartialValue.is_cid
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_nsuniqueid_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Nsuniqueid _=> true
  | _ => false

theorem PartialValue_is_nsuniqueid_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_nsuniqueid v ⦃ r => r = PartialValue_is_nsuniqueid_model v ⦄ := by
  unfold value_observers.PartialValue.is_nsuniqueid
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_datetime_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .DateTime _=> true
  | _ => false

theorem PartialValue_is_datetime_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_datetime v ⦃ r => r = PartialValue_is_datetime_model v ⦄ := by
  unfold value_observers.PartialValue.is_datetime
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_email_address_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .EmailAddress _=> true
  | _ => false

theorem PartialValue_is_email_address_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_email_address v ⦃ r => r = PartialValue_is_email_address_model v ⦄ := by
  unfold value_observers.PartialValue.is_email_address
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_url_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .Url _=> true
  | _ => false

theorem PartialValue_is_url_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_url v ⦃ r => r = PartialValue_is_url_model v ⦄ := by
  unfold value_observers.PartialValue.is_url
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_oauthscope_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .OauthScope _=> true
  | _ => false

theorem PartialValue_is_oauthscope_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_oauthscope v ⦃ r => r = PartialValue_is_oauthscope_model v ⦄ := by
  unfold value_observers.PartialValue.is_oauthscope
  cases v <;> h5i_steps <;> rfl

def PartialValue_is_privatebinary_model (v : value_observers.PartialValue) : Bool :=
  match v with
  | .PrivateBinary=> true
  | _ => false

theorem PartialValue_is_privatebinary_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_privatebinary v ⦃ r => r = PartialValue_is_privatebinary_model v ⦄ := by
  unfold value_observers.PartialValue.is_privatebinary
  cases v <;> h5i_steps <;> rfl

def PartialValue_to_str_model (v : value_observers.PartialValue) : Option (U64) :=
  match v with
  | .Utf8 s  => some s
  | .Iutf8 s  => some s
  | .Iname s  => some s
  | _  => none

theorem PartialValue_to_str_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.to_str v ⦃ r => r = PartialValue_to_str_model v ⦄ := by
  unfold value_observers.PartialValue.to_str
  cases v <;> h5i_steps <;> rfl

end kanidm_kernel.Verified.ValueObservers
