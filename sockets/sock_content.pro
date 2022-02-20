;+
; Project     : VSO
;
; Name        : SOCK_CONTENT
;
; Purpose     : Parse HTTP and FTP response content
;
; Category    : utility system sockets
;
; Syntax      : IDL> sock_content,response
;
; Inputs      : RESPONSE = HTTP or FTP response content string (scalar or vector)
;
; Outputs     : See keywords 
;
; Keywords    : See SOCK_CONTENT_HTTP and _FTP
;
; History     : 2-Oct-2016, Zarro (ADNET) - written
;               30-Jan-2017, Zarro (ADNET) - fixed HTTP check
;               6-May-2021, Zarro (ADNET) - added call to sock_empty
;-

pro sock_content,response,_ref_extra=extra

if is_blank(response) then begin
 sock_empty,_extra=extra     
 return
endif

;-- assume FTP if not HTTP

http_resp=stregex(response[0],'HTTP',/bool,/fold)
if http_resp then sock_content_http,response,_extra=extra else $
 sock_content_ftp,response,_extra=extra

return & end
