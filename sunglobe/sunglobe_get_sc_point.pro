;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_GET_SC_POINT
;
; Purpose     :	Extracts spacecraft pointing from ephemeris, if available.
;
; Category    :	Object graphics, 3D, Planning, generic
;
; Explanation : This routine calls GET_SUNSPICE_HPC_POINT to 
;
; Syntax      :	SUNGLOBE_GET_SC_POINT, sState
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	sState = SunGlobe state structure.
;
; Keywords    :	None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 18-Jan-2019, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_get_sc_point, sstate
;
;  Get the ephemeris date, taking the test offset into account if applicable.
;
utc = anytim2utc(sstate.target_date, /external)
if sstate.test_offset ne 0 then utc.year = utc.year + round(sstate.test_offset)
utc = anytim2utc(utc, /ccsds)
;
;  Call GET_SUNSPICE_HPC_POINT to get the spacecraft pointing.
;
errmsg = ''
point = get_sunspice_hpc_point(utc, sstate.spacecraft, errmsg=errmsg)
if errmsg ne '' then begin
    xack, errmsg
    return
endif
;
;  Use the pointing values, and get the current roll value from the widget.
;
xhpc = point[0]
yhpc = point[1]
widget_control, sstate.wroll, get_value=roll
;
;  Calculate the S/C coordinates.
;
dtor = !dpi / 180.d0
roll = roll * dtor
croll = cos(roll)
sroll = sin(roll)
;
conv = 3600.d0 / dtor
xx = xhpc / conv
yy = yhpc / conv
sinx = sin(xx)
cosy = cos(yy)
siny = sin(yy)
;
xx = cosy * sinx
yy = siny
xp = xx * croll - yy * sroll
yp = xx * sroll + yy * croll
;
ysc = asin(yp)
xsc = asin(xp / cos(ysc))
xsc = conv * xsc
ysc = conv * ysc
;
;  Refresh the graphics window.
;
widget_control, sstate.wxsc, set_value=xsc
widget_control, sstate.wysc, set_value=ysc
;
return
end
