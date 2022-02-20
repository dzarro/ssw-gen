;+
; Project     : HESSI
;
; Name        : TRACE_SERVER
;
; Purpose     : return available TRACE data server
;
; Category    : synoptic sockets
;
; Inputs      : None
;
; Outputs     : SERVER = TRACE data server name
;
; Keywords    : NETWORK = returns 1 if network to that server is up
;               PATH = path to data
;
; History     : Written 2-Jan-2022, Zarro (ADNET/GSFC) 
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function trace_server,_ref_extra=extra, path=path,network=network,verbose=verbose

verbose=keyword_set(verbose)
servers=['https://www.lmsal.com','https://umbra.nascom.nasa.gov']
paths=['/solarsoft/trace/level1','/trace_lev1']

;-- find first available server

for i=0,n_elements(servers)-1 do begin
 server=servers[i]
 path=paths[i]
 url=server+path
 network=have_network(url,_extra=extra,verbose=verbose,/full_path)
 if network then break
endfor

if verbose && ~network then mprint,'Network connection currently unavailable.',/info

return,server

end
