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
; Keywords    : HEADERS = optional string array with headers 
;                         For example: ['Accept: text/xml']
;               FILE = if set, OUTPUT is name of file containing response
;
; History     : 23-November-2011, Zarro (ADNET) - Written
;               2-November-2014, Zarro (ADNET)
;                - allow posting blank content (for probing)
;               16-Sep-2016, Zarro (ADNET)
;               - added call to URL_FIX
;               9-Oct-2018, Zarro (ADNET)
;               - improved error checking
;-

function sock_post,url,content,err=err,file=file,$
         _ref_extra=extra,response_header=response_header


err='' & output=''
response_header=''

if ~since_version('6.4') then begin
 err='Requires IDL version 6.4 or greater.'
 mprint,err
 return,output
endif

if is_blank(url) then begin
 pr_syntax,'output=sock_post(url,content,headers=headers)'
 return,output
endif

;-- parse out URL

stc=url_parse(url)
if is_blank(stc.host) then begin
 err='Host name missing from URL.'
 mprint,err
 return,output
endif

durl=url_fix(url,_extra=extra)
ourl=obj_new('idlneturl2',durl,_extra=extra)
cdir=curdir()
error=0
eflab=0b
catch, error
if (error ne 0) then begin
 catch,/cancel
 err=err_state()
 mprint,err
 message,/reset
 eflag=1b
 goto,bail
endif

;-- have to send output to writeable temp directory

tdir=get_temp_dir()
mk_temp_dir,tdir,sdir,err=err
if is_string(err) then begin
 mprint,err
 return,output
endif

cd,sdir
rfile=''
if is_string(content) then dcontent=content else dcontent=''
rfile = ourl->put(dcontent,/buffer,/post)
eflag=is_blank(rfile)

;-- clean up

bail: cd,cdir
ourl->getproperty,response_filename=efile,response_header=respoonse_header
if obj_valid(ourl) then obj_destroy,ourl

if eflag then begin
 mprint,'POST request failed.'
 if is_string(efile) then begin
  if file_test(efile,/regular) && ~file_test(efile,/zero_length) then begin
   if getenv('DEBUG') ne '' then print,rd_ascii(efile)
   rfile=efile
  endif
 endif
endif

if keyword_set(file) then output=rfile else output=rd_ascii(rfile)

file_delete,sdir,/quiet,/recursive,/allow_nonexistent

return,output

end  
