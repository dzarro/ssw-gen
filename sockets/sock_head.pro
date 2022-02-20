;+
; Project     : VSO
;
; Name        : SOCK_HEAD
;
; Purpose     : Wrapper around IDLnetURL object to send HEAD request
;
; Category    : utility system sockets
;
; Syntax      : IDL> header=sock_head(url)
;
; Inputs      : URL = remote URL file name to check
;
; Outputs     : HEADER = response header 
;
; Keywords    : CODE = HTTP status code
;             : HOST_ONLY = only check host (not full path)
;             : SIZE = number of bytes in return content
;             : PATH = input URL is a path
;             : NO_ACCEPT = add "Accept: none" (for testing)
;
; History     : 24-Aug-2011, Zarro (ADNET) - Written
;                6-Feb-2013, Zarro (ADNET)
;               - added call to new HTTP_CONTENT function
;               19-Jun-2013, Zarro (ADNET) - renamed to sock_head
;               23-Sep-2014, Zarro (ADNET) - stripped down
;               2-Nov-2014, Zarro (ADNET) - skip callback if no path
;               4-Feb-2015, Zarro (ADNET) 
;               - added check for FTP success code
;               10-Feb-2015, Zarro (ADNET) 
;               - pass input URL directly to IDLnetURL2 to parse
;                 PROXY keyword properties in one place
;               21-Feb-2015, Zarro (ADNET)
;               - added separate check for FTP response headers
;               28-March-2106, Zarro (ADNET)
;               - added "Accept: none" keyword to inhibit download
;               16-Sep-2016, Zarro (ADNET)
;               - added call to URL_FIX to support HTTPS
;               30-Jan-2017, Zarro (ADNET)
;               - added RESPONSE_CODE keyword
;               8-Feb-2017, Zarro (ADNET)
;               - fixed bug with extra '/' added to path
;               11-Nov-2018, Zarro (ADNET)
;               - corrected false-positive debug error message
;               15-Jan-2019, Zarro (ADNET)
;               - removed CLOSE CONNECTION call
;               24-Sep-2019, Zarro (ADNET)
;               - initialized response code
;               3-Oct-2019, Zarro (ADNET)
;               - added call to SOCK_ERROR
;-

function sock_head_callback, status, progress, data  

;-- since we only need the response header, we just read
;   the first set of bytes until a non-zero response code is reached


if exist(data) then begin
 help,status
 mprint,'progress[0] '+trim(progress[0])
 mprint,'progress[1] '+trim(progress[1])
 mprint,'progress[2] '+trim(progress[2])
endif

if (progress[0] eq 1) && (progress[2] gt 0) then return,0

return,1

end

;-----------------------------------------------------------------------------
  
function sock_head,url,err=err,_ref_extra=extra,host_only=host_only,code=code,$
               path=path,debug=debug,no_accept=no_accept,response_code=response_code

err='' 
code=0L
response_code=0l

if ~is_url(url,_extra=extra,/scalar,/verbose,err=err) then return,''

durl=url_fix(url,_extra=extra)
stc=url_parse(durl)
url_path=stc.path

if keyword_set(host_only) then begin
 url_path='' 
 stc.path=''
 durl=url_join(stc)
endif

if keyword_set(path) then if ~stregex(url_path,'\/$',/bool) then url_path=url_path+'/'

;-- initialize object 

if keyword_set(no_accept) then headers='Accept: none'

ourl=obj_new('idlneturl2',durl,url_path=url_path,_extra=extra,$
              debug=debug,headers=headers)

if is_string(url_path) && (url_path ne '/') then begin
 ourl->setproperty,callback_data=data,callback_function='sock_head_callback'
endif

;-- have to use a catch since canceling the callback triggers it

error=0
catch, error
if (error ne 0) then begin
 catch,/cancel
 cerr=err_state()
 if keyword_set(debug) then mprint,cerr
 message,/reset
 goto, bail
endif

result=oUrl->Get(/string)  

bail: 
resp=''

if obj_valid(ourl) then begin
 code=sock_code(ourl,err=err,_extra=extra,resp_array=resp,response_code=response_code)
 if is_blank(err) then sock_error,durl,code,response_code=response_code,err=err,_extra=extra
 obj_destroy,ourl
endif

return,resp & end  

