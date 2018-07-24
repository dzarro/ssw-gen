;+
; Project     : VSO
;
; Name        : GET_CR
;
; Purpose     : Return carriage return (CR) string
;               Windows automatically terminates a string with a CR, 
;               but Un*x doesn't so we manually append it.
;
; Category    : system utility sockets
;
; Syntax      : IDL> cr=get_cr()
;
; Inputs      : None
;
; Outputs     : CR = String(13b) if Un*x, '' otherwise
;
; History     : 4 April 2016, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function get_cr

cr=string(13b)
unix=os_family(/lower) ne 'windows'
return,unix?cr:''
end
