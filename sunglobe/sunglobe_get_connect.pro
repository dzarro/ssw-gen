;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_GET_CONNECT
;
; Purpose     :	Widget interface to estimate magnetic connection point
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation : Widget interface to incorporate the magnetic connection point
;               based on PFSS magnetic field data into the SunGlobe program.
;               The first thing that the program does is to use
;               "SSW_PATH,/PFSS" to make sure that the PFSS software is in the
;               user's path.  If the software is not found, then control is
;               returned to SunGlobe.  Otherwise, a simple widget is put up
;               that allows the user to input the parameters for the
;               calculation.
;
; Syntax      :	SUNGLOBE_GET_CONNECT, SSTATE
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	SSTATE  = SunGlobe widget top-level state structure.
;
; Outputs     :	The program returns the graphics model describing the magnetic
;               field.
;
; Keywords    :	GROUP_LEADER = The widget ID of the group leader.
;
;               MODAL   = Run as a modal widget.
;
; Calls       :	SUNGLOBE_CONNECT__DEFINE, WHICH, SSW_PATH
;
; Side effects:	Adds the SolarSoft PFSS software tree to the path.
;
; History     :	Version 1, 05-Mar-2018, William Thompson, GSFC
;               Version 2, 25-Mar-2020, WTT, added solar wind speed adjustment
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_get_connect_event, event
;
;  If the window close box has been selected, then kill the widget.
;
if (tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST') then $
  goto, destroy
;
;  Get the current state structure.
;
widget_control, event.top, get_uvalue=psconnect_state
;
widget_control, event.id, get_uvalue=uvalue
case uvalue of
    'NLINES': begin
        nlines = 10 > event.value < 1000
        widget_control, (*psconnect_state).wnlines, set_value=nlines
    end
    'GAUSSWIDTH': begin
        gausswidth = 1 > abs(event.value) < 30
        widget_control, (*psconnect_state).wgausswidth, set_value=gausswidth
    end
    'WINDSPEED': begin
        windspeed = 100 > abs(event.value) < 5000
        widget_control, (*psconnect_state).wwindspeed, set_value=windspeed
    end
;
;  If the cancel button was pressed, then take no action.
;
    'CANCEL': goto, destroy
;
    'EXIT': begin
        widget_control, /hourglass
        widget_control, (*psconnect_state).wbasis, get_value=basis
;
        widget_control, (*psconnect_state).wnlines, get_value=nlines
        nlines = 10 > nlines < 1000
;
        widget_control, (*psconnect_state).wgausswidth, get_value=gausswidth
        gausswidth = 1 > abs(gausswidth) < 30
;
        widget_control, (*psconnect_state).wwindspeed, get_value=windspeed
        windspeed = 100 > abs(windspeed) < 5000
;
        widget_control, (*psconnect_state).wadjust, get_value=adjust
;
        (*psconnect_state).oconnect = $
          obj_new('sunglobe_connect', sstate=*(*psconnect_state).psstate, $
                  nlines=nlines, gausswidth=gausswidth, windspeed=windspeed, $
                  basis=basis, adjust=adjust, _extra=_extra)
destroy:
        widget_control, event.top, /destroy
        widget_control, hourglass=0
        return
    end
;
    else:
endcase
;
widget_control, event.top, set_uvalue=psconnect_state
end

;------------------------------------------------------------------------------

pro sunglobe_get_connect, sstate, group_leader=group_leader, modal=modal, $
                       _extra=_extra
;
;  Make sure that the PFSS software tree is loaded.
;
which, 'pfss_time2file', outfile=temp
if temp eq '' then begin
    ssw_path, /pfss
    which, 'pfss_time2file', outfile=temp
    if temp eq '' then begin
        xack, '$SSW/packages/pfss not found'
        return
    endif
endif
;
wtopbase = widget_base(/column, group_leader=group_leader, modal=modal, $
                       _extra=_extra)
;
dummy = widget_label(wtopbase, value='Estimate magnetic connection point')
names = ['Ephemeris', 'Current orientation']
wbasis = cw_bgroup(wtopbase, names, /column, /exclusive, /frame, $
                   label_top='Basis for observation point', uvalue='BASIS', $
                   set_value=0, /return_index)
wnlines = cw_field(wtopbase, title='Target number of lines:', /return_events, $
                   value=50, uvalue='NLINES', /integer)
wgausswidth = cw_field(wtopbase, /return_events, value=5.0, /floating, $
                       title='Gaussian width at source surface (degrees)', $
                       uvalue='GAUSSWIDTH')
wwindspeed = cw_field(wtopbase, title='Wind speed (km/s)', /return_events, $
                      value=450.0, uvalue='WINDSPEED', /floating)
;
wadjust = cw_bgroup(wtopbase, 'Adjust for solar wind propagation time', $
                    /column, /nonexclusive, uvalue='ADJUST')
;
wbuttonbase = widget_base(wtopbase, /row)
dummy = widget_button(wbuttonbase, value='Cancel', uvalue='CANCEL')
dummy = widget_button(wbuttonbase, value='Apply', uvalue='EXIT')
;
;  Realize the widget hierarchy.
;
widget_control, wtopbase, /realize
;
;  Define the state structure, and store it in the top base.
;
psconnect_state = ptr_new({wtopbase: wtopbase, $
                           wbasis: wbasis, $
                           wnlines: wnlines, $
                           wgausswidth: wgausswidth, $
                           wwindspeed: wwindspeed, $
                           wadjust: wadjust, $
                           psstate: ptr_new(sstate), $
                           oconnect: obj_new()})
widget_control, wtopbase, set_uvalue=psconnect_state
;
;  Start the whole thing going.
;
xmanager, 'sunglobe_get_connect', wtopbase
;
;  If a valid graphics object was created, then replace the old graphics object
;  with the new one.
;
if obj_valid((*psconnect_state).oconnect) then begin
    if obj_valid(sstate.oconnect) then begin
        sstate.omodelrotate->remove, sstate.oconnect
        obj_destroy, sstate.oconnect
    endif
    sstate.oconnect = (*psconnect_state).oconnect
    sstate.omodelrotate->add, sstate.oconnect
endif
;
end
