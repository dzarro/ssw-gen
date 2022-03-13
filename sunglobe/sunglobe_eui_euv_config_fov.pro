;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_EUI_EUV_CONFIG_FOV
;
; Purpose     :	Widget to configure EUI/HRI/EUV field-of-view in SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning, EUI
;
; Explanation : This routine brings up a widget to allow the user to control
;               the parameters defining a EUI/HRI/EUV field-of-view.  The
;               parameters consist of the size and center position (relative to
;               the spacecraft boresight) in each dimension, in arc seconds.
;               At the moment there are no checks that the parameters are
;               physically compatible with the EUI instrument.
;
; Syntax      :	SUNGLOBE_EUI_EUV_CONFIG_FOV, OEUIEUV
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	OEUIEUV  = Graphics object containing the description of the
;                          EUI field-of-view.
;
; Keywords    :	GROUP_LEADER = The widget ID of the group leader.
;
;               MODAL   = Run as a modal widget.
;
; Calls       :	SUNGLOBE_EUI_FOV__DEFINE
;
; History     :	Version 1, 20-Jan-2016, William Thompson, GSFC
;               Version 2, 24-Feb-2022, WTT, split EUI into EUV and LYA channels
;
; Contact     :	WTHOMPSON
;-
;

;------------------------------------------------------------------------------

pro sunglobe_eui_euv_config_fov_event, event
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
    'XSIZE': begin
        xsize = event.value > 1
        widget_control, sstate.wxsize, set_value=xsize
    end
    'YSIZE': begin
        ysize = event.value > 1
        widget_control, sstate.wysize, set_value=ysize
    end
    'XCEN': begin
        xcen = event.value
        widget_control, sstate.wxcen, set_value=xcen
    end
    'YCEN': begin
        ycen = event.value
        widget_control, sstate.wycen, set_value=ycen
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
        widget_control, sstate.wxsize, get_value=xsize
        sstate.oeuieuv->setproperty, xsize=xsize
        widget_control, sstate.wysize, get_value=ysize
        sstate.oeuieuv->setproperty, ysize=abs(ysize)
        widget_control, sstate.wxcen, get_value=xcen
        sstate.oeuieuv->setproperty, xcen=abs(xcen)
        widget_control, sstate.wycen, get_value=ycen
        sstate.oeuieuv->setproperty, ycen=ycen
destroy:
        widget_control, event.top, /destroy
        return
    end
;
    else:
endcase
;
widget_control, event.top, set_uvalue=sstate, /no_copy
end

;------------------------------------------------------------------------------

pro sunglobe_eui_euv_config_fov, oeuieuv, group_leader=group_leader, modal=modal, $
                             _extra=_extra
;
;  Get the current raster parameters.
;
oeuieuv->getproperty, xsize=xsize
oeuieuv->getproperty, ysize=ysize
oeuieuv->getproperty, xcen=xcen
oeuieuv->getproperty, ycen=ycen
;
;  Set up the top base as a column widget.
;
wtopbase = widget_base(/column, group_leader=group_leader, modal=modal, $
                      _extra=_extra)
dummy = widget_label(wtopbase, value='Configure EUI/HRI/EUV field-of-view')
;
wxsize = cw_field(wtopbase, title='X size (arcsec):  ', $
                  value=xsize, uvalue='XSIZE', /return_events, /floating)
wysize = cw_field(wtopbase, title='Y size (arcsec):  ', $
                  value=ysize, uvalue='YSIZE', /return_events, /floating)
wxcen  = cw_field(wtopbase, title='X offset (arcsec):', $
                  value=xcen, uvalue='XCEN', /return_events, /floating)
wycen  = cw_field(wtopbase, title='Y offset (arcsec):', $
                  value=ycen, uvalue='YCEN', /return_events, /floating)
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
          wxsize: wxsize, $
          wysize: wysize, $
          wxcen: wxcen, $
          wycen: wycen, $
          oeuieuv: oeuieuv}
widget_control, wtopbase, set_uvalue=sstate, /no_copy
;
;  Start the whole thing going.
;
xmanager, 'sunglobe_eui_euv_config_fov', wtopbase
;
end
