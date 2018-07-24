;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_CONVERT
;
; Purpose     :	Widget to show HPC, Carrington coordinates in SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning, generic
;
; Explanation : This routine brings up a widget to display the pointing
;               converted from spacecraft X and Y, which depend on the
;               spacecraft roll, into Helioprojective Cartesian (HPC) X and Y,
;               which are independent of roll.  The HPC values can also be
;               edited and passed back to the SunGlobe widget.  If the point is
;               on the disk, then the Carrington longitude and latitude are
;               also calculated, and can also be edited.
;
;               There's also an option to force all pointing to stay
;               within the limb.
;
;               The Export button writes a JSON file containing the pointing
;               values to the current directory, and exits the program.
;
;               If SUNGLOBE was called from another program, then the pointing
;               values can be sent to that program, which also exits the
;               convert program.
;
; Syntax      :	SUNGLOBE_CONVERT, sState
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	sState = SunGlobe state structure.
;
; Keywords    :	GROUP_LEADER = The widget ID of the group leader.
;
;               MODAL   = Run as a modal widget.
;
; Prev. Hist. :	Earlier name was SUNGLOBE_HPC.
;
; History     :	Version 1, 30-Aug-2016, William Thompson, GSFC
;               Version 2, 01-Aug-2017, WTT, greatly expanded functionality
;               Version 3, 02-Aug-2017, WTT, improved roll calculation
;
; Contact     :	WTHOMPSON
;-
;

;------------------------------------------------------------------------------

pro sunglobe_convert_event, event
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
;
;  Handle events in the S/C section.
;
    'XYSC': begin
check_pointing:
        widget_control, sstate.wxsc, get_value=xsc
        widget_control, sstate.wysc, get_value=ysc
        widget_control, sstate.mstate.wroll, get_value=roll
;
;  Calculate the HPC coordinates.
;
        dtor = !dpi / 180.d0
        roll = roll * dtor
        croll = cos(roll)
        sroll = sin(roll)
;
        conv = 3600.d0 / dtor
        xx = xsc / conv
        yy = ysc / conv
        sinx = sin(xx)
        cosy = cos(yy)
        siny = sin(yy)
;
        xx = cosy * sinx
        yy = siny
        xp =  xx * croll + yy * sroll
        yp = -xx * sroll + yy * croll
;
        yhpc = asin(yp)
        xhpc = asin(xp / cos(yhpc))
        xhpc = conv * xhpc
        yhpc = conv * yhpc
;
;  Calculate Carrington coordinates.
;
        widget_control, sstate.mstate.wdist, get_value=dsun
        widget_control, sstate.mstate.wpitch, get_value=b0
        widget_control, sstate.mstate.wyaw, get_value=l0
        xhpc0 = xhpc
        yhpc0 = yhpc
        sunglobe_hpc2carr, dsun, l0, b0, xhpc, yhpc, crln, crlt, $
                           limb=sstate.limb
        if (xhpc ne xhpc0) or (yhpc ne yhpc0) then begin
            xsc = xhpc * croll - yhpc * sroll
            ysc = xhpc * sroll + yhpc * croll
        endif
        sstate.carrmap = finite(crln) and finite(crlt)
;
;  Refresh the graphics window.
;
        widget_control, sstate.wxhpc, set_value=xhpc
        widget_control, sstate.wyhpc, set_value=yhpc
        widget_control, sstate.wxsc, set_value=xsc
        widget_control, sstate.wysc, set_value=ysc
        widget_control, sstate.wlon, set_value=crln
        widget_control, sstate.wlat, set_value=crlt
        widget_control, sstate.wcarrbase, map=sstate.carrmap
        widget_control, sstate.mstate.wxsc, set_value=xsc
        widget_control, sstate.mstate.wysc, set_value=ysc
        sunglobe_scpoint, sstate.mstate
    end
;
;  Handle events in the HPC section.
;
    'XYHPC': begin
        widget_control, sstate.wxhpc, get_value=xhpc
        widget_control, sstate.wyhpc, get_value=yhpc
        widget_control, sstate.mstate.wroll, get_value=roll
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
;  Calculate Carrington coordinates.
;
        widget_control, sstate.mstate.wdist, get_value=dsun
        widget_control, sstate.mstate.wpitch, get_value=b0
        widget_control, sstate.mstate.wyaw, get_value=l0
        sunglobe_hpc2carr, dsun, l0, b0, xhpc, yhpc, crln, crlt, $
                           limb=sstate.limb
        sstate.carrmap = finite(crln) and finite(crlt)
;
;  Refresh the graphics window.
;
        widget_control, sstate.wxhpc, set_value=xhpc
        widget_control, sstate.wyhpc, set_value=yhpc
        widget_control, sstate.wxsc, set_value=xsc
        widget_control, sstate.wysc, set_value=ysc
        widget_control, sstate.wlon, set_value=crln
        widget_control, sstate.wlat, set_value=crlt
        widget_control, sstate.wcarrbase, map=sstate.carrmap
        widget_control, sstate.mstate.wxsc, set_value=xsc
        widget_control, sstate.mstate.wysc, set_value=ysc
        sunglobe_scpoint, sstate.mstate
    end
;
;  Handle events in the Carrington section
;
    'CARR': begin
        widget_control, sstate.wlon, get_value=crln
        widget_control, sstate.wlat, get_value=crlt
        widget_control, sstate.mstate.wroll, get_value=roll
        widget_control, sstate.mstate.wdist, get_value=dsun
        widget_control, sstate.mstate.wpitch, get_value=b0
        widget_control, sstate.mstate.wyaw, get_value=l0
;
;  Convert from Carrington to HPC.
;
        dtor = !dpi / 180.d0
        roll = dtor * roll
        dsun = dsun * wcs_au() / wcs_rsun()
        b0 = dtor * b0
        lon = dtor * (crln - l0)
        lat = dtor * crlt
;
        cosb = cos(b0)
        sinb = sin(b0)
;
        cosx = cos(lon)
        sinx = sin(lon)
        cosy = cos(lat)
        siny = sin(lat)
;
        x = cosy * sinx
        y = siny*cosb - cosy*cosx*sinb
        z = siny*sinb + cosy*cosx*cosb
;
        zeta = dsun - z
        distance = sqrt(x^2 + y^2 + zeta^2)
        xhpc = atan(x, zeta)
        yhpc = asin(y / distance)
;
;  Convert from HPC to SC.
;
        croll = cos(roll)
        sroll = sin(roll)
;
        sinx = sin(xhpc)
        cosy = cos(yhpc)
        siny = sin(yhpc)
;
        xx = cosy * sinx
        yy = siny
        xp = xx * croll - yy * sroll
        yp = xx * sroll + yy * croll
;
        ysc = asin(yp)
        xsc = asin(xp / cos(ysc))
;
;  Convert to arcseconds.
;
        conv = 3600.d0 / dtor
        xhpc = conv * xhpc
        yhpc = conv * yhpc
        xsc = conv * xsc
        ysc = conv * ysc
;
;  Refresh the graphics window.
;
        widget_control, sstate.wxhpc, set_value=xhpc
        widget_control, sstate.wyhpc, set_value=yhpc
        widget_control, sstate.wxsc, set_value=xsc
        widget_control, sstate.wysc, set_value=ysc
        widget_control, sstate.wlon, set_value=crln
        widget_control, sstate.wlat, set_value=crlt
        widget_control, sstate.mstate.wxsc, set_value=xsc
        widget_control, sstate.mstate.wysc, set_value=ysc
        sunglobe_scpoint, sstate.mstate
    end
;
;  Export the pointing to a JSON file.
;
    'EXPORT': begin
        widget_control, sstate.mstate.wlockorient, get_value=lockorient
        if lockorient then begin
            text = ['Warning: Orientation lock is still in effect.', $
                    'Are you sure you want to export the pointing values?']
            export = xanswer(text)
        end else export = 1
        if export then begin
            widget_control, sstate.wxsc, get_value=xsc
            widget_control, sstate.wysc, get_value=ysc
            widget_control, sstate.mstate.wroll, get_value=roll
            widget_control, sstate.wxhpc, get_value=xhpc
            widget_control, sstate.wyhpc, get_value=yhpc
            if sstate.carrmap then begin
                widget_control, sstate.wlon, get_value=crln
                widget_control, sstate.wlat, get_value=crlt
            end else begin
                crln = !values.f_nan
                crlt = !values.f_nan
            endelse
            json = json_serialize({xsc: xsc, $
                                   ysc: ysc, $
                                   roll: roll, $
                                   xhpc: xhpc, $
                                   yhpc: yhpc, $
                                   ondisk: sstate.carrmap, $
                                   crln: crln, $
                                   crlt: crlt, $
                                   target_date: sstate.mstate.target_date})
;
            filename = xpickfile(group=event.top, filter='*.json', /editable, $
                                 default='sunglobe.json')
            if strmid(filename,strlen(filename)-5,5) ne '.json' then $
              filename = filename + '.json'
            dosave = 1
            if file_exist(filename) then begin
                text = ['File ' + filename + ' already exists.', $
                        'Do you want to overwrite it?']
                dosave = xanswer(text)
            endif
;
            if dosave then begin
                catch, error_status
                if error_status ne 0 then begin
                    catch, /cancel
                    xack, 'Unable to write file ' + filename
                    goto, json_cleanup
                endif
                openw, unit, filename, /get_lun
                printf, unit, json
                free_lun, unit
            end else xack, 'JSON file not created', group=event.top
;
;  Using this option closes the widget.
;
json_cleanup:
            goto, destroy
        endif
    end        
;
;  Send the pointing back to the calling program.
;
    'SENDPOINT': begin
        if widget_info(sstate.mstate.returnid, /valid_id) then begin
            widget_control, sstate.mstate.wlockorient, get_value=lockorient
            if lockorient then begin
                text = ['Warning: Orientation lock is still in effect.', $
                        'Are you sure you want to send the pointing values?']
                sendpoint = xanswer(text)
            end else sendpoint = 1
            if sendpoint then begin
                widget_control, sstate.wxsc, get_value=xsc
                widget_control, sstate.wysc, get_value=ysc
                widget_control, sstate.mstate.wroll, get_value=roll
                widget_control, sstate.wxhpc, get_value=xhpc
                widget_control, sstate.wyhpc, get_value=yhpc
                if sstate.carrmap then begin
                    widget_control, sstate.wlon, get_value=crln
                    widget_control, sstate.wlat, get_value=crlt
                end else begin
                    crln = !values.f_nan
                    crlt = !values.f_nan
                endelse
                send_event = {id: 0L, top: 0L, handler: 0L, $
                              xsc: xsc, $
                              ysc: ysc, $
                              roll: roll, $
                              xhpc: xhpc, $
                              yhpc: yhpc, $
                              ondisk: sstate.carrmap, $
                              crln: crln, $
                              crlt: crlt, $
                              target_date: sstate.mstate.target_date}
                widget_control, sstate.mstate.returnid, send_event=send_event, $
                                set_uvalue='SUNGLOBE_POINTING'
            endif
;
;  Using this option closes the widget.
;
            goto, destroy
        end else begin
            xack, 'The calling program is no longer active'
            widget_control, sstate.wsendpnt, sensitive=0
        endelse
    end
;
;  Toggle whether keeping within the limb is turned on or off.
;
    'LIMB': begin
        sstate.limb = event.select
        if event.select then goto, check_pointing
    end
;
;  Exit the widget.
;
    'EXIT': begin
destroy:
        widget_control, event.top, /destroy
        return
    end
    else:
endcase
;
widget_control, event.top, set_uvalue=sstate, /no_copy
end

;------------------------------------------------------------------------------

pro sunglobe_convert, mstate, group_leader=group_leader, modal=modal, _extra=_extra
;
;  Get the boresight position from the widget, and the roll.
;
widget_control, mstate.wxsc, get_value=xsc
widget_control, mstate.wysc, get_value=ysc
widget_control, mstate.wroll, get_value=roll0
;
;  Calculate the HPC coordinates.
;
roll = roll0 * !dpi / 180.d0
croll = cos(roll)
sroll = sin(roll)
xhpc =  xsc * croll + ysc * sroll
yhpc = -xsc * sroll + ysc * croll
;
;  Set up the top base as a column widget.
;
wtopbase = widget_base(/column, group_leader=group_leader, modal=modal, $
                       _extra=_extra)
;
;  Set up a button menu.
;
wbuttonbase1 = widget_base(wtopbase, /row, /align_center, /nonexclusive)
dummy = widget_button(wbuttonbase1, value='Stay within limb', uvalue='LIMB')
;
wbuttonbase2 = widget_base(wtopbase, /row, /align_center)
dummy = widget_button(wbuttonbase2, value='Quit', uvalue='EXIT')
dummy = widget_button(wbuttonbase2, value='Export', uvalue='EXPORT')
sensitive = widget_info(mstate.returnid, /valid_id)
wsendpnt = widget_button(wbuttonbase2, value='Send pointing values', $
                      uvalue='SENDPOINT', sensitive=sensitive)
;
;  Report the date.
;
wdatebase = widget_base(wtopbase, /align_center, /frame)
wdate = cw_field(wdatebase, /column, value=mstate.target_date, /noedit, $
                 title='Target date')
;
;  Report the spacecraft coordinates.
;
wxybase = widget_base(wtopbase, /column, /frame)
dummy = widget_label(wxybase, value='Spacecraft X,Y coordinates', $
                     /align_center)
dummy = widget_base(wxybase, /align_center, /row)
wroll = cw_field(dummy, /frame, /row, value=roll0, title="Roll", /float, $
                 xsize=9, /noedit)
wxypoint = widget_base(wxybase, /align_center, /row)
wxsc = cw_field(wxypoint, /frame, /row, value=xsc, uvalue='XYSC', $
                title="X", /float, xsize=9, /return_events)
wysc = cw_field(wxypoint, /frame, /row, value=ysc, uvalue='XYSC', $
                title="Y", /float, xsize=9, /return_events)
;
wbuttonbase1 = widget_base(wxybase, /align_center, /row)
dummy = widget_button(wbuttonbase1, value='Apply', uvalue='XYSC')
;
;  Report the derolled coordinates.
;
whpcbase = widget_base(wtopbase, /column, /frame)
dummy = widget_label(whpcbase, value='Derolled HPC coordinates', /align_center)
whpcpoint = widget_base(whpcbase, /align_center, /row)
wxhpc = cw_field(whpcpoint, /frame, /row, value=xhpc, uvalue='XYHPC', $
                 title="X", /float, xsize=9, /return_events)
wyhpc = cw_field(whpcpoint, /frame, /row, value=yhpc, uvalue='XYHPC', $
                 title="Y", /float, xsize=9, /return_events)
;
wbuttonbase2 = widget_base(whpcbase, /align_center, /row)
dummy = widget_button(wbuttonbase2, value='Apply', uvalue='XYHPC')
;
;  Report the Carrington coordinates.
;
widget_control, mstate.wdist, get_value=dsun
widget_control, mstate.wpitch, get_value=b0
widget_control, mstate.wyaw, get_value=l0
sunglobe_hpc2carr, dsun, l0, b0, xhpc, yhpc, crln, crlt
carrmap = finite(crln) and finite(crlt)
;
wcarrbase = widget_base(wtopbase, /column, /frame, map=carrmap)
dummy = widget_label(wcarrbase, value='Carrington coordinates', /align_center)
wcarrpoint = widget_base(wcarrbase, /align_center, /row)
wlon = cw_field(wcarrpoint, /frame, /column, value=crln, uvalue='CARR', $
                title="Longitude", /float, xsize=11, /return_events)
wlat = cw_field(wcarrpoint, /frame, /column, value=crlt, uvalue='CARR', $
                title="Latitude", /float, xsize=11, /return_events)
;
wbuttonbase3 = widget_base(wcarrbase, /align_center, /row)
dummy = widget_button(wbuttonbase3, value='Apply', uvalue='CARR')
;
;  Realize the widget hierarchy.
;
widget_control, wtopbase, /realize
;
;  Define the state structure, and store it in the top base.
;
sstate = {mstate: mstate, $
          wtopbase: wtopbase, $
          wsendpnt: wsendpnt, $
          limb: 0, $
          wxsc: wxsc, $
          wysc: wysc, $
          wxhpc: wxhpc, $
          wyhpc: wyhpc, $
          wcarrbase: wcarrbase, $
          carrmap: carrmap, $
          wlon: wlon, $
          wlat: wlat}
widget_control, wtopbase, set_uvalue=sstate, /no_copy
;
;  Start the whole thing going.
;
xmanager, 'sunglobe_convert', wtopbase
;
end
