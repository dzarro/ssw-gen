;+
; Project     : VSO
;
; Name        : GET_SRS
;
; Purpose     : GET Solar Region Summary (SRS) file name for given date.
;
; Category    : utility 
;
; Syntax      : IDL> file=get_srs(date)
;
; Inputs      : DATE = date for file
;
; Outputs     : Full path to SRS file
;
; Keywords    : None
;
; History     : 23-June-2018, Zarro (ADNET) - Written
;-

function get_srs,date,err=err,_ref_extra=extra

err=''
if ~valid_time(date,err=err) then begin
 mprint,err
 return,''
endif

top='ftp://ftp.swpc.noaa.gov/pub/warehouse'
time=anytim2utc(date,/ext)
year=trim(time.year)
month=string(time.month,'(i2.2)')
day=string(time.day,'(i2.2)')
path=top+'/'+year+'/SRS/'+year+month+day+'SRS.txt'
return,path

end
