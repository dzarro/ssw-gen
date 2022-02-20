;+
; Project     : VSO
;
; Name        : IS_REDIRECT
;
; Purpose     : Check if URL is being redirected
;
; Category    : utility system sockets
;
; Syntax      : IDL> status=is_redirect(url,location)
;
; Inputs      : URL = URL to check
;
; Outputs     : STATUS = 1/0 if redirected or not
;
; Keywords    : ERR = error string
;               LOCATION = redirected location
;
; History     : 5-Mar-2019, Zarro (ADNET/GSFC)
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function is_redirect,url,location=location,_ref_extra=extra

location=''
if ~is_url(url,_extra=extra) then return,0b
if is_ftp(url) then return,0b
if is_ssl(url) then $
 out=sock_head(url,location=location,_extra=extra) else $
  out=sock_response(url,location=location,_extra=extra)

return,is_string(location)
end
