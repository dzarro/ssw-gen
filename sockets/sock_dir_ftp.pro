;+
; Project     : VSO
;
; Name        : SOCK_DIR_FTP
;
; Purpose     : Wrapper around IDLnetURL object to perform
;               directory listing via FTP
;
; Category    : utility system sockets
;
; Syntax      : IDL> sock_dir_ftp,url,out_list
;
; Inputs      : URL = remote URL directory name to list
;
; Outputs     : OUT_LIST = optional output variable to store list
;
; History     : 27-Dec-2009, Zarro (ADNET) - written
;               12-Feb-2015, Zarro (ADNET) - scrubbed 
;               16-Sep-2016, Zarro (ADNET)
;               - added call to URL_FIX
;               21-Dec-2016, Zarro (ADNET)
;               - added check extra/missing delimiter in path
;               22-May-2018, Zarro (ADNET)
;               - removed // in output path names.
;                9-Oct-2019, Zarro (ADNET)
;               - added RESPONSE_CODE and CODE keywords
;-

function sock_dir_ftp_callback, status, progress, data

xstatus,'Searching',wbase=wbase,cancelled=cancelled
if cancelled then xkill,wbase

print,status,progress

return,1 & end

;-------------------------------------------------------------------------

pro sock_dir_ftp,url,out_list,err=err,progress=progress,_ref_extra=extra,$
                     debug=debug,response_code=response_code,code=code

err='' 
out_list=''
code=0L
response_code=0L

if ~is_url(url,_extra=extra,/scalar,err=err) then return
if ~is_ftp(url) then begin
 err='Input URL is not FTP.'
 mprint,err
 return
endif

durl=url_fix(url,/ftp,_extra=extra)

error=0
catch, error
if (error ne 0) then begin  
 catch, /cancel
 if keyword_set(debug) then mprint,err_state()
 message,/reset
 goto,bail
endif
 
ourl=obj_new('idlneturl2',durl,_extra=extra,debug=debug)
callback_function=''
if keyword_set(progress) then callback_function='sock_dir_ftp_callback' 

;-- start listing 

out_list = ourl->getftpdirlist(/short,_extra=extra)

bail:

if obj_valid(ourl) then begin
 code=sock_code(ourl,response_code=response_code,err=err,_extra=extra)
 if is_blank(err) then sock_error,durl,code,response_code=response_code,err=err,_extra=extra
 obj_destroy,ourl
 if is_string(err) then return
endif

;-- reconstruct full URL

stc=url_parse(durl)
server=stc.host
if is_string(stc.username) && is_string(stc.password) && (stc.username ne 'anonymous') then $
 server=stc.username+':'+stc.password+'@'+stc.host 

;--override with keyword values

if is_string(extra) then begin
 chk1=where(stregex(extra,'^(URL_)?USER(NAME)?',/bool,/fold),count1)
 chk2=where(stregex(extra,'^(URL_)?PASS(WORD)?',/bool,/fold),count2)
 if (count1 eq 1) && (count2 eq 1) then begin
  username=scope_varfetch(extra[chk1],/ref)
  password=scope_varfetch(extra[chk2],/ref)
  if is_string(username) && is_string(password) && (username ne 'anonymous') then $
   server=username+':'+password+'@'+stc.host
 endif
endif

delim=''
if is_string(stc.path) then if ~str_pos(stc.path,'/',/last) then delim='/'
out_list=stc.scheme+'://'+server+'/'+stc.path+delim+out_list
if n_elements(out_list) eq 1 then out_list=out_list[0]

if n_params() eq 1 then print,out_list

return & end  
