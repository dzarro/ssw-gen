;+
; Project     : VSO
;
; Name        : GET_SPWC
;
; Purpose     : Get NOAA AR data from Space Weather Prediction Center (SWPC)
;
; Category    : utility, synoptic 
;
; Syntax      : IDL> noaa=get_spwc(dstart,dend)
;
; Inputs      : TSTART = start time
;               TEND = end time
;
; Outputs     : Structure with NOAA active regions characteristics
;
; Keywords    : COUNT = # of results
;               NO_HELIO = don't do heliographic conversion
;               UNIQUE = return unique NOAA names
;               NEAREST = search if no data found
;               DAYS= +/- days to search if /NEAREST (def = 5)
;               LATEST = set to just return latest region
;
; History     : 23-June-2018, Zarro (ADNET) - Written
;               27-January-2019, Zarro (ADNET) - Added DAYS
;               20-March-2019, Zarro (ADNET) - Added LATEST
;-

function get_swpc,tstart,tend,err=err,_ref_extra=extra,count=count,debug=debug,$
                  no_helio=no_helio,unique=unique,nearest=nearest,quiet=quiet,$
                  days=days,latest=latest,status=status

status=0
emess='No NOAA data found for specified time(s).'
err=''
count=0
loud=~keyword_set(quiet)
no_helio=keyword_set(no_helio)

;-- just return latest if requested

if keyword_set(latest) then begin
 srs='https://services.swpc.noaa.gov/text/srs.txt'
 nar=rd_srs(srs,err=err,_extra=extra,/quiet)
 if is_string(err) then begin
  if loud then mprint,emess
  status=1
  return,''
 endif
 if ~no_helio then nar=helio_nar(nar)
 count=n_elements(nar)
 return,nar
endif

debug=keyword_set(debug)
dstart=get_def_times(tstart,tend,dend=dend,/int)
if ~is_number(days) then ndays=5 else ndays=fix(days)

;get_utc,cutc
;dstart.mjd = (dstart.mjd < cutc.mjd)
;dend.mjd = (dend.mjd < cutc.mjd)

if loud then mprint,'Searching for NOAA data between '+anytim2utc(dstart,/vms)+' to '+anytim2utc(dend,/vms)

time=dstart
while (time.mjd le dend.mjd) do begin
 sfile=get_srs(time,err=serr)
 if is_blank(serr) then begin
  sdata=rd_srs(sfile,err=serr,_extra=extra,/quiet)
  if is_struct(sdata) then nar=merge_struct(nar,sdata)
 endif
 time.mjd=time.mjd+1
endwhile


if is_struct(nar) then count=n_elements(nar)
if count eq 0 then begin
 if keyword_set(nearest) then begin
  if loud then mprint,'Searching +/-'+trim(ndays)+' days...'
  nstart=dstart
  nend=dend
  for i=0,ndays-1 do begin
   nstart.mjd=(nstart.mjd-1)
   nend.mjd=(nend.mjd+1)
   nar=get_swpc(nstart,nend,err=err,_extra=extra,count=count,$
                  /no_helio,unique=0b,nearest=0b,/quiet,debug=debug)
   if count gt 0 then begin
    status=-1
    break
   endif
  endfor
 endif
 if count eq 0 then begin
  if loud then mprint,emess
  status=2
  err=emess
  return,''
 endif
endif

;-- determine unique AR pointings

if keyword_set(unique) then nar=sort_nar(nar,count=count,/unique)

;-- append heliocentric pointing tags

if ~no_helio then nar=helio_nar(nar)

return,nar
end

