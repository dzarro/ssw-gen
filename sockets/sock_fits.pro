;+
; Project     : HESSI
;
; Name        : SOCK_FITS
;
; Purpose     : read a FITS file via HTTP sockets
;
; Category    : utility sockets fits
;
; Syntax      : IDL> sock_fits,file,data,header=header,extension=extension
;                   
; Inputs      : FILE = remote file name with URL path attached
;
; Outputs     : DATA = FITS data
;
; Keywords    : ERR   = string error message
;               HEADER = FITS header
;
; History     : 27-Dec-2001,  D.M. Zarro (EITI/GSFC)  Written
;               23-Dec-2005, Zarro (L-3Com/GSFC) - removed COMMON
;               14-Oct-2009, Zarro (ADNET) - made HEADER a keyword
;               15-Nov-2016, Zarr0 (ADNET) - support string EXTENSION input
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro sock_fits,file,data,_ref_extra=extra,extension=extension,err=err

err=''

if ~is_url(file,secure=secure,ftp=ftp,compressed=compressed) then begin
 err='Invalid URL.'
 mprint,err
 return
endif

if secure then begin
 err='Cannot read over HTTPS.'
 mprint,err
 return
endif

if ftp then begin
 err='Cannot read over FTP.'
 mprint,err
 return
endif
 
if compressed then begin
 err='Cannot read compressed file.'
 mprint,err
 return
endif

if n_elements(extension) eq 0 then extension=0
if ~is_number(extension) && is_blank(extension) then begin
 err='Extension must be number or non-blank string.'
 mprint,err
 return
endif

;-- check for string extension name

if is_string(extension) then begin
 extension_name=trim(extension)
 i=-1
 repeat begin
  i=i+1
  key=sock_fits_key(file,'EXTNAME',extension=i,err=err)
 endrep until (is_string(err) || (is_string(key) && key eq extension_name))
 if is_string(err) then begin
  err='Extension name '+extension_name+' not found.' 
  mprint,err
  return
 endif
 rextension=i
endif else begin
 if is_number(extension) then rextension=extension else rextension=0
endelse

err=''
hfits=obj_new('hfits',_extra=extra,err=err)
if ~obj_valid(hfits) then return
delvarx,data
hfits->read,file,data,_extra=extra,err=err,extension=rextension
obj_destroy,hfits

return

end


