;+
; Project     : VSO
;
; Name        : SOCK_DIR_TIME
;
; Purpose     : Get timestamp of a remote directory
;
; Category    : utility system sockets
;
; Syntax      : IDL> time=sock_dir_time(url)
;
; Inputs      : URL = remote URL directory
;
; Outputs     : TIME = remote directory timestamp
;
; Keywords    : ERR = error string
;
; History     : 29-Jul-2019, Zarro (ADNET)
;-

function sock_dir_time,url,_ref_extra=extra,err=err,verbose=verbose

time=''
if ~is_url(url,/scalar,_extra=extra,err=err,verbose=verbose) then return,''

durl=strtrim(url,2)
base=file_basename(durl)
burl=file_dirname(durl)

sock_search,burl,results,/dir,_extra=extra,dates=dates,err=err,verbose=verbose
if is_string(err) then return,''

chk=where(base eq file_basename(results),count)
if (count eq 0) || is_blank(dates) then begin
 err='Failed to get timestamp for subdirectory named: '+base 
 if keyword_set(verbose) then mprint,err
 return,''
endif

time=anytim2utc(dates[chk[0]],/vms)

return,time
end
