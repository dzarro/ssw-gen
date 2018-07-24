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
;               NEAREST = search +/- 14 days if no data found
;
; History     : 23-June-2018, Zarro (ADNET) - Written
;-

function get_swpc,tstart,tend,err=err,_ref_extra=extra,count=count,debug=debug,$
                  no_helio=no_helio,unique=unique,nearest=nearest,quiet=quiet

emess='No NOAA data found for specified time(s).'
err=''
count=0
debug=keyword_set(debug)
dstart=get_def_times(tstart,tend,dend=dend,/no_next,/int)

get_utc,cutc
dstart.mjd = (dstart.mjd < cutc.mjd)
dend.mjd = (dend.mjd < cutc.mjd)

if debug then print,'Searching from: '+anytim(dstart,/vms)+' to '+anytim(dend,/vms)
time=dstart
while (time.mjd le dend.mjd) do begin
 sfile=get_srs(time,err=serr)
 if is_blank(serr) then begin
  sdata=rd_srs(sfile,err=serr,_extra=extra)
  if is_struct(sdata) then nar=merge_struct(nar,sdata)
 endif
 time.mjd=time.mjd+1
endwhile

ndays=14
if is_struct(nar) then count=n_elements(nar)
if count eq 0 then begin
 if keyword_set(nearest) then begin
  mprint,emess
  mprint,'Searching +/-14 days...'
  nstart=dstart
  nend=dend
  for i=0,ndays-1 do begin
   nstart.mjd=(nstart.mjd-1)
   nend.mjd=(nend.mjd+1)
   nar=get_swpc(nstart,nend,err=err,_extra=extra,count=count,$
                  /no_helio,unique=0b,nearest=0b,/quiet,debug=debug)
   if count gt 0 then break
  endfor
 endif
 if count eq 0 then begin
  if ~keyword_set(quiet) then mprint,emess
  err=emess
  return,''
 endif
endif

;-- determine unique AR pointings

if keyword_set(unique) then nar=sort_nar(nar,count=count,/unique)

;-- append heliocentric pointing tags

if ~keyword_set(no_helio) then nar=helio_nar(nar)

return,nar
end
