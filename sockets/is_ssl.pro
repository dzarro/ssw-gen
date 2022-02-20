;+
; Project     : VSO
;
; Name        : IS_SSL
;
; Purpose     : check if URL resource is using SSL
;
; Category    : sockets
;
; Inputs      : URL = string URL to check
;
; Outputs     : 1/0 = yes/no
;
; Keywords    : None
;
; History     : 3-Mar-2019, Zarro (ADNET) - written
;-

function is_ssl,url

if is_blank(url) then return,0b
return,stregex(url[0],'https\:\/\/|ftps\:\/\/',/bool,/fold)

end
