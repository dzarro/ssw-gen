;+
; Project     : VSO
;
; Name        : SOCK_TIME
;
; Purpose     : Get local time of remote file
;
; Category    : utility system sockets
;
; Syntax      : IDL> time=sock_time(url)
;
; Inputs      : URL = remote URL file name 
;
; Outputs     : See keywords
;
; Keywords    : ERR = error string
;
; History     : 6-Jan-2015, Zarro (ADNET) - written
;               12-Jan-2019, Zarro (ADNET) - return time in UTC (unless /use_local_time)
;-

function sock_time,url,_ref_extra=extra,err=err

case 1 of
 n_elements(url) ne 1: err='Input URL must be scalar string.'
 ~is_url(url,/scheme): err='Input file must be URL.'
 else: err=''
endcase

if is_string(err) then begin
 message,err,/info
 return,''
endif

if ~sock_check(url,date=date,err=err,_extra=extra) then return,''
if ~valid_time(date,err=err) then return,''
return,date

end

