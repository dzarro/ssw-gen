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
;               ENCODE = call URL_ENCODE on URL
;
; History     : 16-Sept-2016, Zarro (ADNET)
;               6-Oct-2018, Zarro (ADNET)
;               - added call to URL_ENCODE for query strings
;               10-Oct-2018, Zarro (ADNET)
;               - added /ENCODE
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function url_fix,url,secure=secure,ftp=ftp,_extra=extra,encode=encode

if is_blank(url) then return,''
durl=url[0]
if ~has_url_scheme(durl) then begin
 if keyword_set(ftp) then scheme='ftp://' else scheme='http://'
 durl=scheme+url
endif

if keyword_set(secure) then begin
 durl=str_replace(durl,'http://','https://')
 durl=str_replace(durl,'ftp://','ftps://')
endif

;-- encode special query characters

if keyword_set(encode) then begin
 stc=url_parse(durl)
 if is_string(stc.query) then begin
  equery=url_encode(stc.query,include=['>','<'],exclude=['=',';'],_extra=extra)
  spos=strpos(durl,'?')
  if spos gt 0 then begin
   burl=strmid(durl,0,spos+1)
   durl=burl+equery
  endif
 endif
endif

return,durl
end
