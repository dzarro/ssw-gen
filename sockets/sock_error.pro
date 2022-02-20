;+
; Project     : VSO
;
; Name        : SOCK_ERROR
;
; Purpose     : Parse socket errors
;
; Category    : system utility sockets
;
; Syntax      : IDL> sock_error,url,code,response_code=response_code
;
; Inputs      : URL = URL being checked
;               CODE = status code returned in HTTP response header
;
; Outputs     : None
;
; Keywords    : RESPONSE_CODE = response code returned by IDLnetURL
;               (can differ from CODE if SSL error) 
;               ERR = error string
;               VERBOSE = set to print ERR
;
; History     : 30 January 2017, Zarro (ADNET) - written
;               10 May 2017, Zarro (ADNET) 
;                - added more informative error messages
;               27 November 2017, Zarro (ADNET)
;                - added extra check for secure URL
;               5 December 2017, Zarro (ADNET)
;                - added checks for additional network errors
;               18-January 2019, Zarro (ADNET)
;                - added more known network error codes
;               29-August 2019, Zarro (ADNET)
;                - added more error checks
;                3-October 2019, Zarro (ADNET)
;                - added call to SOCK_DECODE
;
; Contact     : dzarro@solar.stanford.edu
;-

pro sock_error,url,code,response_code=response_code,err=err,verbose=verbose

verbose=keyword_set(verbose)
err=''

error=0b
if is_number(code) then begin
 if stregex(trim(code),'^3',/bool) then return
 error=stregex(trim(code),'^(4|5|0)',/bool)
endif 

;-- check response code errors

err=sock_decode(response_code)
if is_string(err) then begin
 err='Response code = '+trim(response_code)+'. '+err
 if verbose then mprint,err
 return
endif

if ~error then return

;-- check for HTTP status code errors

if is_number(code) then begin
 scode=trim(code)
 if scode eq '404' then smess='URL not found' else $
  smess='URL not accessible'
 if is_string(url) then smess=smess+' - '+url
 err='Status code = '+scode+'. '+smess
 if verbose then mprint,err
endif

return & end
