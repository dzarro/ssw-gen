;+
; Project     : VSO
;
; Name        : PREP_SERVER
;
; Purpose     : Start PREP_SERVER
;
; Category    : utility sockets analysis
;
; History     : 29-August-2016, Zarro (ADNET) - written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro prep_server,_ref_extra=extra

sock_server,/http,_extra=extra

return & end
