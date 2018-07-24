;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_EVENT
;
; Purpose     :	Event handler for SUNGLOBE program
;
; Category    :	Object graphics, 3D, Planning
;
; Inputs      :	EVENT = Event structure
;
; Ext. Events : Events can be triggered by an external routine via the
;               following command:
;
;               WIDGET_CONTROL, eventbase, SEND_EVENT=event, UVALUE=uvalue
;
;               where EVENTBASE is the widget ID returned by the call to
;               sunglobe.pro, UVALUE is one the values below, and EVENT is a
;               structure with the following format:
;
;               event = {ID: 0L, TOP: 0L, HANDLER: 0L, ...}
;
;               where "..." represents additional structure tags depending on
;               UVALUE.  The following (case-sensitive) external events are
;               supported:
;
;               Change the target date (via ANYTIM2UTC).
;
;               uvalue='EVENT_TARGET_DATE'
;               event = {..., TARGET_DATE: target_date}
;
;               See sunglobe_demo.pro for a demonstration of passing events
;               back and forth between SUNGLOBE and another program.
;
; Ret. Events : The following events can be returned to the calling routine if
;               the RETURNID parameter points to a valid widget ID:
;
;               UVALUE='SUNGLOBE_POINTING'
;               event.XSC = Spacecraft X pointing in arc seconds
;               event.YSC = Spacecraft Y pointing in arc seconds
;               event.ROLL= Spacecraft roll angle in degrees for which the
;                           spacecraft pointing values are valid
;               event.XHPC= HPC X pointing in arc seconds
;               event.YHPC= HPC Y pointing in arc seconds
;               event.ONDISK = Flag whether Carrington coordinates are valid
;               event.CRLN= Carrington longitude in degrees
;               event.CRLT= Carrington latitude in degrees
;               event.TARGET_DATE = Target date for which the pointing values
;                                   are valid
;
;               Returned events are also demonstrated in sunglobe_demo.pro
;
; Calls       :	WCS_RSUN, WCS_AU, SUNGLOBE_PARSE_TMATRIX. SUNGLOBE_SELECT_HV,
;               SUNGLOBE_READ_HV, SUNGLOBE_SELECTED_IMAGE, SUNGLOBE_DIFF_ROT,
;               SUNGLOBE_DISPLAY, SUNGLOBE_ORIENT, SUNGLOBE_DISTANCE,
;               SUNGLOBE_REPOINT, SUNGLOBE_GET_EPHEM,
;               SUNGLOBE_SPICE_CONFIG_FOV, SUNGLOBE_SPICE_FOV__DEFINE,
;               SUNGLOBE_CHANGE_DATE, SUNGLOBE_GET_PFSS, SUNGLOBE_GET_CONNECT
;
; Prev. Hist. :	Based on d_globe.pro in the IDL examples directory.
;
; History     :	Version 1, 20-Jan-2016, William Thompson, GSFC
;               Version 2, 5-Apr-2016, WTT, redraw after reading in PFSS
;               Version 3, 4-Aug-2016, WTT, call SUNGLOBE_GET_EPHEM
;               Version 4, 26-Aug-2016, WTT, add generic FOV events
;               Version 5, 2-Sep-2106, WTT, add HPC coordinates, orbit trace
;               Version 6, 14-Nov-2016, WTT, add image SAVE/RESTORE
;               Version 7, 18-Nov-2016, WTT, check if SunSPICE is loaded
;               Version 8, 01-Aug-2017, WTT, add JPEG event
;                       Change SUNGLOBE_HPC call to SUNGLOBE_CONVERT
;                       Move send point option to SUNGLOBE_CONVERT subwidget
;               Version 9, 05-Mar-2018, WTT, add magnetic connection point
;               Version 10, 02-Apr-2018, WTT, unbounded number of images
;
; Contact     :	WTHOMPSON
;-
;
;----------------------------------------------------------------------
;
pro sunglobe_event, event
;
;  If the window close box has been selected, then kill the widget.
;
if (tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST') then $
  goto, destroy
;
;  Get the UVALUE, and act accordingly.
;
widget_control, event.top, get_uvalue=sstate, /no_copy
widget_control, event.id, get_uvalue=uvalue
case uvalue of
;------------------------------------------------------------------------------
;  Set the roll angle to zero.
;------------------------------------------------------------------------------
    'ZEROROLL': begin
        widget_control, sstate.wroll, set_value=0
        sunglobe_orient, sstate
;
;  If the ephemeris button is selected, then change it to the orientation
;  button.
;
        widget_control, sstate.wselephem, get_value=selephem
        if selephem then begin
            widget_control, sstate.wselephem, set_value=0
            widget_control, sstate.wconvert, sensitive=0
            widget_control, sstate.wselorient, set_value=1
            widget_control, sstate.wyaw, sensitive=1
            widget_control, sstate.wpitch, sensitive=1
            widget_control, sstate.wroll, sensitive=1
            widget_control, sstate.wdist, sensitive=1
            widget_control, sstate.wlockorient, sensitive=1
        endif
    end
;------------------------------------------------------------------------------
;  Reset the orientation back to the starting values.  This includes the
;  distance parameter, which is converted from AU to solar radii.
;------------------------------------------------------------------------------
    'RESETORIENT': begin
;
;  First take care of the distance parameter.
;
        sstate.oview->setproperty, eye=sstate.origeye
        dist = sstate.origeye * wcs_rsun() / wcs_au()
        widget_control, sstate.wdist, set_value=dist
        sunglobe_distance, sstate
;
;  Next, take care of the orientation parameters.

        sstate.omodelrotate->setproperty, transform=sstate.origrotate
;
;  Redraw the window.
;
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
;
;  If the ephemeris button is selected, then change it to the orientation
;  button.
;
        widget_control, sstate.wselephem, get_value=selephem
        if selephem then begin
            widget_control, sstate.wselephem, set_value=0
            widget_control, sstate.wconvert, sensitive=0
            widget_control, sstate.wselorient, set_value=1
            widget_control, sstate.wyaw, sensitive=1
            widget_control, sstate.wpitch, sensitive=1
            widget_control, sstate.wroll, sensitive=1
            widget_control, sstate.wdist, sensitive=1
            widget_control, sstate.wlockorient, sensitive=1
        endif
    end
;------------------------------------------------------------------------------
;  Reset the image center.
;------------------------------------------------------------------------------
    'RESETCENTER': begin
        sstate.omodeltranslate->setproperty, transform=sstate.origtranslate
        widget_control, sstate.wxsun, set_value=0.0
        widget_control, sstate.wysun, set_value=0.0
;
;  Redraw the window.
;
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
;
        sstate.omodeltranslate->getproperty, transform=matrix
        sstate.mpoint = invert(matrix)
    end
;------------------------------------------------------------------------------
;  Reset the perspective back to the starting values.  This includes the
;  distance parameter, which is converted from AU to solar radii.
;------------------------------------------------------------------------------
    'RESETZOOM': begin
        sstate.oview->setproperty, viewplane_rect=sstate.origview
;
;  Redraw the window.
;
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Reset the spacecraft pointing to 0,0
;------------------------------------------------------------------------------
    'RESETSCPOINT': begin
        widget_control, sstate.wxsc, set_value=0.0
        widget_control, sstate.wysc, set_value=0.0
        sunglobe_scpoint, sstate
    end
;------------------------------------------------------------------------------
;  Reset the perspective back to the starting values.  This includes the
;  distance parameter, which is converted from AU to solar radii.  Also reset
;  the spacecraft pointing.
;------------------------------------------------------------------------------
    'RESET': begin
        sstate.omodeltranslate->setproperty, transform=sstate.origtranslate
        sstate.omodelrotate->setproperty, transform=sstate.origrotate
        sstate.oview->setproperty, viewplane_rect=sstate.origview
        sstate.oview->setproperty, eye=sstate.origeye
        dist = sstate.origeye * wcs_rsun() / wcs_au()
        widget_control, sstate.wdist, set_value=dist
        widget_control, sstate.wxsun, set_value=0.0
        widget_control, sstate.wysun, set_value=0.0
;
;  Reset the pointing, and redraw the window.
;
        widget_control, sstate.wxsc, set_value=0.0
        widget_control, sstate.wysc, set_value=0.0
        sunglobe_scpoint, sstate
;
        sstate.omodeltranslate->getproperty, transform=matrix
        sstate.mpoint = invert(matrix)
;
;  If the ephemeris button is selected, then change it to the orientation
;  button.
;
        widget_control, sstate.wselephem, get_value=selephem
        if selephem then begin
            widget_control, sstate.wselephem, set_value=0
            widget_control, sstate.wconvert, sensitive=0
            widget_control, sstate.wselorient, set_value=1
            widget_control, sstate.wyaw, sensitive=1
            widget_control, sstate.wpitch, sensitive=1
            widget_control, sstate.wroll, sensitive=1
            widget_control, sstate.wdist, sensitive=1
            widget_control, sstate.wlockorient, sensitive=1
        endif
    end
;------------------------------------------------------------------------------
;  Bring up the help widget.
;------------------------------------------------------------------------------
    'HELP': widg_help, 'sunglobe.hlp', /hierarchy, group_leader=event.top, $
                       /no_block
;------------------------------------------------------------------------------
;  If the ephemeris button is selected, then disable all the widgets in the
;  orientation menu.
;------------------------------------------------------------------------------
    'EPHEMERIS': begin
        widget_control, sstate.wyaw, sensitive=0
        widget_control, sstate.wpitch, sensitive=0
        widget_control, sstate.wroll, sensitive=0
        widget_control, sstate.wdist, sensitive=0
        widget_control, sstate.wlockorient, sensitive=0
        widget_control, sstate.wconvert, sensitive=1
;
;  Make sure only the ephemeris button is selected.
;
        widget_control, sstate.wselephem, set_value=1
        widget_control, sstate.wselorient, set_value=0
        widget_control, sstate.wselpan, set_value=0
;
;  Unless the lock ephemeris button has been enabled, get the ephemeris
;  information for the current date.
;
        widget_control, sstate.wlockorient, get_value=lockorient
        if not lockorient then begin
            which, 'load_sunspice', /quiet, outfile=temp
            if temp ne '' then sunglobe_get_ephem, sstate
        endif
;
;  Make sure that the spacecraft boresight and fields-of-view are displayed
;  correctly.
;
        sunglobe_scpoint, sstate
    end
;------------------------------------------------------------------------------
;  If the orientation button is selected, then enable all the widgets in the
;  orientation menu.
;------------------------------------------------------------------------------
    'ORIENTATION': begin
        widget_control, sstate.wyaw, sensitive=1
        widget_control, sstate.wpitch, sensitive=1
        widget_control, sstate.wroll, sensitive=1
        widget_control, sstate.wdist, sensitive=1
        widget_control, sstate.wlockorient, sensitive=1
;
;  Make sure only the orientation button is selected.
;
        widget_control, sstate.wselephem, set_value=0
        widget_control, sstate.wconvert, sensitive=0
        widget_control, sstate.wselorient, set_value=1
        widget_control, sstate.wselpan, set_value=0
    end
;------------------------------------------------------------------------------
;  If the panning button is selected, then enable all the widgets in the
;  orientation menu.
;------------------------------------------------------------------------------
    'PAN': begin
        widget_control, sstate.wyaw, sensitive=1
        widget_control, sstate.wpitch, sensitive=1
        widget_control, sstate.wroll, sensitive=1
        widget_control, sstate.wdist, sensitive=1
        widget_control, sstate.wlockorient, sensitive=1
;
;  Make sure only the panning button is selected.
;
        widget_control, sstate.wselephem, set_value=0
        widget_control, sstate.wconvert, sensitive=0
        widget_control, sstate.wselorient, set_value=0
        widget_control, sstate.wselpan, set_value=1
    end
;------------------------------------------------------------------------------
;  If the target field has been edited, then update the target date
;  information, and recalculate the images.
;------------------------------------------------------------------------------
    'CHANGEDATE': begin
        case event.value of
;
;  The date button was pressed.  Use XCALENDAR to change the date.
;
            'DATE': begin
                date = sstate.target_date
                xcalendar, date, group=event.top, /modal
                utc = anytim2utc(sstate.target_date)
                utc.mjd = (anytim2utc(date)).mjd
                sstate.target_date = utc2str(utc)
                widget_control, sstate.wtargetdate, set_value=sstate.target_date
            end
;
;  The time button was pressed.  Use XTIME to change the time.
;
            'TIME': begin
                date = sstate.target_date
                xtime, date, group=event.top, /modal
                utc = anytim2utc(sstate.target_date)
                utc.time = (anytim2utc(date)).time
                sstate.target_date = utc2str(utc)
                widget_control, sstate.wtargetdate, set_value=sstate.target_date
            end
        endcase
;
;  Apply the change.
;
        sunglobe_change_date, sstate
    end
;------------------------------------------------------------------------------
;  If a target date event has been sent from the calling widget, then update
;  the target date information, and recalculate the images.
;------------------------------------------------------------------------------
    'EVENT_TARGET_DATE': begin
        if tag_exist(event, 'target_date') then begin
            errmsg = ''
            target_date = anytim2utc(event.target_date, /ccsds, errmsg=errmsg)
            if errmsg ne '' then xack, errmsg else begin
                sstate.target_date = target_date
                widget_control, sstate.wtargetdate, set_value=sstate.target_date
;
;  Apply the change.
;
                sunglobe_change_date, sstate
            endelse
        end else xack, 'Event structure did not contain TARGET_DATE'
    end
;------------------------------------------------------------------------------
;  Handle S/C repointing events
;------------------------------------------------------------------------------
    'SCPOINT': begin
        widget_control, sstate.wxsc, get_value=xsc
        widget_control, sstate.wysc, get_value=ysc
        sunglobe_scpoint, sstate
    end
;------------------------------------------------------------------------------
;  Convert coordinates.
;------------------------------------------------------------------------------
    'CONVERT': begin
        sunglobe_convert, sstate, group_leader=event.top, /modal
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  If any of the YAW, PITCH, or ROW entries have been edited, then retrieve the
;  values and rotate the orb accordingly.
;------------------------------------------------------------------------------
    'YPR': sunglobe_orient, sstate
;------------------------------------------------------------------------------
;  If the distance parameter has been edited, then update the perspective.
;------------------------------------------------------------------------------
    'DIST': begin
        sunglobe_distance, sstate
        sunglobe_scpoint, sstate
    end
;------------------------------------------------------------------------------
;  Handle repointing events.
;------------------------------------------------------------------------------
    'POINT': begin
        sunglobe_repoint, sstate
        sstate.omodeltranslate->getproperty, transform=matrix
        sstate.mpoint = invert(matrix)
    end
;------------------------------------------------------------------------------
;  Create a JPEG of the current window.
;------------------------------------------------------------------------------
    'JPEG': begin
        filename = xpickfile(group=event.top, filter='*.jpg', /editable, $
                             default='sunglobe.jpg')
        if strmid(filename,strlen(filename)-4,4) ne '.jpg' then $
          filename = filename + '.jpg'
        dosave = 1
        if file_exist(filename) then begin
            text = ['File ' + filename + ' already exists.', $
                    'Do you want to overwrite it?']
            dosave = xanswer(text)
        endif
        if dosave then begin
            catch, error_status
            if error_status ne 0 then begin
                catch, /cancel
                xack, 'Unable to write file ' + filename
                goto, jpeg_cleanup
            endif
            otemp = sstate.owindow->read()
            otemp->getproperty, data=image
            write_jpeg, filename, image, /true
        end else xack, 'JPEG not created', group=event.top
jpeg_cleanup:
    end
;------------------------------------------------------------------------------
;  Turn the coordinate grid on or off.
;------------------------------------------------------------------------------
    'GRID': begin
        sstate.hidegrid = 1 - sstate.hidegrid
        sstate.ogrid->setproperty, hide=sstate.hidegrid
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Turn the spacecraft boresight on or off.
;------------------------------------------------------------------------------
    'BORESIGHT': begin
        sstate.hidebore = 1 - sstate.hidebore
        sstate.obore->setproperty, hide=sstate.hidebore
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Turn the SPICE FOV on or off.
;------------------------------------------------------------------------------
    'SPICEFOV': begin
        sstate.hidespice = 1 - sstate.hidespice
        sstate.ospice->setproperty, hide=sstate.hidespice
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Turn the EUI FOV on or off.
;------------------------------------------------------------------------------
    'EUIFOV': begin
        sstate.hideeui = 1 - sstate.hideeui
        sstate.oeui->setproperty, hide=sstate.hideeui
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Turn the PHI FOV on or off.
;------------------------------------------------------------------------------
    'PHIFOV': begin
        sstate.hidephi = 1 - sstate.hidephi
        sstate.ophi->setproperty, hide=sstate.hidephi
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Turn the generic FOV on or off.
;------------------------------------------------------------------------------
    'GENFOV': begin
        sstate.hidegen = 1 - sstate.hidegen
        sstate.ogen->setproperty, hide=sstate.hidegen
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Turn the orbit trace on or off.
;------------------------------------------------------------------------------
    'ORBIT': begin
        sstate.hideorbit = 1 - sstate.hideorbit
        if obj_valid(sstate.oorbit) then $
          sstate.oorbit->setproperty, hide=sstate.hideorbit
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Configure the SPICE field-of-view
;------------------------------------------------------------------------------
    'CONFIGSPICE': begin
        sunglobe_spice_config_fov, sstate.ospice, group_leader=event.top, /modal
        sstate.hidespice = 0
        sstate.ospice->setproperty, hide=sstate.hidespice
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Configure the EUI field-of-view
;------------------------------------------------------------------------------
    'CONFIGEUI': begin
        sunglobe_eui_config_fov, sstate.oeui, group_leader=event.top, /modal
        sstate.hideeui = 0
        sstate.oeui->setproperty, hide=sstate.hideeui
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Configure the PHI field-of-view
;------------------------------------------------------------------------------
    'CONFIGPHI': begin
        sunglobe_phi_config_fov, sstate.ophi, group_leader=event.top, /modal
        sstate.hidephi = 0
        sstate.ophi->setproperty, hide=sstate.hidephi
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Configure the generic field-of-view
;------------------------------------------------------------------------------
    'CONFIGGEN': begin
        sunglobe_generic_config_fov, sstate.ogen, group_leader=event.top, /modal
        sstate.hidegen = 0
        sstate.ogen->setproperty, hide=sstate.hidegen
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Configure the orbit trace
;------------------------------------------------------------------------------
    'CONFIGORBIT': begin
        which, 'load_sunspice', /quiet, outfile=temp
        if temp ne '' then begin
            sunglobe_orbit_config, sstate, group_leader=event.top, /modal
            sstate.hideorbit = 0
            sstate.oorbit->setproperty, hide=sstate.hideorbit
        end else xack, 'Unable to get ephemeris information'
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Handle zoom events here.
;------------------------------------------------------------------------------
    'ZOOM': begin
        sstate.oview->getproperty, viewplane_rect=viewplane_rect
        case event.value of
            'IN':  viewplane_rect /= sqrt(2.0d0)
            'OUT': viewplane_rect *= sqrt(2.0d0)
        endcase
        sstate.oview->setproperty, viewplane_rect=viewplane_rect
;
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Read in a PFSS magnetic field model.
;------------------------------------------------------------------------------
    'GETPFSS': begin
        sunglobe_get_pfss, sstate, group=event.top, /modal
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Estimate PFSS magnetic connection point.
;------------------------------------------------------------------------------
    'GETCONNECT': begin
        sunglobe_get_connect, sstate, group=event.top, /modal
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Turn the PFSS magnetic field model on or off.  If it hasn't been read
;  in yet, then read it in.
;------------------------------------------------------------------------------
    'SHOWPFSS': begin
        if obj_valid(sstate.opfss) then begin
            sstate.hidepfss = 1 - sstate.hidepfss
            sstate.opfss->setproperty, hide=sstate.hidepfss
        end else begin
            sunglobe_get_pfss, sstate, group=event.top, /modal
            sstate.hidepfss = 0
        endelse
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Turn the PFSS magnetic connection point on or off.  If it hasn't been read
;  in yet, then read it in.  If the recalculate property was set, then
;  recalculate it.
;------------------------------------------------------------------------------
    'SHOWCONNECT': begin
        if obj_valid(sstate.oconnect) then begin
            sstate.hideconnect = 1 - sstate.hideconnect
            sstate.oconnect->getproperty, recalculate=recalculate
            if (sstate.hideconnect eq 0) and recalculate then begin
                sstate.oconnect->getproperty, basis=basis
                sstate.oconnect->getproperty, nlines=nlines
                sstate.oconnect->getproperty, gausswidth=gausswidth
                sstate.oconnect->getproperty, windspeed=windspeed
                sstate.omodelrotate->remove, sstate.oconnect
                obj_destroy, sstate.oconnect
                sstate.oconnect = obj_new('sunglobe_connect', sstate=sstate, $
                                          basis=basis, nlines=nlines, $
                                          gausswidth=gausswidth, $
                                          windspeed=windspeed)
                sstate.omodelrotate->add, sstate.oconnect
            endif
            sstate.oconnect->setproperty, hide=sstate.hideconnect
        end else begin
            sunglobe_get_connect, sstate, group=event.top, /modal
            sstate.hideconnect = 0
        endelse
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Read in a Helioviewer image
;------------------------------------------------------------------------------
    'ADDHV': begin
        target_date = sstate.target_date
;
;  Select an HV source ID.
;
        source_id = sunglobe_select_hv(target_date, group=event.top, $
                                       label=label)
;
;  If a source ID has been selected, then read in the image.
;
        if source_id ge 0 then begin
            widget_control, /hourglass
;
;  Set a default opacity based on the number of images already displayed.
;
            opacity = 1. / ((sstate.nmapped<1) + 1.)
            result = sunglobe_read_hv(target_date, source_id, label, $
                                      opacity=opacity)
;
;  If a valid image has been read in, then add it to an image widget base.
;  Make sure there are enough bases for the new image.
;
            if datatype(result) eq 'STC' then begin
                if n_elements(sstate.wimagebases) eq sstate.nmapped then $
                  sunglobe_add_image_widget, sstate
;
;  Start off by moving all the existing widget bases down one step.
;
                for i=sstate.nmapped,1,-1 do begin
                    sstate.pimagestates[i] = sstate.pimagestates[i-1]
                    widget_control, sstate.wimagebases[i].wdraw, $
                                    get_value=window
                    wset, window
                    tv, (*sstate.pimagestates[i]).icon, /true
                    widget_control, sstate.wimagebases[i].wlabel, set_value= $
                                    (*sstate.pimagestates[i]).label
                endfor
;
;  Make sure the last widget is mapped, and update the number of mapped bases.
;
                widget_control, sstate.wimagebases[sstate.nmapped].base, map=1
                sstate.nmapped = sstate.nmapped + 1
;
;  Put the image that has just been read in into the top widget base.
;
                sstate.pimagestates[0] = ptr_new(result)
                widget_control, sstate.wimagebases[0].wdraw, get_value=window
                wset, window
                tv, (*sstate.pimagestates[0]).icon, /true
                widget_control, sstate.wimagebases[0].wlabel, set_value= $
                                (*sstate.pimagestates[0]).label
                widget_control, sstate.wimagebases[0].base, map=1
;
;  Define the first image to be the selected image.
;
                sstate.selected_index = -1
                sunglobe_selected_image, sstate, 0
;
;  Apply differential rotation to the image.
;
                sunglobe_diff_rot, sstate, 0
;
;  Update the display.
;
                sunglobe_display, sstate
            endif
            widget_control, hourglass=0
        endif
    end
;------------------------------------------------------------------------------
;  Handle image selection events.
;------------------------------------------------------------------------------
    'SELECT': begin
        index = (where(event.id eq sstate.wimagebases.id))[0]
        sunglobe_selected_image, sstate, index
    end
;------------------------------------------------------------------------------
;  Move images up.
;------------------------------------------------------------------------------
    'UP': begin
        i1 = sstate.selected_index
        i0 = i1 - 1
        temp = sstate.pimagestates[i0]
        sstate.pimagestates[i0] = sstate.pimagestates[i1]
        sstate.pimagestates[i1] = temp
        for i=i0,i1 do begin
            widget_control, sstate.wimagebases[i].wdraw, get_value=window
            wset, window
            tv, (*sstate.pimagestates[i]).icon, /true
            widget_control, sstate.wimagebases[i].wlabel, set_value= $
                            (*sstate.pimagestates[i]).label
        endfor
        widget_control, sstate.wimagebases[i0].id, set_value=1
        widget_control, sstate.wimagebases[i1].id, set_value=0
        widget_control, sstate.wup, sensitive=(i0 gt 0)
        widget_control, sstate.wdown, sensitive=((i0+1) lt sstate.nmapped)
        sstate.selected_index = i0
        sunglobe_display, sstate, /hourglass
    end
;------------------------------------------------------------------------------
;  Move images down.
;------------------------------------------------------------------------------
    'DOWN': begin
        i0 = sstate.selected_index
        i1 = i0 + 1
        temp = sstate.pimagestates[i0]
        sstate.pimagestates[i0] = sstate.pimagestates[i1]
        sstate.pimagestates[i1] = temp
        for i=i0,i1 do begin
            widget_control, sstate.wimagebases[i].wdraw, get_value=window
            wset, window
            tv, (*sstate.pimagestates[i]).icon, /true
            widget_control, sstate.wimagebases[i].wlabel, set_value= $
                            (*sstate.pimagestates[i]).label
        endfor
        widget_control, sstate.wimagebases[i0].id, set_value=0
        widget_control, sstate.wimagebases[i1].id, set_value=1
        widget_control, sstate.wup, sensitive=(i1 gt 0)
        widget_control, sstate.wdown, sensitive=((i1+1) lt sstate.nmapped)
        sstate.selected_index = i1
        sunglobe_display, sstate, /hourglass
    end
;------------------------------------------------------------------------------
;  Modify the opacity of the selected image.
;------------------------------------------------------------------------------
    'OPACITY': begin
        widget_control, sstate.wopacity, get_value=opacity
;
;  Apply the opacity value to the selected image.
;
        index = sstate.selected_index
        (*sstate.pimagestates[index]).opacity = opacity
        (*sstate.pimagestates[index]).map_alpha[3,*,*] = opacity * $
          (*sstate.pimagestates[index]).mapmask_rot
        (*sstate.pimagestates[index]).omap_alpha->setproperty, $
          data=(*sstate.pimagestates[index]).map_alpha
;
;  Update the buffer display containing the heliographic data.  If a drag
;  event, then use the small version for speed.
;
        if event.drag then begin
            sstate.opixmap_small->draw, sstate.opixview_small
            otempimage = sstate.opixmap_small->read()
        end else begin
            widget_control, /hourglass
            sstate.opixmap->draw, sstate.opixview
            otempimage = sstate.opixmap->read()
            widget_control, hourglass=0
        endelse
;
;  Extract the image data, and apply it to the sphere.
;
        otempimage->getproperty, data=tempimage
        obj_destroy, otempimage
        sstate.oimage->setproperty, data=temporary(tempimage)
;
;  Update the display.
;
        sstate.owindow->draw, sstate.oview
        sunglobe_parse_tmatrix, sstate
    end
;------------------------------------------------------------------------------
;  Delete images.
;------------------------------------------------------------------------------
    'DELETE': if xanswer('Are you sure you want to delete this image?') then $
      begin
;
;  Free up the objects and pointers associated with this image.
;
        i0 = sstate.selected_index
        obj_destroy, (*sstate.pimagestates[i0]).omap_alpha
        ptr_free, sstate.pimagestates[i0]
;
;  Move all the subsequent images up one step.
;
        nimages = sstate.nmapped
        for i = i0, nimages-2 do begin
            sstate.pimagestates[i] = sstate.pimagestates[i+1]
            widget_control, sstate.wimagebases[i].wdraw, get_value=window
            wset, window
            tv, (*sstate.pimagestates[i]).icon, /true
            widget_control, sstate.wimagebases[i].wlabel, set_value= $
                            (*sstate.pimagestates[i]).label
        endfor
;
;  Unmap the bottom widget base, and deselect all images.
;
        widget_control, sstate.wimagebases[nimages-1].base, map=0
        widget_control, sstate.wimagebases[i0].id, set_value=0
        sstate.nmapped = sstate.nmapped - 1
        sunglobe_selected_image, sstate, -1
;
;  Renable adding images.
;
        widget_control, sstate.waddhv, sensitive=1
;
        sunglobe_display, sstate, /hourglass
    endif
;------------------------------------------------------------------------------
;  Handle draw window events here.
;------------------------------------------------------------------------------
    'DRAW': begin
;
;  Avoid anomalous conditions where SSTATE is not defined.
;
        if datatype(sstate) eq 'STC' then begin
;
;  Determine which mouse function has been enabled.
;
            widget_control, sstate.wselephem, get_value=selephem
            widget_control, sstate.wselorient, get_value=selorient
            widget_control, sstate.wselpan, get_value=selpan
;  -----------------------------
;  Handle ephemeris events here.
;  -----------------------------
            if selephem then begin
;
;  Convert from device pixels to view location.
;
                sstate.owindow->getproperty, dimensions=dim
                sstate.oview->getproperty, viewplane_rect=rect
                x = (event.x/dim[0])*rect[2] + rect[0]
                y = (event.y/dim[1])*rect[3] + rect[1]
;
;  Correct for image translation (panning).
;
                coord = [x,y,0,1] # sstate.mpoint
;
;  Convert to arcseconds.
;
                dtor = !dpi / 180.d0            ;Conversion degrees to radians
                rad2arcsec = 3600.d0 / dtor     ;Conv. radians to arcseconds
                widget_control, sstate.wdist, get_value=dist
                dist = dist * wcs_au() / wcs_rsun()
                z = dist + coord[2]
                lon = rad2arcsec * atan(coord[0] / z)
                lat = rad2arcsec * atan(coord[1] / sqrt(coord[0]^2 + z^2))
;
;  Act based on the button pushed.
;
                case event.type of
                    0: begin    ;Button press
                        widget_control, sstate.wxsc, set_value=lon
                        widget_control, sstate.wysc, set_value=lat
                        widget_control, sstate.wdraw, draw_motion_events=1
                        sunglobe_scpoint, sstate
                    end
                    2: begin    ;Motion with button down
                        widget_control, sstate.wxsc, set_value=lon
                        widget_control, sstate.wysc, set_value=lat
                        sunglobe_scpoint, sstate
                    end
                    1: begin    ;Button release
                        widget_control, sstate.wdraw, draw_motion_events=0
                        sunglobe_scpoint, sstate
                    end
                    4: begin    ;Expose event
                        sstate.owindow->draw, sstate.oview
                        sunglobe_parse_tmatrix, sstate
                    end
                endcase
            endif
;  -----------------------------
;  Handle trackball events here.
;  -----------------------------
            if selorient then begin
                bhavetransform = sstate.otrack->update(event, transform=qmat)
                if (bhavetransform ne 0) then begin
                    sstate.omodelrotate->getproperty, transform=trans
                    mtrans=trans # qmat
                    sstate.omodelrotate->setproperty, transform=mtrans
                endif
;
;  Handle button press.
;
                case event.type of
                    0: widget_control, sstate.wdraw, draw_motion_events=1
                    2: begin
                        if (bhavetransform) then begin
                            sstate.owindow->draw, sstate.oview
                            sunglobe_parse_tmatrix, sstate
                        endif
                    end
;
;  Handle button release.
;
                    1: begin
                        widget_control, sstate.wdraw, draw_motion_events=0
                        sstate.owindow->draw, sstate.oview
                        sunglobe_parse_tmatrix, sstate
                    end
;
;  Handle expose events.
;
                    4: begin
                        sstate.owindow->draw, sstate.oview
                        sunglobe_parse_tmatrix, sstate
                    end
                endcase
            endif
;  -----------------------
;  Handle pan events here.
;  -----------------------
            if selpan then begin
                sstate.owindow->getproperty, dimensions=dim
                sstate.oview->getproperty, viewplane_rect=rect
                x = (event.x/dim[0])*rect[2] + rect[0]
                y = (event.y/dim[1])*rect[3] + rect[1]
;
                widget_control, sstate.wdist, get_value=dist
                eye = (dist * wcs_au() / wcs_rsun()) > 3
;
                dtor = !dpi / 180.d0   ;conversion degrees to radians
                asectorad = dtor / 3600.d0 ;conversion arcseconds to radians
                phi   = atan(x/eye) / asectorad
                theta = atan(y/eye) / asectorad
;
                case event.type of
                    0: begin    ;Button press
                        widget_control, sstate.wxsun, get_value=xsun
                        widget_control, sstate.wysun, get_value=ysun
                        sstate.origpan = [xsun + phi, ysun + theta]
                        widget_control, sstate.wdraw, draw_motion_events=1
                    end
                    2: begin    ;Motion with button down
                        widget_control, sstate.wxsun, set_value= $
                                        sstate.origpan[0] - phi
                        widget_control, sstate.wysun, set_value= $
                                        sstate.origpan[1] - theta
                        sunglobe_repoint, sstate
                    end
                    1: begin    ;Button release
                        widget_control, sstate.wdraw, draw_motion_events=0
                        sstate.omodeltranslate->getproperty, transform=matrix
                        sstate.mpoint = invert(matrix)
                        sstate.owindow->draw, sstate.oview
                        sunglobe_parse_tmatrix, sstate
                    end
                    4: begin    ;Expose event
                        sstate.owindow->draw, sstate.oview
                        sunglobe_parse_tmatrix, sstate
                    end
                endcase
            endif
        endif
    end
;------------------------------------------------------------------------------
;  Handle SAVE events here.
;------------------------------------------------------------------------------
    'SAVE': begin
        nmapped = sstate.nmapped
        pimagestates = sstate.pimagestates
        filename = xpickfile(group=event.top, filter='*.geny', /editable, $
                             default='sunglobe.geny')
        if strmid(filename,strlen(filename)-5,5) ne '.geny' then $
          filename = filename + '.geny'
        dosave = 1
        if file_exist(filename) then begin
            text = ['File ' + filename + ' already exists.', $
                    'Do you want to overwrite it?']
            dosave = xanswer(text)
        endif
        if dosave then $
          savegenx, file=filename, nmapped, pimagestates, /overwrite else $
            xack, 'Images not saved', group=event.top
    end
;------------------------------------------------------------------------------
;  Handle RESTORE events here.
;------------------------------------------------------------------------------
    'RESTORE': begin
        filename = xpickfile(group=event.top, filter='*.geny')
        if filename ne '' then begin
            widget_control, /hourglass
            restgenx, file=filename, nmapped, pimagestates
            if datatype(pimagestates) ne 'PTR' then $
              xack, 'Not a valid save file', group=event.top else begin
;
;  Make sure there are enough slots for all the images.
;
                nimages = n_elements(pimagestates)
                while n_elements(sstate.wimagebases) lt nimages do $
                  sunglobe_add_image_widget, sstate
;
;  Display images that have been restored.
;
                for i=0,n_elements(sstate.pimagestates)-1 do begin
                    if i lt nmapped then begin
                        sstate.pimagestates[i] = pimagestates[i]
                        widget_control, sstate.wimagebases[i].wdraw, $
                                        get_value=window
                        wset, window
                        tv, (*sstate.pimagestates[i]).icon, /true
                        widget_control, sstate.wimagebases[i].wlabel, $
                                        set_value=(*sstate.pimagestates[i]).label
                        widget_control, sstate.wimagebases[i].base, map=1
                    end else widget_control, sstate.wimagebases[i].base, map=0
                endfor
                sstate.nmapped = nmapped < n_elements(sstate.pimagestates)
;
;  Define the first image to be the selected image.
;
                sstate.selected_index = -1
                sunglobe_selected_image, sstate, 0
;
;  Apply differential rotation to the image.
;
                sunglobe_diff_rot, sstate, 0
;
;  Update the display.
;
                sunglobe_display, sstate
            endelse
            widget_control, hourglass=0
        endif
    end
;------------------------------------------------------------------------------
;  Quit this application.
;------------------------------------------------------------------------------
    'QUIT': begin
destroy:
        if xanswer('Are you sure you want to quit?') then begin
            widget_control, event.top, set_uvalue=sstate, /no_copy
            widget_control, event.top, /destroy
            return
        end
    end
;
;  Handle all other events.
;
    else:                       ;  Do nothing
endcase
;
widget_control, event.top, set_uvalue=sstate, /no_copy
end
