;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_CHANGE_DATE
;
; Purpose     :	Called from SUNGLOBE_EVENT to apply target date change
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This routine is called from several points in SUNGLOBE_EVENT to
;               apply the effects of a change in the target date.
;
; Syntax      :	SUNGLOBE_CHANGE_DATE, SSTATE
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	SSTATE  = Widget top-level state structure
;
; Calls       :	SUNGLOBE_DISPLAY, SUNGLOBE_GET_EPHEM,
;               SUNGLOBE_PFSS__DEFINE, SUNGLOBE_CONNECT__DEFINE
;
; History     :	Version 1, 15-Jan-2016, William Thompson, GSFC
;               Version 2, 08-Feb-2016, WTT, rotate PFSS
;               Version 3, 4-Aug-2016, WTT, call SUNGLOBE_GET_EPHEM
;               Version 4, 2-Sep-2016, WTT, update orbit trace
;               Version 5, 18-Nov-2016, WTT, apply SSTATE.HIDEORBIT
;                                            check if SunSPICE is loaded
;               Version 6, 05-Mar-2018, WTT, Rebuild magnetic connection point
;               Version 7, 01-Apr-2019, WTT, update active region IDs
;               Version 8, 10-Apr-2019, WTT, diff. rot. Conn. Tool image
;               Version 9, 18-Aug-2021, WTT, diff. rot. FOV paint image
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_change_date, sstate
;
;  Recalculate the differential rotation for all the images.
;
widget_control, /hourglass
for i=0,sstate.nmapped-1 do sunglobe_diff_rot, sstate, i
if ptr_valid(sstate.pconnfile) then sunglobe_diff_rot, sstate, /connfile
if ptr_valid(sstate.pfovpaint) then sunglobe_diff_rot, sstate, /fovpaint
;
;  Also differentially rotate the magnetic field lines, if applicable.
;
if obj_valid(sstate.opfss) then sstate.opfss->diffrot, sstate.target_date
;
;  Recalculate magnetic connection point, if applicable.
;
if obj_valid(sstate.oconnect) then begin
    if sstate.hideconnect then sstate.oconnect->setproperty, recalculate=1 $
      else begin
        sstate.oconnect->getproperty, basis=basis
        sstate.oconnect->getproperty, nlines=nlines
        sstate.oconnect->getproperty, gausswidth=gausswidth
        sstate.oconnect->getproperty, windspeed=windspeed
        sstate.omodelrotate->remove, sstate.oconnect
        obj_destroy, sstate.oconnect
        sstate.oconnect = obj_new('sunglobe_connect', sstate=sstate, $
                                  basis=basis, nlines=nlines, $
                                  gausswidth=gausswidth, windspeed=windspeed)
        sstate.omodelrotate->add, sstate.oconnect
        sstate.oconnect->setproperty, hide=sstate.hideconnect
    endelse
endif
;
;  Update the orbit trace.
;
build_orbit = obj_valid(sstate.oorbit)
if build_orbit then $
  if sstate.target_date eq sstate.oorbit.date then build_orbit = 0
if build_orbit then begin        
    sstate.oorbit->getproperty, ntimes=ntimes
    sstate.oorbit->getproperty, timestep=timestep
    sstate.oorbit->getproperty, timetype=timetype
    sstate.omodelrotate->remove, sstate.oorbit
    obj_destroy, sstate.oorbit
    sstate.oorbit = obj_new('sunglobe_orbit', sstate=sstate, ntimes=ntimes, $
                            timestep=timestep, timetype=timetype)
    sstate.omodelrotate->add, sstate.oorbit
    sstate.oorbit->setproperty, hide=sstate.hideorbit
endif
;
;  Update the NOAA active region IDs.
;
if obj_valid(sstate.onar) then $
  sstate.onar->setproperty, target_date=sstate.target_date
;
;  Update the display.
;
sunglobe_display, sstate
widget_control, hourglass=0
;
;  If the ephemeris button is selected, then update the ephemeris information.
;
widget_control, sstate.wselephem, get_value=selephem
if selephem then begin
    widget_control, sstate.wlockorient, get_value=lockorient
    if not lockorient then begin
        which, 'load_sunspice', /quiet, outfile=temp
        if temp ne '' then sunglobe_get_ephem, sstate
    endif
endif
;
end
