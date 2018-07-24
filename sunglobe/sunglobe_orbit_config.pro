;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_ORBIT_CONFIG
;
; Purpose     :	Widget to configure generic field-of-view in SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning, Orbit
;
; Explanation : This routine brings up a widget to allow the user to control
;               the parameters defining the orbital trace.  The parameters
;               consist of the number of time steps before and after the target
;               time, the time difference between steps, and the units.
;
; Syntax      :	SUNGLOBE_ORBIT_CONFIG, oOrbit
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	oOrbit  = Graphics object containing the description of the
;                         orbital trace.
;
; Keywords    :	GROUP_LEADER = The widget ID of the group leader.
;
;               MODAL   = Run as a modal widget.
;
; Calls       :	SUNGLOBE_ORBIT__DEFINE
;
; History     :	Version 1, 2-Sep-2016, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;

;------------------------------------------------------------------------------

pro sunglobe_orbit_config_event, event
;
;  If the window close box has been selected, then kill the widget.
;
if (tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST') then $
  goto, destroy
;
;  Get the current state structure.
;
widget_control, event.top, get_uvalue=psorbit_state
;
widget_control, event.id, get_uvalue=uvalue
case uvalue of
    'NTIMES': begin
        ntimes = abs(event.value) > 1
        widget_control, (*psorbit_state).wntimes, set_value=ntimes
    end
    'TIMESTEP': begin
        timestep = abs(event.value)
        if timestep eq 0 then timestep = 1.0
        widget_control, (*psorbit_state).wtimestep, set_value=timestep
    end
;
;  If the cancel button was pressed, then take no action.
;
    'CANCEL': begin
        text = 'Are you sure you want to cancel this selection?'
        if xanswer(text) then goto, destroy
    end
;
    'EXIT': begin
        widget_control, (*psorbit_state).wntimes, get_value=ntimes
        ntimes = abs(ntimes) > 1
;
        widget_control, (*psorbit_state).wtimestep, get_value=timestep
        timestep = abs(timestep)
        if timestep eq 0 then timestep = 1.0
;
        widget_control, (*psorbit_state).wtimetype, get_value=itime
        names = ['Days', 'Hours', 'Minutes']
        timetype = names[itime]
;
        (*psorbit_state).oorbit = obj_new('sunglobe_orbit', $
                                      sstate=*(*psorbit_state).psstate, $
                                      ntimes=ntimes, timestep=timestep, $
                                      timetype=timetype)
destroy:
        widget_control, event.top, /destroy
        return
    end
;
    else:
endcase
;
widget_control, event.top, set_uvalue=psorbit_state
end

;------------------------------------------------------------------------------

pro sunglobe_orbit_config, sstate, group_leader=group_leader, modal=modal, $
                           _extra=_extra
;
;  Get the current orbit trace parameters.
;
sstate.oorbit->getproperty, ntimes=ntimes
sstate.oorbit->getproperty, timestep=timestep
sstate.oorbit->getproperty, timetype=timetype
;
;  Set up the top base as a column widget.
;
wtopbase = widget_base(/column, group_leader=group_leader, modal=modal, $
                      _extra=_extra)
dummy = widget_label(wtopbase, value='Configure orbit trace')
wntimes = cw_field(wtopbase, title='Number of before/after time steps: ', $
                   value=ntimes, uvalue='NTIMES', /return_events, /integer)
wtimestep = cw_field(wtopbase, title='Step size: ', value=timestep, $
                     uvalue='TIMESTEP', /return_events, /floating)
;
names = ['Days', 'Hours', 'Minutes']
index = where(timetype eq names)
wtimetype = cw_bgroup(wtopbase, names, row=1, /exclusive, set_value=index, $
                      label_left='Units: ', /return_name, uvalue='TIMETYPE')
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
psorbit_state = ptr_new({wtopbase: wtopbase, $
                         wntimes: wntimes, $
                         wtimestep: wtimestep, $
                         wtimetype: wtimetype, $
                         psstate: ptr_new(sstate), $
                         oorbit: obj_new()})
widget_control, wtopbase, set_uvalue=psorbit_state
;
;  Start the whole thing going.
;
xmanager, 'sunglobe_orbit_config', wtopbase
;
;  If a valid graphics object was created, then replace the old graphics object
;  with the new one.
;
if obj_valid((*psorbit_state).oorbit) then begin
    if obj_valid(sstate.oorbit) then begin
        sstate.omodelrotate->remove, sstate.oorbit
        obj_destroy, sstate.oorbit
    endif
    sstate.oorbit = (*psorbit_state).oorbit
    sstate.omodelrotate->add, sstate.oorbit
endif
;
end
