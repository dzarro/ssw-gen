;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_SCPOINT
;
; Purpose     :	Update spacecraft pointing in SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation : Takes the spacecraft boresight pointing information in the
;               SUNGLOBE widget, and updates the graphics objects tied to the
;               boresight.  At the moment, the only graphics objects affected
;               are the symbol representing the boresight, and the SPICE, EUI,
;               and PHI (or generic) fields-of-view.
;
; Syntax      :	SUNGLOBE_SCPOINT, SSTATE
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	SSTATE= Widget top-level state structure
;
; Calls       :	SUNGLOBE_PARSE_TMATRIX
;
; History     :	Version 1, 20-Jan-2016, William Thompson, GSFC
;               Version 2, 26-Aug-2016, WTT, rebuild generic FOV
;               Version 3, 24-Feb-2022, WTT, split EUI into EUV and Lya channels
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_scpoint, sstate
;
;  Get the solar distance, and subtract one solar radius to stay in front of
;  the Sun.
;
sstate.oview->getproperty, eye=eye
dist = eye - 1
;
;  Get the boresight position from the widget, and convert to radians
;
widget_control, sstate.wxsc, get_value=xsc
widget_control, sstate.wysc, get_value=ysc
dtor = !dpi / 180.d0
asectorad = dtor / 3600.d0
xa = xsc * asectorad
ya = ysc * asectorad
;
;  Convert to cartesian coordinates.
;
sstate.obore->setproperty, data=[dist*tan(xa), dist*tan(ya)/cos(xa), 1]
;
;  Refresh the boresight position in the widget.
;
widget_control, sstate.wxsc, set_value=xsc
widget_control, sstate.wysc, set_value=ysc
;
;  Refresh the instrument fields-of-view.
;
sstate.ospice->build
sstate.oeuieuv->build
sstate.oeuilya->build
sstate.ophi->build
sstate.ogen->build
;
;  Update the graphics window and widget fields.
;
sstate.owindow->draw, sstate.oview
sunglobe_parse_tmatrix, sstate
;
return
end
