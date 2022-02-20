;+
; Project     : HESSI
;
; Name        : RD_GOES_SDAC
;
; Purpose     : read GOES SDAC FITS data (a socket wrapper around GFITS_R)
;
; Category    : synoptic gbo
;
; Syntax      : IDL> rd_goes_sdac
;
; Inputs      : See GFITS_R keywords
;
; Outputs     : See GFITS_R keywords
;
; Keywords    : See GFITS_R keywords
;               STIME, ETIME = start/end times to search
;               REMOTE = force a network search
;               NO_CYCLE = don't search all satellites
;
; History     : Written 15 June 2005, D. Zarro, (L-3Com/GSFC)
;               Modified 24 Nov 2005, Zarro (L-3Com/GSFC)
;                - preserve currently defined $GOES_FITS
;               Modified 26 Dec 2005, Zarro (L-3Com/GSFC)
;                - support varied input time formats with anytim
;               Modified 30 Dec 2005, Zarro (L-3Com/GSFC)
;                - improved by only downloading required files
;               Modified Election Night 7 Nov 2006, Zarro (ADNET/GSFC)
;                - check that $GOES_FITS is a valid archive
;               Modified 22 Jan 2007, Zarro (ADNET/GSFC)
;                - corrected returned satellite number
;               Modified 5 May 2007, Zarro (ADNET/GSFC)
;                - added /NO_CYCLE
;               Modified 6-Mar-2008, Kim.
;                - Cycle through sats even when not reading remotely (so we can
;                  skip bad files)
;                - Added error and err_msg as explicit keywords so can use them here
;               Modified 10-Aug-2008, Kim.
;                - Added 'X*' files (pre-1980 files) to cleanup of temp dir at end
;               Modified 9-Oct-2008, Kim. Init found_sat=0, and set
;               err_msg in catch
;               19-Jan-2012, Zarro (ADNET)
;               - replaced http->copy by sock_copy for better control
;                 thru proxy servers
;               - saved $GOES_FITS in common so that it is only checked
;                 once
;               - ensured that err_msg and error are compatible
;                 (error=0 => err_msg='')
;               - replaced "not" with "~"
;               - added more descriptive /VERBOSE output
;               - added GOES_SAT_LIST to control search list
;               29-Jan-2012, Zarro (ADNET)
;               - removed common and pass download directory via
;                 GOES_DIR
;               19-Feb-2012, Zarro (ADNET)
;                - changed mprint,/cont to mprint,/info because
;                  /cont was setting !error_state
;               26-Dec-2012, Zarro (ADNET)
;                - moved network-related mprints into GOES_SERVER
;               12-Apr-2013, Zarro (ADNET)
;                - attempt remote search if not found locally
;                - added check for start time greater than current time
;               24-Oct-2013, Kim.
;                - Added /a_write to mk_dir for temp dir, so anyone can write in it
;               11-Oct-2016, Kim.
;                - Call sock_get instead of sock_copy, remove
;                  /use_network from call, and add /quiet
;               28-Jan-2017, Zarro (ADNET)
;                - removed /no_check from sock_get as it was
;                  re-downloading previously downloaded files.
;                2-Feb-2017, Zarro (ADNET)
;                - added check for availability of remote servers
;                7-Dec-2017, Zarro (ADNET)
;                - added call to VALID_TRANGE for more stringent time check
;                28-Dec-2017, Zarro (ADNET)
;                - added checks for local archive and SSL support
;                - added widget banner for output
;                19-Sep-2019, Zarro (ADNET)
;                - added different messages for searching local and
;                  remote archives
;                5-Nov-2019, Zarro (ADNET)
;                - more error checking
;                08-Jun-2020, Kim
;               - remove satellites we know aren't in sdac archive from list to search
;               29-Sep-2020, Kim.
;               - for remote, get satellite time range and only look for sat data if req. range overlaps
;
; Contact     : dzarro@solar.stanford.edu
;-

pro rd_goes_sdac,stime=stime,etime=etime,_ref_extra=extra,remote=remote,error=error,$
  sat=sat,no_cycle=no_cycle,err_msg=err_msg,verbose=verbose,widget=widget

  goes_fits_sav=chklog('$GOES_FITS')
  have_dir=is_dir('$GOES_FITS')

  verbose=keyword_set(verbose)
  cycle=~keyword_set(no_cycle)
  remote=keyword_set(remote)
  widget=keyword_set(widget)

  err_msg='' & error=0

  if ~valid_time(stime) || ~valid_time(etime) then begin
    err_msg='Invalid or missing input time range values.'
    error=1
    mprint,err_msg
    if widget then xbanner,err_msg,/append
    return
  endif

  if ~valid_trange([stime,etime],trange=trange,err=err_msg) then begin
    error=1
    mprint,err_msg
    if widget then xbanner,err_msg,/append
    return
  endif

  tstart=trange[0]
  tend=trange[1]

  ;-- generate satellite search list

  search_sats=goes_sat_list(sat,count=count,no_cycle=no_cycle,err=err_msg)

  ; sdac archive has data from GOES 91,92 and 1-15
  if count gt 0 then begin
    q = where(search_sats le 15 or search_sats gt 90, count)
    if count gt 0 then search_sats = search_sats[q]
  endif

  if count eq 0 then begin
    if verbose then mprint,err_msg
    if widget then xbanner,err_msg,/append
    error=1
    return
  endif

  ;-- cycle thru each available GOES satellite until we get a match
  ;   unless /no_cycle set

  sat_name='GOES'+trim(sat)
  no_data_error='No '+ (cycle?'SDAC/GOES':sat_name) +' data available for specified times.'

  ;-- if not forcing a remote, check if GOES_FITS defined

  if ~remote && have_dir then begin
    for i=0,n_elements(search_sats)-1 do begin
      tsat=search_sats[i]
      sat_name='GOES'+trim(tsat)
      mess='Searching local archives for '+sat_name+'...'
      if verbose then mprint,mess
      if widget then xbanner,mess,/append
      mprint,/reset
      gfits_r,stime=tstart,etime=tend,sat=tsat,_extra=extra,error=error,err_msg=err_msg,/sdac,/no_cycle,verbose=verbose
      if error eq 0 then begin
        sat = tsat
        err_msg=''
        mess='Found GOES'+trim(sat)+' data.'
        if verbose then mprint,mess
        if widget then xbanner,mess,/append
        return
      endif
    endfor

    if widget then xbanner,no_data_error,/append
    mprint,no_data_error

  endif

  ;-- determine server

  if ~remote then begin
    if have_dir then mess='Local GOES/SDAC data not found. Trying remote archive...' else $
      mess='Local GOES/SDAC archive not found. Trying remote archive...'
    if verbose then mprint,mess
    if widget then xbanner,mess,/append
  endif

  server=goes_server(network=network,code=code,err=err_msg,/sdac,path=path,response_code=rcode,verbose=verbose)

  if is_string(err_msg) then begin
    sock_error,server,code,response_code=rcode,err=err_msg,verbose=verbose
    if ~verbose then mprint,err_msg
    if widget then xbanner,err_msg,/append
    error=1 & return
  endif

  error=0

  ;-- Create a temporary directory for remote downloading.

  goes_dir=goes_temp_dir()

  goes_url=server+path
  for i=0,n_elements(search_sats)-1 do begin
    found_sat=0b
    tsat=search_sats[i]
    sat_name='GOES'+trim(tsat)
    mess='Searching remote archives for '+sat_name+'...'
    if verbose then mprint,mess
    if widget then xbanner,mess,/append

    ; If this sat's time range doesn't overlap with requested, skip to next sat.
    sat_trange = goes_sat_dates(det='xrs', sat=tsat, /range)
    if sat_trange[0] eq -1 || ~has_overlap(trange, sat_trange) then continue

    ;-- determine which file names to copy

    files=goes_fits_files(tstart,tend,sat=tsat,/no_comp)
    if is_blank(files) then continue
    goes_files=goes_url+'/'+files

    ;-- check if they exist at the server, and download
    ;-- if server is down, check last downloaded files and hope there is
    ;   at least one.

    if network then begin
      sock_get,goes_files,out_dir=goes_dir,local_file=local,verbose=verbose,/quiet
      chk=where(file_test(local),count)
      found_sat=count gt 0
    endif else found_sat=1b

    ;-- if found, then read downloaded files

    if found_sat then begin
      mprint,/reset
      gfits_r,stime=tstart,etime=tend,sat=tsat,_extra=extra,error=error,/sdac,/no_cycle,$
        err_msg=err_msg,verbose=verbose,goes_dir=goes_dir

      ;-- if everything is ok then bail out, otherwise try another satellite
      ;   (unless /no_cycle is set)

      if error eq 0 then break
    endif
  endfor

  if ~found_sat then error=1

  if error eq 0 then begin
    sat=tsat & err_msg=''
    mess='Found GOES'+trim(sat)+' data.'
    if verbose then mprint,mess
    if widget then xbanner,mess,/append
  endif else err_msg=no_data_error

  if (error eq 1) && is_string(err_msg) then begin
    mprint,err_msg
    if widget then xbanner,err_msg,/append
  endif

  ;-- clean up old files

  old_files=file_since(older=10,patt='go*',count=count,path=goes_dir)
  if count gt 0 then file_delete,old_files,/quiet
  old_files=file_since(older=10,patt='X*',count=count,path=goes_dir)
  if count gt 0 then file_delete,old_files,/quiet

  return & end
