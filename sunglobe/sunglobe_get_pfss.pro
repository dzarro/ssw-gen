;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_GET_PFSS
;
; Purpose     :	Widget interface to read in PFSS magnetic field data
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	Widget interface to read in potential field source surface
;               (PFSS) magnetic field data into the SunGlobe program.  The
;               first thing that the program does is to use "SSW_PATH, /PFSS"
;               to make sure that the PFSS software is in the user's
;               path.  If the software is not found, then control is returned
;               to SunGlobe.  Otherwise, a simple widget is put up that allows
;               the user to select the number of magnetic field lines to
;               generate.
;
; Syntax      :	SUNGLOBE_GET_PFSS, SSTATE
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
; Calls       :	SUNGLOBE_PFSS__DEFINE, WHICH, SSW_PATH
;
; Side effects:	Adds the SolarSoft PFSS software tree to the path.
;
; History     :	Version 1, 08-Feb-2016, William Thompson, GSFC
;               Version 2, 12-Mar-2018, WTT, include uniform spacing option
;               Version 3, 20-Mar-2018, WTT, include polar exclusion zone
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_get_pfss_event, event
;
;  If the window close box has been selected, then kill the widget.
;
if (tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST') then $
  goto, destroy
;
;  Get the current state structure.
;
widget_control, event.top, get_uvalue=pspfss_state
;
widget_control, event.id, get_uvalue=uvalue
case uvalue of
;
;  Select between uniform and weighted line spacing.
;
    'FIELDTYPE': begin
        widget_control, (*pspfss_state).wftype, get_value=temp
        case temp of
            0: begin
                widget_control, (*pspfss_state).wspacing, sensitive=1
                widget_control, (*pspfss_state).wnlines, sensitive=0
            end
            1: begin
                widget_control, (*pspfss_state).wspacing, sensitive=0
                widget_control, (*pspfss_state).wnlines, sensitive=1
            end
        endcase
    end
;
;  Set the spacing for FIELDTYPE=5.
;
    'SPACING': begin
        spacing = 1 > event.value < 15
        widget_control, (*pspfss_state).wspacing, set_value=spacing
    end
;
;  Set the number of lines for FIELDTYPE=6.
;
    'NLINES': begin
        nlines = 100 > event.value < 3000
        widget_control, (*pspfss_state).wnlines, set_value=nlines
    end
;
;  Set the polar exclusion zone.
;
    'EXZONE': begin
        exzone = 0 > event.value < 30
        widget_control, (*pspfss_state).wexzone, set_value=exzone
    end
;
;  If the cancel button was pressed, then take no action.
;
    'CANCEL': goto, destroy
;
;  Extract the values and generate the PFSS extrapolation.
;
    'EXIT': begin
        widget_control, (*pspfss_state).wftype, get_value=fieldtype
        fieldtype = fieldtype + 5
        case fieldtype of
            5: begin
                widget_control, (*pspfss_state).wspacing, get_value=spacing
                nlines = 1 > spacing < 15
            end
            6: begin
                widget_control, (*pspfss_state).wnlines, get_value=nlines
                nlines = 100 > nlines < 3000
            end
        endcase
        widget_control, (*pspfss_state).wexzone, get_value=exzone
        exzone = 0 > exzone < 30
        (*pspfss_state).opfss = $
          obj_new('sunglobe_pfss', sstate=*(*pspfss_state).psstate, $
                  fieldtype=fieldtype, nlines=nlines, exzone=exzone, $
                  _extra=_extra)
destroy:
        widget_control, event.top, /destroy
        return
    end
;
    else:
endcase
;
widget_control, event.top, set_uvalue=pspfss_state
end

;------------------------------------------------------------------------------

pro sunglobe_get_pfss, sstate, group_leader=group_leader, modal=modal, $
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
dummy = widget_label(wtopbase, value='Read in PFSS magnetic model')
names = ['Uniform', 'Weighted by field strength']
wftype = cw_bgroup(wtopbase, names, /column, /exclusive, /frame, $
                   label_left='Field type', uvalue='FIELDTYPE', $
                   set_value=1, /return_index)
wspacing = cw_field(wtopbase, title='Field line spacing:', /return_events, $
                    value=10, uvalue='SPACING', /float)
wnlines = cw_field(wtopbase, title='Target number of lines:', /return_events, $
                 value=300, uvalue='NLINES', /integer)
wexzone = cw_field(wtopbase, title='Polar exclusion zone:', /return_events, $
                 value=0.0, uvalue='EXZONE', /float)
;
wbuttonbase = widget_base(wtopbase, /row)
dummy = widget_button(wbuttonbase, value='Cancel', uvalue='CANCEL')
dummy = widget_button(wbuttonbase, value='Apply', uvalue='EXIT')
;
;  Realize the widget hierarchy.
;
widget_control, wtopbase, /realize
widget_control, wspacing, sensitive=0
;
;  Define the state structure, and store it in the top base.
;
pspfss_state = ptr_new({wtopbase: wtopbase, $
                        wftype: wftype, $
                        wspacing: wspacing, $
                        wnlines: wnlines, $
                        wexzone: wexzone, $
                        psstate: ptr_new(sstate), $
                        opfss: obj_new()})
widget_control, wtopbase, set_uvalue=pspfss_state
;
;  Start the whole thing going.
;
xmanager, 'sunglobe_get_pfss', wtopbase
;
;  If a valid graphics object was created, then replace the old graphics object
;  with the new one.
;
if obj_valid((*pspfss_state).opfss) then begin
    if obj_valid(sstate.opfss) then begin
        sstate.omodelrotate->remove, sstate.opfss
        obj_destroy, sstate.opfss
    endif
    sstate.opfss = (*pspfss_state).opfss
    sstate.omodelrotate->add, sstate.opfss
endif
;
end
