;+
; Project     : HESSI
;
; Name        : SOCK_PING
;
; Purpose     : ping a remote Web server
;
; Category    : utility system sockets
;                   
; Inputs      : SERVER = server name
;
; Outputs     : STATUS = 1/0 if up/down
;
; Opt. Outputs: PAGE= server output [deprecated]
;
; Keywords    : TIME = response time (seconds)
;               RESPONSE_CODE = response code from IDLnetURL
;               CODE = HTTP status code
;
; History     : 7-Jan-2002,  D.M. Zarro (EITI/GSFC) - Written
;               20-Jan-2013, Zarro (ADNET) 
;               - Removed deprecated RETRY keyword
;               21-Feb-2013, Zarro (ADNET)
;               - Added call to HAVE_NETWORK
;               29-Aug-2019, Zarro (ADNET)
;               - added call to SOCK_ERROR
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro sock_ping,server,status,page,time=time,_ref_extra=extra,verbose=verbose,$
               response_code=response_code,code=code

page=''
t1=systime(/seconds)
status=have_network(server,_extra=extra,$
                    code=code,response_code=response_code,verbose=0)

t2=systime(/seconds)
if status then time=t2-t1 else time=-1
sock_error,server,code,response_code=response_code,_extra=extra,verbose=verbose

return

end
