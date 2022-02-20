;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_SPICE_CONFIG_FOV
;
; Purpose     :	Widget to configure SPICE field-of-view in SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning, SPICE
;
; Explanation :	This routine brings up a widget to allow the user to control
;               the parameters defining a SPICE raster.  The raster parameters
;               consist of the slit number, number of raster steps, the size of
;               a raster step, and any offset of the middle of the raster from
;               the spacecraft boresight.  At the moment there are no checks
;               that the parameters are physically compatible with the SPICE
;               instrument.
;
; Syntax      :	SUNGLOBE_SPICE_CONFIG_FOV, OSPICE
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	OSPICE  = Graphics object containing the description of the
;                         SPICE field-of-view.
;
; Keywords    :	GROUP_LEADER = The widget ID of the group leader.
;
;               MODAL   = Run as a modal widget.
;
; Calls       :	SUNGLOBE_SPICE_FOV__DEFINE
;
; History     :	Version 1, 12-Jan-2016, William Thompson, GSFC
;               Version 2, 16-Aug-2021, WTT, corrected height typo
;
; Contact     :	WTHOMPSON
;-
;

;------------------------------------------------------------------------------

pro sunglobe_spice_config_fov_event, event
;
;  If the window close box has been selected, then kill the widget.
;
if (tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST') then $
  goto, destroy
;
;  Get the current state structure.
;
widget_control, event.top, get_uvalue=sstate, /no_copy
;
widget_control, event.id, get_uvalue=uvalue
case uvalue of
    'NSTEPS': begin
        nsteps = event.value > 1
        widget_control, sstate.wnsteps, set_value=nsteps
    end
    'STEPSIZE': begin
        stepsize = event.value
        widget_control, sstate.wstepsize, set_value=stepsize
    end
    'MIDPOS': begin
        midpos = event.value
        widget_control, sstate.wmidpos, set_value=midpos
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
        widget_control, sstate.wslitnum, get_value=slitnum
        sstate.ospice->setproperty, slitnum=slitnum
        widget_control, sstate.wnsteps, get_value=nsteps
        sstate.ospice->setproperty, nsteps=abs(nsteps)
        widget_control, sstate.wstepsize, get_value=stepsize
        sstate.ospice->setproperty, stepsize=abs(stepsize)
        widget_control, sstate.wmidpos, get_value=midpos
        sstate.ospice->setproperty, midpos=midpos
destroy:
        widget_control, event.top, /destroy
        return
    end
;
    else:
endcase
;
;  Derive the slit width and height, and the size of the total field-of-view.
;
widget_control, sstate.wslitnum, get_value=slitnum
widget_control, sstate.wnsteps, get_value=nsteps
widget_control, sstate.wstepsize, get_value=stepsize
widget_control, sstate.wmidpos, get_value=midpos
;
height = 11.0
case slitnum of
    1: width = 4.0
    2: width = 6.0
    3: begin
        width = 30.0
        height = 14.0
    end
    else: width = 2.0           ;Slit #0 is the default
endcase
height = string(height, format='(F5.2)')
width = string((((nsteps-1)>0)*abs(stepsize) + width) / 60., format='(F5.2)')
widget_control, sstate.wslitwidth, set_value=width
widget_control, sstate.wslitheight, set_value=height
;
widget_control, event.top, set_uvalue=sstate, /no_copy
end

;------------------------------------------------------------------------------

pro sunglobe_spice_config_fov, ospice, group_leader=group_leader, $
                               modal=modal, _extra=_extra
;
;  Get the current raster parameters.
;
ospice->getproperty, slitnum=slitnum
ospice->getproperty, nsteps=nsteps
ospice->getproperty, stepsize=stepsize
ospice->getproperty, midpos=midpos
;
;  Set up the top base as a column widget.
;
wtopbase = widget_base(/column, group_leader=group_leader, modal=modal, $
                      _extra=_extra)
dummy = widget_label(wtopbase, value='Configure SPICE raster parameters')
;
wslitnum = cw_bgroup(wtopbase, ['2','4','6','30'], /row, $
                     label_left='Slit width:', /return_index, /exclusive, $
                     uvalue='SLITNUM', set_value=slitnum)
;
wnsteps   = cw_field(wtopbase, title='Number of steps:       ', $
                     value=nsteps, uvalue='NSTEPS', /RETURN_EVENTS, /INTEGER)
wstepsize = cw_field(wtopbase, title='Step size (arcsec):    ', $
                     value=stepsize, uvalue='STEPSIZE', /RETURN_EVENTS, $
                     /FLOATING)
wmidpos   = cw_field(wtopbase, title='Center offset (arcsec):', $
                     value=midpos, uvalue='MIDPOS', /RETURN_EVENTS, /FLOATING)
;
;  Derive the slit width and height, and the size of the total field-of-view.
;
height = 11.0
case slitnum of
    1: width = 4.0
    2: width = 6.0
    3: begin
        width = 30.0
        height = 14.0
    end
    else: width = 2.0           ;Slit #0 is the default
endcase
height = string(height, format='(F5.2)')
width = string((((nsteps-1)>0)*abs(stepsize) + width) / 60., format='(F5.2)')
;
wsizebase = widget_base(wtopbase, /row)
wslitwidth  = cw_field(wsizebase, title='Total FOV (arcmin): ', value=width, $
                       xsize=5, /noedit)
wslitheight = cw_field(wsizebase, title='x', value=height, xsize=5, /noedit)
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
sstate = {wtopbase: wtopbase, $
          wslitnum: wslitnum, $
          wnsteps: wnsteps, $
          wstepsize: wstepsize, $
          wmidpos: wmidpos, $
          wslitwidth: wslitwidth, $
          wslitheight: wslitheight, $
          ospice: ospice}
widget_control, wtopbase, set_uvalue=sstate, /no_copy
;
;  Start the whole thing going.
;
xmanager, 'sunglobe_spice_config_fov', wtopbase
;
end
