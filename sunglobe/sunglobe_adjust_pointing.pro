;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_ADJUST_POINTING()
;
; Purpose     :	Adjust the pointing of an image read into SunGlobe
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation : This routine is called from SUNGLOBE_EVENT to fit the limb to
;               correct the pointing.
;
; Syntax      :	SUNGLOBE_ADJUST_POINTING, PIMAGESTATE, GROUP_LEADER=GROUP_LEADER
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	PIMAGESTATE  = Pointer to the image state structure
;
; Opt. Inputs :	None
;
; Keywords    : GROUP_LEADER = The widget ID of the group leader.  When this
;                              keyword points to a valid widget ID, this
;                              routine is run in modal mode.
;
; Outputs     :	PIMAGESTATE  = Pointer to the image state structure
;
; Calls       : SUNGLOBE_ADJ_POINT_PLOT_LIMB, SUNGLOBE_ADJ_POINT_REDISPLAY,
;               SUNGLOBE_ADJ_POINT_EVENT, WCS_RSUN(), SETWINDOW, SCALE_TV,
;               EXPAND_TV, XLOADCT, XACK, FIT_CIRCLE, XANSWER
;
; Restrictions: The limb fitting section of the code assumes that the plate
;               scale is the same in both directions.
;
; Prev. Hist. :	Based on sunglobe_read_fits.pro
;
; History     :	Version 1, William Thompson, 24-Dec-2019, GSFC
;               Version 2, WTT, 8-Jan-2020, add microscope window
;
; Contact     :	WTHOMPSON
;-
;
;==============================================================================
;
;  This routine overplots the location of the solar limb based on the current
;  pointing parameters.
;
pro sunglobe_adj_point_plot_limb, storage
;
;  Extract out the WCS structure.
;
wcs = (*(storage.pimagestate)).wcs
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
pro sunglobe_adj_point_redisplay, data=data
;
;  Extract the STORAGE structure from the widget base, select the graphics
;  window, and redisplay the image.
;
widget_control, data, get_uvalue=storage
setwindow, storage.win
image = (*(storage.pimagestate)).image
expand_tv, image, storage.mx, storage.my, storage.ix, storage.iy, /true
;
;  If there are active fitting points, then replot them.
;
if storage.pfitlist ne !NULL then begin
    wcs = (*(storage.pimagestate)).wcs
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
;  Event handler for the SUNGLOBE_ADJUST_POINTING widget program.
;
pro sunglobe_adj_point_event, ev
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
        (*(storage.pimagestate)).label = label
        widget_control, ev.top, /destroy
    end
;
;  Temporarily plot the current limb location.
;
    'CHECK': begin
        widget_control, ev.top, get_uvalue=storage
        sunglobe_adj_point_plot_limb, storage
        xack, 'Limb position with current pointing values'
        sunglobe_adj_point_redisplay, data=ev.top
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
                sz = size((*(storage.pimagestate)).image)
                sx = sz[2] / float(storage.mx)
                sy = sz[3] / float(storage.my)
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
                sunglobe_adj_point_redisplay, data=ev.top
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
                image = (*(storage.pimagestate)).image
                sz = size(image)
                sx = sz[2] / float(storage.mx)
                sy = sz[3] / float(storage.my)
                x = sx * (ev.x - storage.ix)
                y = sy * (ev.y - storage.iy)
;
;  Extract out a subimage, and display it in the microscope.
;
                x0 = (round(x - storage.micsize/2)) > 0
                x1 = x0 + storage.micsize - 1
                if x1 ge sz[2] then begin
                    x1 = sz[2] - 1
                    x0 = (x1 - storage.micsize + 1) > 0
                endif
                y0 = (round(y - storage.micsize/2)) > 0
                y1 = y0 + storage.micsize - 1
                if y1 ge sz[3] then begin
                    y1 = sz[3] - 1
                    y0 = (y1 - storage.micsize + 1) > 0
                endif
                setwindow, storage.micro
                tv, image[*,x0:x1,y0:y1], /true
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
            sunglobe_adj_point_redisplay, data=ev.top
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
        sunglobe_adj_point_redisplay, data=ev.top
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
        wcs = (*(storage.pimagestate)).wcs
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
        (*(storage.pimagestate)).wcs.crpix = param[0:1] + 1
        (*(storage.pimagestate)).wcs.crval[*] = 0
        (*(storage.pimagestate)).wcs.cdelt = replicate(rsun/param[2], 2)
        sunglobe_adj_point_plot_limb, storage
;
;  Ask if this new pointing should be accepted or not.  If yes, then revert the
;  fitting section to its original desensitized state, and resensitize the "Fit
;  limb" button.
;
        if xanswer('Accept this new pointing?') then begin
            widget_control, /hourglass
            storage.pfitlist = ptr_new()
            storage.pfittext = ptr_new()
            widget_control, storage.wlist, set_value=''
            widget_control, storage.wfitbase, sensitive=0
            widget_control, storage.wfitbtn, sensitive=1
            storage.fitting = 0
;
;  Extract the image and the WCS structure.
;
            image = (*(storage.pimagestate)).image
            wcs = (*(storage.pimagestate)).wcs
;
;  Form the longitude and latitude arrays for the synoptic map.
;
            nx = 2880
            ny = 1440
            lon = (findgen(nx) + 0.5) * 360 / nx
            lat = (findgen(ny) + 0.5) * 180 / ny - 90
            radeg = 180.d0 / !dpi
            lon = rebin(reform(lon,nx,1), nx, ny)
            lat = rebin(reform(lat,1,ny), nx, ny)
;
;  Convert the image into the synoptic map.
;
            wcs_convert_to_coord, wcs, coord, 'hg', lon, lat, /carrington
            pixel = wcs_get_pixel(wcs, coord)
            i = reform(pixel[0,*,*])
            j = reform(pixel[1,*,*])
            w = where(finite(i) and finite(j))
            map = bytarr(3, nx, ny)
            mapmask = bytarr(nx, ny)
            mapmask[w] = 255b
            for k=0,2L do begin
                temp0 = map[k,*,*]
                temp1 = reform(image[k,*,*])
                temp0[w] = temp1[i[w],j[w]]
                map[k,*,*] = temp0
            endfor
            (*(storage.pimagestate)).map = map
            (*(storage.pimagestate)).mapmask = mapmask
;
;  Create a version of the map with an alpha channel, and define the alpha
;  channel based on the mask and opacity.  Form an image object.
;
            sz = size(map)
            map_alpha = bytarr(4,sz[2],sz[3])
            map_alpha[0:2,*,*] = map
            map_alpha[3,*,*] = mapmask * (*(storage.pimagestate)).opacity
            omap_alpha = obj_new('idlgrimage', map_alpha, location=[-1,-1], $
                                 dimension=[2,2], blend_function=[3,4])
            (*(storage.pimagestate)).map_alpha = map_alpha
            (*(storage.pimagestate)).omap_alpha = omap_alpha
;
;  Create dummy rotated versions of MAP and MAPMASK.  These will be updated in
;  SUNGLOBE_DIFF_ROT.
;
            (*(storage.pimagestate)).map_rot = map
            (*(storage.pimagestate)).mapmask_rot = mapmask
            widget_control, hourglass=0
;
;  Otherwise, restore the original WCS structure.
;
        end else begin
            (*(storage.pimagestate)).wcs.crpix = wcs.crpix
            (*(storage.pimagestate)).wcs.crval = wcs.crval
            (*(storage.pimagestate)).wcs.cdelt = wcs.cdelt
        endelse
;
;  Store any new data, and refresh the display.
;
        widget_control, ev.top, set_uvalue=storage
        sunglobe_adj_point_redisplay, data=ev.top
    end
;
;  A value has been entered into the label field.
;
    'LABEL': begin
        widget_control, ev.top, get_uvalue=storage
        widget_control, storage.wlabel, get_value=label
        (*(storage.pimagestate)).label = label
        widget_control, ev.top, set_uvalue=storage
    end
;
;  The Help button has been selected.
;
    'HELP': widg_help, 'sunglobe_adjust_pointing.hlp', /hierarchy, $
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
pro sunglobe_adjust_pointing, pimagestate, group_leader=group_leader
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
                    title='SUNGLOBE_ADJUST_POINTING')
;
;  On the left side, set up a top row of buttons.
;
winbase = widget_base(wmain, /column)
wmenu = widget_base(winbase, /row)
wchkbtn = widget_button(wmenu, value='Check pointing', uvalue='CHECK')
wfitbtn = widget_button(wmenu, value='Fit limb', uvalue='LIMB')
dummy = widget_button(wmenu, value='Help', uvalue='HELP')
dummy = widget_button(wmenu, value='Exit', uvalue='EXIT')
;
;  Set up a widget for the image label.
;
wlabel = cw_field(winbase, title='Image label:', value='', uvalue='LABEL', $
                  xsize=40, /noedit)
;
;  Set up a draw widget.
;
device, get_screen_size = screenSize
xsize = min(screensize[0:1]) * 0.5
ysize = xsize                   ;Keep isotropic
wdraw = widget_draw(winbase, xsize=xsize, ysize=ysize, uvalue='DRAW', $
                    /motion_events, /button_events, /tracking_events, retain=2)
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
storage = {win: win, $
           micro: micro, $
           pimagestate: pimagestate, $
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
;
;  Use SCALE_TV to scale the image to the window, and EXPAND_TV to display it.
;
setwindow, storage.win
image = (*(storage.pimagestate)).image
scale_tv, image, mx, my, ix, iy, /noexact, /nobox, /true
expand_tv, image, mx, my, ix, iy, /true
storage.mx = mx
storage.my = my
storage.ix = ix
storage.iy = iy
widget_control, wmain, set_uvalue=storage
;
;  Populate the label widget.
;
label = (*(storage.pimagestate)).label
widget_control, storage.wlabel, set_value=label
;
;  Start everything going.
;
xmanager, 'sunglobe_adjust_pointing', wmain, /no_block, $
  event_handler='sunglobe_adj_point_event'
;
end
