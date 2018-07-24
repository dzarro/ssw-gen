;+
; Project     : VSO
;
; Name        : PARSE_SRS
;
; Purpose     : Parse a Solar Region Summary (SRS) array from
;               Space Weather Prediction Center
;
; Category    : utility 
;
; Syntax      : IDL> noaa=parse_srs(data)
;
; Inputs      : DATA = ASCII text read from  SRS file
;
; Outputs     : Structure with NOAA active regions characteristics
;
; Keywords    : None
;
; History     : 23-June-2018, Zarro (ADNET) - Written
;-

function parse_srs,data,err=err,_ref_extra=extra

err=''
if is_blank(data) then begin
 err='Missing input data array.'
 mprint,err
 return,''
endif

;-- extract date

regex='[^0-9].([0-9]{4}) +([a-z]+)+ ([0-9]+).+'
sdata=stregex(data,regex,/ext,/sub,/fold)
chk=where(trim(sdata[0,*]) ne '',count)
if count eq 0 then begin
 err='Invalid date in file.'
 mprint,err
 return,''
endif
sdata=sdata[*,chk[0]]
date=sdata[3]+'-'+sdata[2]+'-'+sdata[1]
dtime=anytim(date,/ints)

;-- extract AR data

regex1='([0-9]+) +([N|S])([0-9]{2})([E|W])([0-9]{2})'
regex2=' +([0-9]+) +([0-9]+) +([a-z]+) +([0-9]+) +([0-9]+) +(.*)'

sdata=stregex(data,regex1+regex2,/sub,/extract,/fold_case)
chk=where( trim(sdata[0,*]) ne '',count)
if count eq 0 then return,''

gbo_struct,nar_data=rdata
;rdata.time=dtime.time
rdata.day=dtime.day
if count gt 1 then rdata=replicate(rdata,count)
sdata=sdata[*,chk]
for i=0,count-1 do begin
 pdata=sdata[*,i]
 rdata[i].noaa=pdata[1]
 location=fix([pdata[5],pdata[3]])
 if pdata[2] eq 'S' then location[1]=-location[1] 
 if pdata[4] eq 'E' then location[0]=-location[0] 
 rdata[i].location=location
 rdata.longitude=pdata[6]
 rdata.long_ext=pdata[9]
 rdata.area=pdata[7]
 rdata.num_spots=pdata[10]
 rdata.st$macintosh=byte(strupcase(strpad(pdata[8],3,/after)))
 rdata.st$mag_type=byte(strupcase(strpad(pdata[11],16,/after)))
endfor

return,rdata

end
