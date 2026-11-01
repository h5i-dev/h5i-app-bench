import ArtifactkeeperKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def repodata_encoding_df7b79f6_content_type_model (v : finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding) : List U8 :=
  match v with
  | .Json => [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 106#u8, 115#u8, 111#u8, 110#u8]
  | .Bz2 => [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 98#u8, 122#u8, 105#u8, 112#u8, 50#u8]
  | .Zst => [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 122#u8, 115#u8, 116#u8, 100#u8]
theorem repodata_encoding_df7b79f6_content_type_complete (v : finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding) :
    finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding.content_type v ⦃r => r.val = repodata_encoding_df7b79f6_content_type_model v⦄ := by
  cases v <;> simp only [repodata_encoding_df7b79f6_content_type_model]
  all_goals simp only [finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding.content_type, finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding.upstream_filename]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def repodata_encoding_df7b79f6_upstream_filename_model (v : finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding) : List U8 :=
  match v with
  | .Json => [114#u8, 101#u8, 112#u8, 111#u8, 100#u8, 97#u8, 116#u8, 97#u8, 46#u8, 106#u8, 115#u8, 111#u8, 110#u8]
  | .Bz2 => [114#u8, 101#u8, 112#u8, 111#u8, 100#u8, 97#u8, 116#u8, 97#u8, 46#u8, 106#u8, 115#u8, 111#u8, 110#u8, 46#u8, 98#u8, 122#u8, 50#u8]
  | .Zst => [114#u8, 101#u8, 112#u8, 111#u8, 100#u8, 97#u8, 116#u8, 97#u8, 46#u8, 106#u8, 115#u8, 111#u8, 110#u8, 46#u8, 122#u8, 115#u8, 116#u8]
theorem repodata_encoding_df7b79f6_upstream_filename_complete (v : finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding) :
    finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding.upstream_filename v ⦃r => r.val = repodata_encoding_df7b79f6_upstream_filename_model v⦄ := by
  cases v <;> simp only [repodata_encoding_df7b79f6_upstream_filename_model]
  all_goals simp only [finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding.content_type, finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding.upstream_filename]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def signed_release_variant_007f0cf5_as_str_model (v : finite_catalog.signed_release_variant_007f0cf5.SignedReleaseVariant) : List U8 :=
  match v with
  | .InRelease => [73#u8, 110#u8, 82#u8, 101#u8, 108#u8, 101#u8, 97#u8, 115#u8, 101#u8]
  | .ReleaseGpg => [82#u8, 101#u8, 108#u8, 101#u8, 97#u8, 115#u8, 101#u8, 46#u8, 103#u8, 112#u8, 103#u8]
theorem signed_release_variant_007f0cf5_as_str_complete (v : finite_catalog.signed_release_variant_007f0cf5.SignedReleaseVariant) :
    finite_catalog.signed_release_variant_007f0cf5.SignedReleaseVariant.as_str v ⦃r => r.val = signed_release_variant_007f0cf5_as_str_model v⦄ := by
  cases v <;> simp only [signed_release_variant_007f0cf5_as_str_model]
  all_goals simp only [finite_catalog.signed_release_variant_007f0cf5.SignedReleaseVariant.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def upload_session_state_a43ea4df_as_str_model (v : finite_catalog.upload_session_state_a43ea4df.UploadSessionState) : List U8 :=
  match v with
  | .Open => [111#u8, 112#u8, 101#u8, 110#u8]
  | .Committing => [99#u8, 111#u8, 109#u8, 109#u8, 105#u8, 116#u8, 116#u8, 105#u8, 110#u8, 103#u8]
theorem upload_session_state_a43ea4df_as_str_complete (v : finite_catalog.upload_session_state_a43ea4df.UploadSessionState) :
    finite_catalog.upload_session_state_a43ea4df.UploadSessionState.as_str v ⦃r => r.val = upload_session_state_a43ea4df_as_str_model v⦄ := by
  cases v <;> simp only [upload_session_state_a43ea4df_as_str_model]
  all_goals simp only [finite_catalog.upload_session_state_a43ea4df.UploadSessionState.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def cached_object_verdict_b87a78e2_may_serve_stored_object_model (v : finite_catalog.cached_object_verdict_b87a78e2.CachedObjectVerdict) : Bool :=
  match v with
  | .NotProxyCache => true
  | .Vouched => true
  | .Unvouched => false
  | .Held => false
theorem cached_object_verdict_b87a78e2_may_serve_stored_object_complete (v : finite_catalog.cached_object_verdict_b87a78e2.CachedObjectVerdict) :
    finite_catalog.cached_object_verdict_b87a78e2.CachedObjectVerdict.may_serve_stored_object v ⦃r => r = cached_object_verdict_b87a78e2_may_serve_stored_object_model v⦄ := by
  cases v <;> simp only [cached_object_verdict_b87a78e2_may_serve_stored_object_model]
  all_goals simp only [finite_catalog.cached_object_verdict_b87a78e2.CachedObjectVerdict.may_serve_stored_object]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def outbound_url_context_dd3b7559_env_var_model (v : finite_catalog.outbound_url_context_dd3b7559.OutboundUrlContext) : List U8 :=
  match v with
  | .Upstream => [85#u8, 80#u8, 83#u8, 84#u8, 82#u8, 69#u8, 65#u8, 77#u8, 95#u8, 65#u8, 76#u8, 76#u8, 79#u8, 87#u8, 95#u8, 80#u8, 82#u8, 73#u8, 86#u8, 65#u8, 84#u8, 69#u8, 95#u8, 73#u8, 80#u8, 83#u8]
  | .Webhook => [87#u8, 69#u8, 66#u8, 72#u8, 79#u8, 79#u8, 75#u8, 95#u8, 65#u8, 76#u8, 76#u8, 79#u8, 87#u8, 95#u8, 80#u8, 82#u8, 73#u8, 86#u8, 65#u8, 84#u8, 69#u8, 95#u8, 73#u8, 80#u8, 83#u8]
  | .SsoDiscovery => [83#u8, 83#u8, 79#u8, 95#u8, 65#u8, 76#u8, 76#u8, 79#u8, 87#u8, 95#u8, 80#u8, 82#u8, 73#u8, 86#u8, 65#u8, 84#u8, 69#u8, 95#u8, 73#u8, 80#u8, 83#u8]
  | .TrustedInternal => [65#u8, 75#u8, 95#u8, 84#u8, 82#u8, 85#u8, 83#u8, 84#u8, 69#u8, 68#u8, 95#u8, 73#u8, 78#u8, 84#u8, 69#u8, 82#u8, 78#u8, 65#u8, 76#u8, 95#u8, 65#u8, 76#u8, 76#u8, 79#u8, 87#u8, 95#u8, 80#u8, 82#u8, 73#u8, 86#u8, 65#u8, 84#u8, 69#u8, 95#u8, 73#u8, 80#u8, 83#u8]
theorem outbound_url_context_dd3b7559_env_var_complete (v : finite_catalog.outbound_url_context_dd3b7559.OutboundUrlContext) :
    finite_catalog.outbound_url_context_dd3b7559.OutboundUrlContext.env_var v ⦃r => r.val = outbound_url_context_dd3b7559_env_var_model v⦄ := by
  cases v <;> simp only [outbound_url_context_dd3b7559_env_var_model]
  all_goals simp only [finite_catalog.outbound_url_context_dd3b7559.OutboundUrlContext.env_var]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def jwt_secret_warning_4946346a_message_model (v : finite_catalog.jwt_secret_warning_4946346a.JwtSecretWarning) : List U8 :=
  match v with
  | .TooShort => [105#u8, 116#u8, 32#u8, 105#u8, 115#u8, 32#u8, 115#u8, 104#u8, 111#u8, 114#u8, 116#u8, 101#u8, 114#u8, 32#u8, 116#u8, 104#u8, 97#u8, 110#u8, 32#u8, 51#u8, 50#u8, 32#u8, 99#u8, 104#u8, 97#u8, 114#u8, 97#u8, 99#u8, 116#u8, 101#u8, 114#u8, 115#u8, 46#u8]
  | .KnownPlaceholder => [105#u8, 116#u8, 32#u8, 105#u8, 115#u8, 32#u8, 97#u8, 32#u8, 107#u8, 110#u8, 111#u8, 119#u8, 110#u8, 32#u8, 112#u8, 108#u8, 97#u8, 99#u8, 101#u8, 104#u8, 111#u8, 108#u8, 100#u8, 101#u8, 114#u8, 47#u8, 100#u8, 101#u8, 102#u8, 97#u8, 117#u8, 108#u8, 116#u8, 32#u8, 118#u8, 97#u8, 108#u8, 117#u8, 101#u8, 46#u8]
  | .LowEntropy => [105#u8, 116#u8, 32#u8, 104#u8, 97#u8, 115#u8, 32#u8, 108#u8, 111#u8, 119#u8, 32#u8, 101#u8, 110#u8, 116#u8, 114#u8, 111#u8, 112#u8, 121#u8, 32#u8, 40#u8, 117#u8, 110#u8, 100#u8, 101#u8, 114#u8, 32#u8, 49#u8, 50#u8, 56#u8, 32#u8, 101#u8, 115#u8, 116#u8, 105#u8, 109#u8, 97#u8, 116#u8, 101#u8, 100#u8, 32#u8, 98#u8, 105#u8, 116#u8, 115#u8, 44#u8, 32#u8, 111#u8, 114#u8, 32#u8, 97#u8, 110#u8, 32#u8, 111#u8, 98#u8, 118#u8, 105#u8, 111#u8, 117#u8, 115#u8, 32#u8, 114#u8, 101#u8, 112#u8, 101#u8, 97#u8, 116#u8, 32#u8, 111#u8, 114#u8, 32#u8, 115#u8, 101#u8, 113#u8, 117#u8, 101#u8, 110#u8, 99#u8, 101#u8, 41#u8, 46#u8]
theorem jwt_secret_warning_4946346a_message_complete (v : finite_catalog.jwt_secret_warning_4946346a.JwtSecretWarning) :
    finite_catalog.jwt_secret_warning_4946346a.JwtSecretWarning.message v ⦃r => r.val = jwt_secret_warning_4946346a_message_model v⦄ := by
  cases v <;> simp only [jwt_secret_warning_4946346a_message_model]
  all_goals simp only [finite_catalog.jwt_secret_warning_4946346a.JwtSecretWarning.message]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def incus_file_type_eee7eb85_as_str_model (v : finite_catalog.incus_file_type_eee7eb85.IncusFileType) : List U8 :=
  match v with
  | .UnifiedTarball => [117#u8, 110#u8, 105#u8, 102#u8, 105#u8, 101#u8, 100#u8, 95#u8, 116#u8, 97#u8, 114#u8, 98#u8, 97#u8, 108#u8, 108#u8]
  | .MetadataTarball => [109#u8, 101#u8, 116#u8, 97#u8, 100#u8, 97#u8, 116#u8, 97#u8, 95#u8, 116#u8, 97#u8, 114#u8, 98#u8, 97#u8, 108#u8, 108#u8]
  | .RootfsSquashfs => [114#u8, 111#u8, 111#u8, 116#u8, 102#u8, 115#u8, 95#u8, 115#u8, 113#u8, 117#u8, 97#u8, 115#u8, 104#u8, 102#u8, 115#u8]
  | .RootfsQcow2 => [114#u8, 111#u8, 111#u8, 116#u8, 102#u8, 115#u8, 95#u8, 113#u8, 99#u8, 111#u8, 119#u8, 50#u8]
  | .StreamsIndex => [115#u8, 116#u8, 114#u8, 101#u8, 97#u8, 109#u8, 115#u8, 95#u8, 105#u8, 110#u8, 100#u8, 101#u8, 120#u8]
theorem incus_file_type_eee7eb85_as_str_complete (v : finite_catalog.incus_file_type_eee7eb85.IncusFileType) :
    finite_catalog.incus_file_type_eee7eb85.IncusFileType.as_str v ⦃r => r.val = incus_file_type_eee7eb85_as_str_model v⦄ := by
  cases v <;> simp only [incus_file_type_eee7eb85_as_str_model]
  all_goals simp only [finite_catalog.incus_file_type_eee7eb85.IncusFileType.as_str, finite_catalog.incus_file_type_eee7eb85.IncusFileType.is_tarball]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def incus_file_type_eee7eb85_is_tarball_model (v : finite_catalog.incus_file_type_eee7eb85.IncusFileType) : Bool :=
  match v with
  | .UnifiedTarball => true
  | .MetadataTarball => true
  | .RootfsSquashfs => false
  | .RootfsQcow2 => false
  | .StreamsIndex => false
theorem incus_file_type_eee7eb85_is_tarball_complete (v : finite_catalog.incus_file_type_eee7eb85.IncusFileType) :
    finite_catalog.incus_file_type_eee7eb85.IncusFileType.is_tarball v ⦃r => r = incus_file_type_eee7eb85_is_tarball_model v⦄ := by
  cases v <;> simp only [incus_file_type_eee7eb85_is_tarball_model]
  all_goals simp only [finite_catalog.incus_file_type_eee7eb85.IncusFileType.as_str, finite_catalog.incus_file_type_eee7eb85.IncusFileType.is_tarball]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def sbom_format_104be95e_as_str_model (v : finite_catalog.sbom_format_104be95e.SbomFormat) : List U8 :=
  match v with
  | .CycloneDX => [99#u8, 121#u8, 99#u8, 108#u8, 111#u8, 110#u8, 101#u8, 100#u8, 120#u8]
  | .SPDX => [115#u8, 112#u8, 100#u8, 120#u8]
theorem sbom_format_104be95e_as_str_complete (v : finite_catalog.sbom_format_104be95e.SbomFormat) :
    finite_catalog.sbom_format_104be95e.SbomFormat.as_str v ⦃r => r.val = sbom_format_104be95e_as_str_model v⦄ := by
  cases v <;> simp only [sbom_format_104be95e_as_str_model]
  all_goals simp only [finite_catalog.sbom_format_104be95e.SbomFormat.as_str, finite_catalog.sbom_format_104be95e.SbomFormat.content_type]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def sbom_format_104be95e_content_type_model (v : finite_catalog.sbom_format_104be95e.SbomFormat) : List U8 :=
  match v with
  | .CycloneDX => [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 99#u8, 121#u8, 99#u8, 108#u8, 111#u8, 110#u8, 101#u8, 100#u8, 120#u8, 43#u8, 106#u8, 115#u8, 111#u8, 110#u8]
  | .SPDX => [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 115#u8, 112#u8, 100#u8, 120#u8, 43#u8, 106#u8, 115#u8, 111#u8, 110#u8]
theorem sbom_format_104be95e_content_type_complete (v : finite_catalog.sbom_format_104be95e.SbomFormat) :
    finite_catalog.sbom_format_104be95e.SbomFormat.content_type v ⦃r => r.val = sbom_format_104be95e_content_type_model v⦄ := by
  cases v <;> simp only [sbom_format_104be95e_content_type_model]
  all_goals simp only [finite_catalog.sbom_format_104be95e.SbomFormat.as_str, finite_catalog.sbom_format_104be95e.SbomFormat.content_type]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def cve_status_104be95e_as_str_model (v : finite_catalog.cve_status_104be95e.CveStatus) : List U8 :=
  match v with
  | .Open => [111#u8, 112#u8, 101#u8, 110#u8]
  | .Fixed => [102#u8, 105#u8, 120#u8, 101#u8, 100#u8]
  | .Acknowledged => [97#u8, 99#u8, 107#u8, 110#u8, 111#u8, 119#u8, 108#u8, 101#u8, 100#u8, 103#u8, 101#u8, 100#u8]
  | .FalsePositive => [102#u8, 97#u8, 108#u8, 115#u8, 101#u8, 95#u8, 112#u8, 111#u8, 115#u8, 105#u8, 116#u8, 105#u8, 118#u8, 101#u8]
theorem cve_status_104be95e_as_str_complete (v : finite_catalog.cve_status_104be95e.CveStatus) :
    finite_catalog.cve_status_104be95e.CveStatus.as_str v ⦃r => r.val = cve_status_104be95e_as_str_model v⦄ := by
  cases v <;> simp only [cve_status_104be95e_as_str_model]
  all_goals simp only [finite_catalog.cve_status_104be95e.CveStatus.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def policy_action_104be95e_as_str_model (v : finite_catalog.policy_action_104be95e.PolicyAction) : List U8 :=
  match v with
  | .Allow => [97#u8, 108#u8, 108#u8, 111#u8, 119#u8]
  | .Warn => [119#u8, 97#u8, 114#u8, 110#u8]
  | .Block => [98#u8, 108#u8, 111#u8, 99#u8, 107#u8]
theorem policy_action_104be95e_as_str_complete (v : finite_catalog.policy_action_104be95e.PolicyAction) :
    finite_catalog.policy_action_104be95e.PolicyAction.as_str v ⦃r => r.val = policy_action_104be95e_as_str_model v⦄ := by
  cases v <;> simp only [policy_action_104be95e_as_str_model]
  all_goals simp only [finite_catalog.policy_action_104be95e.PolicyAction.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def severity_1259a9af_penalty_weight_model (v : finite_catalog.severity_1259a9af.Severity) : I32 :=
  match v with
  | .Critical => 25#i32
  | .High => 10#i32
  | .Medium => 3#i32
  | .Low => 1#i32
  | .Info => 0#i32
theorem severity_1259a9af_penalty_weight_complete (v : finite_catalog.severity_1259a9af.Severity) :
    finite_catalog.severity_1259a9af.Severity.penalty_weight v ⦃r => r = severity_1259a9af_penalty_weight_model v⦄ := by
  cases v <;> simp only [severity_1259a9af_penalty_weight_model]
  all_goals simp only [finite_catalog.severity_1259a9af.Severity.penalty_weight, finite_catalog.severity_1259a9af.Severity.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def severity_1259a9af_as_str_model (v : finite_catalog.severity_1259a9af.Severity) : List U8 :=
  match v with
  | .Critical => [99#u8, 114#u8, 105#u8, 116#u8, 105#u8, 99#u8, 97#u8, 108#u8]
  | .High => [104#u8, 105#u8, 103#u8, 104#u8]
  | .Medium => [109#u8, 101#u8, 100#u8, 105#u8, 117#u8, 109#u8]
  | .Low => [108#u8, 111#u8, 119#u8]
  | .Info => [105#u8, 110#u8, 102#u8, 111#u8]
theorem severity_1259a9af_as_str_complete (v : finite_catalog.severity_1259a9af.Severity) :
    finite_catalog.severity_1259a9af.Severity.as_str v ⦃r => r.val = severity_1259a9af_as_str_model v⦄ := by
  cases v <;> simp only [severity_1259a9af_as_str_model]
  all_goals simp only [finite_catalog.severity_1259a9af.Severity.penalty_weight, finite_catalog.severity_1259a9af.Severity.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def age_gate_mode_3fdb45b7_as_str_model (v : finite_catalog.age_gate_mode_3fdb45b7.AgeGateMode) : List U8 :=
  match v with
  | .UpstreamPublishTime => [117#u8, 112#u8, 115#u8, 116#u8, 114#u8, 101#u8, 97#u8, 109#u8, 95#u8, 112#u8, 117#u8, 98#u8, 108#u8, 105#u8, 115#u8, 104#u8, 95#u8, 116#u8, 105#u8, 109#u8, 101#u8]
  | .FirstSeen => [102#u8, 105#u8, 114#u8, 115#u8, 116#u8, 95#u8, 115#u8, 101#u8, 101#u8, 110#u8]
theorem age_gate_mode_3fdb45b7_as_str_complete (v : finite_catalog.age_gate_mode_3fdb45b7.AgeGateMode) :
    finite_catalog.age_gate_mode_3fdb45b7.AgeGateMode.as_str v ⦃r => r.val = age_gate_mode_3fdb45b7_as_str_model v⦄ := by
  cases v <;> simp only [age_gate_mode_3fdb45b7_as_str_model]
  all_goals simp only [finite_catalog.age_gate_mode_3fdb45b7.AgeGateMode.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def age_gate_review_status_3fdb45b7_as_str_model (v : finite_catalog.age_gate_review_status_3fdb45b7.AgeGateReviewStatus) : List U8 :=
  match v with
  | .Pending => [112#u8, 101#u8, 110#u8, 100#u8, 105#u8, 110#u8, 103#u8]
  | .Approved => [97#u8, 112#u8, 112#u8, 114#u8, 111#u8, 118#u8, 101#u8, 100#u8]
  | .Rejected => [114#u8, 101#u8, 106#u8, 101#u8, 99#u8, 116#u8, 101#u8, 100#u8]
theorem age_gate_review_status_3fdb45b7_as_str_complete (v : finite_catalog.age_gate_review_status_3fdb45b7.AgeGateReviewStatus) :
    finite_catalog.age_gate_review_status_3fdb45b7.AgeGateReviewStatus.as_str v ⦃r => r.val = age_gate_review_status_3fdb45b7_as_str_model v⦄ := by
  cases v <;> simp only [age_gate_review_status_3fdb45b7_as_str_model]
  all_goals simp only [finite_catalog.age_gate_review_status_3fdb45b7.AgeGateReviewStatus.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def audit_stream_mode_8053ef47_name_model (v : finite_catalog.audit_stream_mode_8053ef47.AuditStreamMode) : List U8 :=
  match v with
  | .Off => [111#u8, 102#u8, 102#u8]
  | .Stdout => [115#u8, 116#u8, 100#u8, 111#u8, 117#u8, 116#u8]
theorem audit_stream_mode_8053ef47_name_complete (v : finite_catalog.audit_stream_mode_8053ef47.AuditStreamMode) :
    finite_catalog.audit_stream_mode_8053ef47.AuditStreamMode.name v ⦃r => r.val = audit_stream_mode_8053ef47_name_model v⦄ := by
  cases v <;> simp only [audit_stream_mode_8053ef47_name_model]
  all_goals simp only [finite_catalog.audit_stream_mode_8053ef47.AuditStreamMode.name]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def audit_action_3ef0ea8f_as_str_model (v : finite_catalog.audit_action_3ef0ea8f.AuditAction) : List U8 :=
  match v with
  | .Login => [76#u8, 79#u8, 71#u8, 73#u8, 78#u8]
  | .Logout => [76#u8, 79#u8, 71#u8, 79#u8, 85#u8, 84#u8]
  | .LoginFailed => [76#u8, 79#u8, 71#u8, 73#u8, 78#u8, 95#u8, 70#u8, 65#u8, 73#u8, 76#u8, 69#u8, 68#u8]
  | .PasswordChanged => [80#u8, 65#u8, 83#u8, 83#u8, 87#u8, 79#u8, 82#u8, 68#u8, 95#u8, 67#u8, 72#u8, 65#u8, 78#u8, 71#u8, 69#u8, 68#u8]
  | .ApiTokenCreated => [65#u8, 80#u8, 73#u8, 95#u8, 84#u8, 79#u8, 75#u8, 69#u8, 78#u8, 95#u8, 67#u8, 82#u8, 69#u8, 65#u8, 84#u8, 69#u8, 68#u8]
  | .ApiTokenRevoked => [65#u8, 80#u8, 73#u8, 95#u8, 84#u8, 79#u8, 75#u8, 69#u8, 78#u8, 95#u8, 82#u8, 69#u8, 86#u8, 79#u8, 75#u8, 69#u8, 68#u8]
  | .UserCreated => [85#u8, 83#u8, 69#u8, 82#u8, 95#u8, 67#u8, 82#u8, 69#u8, 65#u8, 84#u8, 69#u8, 68#u8]
  | .UserUpdated => [85#u8, 83#u8, 69#u8, 82#u8, 95#u8, 85#u8, 80#u8, 68#u8, 65#u8, 84#u8, 69#u8, 68#u8]
  | .UserDeleted => [85#u8, 83#u8, 69#u8, 82#u8, 95#u8, 68#u8, 69#u8, 76#u8, 69#u8, 84#u8, 69#u8, 68#u8]
  | .UserDisabled => [85#u8, 83#u8, 69#u8, 82#u8, 95#u8, 68#u8, 73#u8, 83#u8, 65#u8, 66#u8, 76#u8, 69#u8, 68#u8]
  | .RoleAssigned => [82#u8, 79#u8, 76#u8, 69#u8, 95#u8, 65#u8, 83#u8, 83#u8, 73#u8, 71#u8, 78#u8, 69#u8, 68#u8]
  | .RoleRevoked => [82#u8, 79#u8, 76#u8, 69#u8, 95#u8, 82#u8, 69#u8, 86#u8, 79#u8, 75#u8, 69#u8, 68#u8]
  | .RepositoryCreated => [82#u8, 69#u8, 80#u8, 79#u8, 83#u8, 73#u8, 84#u8, 79#u8, 82#u8, 89#u8, 95#u8, 67#u8, 82#u8, 69#u8, 65#u8, 84#u8, 69#u8, 68#u8]
  | .RepositoryUpdated => [82#u8, 69#u8, 80#u8, 79#u8, 83#u8, 73#u8, 84#u8, 79#u8, 82#u8, 89#u8, 95#u8, 85#u8, 80#u8, 68#u8, 65#u8, 84#u8, 69#u8, 68#u8]
  | .RepositoryDeleted => [82#u8, 69#u8, 80#u8, 79#u8, 83#u8, 73#u8, 84#u8, 79#u8, 82#u8, 89#u8, 95#u8, 68#u8, 69#u8, 76#u8, 69#u8, 84#u8, 69#u8, 68#u8]
  | .RepositoryPermissionChanged => [82#u8, 69#u8, 80#u8, 79#u8, 83#u8, 73#u8, 84#u8, 79#u8, 82#u8, 89#u8, 95#u8, 80#u8, 69#u8, 82#u8, 77#u8, 73#u8, 83#u8, 83#u8, 73#u8, 79#u8, 78#u8, 95#u8, 67#u8, 72#u8, 65#u8, 78#u8, 71#u8, 69#u8, 68#u8]
  | .ArtifactUploaded => [65#u8, 82#u8, 84#u8, 73#u8, 70#u8, 65#u8, 67#u8, 84#u8, 95#u8, 85#u8, 80#u8, 76#u8, 79#u8, 65#u8, 68#u8, 69#u8, 68#u8]
  | .ArtifactDownloaded => [65#u8, 82#u8, 84#u8, 73#u8, 70#u8, 65#u8, 67#u8, 84#u8, 95#u8, 68#u8, 79#u8, 87#u8, 78#u8, 76#u8, 79#u8, 65#u8, 68#u8, 69#u8, 68#u8]
  | .ArtifactDeleted => [65#u8, 82#u8, 84#u8, 73#u8, 70#u8, 65#u8, 67#u8, 84#u8, 95#u8, 68#u8, 69#u8, 76#u8, 69#u8, 84#u8, 69#u8, 68#u8]
  | .ArtifactMetadataUpdated => [65#u8, 82#u8, 84#u8, 73#u8, 70#u8, 65#u8, 67#u8, 84#u8, 95#u8, 77#u8, 69#u8, 84#u8, 65#u8, 68#u8, 65#u8, 84#u8, 65#u8, 95#u8, 85#u8, 80#u8, 68#u8, 65#u8, 84#u8, 69#u8, 68#u8]
  | .BackupStarted => [66#u8, 65#u8, 67#u8, 75#u8, 85#u8, 80#u8, 95#u8, 83#u8, 84#u8, 65#u8, 82#u8, 84#u8, 69#u8, 68#u8]
  | .BackupCompleted => [66#u8, 65#u8, 67#u8, 75#u8, 85#u8, 80#u8, 95#u8, 67#u8, 79#u8, 77#u8, 80#u8, 76#u8, 69#u8, 84#u8, 69#u8, 68#u8]
  | .BackupFailed => [66#u8, 65#u8, 67#u8, 75#u8, 85#u8, 80#u8, 95#u8, 70#u8, 65#u8, 73#u8, 76#u8, 69#u8, 68#u8]
  | .RestoreStarted => [82#u8, 69#u8, 83#u8, 84#u8, 79#u8, 82#u8, 69#u8, 95#u8, 83#u8, 84#u8, 65#u8, 82#u8, 84#u8, 69#u8, 68#u8]
  | .RestoreCompleted => [82#u8, 69#u8, 83#u8, 84#u8, 79#u8, 82#u8, 69#u8, 95#u8, 67#u8, 79#u8, 77#u8, 80#u8, 76#u8, 69#u8, 84#u8, 69#u8, 68#u8]
  | .RestoreFailed => [82#u8, 69#u8, 83#u8, 84#u8, 79#u8, 82#u8, 69#u8, 95#u8, 70#u8, 65#u8, 73#u8, 76#u8, 69#u8, 68#u8]
  | .PeerRegistered => [80#u8, 69#u8, 69#u8, 82#u8, 95#u8, 82#u8, 69#u8, 71#u8, 73#u8, 83#u8, 84#u8, 69#u8, 82#u8, 69#u8, 68#u8]
  | .PeerUnregistered => [80#u8, 69#u8, 69#u8, 82#u8, 95#u8, 85#u8, 78#u8, 82#u8, 69#u8, 71#u8, 73#u8, 83#u8, 84#u8, 69#u8, 82#u8, 69#u8, 68#u8]
  | .PeerSyncStarted => [80#u8, 69#u8, 69#u8, 82#u8, 95#u8, 83#u8, 89#u8, 78#u8, 67#u8, 95#u8, 83#u8, 84#u8, 65#u8, 82#u8, 84#u8, 69#u8, 68#u8]
  | .PeerSyncCompleted => [80#u8, 69#u8, 69#u8, 82#u8, 95#u8, 83#u8, 89#u8, 78#u8, 67#u8, 95#u8, 67#u8, 79#u8, 77#u8, 80#u8, 76#u8, 69#u8, 84#u8, 69#u8, 68#u8]
  | .SettingChanged => [83#u8, 69#u8, 84#u8, 84#u8, 73#u8, 78#u8, 71#u8, 95#u8, 67#u8, 72#u8, 65#u8, 78#u8, 71#u8, 69#u8, 68#u8]
  | .PluginInstalled => [80#u8, 76#u8, 85#u8, 71#u8, 73#u8, 78#u8, 95#u8, 73#u8, 78#u8, 83#u8, 84#u8, 65#u8, 76#u8, 76#u8, 69#u8, 68#u8]
  | .PluginUninstalled => [80#u8, 76#u8, 85#u8, 71#u8, 73#u8, 78#u8, 95#u8, 85#u8, 78#u8, 73#u8, 78#u8, 83#u8, 84#u8, 65#u8, 76#u8, 76#u8, 69#u8, 68#u8]
  | .PluginEnabled => [80#u8, 76#u8, 85#u8, 71#u8, 73#u8, 78#u8, 95#u8, 69#u8, 78#u8, 65#u8, 66#u8, 76#u8, 69#u8, 68#u8]
  | .PluginDisabled => [80#u8, 76#u8, 85#u8, 71#u8, 73#u8, 78#u8, 95#u8, 68#u8, 73#u8, 83#u8, 65#u8, 66#u8, 76#u8, 69#u8, 68#u8]
  | .EmailSubscriptionCreated => [69#u8, 77#u8, 65#u8, 73#u8, 76#u8, 95#u8, 83#u8, 85#u8, 66#u8, 83#u8, 67#u8, 82#u8, 73#u8, 80#u8, 84#u8, 73#u8, 79#u8, 78#u8, 95#u8, 67#u8, 82#u8, 69#u8, 65#u8, 84#u8, 69#u8, 68#u8]
  | .EmailSubscriptionDeleted => [69#u8, 77#u8, 65#u8, 73#u8, 76#u8, 95#u8, 83#u8, 85#u8, 66#u8, 83#u8, 67#u8, 82#u8, 73#u8, 80#u8, 84#u8, 73#u8, 79#u8, 78#u8, 95#u8, 68#u8, 69#u8, 76#u8, 69#u8, 84#u8, 69#u8, 68#u8]
  | .SbomGenerated => [83#u8, 66#u8, 79#u8, 77#u8, 95#u8, 71#u8, 69#u8, 78#u8, 69#u8, 82#u8, 65#u8, 84#u8, 69#u8, 68#u8]
  | .SbomRead => [83#u8, 66#u8, 79#u8, 77#u8, 95#u8, 82#u8, 69#u8, 65#u8, 68#u8]
  | .ScanReaped => [83#u8, 67#u8, 65#u8, 78#u8, 95#u8, 82#u8, 69#u8, 65#u8, 80#u8, 69#u8, 68#u8]
  | .TotpEnabled => [84#u8, 79#u8, 84#u8, 80#u8, 95#u8, 69#u8, 78#u8, 65#u8, 66#u8, 76#u8, 69#u8, 68#u8]
  | .TotpDisabled => [84#u8, 79#u8, 84#u8, 80#u8, 95#u8, 68#u8, 73#u8, 83#u8, 65#u8, 66#u8, 76#u8, 69#u8, 68#u8]
  | .SessionsInvalidated => [83#u8, 69#u8, 83#u8, 83#u8, 73#u8, 79#u8, 78#u8, 83#u8, 95#u8, 73#u8, 78#u8, 86#u8, 65#u8, 76#u8, 73#u8, 68#u8, 65#u8, 84#u8, 69#u8, 68#u8]
  | .TotpEnrollmentRequired => [84#u8, 79#u8, 84#u8, 80#u8, 95#u8, 69#u8, 78#u8, 82#u8, 79#u8, 76#u8, 76#u8, 77#u8, 69#u8, 78#u8, 84#u8, 95#u8, 82#u8, 69#u8, 81#u8, 85#u8, 73#u8, 82#u8, 69#u8, 68#u8]
  | .TotpPolicyChanged => [84#u8, 79#u8, 84#u8, 80#u8, 95#u8, 80#u8, 79#u8, 76#u8, 73#u8, 67#u8, 89#u8, 95#u8, 67#u8, 72#u8, 65#u8, 78#u8, 71#u8, 69#u8, 68#u8]
  | .ApiTokenPolicyChanged => [65#u8, 80#u8, 73#u8, 95#u8, 84#u8, 79#u8, 75#u8, 69#u8, 78#u8, 95#u8, 80#u8, 79#u8, 76#u8, 73#u8, 67#u8, 89#u8, 95#u8, 67#u8, 72#u8, 65#u8, 78#u8, 71#u8, 69#u8, 68#u8]
  | .AgeGateQueued => [65#u8, 71#u8, 69#u8, 95#u8, 71#u8, 65#u8, 84#u8, 69#u8, 95#u8, 81#u8, 85#u8, 69#u8, 85#u8, 69#u8, 68#u8]
  | .AgeGateApproved => [65#u8, 71#u8, 69#u8, 95#u8, 71#u8, 65#u8, 84#u8, 69#u8, 95#u8, 65#u8, 80#u8, 80#u8, 82#u8, 79#u8, 86#u8, 69#u8, 68#u8]
  | .AgeGateRejected => [65#u8, 71#u8, 69#u8, 95#u8, 71#u8, 65#u8, 84#u8, 69#u8, 95#u8, 82#u8, 69#u8, 74#u8, 69#u8, 67#u8, 84#u8, 69#u8, 68#u8]
  | .AgeGateReopened => [65#u8, 71#u8, 69#u8, 95#u8, 71#u8, 65#u8, 84#u8, 69#u8, 95#u8, 82#u8, 69#u8, 79#u8, 80#u8, 69#u8, 78#u8, 69#u8, 68#u8]
  | .PermissionDenied => [80#u8, 69#u8, 82#u8, 77#u8, 73#u8, 83#u8, 83#u8, 73#u8, 79#u8, 78#u8, 95#u8, 68#u8, 69#u8, 78#u8, 73#u8, 69#u8, 68#u8]
  | .CurationSyncTriggered => [67#u8, 85#u8, 82#u8, 65#u8, 84#u8, 73#u8, 79#u8, 78#u8, 95#u8, 83#u8, 89#u8, 78#u8, 67#u8, 95#u8, 84#u8, 82#u8, 73#u8, 71#u8, 71#u8, 69#u8, 82#u8, 69#u8, 68#u8]
  | .CurationVersionCreated => [67#u8, 85#u8, 82#u8, 65#u8, 84#u8, 73#u8, 79#u8, 78#u8, 95#u8, 86#u8, 69#u8, 82#u8, 83#u8, 73#u8, 79#u8, 78#u8, 95#u8, 67#u8, 82#u8, 69#u8, 65#u8, 84#u8, 69#u8, 68#u8]
  | .CurationVersionPublished => [67#u8, 85#u8, 82#u8, 65#u8, 84#u8, 73#u8, 79#u8, 78#u8, 95#u8, 86#u8, 69#u8, 82#u8, 83#u8, 73#u8, 79#u8, 78#u8, 95#u8, 80#u8, 85#u8, 66#u8, 76#u8, 73#u8, 83#u8, 72#u8, 69#u8, 68#u8]
  | .ProxyScanVerdictDeleted => [80#u8, 82#u8, 79#u8, 88#u8, 89#u8, 95#u8, 83#u8, 67#u8, 65#u8, 78#u8, 95#u8, 86#u8, 69#u8, 82#u8, 68#u8, 73#u8, 67#u8, 84#u8, 95#u8, 68#u8, 69#u8, 76#u8, 69#u8, 84#u8, 69#u8, 68#u8]
  | .CiOidcGroupBindingReconciled => [67#u8, 73#u8, 95#u8, 79#u8, 73#u8, 68#u8, 67#u8, 95#u8, 71#u8, 82#u8, 79#u8, 85#u8, 80#u8, 95#u8, 66#u8, 73#u8, 78#u8, 68#u8, 73#u8, 78#u8, 71#u8, 95#u8, 82#u8, 69#u8, 67#u8, 79#u8, 78#u8, 67#u8, 73#u8, 76#u8, 69#u8, 68#u8]
theorem audit_action_3ef0ea8f_as_str_complete (v : finite_catalog.audit_action_3ef0ea8f.AuditAction) :
    finite_catalog.audit_action_3ef0ea8f.AuditAction.as_str v ⦃r => r.val = audit_action_3ef0ea8f_as_str_model v⦄ := by
  cases v <;> simp only [audit_action_3ef0ea8f_as_str_model]
  all_goals simp only [finite_catalog.audit_action_3ef0ea8f.AuditAction.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def resource_type_3ef0ea8f_as_str_model (v : finite_catalog.resource_type_3ef0ea8f.ResourceType) : List U8 :=
  match v with
  | .User => [117#u8, 115#u8, 101#u8, 114#u8]
  | .Repository => [114#u8, 101#u8, 112#u8, 111#u8, 115#u8, 105#u8, 116#u8, 111#u8, 114#u8, 121#u8]
  | .Artifact => [97#u8, 114#u8, 116#u8, 105#u8, 102#u8, 97#u8, 99#u8, 116#u8]
  | .Role => [114#u8, 111#u8, 108#u8, 101#u8]
  | .ApiToken => [97#u8, 112#u8, 105#u8, 95#u8, 116#u8, 111#u8, 107#u8, 101#u8, 110#u8]
  | .PeerInstance => [112#u8, 101#u8, 101#u8, 114#u8, 95#u8, 105#u8, 110#u8, 115#u8, 116#u8, 97#u8, 110#u8, 99#u8, 101#u8]
  | .Backup => [98#u8, 97#u8, 99#u8, 107#u8, 117#u8, 112#u8]
  | .Setting => [115#u8, 101#u8, 116#u8, 116#u8, 105#u8, 110#u8, 103#u8]
  | .Plugin => [112#u8, 108#u8, 117#u8, 103#u8, 105#u8, 110#u8]
  | .ScanResult => [115#u8, 99#u8, 97#u8, 110#u8, 95#u8, 114#u8, 101#u8, 115#u8, 117#u8, 108#u8, 116#u8]
theorem resource_type_3ef0ea8f_as_str_complete (v : finite_catalog.resource_type_3ef0ea8f.ResourceType) :
    finite_catalog.resource_type_3ef0ea8f.ResourceType.as_str v ⦃r => r.val = resource_type_3ef0ea8f_as_str_model v⦄ := by
  cases v <;> simp only [resource_type_3ef0ea8f_as_str_model]
  all_goals simp only [finite_catalog.resource_type_3ef0ea8f.ResourceType.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def noarch_kind_b8478f7b_as_str_model (v : finite_catalog.noarch_kind_b8478f7b.NoarchKind) : List U8 :=
  match v with
  | .Python => [112#u8, 121#u8, 116#u8, 104#u8, 111#u8, 110#u8]
  | .Generic => [103#u8, 101#u8, 110#u8, 101#u8, 114#u8, 105#u8, 99#u8]
theorem noarch_kind_b8478f7b_as_str_complete (v : finite_catalog.noarch_kind_b8478f7b.NoarchKind) :
    finite_catalog.noarch_kind_b8478f7b.NoarchKind.as_str v ⦃r => r.val = noarch_kind_b8478f7b_as_str_model v⦄ := by
  cases v <;> simp only [noarch_kind_b8478f7b_as_str_model]
  all_goals simp only [finite_catalog.noarch_kind_b8478f7b.NoarchKind.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def conda_archive_type_b8478f7b_as_str_model (v : finite_catalog.conda_archive_type_b8478f7b.CondaArchiveType) : List U8 :=
  match v with
  | .CondaV2 => [99#u8, 111#u8, 110#u8, 100#u8, 97#u8]
  | .TarBz2 => [116#u8, 97#u8, 114#u8, 46#u8, 98#u8, 122#u8, 50#u8]
theorem conda_archive_type_b8478f7b_as_str_complete (v : finite_catalog.conda_archive_type_b8478f7b.CondaArchiveType) :
    finite_catalog.conda_archive_type_b8478f7b.CondaArchiveType.as_str v ⦃r => r.val = conda_archive_type_b8478f7b_as_str_model v⦄ := by
  cases v <;> simp only [conda_archive_type_b8478f7b_as_str_model]
  all_goals simp only [finite_catalog.conda_archive_type_b8478f7b.CondaArchiveType.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def script_kind_a04cea8b_as_str_model (v : finite_catalog.script_kind_a04cea8b.ScriptKind) : List U8 :=
  match v with
  | .PostLink => [112#u8, 111#u8, 115#u8, 116#u8, 45#u8, 108#u8, 105#u8, 110#u8, 107#u8]
  | .PreLink => [112#u8, 114#u8, 101#u8, 45#u8, 108#u8, 105#u8, 110#u8, 107#u8]
  | .PreUnlink => [112#u8, 114#u8, 101#u8, 45#u8, 117#u8, 110#u8, 108#u8, 105#u8, 110#u8, 107#u8]
  | .PreInstall => [112#u8, 114#u8, 101#u8, 105#u8, 110#u8, 115#u8, 116#u8, 97#u8, 108#u8, 108#u8]
  | .Install => [105#u8, 110#u8, 115#u8, 116#u8, 97#u8, 108#u8, 108#u8]
  | .PostInstall => [112#u8, 111#u8, 115#u8, 116#u8, 105#u8, 110#u8, 115#u8, 116#u8, 97#u8, 108#u8, 108#u8]
  | .Prepare => [112#u8, 114#u8, 101#u8, 112#u8, 97#u8, 114#u8, 101#u8]
  | .RpmPre => [114#u8, 112#u8, 109#u8, 45#u8, 112#u8, 114#u8, 101#u8]
  | .RpmPost => [114#u8, 112#u8, 109#u8, 45#u8, 112#u8, 111#u8, 115#u8, 116#u8]
  | .RpmPreUn => [114#u8, 112#u8, 109#u8, 45#u8, 112#u8, 114#u8, 101#u8, 117#u8, 110#u8]
  | .RpmPostUn => [114#u8, 112#u8, 109#u8, 45#u8, 112#u8, 111#u8, 115#u8, 116#u8, 117#u8, 110#u8]
  | .DebPreInst => [100#u8, 101#u8, 98#u8, 45#u8, 112#u8, 114#u8, 101#u8, 105#u8, 110#u8, 115#u8, 116#u8]
  | .DebPostInst => [100#u8, 101#u8, 98#u8, 45#u8, 112#u8, 111#u8, 115#u8, 116#u8, 105#u8, 110#u8, 115#u8, 116#u8]
  | .DebPreRm => [100#u8, 101#u8, 98#u8, 45#u8, 112#u8, 114#u8, 101#u8, 114#u8, 109#u8]
  | .DebPostRm => [100#u8, 101#u8, 98#u8, 45#u8, 112#u8, 111#u8, 115#u8, 116#u8, 114#u8, 109#u8]
  | .ApkPreInstall => [97#u8, 112#u8, 107#u8, 45#u8, 112#u8, 114#u8, 101#u8, 45#u8, 105#u8, 110#u8, 115#u8, 116#u8, 97#u8, 108#u8, 108#u8]
  | .ApkPostInstall => [97#u8, 112#u8, 107#u8, 45#u8, 112#u8, 111#u8, 115#u8, 116#u8, 45#u8, 105#u8, 110#u8, 115#u8, 116#u8, 97#u8, 108#u8, 108#u8]
  | .PythonSetupPy => [112#u8, 121#u8, 116#u8, 104#u8, 111#u8, 110#u8, 45#u8, 115#u8, 101#u8, 116#u8, 117#u8, 112#u8, 45#u8, 112#u8, 121#u8]
theorem script_kind_a04cea8b_as_str_complete (v : finite_catalog.script_kind_a04cea8b.ScriptKind) :
    finite_catalog.script_kind_a04cea8b.ScriptKind.as_str v ⦃r => r.val = script_kind_a04cea8b_as_str_model v⦄ := by
  cases v <;> simp only [script_kind_a04cea8b_as_str_model]
  all_goals simp only [finite_catalog.script_kind_a04cea8b.ScriptKind.as_str, finite_catalog.script_kind_a04cea8b.ScriptKind.runs_as_root]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def script_kind_a04cea8b_runs_as_root_model (v : finite_catalog.script_kind_a04cea8b.ScriptKind) : Bool :=
  match v with
  | .PostLink => false
  | .PreLink => false
  | .PreUnlink => false
  | .PreInstall => false
  | .Install => false
  | .PostInstall => false
  | .Prepare => false
  | .RpmPre => true
  | .RpmPost => true
  | .RpmPreUn => true
  | .RpmPostUn => true
  | .DebPreInst => true
  | .DebPostInst => true
  | .DebPreRm => true
  | .DebPostRm => true
  | .ApkPreInstall => true
  | .ApkPostInstall => true
  | .PythonSetupPy => false
theorem script_kind_a04cea8b_runs_as_root_complete (v : finite_catalog.script_kind_a04cea8b.ScriptKind) :
    finite_catalog.script_kind_a04cea8b.ScriptKind.runs_as_root v ⦃r => r = script_kind_a04cea8b_runs_as_root_model v⦄ := by
  cases v <;> simp only [script_kind_a04cea8b_runs_as_root_model]
  all_goals simp only [finite_catalog.script_kind_a04cea8b.ScriptKind.as_str, finite_catalog.script_kind_a04cea8b.ScriptKind.runs_as_root]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def candidate_confidence_8223875f_as_str_model (v : finite_catalog.candidate_confidence_8223875f.CandidateConfidence) : List U8 :=
  match v with
  | .Low => [108#u8, 111#u8, 119#u8]
  | .Medium => [109#u8, 101#u8, 100#u8, 105#u8, 117#u8, 109#u8]
  | .High => [104#u8, 105#u8, 103#u8, 104#u8]
theorem candidate_confidence_8223875f_as_str_complete (v : finite_catalog.candidate_confidence_8223875f.CandidateConfidence) :
    finite_catalog.candidate_confidence_8223875f.CandidateConfidence.as_str v ⦃r => r.val = candidate_confidence_8223875f_as_str_model v⦄ := by
  cases v <;> simp only [candidate_confidence_8223875f_as_str_model]
  all_goals simp only [finite_catalog.candidate_confidence_8223875f.CandidateConfidence.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def check_b0946112_bit_model (v : finite_catalog.check_b0946112.Check) : U16 :=
  match v with
  | .BundleWellFormed => 1#u16
  | .SubjectDigestBound => 2#u16
  | .CryptoAndChain => 4#u16
  | .RekorInclusion => 8#u16
  | .IdentityExtracted => 16#u16
  | .IssuerAllowlisted => 32#u16
  | .PublisherOwnerBound => 64#u16
  | .RekorSet => 128#u16
  | .StatementPolicy => 256#u16
theorem check_b0946112_bit_complete (v : finite_catalog.check_b0946112.Check) :
    finite_catalog.check_b0946112.Check.bit v ⦃r => r = check_b0946112_bit_model v⦄ := by
  cases v <;> simp only [check_b0946112_bit_model]
  all_goals simp only [finite_catalog.check_b0946112.Check.bit, finite_catalog.check_b0946112.Check.reason_label, finite_catalog.check_b0946112.Check.read_discriminant]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def check_b0946112_reason_label_model (v : finite_catalog.check_b0946112.Check) : List U8 :=
  match v with
  | .BundleWellFormed => [98#u8, 117#u8, 110#u8, 100#u8, 108#u8, 101#u8]
  | .SubjectDigestBound => [115#u8, 117#u8, 98#u8, 106#u8, 101#u8, 99#u8, 116#u8, 32#u8, 98#u8, 105#u8, 110#u8, 100#u8, 105#u8, 110#u8, 103#u8]
  | .CryptoAndChain => [115#u8, 105#u8, 103#u8, 110#u8, 97#u8, 116#u8, 117#u8, 114#u8, 101#u8, 47#u8, 99#u8, 101#u8, 114#u8, 116#u8, 105#u8, 102#u8, 105#u8, 99#u8, 97#u8, 116#u8, 101#u8, 32#u8, 99#u8, 104#u8, 97#u8, 105#u8, 110#u8]
  | .RekorInclusion => [116#u8, 114#u8, 97#u8, 110#u8, 115#u8, 112#u8, 97#u8, 114#u8, 101#u8, 110#u8, 99#u8, 121#u8, 32#u8, 40#u8, 82#u8, 101#u8, 107#u8, 111#u8, 114#u8, 32#u8, 105#u8, 110#u8, 99#u8, 108#u8, 117#u8, 115#u8, 105#u8, 111#u8, 110#u8, 41#u8]
  | .IdentityExtracted => [105#u8, 100#u8, 101#u8, 110#u8, 116#u8, 105#u8, 116#u8, 121#u8]
  | .IssuerAllowlisted => [105#u8, 115#u8, 115#u8, 117#u8, 101#u8, 114#u8]
  | .PublisherOwnerBound => [105#u8, 100#u8, 101#u8, 110#u8, 116#u8, 105#u8, 116#u8, 121#u8, 32#u8, 98#u8, 105#u8, 110#u8, 100#u8, 105#u8, 110#u8, 103#u8]
  | .RekorSet => [116#u8, 114#u8, 97#u8, 110#u8, 115#u8, 112#u8, 97#u8, 114#u8, 101#u8, 110#u8, 99#u8, 121#u8, 32#u8, 40#u8, 82#u8, 101#u8, 107#u8, 111#u8, 114#u8, 32#u8, 83#u8, 69#u8, 84#u8, 41#u8]
  | .StatementPolicy => [115#u8, 116#u8, 97#u8, 116#u8, 101#u8, 109#u8, 101#u8, 110#u8, 116#u8, 32#u8, 112#u8, 111#u8, 108#u8, 105#u8, 99#u8, 121#u8]
theorem check_b0946112_reason_label_complete (v : finite_catalog.check_b0946112.Check) :
    finite_catalog.check_b0946112.Check.reason_label v ⦃r => r.val = check_b0946112_reason_label_model v⦄ := by
  cases v <;> simp only [check_b0946112_reason_label_model]
  all_goals simp only [finite_catalog.check_b0946112.Check.bit, finite_catalog.check_b0946112.Check.reason_label, finite_catalog.check_b0946112.Check.read_discriminant]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def attestation_state_b0946112_as_str_model (v : finite_catalog.attestation_state_b0946112.AttestationState) : List U8 :=
  match v with
  | .Unverified => [117#u8, 110#u8, 118#u8, 101#u8, 114#u8, 105#u8, 102#u8, 105#u8, 101#u8, 100#u8]
  | .Verified => [118#u8, 101#u8, 114#u8, 105#u8, 102#u8, 105#u8, 101#u8, 100#u8]
  | .Failed => [102#u8, 97#u8, 105#u8, 108#u8, 101#u8, 100#u8]
theorem attestation_state_b0946112_as_str_complete (v : finite_catalog.attestation_state_b0946112.AttestationState) :
    finite_catalog.attestation_state_b0946112.AttestationState.as_str v ⦃r => r.val = attestation_state_b0946112_as_str_model v⦄ := by
  cases v <;> simp only [attestation_state_b0946112_as_str_model]
  all_goals simp only [finite_catalog.attestation_state_b0946112.AttestationState.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def inventory_completeness_0e70a8c0_as_str_model (v : finite_catalog.inventory_completeness_0e70a8c0.InventoryCompleteness) : List U8 :=
  match v with
  | .Complete => [99#u8, 111#u8, 109#u8, 112#u8, 108#u8, 101#u8, 116#u8, 101#u8]
  | .Declared => [100#u8, 101#u8, 99#u8, 108#u8, 97#u8, 114#u8, 101#u8, 100#u8]
  | .Partial => [112#u8, 97#u8, 114#u8, 116#u8, 105#u8, 97#u8, 108#u8]
  | .None => [110#u8, 111#u8, 110#u8, 101#u8]
theorem inventory_completeness_0e70a8c0_as_str_complete (v : finite_catalog.inventory_completeness_0e70a8c0.InventoryCompleteness) :
    finite_catalog.inventory_completeness_0e70a8c0.InventoryCompleteness.as_str v ⦃r => r.val = inventory_completeness_0e70a8c0_as_str_model v⦄ := by
  cases v <;> simp only [inventory_completeness_0e70a8c0_as_str_model]
  all_goals simp only [finite_catalog.inventory_completeness_0e70a8c0.InventoryCompleteness.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def egress_proxy_mode_2d09e195_as_str_model (v : finite_catalog.egress_proxy_mode_2d09e195.EgressProxyMode) : List U8 :=
  match v with
  | .Inherit => [105#u8, 110#u8, 104#u8, 101#u8, 114#u8, 105#u8, 116#u8]
  | .Direct => [100#u8, 105#u8, 114#u8, 101#u8, 99#u8, 116#u8]
  | .Explicit => [101#u8, 120#u8, 112#u8, 108#u8, 105#u8, 99#u8, 105#u8, 116#u8]
theorem egress_proxy_mode_2d09e195_as_str_complete (v : finite_catalog.egress_proxy_mode_2d09e195.EgressProxyMode) :
    finite_catalog.egress_proxy_mode_2d09e195.EgressProxyMode.as_str v ⦃r => r.val = egress_proxy_mode_2d09e195_as_str_model v⦄ := by
  cases v <;> simp only [egress_proxy_mode_2d09e195_as_str_model]
  all_goals simp only [finite_catalog.egress_proxy_mode_2d09e195.EgressProxyMode.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def rate_limit_decision_2593facc_label_model (v : finite_catalog.rate_limit_decision_2593facc.RateLimitDecision) : List U8 :=
  match v with
  | .Allowed => [97#u8, 108#u8, 108#u8, 111#u8, 119#u8, 101#u8, 100#u8]
  | .RecipientLimited => [114#u8, 101#u8, 99#u8, 105#u8, 112#u8, 105#u8, 101#u8, 110#u8, 116#u8]
  | .DomainLimited => [100#u8, 111#u8, 109#u8, 97#u8, 105#u8, 110#u8]
theorem rate_limit_decision_2593facc_label_complete (v : finite_catalog.rate_limit_decision_2593facc.RateLimitDecision) :
    finite_catalog.rate_limit_decision_2593facc.RateLimitDecision.label v ⦃r => r.val = rate_limit_decision_2593facc_label_model v⦄ := by
  cases v <;> simp only [rate_limit_decision_2593facc_label_model]
  all_goals simp only [finite_catalog.rate_limit_decision_2593facc.RateLimitDecision.label]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def lock_format_99735155_as_str_model (v : finite_catalog.lock_format_99735155.LockFormat) : List U8 :=
  match v with
  | .PixiLock => [112#u8, 105#u8, 120#u8, 105#u8, 46#u8, 108#u8, 111#u8, 99#u8, 107#u8]
  | .CondaLock => [99#u8, 111#u8, 110#u8, 100#u8, 97#u8, 45#u8, 108#u8, 111#u8, 99#u8, 107#u8]
  | .NpmPackageLock => [112#u8, 97#u8, 99#u8, 107#u8, 97#u8, 103#u8, 101#u8, 45#u8, 108#u8, 111#u8, 99#u8, 107#u8, 46#u8, 106#u8, 115#u8, 111#u8, 110#u8]
  | .CargoLock => [67#u8, 97#u8, 114#u8, 103#u8, 111#u8, 46#u8, 108#u8, 111#u8, 99#u8, 107#u8]
  | .PoetryLock => [112#u8, 111#u8, 101#u8, 116#u8, 114#u8, 121#u8, 46#u8, 108#u8, 111#u8, 99#u8, 107#u8]
  | .UvLock => [117#u8, 118#u8, 46#u8, 108#u8, 111#u8, 99#u8, 107#u8]
theorem lock_format_99735155_as_str_complete (v : finite_catalog.lock_format_99735155.LockFormat) :
    finite_catalog.lock_format_99735155.LockFormat.as_str v ⦃r => r.val = lock_format_99735155_as_str_model v⦄ := by
  cases v <;> simp only [lock_format_99735155_as_str_model]
  all_goals simp only [finite_catalog.lock_format_99735155.LockFormat.as_str, finite_catalog.lock_format_99735155.LockFormat.is_per_platform]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def lock_format_99735155_is_per_platform_model (v : finite_catalog.lock_format_99735155.LockFormat) : Bool :=
  match v with
  | .PixiLock => true
  | .CondaLock => true
  | .NpmPackageLock => false
  | .CargoLock => false
  | .PoetryLock => false
  | .UvLock => false
theorem lock_format_99735155_is_per_platform_complete (v : finite_catalog.lock_format_99735155.LockFormat) :
    finite_catalog.lock_format_99735155.LockFormat.is_per_platform v ⦃r => r = lock_format_99735155_is_per_platform_model v⦄ := by
  cases v <;> simp only [lock_format_99735155_is_per_platform_model]
  all_goals simp only [finite_catalog.lock_format_99735155.LockFormat.as_str, finite_catalog.lock_format_99735155.LockFormat.is_per_platform]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def ecosystem_99735155_as_str_model (v : finite_catalog.ecosystem_99735155.Ecosystem) : List U8 :=
  match v with
  | .Conda => [99#u8, 111#u8, 110#u8, 100#u8, 97#u8]
  | .PyPi => [112#u8, 121#u8, 112#u8, 105#u8]
  | .Npm => [110#u8, 112#u8, 109#u8]
  | .Cargo => [99#u8, 97#u8, 114#u8, 103#u8, 111#u8]
theorem ecosystem_99735155_as_str_complete (v : finite_catalog.ecosystem_99735155.Ecosystem) :
    finite_catalog.ecosystem_99735155.Ecosystem.as_str v ⦃r => r.val = ecosystem_99735155_as_str_model v⦄ := by
  cases v <;> simp only [ecosystem_99735155_as_str_model]
  all_goals simp only [finite_catalog.ecosystem_99735155.Ecosystem.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def edge_kind_99735155_as_str_model (v : finite_catalog.edge_kind_99735155.EdgeKind) : List U8 :=
  match v with
  | .Runtime => [114#u8, 117#u8, 110#u8, 116#u8, 105#u8, 109#u8, 101#u8]
  | .Build => [98#u8, 117#u8, 105#u8, 108#u8, 100#u8]
  | .Dev => [100#u8, 101#u8, 118#u8]
  | .Optional => [111#u8, 112#u8, 116#u8, 105#u8, 111#u8, 110#u8, 97#u8, 108#u8]
  | .Peer => [112#u8, 101#u8, 101#u8, 114#u8]
  | .Constrains => [99#u8, 111#u8, 110#u8, 115#u8, 116#u8, 114#u8, 97#u8, 105#u8, 110#u8, 115#u8]
theorem edge_kind_99735155_as_str_complete (v : finite_catalog.edge_kind_99735155.EdgeKind) :
    finite_catalog.edge_kind_99735155.EdgeKind.as_str v ⦃r => r.val = edge_kind_99735155_as_str_model v⦄ := by
  cases v <;> simp only [edge_kind_99735155_as_str_model]
  all_goals simp only [finite_catalog.edge_kind_99735155.EdgeKind.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def unresolved_kind_99735155_as_str_model (v : finite_catalog.unresolved_kind_99735155.UnresolvedKind) : List U8 :=
  match v with
  | .Unparsed => [117#u8, 110#u8, 112#u8, 97#u8, 114#u8, 115#u8, 101#u8, 100#u8]
  | .MissingDependency => [109#u8, 105#u8, 115#u8, 115#u8, 105#u8, 110#u8, 103#u8, 95#u8, 100#u8, 101#u8, 112#u8, 101#u8, 110#u8, 100#u8, 101#u8, 110#u8, 99#u8, 121#u8]
  | .ConditionalNotInstalled => [99#u8, 111#u8, 110#u8, 100#u8, 105#u8, 116#u8, 105#u8, 111#u8, 110#u8, 97#u8, 108#u8, 95#u8, 110#u8, 111#u8, 116#u8, 95#u8, 105#u8, 110#u8, 115#u8, 116#u8, 97#u8, 108#u8, 108#u8, 101#u8, 100#u8]
  | .VirtualPackage => [118#u8, 105#u8, 114#u8, 116#u8, 117#u8, 97#u8, 108#u8, 95#u8, 112#u8, 97#u8, 99#u8, 107#u8, 97#u8, 103#u8, 101#u8]
  | .Ambiguous => [97#u8, 109#u8, 98#u8, 105#u8, 103#u8, 117#u8, 111#u8, 117#u8, 115#u8]
theorem unresolved_kind_99735155_as_str_complete (v : finite_catalog.unresolved_kind_99735155.UnresolvedKind) :
    finite_catalog.unresolved_kind_99735155.UnresolvedKind.as_str v ⦃r => r.val = unresolved_kind_99735155_as_str_model v⦄ := by
  cases v <;> simp only [unresolved_kind_99735155_as_str_model]
  all_goals simp only [finite_catalog.unresolved_kind_99735155.UnresolvedKind.as_str, finite_catalog.unresolved_kind_99735155.UnresolvedKind.is_parse_failure, finite_catalog.unresolved_kind_99735155.UnresolvedKind.is_graph_gap]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def unresolved_kind_99735155_is_parse_failure_model (v : finite_catalog.unresolved_kind_99735155.UnresolvedKind) : Bool :=
  match v with
  | .Unparsed => true
  | .MissingDependency => false
  | .ConditionalNotInstalled => false
  | .VirtualPackage => false
  | .Ambiguous => false
theorem unresolved_kind_99735155_is_parse_failure_complete (v : finite_catalog.unresolved_kind_99735155.UnresolvedKind) :
    finite_catalog.unresolved_kind_99735155.UnresolvedKind.is_parse_failure v ⦃r => r = unresolved_kind_99735155_is_parse_failure_model v⦄ := by
  cases v <;> simp only [unresolved_kind_99735155_is_parse_failure_model]
  all_goals simp only [finite_catalog.unresolved_kind_99735155.UnresolvedKind.as_str, finite_catalog.unresolved_kind_99735155.UnresolvedKind.is_parse_failure, finite_catalog.unresolved_kind_99735155.UnresolvedKind.is_graph_gap]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def unresolved_kind_99735155_is_graph_gap_model (v : finite_catalog.unresolved_kind_99735155.UnresolvedKind) : Bool :=
  match v with
  | .Unparsed => true
  | .MissingDependency => true
  | .ConditionalNotInstalled => false
  | .VirtualPackage => false
  | .Ambiguous => true
theorem unresolved_kind_99735155_is_graph_gap_complete (v : finite_catalog.unresolved_kind_99735155.UnresolvedKind) :
    finite_catalog.unresolved_kind_99735155.UnresolvedKind.is_graph_gap v ⦃r => r = unresolved_kind_99735155_is_graph_gap_model v⦄ := by
  cases v <;> simp only [unresolved_kind_99735155_is_graph_gap_model]
  all_goals simp only [finite_catalog.unresolved_kind_99735155.UnresolvedKind.as_str, finite_catalog.unresolved_kind_99735155.UnresolvedKind.is_parse_failure, finite_catalog.unresolved_kind_99735155.UnresolvedKind.is_graph_gap]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def package_manager_7f965e35_as_str_model (v : finite_catalog.package_manager_7f965e35.PackageManager) : List U8 :=
  match v with
  | .Apt => [97#u8, 112#u8, 116#u8]
  | .Dnf => [100#u8, 110#u8, 102#u8]
  | .Microdnf => [109#u8, 105#u8, 99#u8, 114#u8, 111#u8, 100#u8, 110#u8, 102#u8]
  | .Yum => [121#u8, 117#u8, 109#u8]
  | .Apk => [97#u8, 112#u8, 107#u8]
  | .Pip => [112#u8, 105#u8, 112#u8]
  | .Conda => [99#u8, 111#u8, 110#u8, 100#u8, 97#u8]
theorem package_manager_7f965e35_as_str_complete (v : finite_catalog.package_manager_7f965e35.PackageManager) :
    finite_catalog.package_manager_7f965e35.PackageManager.as_str v ⦃r => r.val = package_manager_7f965e35_as_str_model v⦄ := by
  cases v <;> simp only [package_manager_7f965e35_as_str_model]
  all_goals simp only [finite_catalog.package_manager_7f965e35.PackageManager.as_str, finite_catalog.package_manager_7f965e35.PackageManager.is_system]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def package_manager_7f965e35_is_system_model (v : finite_catalog.package_manager_7f965e35.PackageManager) : Bool :=
  match v with
  | .Apt => true
  | .Dnf => true
  | .Microdnf => true
  | .Yum => true
  | .Apk => true
  | .Pip => false
  | .Conda => false
theorem package_manager_7f965e35_is_system_complete (v : finite_catalog.package_manager_7f965e35.PackageManager) :
    finite_catalog.package_manager_7f965e35.PackageManager.is_system v ⦃r => r = package_manager_7f965e35_is_system_model v⦄ := by
  cases v <;> simp only [package_manager_7f965e35_is_system_model]
  all_goals simp only [finite_catalog.package_manager_7f965e35.PackageManager.as_str, finite_catalog.package_manager_7f965e35.PackageManager.is_system]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def policy_type_080e6210_as_wire_str_model (v : finite_catalog.policy_type_080e6210.PolicyType) : List U8 :=
  match v with
  | .MaxAgeDays => [109#u8, 97#u8, 120#u8, 95#u8, 97#u8, 103#u8, 101#u8, 95#u8, 100#u8, 97#u8, 121#u8, 115#u8]
  | .MaxVersions => [109#u8, 97#u8, 120#u8, 95#u8, 118#u8, 101#u8, 114#u8, 115#u8, 105#u8, 111#u8, 110#u8, 115#u8]
  | .NoDownloadsDays => [110#u8, 111#u8, 95#u8, 100#u8, 111#u8, 119#u8, 110#u8, 108#u8, 111#u8, 97#u8, 100#u8, 115#u8, 95#u8, 100#u8, 97#u8, 121#u8, 115#u8]
  | .TagPatternKeep => [116#u8, 97#u8, 103#u8, 95#u8, 112#u8, 97#u8, 116#u8, 116#u8, 101#u8, 114#u8, 110#u8, 95#u8, 107#u8, 101#u8, 101#u8, 112#u8]
  | .TagPatternDelete => [116#u8, 97#u8, 103#u8, 95#u8, 112#u8, 97#u8, 116#u8, 116#u8, 101#u8, 114#u8, 110#u8, 95#u8, 100#u8, 101#u8, 108#u8, 101#u8, 116#u8, 101#u8]
  | .SizeQuotaBytes => [115#u8, 105#u8, 122#u8, 101#u8, 95#u8, 113#u8, 117#u8, 111#u8, 116#u8, 97#u8, 95#u8, 98#u8, 121#u8, 116#u8, 101#u8, 115#u8]
theorem policy_type_080e6210_as_wire_str_complete (v : finite_catalog.policy_type_080e6210.PolicyType) :
    finite_catalog.policy_type_080e6210.PolicyType.as_wire_str v ⦃r => r.val = policy_type_080e6210_as_wire_str_model v⦄ := by
  cases v <;> simp only [policy_type_080e6210_as_wire_str_model]
  all_goals simp only [finite_catalog.policy_type_080e6210.PolicyType.as_wire_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def flat_key_write_claim_6572c2eb_needs_release_on_failure_model (v : finite_catalog.flat_key_write_claim_6572c2eb.FlatKeyWriteClaim) : Bool :=
  match v with
  | .NotApplicable => false
  | .Claimed => true
  | .AlreadyOwned => false
theorem flat_key_write_claim_6572c2eb_needs_release_on_failure_complete (v : finite_catalog.flat_key_write_claim_6572c2eb.FlatKeyWriteClaim) :
    finite_catalog.flat_key_write_claim_6572c2eb.FlatKeyWriteClaim.needs_release_on_failure v ⦃r => r = flat_key_write_claim_6572c2eb_needs_release_on_failure_model v⦄ := by
  cases v <;> simp only [flat_key_write_claim_6572c2eb_needs_release_on_failure_model]
  all_goals simp only [finite_catalog.flat_key_write_claim_6572c2eb.FlatKeyWriteClaim.needs_release_on_failure]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def source_view_73842ce1_overwrites_model (v : finite_catalog.source_view_73842ce1.SourceView) : Bool :=
  match v with
  | .Partial => false
  | .Complete => true
theorem source_view_73842ce1_overwrites_complete (v : finite_catalog.source_view_73842ce1.SourceView) :
    finite_catalog.source_view_73842ce1.SourceView.overwrites v ⦃r => r = source_view_73842ce1_overwrites_model v⦄ := by
  cases v <;> simp only [source_view_73842ce1_overwrites_model]
  all_goals simp only [finite_catalog.source_view_73842ce1.SourceView.overwrites]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def repository_type_73842ce1_to_artifact_keeper_model (v : finite_catalog.repository_type_73842ce1.RepositoryType) : List U8 :=
  match v with
  | .Local => [108#u8, 111#u8, 99#u8, 97#u8, 108#u8]
  | .Remote => [114#u8, 101#u8, 109#u8, 111#u8, 116#u8, 101#u8]
  | .Virtual => [118#u8, 105#u8, 114#u8, 116#u8, 117#u8, 97#u8, 108#u8]
theorem repository_type_73842ce1_to_artifact_keeper_complete (v : finite_catalog.repository_type_73842ce1.RepositoryType) :
    finite_catalog.repository_type_73842ce1.RepositoryType.to_artifact_keeper v ⦃r => r.val = repository_type_73842ce1_to_artifact_keeper_model v⦄ := by
  cases v <;> simp only [repository_type_73842ce1_to_artifact_keeper_model]
  all_goals simp only [finite_catalog.repository_type_73842ce1.RepositoryType.to_artifact_keeper]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def advisory_scan_status_38f3e57f_as_str_model (v : finite_catalog.advisory_scan_status_38f3e57f.AdvisoryScanStatus) : List U8 :=
  match v with
  | .Ok => [111#u8, 107#u8]
  | .NotRun => [110#u8, 111#u8, 116#u8, 95#u8, 114#u8, 117#u8, 110#u8]
  | .Partial => [112#u8, 97#u8, 114#u8, 116#u8, 105#u8, 97#u8, 108#u8]
theorem advisory_scan_status_38f3e57f_as_str_complete (v : finite_catalog.advisory_scan_status_38f3e57f.AdvisoryScanStatus) :
    finite_catalog.advisory_scan_status_38f3e57f.AdvisoryScanStatus.as_str v ⦃r => r.val = advisory_scan_status_38f3e57f_as_str_model v⦄ := by
  cases v <;> simp only [advisory_scan_status_38f3e57f_as_str_model]
  all_goals simp only [finite_catalog.advisory_scan_status_38f3e57f.AdvisoryScanStatus.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def proxy_scan_action_2c5d20ab_is_fail_closed_model (v : finite_catalog.proxy_scan_action_2c5d20ab.ProxyScanAction) : Bool :=
  match v with
  | .FailOpen => false
  | .FailClosed => true
theorem proxy_scan_action_2c5d20ab_is_fail_closed_complete (v : finite_catalog.proxy_scan_action_2c5d20ab.ProxyScanAction) :
    finite_catalog.proxy_scan_action_2c5d20ab.ProxyScanAction.is_fail_closed v ⦃r => r = proxy_scan_action_2c5d20ab_is_fail_closed_model v⦄ := by
  cases v <;> simp only [proxy_scan_action_2c5d20ab_is_fail_closed_model]
  all_goals simp only [finite_catalog.proxy_scan_action_2c5d20ab.ProxyScanAction.is_fail_closed]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def vendoring_tool_8d235a49_as_str_model (v : finite_catalog.vendoring_tool_8d235a49.VendoringTool) : List U8 :=
  match v with
  | .AuditWheel => [97#u8, 117#u8, 100#u8, 105#u8, 116#u8, 119#u8, 104#u8, 101#u8, 101#u8, 108#u8]
  | .Delocate => [100#u8, 101#u8, 108#u8, 111#u8, 99#u8, 97#u8, 116#u8, 101#u8]
  | .DelvEWheel => [100#u8, 101#u8, 108#u8, 118#u8, 101#u8, 119#u8, 104#u8, 101#u8, 101#u8, 108#u8]
theorem vendoring_tool_8d235a49_as_str_complete (v : finite_catalog.vendoring_tool_8d235a49.VendoringTool) :
    finite_catalog.vendoring_tool_8d235a49.VendoringTool.as_str v ⦃r => r.val = vendoring_tool_8d235a49_as_str_model v⦄ := by
  cases v <;> simp only [vendoring_tool_8d235a49_as_str_model]
  all_goals simp only [finite_catalog.vendoring_tool_8d235a49.VendoringTool.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def quarantine_state_63e328a6_as_str_model (v : finite_catalog.quarantine_state_63e328a6.QuarantineState) : List U8 :=
  match v with
  | .Quarantined => [113#u8, 117#u8, 97#u8, 114#u8, 97#u8, 110#u8, 116#u8, 105#u8, 110#u8, 101#u8, 100#u8]
  | .Released => [114#u8, 101#u8, 108#u8, 101#u8, 97#u8, 115#u8, 101#u8, 100#u8]
  | .Rejected => [114#u8, 101#u8, 106#u8, 101#u8, 99#u8, 116#u8, 101#u8, 100#u8]
theorem quarantine_state_63e328a6_as_str_complete (v : finite_catalog.quarantine_state_63e328a6.QuarantineState) :
    finite_catalog.quarantine_state_63e328a6.QuarantineState.as_str v ⦃r => r.val = quarantine_state_63e328a6_as_str_model v⦄ := by
  cases v <;> simp only [quarantine_state_63e328a6_as_str_model]
  all_goals simp only [finite_catalog.quarantine_state_63e328a6.QuarantineState.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def inventory_status_731e13d3_as_db_str_model (v : finite_catalog.inventory_status_731e13d3.InventoryStatus) : List U8 :=
  match v with
  | .Complete => [99#u8, 111#u8, 109#u8, 112#u8, 108#u8, 101#u8, 116#u8, 101#u8]
  | .Partial => [112#u8, 97#u8, 114#u8, 116#u8, 105#u8, 97#u8, 108#u8]
  | .Failed => [102#u8, 97#u8, 105#u8, 108#u8, 101#u8, 100#u8]
theorem inventory_status_731e13d3_as_db_str_complete (v : finite_catalog.inventory_status_731e13d3.InventoryStatus) :
    finite_catalog.inventory_status_731e13d3.InventoryStatus.as_db_str v ⦃r => r.val = inventory_status_731e13d3_as_db_str_model v⦄ := by
  cases v <;> simp only [inventory_status_731e13d3_as_db_str_model]
  all_goals simp only [finite_catalog.inventory_status_731e13d3.InventoryStatus.as_db_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def scan_state_5f365d9c_is_unscanned_model (v : finite_catalog.scan_state_5f365d9c.ScanState) : Bool :=
  match v with
  | .Completed => false
  | .InProgress => true
  | .Failed => true
  | .NeverScanned => true
  | .NotApplicable => false
theorem scan_state_5f365d9c_is_unscanned_complete (v : finite_catalog.scan_state_5f365d9c.ScanState) :
    finite_catalog.scan_state_5f365d9c.ScanState.is_unscanned v ⦃r => r = scan_state_5f365d9c_is_unscanned_model v⦄ := by
  cases v <;> simp only [scan_state_5f365d9c_is_unscanned_model]
  all_goals simp only [finite_catalog.scan_state_5f365d9c.ScanState.is_unscanned, finite_catalog.scan_state_5f365d9c.ScanState.reason_token]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def scan_state_5f365d9c_reason_token_model (v : finite_catalog.scan_state_5f365d9c.ScanState) : List U8 :=
  match v with
  | .Completed => [99#u8, 111#u8, 109#u8, 112#u8, 108#u8, 101#u8, 116#u8, 101#u8, 100#u8]
  | .InProgress => [115#u8, 99#u8, 97#u8, 110#u8, 95#u8, 105#u8, 110#u8, 95#u8, 112#u8, 114#u8, 111#u8, 103#u8, 114#u8, 101#u8, 115#u8, 115#u8]
  | .Failed => [115#u8, 99#u8, 97#u8, 110#u8, 95#u8, 102#u8, 97#u8, 105#u8, 108#u8, 101#u8, 100#u8]
  | .NeverScanned => [110#u8, 101#u8, 118#u8, 101#u8, 114#u8, 95#u8, 115#u8, 99#u8, 97#u8, 110#u8, 110#u8, 101#u8, 100#u8]
  | .NotApplicable => [110#u8, 111#u8, 116#u8, 95#u8, 97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 98#u8, 108#u8, 101#u8]
theorem scan_state_5f365d9c_reason_token_complete (v : finite_catalog.scan_state_5f365d9c.ScanState) :
    finite_catalog.scan_state_5f365d9c.ScanState.reason_token v ⦃r => r.val = scan_state_5f365d9c_reason_token_model v⦄ := by
  cases v <;> simp only [scan_state_5f365d9c_reason_token_model]
  all_goals simp only [finite_catalog.scan_state_5f365d9c.ScanState.is_unscanned, finite_catalog.scan_state_5f365d9c.ScanState.reason_token]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def scan_completeness_ba4d10ac_as_str_model (v : finite_catalog.scan_completeness_ba4d10ac.ScanCompleteness) : List U8 :=
  match v with
  | .Complete => [99#u8, 111#u8, 109#u8, 112#u8, 108#u8, 101#u8, 116#u8, 101#u8]
  | .Partial => [112#u8, 97#u8, 114#u8, 116#u8, 105#u8, 97#u8, 108#u8]
  | .NotCataloged => [110#u8, 111#u8, 116#u8, 95#u8, 99#u8, 97#u8, 116#u8, 97#u8, 108#u8, 111#u8, 103#u8, 101#u8, 100#u8]
theorem scan_completeness_ba4d10ac_as_str_complete (v : finite_catalog.scan_completeness_ba4d10ac.ScanCompleteness) :
    finite_catalog.scan_completeness_ba4d10ac.ScanCompleteness.as_str v ⦃r => r.val = scan_completeness_ba4d10ac_as_str_model v⦄ := by
  cases v <;> simp only [scan_completeness_ba4d10ac_as_str_model]
  all_goals simp only [finite_catalog.scan_completeness_ba4d10ac.ScanCompleteness.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def oci_content_kind_bc817bda_path_segment_model (v : finite_catalog.oci_content_kind_bc817bda.OciContentKind) : List U8 :=
  match v with
  | .Blob => [98#u8, 108#u8, 111#u8, 98#u8, 115#u8]
  | .Manifest => [109#u8, 97#u8, 110#u8, 105#u8, 102#u8, 101#u8, 115#u8, 116#u8, 115#u8]
theorem oci_content_kind_bc817bda_path_segment_complete (v : finite_catalog.oci_content_kind_bc817bda.OciContentKind) :
    finite_catalog.oci_content_kind_bc817bda.OciContentKind.path_segment v ⦃r => r.val = oci_content_kind_bc817bda_path_segment_model v⦄ := by
  cases v <;> simp only [oci_content_kind_bc817bda_path_segment_model]
  all_goals simp only [finite_catalog.oci_content_kind_bc817bda.OciContentKind.path_segment]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def oci_cleanup_key_family_c9cc8f67_session_predicate_sql_model (v : finite_catalog.oci_cleanup_key_family_c9cc8f67.OciCleanupKeyFamily) : List U8 :=
  match v with
  | .Pending => [115#u8, 46#u8, 105#u8, 100#u8, 32#u8, 61#u8, 32#u8, 99#u8, 46#u8, 117#u8, 112#u8, 108#u8, 111#u8, 97#u8, 100#u8, 95#u8, 115#u8, 101#u8, 115#u8, 115#u8, 105#u8, 111#u8, 110#u8, 95#u8, 105#u8, 100#u8, 10#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 32#u8, 79#u8, 82#u8, 32#u8, 115#u8, 46#u8, 115#u8, 116#u8, 111#u8, 114#u8, 97#u8, 103#u8, 101#u8, 95#u8, 116#u8, 101#u8, 109#u8, 112#u8, 95#u8, 107#u8, 101#u8, 121#u8, 32#u8, 61#u8, 32#u8, 99#u8, 46#u8, 115#u8, 116#u8, 111#u8, 114#u8, 97#u8, 103#u8, 101#u8, 95#u8, 107#u8, 101#u8, 121#u8]
  | .Unreferenced => [115#u8, 46#u8, 115#u8, 116#u8, 111#u8, 114#u8, 97#u8, 103#u8, 101#u8, 95#u8, 116#u8, 101#u8, 109#u8, 112#u8, 95#u8, 107#u8, 101#u8, 121#u8, 32#u8, 61#u8, 32#u8, 99#u8, 46#u8, 115#u8, 116#u8, 111#u8, 114#u8, 97#u8, 103#u8, 101#u8, 95#u8, 107#u8, 101#u8, 121#u8]
theorem oci_cleanup_key_family_c9cc8f67_session_predicate_sql_complete (v : finite_catalog.oci_cleanup_key_family_c9cc8f67.OciCleanupKeyFamily) :
    finite_catalog.oci_cleanup_key_family_c9cc8f67.OciCleanupKeyFamily.session_predicate_sql v ⦃r => r.val = oci_cleanup_key_family_c9cc8f67_session_predicate_sql_model v⦄ := by
  cases v <;> simp only [oci_cleanup_key_family_c9cc8f67_session_predicate_sql_model]
  all_goals simp only [finite_catalog.oci_cleanup_key_family_c9cc8f67.OciCleanupKeyFamily.session_predicate_sql]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def dedup_scope_78b2cf8c_as_str_model (v : finite_catalog.dedup_scope_78b2cf8c.DedupScope) : List U8 :=
  match v with
  | .PerRepo => [112#u8, 101#u8, 114#u8, 95#u8, 114#u8, 101#u8, 112#u8, 111#u8]
  | .Instance => [105#u8, 110#u8, 115#u8, 116#u8, 97#u8, 110#u8, 99#u8, 101#u8]
theorem dedup_scope_78b2cf8c_as_str_complete (v : finite_catalog.dedup_scope_78b2cf8c.DedupScope) :
    finite_catalog.dedup_scope_78b2cf8c.DedupScope.as_str v ⦃r => r.val = dedup_scope_78b2cf8c_as_str_model v⦄ := by
  cases v <;> simp only [dedup_scope_78b2cf8c_as_str_model]
  all_goals simp only [finite_catalog.dedup_scope_78b2cf8c.DedupScope.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def totp_policy_31812d2d_as_str_model (v : finite_catalog.totp_policy_31812d2d.TotpPolicy) : List U8 :=
  match v with
  | .Disabled => [100#u8, 105#u8, 115#u8, 97#u8, 98#u8, 108#u8, 101#u8, 100#u8]
  | .RequiredForAdmins => [114#u8, 101#u8, 113#u8, 117#u8, 105#u8, 114#u8, 101#u8, 100#u8, 95#u8, 102#u8, 111#u8, 114#u8, 95#u8, 97#u8, 100#u8, 109#u8, 105#u8, 110#u8, 115#u8]
  | .RequiredForAll => [114#u8, 101#u8, 113#u8, 117#u8, 105#u8, 114#u8, 101#u8, 100#u8, 95#u8, 102#u8, 111#u8, 114#u8, 95#u8, 97#u8, 108#u8, 108#u8]
theorem totp_policy_31812d2d_as_str_complete (v : finite_catalog.totp_policy_31812d2d.TotpPolicy) :
    finite_catalog.totp_policy_31812d2d.TotpPolicy.as_str v ⦃r => r.val = totp_policy_31812d2d_as_str_model v⦄ := by
  cases v <;> simp only [totp_policy_31812d2d_as_str_model]
  all_goals simp only [finite_catalog.totp_policy_31812d2d.TotpPolicy.as_str, finite_catalog.totp_policy_31812d2d.TotpPolicy.is_enforcing]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def totp_policy_31812d2d_is_enforcing_model (v : finite_catalog.totp_policy_31812d2d.TotpPolicy) : Bool :=
  match v with
  | .Disabled => false
  | .RequiredForAdmins => true
  | .RequiredForAll => true
theorem totp_policy_31812d2d_is_enforcing_complete (v : finite_catalog.totp_policy_31812d2d.TotpPolicy) :
    finite_catalog.totp_policy_31812d2d.TotpPolicy.is_enforcing v ⦃r => r = totp_policy_31812d2d_is_enforcing_model v⦄ := by
  cases v <;> simp only [totp_policy_31812d2d_is_enforcing_model]
  all_goals simp only [finite_catalog.totp_policy_31812d2d.TotpPolicy.as_str, finite_catalog.totp_policy_31812d2d.TotpPolicy.is_enforcing]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def policy_activation_refusal_31812d2d_message_model (v : finite_catalog.policy_activation_refusal_31812d2d.PolicyActivationRefusal) : List U8 :=
  match v with
  | .PinnedByEnvironment => [84#u8, 104#u8, 101#u8, 32#u8, 84#u8, 79#u8, 84#u8, 80#u8, 32#u8, 101#u8, 110#u8, 102#u8, 111#u8, 114#u8, 99#u8, 101#u8, 109#u8, 101#u8, 110#u8, 116#u8, 32#u8, 112#u8, 111#u8, 108#u8, 105#u8, 99#u8, 121#u8, 32#u8, 105#u8, 115#u8, 32#u8, 112#u8, 105#u8, 110#u8, 110#u8, 101#u8, 100#u8, 32#u8, 98#u8, 121#u8, 32#u8, 116#u8, 104#u8, 101#u8, 32#u8, 84#u8, 79#u8, 84#u8, 80#u8, 95#u8, 80#u8, 79#u8, 76#u8, 73#u8, 67#u8, 89#u8, 32#u8, 101#u8, 110#u8, 118#u8, 105#u8, 114#u8, 111#u8, 110#u8, 109#u8, 101#u8, 110#u8, 116#u8, 32#u8, 118#u8, 97#u8, 114#u8, 105#u8, 97#u8, 98#u8, 108#u8, 101#u8, 32#u8, 97#u8, 110#u8, 100#u8, 32#u8, 99#u8, 97#u8, 110#u8, 110#u8, 111#u8, 116#u8, 32#u8, 98#u8, 101#u8, 32#u8, 99#u8, 104#u8, 97#u8, 110#u8, 103#u8, 101#u8, 100#u8, 32#u8, 116#u8, 104#u8, 114#u8, 111#u8, 117#u8, 103#u8, 104#u8, 32#u8, 116#u8, 104#u8, 101#u8, 32#u8, 65#u8, 80#u8, 73#u8, 46#u8, 32#u8, 85#u8, 110#u8, 115#u8, 101#u8, 116#u8, 32#u8, 84#u8, 79#u8, 84#u8, 80#u8, 95#u8, 80#u8, 79#u8, 76#u8, 73#u8, 67#u8, 89#u8, 32#u8, 97#u8, 110#u8, 100#u8, 32#u8, 114#u8, 101#u8, 115#u8, 116#u8, 97#u8, 114#u8, 116#u8, 32#u8, 116#u8, 111#u8, 32#u8, 109#u8, 97#u8, 110#u8, 97#u8, 103#u8, 101#u8, 32#u8, 105#u8, 116#u8, 32#u8, 104#u8, 101#u8, 114#u8, 101#u8, 46#u8]
  | .ActorNotEnrolled => [69#u8, 110#u8, 97#u8, 98#u8, 108#u8, 101#u8, 32#u8, 84#u8, 79#u8, 84#u8, 80#u8, 32#u8, 111#u8, 110#u8, 32#u8, 121#u8, 111#u8, 117#u8, 114#u8, 32#u8, 111#u8, 119#u8, 110#u8, 32#u8, 97#u8, 99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8, 32#u8, 98#u8, 101#u8, 102#u8, 111#u8, 114#u8, 101#u8, 32#u8, 114#u8, 101#u8, 113#u8, 117#u8, 105#u8, 114#u8, 105#u8, 110#u8, 103#u8, 32#u8, 105#u8, 116#u8, 32#u8, 102#u8, 111#u8, 114#u8, 32#u8, 111#u8, 116#u8, 104#u8, 101#u8, 114#u8, 115#u8, 46#u8, 32#u8, 84#u8, 104#u8, 105#u8, 115#u8, 32#u8, 103#u8, 117#u8, 97#u8, 114#u8, 97#u8, 110#u8, 116#u8, 101#u8, 101#u8, 115#u8, 32#u8, 97#u8, 116#u8, 32#u8, 108#u8, 101#u8, 97#u8, 115#u8, 116#u8, 32#u8, 111#u8, 110#u8, 101#u8, 32#u8, 97#u8, 100#u8, 109#u8, 105#u8, 110#u8, 105#u8, 115#u8, 116#u8, 114#u8, 97#u8, 116#u8, 111#u8, 114#u8, 32#u8, 99#u8, 97#u8, 110#u8, 32#u8, 115#u8, 116#u8, 105#u8, 108#u8, 108#u8, 32#u8, 115#u8, 105#u8, 103#u8, 110#u8, 32#u8, 105#u8, 110#u8, 32#u8, 105#u8, 102#u8, 32#u8, 116#u8, 104#u8, 101#u8, 32#u8, 101#u8, 110#u8, 114#u8, 111#u8, 108#u8, 108#u8, 109#u8, 101#u8, 110#u8, 116#u8, 32#u8, 102#u8, 108#u8, 111#u8, 119#u8, 32#u8, 100#u8, 111#u8, 101#u8, 115#u8, 32#u8, 110#u8, 111#u8, 116#u8, 32#u8, 119#u8, 111#u8, 114#u8, 107#u8, 32#u8, 105#u8, 110#u8, 32#u8, 121#u8, 111#u8, 117#u8, 114#u8, 32#u8, 101#u8, 110#u8, 118#u8, 105#u8, 114#u8, 111#u8, 110#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8]
theorem policy_activation_refusal_31812d2d_message_complete (v : finite_catalog.policy_activation_refusal_31812d2d.PolicyActivationRefusal) :
    finite_catalog.policy_activation_refusal_31812d2d.PolicyActivationRefusal.message v ⦃r => r.val = policy_activation_refusal_31812d2d_message_model v⦄ := by
  cases v <;> simp only [policy_activation_refusal_31812d2d_message_model]
  all_goals simp only [finite_catalog.policy_activation_refusal_31812d2d.PolicyActivationRefusal.message]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def storage_path_format_9d04c6bd_has_fallback_model (v : finite_catalog.storage_path_format_9d04c6bd.StoragePathFormat) : Bool :=
  match v with
  | .Native => false
  | .Artifactory => false
  | .Migration => true
theorem storage_path_format_9d04c6bd_has_fallback_complete (v : finite_catalog.storage_path_format_9d04c6bd.StoragePathFormat) :
    finite_catalog.storage_path_format_9d04c6bd.StoragePathFormat.has_fallback v ⦃r => r = storage_path_format_9d04c6bd_has_fallback_model v⦄ := by
  cases v <;> simp only [storage_path_format_9d04c6bd_has_fallback_model]
  all_goals simp only [finite_catalog.storage_path_format_9d04c6bd.StoragePathFormat.has_fallback]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def log_format_f5cc6ea1_name_model (v : finite_catalog.log_format_f5cc6ea1.LogFormat) : List U8 :=
  match v with
  | .Pretty => [112#u8, 114#u8, 101#u8, 116#u8, 116#u8, 121#u8]
  | .Json => [106#u8, 115#u8, 111#u8, 110#u8]
theorem log_format_f5cc6ea1_name_complete (v : finite_catalog.log_format_f5cc6ea1.LogFormat) :
    finite_catalog.log_format_f5cc6ea1.LogFormat.name v ⦃r => r.val = log_format_f5cc6ea1_name_model v⦄ := by
  cases v <;> simp only [log_format_f5cc6ea1_name_model]
  all_goals simp only [finite_catalog.log_format_f5cc6ea1.LogFormat.name]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def otlp_protocol_f5cc6ea1_name_model (v : finite_catalog.otlp_protocol_f5cc6ea1.OtlpProtocol) : List U8 :=
  match v with
  | .Grpc => [103#u8, 114#u8, 112#u8, 99#u8]
  | .HttpProtobuf => [104#u8, 116#u8, 116#u8, 112#u8, 47#u8, 112#u8, 114#u8, 111#u8, 116#u8, 111#u8, 98#u8, 117#u8, 102#u8]
theorem otlp_protocol_f5cc6ea1_name_complete (v : finite_catalog.otlp_protocol_f5cc6ea1.OtlpProtocol) :
    finite_catalog.otlp_protocol_f5cc6ea1.OtlpProtocol.name v ⦃r => r.val = otlp_protocol_f5cc6ea1_name_model v⦄ := by
  cases v <;> simp only [otlp_protocol_f5cc6ea1_name_model]
  all_goals simp only [finite_catalog.otlp_protocol_f5cc6ea1.OtlpProtocol.name]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def sampler_choice_f5cc6ea1_name_model (v : finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice) : List U8 :=
  match v with
  | .AlwaysOn => [97#u8, 108#u8, 119#u8, 97#u8, 121#u8, 115#u8, 95#u8, 111#u8, 110#u8]
  | .AlwaysOff => [97#u8, 108#u8, 119#u8, 97#u8, 121#u8, 115#u8, 95#u8, 111#u8, 102#u8, 102#u8]
  | .TraceIdRatio => [116#u8, 114#u8, 97#u8, 99#u8, 101#u8, 105#u8, 100#u8, 114#u8, 97#u8, 116#u8, 105#u8, 111#u8]
  | .ParentBasedAlwaysOn => [112#u8, 97#u8, 114#u8, 101#u8, 110#u8, 116#u8, 98#u8, 97#u8, 115#u8, 101#u8, 100#u8, 95#u8, 97#u8, 108#u8, 119#u8, 97#u8, 121#u8, 115#u8, 95#u8, 111#u8, 110#u8]
  | .ParentBasedAlwaysOff => [112#u8, 97#u8, 114#u8, 101#u8, 110#u8, 116#u8, 98#u8, 97#u8, 115#u8, 101#u8, 100#u8, 95#u8, 97#u8, 108#u8, 119#u8, 97#u8, 121#u8, 115#u8, 95#u8, 111#u8, 102#u8, 102#u8]
  | .ParentBasedTraceIdRatio => [112#u8, 97#u8, 114#u8, 101#u8, 110#u8, 116#u8, 98#u8, 97#u8, 115#u8, 101#u8, 100#u8, 95#u8, 116#u8, 114#u8, 97#u8, 99#u8, 101#u8, 105#u8, 100#u8, 114#u8, 97#u8, 116#u8, 105#u8, 111#u8]
theorem sampler_choice_f5cc6ea1_name_complete (v : finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice) :
    finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice.name v ⦃r => r.val = sampler_choice_f5cc6ea1_name_model v⦄ := by
  cases v <;> simp only [sampler_choice_f5cc6ea1_name_model]
  all_goals simp only [finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice.name, finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice.uses_ratio]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def sampler_choice_f5cc6ea1_uses_ratio_model (v : finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice) : Bool :=
  match v with
  | .AlwaysOn => false
  | .AlwaysOff => false
  | .TraceIdRatio => true
  | .ParentBasedAlwaysOn => false
  | .ParentBasedAlwaysOff => false
  | .ParentBasedTraceIdRatio => true
theorem sampler_choice_f5cc6ea1_uses_ratio_complete (v : finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice) :
    finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice.uses_ratio v ⦃r => r = sampler_choice_f5cc6ea1_uses_ratio_model v⦄ := by
  cases v <;> simp only [sampler_choice_f5cc6ea1_uses_ratio_model]
  all_goals simp only [finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice.name, finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice.uses_ratio]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end artifactkeeper_kernel.Verified.FiniteCatalog
