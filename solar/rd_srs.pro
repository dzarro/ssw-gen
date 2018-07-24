;+
; Project     : VSO
;
; Name        : RD_SRS
;
; Purpose     : Read and parse a Solar Region Summary (SRS) file from
;               Space Weather Prediction Center
;
; Category    : utility 
;
; Syntax      : IDL> noaa=rd_srs(file)
;
; Inputs      : FILE  = SRS file name
;              (e.g. ftp://ftp.swpc.noaa.gov/pub/warehouse/2018/SRS/20180623SRS.txt)
;
; Outputs     : Structure with NOAA active regions characteristics
;
; Keywords    : _EXTRA
;
; History     : 23-June-2018, Zarro (ADNET) - Written
;-

function rd_srs,file,err=err,_ref_extra=extra

data=rd_stream(file,err=err,_extra=extra,/quiet)
if is_string(err) then return,''

noaa=parse_srs(data,err=err)
return,noaa
end
