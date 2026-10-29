import KanidmKernel
import H5iAppLib
import Verified.KanidmDeleteProtected
open Aeneas Aeneas.Std Result kanidm_kernel
namespace kanidm_kernel.Verified.SyntaxTypes
set_option maxHeartbeats 4000000
set_option maxRecDepth 8192

def parsePart4 (inputBytes : List U8) : Option syntax_types.SyntaxType :=
  if inputBytes = [67#u8, 69#u8, 82#u8, 84#u8, 73#u8, 70#u8, 73#u8, 67#u8, 65#u8, 84#u8, 69#u8] then some .Certificate else
  if inputBytes = [65#u8, 80#u8, 80#u8, 76#u8, 73#u8, 67#u8, 65#u8, 84#u8, 73#u8, 79#u8, 78#u8, 95#u8, 80#u8, 65#u8, 83#u8, 83#u8, 87#u8, 79#u8, 82#u8, 68#u8] then some .ApplicationPassword else
  if inputBytes = [74#u8, 83#u8, 79#u8, 78#u8] then some .Json else
  if inputBytes = [77#u8, 69#u8, 83#u8, 83#u8, 65#u8, 71#u8, 69#u8] then some .Message else
  if inputBytes = [83#u8, 72#u8, 65#u8, 50#u8, 53#u8, 54#u8] then some .Sha256 else
  if inputBytes = [73#u8, 78#u8, 84#u8, 54#u8, 52#u8] then some .Int64 else
  if inputBytes = [85#u8, 73#u8, 78#u8, 84#u8, 54#u8, 52#u8] then some .Uint64 else
  none

@[step] theorem part4_spec (inputBytes : Slice U8) :
    syntax_types.parse_part_4 inputBytes ⦃ r => r = parsePart4 inputBytes.val ⦄ := by
  unfold syntax_types.parse_part_4
  h5i_steps
  all_goals simp_all [parsePart4]

def parsePart3 (inputBytes : List U8) : Option syntax_types.SyntaxType :=
  if inputBytes = [85#u8, 73#u8, 72#u8, 73#u8, 78#u8, 84#u8] then some .UiHint else
  if inputBytes = [84#u8, 79#u8, 84#u8, 80#u8, 83#u8, 69#u8, 67#u8, 82#u8, 69#u8, 84#u8] then some .TotpSecret else
  if inputBytes = [65#u8, 80#u8, 73#u8, 84#u8, 79#u8, 75#u8, 69#u8, 78#u8] then some .ApiToken else
  if inputBytes = [65#u8, 85#u8, 68#u8, 73#u8, 84#u8, 95#u8, 76#u8, 79#u8, 71#u8, 95#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8] then some .AuditLogString else
  if inputBytes = [69#u8, 67#u8, 95#u8, 75#u8, 69#u8, 89#u8, 95#u8, 80#u8, 82#u8, 73#u8, 86#u8, 65#u8, 84#u8, 69#u8] then some .EcKeyPrivate else
  if inputBytes = [67#u8, 82#u8, 69#u8, 68#u8, 69#u8, 78#u8, 84#u8, 73#u8, 65#u8, 76#u8, 95#u8, 84#u8, 89#u8, 80#u8, 69#u8] then some .CredentialType else
  if inputBytes = [87#u8, 69#u8, 66#u8, 65#u8, 85#u8, 84#u8, 72#u8, 78#u8, 95#u8, 65#u8, 84#u8, 84#u8, 69#u8, 83#u8, 84#u8, 65#u8, 84#u8, 73#u8, 79#u8, 78#u8, 95#u8, 67#u8, 65#u8, 95#u8, 76#u8, 73#u8, 83#u8, 84#u8] then some .WebauthnAttestationCaList else
  if inputBytes = [79#u8, 65#u8, 85#u8, 84#u8, 72#u8, 95#u8, 67#u8, 76#u8, 65#u8, 73#u8, 77#u8, 95#u8, 77#u8, 65#u8, 80#u8] then some .OauthClaimMap else
  if inputBytes = [75#u8, 69#u8, 89#u8, 95#u8, 73#u8, 78#u8, 84#u8, 69#u8, 82#u8, 78#u8, 65#u8, 76#u8] then some .KeyInternal else
  if inputBytes = [72#u8, 69#u8, 88#u8, 95#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8] then some .HexString else
  parsePart4 inputBytes

@[step] theorem part3_spec (inputBytes : Slice U8) :
    syntax_types.parse_part_3 inputBytes ⦃ r => r = parsePart3 inputBytes.val ⦄ := by
  unfold syntax_types.parse_part_3
  h5i_steps
  all_goals simp_all [parsePart3]

def parsePart2 (inputBytes : List U8) : Option syntax_types.SyntaxType :=
  if inputBytes = [79#u8, 65#u8, 85#u8, 84#u8, 72#u8, 95#u8, 83#u8, 67#u8, 79#u8, 80#u8, 69#u8] then some .OauthScope else
  if inputBytes = [79#u8, 65#u8, 85#u8, 84#u8, 72#u8, 95#u8, 83#u8, 67#u8, 79#u8, 80#u8, 69#u8, 95#u8, 77#u8, 65#u8, 80#u8] then some .OauthScopeMap else
  if inputBytes = [80#u8, 82#u8, 73#u8, 86#u8, 65#u8, 84#u8, 69#u8, 95#u8, 66#u8, 73#u8, 78#u8, 65#u8, 82#u8, 89#u8] then some .PrivateBinary else
  if inputBytes = [73#u8, 78#u8, 84#u8, 69#u8, 78#u8, 84#u8, 95#u8, 84#u8, 79#u8, 75#u8, 69#u8, 78#u8] then some .IntentToken else
  if inputBytes = [80#u8, 65#u8, 83#u8, 83#u8, 75#u8, 69#u8, 89#u8] then some .Passkey else
  if inputBytes = [65#u8, 84#u8, 84#u8, 69#u8, 83#u8, 84#u8, 69#u8, 68#u8, 95#u8, 80#u8, 65#u8, 83#u8, 83#u8, 75#u8, 69#u8, 89#u8] then some .AttestedPasskey else
  if inputBytes = [83#u8, 69#u8, 83#u8, 83#u8, 73#u8, 79#u8, 78#u8] then some .Session else
  if inputBytes = [74#u8, 87#u8, 83#u8, 95#u8, 75#u8, 69#u8, 89#u8, 95#u8, 69#u8, 83#u8, 50#u8, 53#u8, 54#u8] then some .JwsKeyEs256 else
  if inputBytes = [74#u8, 87#u8, 83#u8, 95#u8, 75#u8, 69#u8, 89#u8, 95#u8, 82#u8, 83#u8, 50#u8, 53#u8, 54#u8] then some .JwsKeyRs256 else
  if inputBytes = [79#u8, 65#u8, 85#u8, 84#u8, 72#u8, 50#u8, 83#u8, 69#u8, 83#u8, 83#u8, 73#u8, 79#u8, 78#u8] then some .Oauth2Session else
  parsePart3 inputBytes

@[step] theorem part2_spec (inputBytes : Slice U8) :
    syntax_types.parse_part_2 inputBytes ⦃ r => r = parsePart2 inputBytes.val ⦄ := by
  unfold syntax_types.parse_part_2
  h5i_steps
  all_goals simp_all [parsePart2]

def parsePart1 (inputBytes : List U8) : Option syntax_types.SyntaxType :=
  if inputBytes = [82#u8, 65#u8, 68#u8, 73#u8, 85#u8, 83#u8, 95#u8, 85#u8, 84#u8, 70#u8, 56#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8] then some .SecretUtf8String else
  if inputBytes = [83#u8, 69#u8, 67#u8, 82#u8, 69#u8, 84#u8, 95#u8, 85#u8, 84#u8, 70#u8, 56#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8] then some .SecretUtf8String else
  if inputBytes = [83#u8, 83#u8, 72#u8, 75#u8, 69#u8, 89#u8] then some .SshKey else
  if inputBytes = [83#u8, 69#u8, 67#u8, 85#u8, 82#u8, 73#u8, 84#u8, 89#u8, 95#u8, 80#u8, 82#u8, 73#u8, 78#u8, 67#u8, 73#u8, 80#u8, 65#u8, 76#u8, 95#u8, 78#u8, 65#u8, 77#u8, 69#u8] then some .SecurityPrincipalName else
  if inputBytes = [85#u8, 73#u8, 78#u8, 84#u8, 51#u8, 50#u8] then some .Uint32 else
  if inputBytes = [67#u8, 73#u8, 68#u8] then some .Cid else
  if inputBytes = [78#u8, 83#u8, 85#u8, 78#u8, 73#u8, 81#u8, 85#u8, 69#u8, 73#u8, 68#u8] then some .NsUniqueId else
  if inputBytes = [68#u8, 65#u8, 84#u8, 69#u8, 84#u8, 73#u8, 77#u8, 69#u8] then some .DateTime else
  if inputBytes = [69#u8, 77#u8, 65#u8, 73#u8, 76#u8, 95#u8, 65#u8, 68#u8, 68#u8, 82#u8, 69#u8, 83#u8, 83#u8] then some .EmailAddress else
  if inputBytes = [85#u8, 82#u8, 76#u8] then some .Url else
  parsePart2 inputBytes

@[step] theorem part1_spec (inputBytes : Slice U8) :
    syntax_types.parse_part_1 inputBytes ⦃ r => r = parsePart1 inputBytes.val ⦄ := by
  unfold syntax_types.parse_part_1
  h5i_steps
  all_goals simp_all [parsePart1]

def parsePart0 (inputBytes : List U8) : Option syntax_types.SyntaxType :=
  if inputBytes = [85#u8, 84#u8, 70#u8, 56#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8] then some .Utf8String else
  if inputBytes = [85#u8, 84#u8, 70#u8, 56#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8, 95#u8, 73#u8, 78#u8, 83#u8, 69#u8, 78#u8, 83#u8, 73#u8, 84#u8, 73#u8, 86#u8, 69#u8] then some .Utf8StringInsensitive else
  if inputBytes = [85#u8, 84#u8, 70#u8, 56#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8, 95#u8, 73#u8, 78#u8, 65#u8, 77#u8, 69#u8] then some .Utf8StringIname else
  if inputBytes = [85#u8, 85#u8, 73#u8, 68#u8] then some .Uuid else
  if inputBytes = [66#u8, 79#u8, 79#u8, 76#u8, 69#u8, 65#u8, 78#u8] then some .Boolean else
  if inputBytes = [83#u8, 89#u8, 78#u8, 84#u8, 65#u8, 88#u8, 95#u8, 73#u8, 68#u8] then some .SyntaxId else
  if inputBytes = [73#u8, 78#u8, 68#u8, 69#u8, 88#u8, 95#u8, 73#u8, 68#u8] then some .IndexId else
  if inputBytes = [82#u8, 69#u8, 70#u8, 69#u8, 82#u8, 69#u8, 78#u8, 67#u8, 69#u8, 95#u8, 85#u8, 85#u8, 73#u8, 68#u8] then some .ReferenceUuid else
  if inputBytes = [74#u8, 83#u8, 79#u8, 78#u8, 95#u8, 70#u8, 73#u8, 76#u8, 84#u8, 69#u8, 82#u8] then some .JsonFilter else
  if inputBytes = [67#u8, 82#u8, 69#u8, 68#u8, 69#u8, 78#u8, 84#u8, 73#u8, 65#u8, 76#u8] then some .Credential else
  parsePart1 inputBytes

@[step] theorem part0_spec (inputBytes : Slice U8) :
    syntax_types.parse_normalized inputBytes ⦃ r => r = parsePart0 inputBytes.val ⦄ := by
  unfold syntax_types.parse_normalized
  h5i_steps
  all_goals simp_all [parsePart0]

def parseModel := parsePart0

theorem parse_spec (inputBytes : Slice U8) :
    syntax_types.parse_normalized inputBytes ⦃ r => r = parseModel inputBytes.val ⦄ :=
  part0_spec inputBytes

def displayModel : syntax_types.SyntaxType → List U8
  | .Utf8String => [85#u8, 84#u8, 70#u8, 56#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8]
  | .Utf8StringInsensitive => [85#u8, 84#u8, 70#u8, 56#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8, 95#u8, 73#u8, 78#u8, 83#u8, 69#u8, 78#u8, 83#u8, 73#u8, 84#u8, 73#u8, 86#u8, 69#u8]
  | .Utf8StringIname => [85#u8, 84#u8, 70#u8, 56#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8, 95#u8, 73#u8, 78#u8, 65#u8, 77#u8, 69#u8]
  | .Uuid => [85#u8, 85#u8, 73#u8, 68#u8]
  | .Boolean => [66#u8, 79#u8, 79#u8, 76#u8, 69#u8, 65#u8, 78#u8]
  | .SyntaxId => [83#u8, 89#u8, 78#u8, 84#u8, 65#u8, 88#u8, 95#u8, 73#u8, 68#u8]
  | .IndexId => [73#u8, 78#u8, 68#u8, 69#u8, 88#u8, 95#u8, 73#u8, 68#u8]
  | .ReferenceUuid => [82#u8, 69#u8, 70#u8, 69#u8, 82#u8, 69#u8, 78#u8, 67#u8, 69#u8, 95#u8, 85#u8, 85#u8, 73#u8, 68#u8]
  | .JsonFilter => [74#u8, 83#u8, 79#u8, 78#u8, 95#u8, 70#u8, 73#u8, 76#u8, 84#u8, 69#u8, 82#u8]
  | .Credential => [67#u8, 82#u8, 69#u8, 68#u8, 69#u8, 78#u8, 84#u8, 73#u8, 65#u8, 76#u8]
  | .SecretUtf8String => [83#u8, 69#u8, 67#u8, 82#u8, 69#u8, 84#u8, 95#u8, 85#u8, 84#u8, 70#u8, 56#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8]
  | .SshKey => [83#u8, 83#u8, 72#u8, 75#u8, 69#u8, 89#u8]
  | .SecurityPrincipalName => [83#u8, 69#u8, 67#u8, 85#u8, 82#u8, 73#u8, 84#u8, 89#u8, 95#u8, 80#u8, 82#u8, 73#u8, 78#u8, 67#u8, 73#u8, 80#u8, 65#u8, 76#u8, 95#u8, 78#u8, 65#u8, 77#u8, 69#u8]
  | .Uint32 => [85#u8, 73#u8, 78#u8, 84#u8, 51#u8, 50#u8]
  | .Cid => [67#u8, 73#u8, 68#u8]
  | .NsUniqueId => [78#u8, 83#u8, 85#u8, 78#u8, 73#u8, 81#u8, 85#u8, 69#u8, 73#u8, 68#u8]
  | .DateTime => [68#u8, 65#u8, 84#u8, 69#u8, 84#u8, 73#u8, 77#u8, 69#u8]
  | .EmailAddress => [69#u8, 77#u8, 65#u8, 73#u8, 76#u8, 95#u8, 65#u8, 68#u8, 68#u8, 82#u8, 69#u8, 83#u8, 83#u8]
  | .Url => [85#u8, 82#u8, 76#u8]
  | .OauthScope => [79#u8, 65#u8, 85#u8, 84#u8, 72#u8, 95#u8, 83#u8, 67#u8, 79#u8, 80#u8, 69#u8]
  | .OauthScopeMap => [79#u8, 65#u8, 85#u8, 84#u8, 72#u8, 95#u8, 83#u8, 67#u8, 79#u8, 80#u8, 69#u8, 95#u8, 77#u8, 65#u8, 80#u8]
  | .PrivateBinary => [80#u8, 82#u8, 73#u8, 86#u8, 65#u8, 84#u8, 69#u8, 95#u8, 66#u8, 73#u8, 78#u8, 65#u8, 82#u8, 89#u8]
  | .IntentToken => [73#u8, 78#u8, 84#u8, 69#u8, 78#u8, 84#u8, 95#u8, 84#u8, 79#u8, 75#u8, 69#u8, 78#u8]
  | .Passkey => [80#u8, 65#u8, 83#u8, 83#u8, 75#u8, 69#u8, 89#u8]
  | .AttestedPasskey => [65#u8, 84#u8, 84#u8, 69#u8, 83#u8, 84#u8, 69#u8, 68#u8, 95#u8, 80#u8, 65#u8, 83#u8, 83#u8, 75#u8, 69#u8, 89#u8]
  | .Session => [83#u8, 69#u8, 83#u8, 83#u8, 73#u8, 79#u8, 78#u8]
  | .JwsKeyEs256 => [74#u8, 87#u8, 83#u8, 95#u8, 75#u8, 69#u8, 89#u8, 95#u8, 69#u8, 83#u8, 50#u8, 53#u8, 54#u8]
  | .JwsKeyRs256 => [74#u8, 87#u8, 83#u8, 95#u8, 75#u8, 69#u8, 89#u8, 95#u8, 82#u8, 83#u8, 50#u8, 53#u8, 54#u8]
  | .Oauth2Session => [79#u8, 65#u8, 85#u8, 84#u8, 72#u8, 50#u8, 83#u8, 69#u8, 83#u8, 83#u8, 73#u8, 79#u8, 78#u8]
  | .UiHint => [85#u8, 73#u8, 72#u8, 73#u8, 78#u8, 84#u8]
  | .TotpSecret => [84#u8, 79#u8, 84#u8, 80#u8, 83#u8, 69#u8, 67#u8, 82#u8, 69#u8, 84#u8]
  | .ApiToken => [65#u8, 80#u8, 73#u8, 84#u8, 79#u8, 75#u8, 69#u8, 78#u8]
  | .AuditLogString => [65#u8, 85#u8, 68#u8, 73#u8, 84#u8, 95#u8, 76#u8, 79#u8, 71#u8, 95#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8]
  | .EcKeyPrivate => [69#u8, 67#u8, 95#u8, 75#u8, 69#u8, 89#u8, 95#u8, 80#u8, 82#u8, 73#u8, 86#u8, 65#u8, 84#u8, 69#u8]
  | .Image => [73#u8, 77#u8, 65#u8, 71#u8, 69#u8]
  | .CredentialType => [67#u8, 82#u8, 69#u8, 68#u8, 69#u8, 78#u8, 84#u8, 73#u8, 65#u8, 76#u8, 95#u8, 84#u8, 89#u8, 80#u8, 69#u8]
  | .WebauthnAttestationCaList => [87#u8, 69#u8, 66#u8, 65#u8, 85#u8, 84#u8, 72#u8, 78#u8, 95#u8, 65#u8, 84#u8, 84#u8, 69#u8, 83#u8, 84#u8, 65#u8, 84#u8, 73#u8, 79#u8, 78#u8, 95#u8, 67#u8, 65#u8, 95#u8, 76#u8, 73#u8, 83#u8, 84#u8]
  | .OauthClaimMap => [79#u8, 65#u8, 85#u8, 84#u8, 72#u8, 95#u8, 67#u8, 76#u8, 65#u8, 73#u8, 77#u8, 95#u8, 77#u8, 65#u8, 80#u8]
  | .KeyInternal => [75#u8, 69#u8, 89#u8, 95#u8, 73#u8, 78#u8, 84#u8, 69#u8, 82#u8, 78#u8, 65#u8, 76#u8]
  | .HexString => [72#u8, 69#u8, 88#u8, 95#u8, 83#u8, 84#u8, 82#u8, 73#u8, 78#u8, 71#u8]
  | .Certificate => [67#u8, 69#u8, 82#u8, 84#u8, 73#u8, 70#u8, 73#u8, 67#u8, 65#u8, 84#u8, 69#u8]
  | .ApplicationPassword => [65#u8, 80#u8, 80#u8, 76#u8, 73#u8, 67#u8, 65#u8, 84#u8, 73#u8, 79#u8, 78#u8, 95#u8, 80#u8, 65#u8, 83#u8, 83#u8, 87#u8, 79#u8, 82#u8, 68#u8]
  | .Json => [74#u8, 83#u8, 79#u8, 78#u8]
  | .Message => [77#u8, 69#u8, 83#u8, 83#u8, 65#u8, 71#u8, 69#u8]
  | .Sha256 => [83#u8, 72#u8, 65#u8, 50#u8, 53#u8, 54#u8]
  | .Int64 => [73#u8, 78#u8, 84#u8, 54#u8, 52#u8]
  | .Uint64 => [85#u8, 73#u8, 78#u8, 84#u8, 54#u8, 52#u8]

theorem display_spec (syntaxValue : syntax_types.SyntaxType) :
    syntax_types.display syntaxValue ⦃ r => r.val = displayModel syntaxValue ⦄ := by
  unfold syntax_types.display
  cases syntaxValue <;> h5i_steps
  all_goals simp_all [displayModel, alloc.vec.Vec.val, alloc.slice.Slice.into_vec, Array.to_slice, Slice.from_val, Array.make_val, alloc.vec.Vec.new, Slice.new]

def indicesModel : syntax_types.SyntaxType → List syntax_types.IndexType
  | .Utf8String => [.Equality, .Presence]
  | .Utf8StringInsensitive => [.Equality, .Presence]
  | .Utf8StringIname => [.Equality, .Presence, .SubString]
  | .Uuid => [.Equality, .Presence]
  | .Boolean => [.Equality]
  | .ReferenceUuid => [.Equality, .Presence]
  | .Credential => [.Equality]
  | .SshKey => [.Equality, .Presence]
  | .SecurityPrincipalName => [.Equality, .Presence, .SubString]
  | .Uint32 | .Int64 | .Uint64 => [.Equality, .Presence, .Ordering]
  | .Cid => [.Equality, .Presence, .Ordering]
  | .NsUniqueId => [.Equality, .Presence]
  | .DateTime => [.Equality, .Presence, .Ordering]
  | .EmailAddress => [.Equality, .SubString]
  | .OauthScopeMap => [.Equality]
  | .IntentToken => [.Equality]
  | .Passkey => [.Equality]
  | .AttestedPasskey => [.Equality]
  | .Session => [.Equality]
  | .Oauth2Session => [.Equality]
  | .ApiToken => [.Equality]
  | .OauthClaimMap => [.Equality]
  | .ApplicationPassword => [.Equality]
  | .SecretUtf8String => []
  | .Url => []
  | .OauthScope => []
  | .PrivateBinary => []
  | .JwsKeyEs256 => []
  | .JwsKeyRs256 => []
  | .UiHint => []
  | .TotpSecret => []
  | .AuditLogString => []
  | .EcKeyPrivate => []
  | .Image => []
  | .CredentialType => []
  | .WebauthnAttestationCaList => []
  | .KeyInternal => []
  | .HexString => []
  | .Certificate => []
  | .SyntaxId => []
  | .IndexId => []
  | .JsonFilter => []
  | .Json => []
  | .Message => []
  | .Sha256 => [.Equality]

theorem indices_spec (syntaxValue : syntax_types.SyntaxType) :
    syntax_types.index_types syntaxValue ⦃ r => r.val = indicesModel syntaxValue ⦄ := by
  unfold syntax_types.index_types
  cases syntaxValue <;> h5i_steps
  all_goals simp_all [indicesModel, alloc.vec.Vec.val, alloc.slice.Slice.into_vec, Array.to_slice, Slice.from_val, Array.make_val, alloc.vec.Vec.new]
  all_goals rfl

end kanidm_kernel.Verified.SyntaxTypes
