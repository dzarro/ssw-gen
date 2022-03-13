;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_CHANGE_SPACECRAFT
;
; Purpose     :	Called from SUNGLOBE_EVENT to apply spacecraft change
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This routine is called from SUNGLOBE_EVENT to change the
;               selected spacecraft.
;
; Syntax      :	SUNGLOBE_CHANGE_SPACECRAFT, SSTATE
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	SSTATE  = Widget top-level state structure
;
; Calls       :	SUNGLOBE_DISPLAY, SUNGLOBE_GET_EPHEM,
;               SUNGLOBE_PFSS__DEFINE, SUNGLOBE_CONNECT__DEFINE,
;               PARSE_SUNSPICE_NAME, XANSWER
;
; History     :	Version 1, 01-Apr-2019, William Thompson, GSFC
;               Version 2, 10-Apr-2019, WTT, check Connection Tool image
;               Version 3, 11-Apr-2019, WTT, ask before removing conn. image
;               Version 4, 24-Feb-2022, WTT, split EUI into EUV and Lya channels
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_change_spacecraft, sstate, group_leader=group_leader
;
spacecraft = sstate.spacecraft          ;Keep track of original value
pspacecraft = ptr_new(spacecraft)
sunglobe_select_spacecraft, pspacecraft, group_leader=group_leader
sstate.spacecraft = *pspacecraft
;
widget_control, /hourglass
;
;  The FOV configuration, paint, and on/off buttons depend on which spacecraft
;  was selected.
;
if sstate.spacecraft eq '-144' then begin ;Solar Orbiter
    widget_control, sstate.wfovconfig[0], set_uvalue='CONFIGSPICE', $
                    set_value='Configure SPICE field-of-view'
    widget_control, sstate.wfovconfig[1], set_uvalue='CONFIGEUIEUV', $
                    set_value='Configure EUI/HRI/EUV field-of-view', sensitive=1
    widget_control, sstate.wfovconfig[2], set_uvalue='CONFIGEUILYA', $
                    set_value='Configure EUI/HRI/Lya field-of-view', sensitive=1
    widget_control, sstate.wfovconfig[3], set_uvalue='CONFIGPHI', $
                    set_value='Configure PHI field-of-view', sensitive=1
;
    widget_control, sstate.wfovpaint[0], set_uvalue='PAINTSPICE', $
                    set_value='Paint SPICE field-of-view'
    widget_control, sstate.wfovpaint[1], set_uvalue='PAINTEUIEUV', $
                    set_value='Paint EUI/HRI/EUV field-of-view', sensitive=1
    widget_control, sstate.wfovpaint[2], set_uvalue='PAINTEUILYA', $
                    set_value='Paint EUI/HRI/Lya field-of-view', sensitive=1
    widget_control, sstate.wfovpaint[3], set_uvalue='PAINTPHI', $
                    set_value='Paint PHI field-of-view', sensitive=1
;
    widget_control, sstate.wfovonoff[0], set_uvalue='SPICEFOV', $
                    set_value='SPICE field-of-view on/off'
    widget_control, sstate.wfovonoff[1], set_uvalue='EUIEUVFOV', $
                    set_value='EUI/HRI/EUV field-of-view on/off', sensitive=1
    widget_control, sstate.wfovonoff[2], set_uvalue='EUILYAFOV', $
                    set_value='EUI/HRI/Lya field-of-view on/off', sensitive=1
    widget_control, sstate.wfovonoff[3], set_uvalue='PHIFOV', $
                    set_value='PHI field-of-view on/off', sensitive=1
;
;  If Solar Orbiter was selected, then hide the generic FOV.
;
    sstate.hidegen = 1
    sstate.ogen->setproperty, hide=sstate.hidegen

end else begin
    widget_control, sstate.wfovconfig[0], set_uvalue='CONFIGGEN', $
                    set_value='Configure field-of-view'
    widget_control, sstate.wfovpaint[0], set_uvalue='PAINTGEN', $
                    set_value='Paint field-of-view'
    widget_control, sstate.wfovonoff[0], set_uvalue='GENFOV', $
                    set_value='Field-of-view on/off'
    for i=1,3 do begin
        widget_control, sstate.wfovconfig[i], set_value='',set_uvalue='', $
                        sensitive=0
        widget_control, sstate.wfovpaint[i], set_value='',set_uvalue='', $
                        sensitive=0
        widget_control, sstate.wfovonoff[i], set_value='', set_uvalue='', $
                        sensitive=0
    endfor
;
;  If Solar Orbiter wasn't selected, then hide its FOVs.
;
        sstate.hidespice = 1
        sstate.ospice->setproperty, hide=sstate.hidespice
        sstate.hideeuieuv = 1
        sstate.oeuieuv->setproperty, hide=sstate.hideeuieuv
        sstate.hideeuilya = 1
        sstate.oeuilya->setproperty, hide=sstate.hideeuilya
        sstate.hidephi = 1
        sstate.ophi->setproperty, hide=sstate.hidephi
endelse
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
  if sstate.spacecraft eq spacecraft then build_orbit = 0
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
;  If a Magnetic Connectivity Tool image was read in, agreed with the old
;  viewpoint, but not with the new viewpoint, then ask if the user wants to
;  delete that image.
;
if ptr_valid(sstate.pconnfile) then begin
    connsctext = (*sstate.pconnfile).spacecraft
    connsc = parse_sunspice_name(connsctext)
    if (connsc eq spacecraft) and (connsc ne sstate.spacecraft) then begin
        question = 'Remove magnetic connection image for ' + connsctext + '?'
        if xanswer(question) then begin
            obj_destroy, (*sstate.pconnfile).omap_alpha
            ptr_free, sstate.pconnfile
            sstate.hideconnfile = 0
        endif
    endif
endif
;
;  Update the display.
;
sunglobe_display, sstate
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
widget_control, hourglass=0
end
