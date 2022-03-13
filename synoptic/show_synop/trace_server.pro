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
;               FLEVEL = 0 or 1 for processing level [def = 1]
;
; History     : Written 2-Jan-2022, Zarro (ADNET/GSFC) 
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function trace_server,_ref_extra=extra, path=path,network=network,verbose=verbose,$
                      flevel=flevel

verbose=keyword_set(verbose)
if ~is_number(flevel) then level=1 else level=0 > fix(flevel) < 1
if level eq 1 then begin   
 servers=['https://www.lmsal.com','https://umbra.nascom.nasa.gov']
 paths=['/solarsoft/trace/level1','/trace_lev1']
endif else begin
 servers=['https://umbra.nascom.nasa.gov']
 paths=['/trace00']  
endelse

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
