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
; Keywords    : NO_PORT = exclude port number if standard for scheme
;
; History     : 11-November-2018, Zarro (ADNET) - written
;               21-November-2018, Zarro (ADNET) - added NO_PORT
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function url_join,stc,no_port=no_port

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

;-- don't include default port numbers

url=url+stc.host
no_port=keyword_set(no_port)
port=trim(stc.port)
if is_string(port) then begin
 add_port=1b
 if no_port then begin
  case 1 of
   (port eq '80' && scheme eq 'http'): add_port=0b
   (port eq '443' && scheme eq 'https'): add_port=0b
   (port eq '21' && scheme eq 'ftp'): add_port=0b
   (port eq '22' && scheme eq 'ftps'): add_port=0b
   else: add_port=1b
  endcase
 endif
 if add_port then url=url+':'+port
endif

if is_string(stc.path) then begin
 delim='/'
 if strpos(stc.path,'/') eq 0 then delim='' 
 url=url+delim+stc.path
endif
if is_string(stc.query) then url=url+'?'+stc.query

return,url

end
