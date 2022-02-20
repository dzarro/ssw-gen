;+
; Project     : VSO
;
; Name        : SOCK_JSON
;
; Purpose     : Send JSON string to server via POST
;
; Category    : utility system sockets
;
; Syntax      : IDL> result=sock_json(url,json)
;
; Inputs      : URL = server URL
;               JSON = JSON string
;
; Outputs     : RESULT = result returned from server
;
; Keywords    : ERR = error string
;
; History     : 8-Nov-2019, Zarro (ADNET) - written
;-

function sock_json,url,json,err=err,_ref_extra=extra,verbose=verbose

err=''
error=0
verbose=keyword_set(verbose)
catch, error
if (error ne 0) then begin
 catch, /cancel
 err=err_state()
 if verbose then mprint,err
 message,/reset
 return,''
endif

result=sock_post(url,json,header='Content-Type:application/json',_extra=extra,err=err,verbose=verbose)
if is_string(result) && is_blank(err) then result=json_parse(result,/tostruct,/toarray,_extra=extra)

return,result

end
