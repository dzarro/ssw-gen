;+
; Project     : VSO
;
; Name        : URL_FIX
;
; Purpose     : Fix a URL by ensuring it has a proper scheme
;
; Category    : utility system sockets
;
; Inputs      : URL = URL to fix (def to http://)
;
; Outputs     : DURL = URL with proper scheme (http:// or ftp://)
;
; Keywords    : FTP = force FTP scheme 
;               SECURE = force secure scheme (e.g. https://)
;
; History     : 16-Sept-2016, Zarro (ADNET)
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function url_fix,url,secure=secure,ftp=ftp

if is_blank(url) then return,''
durl=url
if ~has_url_scheme(durl) then begin
 if keyword_set(ftp) then scheme='ftp://' else scheme='http://'
 durl=scheme+url
endif

if keyword_set(secure) then begin
 durl=str_replace(durl,'http://','https://')
 durl=str_replace(durl,'ftp://','ftps://')
endif
return,durl
end
