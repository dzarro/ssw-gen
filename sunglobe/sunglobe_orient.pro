;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_ORIENT
;
; Purpose     :	Called from SUNGLOBE_EVENT to control globe orientation
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This routine is called from several points in SUNGLOBE_EVENT to
;               update the orientation of the globe based on the input values.
;
; Syntax      :	SUNGLOBE_ORIENT, SSTATE
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	SSTATE  = Widget top-level state structure
;
; Calls       :	SUNGLOBE_PARSE_TMATRIX
;
; History     :	Version 1, 7-Jan-2016, William Thompson, GSFC
;               Version 2, 05-Aug-2016, WTT, change roll sign
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_orient, sstate
;
;  Start with the original orientation.
;
sstate.omodelrotate->setproperty, transform=sstate.origrotate
;
;  Read in the yaw, pitch, and yaw values from the widget, and apply each to
;  the globe in turn.
;
widget_control, sstate.wyaw, get_value=yaw
sstate.omodelrotate->rotate, [0, 1, 0], -yaw
;
widget_control, sstate.wpitch, get_value=pitch
sstate.omodelrotate->rotate, [1, 0, 0], pitch
;
widget_control, sstate.wroll, get_value=roll
sstate.omodelrotate->rotate, [0, 0, 1], roll
;
;  Redraw the window, and refresh the widget parameters.
;
sstate.owindow->draw, sstate.oview
sunglobe_parse_tmatrix, sstate
;
end
