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
;               7-Mar-2019, Zarro (ADNET)
;               - added check for port 443 in HTTPS
;               5-Nov-2019, Zarro (ADNET)
;               - added check for 80:443
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function url_fix,url,secure=secure,ftp=ftp,_extra=extra,encode=encode


if is_blank(url) then return,''
durl=strtrim(url[0],2)
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

;-- ensure ports are self-consistent

if stregex(durl,'^https\:\/\/',/bool) then begin
 durl=str_replace(durl,':80:443',':443')
 durl=str_replace(durl,':443:80',':443')
 durl=str_replace(durl,':80',':443')
endif

if stregex(durl,'^http\:\/\/',/bool) then begin
 durl=str_replace(durl,':80:443',':80')
 durl=str_replace(durl,':443:80',':80')
 durl=str_replace(durl,':443',':80')
endif

if stregex(durl,'^ftps\:\/\/',/bool) then durl=str_replace(durl,':21',':22')
if stregex(durl,'^ftp\:\/\/',/bool) then durl=str_replace(durl,':22',':21')

return,durl
end
