;+
; Project     : HESSI
;
; Name        : RD_GOES
;
; Purpose     : read GOES data
;
; Category    : synoptic gbo
;
; Syntax      : IDL> rd_goes,times,data,trange=trange
;
; Inputs      : None
;
; Outputs     : TIMES = time array (SECS79)
;               DATA  = data array (# TIMES x 2)
;
; Keywords    : TRANGE=[TSTART, TEND] = time interval to select
;               TAI = TIMES in TAI format
;               NO_CYCLE = don't search each satellite
;               SAT = satellite number to search
;                     (updated if NO_CYCLE=0)
;               REMOTE = force a remote archive search
;               WIDGET = set to write output to text widget
;               GDATA = DATA in structure format
;
; History     : Written 18 Feb 2001, D. Zarro, EITI/GSFC
;               14-Dec-2005 - changed err message text
;               Modified 5 May 2007, Zarro (ADNET/GSFC)
;                - changed /NO_SEARCH to /NO_CYCLE
;               10-Aug-2008, Kim.
;                - Call sat_names with /since_1980)
;                - Don't print error msg about no data, just pass back
;               20-Jan-2012, Zarro (ADNET)
;                - replaced "not" with "~", and used a temporary
;                  when concatanating channel data.
;                - added more error checking for invalid times
;                - added more descriptive /VERBOSE output
;                - added GOES_SAT_LIST to control search list
;                19-Feb-2012, Zarro (ADNET)
;                - changed message,/cont to message,/info because
;                  /cont was setting !error_state
;                16-Apr-2012, Zarro (ADNET)
;                - fixed dimensions of returned DATA
;                13-Apr-2013, Zarro (ADNET)
;                - added check for start time greater than current
;                  time
;                2-Feb-2017, Zarro (ADNET)
;                - added check for availability of remote servers
;                7-Dec-2017, Zarro (ADNET)
;                - added call to VALID_TRANGE for more stringent time
;                  check
;                28-Dec-2017, Zarro (ADNET)
;                - added checks for local archive and SSL support
;                - added widget banner for output
;                19-Sep-2019, Zarro (ADNET)
;                - added different messages for searching local and
;                  remote archives
;                5-Nov-2019, Zarro (ADNET)
;                - more error checking
;               28-May-2020, Zarro (ADNET)
;               - changed _ref_extra to _extra
;               08-Jun-2020, Kim
;               - remove satellites we know aren't in yohkoh archive from list to search
;               29-Sep-2020, Kim.
;               - get satellite time range and only look for sat data if trange overlaps
;
; Contact     : dzarro@solar.stanford.edu
;-

pro rd_goes,times,data,err=err,trange=trange,count=count,tai=tai,$
  _extra=extra,status=status,verbose=verbose,gdata=gdata,widget=widget,$
  type=type,sat=sat,gsat=gsat,no_cycle=no_cycle,remote=remote

  ;-- usual error checks

  want_data=(n_params() eq 2) && ~arg_present(gdata)
  verbose=keyword_set(verbose)
  cycle=~keyword_set(no_cycle)
  widget=keyword_set(widget)
  remote=keyword_set(remote)

  err=''
  count=0
  delvarx,times,data
  gsat=''
  type=''
  status=0
  res='3 sec'

  time_input=0
  if ~valid_trange(trange,trange=vrange,err=err,/ascii) then begin
    error=1
    mprint,err
    if widget then xbanner,err,/append
    return
  endif

  ;-- check if SSL is supported

  if remote then begin
    server=goes_server(response_code=rcode,code=code,err=err,verbose=verbose)
    if is_string(err) then begin
      sock_error,server,code,response_code=rcode,err=err,verbose=verbose
      if ~verbose then mprint,err
      if widget then xbanner,err,/append
      status=1
      return
    endif
  endif

  ;-- GOES satellite can be entered as a number (e.g. 12) or as a keyword
  ;   (e.g. /GOES12)

  chk=have_tag(extra,'goe',index,/start,tag=tag)
  if ~is_number(sat) then begin
    if chk then begin
      msat=stregex(tag[0],'goes'+'([0-9]+)',/extract,/sub,/fold)
      if is_number(msat[1]) then sat=fix(msat[1])
    endif
  endif

  ;-- generate satellite search list

  search_sats=goes_sat_list(sat,count=count,err=err,/since_1980,no_cycle=no_cycle)

  if count gt 0 then begin
    q = where(search_sats le 15 and search_sats ge 6, count)
    if count gt 0 then search_sats = search_sats[q]
  endif

  if count eq 0 then begin
    mprint,err
    if widget then xbanner,err,/append
    status=1
    gsat=''
    return
  endif

  ;-- cycle thru each available GOES satellite
  ;   unless /no_cycle set

  if is_struct(extra) && (index gt -1) then extra=rem_tag(extra,index)
  if have_tag(extra,'fiv',/start) then res='5 min'
  if have_tag(extra,'one',/start) then res='1 min'

  t1=anytim(vrange[0],/int)
  t2=anytim(vrange[1],/int)

  for i=0,n_elements(search_sats)-1 do begin
    tsat=search_sats[i]
    sat_name='GOES'+trim(tsat)
    nextra=add_tag(extra,1,sat_name)
    if remote then mess='remote' else mess='local'
    output='Searching '+mess+' archives for '+sat_name+'...'
    if verbose then mprint,output
    if widget then xbanner,output,/append

    ; If this sat's time range doesn't overlap with requested, skip to next sat.
    sat_trange = goes_sat_dates(det='xrs', sat=tsat, /range)
    if sat_trange[0] eq -1 || ~has_overlap(vrange, sat_trange) then continue

    rd_gxd,t1,t2,gdata,_extra=nextra,status=status,verbose=verbose,check_sdac=0,remote=remote
    if is_struct(gdata) then begin
      type=sat_name
      output='Found '+type+' data.'
      if verbose then mprint,output
      if widget then xbanner,output,/append

      ;-- unpack the data

      if n_params() ge 1 then $
        if keyword_set(tai) then times=anytim(gdata,/tai) else times=anytim(gdata)
      if want_data then $
        data=[[temporary([gdata.lo])],[temporary([gdata.hi])]]

      count=n_elements(gdata)
      gsat=sat_name & sat=tsat
      return
    endif
  endfor

  gsat='GOES'+trim(sat)
  no_data_error='No '+ (cycle?'GOES/Yohkoh':gsat) +' data available for specified times.'
  err=no_data_error
  mprint,err
  if widget then xbanner,err,/append
  status=2
  delvarx,gdata

  return
end
