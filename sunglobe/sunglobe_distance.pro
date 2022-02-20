;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_DISTANCE
;
; Purpose     :	Called from SUNGLOBE_EVENT to control perspective.
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This routine is called from several points in SUNGLOBE_EVENT to
;               update the perspective of the globe based on the distance
;               value.
;
; Syntax      :	SUNGLOBE_DISTANCE, SSTATE
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	SSTATE  = Widget top-level state structure
;
; Calls       :	SUNGLOBE_PARSE_TMATRIX
;
; History     :	Version 1, 7-Jan-2016, William Thompson, GSFC
;               Version 2, 10-Apr-2019, WTT, corrected documentation
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_distance, sstate
;
;  Get the current eye distance in solar radii.  This is used below to adjust
;  the pointing parameters.
;
sstate.oview->getproperty, eye=eye0
;
;  Convert between AU and solar radii.  The distance is limited to 3 solar
;  radii or above.
;
widget_control, sstate.wdist, get_value=dist
eye = (dist * wcs_au() / wcs_rsun()) > 3
;
;  Apply the new eye distance, redraw the window, and adjust the widget
;  parameters.
;
sstate.oview->setproperty, eye=eye
sstate.owindow->draw, sstate.oview
sunglobe_parse_tmatrix, sstate
;
;  Update the distance parameter in the widget.
;
dist = eye * wcs_rsun() / wcs_au()
widget_control, sstate.wdist, set_value=dist
;
;  Adjust the pointing parameters accordingly.
;
widget_control, sstate.wxsun, get_value=xsun
widget_control, sstate.wxsun, set_value=xsun*eye0/eye
widget_control, sstate.wysun, get_value=ysun
widget_control, sstate.wysun, set_value=ysun*eye0/eye
;
;  Call sunglobe_repoint to correctly handle the effect of the change of
;  distance on the pointing.
;
sunglobe_repoint, sstate
;
end
