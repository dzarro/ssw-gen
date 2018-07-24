;+
; Project     : VSO
;                  
; Name        : USE_NETWORK
;               
; Purpose     : Set !use_network system variable to enable/disable
;               using IDL network objects
;                             
; Category    : system utility sockets
;               
; Syntax      : IDL> use_network
;
; Outputs     : None
;
; Keywords    : OFF = switch off using IDL network objects
;               SECURE = use secure protocol
;                   
; History     : 22 November 2013 (ADNET) - written
;               16 September 2016 (ADNET)
;               - added SECURE
;
; Contact     : dzarro@solar.stanford.edu
;-    

pro use_network,off=off,secure=secure

ver=since_version('6.4')

if ~ver then begin
 message,'IDL network objects not supported for this IDL version.',/info
 defsysv,'!use_network',0
 return
endif

if keyword_set(off) then val=0 else begin
 if keyword_set(secure) then val=2 else val=1
endelse

defsysv,'!use_network',val

return

end

