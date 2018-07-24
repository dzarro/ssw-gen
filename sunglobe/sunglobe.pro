;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE
;
; Purpose     :	3D Sun pointing tool
;
; Category    :	Object graphics, 3D, Planning, Widget
;
; Explanation : Widget program using object graphics to manipulate a 3D Sun,
;               with eventual application to a pointing tool for the SPICE
;               instrument on Solar Orbiter.
;
; Syntax      :	SUNGLOBE
;
; Examples    :	SUNGLOBE
;               SUNGLOBE, '2012-11-23 15:38', TEST=10
;
;               See also sunglobe_demo.pro for an demonstration of how SUNGLOBE
;               can be called from another widget program, with events passed
;               back and forth.
;
; Inputs      :	None required
;
; Opt. Inputs :	TARGET_DATE = The target date/time for selecting images.  If not
;                             passed, the present date/time is used.
;
; Outputs     :	None
;
; Opt. Outputs:	None
;
; Keywords    :	GROUP_LEADER   = Widget ID of group leader calling SUNGLOBE
;
;               TOPBASE = Returns the top level base ID
;
;               SENDBASE= Returns a widget ID that events can be sent to via
;
;                               WIDGET_CONTROL, sendbase, SEND_EVENT={...}
;
;                         See sunglobe_event.pro for more information about the
;                         kind of events that can be sent, and how to send
;                         them.
;
;               RETURNID= Widget ID in the group leader that events can be sent
;                         to via
;
;                               WIDGET_CONTROL, sendbase, SEND_EVENT={...}
;
;                         This should be the ID of a widget that does not
;                         otherwise take events, and whose UVALUE can be
;                         overridden.  See sunglobe_event.pro for more
;                         information about the kind of events that can be
;                         returned.
;
;               ORBSIZE =  A floating point number representing the distance in
;                          degrees between orb vertices.  The default is 5.
;
;               SPACECRAFT = The name of the spacecraft whose ephemeris
;                            information will be used.  Default is "Solar
;                            Orbiter".  Can also specify "Earth" for
;                            ground-based or in orbit observatories.
;
;               EARTH   = Shortcut for SPACECRAFT='Earth'.
;
;               TEST_OFFSET = Number of years to offset from the current date
;                             to make it look like Orbiter has already
;                             launched for ephemeris purposes.  For example,
;                             setting TEST_OFFSET=8 will treat dates in 2016 as
;                             if they were 2024 when referencing the ephemeris.
;
;               MAXIMAGES = Maximum number of images which can be read in.
;                           Default is 1, since SUNGLOBE is now able to create
;                           spaces for new images on the fly.
;
; Calls       :	SUNGLOBE_MAKE_OBJECTS, SUNGLOBE_MAKE_IMAGE_WIDGETS,
;               SUNGLOBE_LOAD_EPHEM, SUNGLOBE_SPICE_FOV__DEFINE
;
; Common      :	None
;
; Restrictions:	None
;
; Side effects:	None
;
; Prev. Hist. :	Based on d_globe.pro in the IDL examples directory.
;
; History     :	Version 1, 20-Jan-2016, William Thompson, GSFC
;               Version 2, 04-Apr-2016, WTT, moved SUNGLOBE_MAKE_IMAGE_WIDGETS
;                                            to show startup text earlier.
;               Version 3, 04-Aug-2016, WTT, change load ephemeris call
;                       Add SPACECRAFT keyword.
;               Version 4, 26-Aug-2016, WTT, pass SPACECRAFT to load routine
;                       FOV options depend on SPACECRAFT
;               Version 5, 2-Sep-2016, WTT, added HPC button, orbit trace
;               Version 6, 11-Nov-2016, WTT, add save/restore options
;               Version 7, 18-Nov-2016, WTT, add keyword MAXIMAGES
;                                            check if SunSPICE is loaded
;               Version 8, 22-Nov-2016, WTT, add keyword /EARTH
;               Version 9, 30-Nov-2016, WTT, renamed GROUP to GROUP_LEADER
;               Version 10, 01-Aug-2017, WTT, add JPEG option
;                       Rename HPC button to CONVERT
;                       Move send point option to SUNGLOBE_CONVERT subwidget
;               Version 11, 05-Mar-2018, WTT, add magnetic connection point
;               Version 12, 02-Apr-2018, WTT, unbounded number of images
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe, date, group_leader=group_leader, topbase=wtopbase, $
              test_offset=test_offset, sendbase=wsubbase, returnid=returnid, $
              spacecraft=k_spacecraft, earth=earth, maximages=maximages, $
              _extra=_extra
;
on_error, 2
if n_elements(test_offset) eq 0 then test_offset = 0
if n_elements(returnid) eq 0 then returnid = 0L
if n_elements(k_spacecraft) eq 1 then spacecraft = k_spacecraft
if keyword_set(earth) and (n_elements(spacecraft) eq 0) then $
  spacecraft = 'Earth'
if n_elements(spacecraft) eq 0 then spacecraft = "Solar Orbiter"
which,'parse_sunspice_name',/quiet,out=temp
if temp ne '' then spacecraft = parse_sunspice_name(spacecraft)
;
;  Check the validity of the target date.
;
if n_elements(date) eq 0 then get_utc, target_date, /ccsds else begin
    errmsg = ''
    target_date = anytim2utc(date, /ccsds, errmsg=errmsg)
    if errmsg ne '' then message, errmsg
endelse
;
;  Check the validity of the group identifier.
;
ngroup=n_elements(group_leader)
if (ngroup ne 0) then begin
    check = widget_info(group_leader, /valid_id)
    if (check NE 1) then message, 'The group identifier is not valid'
    groupbase = group_leader
endif else groupbase = 0L
;
;  Get the screen size, and use this to define the size of the graphics window.
;
device, get_screen_size = screenSize
xsize = min(screensize[0:1]) * 0.75
ysize = xsize                     ;Keep isotropic
;
;  Construct all base widgets.
;
wtopbase = widget_base(title='SunGlobe', xpad=0, ypad=0, $
            /tlb_kill_request_events, group_leader=group_leader, $
            /column, tlb_frame_attr=1, mbar=barbase)
;
;  Create the buttons in the menu bar.  Define the File pull-down menu.
;
wfilemenu = widget_button(barbase, value='File')
waddhv = widget_button(wfilemenu, value='Read in Helioviewer image', $
                       UVALUE='ADDHV')
wgetpfss = widget_button(wfilemenu, value='Read in PFSS magnetic field', $
                         UVALUE='GETPFSS')
wgetconnect = widget_button(wfilemenu, uvalue='GETCONNECT', $
                            value='Estimate magnetic connection point')
wsave = widget_button(wfilemenu, value='Save images', UVALUE='SAVE')
wrestore = widget_button(wfilemenu, value='Restore images', $
                         UVALUE='RESTORE')
wjpeg = widget_button(wfilemenu, value='Write JPEG', uvalue='JPEG')
wquit  = widget_button(wfilemenu, value='Quit', uvalue='QUIT')
;
;  Define the Actions pull-down menu.
;
wactionbutton = widget_button(barbase, value='Actions')
wzeroroll = widget_button(wactionbutton, value='Reset roll angle', $
                          uvalue='ZEROROLL')
wresetorient = widget_button(wactionbutton, value='Reset orientation', $
                             uvalue='RESETORIENT')
wresetcenter = widget_button(wactionbutton, value='Reset center', $
                             uvalue='RESETCENTER')
wresetzoom = widget_button(wactionbutton, value='Reset zoom', $
                           uvalue='RESETZOOM')
wresetpoint = widget_button(wactionbutton, value='Reset pointing', $
                            uvalue='RESETSCPOINT')
wresetbutton = widget_button(wactionbutton, value='Reset all', $
                             uvalue='RESET')
;
;  Define the Configure pull-down menu.
;
wconfigbutton = widget_button(barbase, value='Configure')
;
;  The FOV configuration buttons depend on which spacecraft was selected.
;
if spacecraft eq '-144' then begin
    wspiceconfig = widget_button(wconfigbutton, uvalue='CONFIGSPICE', $
                                 value='Configure SPICE field-of-view')
    weuiconfig = widget_button(wconfigbutton, uvalue='CONFIGEUI', $
                               value='Configure EUI field-of-view')
    wphiconfig = widget_button(wconfigbutton, uvalue='CONFIGPHI', $
                               value='Configure PHI field-of-view')
end else begin
    wgenconfig = widget_button(wconfigbutton, uvalue='CONFIGGEN', $
                               value='Configure field-of-view')
endelse
;
worbitconfig = widget_button(wconfigbutton, uvalue='CONFIGORBIT', $
                             value='Configure orbit trace')
;
;  Define the Options pull-down menu.
;
woptionbutton = widget_button(barbase, value='Options')
wgrid = widget_button(woptionbutton, value='Coordinate grid on/off', $
                      uvalue='GRID')
wshowpfss = widget_button(woptionbutton, value='PFSS magnetic field on/off', $
                          uvalue='SHOWPFSS')
wshowconnect = widget_button(woptionbutton, uvalue='SHOWCONNECT', $
                             value='Magnetic connection point on/off')
wbore = widget_button(woptionbutton, value='Spacecraft boresight on/off', $
                      uvalue='BORESIGHT')
;
;  The FOV on/off buttons depend on which spacecraft was selected.
;
if spacecraft eq '-144' then begin
    wspicefov = widget_button(woptionbutton, value='SPICE field-of-view on/off', $
                              uvalue='SPICEFOV')
    weuifov = widget_button(woptionbutton, value='EUI field-of-view on/off', $
                            uvalue='EUIFOV')
    wphifov = widget_button(woptionbutton, value='PHI field-of-view on/off', $
                            uvalue='PHIFOV')
end else begin
    wgenfov = widget_button(woptionbutton, value='Field-of-view on/off', $
                            uvalue='GENFOV')
endelse
;
worbit = widget_button(woptionbutton, value='Orbit trace on/off', $
                       uvalue='ORBIT')
;
;  Define the help button.
;
whelpbutton = widget_button(barbase, value='Help', /help)
dummy = widget_button(whelpbutton, value='Help widget', uvalue='HELP')
;
;  Create the widgets other than the menu bar.
;
wsubbase = widget_base(wtopbase, column=3, uvalue='')
;
;  Create the widgets along the left side.
;
wleftbase = widget_base(wsubbase, /align_center, /column)
;
;  Create widgets for selecting the ephemeris, controlling the date, and
;  displaying pointing information.
;
wephembase = widget_base(wleftbase, /align_center, /column, /frame)
wselephem = cw_bgroup(wephembase, 'Ephemeris', uvalue='EPHEMERIS', $
                      /nonexclusive, set_value=0)
wtargetdate = widget_text(wephembase, value=target_date, uvalue='DATE', $
                          xsize=23)
wbuttonbase = widget_base(wephembase, /row, /align_center)
dummy = cw_bgroup(wbuttonbase, ['Date', 'Time'], /ROW, uvalue='CHANGEDATE', $
                  button_uvalue=['DATE','TIME'])
dummy = widget_label(wbuttonbase, value='     ')
wconvert = widget_button(wbuttonbase, value='Convert', uvalue='CONVERT', $
                         /align_right, sensitive=0)
dummy = widget_label(wephembase, value='Spacecraft pointing (arcsec)')
wscpoint = widget_base(wephembase, /align_center, /row)
xsc = 0.0
wxsc = cw_field(wscpoint, /frame, /row, uvalue="SCPOINT", value=xsc, $
                 title="X", /return_events, /float, xsize=9)
ysc = 0.0
wysc = cw_field(wscpoint, /frame, /row, uvalue="SCPOINT", value=ysc, $
                 title="Y", /return_events, /float, xsize=9)
;
;  Create widgets for controlling the globe orientation.
;
worientbase = widget_base(wleftbase, /align_center, /column, /frame)
wselorient = cw_bgroup(worientbase, 'Orientation (Carrington)', $
                       uvalue='ORIENTATION', /nonexclusive, set_value=1)
wlonlat = widget_base(worientbase, /align_center, /row)
wyaw   = cw_field(wlonlat, /frame, /column, uvalue="YPR", xsize=9, $
                  title="Longitude", /return_events, /float)
wpitch = cw_field(wlonlat, /frame, /column, uvalue="YPR", xsize=9, $
                  title="Latitude", /return_events, /float)
wroll  = cw_field(worientbase, /frame, /row, uvalue="YPR", xsize=9, $
                  title="Roll", /return_events, /float)
wdist  = cw_field(worientbase, /frame, /row, uvalue="DIST", xsize=9, $
                  title="Distance (AU)", /return_events, /float)
wlockorient = cw_bgroup(worientbase, 'Lock orientation', uvalue='LOCKORIENT', $
                      /nonexclusive, set_value=0)
;
;  Create widgets to control the image center location
;
wpanbase = widget_base(wleftbase, /align_center, /column, /frame)
wselpan = cw_bgroup(wpanbase, 'Image center (arcsec)', uvalue='PAN', $
                    /nonexclusive, set_value=0)
wpoint = widget_base(wpanbase, /align_center, /row)
xsun = 0.0
wxsun = cw_field(wpoint, /frame, /row, uvalue="POINT", value=xsun, $
                 title="X", /return_events, /float, xsize=9)
ysun = 0.0
wysun = cw_field(wpoint, /frame, /row, uvalue="POINT", value=ysun, $
                 title="Y", /return_events, /float, xsize=9)
;
;  Put in some blank space.
;
;;dummy = widget_label(wleftbase, value=' ')
;
;  Define buttons to zoom in and out.
;
wimctrl = widget_base(wleftbase, /align_center, /column, /frame)
wzoom = cw_bgroup(wimctrl, ['Zoom in', 'Zoom out'], /ROW, UVALUE='ZOOM', $
                  button_uvalue=['IN','OUT'])
;
;  Put in some blank space.
;
;;dummy = widget_label(wleftbase, value=' ')
;
;  Create a widget base to contain information about the selected image
;
wselected = widget_base(wleftbase, /align_center, /column, /frame)
dummy = widget_label(wselected, value='Selected image')
wlabel = widget_text(wselected, xsize=23)
wimdate = widget_text(wselected, xsize=23)
wmove = widget_base(wselected, /row)
wup   = widget_button(wmove, value='Move up',   UVALUE='UP',   SENSITIVE=0)
wdown = widget_button(wmove, value='Move down', UVALUE='DOWN', SENSITIVE=0)
wopacity = cw_fslider(wselected, minimum=0.0, maximum=1.0, value=0.0, $
                      title='Opacity', UVALUE='OPACITY', /drag, /frame, /edit)
wdelete = widget_button(wselected, value='Delete', UVALUE='DELETE', SENSITIVE=0)
;
;  Set up the draw widget.
;
wdrawbase = widget_base(wsubbase, /align_center, /column)
wdraw = widget_draw(wdrawbase, xsize=xsize, ysize=ysize, uvalue='DRAW', $
                    /button_events, graphics_level=2, retain=0, /expose_events)
;
;  Set up the image selection base.
;
wrightbase = widget_base(wsubbase, /align_center, /column, $
                         y_scroll_size=ysize)
;
;  Realize  the widget hierarchy.
;
widget_control, wtopbase, /realize
widget_control, wopacity, sensitive=0
widget_control, hourglass=1
widget_control, wdraw, get_value=owindow
;
;  Create the objects.
;
sobject = sunglobe_make_objects([xsize, ysize], owindow, _extra=_extra)
;
;  Create the image widgets inside the selection base.
;
sunglobe_make_image_widgets, wrightbase, wimagebases, pimagestates, $
                             maximages=maximages
;
;  Load the ephemeris data.
;
sunglobe_load_ephem, spacecraft
;
;  Get the inverse of the current translate matrix.
;
mpoint = invert(sobject.origtranslate)
;
;  Build sState structure used in event handlers.
;
sstate={waddhv: waddhv, $                               ;Widget IDs
        wselephem: wselephem, $
        wtargetdate: wtargetdate, $
        wxsc: wxsc, $
        wysc: wysc, $
        wconvert: wconvert, $
        wselorient: wselorient, $
        wyaw: wyaw, $
        wpitch: wpitch, $
        wroll: wroll, $
        wdist: wdist, $
        wlockorient: wlockorient, $
        wselpan: wselpan, $
        wxsun: wxsun, $
        wysun: wysun, $
        wlabel: wlabel, $
        wimdate: wimdate, $
        wup: wup, $
        wdown: wdown, $
        wopacity: wopacity, $
        wdelete: wdelete, $
        wdraw: wdraw, $
        wrightbase: wrightbase, $                       ;Base for images
        wimagebases: wimagebases, $                     ;Image bases
        pimagestates: pimagestates, $                   ;Image states
        oimage: sobject.oimage, $                       ;Object IDs
        osphere: sobject.osphere, $
        ogrid:sobject.ogrid, $
        otrack:sobject.otrack, $
        omodelrotate: sobject.omodelrotate, $           ;Model IDs
        omodeltranslate: sobject.omodeltranslate, $
        ocontainer: sobject.ocontainer, $
        owindow: sobject.owindow, $
        oview: sobject.oview, $
        ofont: sobject.ofont, $
        otext: sobject.otext, $
        opixmap: sobject.opixmap, $
        opixmodel: sobject.opixmodel, $
        opixview: sobject.opixview, $
        opixmap_small: sobject.opixmap_small, $
        opixmodel_small: sobject.opixmodel_small, $
        opixview_small: sobject.opixview_small, $
        obore: sobject.obore, $
        ospice: obj_new(), $
        oeui: obj_new(), $
        ophi: obj_new(), $
        ogen: obj_new(), $
        opfss: obj_new(), $
        oconnect: obj_new(), $
        oorbit: obj_new(), $
        origtranslate: sobject.origtranslate, $   ;Translation matrix to reset
        origrotate: sobject.origrotate, $         ;Rotation matrix to reset
        mpoint: mpoint, $                         ;Inverse of translate matrix
        origview: sobject.origview, $             ;Original view
        origeye: sobject.origeye, $               ;Original eye distance
        origpan: fltarr(2), $                     ;For panning with cursor
        groupbase: groupbase, $                   ;Base of group leader
        returnid: returnid, $                     ;ID for returned events
        nmapped: 0, $                             ;Number of active images
        selected_index: -1, $                     ;Selected index
        hidegrid: 0, $                            ;Grid on/off
        hidepfss: 0, $                            ;PFSS on/off
        hideconnect: 0, $                         ;Connection on/off
        hidebore: 1, $                            ;Boresight on/off
        hidespice: 1, $                           ;SPICE FOV on/off
        hideeui: 1, $                             ;EUI FOV on/off
        hidephi: 1, $                             ;PHI FOV on/off
        hidegen: 1, $                             ;Generic FOV on/off
        hideorbit: 1, $                           ;Orbit trace on/off
        spacecraft: spacecraft, $                 ;Spacecraft ID
        test_offset: round(test_offset), $        ;Ephemeris offset (years)
        target_date: target_date}                 ;Target date
;
;  Create the SPICE field-of-view object.
;
sstate.ospice = obj_new('sunglobe_spice_fov', sstate=sstate, /hide, $
                        _extra=_extra)
sstate.omodeltranslate->add, sstate.ospice
sstate.ocontainer->add, sstate.ospice
;
;  Create the EUI field-of-view object.
;
sstate.oeui = obj_new('sunglobe_eui_fov', sstate=sstate, /hide, $
                      linestyle=2, _extra=_extra)
sstate.omodeltranslate->add, sstate.oeui
sstate.ocontainer->add, sstate.oeui
;
;  Create the PHI field-of-view object.
;
sstate.ophi = obj_new('sunglobe_phi_fov', sstate=sstate, /hide, $
                      linestyle=3, _extra=_extra)
sstate.omodeltranslate->add, sstate.ophi
sstate.ocontainer->add, sstate.ophi
;
;  Create a generic field-of-view object.
;
sstate.ogen = obj_new('sunglobe_generic_fov', sstate=sstate, /hide, $
                      _extra=_extra)
sstate.omodeltranslate->add, sstate.ogen
sstate.ocontainer->add, sstate.ogen
;
;  Create the orbit object.
;
which, 'load_sunspice', /quiet, outfile=temp
if temp ne '' then begin
    sstate.oorbit = obj_new('sunglobe_orbit', sstate=sstate, /hide, _extra=_extra)
    sstate.omodelrotate->add, sstate.oorbit
    sstate.ocontainer->add, sstate.oorbit
endif
;
;  Initialize the UVALUE of the topbase.
;
widget_control, wtopbase, set_uvalue=sstate, /no_copy
;
;  Get the distance value, and initialize it in the widget field.
;
sobject.oview->getproperty, eye=eye
dist = eye * wcs_rsun() / wcs_au()
widget_control, wdist, set_value=dist
;
;  Remove the starting up text.
;
widget_control, hourglass=0
sobject.omodelrotate->remove, sobject.otext
;
;  Register the widget with XMANAGER.
;
xmanager, 'sunglobe', wtopbase, /no_block, event_handler='sunglobe_event', $
          cleanup="sunglobe_cleanup"
;
end
