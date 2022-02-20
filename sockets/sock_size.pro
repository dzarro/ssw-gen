;+
; Project     : HESSI
;
; Name        : SOCK_SIZE
;
; Purpose     : get sizes of remote files in bytes
;
; Category    : utility system sockets
;
; Syntax      : IDL> rsize=sock_size(rfile)
;                   
; Example     : IDL> rsize=sock_size('http://server.domain/filename')
;
; Inputs      : RFILE = remote file names
;
; Outputs     : RSIZE = remote file sizes
;
; Keywords    : ERR = string error
;               DATE = UTC date of remote file
;
; History     : 1-Feb-2007,  D.M. Zarro (ADNET/GSFC) - Written
;               3-Feb-2007, Zarro (ADNET/GSFC) - added FTP support
;               26-Oct-2009, Zarro (ADNET) 
;                - replaced HEAD with more direct GET method
;               21-Feb-2013, Zarro (ADNET)
;                - added call to SOCK_HEAD
;               21-Feb-2015, Zarro (ADNET)
;                - moved FTP size check into SOCK_HEAD
;               21-Dec-2018, Zarro (ADNET)
;                - changed _EXTRA to _REF_EXTRA
;               28-Jan-2019, Zarro (ADNET)
;                - added ARG_PRESENT check
;               17-Nov-2019, Zarro (ADNET)
;                - added call to SOCK_CHECK
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function sock_size,rfile,err=err,_ref_extra=extra,date=rdate

;-- usual error check

ret_date=arg_present(rdate)
rdate=''

err=''
if ~is_string(rfile) then begin
 err='Missing input filenames'
 rdate=''
 return,0.
endif

nfiles=n_elements(rfile)
rsize=fltarr(nfiles)
rdate=strarr(nfiles)

for i=0,nfiles-1 do begin
 check=sock_check(rfile[i],size=bsize,date=bdate,_extra=extra)
 if check then begin
  rsize[i]=bsize
  if ret_date then if is_string(bdate) then rdate[i]=bdate
 endif
endfor

if nfiles eq 1 then begin
 rsize=rsize[0]
 rdate=rdate[0]
endif

return,rsize
end


