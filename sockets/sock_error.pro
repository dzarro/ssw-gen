;+
; Project     : VSO
;
; Name        : SOCK_ERROR
;
; Purpose     : Parse socket errors
;
; Category    : system utility sockets
;
; Syntax      : IDL> sock_error,url,status_code,response_code=response_code
;
; Inputs      : URL = URL being checked
;               STATUS_CODE = status code returned in HTTP response
;               header
;
; Outputs     : None
;
; Keywords    : RESPONSE_CODE = response code returned by IDLnetURL
;               (can differ from STATUS_CODE if SSL error) 
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
;
; Contact     : dzarro@solar.stanford.edu
;-

pro sock_error,url,status_code,response_code=response_code,err=err,verbose=verbose

verbose=keyword_set(verbose)
err=''

;-- check for known network issues

if is_number(response_code) then begin
 case fix(response_code) of
  28: err='Network timeout error.'
  33: err='Range requests not supported.'
  18: err='Network transfer interrupted.'
  35: err='SSL connection failed. SSL not supported on current system - '+sock_idl_agent()
  else: begin
   if verbose then mprint,'Response code = '+trim(response_code)
  end
 endcase
 if is_string(err) then begin
  if verbose then mprint,err
  return
 endif
endif

;-- check for issues not caught previously

chk=is_url(url)
if ~chk then return
if is_number(status_code) then begin
 scode=trim(status_code)
 if scode eq '404' then smess='URL not found - '+url else $
  smess='URL not accessible - '+url
 err='Status code = '+scode+'. '+smess
 if verbose then mprint,err
endif

return & end
