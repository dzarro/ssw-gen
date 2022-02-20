;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_SELECTED_IMAGE
;
; Purpose     :	Update information about selected image
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This routine is called from sunglobe_event.pro to update the
;               information about the selected image in the SUNGLOBE widget.
;
; Syntax      :	SUNGLOBE_SELECTED_IMAGE
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	SSTATE  = Widget top-level state structure
;
;               INDEX   = Index of selected image.  Setting this to -1 resets
;                         all the information widgets back to their default.
;
; Outputs     :	The information about the selected image is displayed in the
;               widget.
;
; History     :	Version 1, William Thompson, 30-Dec-2015
;               Version 2, 24-Dec-2019, WTT, added Adjust Pointing option
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_selected_image, sstate, index
;
;  If INDEX is less than zero, then clear the information about the selected
;  image.
;
if index lt 0 then begin
    sstate.selected_index = -1
    widget_control, sstate.wlabel, set_value=''
    widget_control, sstate.wimdate, set_value=''
    widget_control, sstate.wup, sensitive=0
    widget_control, sstate.wdown, sensitive=0
    widget_control, sstate.wopacity, set_value=0, sensitive=0
    widget_control, sstate.wadjust, sensitive=0
    widget_control, sstate.wdelete, sensitive=0
;
;  Otherwise, if not already done, display the information about the selected
;  image.
;
end else if index ne sstate.selected_index then begin
    pstate = sstate.pimagestates[index]
    sstate.selected_index = index
    widget_control, sstate.wlabel, set_value=(*pstate).label
    widget_control, sstate.wimdate, set_value=(*pstate).wcs.time.observ_date
    widget_control, sstate.wup, sensitive=(index gt 0)
    widget_control, sstate.wdown, sensitive=((index+1) lt sstate.nmapped)
    widget_control, sstate.wopacity, set_value=(*pstate).opacity, sensitive=1
    widget_control, sstate.wadjust, sensitive=1
    widget_control, sstate.wdelete, sensitive=1
endif
;
;  Make sure that this is the only image which is selected.
;
for i=0,sstate.nmapped-1 do widget_control, sstate.wimagebases[i].id, $
  set_value=(i eq sstate.selected_index)
;
end
