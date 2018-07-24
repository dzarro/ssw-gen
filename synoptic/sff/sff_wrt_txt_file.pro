
; 11-aug-2017, Kim, Added writing last_update text file  (only if only_cmx is 0) at end
; 13-Aug-2017, Kim, Changed local_machine keyword to run_offline to be consistent with other sff routines
; 14-Aug-2017, Kim, Allow top_dir and out_dir to be different (need to be different for run_offline option)
; 31-Aug-2017, Kim. Removed /verbose from restore (/verbose made log file huge)
; 14-Sep-2017, Kim. Added time_range keyword, so can write time_range[1] in last_update file.

pro sff_wrt_txt_file, only_cmx = only_cmx, run_offline = run_offline, time_range=time_range

  if keyword_set( run_offline ) then begin
    top_dir = '~/solar_flare_finder'
    out_dir = curdir()
  endif else begin
    top_dir = '/data/sff
    out_dir = top_dir
  endelse

  if keyword_set( only_cmx ) then begin
    f = file_search( top_dir+'/sav_files/*/*/20*.sav', count = count )
    c = where( strmid( f, 72, 2 ) eq '_C' )
    m = where( strmid( f, 72, 2 ) eq '_M' )
    x = where( strmid( f, 72, 2 ) eq '_X' )
    dum = [ c, m, x ]
    dum_sort = dum[ sort( dum ) ]
    f = f[ dum_sort ]
    count = n_elements( f )
  endif else f = file_search( top_dir+'/sav_files/*/*/20*.sav', count = count )

  header = [ 'Sol,GOES Start,GOES Peak,GOES End,GOES Class,AIA X-pos,AIA y-pos,RHESSI ID,RHESSI Coverage,RHESSI lo,RHESSI hi,RHESSI X-pos,RHESSI Y-pos,RHESSI,MEGS-A,MEGS-B,EIS,SOT,XRT,IRIS,FID' ]
  string_array = strarr( count )
  struct_array = replicate( { gev_struct, sol: ' ', gev_start: ' ', gev_peak: ' ', gev_end: ' ', goes_class: ' ', aia_xcen: ' ', aia_ycen: ' ', hsi_flare_id: ' ', hsi_coverage: ' ', hsi_lo_energy: ' ', $
    hsi_hi_energy: ' ', hsi_xpos: ' ', hsi_ypos: ' ', hsi_obs: ' ', megsa_obs: ' ', megsb_obs: ' ', eis_obs: ' ', sot_obs: ' ', xrt_obs: ' ', iris_obs: ' ', fid: ' ' }, count )

  print, 'Restoring ' + trim(count) + ' individual flare save files to create ssw_sff_list .txt, .sav, and .csv files.' 
  
  for i = 0, count-1 do begin
    restore, f[ i ]
    str_dum = strmid( f[ i ], 49, 54 )
    ;fid = str_pick( str_dum, '/', '.sav' )
    fs = sff_str
    fid = fs.fid

    if ( size( fs.hsi_flare, /type ) ne 8 ) then begin
      ;hsi_coverage = '-1'
      hsi_flare_id = '0';'-1'
      hsi_lo_energy = '0';'-1'
      hsi_hi_energy = '0';'-1'
      hsi_xpos = '0';'-1'
      hsi_ypos = '0';'-1'
    endif else begin
      ;hsi_coverage = strmid( fid, 22, 3 )
      hsi_flare_id = fs.hsi_flare.id_number
      hsi_lo_energy = fs.hsi_flare.energy_hi[ 0 ]
      hsi_hi_energy = fs.hsi_flare.energy_hi[ 1 ]
      hsi_xpos = fs.hsi_flare.x_position
      hsi_ypos = fs.hsi_flare.y_position
    endelse

    if ( str_find( fid, 'hsi' ) ne ''  ) then begin
      hsi_obs = '1'
      ;hsi_coverage = str_pick( fid, 'hsi', '_' )
      hsi_coverage = strmid( fid, 22, 3 )
    endif else begin
      hsi_obs = '0'
      hsi_coverage = '-1'
    endelse

    if ( fs.eve_megsa_times[ 0 ] ne -1 ) then megsa_obs = '1' else megsa_obs = '0'
    if ( fs.eve_megsb_times[ 0 ] ne -1 ) then megsb_obs = '1' else megsb_obs = '0'
    if ( size( fs.eis_rasters, /type ) eq 8 ) then eis_obs = '1' else eis_obs = '0'
    if ( size( fs.sot_data, /type ) eq 8 ) then sot_obs = '1' else sot_obs = '0'
    if ( size( fs.xrt_data, /type ) eq 8 ) then xrt_obs = '1' else xrt_obs = '0'
    if ( size( fs.iris_rasters, /type ) eq 8 ) then iris_obs = '1' else iris_obs = '0'

    string_array[ i ] = [ fs.sol+','+fs.gev.gev_start+','+fs.gev.gev_peak+','+fs.gev.gev_end+','+fs.gev.goes_class+','+num2str( fs.gev.aia_xcen )+','+num2str( fs.gev.aia_ycen ) $
      +','+num2str( hsi_flare_id )+','+hsi_coverage+','+num2str( hsi_lo_energy )+','+num2str( hsi_hi_energy )+','+num2str( hsi_xpos )+','+num2str( hsi_ypos )+','+hsi_obs+','$
      +megsa_obs+','+megsb_obs+','+eis_obs+','+sot_obs+','+xrt_obs+','+iris_obs+','+fid ]

    struct_array[ i ] = { gev_struct, fs.sol, fs.gev.gev_start, fs.gev.gev_peak, fs.gev.gev_end, fs.gev.goes_class, num2str( fs.gev.aia_xcen ), num2str( fs.gev.aia_ycen ), $
      num2str( hsi_flare_id ), hsi_coverage, num2str( hsi_lo_energy ), num2str( hsi_hi_energy ), num2str( hsi_xpos ), num2str( hsi_ypos ), hsi_obs, megsa_obs, megsb_obs, eis_obs, $
      sot_obs, xrt_obs, iris_obs, fid }
  endfor

  if keyword_set( only_cmx ) then begin
    prstr, string_array, file = out_dir + '/ssw_sff_list_cmx.txt'
    save, filename = out_dir + '/ssw_sff_list_cmx.sav', struct_array
    write_csv, out_dir + '/ssw_sff_list_cmx.csv', [ header, string_array ]
  endif else begin
    prstr, string_array, file = out_dir + '/ssw_sff_list.txt'
    save, filename = out_dir + '/ssw_sff_list.sav', struct_array
    write_csv, out_dir + '/ssw_sff_list.csv', [ header, string_array ]
    
    wrt_ascii, time_range[1], 'last_update.txt'
  endelse

end
