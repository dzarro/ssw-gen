;+
; Project     : HESSI
;
; Name        : SOCK_RESPONSE
;
; Purpose     : return the HTTP header of a remote URL
;
; Category    : utility sockets 
;
; Syntax      : IDL> header=sock_response(url)
;                   
; Inputs      : URL = remote URL 
;
; Outputs     : HEADER = string header
;
; Keywords    : ERR   = string error message
;               HOST_ONLY = only check host name (without full path)
;
; History     : 28-Feb-2012, Zarro (ADNET) - written
;               26-Feb-2015, Zarro (ADNET)
;               - removed FTP restriction
;               19-Sep-2016, Zarro (ADNET)
;               - added call to URL_FIX to support HTTPS
;               10-March-2017, Zarro (ADNET)
;               - removed check for QUERY
;               17-Nov-2018, Zarro (ADNET)
;               - added support for URL username/password
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function sock_response,url,_ref_extra=extra,host_only=host_only

if is_blank(url) then begin
 pr_syntax,'header=sock_response(url)'
 return,''
endif

durl=url_fix(url,_extra=extra)
stc=url_parse(durl)

if keyword_set(host_only) then begin
 stc.path='/'
 durl=url_join(stc)
endif

query=is_string(stc.query)
http=obj_new('http',_extra=extra)

http->head,durl,response,_extra=extra

;,head=~query

obj_destroy,http
sock_content_http,response,_extra=extra
return,response

end


