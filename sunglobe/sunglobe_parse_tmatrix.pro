;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_PARSE_TMATRIX
;
; Purpose     :	Derives angles from SUNGLOBE rotation object
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	Extracts the T-matrix from the rotation objection for the
;               SUNGLOBE program, and parses it to derive the longitude,
;               latitude, and roll.  These are then updated in the widget.
;
; Syntax      :	SUNGLOBE_PARSE_TMATRIX, SSTATE
;
; Examples    :	Called from sunglobe_event.pro
;
; Inputs      :	SSTATE  = Widget top-level state structure
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 04-Dec-2015, William Thompson, GSFC
;               Version 2, 05-Aug-2016, WTT, change roll sign
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_parse_tmatrix, sState
;
sstate.omodelrotate -> getproperty, transform=tmatrix
format = '(F10.3)'
;
roll = -atan(tmatrix[2,0], tmatrix[2,1]) * !radeg
widget_control, sstate.wroll, set_value=string(roll, format=format) ;
;
pitch = asin(tmatrix[2,2]) * !radeg
widget_control, sstate.wpitch, set_value=string(pitch, format=format)
;
yaw = atan(tmatrix[1,2], tmatrix[0,2]) * !radeg
if yaw lt 0 then yaw = yaw + 360
widget_control, sstate.wyaw, set_value=string(yaw, format=format)
;
end
