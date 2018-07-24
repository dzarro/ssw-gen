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
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function drot_nar,nar,time,count=count,err=err

err=''

;-- input error checks

chk=have_tag(nar,['x','y','time','day'],index,/exact,count=count)
if (count ne 4) then begin
 pr_syntax,'rnar=drot_nar(nar,time,count=count)'
 if exist(nar) then return,nar else return,-1
endif

if ~valid_time(time,err=err) then return,nar

;-- solar rotate

dtime=anytim(time,/ints)
etime=anytim2utc(time,/utc_int)
np=n_elements(nar)
for i=0,np-1 do begin
 tnar=nar[i]
 stime=anytim2utc(tnar,/utc_int)
 rcor=rot_xy(tnar.x,tnar.y,tstart=stime,tend=etime,$
             offlimb=offlimb,index=index)

; dprint,'offlimb, index: ',offlimb,index,tnar.x,rcor[0]
 if index[0] gt -1 then begin
  rcor=reform(rcor)                      
  tnar.x=rcor[0]
  tnar.y=rcor[1]
  tnar.time=dtime.time
  tnar.day=dtime.day 
  helio=arcmin2hel(tnar.x/60.,tnar.y/60.,date=dtime)
  tnar.location[0]=helio[1]
  tnar.location[1]=helio[0]
  rnar=merge_struct(rnar,tnar)
 endif
endfor

count=n_elements(rnar)

if count eq 0 then mprint,'All points rotated off disk.'
if (count gt 0) then return,rnar else return,-1

end


