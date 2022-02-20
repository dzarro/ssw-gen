;+
; Project     : VSO
;
; Name        : SOCK_EMPTY
;
; Purpose     : Return empty socket response
;
; Category    : utility system sockets
;
; Syntax      : IDL> sock_empty,response
;
; Inputs      : RESPONSE = HTTP or FTP response content string (scalar or vector)
;
; Outputs     : See keywords 
;
; Keywords    : See SOCK_CONTENT_HTTP
;
; History     : 6-May-2021, Zarro (ADNET) - written
;-

pro sock_empty,response,type=type,size=bsize,date=date,$
               disposition=disposition,location=location,code=code,$
               chunked=chunked,range=range,resp_array=resp,accept=accept,$
               content_location=content_location,_ref_extra=extra

type='' & date='' & bsize=0l & disposition='' & location='' & code=0L
chunked=0b & accept='' & content_location='' & resp=''

return
end
