;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_CLEANUP
;
; Purpose     :	Cleanup routine for SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	Destroys the objects used for SUNGLOBE and frees the pointers.
;
; Syntax      :	SUNGLOBE_CLEANUP, TLB
;
; Inputs      :	TLB     = Top level base ID
;
; Prev. Hist. :	Based on d_globe.pro in the IDL examples directory.
;
; History     :	Version 1, 4-Jan-2016, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
;----------------------------------------------------------------------
;
pro sunglobe_cleanup, tlb
;
;  Get the top-level UVALUE containing all the object and pointer IDs.
;
widget_control, tlb, get_uvalue=sstate, /no_copy
;
;  Free all objects and pointers associated with the individual images.
;
for i=0,n_elements(sstate.pimagestates)-1 do $
  if ptr_valid(sstate.pimagestates[i]) then begin
    obj_destroy, (*sstate.pimagestates[i]).omap_alpha
    ptr_free, sstate.pimagestates[i]
endif
;
;  Free the pointer associated with the SPICE field-of-view description.
;
ptr_free, sstate.ospice.psstate
;
;  Destroy the top objects & attribute objects.
;
obj_destroy, sstate.ocontainer
;
;  Map the group leader base if it exists.
;
if (widget_info(sstate.groupbase, /valid_id)) then $
        widget_control, sstate.groupbase, /map
;
end
