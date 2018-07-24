;+
; Project     : VSO
;
; Name        : SOCK_SSL
;
; Purpose     : Check if SSL is supported
;
; Category    : system utility sockets
;
; Syntax      : IDL> ssl=sock_ssl(response_code)
;
; Inputs      : RESPONSE_CODE = code returned from IDlnetURL property
;
; Outputs     : SSL = 0 if RESPONSE_CODE=35
;
; History     : 1 February 2017, Zarro (ADNET) - written
;               6 December 2017, Zarro (ADNET) - fixed check for NO_SSL environment variable
;
; Contact     : dzarro@solar.stanford.edu
;-

function sock_ssl,response_code

no_ssl=chklog('NO_SSL') ne ''
if no_ssl then return,0b

if is_number(response_code) then begin
 no_ssl=trim(response_code) eq '35'
 if no_ssl then return,0b
endif

return,1b

end
