import Spec
import H5iAppLib
/-! Derived `PartialEq`/`Clone` specs for every extracted type (one shared copy). -/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec
open H5iAppLib

h5i_derive_all
