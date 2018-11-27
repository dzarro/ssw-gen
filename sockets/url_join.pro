;+
; Project     : VSO
;
; Name        : URL_JOIN
;
; Purpose     : Join structure elements returned from URL_PARSE into URL string
;
; Category    : utility sockets
;
; Inputs      : STC = URL structure
;
; Outputs     : URL = URL_SCHEME://URL_USERNAME:URL_PASSWORD@URL_HOST:URL_PORT/URL_PATH?URL_QUERY
;
; Keywords    : None
;
; History     : 11-November-2018, Zarro (ADNET) - written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function url_join,stc

url=''
if ~is_struct(stc) then return,url
temp=url_parse()
if ~match_struct(stc,temp,/tags) then return,url
if is_blank(stc.host) then return,url

scheme=stc.scheme
if is_blank(scheme) then scheme='http' 
url=url+scheme+'://'
if is_string(stc.username) || is_string(stc.password) then begin
 if is_string(stc.username) && is_blank(stc.password) then url=url+stc.username+'@'
 if is_string(stc.username) && is_string(stc.password) then url=url+stc.username+':'+stc.password+'@'
endif

url=url+stc.host
if is_string(stc.port) then url=url+':'+stc.port
if is_string(stc.path) then begin
 delim='/'
 if strpos(stc.path,'/') eq 0 then delim='' 
 url=url+delim+stc.path
endif
if is_string(stc.query) then url=url+'?'+stc.query

return,url

end
