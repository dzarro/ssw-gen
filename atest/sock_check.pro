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
;                - added fall-back to old SOCK_RESPONSE for non-secure
;                  queries
;               18-January-2019, Zarro (ADNET)
;                - absorbed ERR and RESPONSE strings in _REF_EXTRA
;                7-March-2019, Zarro (ADNET)
;                - deprecated old SOCK_RESPONSE
;                4-October-2019, Zarro (ADNET)
;                - improved error propagation via keyword inheritance
;                5-November-2019, Zarro (ADNET)
;                - added check for redirect
;               20-February-2022, Zarro (ADNET)
;                - removed URL_FIX call on LOCATION
;-

function sock_check,url,_ref_extra=extra,code=code,location=location

location=''
response=sock_head(url,_extra=extra,/scalar,code=code,location=location)

if is_url(location) then begin
; location=url_fix(location,_extra=extra)
 response=sock_head(location,_extra=extra,/scalar,code=code)
endif
scode=strtrim(code,2)
nok=stregex(scode,'^(4|5|0)',/bool) 
state=~nok
return,state

end
