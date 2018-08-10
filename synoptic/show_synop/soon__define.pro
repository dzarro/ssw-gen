;+
; Project     : RHESSI
;
; Name        : SOON__DEFINE
;
; Purpose     : Class definition for SOON H-alpha data object
;
; Category    : Objects
;
; History     : 4 July 2018, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

pro soon::read,file,_ref_extra=extra,err=err,roll_correct=roll_correct

err=''
self->fits::read,file,_extra=extra
count=self->get(/count)
if count eq 0 then begin
 err='Error reading file(s).'
 mprint,err
 return
endif

;-- compute proper pointings and adjust map centers

for i=0,count-1 do begin
 index=self->get(i,/index)
 time=self->get(i,/time)
 xy=hel2arcmin(index.lat,index.lon,date=time)*60.
 crval1=xy[0] & crval2=xy[1]
 xcen=comp_fits_cen(index.crpix1,index.cdelt1,index.naxis1,crval1)
 ycen=comp_fits_cen(index.crpix2,index.cdelt2,index.naxis2,crval2)
 map=self->get(i,/map,/no_copy)
 map.xc=xcen
 map.yc=ycen
 self->set,i,map=map,/no_copy
endfor

;-- may need to correct for roll (tbd) 

if keyword_set(roll_correct) then self->roll_correct

return & end

;------------------------------------------------------
pro soon__define,void                 

void={soon, inherits fits}

return & end
