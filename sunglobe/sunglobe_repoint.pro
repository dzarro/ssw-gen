;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_REPOINT
;
; Purpose     :	Handle repointing events in SUNGLOBE_EVENT
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	Called from sunglobe_event.pro to handle repointing events
;               caused by various operations.  Rather than changing the
;               viewplane parameters--which would also change the eye position,
;               and thus the perspective--the graphics objects are rotated
;               about the eye location.
;
; Syntax      :	SUNGLOBE_REPOINT, SSTATE
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	SSTATE= Widget top-level state structure
;
; Calls       :	WCS_AU, WCS_RSUN, SUNGLOBE_PARSE_TMATRIX
;
; History     :	Version 1, 7-Jan-2016, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_repoint, sstate
;
;  Revert to the original orientation.
;
sstate.omodeltranslate->setproperty, transform=sstate.origtranslate
;
;  Get the distance and the pointing values
;
widget_control, sstate.wdist, get_value=dist
rad = dist * wcs_au() / wcs_rsun() ;convert Solar radii to AU
;
widget_control, sstate.wxsun, get_value=xsun
widget_control, sstate.wysun, get_value=ysun
;
dtor = !dpi / 180.d0               ;conversion degrees to radians
asectorad = dtor / 3600.d0         ;conversion arcseconds to radians
;
;  Apply the X pointing.
;
xx = -xsun * asectorad
sstate.omodeltranslate->rotate, [0,1,0], -xx / dtor
sstate.omodeltranslate->translate, rad*sin(xx), 0, rad*(1-cos(xx))
;
;  Apply the Y pointing.
;
yy = -ysun * asectorad
sstate.omodeltranslate->rotate, [1,0,0], yy / dtor
sstate.omodeltranslate->translate, 0, rad*sin(yy), rad*(1-cos(yy))
;
;  Reformat the input parameters.
;
widget_control, sstate.wxsun, set_value=xsun
widget_control, sstate.wysun, set_value=ysun
;
;  Update the graphics window and widget fields.
;
sstate.owindow->draw, sstate.oview
sunglobe_parse_tmatrix, sstate
;
return
end
