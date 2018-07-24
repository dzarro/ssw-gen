;+
; Project     : VSO
;
; Name        : SORT_NAR
;
; Purpose     : Sort NOAA AR data in time 
;
; Category    : utility synoptic
;
; Syntax      : IDL> noaa=sort_nar(nar)
;
; Inputs      : NAR structure from GET_NAR
;
; Outputs     : Sorted NAR data 
;
; Keywords    : UNIQUE = return unique most recent AR names
;               COUNT = # of results
;
; History     : 24-June-2018, Zarro (ADNET) - Written
;-

function sort_nar,nar,unique=unique,count=count

count=0
if (~have_tag(nar,'noaa')) || (n_elements(nar) le 1) then return,nar

unique=keyword_set(unique)
times=anytim2tai(nar)
so=sort(times)
dnar=nar[so]
count=n_elements(dnar)

if ~unique then return,dnar

dtime=times[so]
for i=0,count-1 do begin
 dnoaa=dnar[i].noaa
 if exist(tnar) then begin
  check=where(dnoaa eq tnar.noaa,dcount)
  if dcount eq 1 then continue
 endif
 check=where(dnoaa eq dnar.noaa,dcount)
 rnar=dnar[check]
 rtime=dtime[check]
 rmax=max(rtime,index)
 tnar=merge_struct(tnar,rnar[index])
endfor

count=n_elements(tnar)
return,tnar
end
