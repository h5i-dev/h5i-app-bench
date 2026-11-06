import M5airqKernel
import H5iAppLib.Basic
open Aeneas Aeneas.Std Result m5airq_kernel
namespace Scratch
set_option maxHeartbeats 4000000

@[step] theorem ct_eq8_spec (a b : Array U8 8#usize) : ct_eq8 a b ⦃ _ => True ⦄ := by
  unfold ct_eq8; step*
@[step] theorem is_zero8_spec (t : Array U8 8#usize) : is_zero8 t ⦃ _ => True ⦄ := by
  unfold is_zero8; step*
@[step] theorem age_ok_spec (now created : U32) : age_ok now created ⦃ _ => True ⦄ := by
  unfold age_ok; step* <;> scalar_tac
@[step] theorem transport_blocks_spec (a b : Bool) : transport_blocks a b ⦃ _ => True ⦄ := by
  unfold transport_blocks; step*
@[step] theorem slot_valid_spec (slot : SessionSlot) (token : Array U8 8#usize) (now : U32) :
    slot_valid slot token now ⦃ _ => True ⦄ := by
  unfold slot_valid; step*
@[step] theorem validate_session_spec (store : SessionStore) (token : Array U8 8#usize) (now : U32) :
    validate_session store token now ⦃ _ => True ⦄ := by
  unfold validate_session; step*

theorem check_auth_total
    (cfg : AuthCfg) (store : SessionStore) (now : U32) (cp : Bool) (ct : Array U8 8#usize)
    (bp bm ahp ahm aqp aqm dok https health : Bool) :
    ∃ r, check_auth cfg store now cp ct bp bm ahp ahm aqp aqm dok https health = ok r := by
  have h : check_auth cfg store now cp ct bp bm ahp ahm aqp aqm dok https health ⦃ _ => True ⦄ := by
    unfold check_auth
    step*
  exact H5iAppLib.ok_of h

end Scratch
