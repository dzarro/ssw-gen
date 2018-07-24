;+
; ROUTINE: SFF_FINDER
;
; PURPOSE: To find solar flares jointly observed by RHESSI, SDO/EVE,
; Hinode/EIS+SOT+XRT, and IRIS
;
; USEAGE:     It searches for all GOES events included in Sam
; Freeland's SSW Latest Events list, then cross-references to
; see which were also observed by RHESSI, SDO/EVE, EIS, SOT, XRT
; and IRIS.
;
; INPUT KEYWORDS:
;   ssw_gev_array - structure containing all SSW Latest events since the last update
;   run_offline - if set, this is not being run on hesperia
;
; OUTPUT: A .png and .sav file containing all metadata from each of
; the above instruments for each GOES event.
;
; KEYWORDS:
;
; RESTRICTIONS: Some months are still missing GOES events in the HEK.
;
; AUTHOR:        Ryan Milligan (NASA/GSFC, QUB) Jan 2016
;             - 8 Nov 2016: updated to include all GOES flares, using
;               AIA to get flare locations. From Sam Freeland's
;               HEK routine.
;             - 13 Jul 2017: updated in preparation for automating.
;             - 14-Aug-2017, Kim Tolbert, Added some informative print statements, 
;               init flag to -1 to avoid crash if flag_changes has no changes
;             - 15-Sep-2017, Kim. Added time_range keyword - times we're running this for. 
;               Added writing png and sav files to temporary directory, and when finished processing time period, 
;               delete files for that period from standard location, and copy files from temporary spot.
;               Temp dirs are: top_dir + temp_dir + '/png_files' and top_dir + temp_dir + '/sav_files'
;               Changed rhessi flag colors to standard colors used.
;               Added a timestamp. Call evt_grid with /quiet. Added print statements.
;             - 02-Feb-2018, Kim. Make directories for final location of png and sav files, just in case they don't exist yet.
;-

pro sff_finder, ssw_gev_array=ssw_gev_array, time_range=time_range, status=status, run_offline = run_offline

  status = 0

  !p.thick = 1.
  !x.thick = 1.
  !y.thick = 1.
  circle_sym
  alpha = cgsymbol( 'alpha' )

  if keyword_set( run_offline ) then begin
    window, 2, xsize = 1000, ysize = 500., retain = 2.
    top_dir = '~/solar_flare_finder'
    temp_dir = top_dir + '/temp_files'   
    !p.charsize = 1.
  endif else begin
    top_dir = '/data/sff'
    temp_dir = top_dir + '/temp_files'
    thisDevice = !D.Name
    Set_Plot, 'Z'
    !p.charsize = 0.8
;    !p.background = 255
;    !p.color = 0
    device, Set_Resolution=[ 1000, 500 ], set_pixel_depth=24, decomposed=0
  endelse
  
  ; First make sure our temporary location is empty (since we'll be moving everything here to standard location)
  file_delete, temp_dir + '/png_files', /quiet, /allow_nonexistent, /recursive
  file_delete, temp_dir + '/sav_files', /quiet, /allow_nonexistent, /recursive

  ;; Change environment variable for EIS database
  status = fix_zdbase( /EIS )
  ;; Open socket to nearest RHESSI server and create HSI_OBS_SUMMARY object
  hsi_server
  hsi_obj = hsi_obs_summary()

  ;; Do a search for all SSW Latest events since the last update
  ;ssw_gev_array = update_ssw_gev()
  ;  restore, '../flare_lists/ssw_gev_list_all_20100501-20170412.sav', /ver

  ;recent_flares = where( anytim( ssw_gev_array.gev_start ) ge anytim( update_date ) )
  goes_count = n_elements( ssw_gev_array ) ;; after duplicates have been removed
  gev = ssw_gev_array;; after duplicates have been removed
  gev_start = anytim( gev.gev_start )
  gev_peak = anytim( gev.gev_peak )
  gev_end = anytim( gev.gev_end )

  ;; Read in the ascii file of all SDO/EVE MEGS-B exposure times. Option to
  ;; automatically update the file.
  sock_copy, 'http://lasp.colorado.edu/eve/data_access/evewebdata/interactive/megsb_daily_exposure_hours.csv', $
    'megsb_daily_exposure_hours.dat', out_dir = temp_dir + '/eve_data', /clobber
  readcol, temp_dir + '/eve_data/megsb_daily_exposure_hours.dat', date, doy, exp, delim = ',', skipline = 1, format = 'A,I,A'

  ;; Eliminate days when MEGS-B was not exposed
  e = where( exp ne -1 )
  exp = exp[ e ]
  date = date[ e ]
  doy = doy[ e ]
  eve_count = n_elements( exp )

  ;; Create arrays of start and end times of MEGS-B exposures
  for i = 0, eve_count-1 do begin
    ee = str_sep( exp[ i ], ' ' ) ;; Accounts for multiple exposures in one day
    for j = 0, n_elements( ee )-1 do begin
      s = str2arr( ee[ j ], delimit = '-' )
      if ( n_elements( s ) eq 1 ) then s = [ s, s ]
      tstart = date[ i ] + ' ' + s[ 0 ] + ':00:00'
      tstart = round_time( tstart, /hour )
      tend = date[ i ] + ' ' + s[ 1 ] + ':00:00'
      tend = round_time( tend, /hour ) + 3600.
      ;print, anytim2utc( tstart, /vms), ' ', anytim2utc( tend, /vms )
      if n_elements( megsb_stime ) eq 0 then begin
        megsb_stime = tstart
        megsb_etime = tend
      endif else begin
        megsb_stime = [ temporary( megsb_stime ), tstart ]
        megsb_etime = [ temporary( megsb_etime ), tend ]
      endelse
    endfor
  endfor

  ;; Stitch together contigous time intervals
  a = intarr( n_elements( megsb_stime ) )
  for k = 1, n_elements( megsb_stime )-1 do begin
    if ( megsb_stime[ k ] eq megsb_etime[ k-1 ] ) then a[ k ] = k
  endfor

  b = where( a eq 0 )
  na = n_elements( a )
  nb = n_elements( b )
  c = [ b[ 1:-1 ]-1, na-1 ]
  megsb_times_arr = dblarr( 2, nb )
  megsb_start_times = anytim( anytim2utc( megsb_stime[ b ], /vms ) )
  megsb_end_times = anytim( anytim2utc( megsb_etime[ c ], /vms ) )
  megsb_times_arr[ 0, * ] = megsb_start_times
  megsb_times_arr[ 1, * ] = megsb_end_times

  ;; Start Search
  for i = 0, goes_count-1 do begin
    print,''
    print, 'Working on GOES event ' + trim(i) + ' (total events = ' + trim(goes_count) + ') Current time = ' + !stime
    print, '  Event time = ' + anytim(gev_start[i],/vms) + ' to ' + anytim(gev_end[i],/vms)
    gtr_ext = [ anytim( gev_start[ i ]-1800., /vms ), anytim( gev_end[ i ]+3600., /vms ) ] ;; Extend GOES start/end times by 30/60 minutes
    gtr_eis_ext = [ anytim( gev_start[ i ]-14400., /vms ), anytim( gev_end[ i ]+14400., /vms ) ] ;; Extend GOES start/end times by 4 hours for EIS_LIST_RASTER
    gev_rise_time = [ gev_start[ i ], gev_peak[ i ] ]
    gev_full_time =  [ gev_start[ i ], gev_end[ i ] ]
    gev_dur = gev_rise_time[ 1 ]-gev_rise_time[ 0 ] ;; get the duration of the impulsive phase
    xpos = gev[ i ].aia_xcen
    ypos = gev[ i ].aia_ycen

    ;;  find the largest RHESSI flare during the GOES event
    hsi_flare_id = hsi_whichflare( gev_full_time, /biggest )
    hsi_flare = hsi_getflare( hsi_flare_id )
    print, 'RHESSI flare = ' + trim(hsi_flare_id)
    hsi_obj -> set, obs_time_interval = gev_rise_time
    flag_changes = hsi_obj -> changes() ;; find the RHESSI flare flags within GOES rise phase
    flag = -1
    if ( size( flag_changes, /type ) ne 2 ) then begin
      flag = where( flag_changes.flare_flag.state eq 1 )
      if ( flag[ 0 ] ne -1 ) then begin
        if ( flag_changes.flare_flag.start_times[ flag[ 0 ] ] lt gev_rise_time[ 0 ] ) or ( flag_changes.flare_flag.start_times[ flag[ 0 ] ] eq -1 ) $
          then flag_changes.flare_flag.start_times[ flag[ 0 ] ] = gev_rise_time[ 0 ]
        if ( flag_changes.flare_flag.end_times[ flag[ -1 ] ] gt gev_rise_time[ 1 ] ) or ( flag_changes.flare_flag.end_times[ flag[ -1 ] ] eq -1 ) $
          then flag_changes.flare_flag.end_times[ flag[ -1 ] ] = gev_rise_time[ 1 ]
        hsi_durs = dblarr( n_elements( flag ) )
        for j = 0, n_elements( flag )-1 do hsi_durs[ j ] = flag_changes.flare_flag.end_times[ flag[ j ] ] - flag_changes.flare_flag.start_times[ flag[ j ] ]
        hsi_dur = total( hsi_durs )
        hsi_frac = num2str( hsi_dur/gev_dur )
        if ( hsi_frac gt 0 ) and ( hsi_frac lt 0.01 ) then hsi_frac = 0.01
        hsi_frac_lab = strmid( hsi_frac, 0, 1 ) + strmid( hsi_frac, 2, 2 )
      endif else hsi_dur = 0.
    endif
    if ( hsi_flare_id[ 0 ] ne -1 ) and ( flag[ 0 ] ne -1 ) then hsi_obs = 1 else hsi_obs = 0

    ;; Start to cross-refence metadata from different instruments
    ;; SDO/EVE MEGS-A
    ;; Assume that MEGS-A was observing continuously from launch
    ;; up until midnight on 26 May 2014
    megsa_times = [ anytim( '30-Apr-2010' ), anytim( '27-May-2014' ) ]
    if ( gev_rise_time[ 0 ] gt megsa_times[ 0 ] ) and ( gev_rise_time[ 1 ] gt megsa_times[ 0 ] ) and ( gev_rise_time[ 0 ] lt megsa_times[ 1 ] ) and ( gev_rise_time[ 1 ] lt megsa_times[ 1 ] ) then $
      eve_aobs = 1 else eve_aobs = 0
    ;; SDO/EVE MEGS-B
    megsb_check = where( ( gev_rise_time[ 0 ] gt megsb_start_times ) and ( gev_rise_time[ 1 ] gt megsb_start_times ) $
      and ( gev_rise_time[ 0 ] lt megsb_end_times ) and ( gev_rise_time[ 1 ] lt megsb_end_times ) )
    if ( megsb_check eq -1 ) then eve_bobs = 0 else eve_bobs = 1 & megsb_times = [ anytim( megsb_start_times[ megsb_check ], /vms ), anytim( megsb_end_times[ megsb_check ], /vms ) ]
    ;; Hinode/EIS
    eis_list_raster, gtr_eis_ext[ 0 ], gtr_eis_ext[ 1 ], eis_rasters, eis_count, files = eis_files
    if ( eis_count ne 0 ) then begin
      ;; Check at least the start and/or end of one raster lies with in the flare itself
      eis_sflare = where( ( anytim( anytim2utc( eis_rasters.date_obs ) ) ge gev_start[ i ] ) and ( anytim( anytim2utc( eis_rasters.date_obs ) ) le gev_end[ i ] ) ) ; EIS start within GOES time
      eis_eflare = where( ( anytim( anytim2utc( eis_rasters.date_end ) ) ge gev_start[ i ] ) and ( anytim( anytim2utc( eis_rasters.date_end ) ) le gev_end[ i ] ) ) ; EIS end within GOES time
      eis_wflare = where( ( anytim( anytim2utc( eis_rasters.date_obs ) ) le gev_start[ i ] ) and ( anytim( anytim2utc( eis_rasters.date_end ) ) ge gev_end[ i ] ) ) ; Whole GOES time within EIS time
      eis_tim_check = [ eis_sflare, eis_eflare, eis_wflare ]
      eis_dum = where( eis_tim_check ne -1 )
      eis_dummy = eis_tim_check( eis_dum )
      eis_time_check = eis_dummy( rem_dup( eis_dummy ) )
      ;if ( eis_sflare[ 0 ] ne -1 ) or ( eis_eflare[ 0 ] ne -1 ) then begin
      eis_x0 = ( eis_rasters.xcen - eis_rasters.fovx/2.); - 20. ; allow for +/- 20 arcsec pointing uncertainty. Seems to work for sit-and-stare too.
      eis_x1 = ( eis_rasters.xcen + eis_rasters.fovx/2.); + 20.
      eis_y0 = ( eis_rasters.ycen - eis_rasters.fovy/2.); - 20.
      eis_y1 = ( eis_rasters.ycen + eis_rasters.fovy/2.); +20.
      eis_fov_check = where( ( xpos ge eis_x0 ) and ( xpos le eis_x1 ) and ( ypos ge eis_y0 ) and ( ypos le eis_y1 ) )
      ;if ( eis_fov_check[ 0 ] ne -1 ) then
      ;eis_obs = 1 else eis_obs = 0
      eis_check = find_common( eis_time_check, eis_fov_check )
      if ( eis_check[ 0 ] ne -1 ) then eis_obs = 1 else eis_obs = 0
      ;endif  else eis_obs = 0
    endif else eis_obs = 0
    ;; Hinode/SOT
    sot_cat, gtr_ext[ 0 ], gtr_ext[ 1 ], /level0, sot_out, sot_files, tcount = sot_count, /urls
    if ( sot_count ne 0. ) and ( size( sot_out, /type ) eq 8 ) then begin
      sot_flare = where( ( anytim( anytim2utc( sot_out.date_obs ) ) ge gev_start[ i ] ) and ( anytim( anytim2utc( sot_out.date_obs ) ) le gev_end[ i ] ) )
      if ( sot_flare[ 0 ] ne -1 ) then begin
        sot_x0 = ( sot_out.xcen - sot_out.fovx/2.); - 20. ; allow for +/- 20 arcsec pointing uncertainty
        sot_x1 = ( sot_out.xcen + sot_out.fovx/2.); +20.
        sot_y0 = ( sot_out.ycen - sot_out.fovy/2.); - 20.
        sot_y1 = ( sot_out.ycen + sot_out.fovy/2.); +20.
        sot_fov_check = where( ( xpos ge sot_x0 ) and ( xpos le sot_x1 ) and ( ypos ge sot_y0 ) and ( ypos le sot_y1 ) )
        if ( sot_fov_check[ 0 ] ne -1 ) then sot_obs = 1 else sot_obs = 0
      endif else sot_obs = 0
    endif else sot_obs = 0
    ;; Hinode/XRT
    xrt_cat, gtr_ext[ 0 ], gtr_ext[ 1 ], xrt_out, xrt_files, /urls
    xrt_count = n_elements( xrt_out )
    if ( xrt_count ne 0. ) and ( size( xrt_out, /type ) eq 8 ) then begin
      xrt_flare = where( ( anytim( anytim2utc( xrt_out.date_obs ) ) ge gev_start[ i ] ) and ( anytim( anytim2utc( xrt_out.date_obs ) ) le gev_end[ i ] ) )
      if ( xrt_flare[ 0 ] ne -1 ) then begin
        xrt_x0 = ( xrt_out.xcen - xrt_out.fovx/2.); - 20. ; allow for +/- 20 arcsec pointing uncertainty
        xrt_x1 = ( xrt_out.xcen + xrt_out.fovx/2.); +20.
        xrt_y0 = ( xrt_out.ycen - xrt_out.fovy/2.); - 20.
        xrt_y1 = ( xrt_out.ycen + xrt_out.fovy/2.); +20.
        xrt_fov_check = where( ( xpos ge xrt_x0 ) and ( xpos le xrt_x1 ) and ( ypos ge xrt_y0 ) and ( ypos le xrt_y1 ) )
        if ( xrt_fov_check[ 0 ] ne -1 ) then xrt_obs = 1 else xrt_obs = 0
      endif else xrt_obs = 0
    endif else xrt_obs = 0
    ;; IRIS
    ;iris_timeline = iris_time2timeline( gev_time[ 0 ], gev_time[ 1 ] )
    if ( gev_rise_time[ 0 ] gt anytim( '27-Jun-2013' ) ) then iris_rasters = iris_obs2hcr( gev_full_time[ 0 ], gev_full_time[ 1 ] ) else iris_rasters = -1
    if ( size( iris_rasters, /type ) eq 8 ) then begin
      iris_x0 = ( iris_rasters.xcen - iris_rasters.xfov/2.); - 20. ; allow for +/- 20 arcsec pointing uncertainty
      iris_x1 = ( iris_rasters.xcen + iris_rasters.xfov/2.); +20.
      iris_y0 = ( iris_rasters.ycen - iris_rasters.yfov/2.); - 20.
      iris_y1 = ( iris_rasters.ycen + iris_rasters.yfov/2.); +20.
      iris_fov_check = where( ( xpos ge iris_x0 ) and ( xpos le iris_x1 ) and ( ypos ge iris_y0 ) and ( ypos le iris_y1 ) )
      if ( iris_fov_check[ 0 ] ne -1 ) then iris_obs = 1 else iris_obs = 0
    endif else iris_obs = 0

    !p.multi = [ 0, 1, 2 ]
    sol = time2fid( anytim( gev_start[ i ], /vms ), /full, /second, /time )
    gclass = strmid( gev[ i ].goes_class, 0, 2 )
    fid = sol + '_' + gclass
    if ( hsi_obs eq 1 ) then fid = fid + '_hsi' + hsi_frac_lab
    if ( eve_aobs eq 1 ) or ( eve_bobs eq 1 ) then fid = fid + '_megs'
    if ( eve_aobs eq 1 ) then fid = fid + 'a'
    if ( eve_bobs eq 1 ) then fid = fid + 'b'
    if ( eis_obs eq 1 ) then fid = fid + '_eis'
    if ( sot_obs eq 1 ) then fid = fid + '_sot'
    if ( xrt_obs eq 1 ) then fid = fid + '_xrt'
    if ( iris_obs eq 1 ) then fid = fid + '_iris'

    ;; Plot
    loadct, 0
    reverse_colors
    ;; Plot GOES lightcurves with times of other instruments overplotted
    goes_obj = ogoes()
    goes_obj -> set, tstart = gtr_ext[ 0 ], tend = gtr_ext[ 1 ], sat = 'goes15'
    xrs_data = goes_obj ->getdata( /struct )
    if ( size( xrs_data, /type ) ne 8 ) then begin
      goes_obj -> set, sat = 'goes14'
      xrs_data = goes_obj ->getdata( /struct )
    endif
    if ( size( xrs_data, /type ) eq 8 ) then begin
      utplot, xrs_data.tarray, xrs_data.yclean[ *, 0 ], xrs_data.utbase, position = [ 0.05, 0.57, 0.46, 0.96 ], /no_timestamp, /xs, yrange = [ 1e-12, 1e-2 ], $
        ystyle = 9, legend = 0, ytitle = 'X-ray Flux (W m!U-2!N)', /ylog, title = goes_obj -> get( /sat ) + ' XRS'
      outplot, xrs_data.tarray, xrs_data.yclean[ *, 1 ], line = 1;, thick = 2.
      ;; Overplot GOES15 EUVS Lya lightcurve
      goes_obj -> set, euv = 3, sat = 'goes15'
      euvs_data = goes_obj -> getdata( /struct )
      if ( size( euvs_data, /type ) eq 8 ) then begin
        q = where( euvs_data.yclean[ *, 0 ] ne -99999. )
        axis, /yaxis, /save, ytitle = 'GOES15 Ly'+alpha+' Flux (W m!U-2!N)', color = 100, yrange = [ 0.006, 0.010 ], ylog = 0
        if ( q[ 0 ] ne -1 ) then outplot, euvs_data.tarray[ q ], euvs_data.yclean[ q, 0 ], color = 100.
      endif else begin
        axis, /yaxis, /save, yrange = [ 0.006, 0.010 ], ylog = 0, ytickname = replicate( ' ', 5 )
      endelse

      ssw_legend, [ 'GOES Start', 'GOES Peak', 'GOES End' ], line = [ 1, 0, 2 ], color = 80, /top, /right, box = 0, thick = 2.
      ssw_legend, gev[ i ].goes_class, /left, /top, box = 0
      evt_grid, gev_start[ i ], line = 1, color = 80, thick = 2.
      evt_grid, gev_peak[ i ], line = 0, color = 80, thick = 2.
      evt_grid, gev_end[ i ], line = 2, color = 80, thick = 2.
      hsi_linecolors
      if ( eis_obs eq 1 ) then begin
        for k = 0, n_elements( eis_fov_check )-1 do begin
          evt_grid, anytim2utc( eis_rasters[ eis_fov_check[ k ] ].date_obs, /vms ), line = 1, color = 3, /ticks, ticklen = 0.05,  tickpos = 0.68, thick = 2, /quiet
          evt_grid, anytim2utc( eis_rasters[ eis_fov_check[ k ] ].date_end, /vms ), line = 2, color = 3, /ticks, ticklen = 0.05, tickpos = 0.68, thick = 2., /quiet
          ;outplot, [ anytim2utc( eis_rasters[ eis_fov_check[ k ] ].date_obs, /vms ), anytim2utc( eis_rasters[ eis_fov_check[ k ] ].date_end, /vms ) ], [ 7e-10, 7e-10 ], color = 3
          outplot, [ anytim2utc( eis_rasters[ eis_fov_check[ k ] ].date_obs, /vms ), anytim2utc( eis_rasters[ eis_fov_check[ k ] ].date_end, /vms ) ], [ 0.0071, 0.0071 ], color = 3
          ssw_legend, [ 'EIS Start', 'EIS end' ], line = [ 1, 2  ],  position = [ 0.47, 0.86 ], /norm, color = 3, box = 0, /right
        endfor
      endif
      if ( sot_obs eq 1 ) then begin
        for k = 0, sot_count-1 do begin
          evt_grid, anytim2utc( sot_out[ k ].date_obs, /vms ), line = 0, color = 5, /ticks, tickpos = 0.62, ticklen = 0.02
          ssw_legend, 'SOT', position= [ 0.38, 0.79 ], /norm, textcolor = 5, box = 0
        endfor
      endif
      if ( xrt_obs eq 1 ) then begin
        for k = 0, xrt_count-1 do begin
          evt_grid, anytim2utc( xrt_out[ k ].date_obs, /vms ), line = 0, color = 6, /ticks, tickpos = 0.64, ticklen = 0.02
          ssw_legend, 'XRT', position= [ 0.38, 0.81 ], /norm, textcolor = 6, box = 0
        endfor
      endif
      if ( eve_aobs eq 1 ) then begin
        ;outplot, [ anytim( megsa_times[ 0 ], /vms ), anytim( megsa_times[ 1 ], /vms ) ],  [ 3*( 10^!y.crange[ 0 ] ), 3*( 10^!y.crange[ 0 ] ) ], color = 7, thick = 3
        outplot, [ anytim( megsa_times[ 0 ], /vms ), anytim( megsa_times[ 1 ], /vms ) ],  [ 0.0061, 0.0061 ], color = 7, thick = 3
        ssw_legend, 'EVE MEGS-A', textcolor = 7, box = 0, position = [ 0.38, 0.75 ], /norm
      endif
      if ( eve_bobs eq 1 ) then begin
        ;outplot, [ megsb_times[ 0 ], megsb_times[ 1 ] ],  [ 2*( 10^!y.crange[ 0 ] ), 2*( 10^!y.crange[ 0 ] ) ], color = 4, thick = 3
        outplot, [ megsb_times[ 0 ], megsb_times[ 1 ] ],  [ 0.00605, 0.00605 ], color = 4, thick = 3
        ssw_legend, 'EVE MEGS-B', textcolor = 4, box = 0, position = [ 0.38, 0.73 ], /norm
      endif
      if ( iris_obs eq 1 ) then begin
        ;outplot, [ anytim( iris_rasters.starttime, /vms ), anytim( iris_rasters.stoptime, /vms ) ],  [ 5*( 10^!y.crange[ 0 ] ), 5*( 10^!y.crange[ 0 ] ) ], color = 2, thick = 3
        outplot, [ anytim( iris_rasters.starttime, /vms ), anytim( iris_rasters.stoptime, /vms ) ],  [ 0.00615, 0.00615 ], color = 2, thick = 3
        ssw_legend, 'IRIS', textcolor = 2, box = 0, position = [ 0.38, 0.77 ], /norm
      endif

      ;; Plot RHESSI lightcurves
      hsi_obj -> set, obs_time_interval = gtr_ext
      if ( hsi_obs ne 0 ) then begin
        case hsi_flare.energy_hi[ 1 ] of
          25.: max_ind = 3
          50.: max_ind = 4
          100.: max_ind = 5
          300.: max_ind = 6
          800.: max_ind = 7
          7000.: max_ind = 8
          20000.: max_ind = 9
          else: max_ind = 2
        endcase
      endif else max_ind = 2
      hsi_labels = [ 'Det 1,3,4,5,6,9', '6-12 keV', '12-25 keV', '25-50 keV', '50-100 keV', '100-300 keV', '300-800 keV', '800-7000 keV', '7000-20000 keV' ]
      hsi_colors = [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
      hsi_obj -> plot, /xs, /corrected, dim1_colors = hsi_colors[ 0:max_ind ], dim1_line = 0, psym = 10, /flare, /saa, /night, /no_timestamp, legend = 0, $
        position = [ 0.05, 0.08, 0.46, 0.47 ], flag_colors = [8,4,6], ytickformat = 'tick_label_exp', yrange = [ 1e-1, 1e6 ], ystyle = 1, dim1_use = indgen( max_ind )+1
      ssw_legend, hsi_labels[ 0:max_ind ], /top, /left, box = 0,  textcolor = [ 0, indgen( max_ind )+2 ]
      evt_grid, gev_start[ i ], line = 1, color = 80, thick = 2.
      evt_grid, gev_peak[ i ], line = 0, color = 80, thick = 2.
      evt_grid, gev_end[ i ], line = 2, color = 80, thick = 2.
      !p.multi = [ 1, 2, 1 ]

      ;; Get AIA 131A image closest to GOES event peak time. Clean, prep and
      ;; create map structure. If no AIA, use SWAP or XRT.
      local = ''
      vaia = vso_files( anytim( gev_peak[ i ], /vms ), anytim( gev_peak[ i ]+300., /vms ), inst = 'aia', wave = '131', /url )
      vaia_ind = where( vaia ne '' )
      if ( vaia_ind[ 0 ] ne -1 ) then sock_copy, vaia[ vaia_ind[ 0 ] ], local = local, /verbose, out_dir = temp_dir+'/aia_files'
      if ( local eq '' ) then begin
        vswap = vso_files( anytim( gev_peak[ i ], /vms ), anytim( gev_peak[ i ]+600., /vms ), inst = 'swap', /url )
        sock_copy, vswap[ 0 ], local = local, /verbose, out_dir = temp_dir+'/swap_files'
        if ( vswap[ 0 ] eq '' ) or ( local eq '' ) then begin
          vxrt = vso_files( anytim( gev_peak[ i ], /vms ), anytim( gev_peak[ i ]+600., /vms ), inst = 'xrt', /url )
          if ( vxrt[ 0 ] ne '' ) then begin
            sock_copy, vxrt[ 0 ], local = local, /verbose, out_dir = temp_dir+'/xrt_files'
            fits2map, local, map
            loadct, 3
            chg_ctable, gamma = 1.
          endif
        endif else begin
          fits2map, local, map
          aia_lct, wave = '171', /load
          chg_ctable, gamma = 2.
        endelse
      endif else begin
        fits2map, local, map
        aia_lct, wave = '131', /load
        chg_ctable, gamma = 1.
      endelse

      ;; Plot map
      hsi_linecolors
      if ( size( map, /type ) eq 8 ) then begin
        plot_map, map, /log, grid = 10, position = [ 0.54, 0.08, 0.98, 0.96 ], /limb, lcolor = 255, gcolor = 255, color = 0, xrange = [ -1100, 1100 ], yr = [ -1100, 1100 ], ytitle = ' '
      endif else begin
        reverse_colors
        plot_helio, gev_peak[ i ], grid = 10, title = anytim( gev_peak[ i ], /vms ), position = [ 0.54, 0.08, 0.98, 0.96 ], xrange = [ -1100, 1100 ], yr = [ -1100, 1100 ], /limb
      endelse
      draw_circle, xpos, ypos, 100., /data, color = 255
      if ( hsi_obs eq 0 ) then ssw_legend, 'AIA flare location', color = 255, textcolor = 255, psym = 8, /top, /left, box = 0 else ssw_legend, [ 'AIA flare location', 'RHESSI contours' ], psym = 8, color = [ 255, 0 ], /top, /left, box = 0

      ;; Overplot RHESSI contours
      hsi_fsmap = hsi_qlook_image( flare_id = hsi_flare_id, /map, /full_sun )
      if ( size( hsi_fsmap, /type ) eq 8 ) then begin
        loadct, 1
        chg_ctable, gamma = 2
        plot_map, hsi_fsmap, /over, levels = [ 0.5, 0.6, 0.7, 0.8, 0.9 ]*max( hsi_fsmap.data ), color = 0 ;grid = 10, position = [ 0.54, 0.08, 0.98, 0.96 ], /limb, lcolor = 255, gcolor = 255, color = 0
        ;xrange = [ hsi_flare.x_position-500, hsi_flare.x_position+500 ], yrange = [ hsi_flare.y_position-500, hsi_flare.y_position+500 ]
        hsi_linecolors
      endif

      ;; Overplot EIS FOV
      if ( eis_obs eq 1 ) then begin
        for p = 0, n_elements( eis_fov_check )-1 do begin
          x0 = eis_rasters[ eis_fov_check[ p ] ].xcen - eis_rasters[ eis_fov_check[ p ] ].fovx/2
          x1 = eis_rasters[ eis_fov_check[ p ] ].xcen + eis_rasters[ eis_fov_check[ p ] ].fovx/2.
          y0 = eis_rasters[ eis_fov_check[ p ] ].ycen - eis_rasters[ eis_fov_check[ p ] ].fovy/2.
          y1 = eis_rasters[ eis_fov_check[ p ] ].ycen + eis_rasters[ eis_fov_check[ p ] ].fovy/2.
          draw_boxcorn, x0, y0, x1, y1, /data, color = 3
          ssw_legend, 'EIS FOV', textcolor = 3, position = [ -1100, -800 ], /data, box = 0
        endfor
      endif

      ;; Overplot SOT FOV
      if ( sot_obs eq 1 ) then begin
        for q = 0, n_elements( sot_fov_check )-1 do begin
          x0 = sot_out[ sot_fov_check[ q ] ].xcen - sot_out[ sot_fov_check[ q ] ].fovx/2
          x1 = sot_out[ sot_fov_check[ q ] ].xcen + sot_out[ sot_fov_check[ q ] ].fovx/2.
          y0 = sot_out[ sot_fov_check[ q ] ].ycen - sot_out[ sot_fov_check[ q ] ].fovy/2.
          y1 = sot_out[ sot_fov_check[ q ] ].ycen + sot_out[ sot_fov_check[ q ] ].fovy/2.
          draw_boxcorn, x0, y0, x1, y1, /data, color = 5
          ssw_legend, 'SOT FOV', textcolor = 5, position = [ -1100, -850 ], /data, box = 0
        endfor
      endif

      ;; Overplot XRT FOV. If XRT FOV extends beyond RHESSI FOV, then crop.
      if ( xrt_obs eq 1 ) then begin
        for r = 0, n_elements( xrt_fov_check )-1 do begin
          x0 = xrt_out[ xrt_fov_check[ r ] ].xcen - xrt_out[ xrt_fov_check[ r ] ].fovx/2
          if ( x0 le !x.crange[ 0 ] ) then x0 = !x.crange[ 0 ]
          x1 = xrt_out[ xrt_fov_check[ r ] ].xcen + xrt_out[ xrt_fov_check[ r ] ].fovx/2.
          if ( x1 ge !x.crange[ 1 ] ) then x1 = !x.crange[ 1 ]
          y0 = xrt_out[ xrt_fov_check[ r ] ].ycen - xrt_out[ xrt_fov_check[ r ] ].fovy/2.
          if ( y0 le !y.crange[ 0 ] ) then y0 = !y.crange[ 0 ]
          y1 = xrt_out[ xrt_fov_check[ r ] ].ycen + xrt_out[ xrt_fov_check[ r ] ].fovy/2.
          if ( y1 ge !y.crange[ 1 ] ) then y1 = !y.crange[ 1 ]
          draw_boxcorn, x0, y0, x1, y1, /data, color = 6
          ssw_legend, 'XRT FOV', textcolor = 6, position = [ -1100, -900 ], /data, box = 0
        endfor
      endif

      ;; Overplot IRIS FOV
      if ( iris_obs eq 1 ) then begin
        for s = 0, n_elements( iris_fov_check )-1 do begin
          x0 = iris_rasters[ iris_fov_check[ s ] ].xcen - iris_rasters[ iris_fov_check[ s ] ].xfov/2
          x1 = iris_rasters[ iris_fov_check[ s ] ].xcen + iris_rasters[ iris_fov_check[ s ] ].xfov/2.
          y0 = iris_rasters[ iris_fov_check[ s ] ].ycen - iris_rasters[ iris_fov_check[ s ] ].yfov/2.
          y1 = iris_rasters[ iris_fov_check[ s ] ].ycen + iris_rasters[ iris_fov_check[ s ] ].yfov/2.
          draw_boxcorn, x0, y0, x1, y1, /data, color = 2
          ssw_legend, 'IRIS FOV', textcolor = 2, position = [ -1100, -950 ], /data, box = 0
        endfor
      endif
      
      timestamp, /bottom, color=0, charsize=.7

      year = strmid( fid, 0, 4 )
      month = strmid( fid, 4, 2)
      if keyword_set( run_offline ) then begin
        write_png, top_dir+'/png_files/'+year+'/'+month+'/'+fid+'.png', tvrd( /true )
      endif else begin
        image = TVRD(/true)
        TVLCT, r, g, b, /Get
        out_dir = temp_dir+'/png_files/'+year+'/'+month+'/
        if ~is_dir(out_dir) then file_mkdir, out_dir
        write_png, out_dir + fid+'.png', image, r, g, b
      endelse
      if ( eve_aobs eq 0 ) then megsa_times = -1 else megsa_times = gtr_ext
      if ( eve_bobs eq 0 ) then megsb_times = -1 else megsb_times = megsb_times[ *, megsb_check ]
      if ( eis_obs eq 0 ) then eis_rasters = -1 else eis_rasters = add_tag( eis_rasters[ eis_fov_check ], eis_files[ eis_fov_check ], 'url' )
      if ( sot_obs eq 0 ) then sot_data = -1 else sot_data = add_tag( sot_out[ sot_fov_check ], sot_files[ sot_fov_check ], 'url' )
      if ( xrt_obs eq 0 ) then xrt_data = -1 else xrt_data = add_tag( xrt_out[ xrt_fov_check ], xrt_files[ xrt_fov_check ], 'url' )
      if ( iris_obs eq 0 ) then iris_rasters = -1 else iris_rasters = iris_rasters[ iris_fov_check ]
      sff_str = { sol:sol, fid:fid, gev:gev[ i ], hsi_flare:hsi_flare, eve_megsa_times:megsa_times, eve_megsb_times:megsb_times, $
        eis_rasters:eis_rasters, sot_data:sot_data, xrt_data:xrt_data, iris_rasters:iris_rasters }
      out_dir = temp_dir+'/sav_files/'+year+'/'+month+'/'
      if ~is_dir(out_dir) then file_mkdir, out_dir
      save, filename = out_dir + fid + '.sav', sff_str
      print, 'Wrote .png and .sav files for ' + fid + '  Current time = ' + !stime
    endif else goto, next
    next:
  endfor
  
  ; Now we've written all of the png and sav files in temp_dir/png_files/yyyy/mm and temp_dir/sav_files/yyyy/mm.
  ; First we'll delete the old files then we'll move the png and sav files from the temp location to the regular location.
  ; 
  ; Delete all of the existing .png and .sav files for the period we're running. (don't want files with slightly
  ; different times in names to hang around, or same time, but fewer instruments in name.)
  days = timegrid(time_range[0], time_range[1], /days)
  filedates = time2file(days,/date_only)
  print, 'Deleting all png and sav files for ' + arr2str(filedates,',')
  for i=0,n_elements(filedates)-1 do begin
    png_files = file_search(top_dir + '/png_files', filedates[i]+'*.png', count=npng)
    sav_files = file_search(top_dir + '/sav_files', filedates[i]+'*.sav', count=nsav)
    if npng gt 0 then file_delete, png_files, /quiet
    if nsav gt 0 then file_delete, sav_files, /quiet
  endfor
  
  ; Now move from temp_dir to top_dir

  new_png = file_search(temp_dir + '/png_files', '*.png', count=kpng)
  new_sav = file_search(temp_dir + '/sav_files', '*.sav', count=ksav)
  final_new_png = str_replace(new_png, temp_dir, top_dir)
  final_new_sav = str_replace(new_sav, temp_dir, top_dir)
  file_mkdir, file_dirname(final_new_png)  ; doesn't hurt if dir already exists
  file_mkdir, file_dirname(final_new_sav)
  print, 'Moving new png and sav files from temporary directory to standard location. Number of each: ' + trim(kpng)
  if kpng gt 0 then file_move, new_png, final_new_png, /overwrite
  if ksav gt 0 then file_move, new_sav, final_new_sav, /overwrite

  if keyword_set( run_offline ) then set_plot, thisDevice

  status = 1

end
