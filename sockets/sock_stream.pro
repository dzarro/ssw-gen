;+
; Project     : VSO
;
; Name        : SOCK_STREAM
;
; Purpose     : Stream a file from a URL into a buffer
;
; Category    : utility system sockets
;
; Syntax      : IDL> buffer=sock_stream(url)
;
; Inputs      : URL = remote URL file name to stream
;
; Outputs     : BUFFER = byte array
;
; Keywords    : COMPRESS = compress buffer
;               CODE = HTTP status code
;               QUIET = turn off error messages
;
; History     : 13-Jan-2016, Zarro (ADNET) - Written
;               23-Jun-2018, Zarro (ADNET) - add QUIET
;               24-Mar-2019, Zarro (ADNET) - added SOCK_ERROR
;                4-Oct-2019, Zarro (ADNET) - initialized CODE
;-

function sock_stream,url,compress=compress,err=err,_ref_extra=extra,$
                     code=code,quiet=quiet,debug=debug

forward_function zlib_compress
err=''
code=0L
quiet=keyword_set(quiet)
debug=keyword_set(debug)

if ~is_url(url,/scheme) then begin
 err='URL not entered.'
 pr_syntax,'buffer=sock_stream,url [,/compress]'
 return,''
endif

stc=url_parse(url)
if is_blank(stc.path) then begin
 err='Path name not included in URL.'
 if ~quiet then mprint,err
 return,''
endif

;-- initialize object 

error=0 & eflag=0b
catch,error
if (error ne 0) then begin
 derr=err_state()
 if debug then mprint,derr
 catch,/cancel
 message,/reset
 eflag=1b
 goto,bail
endif

durl=url_fix(url,_extra=extra)
ourl=obj_new('idlneturl2',durl,_extra=extra)
buffer = ourl->Get(/buffer)  

bail:
ourl->getproperty,response_code=rcode,_extra=extra,response_header=header
obj_destroy,ourl

if is_string(header) then sock_content,header,code=code
if eflag then begin
 if is_string(header) then begin
  sock_error,durl,code,response_code=rcode,err=err,verbose=~quiet
 endif else begin
  err=derr
  if ~quiet then mprint,err
 endelse
 return,''
endif

if is_byte(buffer) && n_elements(buffer) gt 1 then begin
 if keyword_set(compress) then buffer=zlib_compress(temporary(buffer),/gzip)
 return,buffer
endif

;-- problems if we got here.

err='Read failed. Status code = '+trim(code)
if ~quiet then mprint,err

return,'' & end  


