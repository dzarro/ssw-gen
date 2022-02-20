;+
; Project     : SOHO - CDS
;
; Name        : DROT_NAR
;
; Purpose     : Solar rotate NOAA AR pointings to given time
;
; Category    : planning
;
; Syntax      : IDL> rnar=drot_nar(nar,time,count=count)
;
; Inputs      : NAR = NOAA AR pointing structure from GET_NAR
;               TIME = time to rotate to
;
;
; Keywords    : COUNT = # or rotated AR pointings remaining on disk
;               ERR = error messages
;
; History     : Written, 20-NOV-1998,  D.M. Zarro (SM&A)
;               Modified, 13 Jan 2005, Zarro (L-3Com/GSFC) - updated NAR
;                structure with rotated time.
;               Modified, 23 July 2009, Zarro (ADNET) 
;               - updated LOCATION field with rotated heliographic
;                 coordinates.
;              24-June-2018, Zarro (ADNET) - check for valid input time
;              13-Feb-2019, Zarro (ADNET) - used absolute VMS string time
;              17-Feb-2019, Zarro (ADNET) - check for rotation off disk
;              26-Feb-2019, Zarro )ADNET) - added /RETURN_BACKSIDE
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function drot_nar,nar,time,count=count,err=err,_ref_extra=extra,return_backside=return_backside

err=''

;-- input error checks

backside=keyword_set(return_backside)
count=0
chk=have_tag(nar,['x','y','time','day'],index,/exact,count=tcount)
if (tcount ne 4) then begin
 pr_syntax,'rnar=drot_nar(nar,time,count=count)'
 if exist(nar) then return,nar else return,''
endif

if ~valid_time(time,err=err) then return,nar

;-- solar rotate

etime=anytim(time,/vms)
dtime=anytim(time,/ints)
np=n_elements(nar)
secs_per_day=24.*3600.

for i=0,np-1 do begin
 tnar=nar[i]
 stime=anytim(tnar,/vms)
 helio=arcmin2hel(tnar.x/60.,tnar.y/60.,date=stime)
 tdiff=(anytim(etime)-anytim(stime))/secs_per_day
 if ~backside then begin
  period=0.5*solar_drot(helio[0])
  if (abs(tdiff) gt period) then continue
 endif
 rcor=rot_xy(tnar.x,tnar.y,tstart=stime,tend=etime,$
             offlimb=offlimb,index=index,_extra=extra,return_backside=return_backside)

 if ~backside then begin
  if index[0] le -1 then continue
  if (rcor[0] lt tnar.x) && (tdiff gt 0.) then continue
  if (rcor[0] gt tnar.x) && (tdiff lt 0.) then continue 
 endif

 rcor=reform(rcor)                      
 tnar.x=rcor[0]
 tnar.y=rcor[1]
 tnar.time=dtime.time
 tnar.day=dtime.day 
 helio=arcmin2hel(tnar.x/60.,tnar.y/60.,date=etime)
 tnar.location[0]=helio[1]
 tnar.location[1]=helio[0]
 rnar=merge_struct(rnar,tnar)
endfor

count=n_elements(rnar)

if count eq 0 then mprint,"All AR's rotated off disk."
if (count gt 0) then return,rnar else return,''

end


