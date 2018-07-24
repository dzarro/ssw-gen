;+
; Project     : HESSI
;
; Name        : SOCK_FITS_HEAD
;
; Purpose     : read a remote FITS file header via HTTP sockets
;
; Category    : utility sockets fits
;
; Syntax      : IDL> sock_fits_head,file,header
;                   
; Inputs      : FILE = remote URL file name 
;
; Outputs     : HEADER = FITS header
;
; Keywords    : ERR   = string error message
;
; History     : 10-March-2017, Zarro - written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro sock_fits_head,file,header,_ref_extra=extra,err=err

err=''
header=''

if ~is_url(file,secure=secure) then begin
 err='Invalid URL.'
 mprint,err
 return
endif

url=file
if ~secure then begin
 h=sock_response(file,location=location,code=code)
 if is_string(location) then url=location
endif

chk=is_url(url,secure=secure,ftp=ftp,compressed=compressed)

if ftp then begin
 err='Cannot read FITS header over FTP.'
 mprint,err
 return
endif

if compressed then begin
 err='Cannot read compressed FITS file header.'
 mprint,err
 return
endif

if secure then begin
 sock_list,url,header,err=err,range=[0,2879],_extra=extra
 if is_string(header) then header=string(reform(byte(header),80,36)) 
endif else begin
 sock_fits,url,header=header,/nodata,err=err,/no_badheader,_extra=extra
endelse
 
return
end


