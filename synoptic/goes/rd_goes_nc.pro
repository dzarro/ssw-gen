;+
;Name: rd_goes_nc
;
;Purpose: Read GOES XRS data from NETCDF files at NOAA (or local archive of NETCDF files). As of May 2020, this
;  is for new G16,17 data and reprocessed G13,14,15 data.  Calls S. Freeland's routines to find
;  files, copy them, and read them.
;
;Input Keywords:
; trange - time range to read in anytim format
; no_cycle - just return sat requested, otherwise start with sat and if not found, loop through other sats
; verbose - if set, print info messages
; widget - if set,  print/add messages to the xbanner widget
; sat - satellite choice (number, e.g. 17). Also output keyword indicating sat data is from.
; extra - keywords to pass on, includes one_minute
;
;Output Keywords:
; times - array of times for data (from gdata struct, include here just so matches other rd_goes... routines)
; gdata - structure containing everything from files read
; sat - sat data is from (number, e.g. 17)
; err_msg - error message, blank means no error
; 
; Examples:
;   rd_goes_nc, trange=anytim('10-sep-2017')+[0.,86399], times=ut, gdata = gdata, sat=16
;   rd_goes_nc, trange=anytim('10-sep-2017')+[0.,86399], times=ut, gdata = gdata, sat=16, /one_minute
;   
; Restrictions:
;  Currently g16,17 and reprocessed G13,14,15 are available, and because of the way the calls to the read routines work,
;  this info is hard-coded and will need to change when more sats are available at noaa archive. Also currently don't
;  search at all if requested time is < earliest g13,14,15 data(2009), so will need to change that too.
;
; Written: 25-May-2020 Kim Tolbert
; Modifications:
; 18-Jun-2020, Kim. Sam added count keyword to read_goes_nc - will be 0 if no data in requested
;   time range (even though it returns whatever it did find not in time requested in gdata structure).
;   So check that count ne 0 before using data.
; 29-Sep-2020, Kim. Get satellite time range and only look for sat data if trange overlaps
;
;-

pro rd_goes_nc, trange=trange, no_cycle=no_cycle, verbose=verbose, widget=widget, $
  times=times, gdata=gdata, sat=sat_num, err_msg=err_msg,_extra=extra, five_min=five_min

  checkvar, verbose, 0
  checkvar, widget, 0
  quiet = ~keyword_set(verbose)

  if keyword_set(five_min) then begin
    err_msg = 'Five minute NOAA data not available, choose hi res (no keyword) or one minute (/one_minute) resolution.'
    mprint,err_msg
    if widget then xbanner,err_msg,/append
    return
  endif

  err_msg = ''

  cycle = ~keyword_set(no_cycle)

  if ~valid_trange(trange,err=err_msg) then begin
    mprint,err_msg
    if widget then xbanner,err_msg,/append
    return
  endif

  ; Need to take goesxx out of extra if it's there, so we can set which goesxx we want as we cycle through sats below
  chk=have_tag(extra,'goe',index,/start,tag=tag)
  if is_struct(extra) && (index gt -1) then extra=rem_tag(extra,index)

  no_data_error='No '+ (cycle?'NOAA/GOES':sat_name) +' data available for specified times.'

  ; Don't even bother searching if requested time is < earliest g13,14,15 data.
  
  if anytim(trange[0]) gt anytim('1-jan-2009') then begin
    search_sats=goes_sat_list(sat_num,count=count,no_cycle=no_cycle,err=err_msg)
    if count eq 0 then begin
      if verbose then mprint,err_msg
      if widget then xbanner,err_msg,/append
      return
    endif

    out_dir = goes_temp_dir()

    for i=0,count-1 do begin

      tsat=search_sats[i]

      ; Unfortunately, the ssw_goesx_time2files routines below default to their latest sat number if don't
      ; pass in a goesxx=1 keyword that it recognizes (e.g. GOES11=1 would default to GOES15). So for now we have to
      ; hard-code not to search for sat < 13, and have to remember to change this when NOAA archive of
      ; reprocessed data expands (or Sam changes those routines).
      if tsat lt '13'  or tsat gt '90' then continue ; skip to end of loop

      sat_name='GOES'+trim(tsat)
      mess='Searching remote archives for '+sat_name+'...'
      if verbose then mprint,mess
      if widget then xbanner,mess,/append
      
      ; If this sat's time range doesn't overlap with requested, skip to next sat.
      sat_trange = goes_sat_dates(det='xrs', sat=tsat, /range)
      if sat_trange[0] eq -1 || ~has_overlap(trange, sat_trange) then continue
      
      ; Find files for requested sat and time
      if tsat gt '15' then begin
        sat_tags = {goes17: tsat eq '17', goes16: tsat eq '16'}
        new_extra = is_struct(extra) ? join_struct(sat_tags, extra) : sat_tags
        files = ssw_goesr_time2files(trange[0], trange[1], _extra=new_extra, /xrs, count=nfile, quiet=quiet)
      endif else begin
        sat_tags = {goes15: tsat eq '15', goes14: tsat eq '14', goes13: tsat eq '13'}
        new_extra = is_struct(extra) ? join_struct(sat_tags, extra) : sat_tags
        files = ssw_goesn_time2files(trange[0], trange[1], _extra=new_extra, /xrs, count=nfile, quiet=quiet)
      endelse

      if nfile gt 0 then begin
        ; Copy file(s) if necessary to out_dir and read data
        read_goes_nc, files, gdata, /gxd, timerange=trange, quiet=quiet, out_dir=out_dir, count=count
        if count gt 0 && is_struct(gdata) then begin
          times = anytim(gdata)
          sat_num = tsat
          err_msg=''
          mess='Found ' + sat_name + ' data.'
          if verbose then mprint,mess
          if widget then xbanner,mess,/append
          return
        endif
      endif
    endfor
  endif

  err_msg = no_data_error
  if widget then xbanner,err_msg,/append
  if verbose then mprint,err_msg
end
