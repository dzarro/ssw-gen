
;+
; NAME:
;      PIXEL_MASK_GUI
;
; PURPOSE:
;      Create a pixel mask for a 2D image.
;
; CATEGORY:
;      Image processing.
;
; CALLING SEQUENCE: 
;      Result = PIXEL_MASK_GUI( Image )
;
; INPUTS:
;      Map:   Can be either a 2D image, or an IDL map structure
;             containing a 2D image. If you are using Hinode/EIS data,
;             then you should create the map with EIS_MAKE_IMAGE (with
;             /map keyword) otherwise you will need to set the SLIT
;             and WVL optional inputs (see below).
;
; OPTIONAL INPUTS:
;      Slit:  The size of the EIS slit. Should be either 1 or 2 for
;             the 1" or 2" slit, respectively. Note that this input is
;             not necessary if MAP has been created with EIS_MAKE_IMAGE.
;      Wvl:   The wavelength for which the image was created. Note
;             that this input is not necessary if MAP has been created
;             with EIS_MAKE_IMAGE.
;      Mask:  A mask structure created from a previous call to
;             PIXEL_MASK_GUI. Must have the same size images as the
;             input MAP.
;      Dx:    Specify the X-pixel size of the input image (not needed
;             if a map structure was input).
;      Dy:    Specify the Y-pixel size of the input image (not needed
;             if a map structure was input).
;      Yshift: If MASK has been input, then this keyword shifts the
;              mask pixels in the Y-direction. For example, setting
;              yshift=+100 will move the mask pixels upwards by 100
;              pixels. You may "lose" pixels when doing this, and a
;              warning will be printed to the screen.
;
; OUTPUTS:
;      The routine will return a 2D byte array containing 0's and 1's,
;      with 1 indicating the pixel has been selected by the user. The
;      array has the same size as the input array.
;
;      In order to be compatible with the original EIS_PIXEL_MASK
;      routine (see notes below), the routine will return a different
;      output if the WVL and SLIT keywords have been specified (or if
;      these tags are present in the input map structure). In this
;      case a structure will be returned with the following tags:
;        .image   A 2D byte array containing 0's and 1's (i.e., the
;                 pixel mask).
;        .wvl     The wavelength to which the mask belongs.
;        .slit    Integer giving the EIS slit size (should be 1 or 2).
;        .id      This is copied from the map structure (if
;                 available).
;        .time_stamp  Time at which mask was created.
;
;      If a problem is found, then a value of -1 (integer) will be
;      returned. 
;
; INTERNAL ROUTINES:
;      PIXMASK_COLTABLE, PIXMASK_PAINTING, PIXMASK_POLY_POINTS,
;      PIXMASK_DRAWBOX, PIXMASK_GET_TICKV, PIXMASK_YTICKS,
;      PIXMASK_XTICKS, PIXMASK_OPLOT_MASK, PIXMASK_PLOT_IMAGE,
;      PIXMASK_FONT, PIXMASK_BASE_EVENT, PIXMASK_WIDGET
;
; PROGRAMMING NOTES:
;      I originally wrote a routine for creating a pixel mask called
;      EIS_PIXEL_MASK that was specifically intended for data from the
;      Hinode/EIS instrument. The output was a structure containing
;      the mask and additional data.
;
;      To make the new routine more generally useful I allow it to
;      accept any 2D image or map structure, and the output will be a
;      2D image mask *unless* the routine determines that it is using
;      an EIS image.
;
; EXAMPLE:
;      For EIS data, the commands below create an image at 195.12
;      angstroms and store it in a map. The user then creates the
;      pixel mask and passes it to eis_mask_spectrum which generates a
;      spectrum averaged over the mask.
;      IDL> eis_make_image, filename, 195.12, map, /map
;      IDL> mask=pixel_mask_gui(map)
;      IDL> eis_mask_spectrum,filename,mask,swspec=swspec,lwspec=lwspec
;
;      For AIA data, we read a cutout image into data and then create
;      a mask:
;      IDL> read_sdo, filename, index, data
;      IDL> mask=pixel_mask_gui(data)
;
;      One can also read the AIA data into a map and call the routine
;      as:
;      IDL> read_sdo, filename, index, data
;      IDL> index2map, index, data, map
;      IDL> mask=pixel_mask_gui(map)
;
; MODIFICATION HISTORY:
;      Ver.1, 26-Jun-2017, Peter Young
;        This is a widget-based version of the original
;        eis_pixel_mask.
;      Ver.2, 27-Jun-2017, Peter Young
;        Modified so that it works on any 2D image or map.
;      Ver.3, 28-Jun-2017, Peter Young
;        Final adjustments to output and header.
;      Ver.4, 21-Aug-2019, Peter Young
;        Added MASK= optional input.
;      Ver.5, 29-Jan-2020, Peter Young
;        Added YSHIFT= keyword.
;-


;-------------------
PRO pixmask_coltable, desc=desc, state=state, set_value=set_value
;
; This provides the list of color tables for the color pull-down menu
; (output 'desc'). It also sets the color table if 'state' and
; 'set_value' are specified.
;
; **Be careful when adding new color tables. Need to update 'desc' and
; **the if statements.

;
; This determines if the user has the aia_lct routine.
;
swtch=have_proc('aia_lct')

desc=['1\COLOR', $
      '0\B+W','0\Blue','0\Red']

IF have_proc('aia_lct') THEN BEGIN
  desc=[desc,'0\Std-Gamma','2\AIA 193']
ENDIF ELSE BEGIN
  desc=[desc,'2\Std-Gamma']
ENDELSE 

n_ct=n_elements(desc)

IF n_tags(state) NE 0 AND n_elements(set_value) NE 0 THEN BEGIN
  state.wid_data.coltable=set_value
  widget_control,state.pixmask_base,set_uvalue=state
 ;
  IF set_value EQ 0 THEN loadct,0
  IF set_value EQ 1 THEN loadct,1
  IF set_value EQ 2 THEN loadct,3
  IF set_value EQ 3 THEN loadct,5
  IF set_value EQ 4 THEN aia_lct,r,g,b,wavelnth=193,/load
ENDIF 

END


;-------------------
PRO pixmask_painting, event, state, wid
;
; This code is based on the drawbox code (see below). As the user
; holds down the mouse button, the mask pixels are continually updated
; and over-plotted on the background image (which is static due to the
; use of the device-copy command). A difference is that I have to
; update mask when the mouse button is released for the case when the
; user just wants to select a single pixel.
;
xscale=state.wid_data.scale[0]
yscale=state.wid_data.scale[1]

;
; Clicking-and-holding the mouse button sets paint_flag to
; 1. Releasing the mouse button sets it back to zero (it's
; normal state). 
;
paint_flag=state.wid_data.paint_flag

;
; If paint_mode is 0 then points will be added to the mask. If 1 then
; they will be removed from the mask.
;
paint_mode=state.wid_data.paint_mode

CASE 1 OF
 ;
 ; This responds to the initial mouse button press by plotting the
 ; background image and copying it using the device command.
 ;
  event.press EQ 1 AND paint_flag EQ 0: BEGIN
    state.wid_data.paint_flag=1
    pixmask_plot_image, state
    Window, /Pixmap, /Free, XSize=state.box.xsiz, YSize=state.box.ysiz
    state.box.pixid = !D.Window
    Device, Copy=[0, 0, state.box.xsiz, state.box.ysiz, 0, 0, wid]
    wset,wid
    widget_control,state.pixmask_base,set_uvalue=state
  END
 ;
 ; This responds to the mouse being dragged across the image
 ; (painting) and the mouse button release event. The mask image tag
 ; is continually updated until the mouse button is released
 ; (paint_flag=0). 
 ;
  (event.release EQ 1 AND paint_flag EQ 1) OR paint_flag EQ 1: BEGIN
    IF (event.release EQ 1 AND paint_flag EQ 1) THEN state.wid_data.paint_flag=0
    result=convert_coord(event.x, $
                         event.y,/device,/to_data)
    xpix=round(result[0]/xscale)
    ypix=round(result[1]/yscale)
    xpos=xpix*xscale
    ypos=ypix*yscale
    IF paint_mode EQ 1 THEN state.data.mask[xpix,ypix]=0b ELSE state.data.mask[xpix,ypix]=1b
    Device, Copy=[0, 0, state.box.xsiz, state.box.ysiz, 0, 0, state.box.pixid]
    pixmask_oplot_mask, state
    widget_control,state.pixmask_base,set_uvalue=state
  END
  ELSE: 
ENDCASE 

END


;----------------------
PRO pixmask_poly_points, event, state
;
; This responds to the user's mouse clicks as he/she selects
; the vertices of the polygon. With each click a new entry is added to
; state.poly_list (an IDL list).
;
xscale=state.wid_data.scale[0]
yscale=state.wid_data.scale[1]

IF event.release EQ 1 THEN BEGIN
  result=convert_coord(event.x, $
                       event.y,/device,/to_data)
  xpix=round(result[0]/xscale)
  ypix=round(result[1]/yscale)
  xpos=xpix*xscale
  ypos=ypix*yscale
  plots,xpos,ypos,psym=1,symsiz=2
  plots,xpos,ypos,psym=7,symsiz=2,col=0
  state.poly_list.add,[xpix,ypix]
ENDIF 

END 


;----------------
PRO pixmask_drawbox, event, state, wid
;
; This is the event handler that deals with the Zoom option for the
; images. It draws a rubber-band box
;
xscale=state.wid_data.scale[0]
yscale=state.wid_data.scale[1]

CASE 1 OF
 ;
 ; The event begins with a mouse press-and-hold, which sets flag to 1.
 ;
  event.press EQ 1 AND state.box.flag EQ 0: BEGIN
    state.box.flag=1
    state.box.x0=event.x
    state.box.y0=event.y
    state.box.wid=wid
    wset,wid
    pixmask_plot_image, state, /oplot
    Window, /Pixmap, /Free, XSize=state.box.xsiz, YSize=state.box.ysiz
    state.box.pixid = !D.Window
    Device, Copy=[0, 0, state.box.xsiz, state.box.ysiz, 0, 0, wid]
    wset,wid
    widget_control,state.pixmask_base,set_uvalue=state
  END
 ;
 ;
 ; When the mouse button is released, the zoom box is finalized and the
 ; pixel coordinates are stored in wid_data.prange_x, prange_y. Flag
 ; is set back to 0.
 ;
  event.release EQ 1 AND state.box.flag EQ 1: BEGIN
    WDelete, state.box.pixid
    state.box.flag=0
    state.box.x1=event.x
    state.box.y1=event.y
    widget_control,state.pixmask_base,set_uvalue=state
    result=convert_coord([state.box.x0,state.box.x1], $
                         [state.box.y0,state.box.y1],/device,/to_data)

    xra=[result[0,0],result[0,1]]
    xra=xra[sort(xra)]
    xpix0=max([round(xra[0]/xscale),0])
    xpix1=min([round(xra[1]/xscale),state.data.nx-1])
    state.wid_data.prange_x=[xpix0,xpix1]

    yra=[result[1,0],result[1,1]]
    yra=yra[sort(yra)]
    ypix0=max([round(yra[0]/yscale),0])
    ypix1=min([round(yra[1]/yscale),state.data.ny-1])
    state.wid_data.prange_y=[ypix0,ypix1]

    widget_control,state.pixmask_base,set_uvalue=state
    pixmask_plot_image, state, /oplot
  END
 ;
 ;
 ; While the mouse button is being held, we continually redraw the box
 ; on the image. The use of device,/copy means that the image is not
 ; continually re-drawn along with the box.
 ; 
  state.box.flag EQ 1: BEGIN
    Device, Copy=[0, 0, state.box.xsiz, state.box.ysiz, 0, 0, state.box.pixid]
    PlotS, [state.box.x0, state.box.x0, event.x, event.x, state.box.x0], $
         [state.box.y0, event.y, event.y, state.box.y0, state.box.y0], $
         /Device
  END
  
  ELSE: 
  
ENDCASE

END


;-------------------------
FUNCTION pixmask_get_tickv, r, scale, n=n, tsep=tsep
;
; This retrieves the tick values ([x,y]tickv) for use in pixmask_plot_image
; when scale is not 1. The optional outputs n and tsep are used to get
; the values of [x,y]ticks and [x,y]minor
;
d=r[1]-r[0]+1
CASE 1 OF
  d GE 250: tsep=50.
  d GE 100: tsep=10.
  d GE 45: tsep=5.
  d GE 9: tsep=2.
  ELSE: tsep=1.
ENDCASE 
p0=ceil(r[0]/tsep)
p1=floor(r[1]/tsep)
n=p1-p0+1
return,(findgen(n)*tsep+r[0])*scale

END


;----------------------
function pixmask_yticks, axis, index, value
;
; This converts the Y-axis to pixels rather than arcsec (see
; pixmask_plot_image). 
;
COMMON pm_ticks, xscale, yscale
return,trim(round(value/yscale))
END

;----------------------
function pixmask_xticks, axis, index, value
;
; This converts the X-axis to pixels rather than arcsec (see
; pixmask_plot_image). 
;
COMMON pm_ticks, xscale, yscale
return,trim(round(value/xscale))
END


;---------------------
PRO pixmask_oplot_mask, state
;
; Overplots the pixel mask on the image. Note that I plot two points,
; one white, one black, to aid viewing in light and dark areas.
;
mask=state.data.mask
show_mask=state.wid_data.show_mask
xr=state.wid_data.prange_x
yr=state.wid_data.prange_y
xscale=state.wid_data.scale[0]
yscale=state.wid_data.scale[1]
;
IF max(mask) EQ 1 AND show_mask EQ 1 THEN BEGIN
  k=where(mask EQ 1,nk)
  locs=array_indices(mask,k)
  xpos=locs[0,*]
  ypos=locs[1,*]
  ip=where(xpos GE xr[0] AND xpos LE xr[1] AND ypos GE yr[0] AND ypos LE yr[1],np)
  IF np NE 0 THEN BEGIN
    sq=1.5
    usersym,[-1,1,1,-1]*sq,[-1,-1,1,1]*sq,/fill
    plots,xpos[ip]*xscale,ypos[ip]*yscale,psym=1,symsize=2
    plots,xpos[ip]*xscale,ypos[ip]*yscale,psym=7,symsize=2,col=0
  ENDIF 
ENDIF 

END


;---------------------
PRO pixmask_plot_image, state, oplot=oplot
COMMON pm_ticks, xscale, yscale

image=state.data.image
xr=state.wid_data.prange_x
yr=state.wid_data.prange_y

image=image[xr[0]:xr[1],yr[0]:yr[1]]
scale=state.wid_data.scale
xscale=scale[0]
yscale=scale[1]
origin=[xr[0]*xscale,yr[0]*yscale]

;
; The following is required to handle the conversion between pixels
; and data coordinates in the cases that the X-scale or Y-scale are
; not 1.
;
IF xscale NE 1. THEN BEGIN 
  xtickv=pixmask_get_tickv(xr,xscale,n=n,tsep=tsep)
  xticks=n-1
  xminor=min([round(tsep),5])
ENDIF 
;
IF yscale NE 1. THEN BEGIN 
  ytickv=pixmask_get_tickv(yr,yscale,n=n,tsep=tsep)
  yticks=n-1
  yminor=min([round(tsep),5])
ENDIF 

plot_image,image,scale=scale,origin=origin,charsiz=1.5, $
           xtickformat='pixmask_xticks', $
           ytickformat='pixmask_yticks', $
           xtitle='X (pixels)', $
           ytitle='Y (pixels)', $
           xtickv=xtickv,xticks=xticks,xminor=xminor, $
           ytickv=ytickv,yticks=yticks,yminor=yminor

IF keyword_set(oplot) THEN pixmask_oplot_mask, state


END


;------------------
PRO pixmask_font, font, big=big, med=med, fixed=fixed
;+
;  Defines the fonts to be used in the widgets. Allows for Windows and Unix 
;  operating systems.
;-
CASE !version.os_family OF

  'unix': BEGIN
    IF keyword_set(fixed) THEN fstr='-*-courier-' ELSE $
       fstr='-adobe-helvetica-'
    CASE 1 OF
      keyword_set(big): str='18'
      keyword_set(med): str='14'
      ELSE: str='12'
    ENDCASE 
    font=fstr+'bold-r-*-*-'+str+'-*'
  END

  ELSE: BEGIN
    IF keyword_set(fixed) THEN fstr='Courier' ELSE $
         fstr='Arial'
    CASE 1 OF
      keyword_set(big): str='20'
      keyword_set(med): str='18'
      ELSE: str='16'
    ENDCASE 
    font=fstr+'*bold*'+str
  END

ENDCASE

END


;---------------------
PRO pixmask_base_event, event
;
; This is the event handler for the GUI.
;
WIDGET_CONTROL,Event.top, get_uvalue=state

CASE event.id OF

  state.pixmask_options: BEGIN
   ;
   ; This responds to the user clicking on one of the three mouse options
   ; (Zoom, Poly, Paint). Clicking on either of Poly or Paint results
   ; in a sub-widget being sensitized giving additional options.
   ;
    state.wid_data.options=event.value
    IF event.value EQ 2 THEN widget_control,state.paint_base,sens=1 $
    ELSE widget_control,state.paint_base,sens=0
    IF event.value EQ 1 THEN widget_control,state.poly_base,sens=1 $
    ELSE widget_control,state.poly_base,sens=0
    widget_control,state.pixmask_base,set_uvalue=state
  END 
  
  state.paint_options: BEGIN
   ;
   ; This responds to the painting options (add/delete points).
   ;
    state.wid_data.paint_mode=event.value
    widget_control,state.pixmask_base,set_uvalue=state
    pixmask_plot_image, state, /oplot
  END 

  state.poly_button: BEGIN
   ;
   ; This is the response to the 'Close polygon' button.
   ;
    n=state.poly_list.count()
    IF n LT 3 THEN BEGIN
      pixmask_font,font
      xpopup,'Please select at least 3 points before closing the polygon', $
             tfont=font,bfont=font,xsiz=70           
    ENDIF ELSE BEGIN 
      xy=intarr(n,2)
      FOR i=0,n-1 DO xy[i,*]=state.poly_list[i]
      nx=state.data.nx
      ny=state.data.ny
     ;
     ; Polyfillv has the quirk that it creates a polygon with an area
     ; defined by the pixel centers of the outer boundary. This means
     ; that it doesn't select all the pixels that the user
     ; expects. Specifically pixels on the top and left boundaries are
     ; missing.
     ;
      ind=polyfillv(xy[*,0],xy[*,1],nx,ny)
      state.data.mask[ind]=1b
      state.poly_list=list()   ; reset the list of vertices
      widget_control,state.pixmask_base,set_uvalue=state
      pixmask_plot_image, state, /oplot
    ENDELSE 
    
  END 
  
  state.plot: BEGIN
   ;
   ; This handles the events generated when the user clicks/moves the
   ; mouse over the displayed image. The response depends on the mouse
   ; options (0-Zoom, 1-Poly, 2-Paint).
   ;
    CASE state.wid_data.options OF
     ;
     ; This is the ZOOM option
     ;
      0: BEGIN 
        widget_control,state.plot,draw_motion_events=1
        pixmask_drawbox, event, state, state.wid_data.im_id
      END
     ;
     ; This is the polygon option
     ;
      1: BEGIN
        widget_control,state.plot,draw_motion_events=1
        pixmask_poly_points, event, state
      END 
     ;
     ; This is the painting option
     ;
      2: BEGIN
        widget_control,state.plot,draw_motion_events=1
        pixmask_painting, event, state, state.wid_data.im_id

      END 
    ENDCASE 
  END
  
  state.exit: BEGIN
   ;
   ; These are the big buttons at the top of the GUI.
   ;
    CASE event.value OF
     ;
     ; EXIT
     ; ----
      0: BEGIN
       ;
       ; Here I save the mask image to a temporary save file. When the
       ; widget is closed, this file is read and the image stored in
       ; the output.mask tag.
       ;
        outfile=concat_dir('IDL_TMPDIR','image.save')
        mask_image=state.data.mask
        save,file=outfile,mask_image
        widget_control, event.top, /destroy
      END 
     ;
     ; Unzoom the image back to the original size
     ; ------
      1: BEGIN
        state.wid_data.prange_x=[0,state.data.nx-1]
        state.wid_data.prange_y=[0,state.data.ny-1]
        widget_control,state.pixmask_base,set_uvalue=state
        pixmask_plot_image, state, /oplot
      END
     ;
     ;
     ; Reset option (set mask to all zeros)
     ; -----
      2: BEGIN
        state.data.mask=0b
        state.poly_list=list()
        widget_control,state.pixmask_base,set_uvalue=state
        pixmask_plot_image, state, /oplot        
      END
     ;
     ; Color tables
     ; ------------
      ELSE: BEGIN
        new_coltable=event.value-4
        coltable=state.wid_data.coltable
        IF coltable NE new_coltable THEN BEGIN
          pixmask_coltable,state=state,set_value=new_coltable
         ;
          pixmask_plot_image, state, /oplot        
        ENDIF  
      END 
      
    ENDCASE
  END
ENDCASE 

END


;---------------------
PRO pixmask_widget, data

pixmask_font,font
pixmask_font,medfont,/med
pixmask_font,bigfont,/big
pixmask_font,fixfont,/fixed

;
; Get initial pixel ranges (prange) for plot
;
prange_x=[0,data.nx-1]
prange_y=[0,data.ny-1]

;
; Get image scaling
;
scale=[data.dx,data.dy]


wid_data={ prange_x: prange_x, $
           prange_y: prange_y, $
           image_id: 0, $
           options: 0, $
           im_id: 0, $
           scale: scale, $
           paint_flag: 0, $
           paint_mode: 0, $
           show_mask: 1, $
           coltable: 0}

pixmask_base=widget_base(/row,map=1,title='PIXEL_MASK_GUI')

control_base=widget_base(pixmask_base,/col,map=1)

;pixmask_exit=widget_button(control_base,value='EXIT',font=bigfont)

pixmask_coltable,desc=desc
desc=['0\EXIT','0\UNZOOM','0\RESET',desc]
pixmask_exit=cw_pdmenu(control_base,desc,font=bigfont)

options_base=widget_base(control_base,map=1,frame=1,/col)
pixmask_options=cw_bgroup(options_base,set_value=wid_data.options, $
                ['Zoom','Polygon mode','Painting mode'], $
                /col,font=medfont,/exclusive,/no_release,label_top='Mouse options')

poly_base=widget_base(control_base,map=1,frame=1,sens=0,/col)
poly_label=widget_label(poly_base,value='Polygon options',font=medfont)
poly_button=widget_button(poly_base,value='Close polygon',font=medfont)

paint_base=widget_base(control_base,map=1,frame=1,sens=0)
paint_options=cw_bgroup(paint_base,set_value=wid_data.paint_mode, $
                        ['Add points','Delete points'], $
                        /col,font=medfont,/exclusive,/no_release, $
                        label_top='Painting options')


plot_base=widget_base(pixmask_base,/col,map=1)

xsiz=700
ysiz=700
pixmask_plot=widget_draw(plot_base,xsiz=xsiz,ysiz=ysiz,/sens, $
                    /button_events,/motion_events)

;
; Structure for defining the rubber-band box used for selecting sub-images
;
box={flag: 0, wid: 0, x0: 0, y0: 0, x1:0, y1:0, $
     xsiz:xsiz, ysiz: ysiz, pixid:0}



state={pixmask_base: pixmask_base, $
       exit: pixmask_exit, $
       plot: pixmask_plot, $
       data: data, $
       wid_data: wid_data, $
       pixmask_options: pixmask_options, $
       box: box, $
       paint_options: paint_options, $
       paint_base: paint_base, $
       poly_base: poly_base, $
       poly_button: poly_button, $
       poly_list: list() }


WIDGET_CONTROL, pixmask_base, /REALIZE, set_uvalue=state

widget_control,pixmask_plot,get_value=image_id
widget_control,state.plot,draw_motion_events=0

wid_data.im_id=image_id

state.wid_data=wid_data
widget_control,pixmask_base,set_uvalue=state

pixmask_plot_image, state, /oplot

XMANAGER, 'pixmask_base', pixmask_base, group=group


END


;----------------------
FUNCTION pixel_mask_gui, map, slit=slit, wvl=wvl, dx=dx, dy=dy, mask=mask, $
                         yshift=yshift


IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> mask=pixel_mask_gui(map [, slit=, wvl=, dx=, dy=, yshift= ])'
  print,'   map -  either a 2D image, or an IDL map structure'
  print,'   slit - only relevant for Hinode/EIS data; should be 1 or 2'
  print,'   wvl  - only relevant for Hinode/EIS data'
  print,'   dx   - X-scale for image'
  print,'   dy   - Y-scale for image'
  print,'   mask - Input a previously-created mask to use as starting point.'
  print,'   yshift - Y-pixel shift to apply to the input mask.'
  return,-1
ENDIF 


;
; The following checks if we have a map or an image.
;
IF n_tags(map) EQ 0 THEN BEGIN
  s=size(map)
  IF s[0] NE 2 THEN BEGIN
    print,'%EIS_PIXEL_MASK: the input MAP should be either an IDL map structure, or a 2D image. Returning...'
    return,-1
  ENDIF
  image=map
  nx=s[1]
  ny=s[2]
  IF n_elements(dx) EQ 0 THEN dx=1.0
  IF n_elements(dy) EQ 0 THEN dy=1.0
ENDIF ELSE BEGIN
  image=map.data
  s=size(image,/dim)
  nx=s[0]
  ny=s[1]
  dx=map.dx
  dy=map.dy
 ;
 ; Here I access the slit used for the observation (only applies to
 ; EIS).
 ;
  IF tag_exist(map,'slit_ind') THEN BEGIN
    slit_ind=map.slit_ind
    CASE slit_ind OF
      0: slit=1
      2: slit=2
      ELSE: BEGIN
        print,'%EIS_PIXEL_MASK: The image is from a slot data-set and is not compatible with this routine. Returning...'
        return,-1
      END
    ENDCASE 
  ENDIF 
 ;
 ; Here I access the wavelength for the image (only applies to EIS).
 ; 
  IF tag_exist(map,'wvl') THEN wvl=map.wvl
ENDELSE 

;
; Check if MASK has been input and make sure it has the right format.
; 
IF n_elements(mask) NE 0 THEN BEGIN
  s=size(mask.image,/dim)
  IF s[0] NE nx OR s[1] NE ny THEN BEGIN
    print,'% PIXEL_MASK_GUI: the dimensions of the input MASK image do not match those of the image. Returning...'
    return,-1
  ENDIF
  IF min(mask.image) LT 0 OR max(mask.image) GT 1 THEN BEGIN
    print,"% PIXEL_MASK_GUI: the input MASK image must contain only 0's AND 1's. Returning..."
    return,-1
  ENDIF
  mask_image=mask.image
 ;
 ; Performs a Y-shift of the input pixel mask.
 ;
  IF n_elements(yshift) NE 0 THEN BEGIN
    IF abs(yshift) lt ny THEN BEGIN 
      im=bytarr(nx,ny)
      IF yshift GE 0 THEN BEGIN
        im[*,yshift:*]=mask_image[*,0:(ny-yshift-1)]
      ENDIF ELSE BEGIN
        im[*,0:(ny+yshift-1)]=mask_image[*,-yshift:*]
      ENDELSE
      chck=where(im EQ 1,n1)
      chck=where(mask_image EQ 1,n2)
      IF n1 NE n2 THEN BEGIN
        print,'% PIXEL_MASK_GUI: Warning - the shifted mask has less pixels than the original mask.'
      ENDIF 
      mask_image=im
    ENDIF 
  ENDIF 
ENDIF ELSE BEGIN
  mask_image=bytarr(nx,ny)
ENDELSE 


IF n_elements(wvl) EQ 0 THEN wvl=-1.
IF n_elements(slit) EQ 0 THEN slit=-1

;
; If eis_swtch=1, then the output is a structure; otherwise an image.
;
IF wvl NE -1 AND slit NE -1 THEN eis_swtch=1 ELSE eis_swtch=0


;
; This structure contains information about the image that is passed
; to the GUI.
;
data={image: image, slit: round(slit), wvl: wvl, mask: mask_image, nx: nx, ny: ny, $
      dx: dx, dy: dy}


;
; This is the call to start up the GUI.
;
pixmask_widget, data

;
; Closing the GUI creates this temporary save file containing the mask
; that I now restore back to IDL.
;
infile=concat_dir('IDL_TMPDIR','image.save')
chck=file_search(infile,count=count)
IF count EQ 0 THEN mask_image=data.mask ELSE restore,chck

;
; Create the output.
;
IF eis_swtch EQ 1 THEN BEGIN
  IF n_tags(map) NE 0 THEN id=map.id
  output={ image: mask_image, $
           wvl: data.wvl, $
           slit: data.slit, $
           id: id, $
           time_stamp: systime()}
ENDIF ELSE BEGIN
  output=mask_image
ENDELSE 

return,output

END
