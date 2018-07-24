; 14-Aug-2017, Kim, Added some print statements to show what times we're running
; 14-Sep-2017, Kim. Change time interval to run to last_update-2days to present-7days (was last_update-2days to present)
;    Added time_range keyword to pass out the time interval we're searching for events. 

function sff_update_ssw_gev, time_range=time_range, status=status ;, savefile = savefile, count = count

  status = 0
  
  
  last_update = rd_ascii( 'last_update.txt' )
    
  ; time range to search is last processed date minus 2 days to current date minus 1 week - 1 sec (so date is on the last day we're actually doing)
  time_range = [anytim( last_update, /date_only )-2.*86400., anytim(!stime, /date_only) - 7.*86400. - 1.]
  time_range = anytim(time_range, /vms)
  t0 = time_range[0] & t1 = time_range[1]   
    
  print,'Current time = ' + !stime
  print,'last_update = ' + last_update
  print,'Searching for events between ' + t0 + ' and ' + t1
  if anytim(t1) lt anytim(t0) then begin
    print, 'Aborting. End time is less than start time.'
    return, -1
  endif

  her_temp = ssw_her_query( ssw_her_make_query( t0, t1, /fl, search=[ 'FRM_NAME=SSW Latest Events' ], result_limit = 1000 ) ) & help, her_temp
  if ~is_struct(her_temp) then begin
    print,'No events found between ' + t0 + ' and ' + t1
    return, -1
  endif

  her_count = n_elements( her_temp.fl )
  her = her_temp.fl

  gev_start = her.event_starttime
  gev_peak = her.event_peaktime
  gev_end = her.event_endtime
  goes_class = her.fl_goescls
  ;xdum = her.fl.event_coord1
  ;ydum = her.fl.event_coord2
  aia_xcen = her.hpc_x
  aia_ycen = her.hpc_y
  aia_xhel = her.hgs_x
  aia_yhel = her.hgs_y
  aia_loc = strarr( her_count )

  ssw_gev_array_temp = REPLICATE( { ssw_gev_struct, gev_start:' ', gev_peak:' ', gev_end:' ', goes_class:' ', aia_loc:' ', aia_xcen:0E, aia_ycen:0E }, her_count )

  for i = 0, her_count-1 do aia_loc[ i ] = conv_a2h( [ aia_xcen[ i ], aia_ycen[ i ] ], /string )
  for i = 0, her_count-1 do ssw_gev_array_temp[ i ] = { ssw_gev_struct, gev_start[ i ], gev_peak[ i ], gev_end[ i ], goes_class[ i ], aia_loc[ i ], aia_xcen[ i ], aia_ycen[ i ] }

  ;; Remove duplicates
  dup = rem_dup( ssw_gev_array_temp.gev_start )
  ssw_gev_array_rem_dup_temp = ssw_gev_array_temp[ dup ]
  ;count_rem_dup_temp = n_elements( dup )

  ;; Remove A-class flares
  aa = where( strmid( ssw_gev_array_rem_dup_temp.goes_class, 0, 1 ) ne 'A' )
  ssw_gev_array = ssw_gev_array_rem_dup_temp[ aa ]
  count = n_elements( aa )

  status = 1
  return, ssw_gev_array

end
