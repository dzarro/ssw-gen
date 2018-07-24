;+
; Project     : VSO
;                  
; Name        : IDL_NETWORK
;               
; Purpose     : Test status !use_network which is set to use 
;               IDLnetURL object instead of direct socket calls.
;                             
; Category    : system utility sockets
;               
; Syntax      : IDL> status=idl_network()
;
; History     : 28 September 2016 (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-    

function idl_network

defsysv,'!use_network',exists=exists
if ~exists then defsysv,'!use_network',0
return,!use_network gt 0

end

