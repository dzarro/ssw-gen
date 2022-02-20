;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_READ_FITS()
;
; Purpose     :	Read in a generic FITS file for the SUNGLOBE program
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This routine is called from SUNGLOBE_GET_FITS() to read in a
;               generic FITS file, and prepare it for viewing within the
;               SUNGLOBE program by scaling it and applying a color table.  The
;               user also has the option of fitting the limb to correct the
;               pointing.
;
; Syntax      :	SUNGLOBE_READ_FITS, POUTPUT, GROUP_LEADER=GROUP_LEADER
;
; Examples    :	See sunglobe_get_fits.pro
;
; Inputs      :	None
;
; Opt. Inputs :	None
;
; Keywords    : SOAR_DATE = Date for searching Solar Orbiter archive.  Use of
;                           this option bypasses browsing local directories.
;                           If the environment variable SOAR_DIRECTORY is
;                           defined, then files copied over from the archive
;                           are stored in this directory--otherwise they are
;                           temporary.
;
;               GROUP_LEADER = The widget ID of the group leader.  When this
;                              keyword points to a valid widget ID, this
;                              routine is run in modal mode.
;
; Outputs     :	POUTPUT = Pointer to a structure with the following tags:
;
;                       PIMAGE = Pointer to the processed image.
;                       PWCS   = Pointer to the WCS structure.
;                       LABEL  = String label to be associated with the file.
;
; Calls       :	SUNGLOBE_READ_FITS_CLEANUP, SUNGLOBE_READ_FITS_PLOT_LIMB,
;               SUNGLOBE_READ_FITS_REDISPLAY, SUNGLOBE_READ_FITS_EVENT,
;               WCS_RSUN(), SETWINDOW, XPICKFILE, FXREAD, FITSHEAD2WCS,
;               SCALE_TV, EXPAND_TV, XLOADCT, XACK, FIT_CIRCLE, XANSWER,
;               SOAR_GET, WCS_FIND_SYSTEM
;
; Restrictions: The limb fitting section of the code assumes that the plate
;               scale is the same in both directions.
;
; History     :	Version 1, William Thompson, 14-Jan-2019, GSFC
;               Version 2, WTT, 24-Dec-2019, Corrected implicit assumption that
;                       reference pixel is Sun center.  Make help modal.
;               Version 3, WTT,  8-Jan-2020, add microscope window
;               Version 4, WTT, 21-Jan-2021, add Solar Orbiter option
;               Version 5, WTT, 21-May-2021, for FITS files with multiple
;                       coordinate systems, look for Helioprojective-Cartesian
;
; Contact     :	WTHOMPSON
;-
;
;==============================================================================
;
;  Routine called when the program exits.  Converts the original image into a
;  24-bit color representation.
;
pro sunglobe_read_fits_cleanup, tlb
;
;  Extract the STORAGE structure from the widget base, and extract out the
;  image.
;
widget_control, tlb, get_uvalue=storage
pimage = ((*(storage.poutput)).pimage)
;
;  Byte-scale the image, and apply the color table.
;
if pimage ne !NULL then begin
    temp = bytscl(*pimage, min=storage.imin, max=storage.imax)
    tvlct, red, green, blue, /get
    sz = size(temp)
    image = bytarr(3,sz[1],sz[2])
    image[0,*,*] = red[temp]
    image[1,*,*] = green[temp]
    image[2,*,*] = blue[temp]
;
;  Store the scaled image back into the output structure.
;
    (*(storage.poutput)).pimage = ptr_new(image)
endif
end
;
;==============================================================================
;
;  This routine overplots the location of the solar limb based on the current
;  pointing parameters.
;
pro sunglobe_read_fits_plot_limb, storage
;
;  Extract out the WCS structure.
;
wcs = *((*(storage.poutput)).pwcs)
;
;  Calculate the solar radius in the units given by the CUNIT keywords.  Assume
;  that the same units and plate scale are used in both dimensions.
;
rsun = asin(wcs_rsun() / wcs.position.dsun_obs)
radeg = 180.d0 / !dpi
case wcs.cunit[0] of
    'deg':    rsun = rsun * radeg
    'arcmin': rsun = rsun * radeg * 60
    'arcsec': rsun = rsun * radeg * 3600
    'mas':    rsun = rsun * radeg * 3600D3
    else:
endcase
;
;  Convert into image pixel units.
;
rsun = rsun / wcs.cdelt[0]
;
;  Form a circle in image pixel coordinates based on the WCS values.
;
theta = 10 * findgen(37) / radeg
center = wcs_get_pixel(wcs, [0,0])
x = rsun * cos(theta) + center[0]
y = rsun * sin(theta) + center[1]
;
;  Get the parameters relating image pixels and screen pixels, and convert the
;  circle into screen pixel coordinates.
;
sx = float(storage.mx) / wcs.naxis[0]
sy = float(storage.my) / wcs.naxis[1]
x = sx*x + storage.ix
y = sy*y + storage.iy
;
;  Select the correct window, and overplot the circle.
;
setwindow, storage.win
plots, x, y, /device
end
;
;==============================================================================
;
;  This procedure serves as the callback routine for XLOADCT to redisplay the
;  image and any overplotted fit points.
;
pro sunglobe_read_fits_redisplay, data=data
;
;  Extract the STORAGE structure from the widget base, select the graphics
;  window, and redisplay the image.
;
widget_control, data, get_uvalue=storage
setwindow, storage.win
tv, *(storage.pbscaled), storage.ix, storage.iy
;
;  If there are active fitting points, then replot them.
;
if storage.pfitlist ne !NULL then begin
    wcs = *((*(storage.poutput)).pwcs)
    fitlist = *(storage.pfitlist)
    sx = float(storage.mx) / wcs.naxis[0]
    sy = float(storage.my) / wcs.naxis[1]
    plots, sx*fitlist[0,*] + storage.ix, sy*fitlist[1,*] + storage.iy, $
      psym=1, symsize=3, /device
endif
end
;
;==============================================================================
;
;  Event handler for the SUNGLOBE_READ_FITS widget program.
;
pro sunglobe_read_fits_event, ev
;
;  If the window close box has been selected, then kill the widget.
;
if (tag_names(ev, /structure_name) eq 'WIDGET_KILL_REQUEST') then $
  goto, destroy
;
;  Get the UVALUE, and act accordingly.
;
widget_control, ev.id, get_uvalue=uvalue
case uvalue of
    'EXIT': begin
destroy:
        widget_control, ev.top, get_uvalue=storage
        widget_control, storage.wlabel, get_value=label
        (*(storage.poutput)).label = label
        widget_control, ev.top, /destroy
    end
;
;  The "Read file" button" was selected.
;
    'READ': begin
;
;  Set up error catching.
;
        catch, error_status
        if error_status ne 0 then begin
            catch, /cancel
            xack, !error_state.msg
            return
        endif
;
;  Define default values for several variables.
;
        label = ''
        tempdir = ''
        soardir = ''
;
;  Select a file to read in.
;
        widget_control, ev.top, get_uvalue=storage
        if valid_time(storage.soar_date) then begin
           desc = sunglobe_select_soar(storage.soar_date, label=label, $
                                       group_leader=ev.top)
           if datatype(desc) eq 'STC' then begin
              soardir = getenv('SOAR_DIRECTORY')
              if soardir ne '' then begin
                 filename = concat_dir(soardir, desc.file_name)
                 if file_exist(filename) then goto, do_read
              endif
              mk_temp_dir, get_temp_dir(), tempdir
              errmsg = ''
              widget_control, /hourglass
              status = soar_get(desc, out_dir=tempdir, errmsg=errmsg)
              widget_control, hourglass=0
              if errmsg ne '' then begin
                 catch, /cancel
                 xack, errmsg
                 return
              endif
              filename = (file_search(concat_dir(tempdir,'*')))[0]
              if filename eq '' then begin
                 catch, /cancel
                 xack, 'File ' + desc.file_name + ' not found.'
                 return
              endif
           end else begin
              catch, /cancel
              xack, 'No file selected'
              return
           endelse
        end else begin
           filename = xpickfile(group=ev.top)
           if filename eq '' then begin
              catch, /cancel
              xack, 'No file selected'
              return
           endif
        endelse
;
;  Read in the file, and extract the image and image header.
;
do_read:
        errmsg = ''
        fxread, filename, image, header, errmsg=errmsg
        if tempdir ne '' then begin
           if soardir ne '' then file_move, filename, soardir
           file_delete, tempdir, /recursive
        endif
        if errmsg ne '' then begin
            catch, /cancel
            xack, errmsg
            return
        endif
;
;  Extract the WCS information.
;
        system = wcs_find_system(header, 'Helioprojective-Cartesian')
        wcs = fitshead2wcs(header, system=system, errmsg=errmsg)
        if errmsg ne '' then begin
            catch, /cancel
            xack, errmsg
            return
        endif
;
;  Make sure it's an image.
;
        sz = size(image)
        if sz[0] ne 2 then begin
            catch, /cancel
            xack, 'Not a two-dimensional image'
            return
        endif
;
;  Initialize the min and max values for scaling the image.
;
        storage.imin = min(image)
        storage.imax = max(image)
        widget_control, storage.wmin, set_value=storage.imin
        widget_control, storage.wmax, set_value=storage.imax
;
;  Use SCALE_TV to scale the image to the window, and EXPAND_TV to display it.
;
        setwindow, storage.win
        scale_tv, image, mx, my, ix, iy, /noexact, /nobox
        expand_tv, image, mx, my, ix, iy, min=imin, max=imax, bscaled=bscaled
;
;  Populate the image label with the filename.
;
        if label eq '' then break_file, filename, disk, dir, label
        widget_control, storage.wlabel, set_value=label
        (*(storage.poutput)).label = label
;
;  Store the image, wcs, and the metadata used within the routine.
;
        (*(storage.poutput)).pimage = ptr_new(image)
        (*(storage.poutput)).pwcs = ptr_new(wcs)
        storage.pbscaled = ptr_new(bscaled)
        storage.mx = mx
        storage.my = my
        storage.ix = ix
        storage.iy = iy
;
;  Enable the "Check pointing" and "Fit Limb" buttons, and store everything in
;  widget base.
;
        widget_control, storage.wchkbtn, sensitive=1
        widget_control, storage.wfitbtn, sensitive=1
        widget_control, ev.top, set_uvalue=storage
    end
;
;  A minimum value was entered.
;
    'MIN': begin
        widget_control, ev.top, get_uvalue=storage
        widget_control, storage.wmin, get_value=imin
        widget_control, storage.wmax, get_value=imax
        if imin ge imax then begin
            imin = imax - 1
            widget_control, storage.wmin, set_value=imin
        endif
        storage.imin = imin
        storage.imax = imax
;
;  Redisplay the image with the new min/max values.
;
        setwindow, storage.win
        expand_tv, *((*(storage.poutput)).pimage), storage.mx, storage.my, $
          storage.ix, storage.iy, min=imin, max=imax, bscaled=bscaled
;
;  Store the byte-scaled image, and redisplay any fit points.
;
        storage.pbscaled = ptr_new(bscaled)
        widget_control, ev.top, set_uvalue=storage
        sunglobe_read_fits_redisplay, data=ev.top
    end
;
;  A maximum value was entered.
;
    'MAX': begin
        widget_control, ev.top, get_uvalue=storage
        widget_control, storage.wmin, get_value=imin
        widget_control, storage.wmax, get_value=imax
        if imin ge imax then begin
            imax = imin + 1
            widget_control, storage.wmax, set_value=imax
        endif
        storage.imin = imin
        storage.imax = imax
;
;  Redisplay the image with the new min/max values.
;
        setwindow, storage.win
        expand_tv, *((*(storage.poutput)).pimage), storage.mx, storage.my, $
          storage.ix, storage.iy, min=imin, max=imax, bscaled=bscaled
;
;  Store the byte-scaled image, and redisplay any fit points.
;
        storage.pbscaled = ptr_new(bscaled)
        widget_control, ev.top, set_uvalue=storage
        sunglobe_read_fits_redisplay, data=ev.top
    end
;
;  Call XLOADCT.
;
    'COLOR': xloadct, group=ev.top, updatecbdata=ev.top, $
      updatecallback="sunglobe_read_fits_redisplay"
;
;  Temporarily plot the current limb location.
;
    'CHECK': begin
        widget_control, ev.top, get_uvalue=storage
        sunglobe_read_fits_plot_limb, storage
        xack, 'Limb position with current pointing values'
        sunglobe_read_fits_redisplay, data=ev.top
    end
;
;  Enable the limb fitting part of the code.  Desensitive the "Fit limb"
;  button.
;
    'LIMB': begin
        widget_control, ev.top, get_uvalue=storage
        widget_control, storage.wfitbase, sensitive=1
        storage.fitting = 1
        widget_control, storage.wfitbtn, sensitive=0
        widget_control, ev.top, set_uvalue=storage
    end
;
;  Process button down events in the draw window, but only if the fitting
;  section of the code has been activated.
;
    'DRAW': case 1 of
        tag_exist(ev, 'PRESS'): if ev.press then begin
            widget_control, ev.top, get_uvalue=storage
            if storage.fitting then begin
;
;  Convert from screen pixels into image pixels.
;
                sz = size(*((*(storage.poutput)).pimage))
                sx = sz[1] / float(storage.mx)
                sy = sz[2] / float(storage.my)
                x = sx * (ev.x - storage.ix)
                y = sy * (ev.y - storage.iy)
;
;  Generate a text line containing the selected location.  Store the location
;  and text line into their proper arrays.
;
                txt = '(' + trim(x,'(F10.1)') + ', ' + trim(y,'(F10.1)') + ')'
                if storage.pfitlist eq !NULL then begin
                    fitlist = [x,y]
                    fittext = txt
                end else begin
                    fitlist = [[*(storage.pfitlist)], [x,y]]
                    fittext = [*(storage.pfittext), txt]
                endelse
                storage.pfitlist = ptr_new(fitlist)
                storage.pfittext = ptr_new(fittext)
;
;  Update the list of pixel locations.
;
                widget_control, storage.wlist, set_value=fittext
;
;  Enable the "Fit points" button based on how many points have been selected.
;
                widget_control, storage.wfitdone, $
                                sensitive=(n_elements(fittext) ge 5)
;
;  Store the updated data, and refresh the display.
;
                widget_control, ev.top, set_uvalue=storage
                sunglobe_read_fits_redisplay, data=ev.top
            endif
;
;  Process motion events in the draw window, but only if the fitting section of
;  the code has been activated, and "Use microscope" is checked.
;
        endif else if ev.type eq 2 then begin
            widget_control, ev.top, get_uvalue=storage
            widget_control, storage.wusemicro, get_value=use_micro
            if storage.fitting and use_micro then begin
;
;  Convert from screen pixels into image pixels.
;
                image = *((*(storage.poutput)).pimage)
                sz = size(image)
                sx = sz[1] / float(storage.mx)
                sy = sz[2] / float(storage.my)
                x = sx * (ev.x - storage.ix)
                y = sy * (ev.y - storage.iy)
;
;  Extract out a subimage, and display it in the microscope.
;
                x0 = (round(x - storage.micsize/2)) > 0
                x1 = x0 + storage.micsize - 1
                if x1 ge sz[1] then begin
                    x1 = sz[1] - 1
                    x0 = (x1 - storage.micsize + 1) > 0
                endif
                y0 = (round(y - storage.micsize/2)) > 0
                y1 = y0 + storage.micsize - 1
                if y1 ge sz[2] then begin
                    y1 = sz[2] - 1
                    y0 = (y1 - storage.micsize + 1) > 0
                endif
                setwindow, storage.micro
                subimage = image[x0:x1,y0:y1]
                bscale, subimage, min=storage.imin, max=storage.imax
                tv, subimage
                plots, replicate(x-x0,2), [0,y1-y0], /device
                plots, [0,x1-x0], replicate(y-y0,2), /device
                setwindow, storage.win
            endif
        endif
;
;  If the cursor leaves the main draw widget, then erase the microscope.
;
        tag_exist(ev, 'ENTER'): begin
            if ev.enter eq 0 then begin
                widget_control, ev.top, get_uvalue=storage
                setwindow, storage.micro
                erase
                setwindow, storage.win
            endif
        end
    endcase
;
;  Remove the last fit point from the list.
;
    'REMOVE': begin
        widget_control, ev.top, get_uvalue=storage
        if storage.pfitlist ne !NULL then begin
            fitlist = *(storage.pfitlist)
            fittext = *(storage.pfittext)
            nlist = n_elements(fittext)
            if nlist eq 1 then begin
                storage.pfitlist = ptr_new()
                storage.pfittext = ptr_new()
                widget_control, storage.wlist, set_value=''
            end else begin
                fitlist = fitlist[*,0:nlist-2]
                fittext = fittext[0:nlist-2]
                storage.pfitlist = ptr_new(fitlist)
                storage.pfittext = ptr_new(fittext)
                widget_control, storage.wlist, set_value=fittext
            endelse
;
;  Enable the "Fit points" button based on how many points have been selected.
;
            widget_control, storage.wfitdone, $
              sensitive=(n_elements(fittext) ge 5)
;
;  Store the updated data, and refresh the display.
;
            widget_control, ev.top, set_uvalue=storage
            sunglobe_read_fits_redisplay, data=ev.top
        endif
    end
;
;  Cancel the limb fitting.
;
    'FITCANCEL': begin
        widget_control, ev.top, get_uvalue=storage
        storage.pfitlist = ptr_new()
        storage.pfittext = ptr_new()
        widget_control, storage.wlist, set_value=''
        widget_control, storage.wfitbase, sensitive=0
        storage.fitting = 0
;
;  Resensitize the "Fit limb" button, store the updated data, and refresh the
;  display.
;
        widget_control, storage.wfitbtn, sensitive=1
        widget_control, ev.top, set_uvalue=storage
        sunglobe_read_fits_redisplay, data=ev.top
    end
;
;  The "Fit points" button has been selected.  Extract the STORAGE structure
;  from the widget base, and determine whether the "Hold radius constant"
;  option has been selected.
;
    'FITDONE': begin
        widget_control, ev.top, get_uvalue=storage
        widget_control, storage.wfitrad, get_value=radius_fix
;
;  Extract the WCS structure, and calculate the initial fitting parameters.
;
        wcs = *((*(storage.poutput)).pwcs)
        rsun = asin(wcs_rsun() / wcs.position.dsun_obs)
        radeg = 180.d0 / !dpi
        case wcs.cunit[0] of
            'deg':    rsun = rsun * radeg
            'arcmin': rsun = rsun * radeg * 60
            'arcsec': rsun = rsun * radeg * 3600
            'mas':    rsun = rsun * radeg * 3600D3
            else:
        endcase
        radius = rsun / wcs.cdelt[0]
        center = wcs_get_pixel(wcs, [0,0])
        param0 = [center, radius]
;
;  Fit a circle to the selected points.
;
        fitlist = *(storage.pfitlist)
        param = fit_circle(fitlist[0,*], fitlist[1,*], param0, $
                           radius_fix=radius_fix)
;
;  Generate a new WCS from the fit, and plot the limb location based on these
;  new data.
;
        newwcs = wcs
        newwcs.crpix = param[0:1] + 1
        newwcs.crval[*] = 0
        newwcs.cdelt = replicate(rsun/param[2], 2)
        (*(storage.poutput)).pwcs = ptr_new(newwcs)
        sunglobe_read_fits_plot_limb, storage
;
;  Ask if this new pointing should be accepted or not.  If yes, then revert the
;  fitting section to its original desensitized state, and resensitize the "Fit
;  limb" button.
;
        if xanswer('Accept this new pointing?') then begin
            storage.pfitlist = ptr_new()
            storage.pfittext = ptr_new()
            widget_control, storage.wlist, set_value=''
            widget_control, storage.wfitbase, sensitive=0
            widget_control, storage.wfitbtn, sensitive=1
            storage.fitting = 0
;
;  Otherwise, restore the original WCS structure.
;
        end else (*(storage.poutput)).pwcs = ptr_new(wcs)
;
;  Store any new data, and refresh the display.
;
        widget_control, ev.top, set_uvalue=storage
        sunglobe_read_fits_redisplay, data=ev.top
    end
;
;  A value has been entered into the label field.
;
    'LABEL': begin
        widget_control, ev.top, get_uvalue=storage
        widget_control, storage.wlabel, get_value=label
        (*(storage.poutput)).label = label
        widget_control, ev.top, set_uvalue=storage
    end
;
;  The Help button has been selected.
;
    'HELP': widg_help, 'sunglobe_read_fits.hlp', /hierarchy, $
      group_leader=ev.top, /nofont, /modal
;
    else:
endcase
;
end
;
;==============================================================================
;
;  This routine sets up the widget.
;
pro sunglobe_read_fits, poutput, group_leader=group_leader, $
                        soar_date=k_soar_date
;
;  Initialize the output structure.
;
poutput = ptr_new({pimage: ptr_new(), pwcs: ptr_new(), label: ''})
;
;  Decide whether or not this should be a modal widget.
;
modal = 0
if n_elements(group_leader) eq 1 then $
  modal = widget_info(group_leader, /valid_id)
;
;  Set up the main base.
;
wmain = widget_base(/row, group_leader=group_leader, modal=modal, $
                    title='SUNGLOBE_READ_FITS')
;
;  On the left side, set up a top row of buttons.
;
winbase = widget_base(wmain, /column)
wmenu = widget_base(winbase, /row)
dummy = widget_button(wmenu, value='Read file', uvalue='READ')
dummy = widget_button(wmenu, value='Adjust color table', uvalue='COLOR')
wchkbtn = widget_button(wmenu, value='Check pointing', uvalue='CHECK', $
                        sensitive=0)
wfitbtn = widget_button(wmenu, value='Fit limb', uvalue='LIMB', sensitive=0)
dummy = widget_button(wmenu, value='Help', uvalue='HELP')
dummy = widget_button(wmenu, value='Exit', uvalue='EXIT')
;
;  Set up a widget for the image label.
;
wlabel = cw_field(winbase, title='Image label:', value='', uvalue='LABEL', $
                  xsize=40, /return_events)
;
;  Set up a draw widget.
;
device, get_screen_size = screenSize
xsize = min(screensize[0:1]) * 0.5
ysize = xsize                   ;Keep isotropic
wdraw = widget_draw(winbase, xsize=xsize, ysize=ysize, uvalue='DRAW', $
                    /motion_events, /button_events, /tracking_events, retain=2)
;
;  Along the bottom, set up widgets for controlling the image minimum and
;  maximum for scaling.
;
dummy = widget_base(winbase, /row)
wmin = cw_field(dummy, title='Image minimum:', xsize=15, /floating, $
                uvalue='MIN', /return_events)
wmax = cw_field(dummy, title='maximum:', xsize=15, /floating, $
                uvalue='MAX', /return_events)
;
;  On the right side, set up widgets for fitting the limb.
;
wfitbase = widget_base(wmain, /column, /frame, sensitive=0)
dummy = widget_label(wfitbase, value='Select points in a circle on the limb.')
dummy = widget_button(wfitbase, value='Remove last point', uvalue='REMOVE')
wlist = widget_list(wfitbase, xsize=30, ysize=20)
wfitrad = cw_bgroup(wfitbase, 'Hold radius constant', uvalue='NOFITRAD', $
                    /nonexclusive)
wbuttonbase = widget_base(wfitbase, /row)
dummy = widget_button(wbuttonbase, value='Cancel', uvalue='FITCANCEL')
wfitdone = widget_button(wbuttonbase, value='Fit points', uvalue='FITDONE', $
                         sensitive=0)
;
;  Add a "microscope" draw widget.
;
micsize = xsize / 4
wmicrobase = widget_base(wfitbase, /column, /frame)
wusemicro = cw_bgroup(wmicrobase, 'Use microscope', uvalue='USEMICRO', $
                      /nonexclusive)
wmicro = widget_draw(wmicrobase, xsize=micsize, ysize=micsize, uvalue='MICRO', $
                     retain=2)
;
;  Realize the widget, and get the window number.
;
widget_control, wmain, /realize
widget_control, wdraw, get_value=win
widget_control, wmicro, get_value=micro
;
;  Set up the STORAGE structure, and store it in the top base.
;
if valid_time(k_soar_date) then soar_date = k_soar_date else soar_date = ''
storage = {soar_date: soar_date, $
           win: win, $
           micro: micro, $
           wmin: wmin, $
           wmax: wmax, $
           imin: 0.0, $
           imax: 0.0, $
           poutput: poutput, $
           mx: 0, $
           my: 0, $
           ix: 0, $
           iy: 0, $
           pbscaled: ptr_new(), $
           wchkbtn: wchkbtn, $
           wfitbtn: wfitbtn, $
           wlabel: wlabel, $
           wfitbase: wfitbase, $
           wfitdone: wfitdone, $
           fitting: 0, $
           wfitrad: wfitrad, $
           wusemicro: wusemicro, $
           micsize: micsize, $
           wlist: wlist, $
           pfitlist: ptr_new(), $
           pfittext: ptr_new()}
widget_control, wmain, set_uvalue=storage
;
;  Start everything going.
;
xmanager, 'sunglobe_read_fits', wmain, /no_block, $
  event_handler='sunglobe_read_fits_event', $
  cleanup='sunglobe_read_fits_cleanup'
;
end
