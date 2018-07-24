;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_GET_EPHEM
;
; Purpose     :	Update ephemeris information in SUNGLOBE widget
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation : This routine uses the target date in the SUNGLOBE program to
;               derive the position of the selected spacecraft (e.g Solar
;               Orbiter), and updates the globe and the widget information
;               accordingly.  Has no effect if outside the valid ephemeris
;               range.
;
; Syntax      :	SUNGLOBE_GET_EPHEM, SSTATE
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	SSTATE  = Widget top-level state structure
;
; Calls       :	ANYTIM2UTC, GET_SUNSPICE_LONLAT, SUNGLOBE_DISTANCE,
;               SUNGLOBE_ORIENT, GET_SUNSPICE_ROLL
;
; History     :	Version 1, 7-Jan-2016, William Thompson, GSFC
;               Version 2, 4-Aug-2016, WTT, use SUNSPICE package
;                       Better error handling.  Include roll if available.
;                       Renamed to SUNGLOBE_GET_EPHEM.  Make multimission.
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_get_ephem, sstate
;
;  Get the ephemeris date, taking the test offset into account if applicable.
;
utc = anytim2utc(sstate.target_date, /external)
if sstate.test_offset ne 0 then utc.year = utc.year + round(sstate.test_offset)
utc = anytim2utc(utc, /ccsds)
;
;  If within the valid range, then get the ephemeris position.
;
errmsg = ''
coord = get_sunspice_lonlat(utc, sstate.spacecraft, system='carrington', $
                            /degrees, errmsg=errmsg)
if errmsg eq '' then begin
;
;  Update the distance information and redisplay.
;
    widget_control, sstate.wdist, set_value=coord[0] / wcs_au(unit='km')
    sunglobe_distance, sstate
;
;  Get the spacecraft roll information, if available.
;
    test = get_sunspice_roll(utc, sstate.spacecraft, /degrees, $
                             /post_conjunction, errmsg=errmsg)
    if (errmsg eq '') then roll = test else roll = 0.0
;
;  Update the orientation information.
;
    widget_control, sstate.wyaw, set_value=coord[1]
    widget_control, sstate.wpitch, set_value=coord[2]
    widget_control, sstate.wroll, set_value=roll
;
;  Otherwise, inform the user that the date is outside the valid range.
;
end else xack, 'Unable to get ephemeris information for ' + utc
;
;  Refresh the display.  This is done even if the values aren't changed,
;  to make sure the entire image is visible.
;
sunglobe_orient, sstate
;
return
end
