;+
; Project     : VSO
;
; Name        : SSL_CHECK
;
; Purpose     : Check if SSL is supported by using CATCH
;
; Category    : system utility sockets
;
; Syntax      : IDL> ssl=ssl_check(url)
;
; Inputs      : URL = URL of host to check [def= https://www.google.com]
; 
; Keywords    : ERR = error message
;               RESET = reset last check
;
; Outputs     : SSL = 0/1 is supported or not
;
; History     : 7 December 2017, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function ssl_check,url,err=err,reset=reset,_ref_extra=extra

err=''
common ssl_check,saved

if keyword_set(reset) then delvarx,saved

if is_url(url) then turl=url else turl='https://www.google.com'

;-- save time by not re-checking if already checked

serr='SSL certificate problem or SSL not supported for current system: '+sock_idl_agent()
if is_struct(saved) then begin
 chk=where(turl eq saved.url,count)
 if count eq 1 then begin
  check=saved[chk].check
  if ~check then err=serr
  return,check
 endif  
endif

;-- check URL and save result

r=sock_head(turl,response_code=rcode,_extra=extra)
bad=where(rcode eq [35,53,54,58,59,60,66],count)
check=count eq 0
if ~check then err=serr
saved=merge_struct(saved,{url:turl,check:check})
 
return,check

end
