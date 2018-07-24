;+
; Project     : VSO
;
; Name        : HELIO_NAR
;
; Purpose     : Add heliocentric coordinates to NOAA AR data
;heliocentric coordinates
; Category    : utility
;
; Syntax      : IDL> noaa=helio_nar(nar)
;
; Inputs      : NOAA AR structure 
;
; Outputs     : NAR data with heliocentric coordinates appended
;
; Keywords    : None
;
; History     : 24-June-2018, Zarro (ADNET) - Written
;-

function helio_nar,nar

if (~have_tag(nar,'noaa')) then return,nar

count=n_elements(nar)
for i=0,count-1 do begin
 temp=nar[i]
 helio=temp.location
 xy=hel2arcmin(helio[1],helio[0],_extra=extra,date=anytim(temp,/utc_int))*60.
 temp=add_tag(temp,xy[0],'x')
 temp=add_tag(temp,xy[1],'y',index='x')
 new_nar=merge_struct(new_nar,temp)
endfor

return,new_nar
end
