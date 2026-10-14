import Verified.OxicloudBytes
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open oxicloud_kernel.model
open H5iAppLib hiding lit
open oxicloud_kernel.Verified.OxicloudBytes
namespace oxicloud_kernel.Verified.OxicloudAuthWire

theorem subject_bytes_ok (value : Subject) (out : alloc.vec.Vec U8)
    (h : authwire.subject_bytes value = ok out) : out.val = SubjectWire value := by
  cases value <;> unfold authwire.subject_bytes at h <;> h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at hs
  all_goals subst s
  all_goals have hc := copy_ok _ _ h
  all_goals simpa [SubjectWire, Array.to_slice, Array.make] using hc

theorem subject_parse_ok (raw : Slice U8) (id : U64) (o : Option Subject)
    (h : authwire.subject_parse raw id = ok o) (value : Subject) :
    (o = some value ↔ raw.val = SubjectWire value ∧ id = SubjectId value) := by
  unfold authwire.subject_parse at h
  h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars
  all_goals have he := equal_ok _ _ _ hb
  all_goals try have he1 := equal_ok _ _ _ hb1
  all_goals try have he2 := equal_ok _ _ _ hb2
  all_goals cases value <;> simp_all [SubjectWire, SubjectId, Array.to_slice, Array.make]

theorem subject_id_ok (value : Subject) : authwire.subject_id value = ok (SubjectId value) := by
  cases value <;> rfl

theorem resource_bytes_ok (value : Resource) (out : alloc.vec.Vec U8)
    (h : authwire.resource_bytes value = ok out) : out.val = ResourceWire value := by
  cases value <;> unfold authwire.resource_bytes at h <;> h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at hs
  all_goals subst s
  all_goals have hc := copy_ok _ _ h
  all_goals simpa [ResourceWire, Array.to_slice, Array.make] using hc

theorem resource_parse_ok (raw : Slice U8) (id : U64) (o : Option Resource)
    (h : authwire.resource_parse raw id = ok o) (value : Resource) :
    (o = some value ↔ raw.val = ResourceWire value ∧ id = ResourceId value) := by
  unfold authwire.resource_parse at h
  h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars
  all_goals have he := equal_ok _ _ _ hb
  all_goals try have he1 := equal_ok _ _ _ hb1
  all_goals try have he2 := equal_ok _ _ _ hb2
  all_goals try have he3 := equal_ok _ _ _ hb3
  all_goals try have he4 := equal_ok _ _ _ hb4
  all_goals try have he5 := equal_ok _ _ _ hb5
  all_goals cases value <;> simp_all [ResourceWire, ResourceId, Array.to_slice, Array.make]

theorem resource_id_ok (value : Resource) : authwire.resource_id value = ok (ResourceId value) := by
  cases value <;> rfl

theorem permission_bytes_ok (value : Permission) (out : alloc.vec.Vec U8)
    (h : authwire.permission_bytes value = ok out) : out.val = PermissionWire value := by
  cases value <;> unfold authwire.permission_bytes at h <;> h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at hs
  all_goals subst s
  all_goals have hc := copy_ok _ _ h
  all_goals simpa [PermissionWire, Array.to_slice, Array.make] using hc

theorem permission_parse_ok (raw : Slice U8) (o : Option Permission)
    (h : authwire.permission_parse raw = ok o) (value : Permission) :
    (o = some value ↔ raw.val = PermissionWire value) := by
  unfold authwire.permission_parse at h
  h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars
  all_goals have he := equal_ok _ _ _ hb
  all_goals try have he1 := equal_ok _ _ _ hb1
  all_goals try have he2 := equal_ok _ _ _ hb2
  all_goals try have he3 := equal_ok _ _ _ hb3
  all_goals try have he4 := equal_ok _ _ _ hb4
  all_goals try have he5 := equal_ok _ _ _ hb5
  all_goals try have he6 := equal_ok _ _ _ hb6
  all_goals cases value <;> simp_all [PermissionWire, Array.to_slice, Array.make]

theorem role_bytes_ok (value : Role) (out : alloc.vec.Vec U8)
    (h : authwire.role_bytes value = ok out) : out.val = GrantRoleWire value := by
  cases value <;> unfold authwire.role_bytes at h <;> h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at hs
  all_goals subst s
  all_goals have hc := copy_ok _ _ h
  all_goals simpa [GrantRoleWire, Array.to_slice, Array.make] using hc

theorem role_parse_ok (raw : Slice U8) (o : Option Role)
    (h : authwire.role_parse raw = ok o) (value : Role) :
    (o = some value ↔ raw.val = GrantRoleWire value) := by
  unfold authwire.role_parse at h
  h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars
  all_goals have he := equal_ok _ _ _ hb
  all_goals try have he1 := equal_ok _ _ _ hb1
  all_goals try have he2 := equal_ok _ _ _ hb2
  all_goals try have he3 := equal_ok _ _ _ hb3
  all_goals try have he4 := equal_ok _ _ _ hb4
  all_goals cases value <;> simp_all [GrantRoleWire, Array.to_slice, Array.make]

/-- Identity projections cannot substitute a group or link for a user row. -/
theorem user_identity (s : Subject) (id : U64) :
    authwire.subject_user_id s = ok (some id) ↔ s = .User id := by
  cases s <;> simp [authwire.subject_user_id]

/-- Only a link principal can project to a share token identity. -/
theorem token_identity (s : Subject) (id : U64) :
    authwire.subject_token_id s = ok (some id) ↔ s = .Token id := by
  cases s <;> simp [authwire.subject_token_id]


/-- Enumeration preserves the stable query order. -/
theorem permission_all_ok (out : alloc.vec.Vec Permission)
    (h : authwire.permission_all = ok out) : out.val = PermissionOrder := by
  unfold authwire.permission_all at h
  h5i_invert h
  rw [push_ok h, push_ok hout5, push_ok hout4, push_ok hout3, push_ok hout2, push_ok hout1, push_ok hout_1]
  rfl

/-- Enumeration preserves the stable query order. -/
theorem role_all_ok (out : alloc.vec.Vec Role)
    (h : authwire.role_all = ok out) : out.val = RoleOrder := by
  unfold authwire.role_all at h
  h5i_invert h
  rw [push_ok h, push_ok hout3, push_ok hout2, push_ok hout1, push_ok hout_1]
  rfl

end oxicloud_kernel.Verified.OxicloudAuthWire
