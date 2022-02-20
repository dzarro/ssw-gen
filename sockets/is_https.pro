;+
; Project     : VSO
;
; Name        : IS_HTTPS
;
; Purpose     : check if URL resource is using secure HTTPS
;
; Category    : sockets
;
; Inputs      : URL = string URL to check
;
; Outputs     : 1 if HTTPS
;
; Keywords    : None
;
; History     : Written 24-Sept-2016, Zarro (ADNET)
;-

function is_https,url

if is_blank(url) then return,0b
return,stregex(url[0],'https\:\/\/',/bool,/fold)

end
