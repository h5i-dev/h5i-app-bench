import OxicloudKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def authz_denial_visibility_4079d78e_as_str_model (v : finite_catalog.authz_denial_visibility_4079d78e.AuthzDenialVisibility) : List U8 :=
  match v with
  | .Visible => [118#u8, 105#u8, 115#u8, 105#u8, 98#u8, 108#u8, 101#u8]
  | .Hidden => [104#u8, 105#u8, 100#u8, 100#u8, 101#u8, 110#u8]
theorem authz_denial_visibility_4079d78e_as_str_complete (v : finite_catalog.authz_denial_visibility_4079d78e.AuthzDenialVisibility) :
    finite_catalog.authz_denial_visibility_4079d78e.AuthzDenialVisibility.as_str v ⦃r => r.val = authz_denial_visibility_4079d78e_as_str_model v⦄ := by
  cases v <;> simp only [authz_denial_visibility_4079d78e_as_str_model]
  all_goals simp only [finite_catalog.authz_denial_visibility_4079d78e.AuthzDenialVisibility.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def ref_level_2ec664a4_as_str_model (v : finite_catalog.ref_level_2ec664a4.RefLevel) : List U8 :=
  match v with
  | .Chunk => [99#u8, 104#u8, 117#u8, 110#u8, 107#u8]
  | .Manifest => [109#u8, 97#u8, 110#u8, 105#u8, 102#u8, 101#u8, 115#u8, 116#u8]
theorem ref_level_2ec664a4_as_str_complete (v : finite_catalog.ref_level_2ec664a4.RefLevel) :
    finite_catalog.ref_level_2ec664a4.RefLevel.as_str v ⦃r => r.val = ref_level_2ec664a4_as_str_model v⦄ := by
  cases v <;> simp only [ref_level_2ec664a4_as_str_model]
  all_goals simp only [finite_catalog.ref_level_2ec664a4.RefLevel.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def checksum_alg_cf7683cd_as_str_model (v : finite_catalog.checksum_alg_cf7683cd.ChecksumAlg) : List U8 :=
  match v with
  | .Md5 => [109#u8, 100#u8, 53#u8]
  | .Sha256 => [115#u8, 104#u8, 97#u8, 50#u8, 53#u8, 54#u8]
  | .Blake3 => [98#u8, 108#u8, 97#u8, 107#u8, 101#u8, 51#u8]
theorem checksum_alg_cf7683cd_as_str_complete (v : finite_catalog.checksum_alg_cf7683cd.ChecksumAlg) :
    finite_catalog.checksum_alg_cf7683cd.ChecksumAlg.as_str v ⦃r => r.val = checksum_alg_cf7683cd_as_str_model v⦄ := by
  cases v <;> simp only [checksum_alg_cf7683cd_as_str_model]
  all_goals simp only [finite_catalog.checksum_alg_cf7683cd.ChecksumAlg.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def thumbnail_size_e90c1659_as_str_model (v : finite_catalog.thumbnail_size_e90c1659.ThumbnailSize) : List U8 :=
  match v with
  | .Icon => [73#u8, 99#u8, 111#u8, 110#u8]
  | .Preview => [80#u8, 114#u8, 101#u8, 118#u8, 105#u8, 101#u8, 119#u8]
  | .Large => [76#u8, 97#u8, 114#u8, 103#u8, 101#u8]
theorem thumbnail_size_e90c1659_as_str_complete (v : finite_catalog.thumbnail_size_e90c1659.ThumbnailSize) :
    finite_catalog.thumbnail_size_e90c1659.ThumbnailSize.as_str v ⦃r => r.val = thumbnail_size_e90c1659_as_str_model v⦄ := by
  cases v <;> simp only [thumbnail_size_e90c1659_as_str_model]
  all_goals simp only [finite_catalog.thumbnail_size_e90c1659.ThumbnailSize.as_str, finite_catalog.thumbnail_size_e90c1659.ThumbnailSize.max_dimension, finite_catalog.thumbnail_size_e90c1659.ThumbnailSize.dir_name]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def thumbnail_size_e90c1659_max_dimension_model (v : finite_catalog.thumbnail_size_e90c1659.ThumbnailSize) : U32 :=
  match v with
  | .Icon => 150#u32
  | .Preview => 400#u32
  | .Large => 800#u32
theorem thumbnail_size_e90c1659_max_dimension_complete (v : finite_catalog.thumbnail_size_e90c1659.ThumbnailSize) :
    finite_catalog.thumbnail_size_e90c1659.ThumbnailSize.max_dimension v ⦃r => r = thumbnail_size_e90c1659_max_dimension_model v⦄ := by
  cases v <;> simp only [thumbnail_size_e90c1659_max_dimension_model]
  all_goals simp only [finite_catalog.thumbnail_size_e90c1659.ThumbnailSize.as_str, finite_catalog.thumbnail_size_e90c1659.ThumbnailSize.max_dimension, finite_catalog.thumbnail_size_e90c1659.ThumbnailSize.dir_name]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def thumbnail_size_e90c1659_dir_name_model (v : finite_catalog.thumbnail_size_e90c1659.ThumbnailSize) : List U8 :=
  match v with
  | .Icon => [105#u8, 99#u8, 111#u8, 110#u8]
  | .Preview => [112#u8, 114#u8, 101#u8, 118#u8, 105#u8, 101#u8, 119#u8]
  | .Large => [108#u8, 97#u8, 114#u8, 103#u8, 101#u8]
theorem thumbnail_size_e90c1659_dir_name_complete (v : finite_catalog.thumbnail_size_e90c1659.ThumbnailSize) :
    finite_catalog.thumbnail_size_e90c1659.ThumbnailSize.dir_name v ⦃r => r.val = thumbnail_size_e90c1659_dir_name_model v⦄ := by
  cases v <;> simp only [thumbnail_size_e90c1659_dir_name_model]
  all_goals simp only [finite_catalog.thumbnail_size_e90c1659.ThumbnailSize.as_str, finite_catalog.thumbnail_size_e90c1659.ThumbnailSize.max_dimension, finite_catalog.thumbnail_size_e90c1659.ThumbnailSize.dir_name]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def thumbnail_format_e90c1659_as_str_model (v : finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat) : List U8 :=
  match v with
  | .Webp => [87#u8, 101#u8, 98#u8, 112#u8]
  | .Jpeg => [74#u8, 112#u8, 101#u8, 103#u8]
theorem thumbnail_format_e90c1659_as_str_complete (v : finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat) :
    finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat.as_str v ⦃r => r.val = thumbnail_format_e90c1659_as_str_model v⦄ := by
  cases v <;> simp only [thumbnail_format_e90c1659_as_str_model]
  all_goals simp only [finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat.as_str, finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat.ext, finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat.mime]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def thumbnail_format_e90c1659_ext_model (v : finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat) : List U8 :=
  match v with
  | .Webp => [119#u8, 101#u8, 98#u8, 112#u8]
  | .Jpeg => [106#u8, 112#u8, 103#u8]
theorem thumbnail_format_e90c1659_ext_complete (v : finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat) :
    finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat.ext v ⦃r => r.val = thumbnail_format_e90c1659_ext_model v⦄ := by
  cases v <;> simp only [thumbnail_format_e90c1659_ext_model]
  all_goals simp only [finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat.as_str, finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat.ext, finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat.mime]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def thumbnail_format_e90c1659_mime_model (v : finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat) : List U8 :=
  match v with
  | .Webp => [105#u8, 109#u8, 97#u8, 103#u8, 101#u8, 47#u8, 119#u8, 101#u8, 98#u8, 112#u8]
  | .Jpeg => [105#u8, 109#u8, 97#u8, 103#u8, 101#u8, 47#u8, 106#u8, 112#u8, 101#u8, 103#u8]
theorem thumbnail_format_e90c1659_mime_complete (v : finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat) :
    finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat.mime v ⦃r => r.val = thumbnail_format_e90c1659_mime_model v⦄ := by
  cases v <;> simp only [thumbnail_format_e90c1659_mime_model]
  all_goals simp only [finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat.as_str, finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat.ext, finite_catalog.thumbnail_format_e90c1659.ThumbnailFormat.mime]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def output_format_f1a5ab73_extension_model (v : finite_catalog.output_format_f1a5ab73.OutputFormat) : List U8 :=
  match v with
  | .WebP => [119#u8, 101#u8, 98#u8, 112#u8]
theorem output_format_f1a5ab73_extension_complete (v : finite_catalog.output_format_f1a5ab73.OutputFormat) :
    finite_catalog.output_format_f1a5ab73.OutputFormat.extension v ⦃r => r.val = output_format_f1a5ab73_extension_model v⦄ := by
  cases v <;> simp only [output_format_f1a5ab73_extension_model]
  all_goals simp only [finite_catalog.output_format_f1a5ab73.OutputFormat.extension, finite_catalog.output_format_f1a5ab73.OutputFormat.mime_type]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def output_format_f1a5ab73_mime_type_model (v : finite_catalog.output_format_f1a5ab73.OutputFormat) : List U8 :=
  match v with
  | .WebP => [105#u8, 109#u8, 97#u8, 103#u8, 101#u8, 47#u8, 119#u8, 101#u8, 98#u8, 112#u8]
theorem output_format_f1a5ab73_mime_type_complete (v : finite_catalog.output_format_f1a5ab73.OutputFormat) :
    finite_catalog.output_format_f1a5ab73.OutputFormat.mime_type v ⦃r => r.val = output_format_f1a5ab73_mime_type_model v⦄ := by
  cases v <;> simp only [output_format_f1a5ab73_mime_type_model]
  all_goals simp only [finite_catalog.output_format_f1a5ab73.OutputFormat.extension, finite_catalog.output_format_f1a5ab73.OutputFormat.mime_type]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def device_poll_error_1fb5547a_error_code_model (v : finite_catalog.device_poll_error_1fb5547a.DevicePollError) : List U8 :=
  match v with
  | .AuthorizationPending => [97#u8, 117#u8, 116#u8, 104#u8, 111#u8, 114#u8, 105#u8, 122#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 95#u8, 112#u8, 101#u8, 110#u8, 100#u8, 105#u8, 110#u8, 103#u8]
  | .SlowDown => [115#u8, 108#u8, 111#u8, 119#u8, 95#u8, 100#u8, 111#u8, 119#u8, 110#u8]
  | .AccessDenied => [97#u8, 99#u8, 99#u8, 101#u8, 115#u8, 115#u8, 95#u8, 100#u8, 101#u8, 110#u8, 105#u8, 101#u8, 100#u8]
  | .ExpiredToken => [101#u8, 120#u8, 112#u8, 105#u8, 114#u8, 101#u8, 100#u8, 95#u8, 116#u8, 111#u8, 107#u8, 101#u8, 110#u8]
  | .InvalidDeviceCode => [105#u8, 110#u8, 118#u8, 97#u8, 108#u8, 105#u8, 100#u8, 95#u8, 103#u8, 114#u8, 97#u8, 110#u8, 116#u8]
theorem device_poll_error_1fb5547a_error_code_complete (v : finite_catalog.device_poll_error_1fb5547a.DevicePollError) :
    finite_catalog.device_poll_error_1fb5547a.DevicePollError.error_code v ⦃r => r.val = device_poll_error_1fb5547a_error_code_model v⦄ := by
  cases v <;> simp only [device_poll_error_1fb5547a_error_code_model]
  all_goals simp only [finite_catalog.device_poll_error_1fb5547a.DevicePollError.error_code, finite_catalog.device_poll_error_1fb5547a.DevicePollError.description, finite_catalog.device_poll_error_1fb5547a.DevicePollError.http_status]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def device_poll_error_1fb5547a_description_model (v : finite_catalog.device_poll_error_1fb5547a.DevicePollError) : List U8 :=
  match v with
  | .AuthorizationPending => [84#u8, 104#u8, 101#u8, 32#u8, 97#u8, 117#u8, 116#u8, 104#u8, 111#u8, 114#u8, 105#u8, 122#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 32#u8, 114#u8, 101#u8, 113#u8, 117#u8, 101#u8, 115#u8, 116#u8, 32#u8, 105#u8, 115#u8, 32#u8, 115#u8, 116#u8, 105#u8, 108#u8, 108#u8, 32#u8, 112#u8, 101#u8, 110#u8, 100#u8, 105#u8, 110#u8, 103#u8, 46#u8, 32#u8, 67#u8, 111#u8, 110#u8, 116#u8, 105#u8, 110#u8, 117#u8, 101#u8, 32#u8, 112#u8, 111#u8, 108#u8, 108#u8, 105#u8, 110#u8, 103#u8, 46#u8]
  | .SlowDown => [89#u8, 111#u8, 117#u8, 32#u8, 97#u8, 114#u8, 101#u8, 32#u8, 112#u8, 111#u8, 108#u8, 108#u8, 105#u8, 110#u8, 103#u8, 32#u8, 116#u8, 111#u8, 111#u8, 32#u8, 102#u8, 114#u8, 101#u8, 113#u8, 117#u8, 101#u8, 110#u8, 116#u8, 108#u8, 121#u8, 46#u8, 32#u8, 80#u8, 108#u8, 101#u8, 97#u8, 115#u8, 101#u8, 32#u8, 115#u8, 108#u8, 111#u8, 119#u8, 32#u8, 100#u8, 111#u8, 119#u8, 110#u8, 46#u8]
  | .AccessDenied => [84#u8, 104#u8, 101#u8, 32#u8, 117#u8, 115#u8, 101#u8, 114#u8, 32#u8, 100#u8, 101#u8, 110#u8, 105#u8, 101#u8, 100#u8, 32#u8, 116#u8, 104#u8, 101#u8, 32#u8, 97#u8, 117#u8, 116#u8, 104#u8, 111#u8, 114#u8, 105#u8, 122#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 32#u8, 114#u8, 101#u8, 113#u8, 117#u8, 101#u8, 115#u8, 116#u8, 46#u8]
  | .ExpiredToken => [84#u8, 104#u8, 101#u8, 32#u8, 100#u8, 101#u8, 118#u8, 105#u8, 99#u8, 101#u8, 95#u8, 99#u8, 111#u8, 100#u8, 101#u8, 32#u8, 104#u8, 97#u8, 115#u8, 32#u8, 101#u8, 120#u8, 112#u8, 105#u8, 114#u8, 101#u8, 100#u8, 46#u8, 32#u8, 80#u8, 108#u8, 101#u8, 97#u8, 115#u8, 101#u8, 32#u8, 115#u8, 116#u8, 97#u8, 114#u8, 116#u8, 32#u8, 97#u8, 32#u8, 110#u8, 101#u8, 119#u8, 32#u8, 97#u8, 117#u8, 116#u8, 104#u8, 111#u8, 114#u8, 105#u8, 122#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 32#u8, 102#u8, 108#u8, 111#u8, 119#u8, 46#u8]
  | .InvalidDeviceCode => [84#u8, 104#u8, 101#u8, 32#u8, 100#u8, 101#u8, 118#u8, 105#u8, 99#u8, 101#u8, 95#u8, 99#u8, 111#u8, 100#u8, 101#u8, 32#u8, 105#u8, 115#u8, 32#u8, 110#u8, 111#u8, 116#u8, 32#u8, 114#u8, 101#u8, 99#u8, 111#u8, 103#u8, 110#u8, 105#u8, 122#u8, 101#u8, 100#u8, 46#u8]
theorem device_poll_error_1fb5547a_description_complete (v : finite_catalog.device_poll_error_1fb5547a.DevicePollError) :
    finite_catalog.device_poll_error_1fb5547a.DevicePollError.description v ⦃r => r.val = device_poll_error_1fb5547a_description_model v⦄ := by
  cases v <;> simp only [device_poll_error_1fb5547a_description_model]
  all_goals simp only [finite_catalog.device_poll_error_1fb5547a.DevicePollError.error_code, finite_catalog.device_poll_error_1fb5547a.DevicePollError.description, finite_catalog.device_poll_error_1fb5547a.DevicePollError.http_status]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def device_poll_error_1fb5547a_http_status_model (v : finite_catalog.device_poll_error_1fb5547a.DevicePollError) : U16 :=
  match v with
  | .AuthorizationPending => 400#u16
  | .SlowDown => 400#u16
  | .AccessDenied => 403#u16
  | .ExpiredToken => 400#u16
  | .InvalidDeviceCode => 400#u16
theorem device_poll_error_1fb5547a_http_status_complete (v : finite_catalog.device_poll_error_1fb5547a.DevicePollError) :
    finite_catalog.device_poll_error_1fb5547a.DevicePollError.http_status v ⦃r => r = device_poll_error_1fb5547a_http_status_model v⦄ := by
  cases v <;> simp only [device_poll_error_1fb5547a_http_status_model]
  all_goals simp only [finite_catalog.device_poll_error_1fb5547a.DevicePollError.error_code, finite_catalog.device_poll_error_1fb5547a.DevicePollError.description, finite_catalog.device_poll_error_1fb5547a.DevicePollError.http_status]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def notify_trigger_5dfe5802_audit_str_model (v : finite_catalog.notify_trigger_5dfe5802.NotifyTrigger) : List U8 :=
  match v with
  | .GrantCreated => [103#u8, 114#u8, 97#u8, 110#u8, 116#u8, 95#u8, 99#u8, 114#u8, 101#u8, 97#u8, 116#u8, 101#u8, 100#u8]
  | .ManualResend => [109#u8, 97#u8, 110#u8, 117#u8, 97#u8, 108#u8, 95#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 100#u8]
theorem notify_trigger_5dfe5802_audit_str_complete (v : finite_catalog.notify_trigger_5dfe5802.NotifyTrigger) :
    finite_catalog.notify_trigger_5dfe5802.NotifyTrigger.audit_str v ⦃r => r.val = notify_trigger_5dfe5802_audit_str_model v⦄ := by
  cases v <;> simp only [notify_trigger_5dfe5802_audit_str_model]
  all_goals simp only [finite_catalog.notify_trigger_5dfe5802.NotifyTrigger.audit_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def notify_kind_5dfe5802_audit_str_model (v : finite_catalog.notify_kind_5dfe5802.NotifyKind) : List U8 :=
  match v with
  | .MagicLink => [109#u8, 97#u8, 103#u8, 105#u8, 99#u8, 95#u8, 108#u8, 105#u8, 110#u8, 107#u8]
  | .PlainNotification => [112#u8, 108#u8, 97#u8, 105#u8, 110#u8, 95#u8, 110#u8, 111#u8, 116#u8, 105#u8, 102#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8]
theorem notify_kind_5dfe5802_audit_str_complete (v : finite_catalog.notify_kind_5dfe5802.NotifyKind) :
    finite_catalog.notify_kind_5dfe5802.NotifyKind.audit_str v ⦃r => r.val = notify_kind_5dfe5802_audit_str_model v⦄ := by
  cases v <;> simp only [notify_kind_5dfe5802_audit_str_model]
  all_goals simp only [finite_catalog.notify_kind_5dfe5802.NotifyKind.audit_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def cipher_kind_a4fe67b2_as_str_model (v : finite_catalog.cipher_kind_a4fe67b2.CipherKind) : List U8 :=
  match v with
  | .AesGcm256 => [97#u8, 101#u8, 115#u8, 45#u8, 50#u8, 53#u8, 54#u8, 45#u8, 103#u8, 99#u8, 109#u8]
  | .None => [110#u8, 111#u8, 110#u8, 101#u8]
theorem cipher_kind_a4fe67b2_as_str_complete (v : finite_catalog.cipher_kind_a4fe67b2.CipherKind) :
    finite_catalog.cipher_kind_a4fe67b2.CipherKind.as_str v ⦃r => r.val = cipher_kind_a4fe67b2_as_str_model v⦄ := by
  cases v <;> simp only [cipher_kind_a4fe67b2_as_str_model]
  all_goals simp only [finite_catalog.cipher_kind_a4fe67b2.CipherKind.as_str, finite_catalog.cipher_kind_a4fe67b2.CipherKind.needs_key]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def cipher_kind_a4fe67b2_needs_key_model (v : finite_catalog.cipher_kind_a4fe67b2.CipherKind) : Bool :=
  match v with
  | .AesGcm256 => true
  | .None => false
theorem cipher_kind_a4fe67b2_needs_key_complete (v : finite_catalog.cipher_kind_a4fe67b2.CipherKind) :
    finite_catalog.cipher_kind_a4fe67b2.CipherKind.needs_key v ⦃r => r = cipher_kind_a4fe67b2_needs_key_model v⦄ := by
  cases v <;> simp only [cipher_kind_a4fe67b2_needs_key_model]
  all_goals simp only [finite_catalog.cipher_kind_a4fe67b2.CipherKind.as_str, finite_catalog.cipher_kind_a4fe67b2.CipherKind.needs_key]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def device_code_status_fb933849_as_str_model (v : finite_catalog.device_code_status_fb933849.DeviceCodeStatus) : List U8 :=
  match v with
  | .Pending => [112#u8, 101#u8, 110#u8, 100#u8, 105#u8, 110#u8, 103#u8]
  | .Authorized => [97#u8, 117#u8, 116#u8, 104#u8, 111#u8, 114#u8, 105#u8, 122#u8, 101#u8, 100#u8]
  | .Denied => [100#u8, 101#u8, 110#u8, 105#u8, 101#u8, 100#u8]
  | .Expired => [101#u8, 120#u8, 112#u8, 105#u8, 114#u8, 101#u8, 100#u8]
theorem device_code_status_fb933849_as_str_complete (v : finite_catalog.device_code_status_fb933849.DeviceCodeStatus) :
    finite_catalog.device_code_status_fb933849.DeviceCodeStatus.as_str v ⦃r => r.val = device_code_status_fb933849_as_str_model v⦄ := by
  cases v <;> simp only [device_code_status_fb933849_as_str_model]
  all_goals simp only [finite_catalog.device_code_status_fb933849.DeviceCodeStatus.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def drive_kind_bf867fda_as_str_model (v : finite_catalog.drive_kind_bf867fda.DriveKind) : List U8 :=
  match v with
  | .Personal => [112#u8, 101#u8, 114#u8, 115#u8, 111#u8, 110#u8, 97#u8, 108#u8]
  | .Shared => [115#u8, 104#u8, 97#u8, 114#u8, 101#u8, 100#u8]
theorem drive_kind_bf867fda_as_str_complete (v : finite_catalog.drive_kind_bf867fda.DriveKind) :
    finite_catalog.drive_kind_bf867fda.DriveKind.as_str v ⦃r => r.val = drive_kind_bf867fda_as_str_model v⦄ := by
  cases v <;> simp only [drive_kind_bf867fda_as_str_model]
  all_goals simp only [finite_catalog.drive_kind_bf867fda.DriveKind.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def magic_link_status_023c994e_as_str_model (v : finite_catalog.magic_link_status_023c994e.MagicLinkStatus) : List U8 :=
  match v with
  | .Pending => [112#u8, 101#u8, 110#u8, 100#u8, 105#u8, 110#u8, 103#u8]
  | .Used => [117#u8, 115#u8, 101#u8, 100#u8]
  | .Expired => [101#u8, 120#u8, 112#u8, 105#u8, 114#u8, 101#u8, 100#u8]
theorem magic_link_status_023c994e_as_str_complete (v : finite_catalog.magic_link_status_023c994e.MagicLinkStatus) :
    finite_catalog.magic_link_status_023c994e.MagicLinkStatus.as_str v ⦃r => r.val = magic_link_status_023c994e_as_str_model v⦄ := by
  cases v <;> simp only [magic_link_status_023c994e_as_str_model]
  all_goals simp only [finite_catalog.magic_link_status_023c994e.MagicLinkStatus.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def session_origin_086d7c6c_as_str_model (v : finite_catalog.session_origin_086d7c6c.SessionOrigin) : List U8 :=
  match v with
  | .Password => [112#u8, 97#u8, 115#u8, 115#u8, 119#u8, 111#u8, 114#u8, 100#u8]
  | .Opaque => [111#u8, 112#u8, 97#u8, 113#u8, 117#u8, 101#u8]
  | .MagicLink => [109#u8, 97#u8, 103#u8, 105#u8, 99#u8, 95#u8, 108#u8, 105#u8, 110#u8, 107#u8]
  | .Oidc => [111#u8, 105#u8, 100#u8, 99#u8]
  | .Device => [100#u8, 101#u8, 118#u8, 105#u8, 99#u8, 101#u8]
  | .Unknown => [117#u8, 110#u8, 107#u8, 110#u8, 111#u8, 119#u8, 110#u8]
theorem session_origin_086d7c6c_as_str_complete (v : finite_catalog.session_origin_086d7c6c.SessionOrigin) :
    finite_catalog.session_origin_086d7c6c.SessionOrigin.as_str v ⦃r => r.val = session_origin_086d7c6c_as_str_model v⦄ := by
  cases v <;> simp only [session_origin_086d7c6c_as_str_model]
  all_goals simp only [finite_catalog.session_origin_086d7c6c.SessionOrigin.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def user_role_d47f77bc_as_str_model (v : finite_catalog.user_role_d47f77bc.UserRole) : List U8 :=
  match v with
  | .Owner => [111#u8, 119#u8, 110#u8, 101#u8, 114#u8]
  | .Admin => [97#u8, 100#u8, 109#u8, 105#u8, 110#u8]
  | .User => [117#u8, 115#u8, 101#u8, 114#u8]
  | .Anonymous => [97#u8, 110#u8, 111#u8, 110#u8, 121#u8, 109#u8, 111#u8, 117#u8, 115#u8]
theorem user_role_d47f77bc_as_str_complete (v : finite_catalog.user_role_d47f77bc.UserRole) :
    finite_catalog.user_role_d47f77bc.UserRole.as_str v ⦃r => r.val = user_role_d47f77bc_as_str_model v⦄ := by
  cases v <;> simp only [user_role_d47f77bc_as_str_model]
  all_goals simp only [finite_catalog.user_role_d47f77bc.UserRole.as_str, finite_catalog.user_role_d47f77bc.UserRole.rank, finite_catalog.user_role_d47f77bc.UserRole.is_anonymous, finite_catalog.user_role_d47f77bc.UserRole.is_privileged]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def user_role_d47f77bc_rank_model (v : finite_catalog.user_role_d47f77bc.UserRole) : U8 :=
  match v with
  | .Owner => 3#u8
  | .Admin => 2#u8
  | .User => 1#u8
  | .Anonymous => 0#u8
theorem user_role_d47f77bc_rank_complete (v : finite_catalog.user_role_d47f77bc.UserRole) :
    finite_catalog.user_role_d47f77bc.UserRole.rank v ⦃r => r = user_role_d47f77bc_rank_model v⦄ := by
  cases v <;> simp only [user_role_d47f77bc_rank_model]
  all_goals simp only [finite_catalog.user_role_d47f77bc.UserRole.as_str, finite_catalog.user_role_d47f77bc.UserRole.rank, finite_catalog.user_role_d47f77bc.UserRole.is_anonymous, finite_catalog.user_role_d47f77bc.UserRole.is_privileged]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def user_role_d47f77bc_is_anonymous_model (v : finite_catalog.user_role_d47f77bc.UserRole) : Bool :=
  match v with
  | .Owner => false
  | .Admin => false
  | .User => false
  | .Anonymous => true
theorem user_role_d47f77bc_is_anonymous_complete (v : finite_catalog.user_role_d47f77bc.UserRole) :
    finite_catalog.user_role_d47f77bc.UserRole.is_anonymous v ⦃r => r = user_role_d47f77bc_is_anonymous_model v⦄ := by
  cases v <;> simp only [user_role_d47f77bc_is_anonymous_model]
  all_goals simp only [finite_catalog.user_role_d47f77bc.UserRole.as_str, finite_catalog.user_role_d47f77bc.UserRole.rank, finite_catalog.user_role_d47f77bc.UserRole.is_anonymous, finite_catalog.user_role_d47f77bc.UserRole.is_privileged]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def user_role_d47f77bc_is_privileged_model (v : finite_catalog.user_role_d47f77bc.UserRole) : Bool :=
  match v with
  | .Owner => true
  | .Admin => true
  | .User => false
  | .Anonymous => false
theorem user_role_d47f77bc_is_privileged_complete (v : finite_catalog.user_role_d47f77bc.UserRole) :
    finite_catalog.user_role_d47f77bc.UserRole.is_privileged v ⦃r => r = user_role_d47f77bc_is_privileged_model v⦄ := by
  cases v <;> simp only [user_role_d47f77bc_is_privileged_model]
  all_goals simp only [finite_catalog.user_role_d47f77bc.UserRole.as_str, finite_catalog.user_role_d47f77bc.UserRole.rank, finite_catalog.user_role_d47f77bc.UserRole.is_anonymous, finite_catalog.user_role_d47f77bc.UserRole.is_privileged]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def federation_kind_d47f77bc_as_str_model (v : finite_catalog.federation_kind_d47f77bc.FederationKind) : List U8 :=
  match v with
  | .MagicLink => [109#u8, 97#u8, 103#u8, 105#u8, 99#u8, 95#u8, 108#u8, 105#u8, 110#u8, 107#u8]
  | .Ocm => [111#u8, 99#u8, 109#u8]
  | .Oidc => [111#u8, 105#u8, 100#u8, 99#u8]
theorem federation_kind_d47f77bc_as_str_complete (v : finite_catalog.federation_kind_d47f77bc.FederationKind) :
    finite_catalog.federation_kind_d47f77bc.FederationKind.as_str v ⦃r => r.val = federation_kind_d47f77bc_as_str_model v⦄ := by
  cases v <;> simp only [federation_kind_d47f77bc_as_str_model]
  all_goals simp only [finite_catalog.federation_kind_d47f77bc.FederationKind.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def error_kind_59712eff_as_str_model (v : finite_catalog.error_kind_59712eff.ErrorKind) : List U8 :=
  match v with
  | .NotFound => [78#u8, 111#u8, 116#u8, 32#u8, 70#u8, 111#u8, 117#u8, 110#u8, 100#u8]
  | .AlreadyExists => [65#u8, 108#u8, 114#u8, 101#u8, 97#u8, 100#u8, 121#u8, 32#u8, 69#u8, 120#u8, 105#u8, 115#u8, 116#u8, 115#u8]
  | .InvalidInput => [73#u8, 110#u8, 118#u8, 97#u8, 108#u8, 105#u8, 100#u8, 32#u8, 73#u8, 110#u8, 112#u8, 117#u8, 116#u8]
  | .AccessDenied => [65#u8, 99#u8, 99#u8, 101#u8, 115#u8, 115#u8, 32#u8, 68#u8, 101#u8, 110#u8, 105#u8, 101#u8, 100#u8]
  | .Timeout => [84#u8, 105#u8, 109#u8, 101#u8, 111#u8, 117#u8, 116#u8]
  | .TransientBackend => [84#u8, 114#u8, 97#u8, 110#u8, 115#u8, 105#u8, 101#u8, 110#u8, 116#u8, 32#u8, 66#u8, 97#u8, 99#u8, 107#u8, 101#u8, 110#u8, 100#u8]
  | .InternalError => [73#u8, 110#u8, 116#u8, 101#u8, 114#u8, 110#u8, 97#u8, 108#u8, 32#u8, 69#u8, 114#u8, 114#u8, 111#u8, 114#u8]
  | .NotImplemented => [78#u8, 111#u8, 116#u8, 32#u8, 73#u8, 109#u8, 112#u8, 108#u8, 101#u8, 109#u8, 101#u8, 110#u8, 116#u8, 101#u8, 100#u8]
  | .UnsupportedOperation => [85#u8, 110#u8, 115#u8, 117#u8, 112#u8, 112#u8, 111#u8, 114#u8, 116#u8, 101#u8, 100#u8, 32#u8, 79#u8, 112#u8, 101#u8, 114#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8]
  | .DatabaseError => [68#u8, 97#u8, 116#u8, 97#u8, 98#u8, 97#u8, 115#u8, 101#u8, 32#u8, 69#u8, 114#u8, 114#u8, 111#u8, 114#u8]
  | .QuotaExceeded => [81#u8, 117#u8, 111#u8, 116#u8, 97#u8, 32#u8, 69#u8, 120#u8, 99#u8, 101#u8, 101#u8, 100#u8, 101#u8, 100#u8]
  | .Conflict => [67#u8, 111#u8, 110#u8, 102#u8, 108#u8, 105#u8, 99#u8, 116#u8]
  | .PreconditionFailed => [80#u8, 114#u8, 101#u8, 99#u8, 111#u8, 110#u8, 100#u8, 105#u8, 116#u8, 105#u8, 111#u8, 110#u8, 32#u8, 70#u8, 97#u8, 105#u8, 108#u8, 101#u8, 100#u8]
theorem error_kind_59712eff_as_str_complete (v : finite_catalog.error_kind_59712eff.ErrorKind) :
    finite_catalog.error_kind_59712eff.ErrorKind.as_str v ⦃r => r.val = error_kind_59712eff_as_str_model v⦄ := by
  cases v <;> simp only [error_kind_59712eff_as_str_model]
  all_goals simp only [finite_catalog.error_kind_59712eff.ErrorKind.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def permission_5d9dca62_as_str_model (v : finite_catalog.permission_5d9dca62.Permission) : List U8 :=
  match v with
  | .Read => [114#u8, 101#u8, 97#u8, 100#u8]
  | .Create => [99#u8, 114#u8, 101#u8, 97#u8, 116#u8, 101#u8]
  | .Share => [115#u8, 104#u8, 97#u8, 114#u8, 101#u8]
  | .Comment => [99#u8, 111#u8, 109#u8, 109#u8, 101#u8, 110#u8, 116#u8]
  | .Delete => [100#u8, 101#u8, 108#u8, 101#u8, 116#u8, 101#u8]
  | .Update => [117#u8, 112#u8, 100#u8, 97#u8, 116#u8, 101#u8]
  | .Manage => [109#u8, 97#u8, 110#u8, 97#u8, 103#u8, 101#u8]
theorem permission_5d9dca62_as_str_complete (v : finite_catalog.permission_5d9dca62.Permission) :
    finite_catalog.permission_5d9dca62.Permission.as_str v ⦃r => r.val = permission_5d9dca62_as_str_model v⦄ := by
  cases v <;> simp only [permission_5d9dca62_as_str_model]
  all_goals simp only [finite_catalog.permission_5d9dca62.Permission.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def role_5d9dca62_as_str_model (v : finite_catalog.role_5d9dca62.Role) : List U8 :=
  match v with
  | .Viewer => [118#u8, 105#u8, 101#u8, 119#u8, 101#u8, 114#u8]
  | .Commenter => [99#u8, 111#u8, 109#u8, 109#u8, 101#u8, 110#u8, 116#u8, 101#u8, 114#u8]
  | .Contributor => [99#u8, 111#u8, 110#u8, 116#u8, 114#u8, 105#u8, 98#u8, 117#u8, 116#u8, 111#u8, 114#u8]
  | .Editor => [101#u8, 100#u8, 105#u8, 116#u8, 111#u8, 114#u8]
  | .Owner => [111#u8, 119#u8, 110#u8, 101#u8, 114#u8]
theorem role_5d9dca62_as_str_complete (v : finite_catalog.role_5d9dca62.Role) :
    finite_catalog.role_5d9dca62.Role.as_str v ⦃r => r.val = role_5d9dca62_as_str_model v⦄ := by
  cases v <;> simp only [role_5d9dca62_as_str_model]
  all_goals simp only [finite_catalog.role_5d9dca62.Role.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def run_status_dbd87cc3_as_str_model (v : finite_catalog.run_status_dbd87cc3.RunStatus) : List U8 :=
  match v with
  | .Running => [82#u8, 117#u8, 110#u8, 110#u8, 105#u8, 110#u8, 103#u8]
  | .Paused => [80#u8, 97#u8, 117#u8, 115#u8, 101#u8, 100#u8]
  | .CancelRequested => [67#u8, 97#u8, 110#u8, 99#u8, 101#u8, 108#u8, 82#u8, 101#u8, 113#u8, 117#u8, 101#u8, 115#u8, 116#u8, 101#u8, 100#u8]
  | .Completed => [67#u8, 111#u8, 109#u8, 112#u8, 108#u8, 101#u8, 116#u8, 101#u8, 100#u8]
  | .Failed => [70#u8, 97#u8, 105#u8, 108#u8, 101#u8, 100#u8]
  | .Cancelled => [67#u8, 97#u8, 110#u8, 99#u8, 101#u8, 108#u8, 108#u8, 101#u8, 100#u8]
theorem run_status_dbd87cc3_as_str_complete (v : finite_catalog.run_status_dbd87cc3.RunStatus) :
    finite_catalog.run_status_dbd87cc3.RunStatus.as_str v ⦃r => r.val = run_status_dbd87cc3_as_str_model v⦄ := by
  cases v <;> simp only [run_status_dbd87cc3_as_str_model]
  all_goals simp only [finite_catalog.run_status_dbd87cc3.RunStatus.as_str, finite_catalog.run_status_dbd87cc3.RunStatus.is_non_terminal]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def run_status_dbd87cc3_is_non_terminal_model (v : finite_catalog.run_status_dbd87cc3.RunStatus) : Bool :=
  match v with
  | .Running => true
  | .Paused => true
  | .CancelRequested => true
  | .Completed => false
  | .Failed => false
  | .Cancelled => false
theorem run_status_dbd87cc3_is_non_terminal_complete (v : finite_catalog.run_status_dbd87cc3.RunStatus) :
    finite_catalog.run_status_dbd87cc3.RunStatus.is_non_terminal v ⦃r => r = run_status_dbd87cc3_is_non_terminal_model v⦄ := by
  cases v <;> simp only [run_status_dbd87cc3_is_non_terminal_model]
  all_goals simp only [finite_catalog.run_status_dbd87cc3.RunStatus.as_str, finite_catalog.run_status_dbd87cc3.RunStatus.is_non_terminal]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def progress_kind_dbd87cc3_as_str_model (v : finite_catalog.progress_kind_dbd87cc3.ProgressKind) : List U8 :=
  match v with
  | .Count => [99#u8, 111#u8, 117#u8, 110#u8, 116#u8]
  | .Approximate => [97#u8, 112#u8, 112#u8, 114#u8, 111#u8, 120#u8, 105#u8, 109#u8, 97#u8, 116#u8, 101#u8]
theorem progress_kind_dbd87cc3_as_str_complete (v : finite_catalog.progress_kind_dbd87cc3.ProgressKind) :
    finite_catalog.progress_kind_dbd87cc3.ProgressKind.as_str v ⦃r => r.val = progress_kind_dbd87cc3_as_str_model v⦄ := by
  cases v <;> simp only [progress_kind_dbd87cc3_as_str_model]
  all_goals simp only [finite_catalog.progress_kind_dbd87cc3.ProgressKind.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def err_cause_75575f17_as_str_model (v : finite_catalog.err_cause_75575f17.ErrCause) : List U8 :=
  match v with
  | .Handler => [104#u8, 97#u8, 110#u8, 100#u8, 108#u8, 101#u8, 114#u8]
  | .Timeout => [116#u8, 105#u8, 109#u8, 101#u8, 111#u8, 117#u8, 116#u8]
  | .Panicked => [112#u8, 97#u8, 110#u8, 105#u8, 99#u8, 107#u8, 101#u8, 100#u8]
theorem err_cause_75575f17_as_str_complete (v : finite_catalog.err_cause_75575f17.ErrCause) :
    finite_catalog.err_cause_75575f17.ErrCause.as_str v ⦃r => r.val = err_cause_75575f17_as_str_model v⦄ := by
  cases v <;> simp only [err_cause_75575f17_as_str_model]
  all_goals simp only [finite_catalog.err_cause_75575f17.ErrCause.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def dpop_verify_error_8219bbef_reason_model (v : finite_catalog.dpop_verify_error_8219bbef.DpopVerifyError) : List U8 :=
  match v with
  | .Malformed => [109#u8, 97#u8, 108#u8, 102#u8, 111#u8, 114#u8, 109#u8, 101#u8, 100#u8, 95#u8, 106#u8, 119#u8, 115#u8]
  | .WrongTyp => [119#u8, 114#u8, 111#u8, 110#u8, 103#u8, 95#u8, 116#u8, 121#u8, 112#u8]
  | .WrongAlg => [119#u8, 114#u8, 111#u8, 110#u8, 103#u8, 95#u8, 97#u8, 108#u8, 103#u8]
  | .WrongJwk => [119#u8, 114#u8, 111#u8, 110#u8, 103#u8, 95#u8, 106#u8, 119#u8, 107#u8]
  | .SignatureInvalid => [115#u8, 105#u8, 103#u8, 110#u8, 97#u8, 116#u8, 117#u8, 114#u8, 101#u8, 95#u8, 105#u8, 110#u8, 118#u8, 97#u8, 108#u8, 105#u8, 100#u8]
  | .WrongHtm => [119#u8, 114#u8, 111#u8, 110#u8, 103#u8, 95#u8, 104#u8, 116#u8, 109#u8]
  | .WrongHtu => [119#u8, 114#u8, 111#u8, 110#u8, 103#u8, 95#u8, 104#u8, 116#u8, 117#u8]
  | .IatMissing => [105#u8, 97#u8, 116#u8, 95#u8, 109#u8, 105#u8, 115#u8, 115#u8, 105#u8, 110#u8, 103#u8]
  | .IatOutOfWindow => [105#u8, 97#u8, 116#u8, 95#u8, 111#u8, 117#u8, 116#u8, 95#u8, 111#u8, 102#u8, 95#u8, 119#u8, 105#u8, 110#u8, 100#u8, 111#u8, 119#u8]
  | .JtiMissing => [106#u8, 116#u8, 105#u8, 95#u8, 109#u8, 105#u8, 115#u8, 115#u8, 105#u8, 110#u8, 103#u8]
  | .JktMismatch => [106#u8, 107#u8, 116#u8, 95#u8, 109#u8, 105#u8, 115#u8, 109#u8, 97#u8, 116#u8, 99#u8, 104#u8]
theorem dpop_verify_error_8219bbef_reason_complete (v : finite_catalog.dpop_verify_error_8219bbef.DpopVerifyError) :
    finite_catalog.dpop_verify_error_8219bbef.DpopVerifyError.reason v ⦃r => r.val = dpop_verify_error_8219bbef_reason_model v⦄ := by
  cases v <;> simp only [dpop_verify_error_8219bbef_reason_model]
  all_goals simp only [finite_catalog.dpop_verify_error_8219bbef.DpopVerifyError.reason]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def output_format_a83b795c_extension_model (v : finite_catalog.output_format_a83b795c.OutputFormat) : List U8 :=
  match v with
  | .WebP => [119#u8, 101#u8, 98#u8, 112#u8]
theorem output_format_a83b795c_extension_complete (v : finite_catalog.output_format_a83b795c.OutputFormat) :
    finite_catalog.output_format_a83b795c.OutputFormat.extension v ⦃r => r.val = output_format_a83b795c_extension_model v⦄ := by
  cases v <;> simp only [output_format_a83b795c_extension_model]
  all_goals simp only [finite_catalog.output_format_a83b795c.OutputFormat.extension, finite_catalog.output_format_a83b795c.OutputFormat.mime_type]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def output_format_a83b795c_mime_type_model (v : finite_catalog.output_format_a83b795c.OutputFormat) : List U8 :=
  match v with
  | .WebP => [105#u8, 109#u8, 97#u8, 103#u8, 101#u8, 47#u8, 119#u8, 101#u8, 98#u8, 112#u8]
theorem output_format_a83b795c_mime_type_complete (v : finite_catalog.output_format_a83b795c.OutputFormat) :
    finite_catalog.output_format_a83b795c.OutputFormat.mime_type v ⦃r => r.val = output_format_a83b795c_mime_type_model v⦄ := by
  cases v <;> simp only [output_format_a83b795c_mime_type_model]
  all_goals simp only [finite_catalog.output_format_a83b795c.OutputFormat.extension, finite_catalog.output_format_a83b795c.OutputFormat.mime_type]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def opaque_mode_b0957357_as_str_model (v : finite_catalog.opaque_mode_b0957357.OpaqueMode) : List U8 :=
  match v with
  | .Off => [111#u8, 102#u8, 102#u8]
  | .Migrate => [109#u8, 105#u8, 103#u8, 114#u8, 97#u8, 116#u8, 101#u8]
  | .OpaqueOnly => [111#u8, 112#u8, 97#u8, 113#u8, 117#u8, 101#u8, 95#u8, 111#u8, 110#u8, 108#u8, 121#u8]
theorem opaque_mode_b0957357_as_str_complete (v : finite_catalog.opaque_mode_b0957357.OpaqueMode) :
    finite_catalog.opaque_mode_b0957357.OpaqueMode.as_str v ⦃r => r.val = opaque_mode_b0957357_as_str_model v⦄ := by
  cases v <;> simp only [opaque_mode_b0957357_as_str_model]
  all_goals simp only [finite_catalog.opaque_mode_b0957357.OpaqueMode.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def phase_ce65bf5b_as_str_model (v : finite_catalog.phase_ce65bf5b.Phase) : List U8 :=
  match v with
  | .Derived => [100#u8, 101#u8, 114#u8, 105#u8, 118#u8, 101#u8, 100#u8]
  | .Attached => [97#u8, 116#u8, 116#u8, 97#u8, 99#u8, 104#u8, 101#u8, 100#u8]
theorem phase_ce65bf5b_as_str_complete (v : finite_catalog.phase_ce65bf5b.Phase) :
    finite_catalog.phase_ce65bf5b.Phase.as_str v ⦃r => r.val = phase_ce65bf5b_as_str_model v⦄ := by
  cases v <;> simp only [phase_ce65bf5b_as_str_model]
  all_goals simp only [finite_catalog.phase_ce65bf5b.Phase.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def thumbnail_size_4088a69a_max_dimension_model (v : finite_catalog.thumbnail_size_4088a69a.ThumbnailSize) : U32 :=
  match v with
  | .Icon => 150#u32
  | .Preview => 400#u32
  | .Large => 800#u32
theorem thumbnail_size_4088a69a_max_dimension_complete (v : finite_catalog.thumbnail_size_4088a69a.ThumbnailSize) :
    finite_catalog.thumbnail_size_4088a69a.ThumbnailSize.max_dimension v ⦃r => r = thumbnail_size_4088a69a_max_dimension_model v⦄ := by
  cases v <;> simp only [thumbnail_size_4088a69a_max_dimension_model]
  all_goals simp only [finite_catalog.thumbnail_size_4088a69a.ThumbnailSize.max_dimension, finite_catalog.thumbnail_size_4088a69a.ThumbnailSize.dir_name]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def thumbnail_size_4088a69a_dir_name_model (v : finite_catalog.thumbnail_size_4088a69a.ThumbnailSize) : List U8 :=
  match v with
  | .Icon => [105#u8, 99#u8, 111#u8, 110#u8]
  | .Preview => [112#u8, 114#u8, 101#u8, 118#u8, 105#u8, 101#u8, 119#u8]
  | .Large => [108#u8, 97#u8, 114#u8, 103#u8, 101#u8]
theorem thumbnail_size_4088a69a_dir_name_complete (v : finite_catalog.thumbnail_size_4088a69a.ThumbnailSize) :
    finite_catalog.thumbnail_size_4088a69a.ThumbnailSize.dir_name v ⦃r => r.val = thumbnail_size_4088a69a_dir_name_model v⦄ := by
  cases v <;> simp only [thumbnail_size_4088a69a_dir_name_model]
  all_goals simp only [finite_catalog.thumbnail_size_4088a69a.ThumbnailSize.max_dimension, finite_catalog.thumbnail_size_4088a69a.ThumbnailSize.dir_name]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end oxicloud_kernel.Verified.FiniteCatalog
