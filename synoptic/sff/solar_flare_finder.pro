;+
; ROUTINE: SOLAR_FLARE_FINDER
;
; PURPOSE: An interactive widget designed to find solar flares jointly
; observed by RHESSI, SDO/EVE (MEGS-A and MEGS-B),
; Hinode/EIS+SOT+XRT, and IRIS
;
; USAGE: Searches a pre-gerenated text file (SFF_LIST.TXT) of flare
; parameters made using SFF_FINDER.PRO. Select timerange, GOES
; class, RHESSI energeies and location, and whatever instruments are
; desired and a list is returned. Click on a given flare to bring up a
; summary plot of the observations available.
;
; INPUT: Timerange, choice of instruments, GOES class, RHESSI flare
; location, maximum energy and coverage.
;
; OUTPUT: A plot (and optional IDL .sav file) of 1) the GOES
; lightcurves with the timing of observations by other instruments
; overlaid, 2) RHESSI lightcurves, and 3) RHESSI quicklook image with
; the fields of view of other instruments overlaid.
;
; KEYWORDS: None
;
; RESTRICTIONS: This routine only uses metadata provided by the
; various instrument teams. It does makes no guarantees about the
; quality of the data that was taken during a given flare. It merely
; illustrates that the timing and pointing of the instrument coincided
; with the timing and location of the flare.
;
; AUTHORS:        Ryan Milligan (NASA/GSFC, QUB) Jan 2016
;             Kim Tolbert (NASA/GSFC) May 2016 - added widget support
; Modifications:
; 19-Sep-2017, Kim. Previously last_update and sff_list files were distributed in SSW.
;   Now copy them from server, read them once, and store contents in state structure.
;   (This way they're in sync with png/sav files online.)
;   Also ensure end time is never > last_update time.
;   Also, previously crashed if a plot file isn't found. Now print a message, suggest 
;   restarting this program (since only read the sff_list file once, can get out of sync
;   with plot files online.)
; 08-Jan-2018, Kim. Change get_temp_dir to session_dir so that multiple users don't interfere
;   with each other
;-

pro sff_event, event

  curdir = curdir()
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    msg = '     Do you really want to kill Flare Finder?     '
    answer = xanswer (msg, /str, /suppress, default=1)
    if answer eq 'y' then widget_control, event.top, /destroy
    return
  endif

  widget_control, event.top, get_uvalue=state
  widget_control, event.id, get_uvalue=uvalue

  case uvalue of

    'search': begin
      widget_control, state.wtimes, get_value=timerange
      widget_control, state.wclass, get_value=class
      widget_control, state.whenergy, get_value=hen
      widget_control, state.wloc, get_value=loc
      widget_control, state.wcov, get_value=cov
      widget_control, state.whinode, get_value=hin
      widget_control, state.wsdoeve, get_value=sdo
      widget_control, state.wiris, get_value=iris

      ; Search the SFF_LIST.TXT file to find the events meeting the criteria just collected
      flares_found = sff_search( timerange, class, hen, loc, cov, hin, sdo, iris, sff_list=state.sff_list )
      nflares = num2str( n_elements( flares_found ) )
      if ( flares_found[ 0 ] eq -1 ) then begin
        message, 'Sorry. No flares found matching those criteria...', /continue
        vals = 'Sorry. No flares found matching those criteria...'
        nflares = '0'
      endif else begin
        vals = flares_found ;str_match( pngfiles, flares_found )
      endelse
      state = rep_tag_value(state, vals, 'list_vals')
      widget_control, state.wlist, set_value=state.list_vals
      widget_control, state.wlabel, set_value='Found '+nflares+' events. Select one to plot.'
      widget_control, state.wbase, set_uvalue=state
    end

    'event': begin
      sel = widget_info(state.wlist, /list_select)
      choice = state.list_vals[sel]
      if choice ne ''  && ~stregex(choice,'Sorry', /bool) then begin
        sff_file = sff_filename( state, choice )
        if ( state.run_offline eq 1 ) then local_file = sff_file else sock_copy, sff_file, out_dir=session_dir(), local_file=local_file
        if local_file eq '' then begin
          print, ''
          print, 'Requested file ' + sff_file + ' not found on server. '
          print, '  There could be a problem with the network, the server, or perhaps the list of files has been updated on the server.'
          print, '  Try restarting the solar_flare_finder program.'
        endif else begin
          print, 'Local file = ' + local_file
          png = read_png(local_file)
          widget_control, state.wdraw, get_value=win
          wset, win
          erase
          tv, png, /true

          ; restore colors and plot window id
          tvlct, state.rsave, state.gsave, state.bsave
          wset, state.winsave
        endelse
      endif
    end

    'help':begin
      ;ok = dialog_message( sff_help( ), /information )
      if ( state.run_offline eq 1 ) then help_file = '~/solar_flare_finder/ssw_versions/sff_help.txt' else help_file = chklog('$SSW\gen\idl\synoptic\sff\sff_help.txt')
      XDISPLAYFILE, help_file, WTEXT=w, height = 65, width = 100, done_button='Done'
      WIDGET_CONTROL, w;, SET_TEXT_SELECT=[0, 10]
    end

    'dlpng':begin
      sel = widget_info(state.wlist, /list_select)
      if sel eq -1 then begin
        print,'No event selected.'
        return
      endif
      choice = state.list_vals[sel]
      if ~stregex(choice,'Sorry', /bool) then begin
        print, 'Downloading ' + choice + '.png file to your current directory ...'
        sock_copy, sff_filename(state, choice), out_dir = curdir
      endif
    end

    'dlsav':begin
      sel = widget_info(state.wlist, /list_select)
      if sel eq -1 then begin
        print,'No event selected.'
        return
      endif
      choice = state.list_vals[sel]
      if ~stregex(choice,'Sorry', /bool) then begin
        print, 'Downloading ' + choice + '.sav file to your current directory ...'
        sock_copy, sff_filename(state, choice, /save), out_dir = curdir
      endif
    end

    'dllist':begin
      filter = '*.txt'
      list_file = dialog_pickfile( filter = filter)
      print, 'Downloading '+list_file+' to your current directory ...'
      prstr, state.list_vals, file = list_file
    end

    'quit': begin
      widget_control, state.wbase, /destroy
      return
    end

    else:
  endcase
  
  ; make sure end time isn't > last_update
  widget_control, state.wtimes, get_value=timerange
  if anytim(timerange[1]) gt anytim(state.last_update) then begin
    timerange[1] = state.last_update
    widget_control, state.wtimes, set_value=timerange
  endif

end

;-----

pro solar_flare_finder, run_offline = run_offline

  run_offline = keyword_set(run_offline)

  last_update_file = 'https://hesperia.gsfc.nasa.gov/sff/last_update.txt'  
  sock_copy, last_update_file, out_dir=session_dir(), local_file=local_file
  last_update = rd_ascii( local_file )
  
  if run_offline then begin
    sff_list_file = '~/solar_flare_finder/ssw_versions/ssw_sff_list.txt'
  endif else begin
    sff_list_file_remote = 'https://hesperia.gsfc.nasa.gov/sff/ssw_sff_list.txt'
    sock_copy, sff_list_file_remote, out_dir=session_dir(), local_file=sff_list_file
  endelse  
  sff_list = rd_tfile( sff_list_file, 21, 0, delim = ',' )
  
  if xregistered ('Solar Flare Finder') then begin
    xshow,'Solar Flare Finder', /name
    return
  endif

  classes = ['B','C','M','X','All']
  henergy = ['3-6 keV','6-12 keV','12-25 keV','25-50 keV','50-100 keV','100-300 keV','300-800 keV','800-7000 keV','7000-20000 keV','No preference']
  coverage = [ '>0% of rise phase','>90% of rise phase','No preference' ]
  location = ['>-600"/<+600"', '<-600"/>+600"','No preference' ]
  hinode = [ 'EIS', 'SOT', 'XRT' ]
  sdoeve = [ 'MEGS-A','MEGS-B' ]
  iris = [ 'SJI' ]

  if run_offline then top_dir = '~/solar_flare_finder' else top_dir = 'http://hesperia.gsfc.nasa.gov/sff'

  ;save current color and window id values and restore after plotting, so we don't mess
  ; up plotting outside of this widget
  tvlct, rsave, gsave, bsave, /get
  winsave = !d.window
  nflares = ''

  wbase = widget_base(title='Solar Flare Finder', /column, $
    /tlb_kill)

  wrow1_base = widget_base(wbase, /row, /frame)

  wcol1_base = widget_base(wrow1_base, /column, space=0, xpad=0, ypad=0)

  wtimes = cw_ut_range(wcol1_base, value=['1-May-2010 00:00', last_update ], label='', $
    uvalue='times', /noreset, /frame)

  ;wsolids = widget_text( wcol1_base, value ='SOL identifier', /editable )
  ;whsiids = widget_text( wcol1_base, value ='RHESSI flare number', /editable )

  wclass_base = widget_base(wcol1_base, /row)
  wclass = cw_bgroup(wclass_base, classes, /row, /exclusive, $
    label_left='GOES Class:', set_value=4, space=0, uvalue='', ids=wclass_ids )

  whenergy_base = widget_base(wcol1_base, /row)
  whenergy = cw_bgroup(whenergy_base, henergy, row=3, /exclusive, $
    label_left='RHESSI Max. Energy:', set_value=9, space=0, uvalue='', ids=whenergy_ids)

  wcov_base = widget_base(wcol1_base, /row)
  wcov = cw_bgroup(wcov_base, coverage, /row, /exclusive, $
    label_left='RHESSI Coverage', set_value=2, space=0, uvalue='', ids=wcov_ids)

  wloc_base = widget_base(wcol1_base, /row)
  wloc = cw_bgroup(wloc_base, location, /row, /exclusive, $
    label_left='SDO/AIA Flare Location:', set_value=2, space=0, uvalue='', ids=wloc_ids)

  whinode_base = widget_base(wcol1_base, /row)
  whinode = cw_bgroup(whinode_base, hinode, /row, /nonexclusive, $
    label_left='Hinode:', set_value=0, space=0, uvalue='', ids=whinode_ids, /return_index)

  wsdoeve_base = widget_base(wcol1_base, /row)
  wsdoeve = cw_bgroup(wsdoeve_base, sdoeve, /row, /nonexclusive, $
    label_left='SDO/EVE:', set_value=0, space=0, uvalue='', ids=wsdoeve_ids, /return_index)

  wiris_base = widget_base(wcol1_base, /row)
  wiris = cw_bgroup(wiris_base, iris, /row, /nonexclusive, $
    label_left='IRIS:', set_value=0, space=0, uvalue='', ids=wiris_ids, /return_index)

  wsearch = widget_button(wcol1_base, value='Search', uvalue='search', /align_center)

  wlist_base = widget_base(wrow1_base, /column, /frame)
  wlabel = widget_label(wlist_base, value='Found these events. Select one to plot.')
  wlist = widget_list (wlist_base, xsize=62, ysize=28, value='', uvalue='event')

  wbutton_base = widget_base(wrow1_base, /column, /frame)
  whelp = widget_button( wbutton_base, value = 'Help', uvalue = 'help' )
  wdlpng = widget_button( wbutton_base, value = 'Download .PNG', uvalue = 'dlpng' )
  wdlsav = widget_button( wbutton_base, value = 'Download .SAV', uvalue = 'dlsav' )
  wdllist = widget_button( wbutton_base, value = 'Download list', uvalue = 'dllist' )
  wexit = widget_button(wbutton_base, value='Quit', uvalue='quit')

  wdraw = widget_draw(wbase, xsize=1000, ysize=500)

  state = { $
    wbase: wbase, $
    classes: classes, $
    henergy: henergy, $
    hinode: hinode, $
    sdoeve: sdoeve, $
    iris: iris, $
    list_vals: '', $
    wtimes: wtimes, $
    wclass: wclass, $
    wlabel:wlabel, $
    whenergy: whenergy, $
    wcov:wcov, $
    wloc: wloc, $
    whinode: whinode, $
    wsdoeve:wsdoeve, $
    wiris: wiris, $
    wlist: wlist, $
    wdraw: wdraw, $
    rsave: rsave, $
    gsave: gsave, $
    bsave: bsave, $
    winsave: winsave, $
    top_dir: top_dir, $
    run_offline:run_offline, $
    last_update: last_update, $
    sff_list: sff_list }

  widget_control, wbase, set_uvalue=state
  widget_control, wbase, /realize

  xmanager, 'Solar Flare Finder', wbase, event='sff_event', /no_block

end
