;+
; Project     : VSO
;
; Name        : SOCK_POST
;
; Purpose     : Wrapper around IDLnetURL object to issue POST request
;
; Category    : utility system sockets
;
; Syntax      : IDL> output=sock_post(url,content)
;
; Inputs      : URL = remote URL file to send content
;               CONTENT = string content to post
;
; Outputs     : OUTPUT = server response
;
; Keywords    : FILE = if set, OUTPUT is name of file containing response
;
; History     : 23-November-2011, Zarro (ADNET) - Written
;               2-November-2014, Zarro (ADNET)
;                - allow posting blank content (for probing)
;               16-Sep-2016, Zarro (ADNET)
;               - added call to URL_FIX
;               9-Oct-2018, Zarro (ADNET)
;               - improved error checking
;               3-Mar-2019, Zarro (ADNET)
;               - more error checking
;               4-Oct-2019, Zarro (ADNET) 
;               - initialized CODE
;               8-Nov-2019, Zarro (ADNET)
;               - improved error checking
;-

function sock_post,url,content,err=err,file=file,_ref_extra=extra,$
          response_code=response_code,code=code,debug=debug,old_version=old_version

err='' & output=''
code=0L
response_code=0L
debug=keyword_set(debug)

old_ver=keyword_set(old_version)

if ~is_url(url,_extra=extra,/scalar,err=err) then return,''

cdir=curdir()
error=0
catch, error
if (error ne 0) then begin
 catch, /cancel
 dmess=err_state()
 if debug then mprint,dmess
 message,/reset
 goto,bail
endif

durl=url_fix(url,_extra=extra)
ourl=obj_new('idlneturl2',durl,_extra=extra,debug=debug)

new_ver=since_version('8.6.1') && ~old_ver

if is_string(content) then dcontent=content else dcontent=''

;-- have to send output to writeable temp directory if older than
;   IDL 8.6.1. New version accepts /STRING_ARRAY

;filename=get_temp_file()
rfile='' & efile=''
if new_ver then begin
 rfile = ourl->put(dcontent,/buffer,/post,/string_array)
endif else begin
 sdir=session_dir()
 cd,sdir
 rfile = ourl->put(dcontent,/buffer,/post)
endelse

;-- clean up

bail: 

if ~new_ver then cd,cdir
if obj_valid(ourl) then begin
 code=sock_code(ourl,err=err,response_code=response_code,_extra=extra,response_header=header,response_file=efile)
 if is_blank(err) then sock_error,durl,code,response_code=response_code,err=err,_extra=extra
 obj_destroy,ourl
endif

;-- check for errors

if debug then begin
 if is_string(efile) then begin
  if file_test(efile,/regular) && ~file_test(efile,/zero_length) then print,rd_ascii(efile)
 endif
 if is_blank(rfile) then return,header
endif

if keyword_set(file) && ~new_ver then return,rfile

if new_ver then return,rfile

if is_string(rfile) then begin
 if file_test(rfile,/regular) && ~file_test(rfile,/zero_length) then output=rd_ascii(rfile)
 file_delete,sdir,/quiet,/recursive,/allow_nonexistent 
endif

return,output

end  
