;+
; Project     : VSO
;
; Name        : SOCK_CHECK
;
; Purpose     : Check if URL file exists by sending a HEAD request for it
;
; Category    : utility system sockets
;
; Syntax      : IDL> chk=sock_check(url)
;
; Inputs      : URL = remote URL file name to check
;
; Outputs     : CHK = 1 or 0 if exists or not
;
; Keywords    : CODE = status code from HTTP header
;               RESPONSE_CODE = response code from IDLnetURL
;
; History     : 10-March-2010, Zarro (ADNET) - Written
;               19-June-2013, Zarro - Reinstated
;               28-October-2013, Zarro 
;                - more stringent test for return code 2xxx
;               7-October-2014, Zarro
;                - return code in keyword
;               2-February-2017, Zarro (ADNET)
;                - added RESPONSE_CODE
;               10-March-2017, Zarro (ADNET)
;                - added fall-back to old SOCK_RESPONSE for non-secure queries
;-

function sock_check,url,code=code,response_code=response_code,_ref_extra=extra,err=err

err=''
response_code=42
code=404L
if ~is_url(url,secure=secure,query=query,_extra=extra) then return,0b
if n_elements(url) gt 1 then begin
 err='Input URL must be scalar.'
 mprint,err
 return,0b
endif

if ~secure && query then checker='sock_response' else checker='sock_head'
response=call_function(checker,url,_extra=extra,code=code,err=err,response_code=response_code,$
 location=location)

scode=strtrim(code,2)
nok=stregex(scode,'^(4|5)',/bool) 
state=~nok

return,state

end
