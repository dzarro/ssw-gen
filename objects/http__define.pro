;+
; Project     : HESSI
;
; Name        : HTTP__DEFINE
;
; Purpose     : Define a HTTP class
;
; Explanation : defines a HTTP class to open URL's and download (GET)
;               files. Example:
;
;               a=obj_new('http')                  ; create a HTTP object
;               a->open,'orpheus.nascom.nasa.gov'  ; open a URL socket 
;               a->head,'~zarro/dmz.html'          ; view file info
;               a->list,'~zarro/dmz.html'          ; list text file from server
;               a->copy,'~zarro/dmz.html'          ; copy file
;               a->close                           ; close socket
;
;               If using a proxy server, then set environmental 
;               http_proxy, e.g:
;
;               setenv,'http_proxy=orpheus.nascom.nasa.gov:8080'
;                
;               or
;
;               a->hset,proxy='orpheus.nascom.nasa.gov:8080'
;
; Category    : objects sockets 
;               
; Syntax      : IDL> a=obj_new('http')
;
; History     : Written, 6 June 2001, D. Zarro (EITI/GSFC)
;               Modified, 31 December 2002, Zarro (EER/GSFC) - made PORT
;               a property
;               Modified, 5 January 2003, Zarro (EER/GSFC) - improved
;               proxy support
;               13-Jan-2002, Zarro (EER/GSFC) - added cache support
;               and /reset
;               26-Jan-2003, Zarro (EER/GSFC) - added URL path check
;               4-May-2003, Zarro (EER/GSFC) - added POST support & switched
;               default to HTTP/1.1
;               20-Sep-2003, Zarro (GSI/GSFC) - added RANGE and CACHE-CONTROL directives
;               30-Sep-2003, Zarro (GSI/GSFC) - added READ_TIMEOUT property to control
;               proxy timeouts
;               28-Jun-2004, Kim Tolbert - set self.unit=0 after closing to avoid conflicts
;               15-Apr-2005, Zarro (L-3Com/GSFC) - added call to HTML_DECHUNK
;               20-Apr-2005, Zarro (L-3Com/GSFC) - allowed PORT to be set from URL
;               11-Sep-2005, Zarro (L-3Com/GSFC) - added COPY_FILE keyword to ::COPY
;               10-Nov-2005, Hourcle (L-3Com/GSFC) - added support for adding headers
;               11-Nov-2005, Zarro (L-3Com/GSFC) - changed from using pointer 
;                to keyword for extra header
;               1-Dec-2005, Zarro (L-3Com/GSFC) - minor bug fixes with
;                closing and validating servers
;               16-Dec-2005, Zarro (L-3Com/GSFC) - fixed case where
;                socket was not closing after a request
;               26-Dec-2005, Zarro (L-3Com/GSFC) - added more
;                diagnostic output to /VERBOSE
;               16-Nov-2006, Zarro (ADNET/GSFC) - sped up copy
;                by not checking remote file size twice.
;               1-March-07, Zarro (ADNET) - added call to better parse_url
;                function in corresponding method.
;               6-Mar-2007, SVH Haugan (ITA) - copy now passes info to 
;                self->make, to allow additional headers
;               21-July-2007, Zarro (ADNET) 
;                - changed parse_url function to url_parse to avoid 
;                  naming conflict with 6.4
;               3-Dec-2007, Zarro (ADNET)
;                - support copying files with unknown sizes
;               4-Jan-2008, Zarro (ADNET)
;                - added LOCAL_FILE keyword (synonym for COPY_FILE)
;               14-Sept-2009, Zarro (ADNET)
;                - added check for content-disposition (thanks, JoeH)
;                  and improved HTTP error code checking (but can be
;                  better)
;               24-Oct-2009, Zarro (ADNET)
;                - improved checking for remote file size by using GET
;                  instead of HEAD, which gets confused by redirects.
;               26-March-2010, Zarro (ADNET)
;                - fixed bug with URL not being parsed correctly when 
;                  server/host name not included.
;               27-May-2010, Kim.
;                - don't print clobber or same size messages if
;                  verbose is set
;               20-Sep-2010, Zarro (ADNET)
;                - added check for Redirects (not bullet-proof yet)
;               17-Nov-2010, Zarro (ADNET)
;                - added username/password support for proxy server
;               19-Aug-2011, Zarro (ADNET)
;                - improved PROXY support; added check for $no_proxy
;                9-Dec-2011, Zarro (ADNET)
;                - added check for proxy server during init
;                - fixed bug where proxy port wasn't appended
;                  to proxy host name 
;                - disabled no-cache directive as it was confusing
;                  proxy servers
;                16-Jan-2012, Zarro (ADNET)
;                - added support for entering protocol as number or
;                  string
;                19-Feb-2012, Zarro (ADNET) 
;                - changed message,/cont to message,/info because
;                  /cont was setting !error_state
;                26-Mar-2012, Zarro (ADNET)
;                - reworked ::LIST and ::COPY to better handle
;                  redirects
;                - added byte-order properties to better handle FITS
;                  files
;                25-May-2012, Zarro (ADNET)
;                - deprecated COPY_FILE keyword
;                15-July-2012, Zarro (ADNET)
;                - added support for $USER_AGENT environment variable
;                15-August-2012, Zarro (ADNET)
;                - more proxy tweaking and improved checking for
;                  existing files
;                7-September-2012, Zarro (ADNET)
;                - moved download progress messages to rdwrt_buff
;                - added more stringent check for valid HTTP status
;                  code 200
;                14-October-2012, Zarro (ADNET)
;                - added byte range support.
;                  [e.g., range='200-300' will download bytes 200-300
;                  of file]
;                14-November-2012, Zarro (ADNET)
;                - added NO_OPEN and NO_SEND keywords in REQUEST
;                  method (for testing only)
;                9-Dec-2012, Zarro (ADNET)
;                - changed HEAD method to read formatted text rather
;                  that unformatted bytes (seems faster) 
;                - retired unused properties/keywords (rawio,secure)
;                15-Dec-2012, Zarro (ADNET)
;                - improved error checking for connect/read timeouts
;                  on slow servers and networks
;                6-February-2013, Zarro (ADNET)
;                - made PROTOCOL property a float (removed HTTP/ string portion)
;                1-Mar-2013, Zarro (ADNET)
;                - replaced rdwrt_buff with rd_socket, which handles
;                  chunked-encoding
;                18-Apr-2013, Zarro (ADNET)
;                - removed redundant REDIRECT check from POST method 
;                25-May-2013, Zarro (ADNET)
;                - added file_poll_input check before reading socket
;                  [avoids socket hangs]
;                - restored NO-CACHE capability [CACHE=1 by default]
;                - skip REDIRECT check if URL contains a query
;                  [which implies GET or POST]
;                22-June-2013, Zarro (ADNET)
;                - removed default READ_ and CONNECT_TIMEOUT
;                  keywords; leave these for user to set.
;                26-July-2013, Zarro (ADNET)
;                -  URL_PARSE method now calls URL_PARSE function which
;                   handles username/password
;                22-October-2013, Zarro (ADNET)
;                - restored using last SERVER name if not entered in URL
;                20-November-2013, Zarro (ADNET)
;                - added calls to IDL network objects if try_network()
;                  is true
;                24-November-2013, Zarro (ADNET)
;                - replaced RD_SOCKET by SOCK_READU
;                - replaced HTTP_CONTENT by SOCK_CONTENT
;                28-December-2013, Zarro (ADNET)
;                - replaced try_network() by self->use_network() to
;                  avoid potential name conflicts
;                2-Jan-2014, Zarro (ADNET)
;                - added /BUFFER keyword to ::LIST 
;                - added NETWORK_TIMEOUT property
;                22-Jan-2014, Zarro (ADNET)
;                - added check for blank file name in URL
;                25-Feb-2014, Zarro (ADNET)
;                - moved $USER_AGENT check to ::MAKE
;                - added string(10b) for LF after HEAD/GET requests
;                 (some newer OS X systems weren't translating
;                 these correctly)
;                28-September-2014, Zarro (ADNET)
;                - added default IDL User-Agent
;                9-Oct-2014, Zarro (ADNET)
;                - do not delete current file if cancelling download
;                3-Nov-2014, Zarro (ADNET)
;                - more error checking for stricter servers
;                17-Nov-2014, Zarro (ADNET)
;                - added check for local vs remote timestamps
;                26-Dec-2014, Zarro (ADNET)
;                - replaced use_network method by try_network
;                5-February-2015, Zarro (ADNET)
;                - added additional checks for failed downloads
;                26-February-2015, Zarro (ADNET)
;                - added PROXY connection header
;                - added experimental FTP support
;                - added USERNAME,PASSWORD properties
;                2-March-2015, Zarro (ADNET)
;                - added URL input argument to INIT
;                - reinforced error checking
;                15-March-2015, Zarro (ADNET)
;                - made no-cache the default
;                23-March-2015, Zarro (ADNET)
;                - added check for header read timeout
;                4-Dec-2015, Zarro (ADNET)
;                - added check for query string errors
;                18-Mar-2016, Zarro (ADNET)
;                - added "Accept: */*" to HTTP header to satisfy
;                  some finicky servers
;                6-June-2016, Zarro (ADNET)
;                - added another PROXY server check
;                25-August-2016, Zarro (ADNET)
;                - added check for URL in Location redirect
;                5-September-2016, Zarro (ADNET)
;                - improved check for remote timestamp
;                21-September-2016, Zarro (ADNET)
;                - checked status of redirects
;                17-April-2017, Zarro (ADNET)
;                - print URL with status error message
;                21-April-2017, Stein Haugan (UiO)
;                - using WRITEU and adding CRLF for header
;                28-January-2018, Zarro (ADNET)
;                - made PORT a long variable
;                9-Oct-2018, Zarro (ADNET)
;                - added error check to POST return
;                17-Nov-2018, Zarro (ADNET)
;                - added check for password without username
;                3-March-2019, Zarro (ADNET) 
;                - added redirect to IDLnetURL for SSL
;                18-January-2020, S. Haugan (UiO)
;                - adding Host: header for http 1.0, not just >= 1.1
;
; Contact     : dzarro@solar.stanford.edu
;-

;-- init HTTP socket

function http::init,url,err=err,_ref_extra=extra

err=''

if ~allow_sockets(err=err,_extra=extra) then return,0b

;-- initialize USER-AGENT string 

sagent=sock_idl_agent()

;-- check for PROXY server

self->set_proxy

self->hset,buffsize=1024l,protocol=1.1,port=80L,_extra=extra,$
     user_agent=sagent,read_timeout=-1,connect_timeout=-1,cache=0,$
      network_timeout=300.d,scheme='http'

if is_string(url) then self->url_set,url,err=err

return,1

end
;--------------------------------------------------------------------------

;-- parse URL input

pro http::url_parse,url,server,file,port=port,query=query,scheme=scheme,$
                    username=username,password=password

query=''
file=''
server='' 
username=''
password=''
scheme=''
port=0L

if is_blank(url) then return
res=url_parse(url)
server=res.host
file=res.path
query=res.query
scheme=res.scheme

if is_string(query) then file=file+'?'+query
if is_string(res.port) then port=long(res.port)

;if is_blank(server) then host=self->hget(/server)
username=res.username
password=res.password
return & end

;---------------------------------------------------------------------------

pro http::cleanup

self->close

return & end

;--------------------------------------------------------------------------

function http::hget,_ref_extra=extra

return,self->getprop(_extra=extra)

end

;---------------------------------------------------------------------------
;-- send request for specified type [def='text']

pro http::send_request,url,type=type,err=err,request=request,$
                     _ref_extra=extra,verbose=verbose,no_send=no_send

err=''
request=''

verbose=keyword_set(verbose)
if verbose then mprint,'Requesting '+url

self->open,url,err=err,_extra=extra

if is_string(err) then begin
 self->close & return
endif

self->make,request,_extra=extra

if keyword_set(no_send) then return
self->send,request,err=err,_extra=extra

return & end

;--------------------------------------------------------------------------
;-- create request string

pro http::make,request,head=head,trace=trace,keep_alive=keep_alive,$
           no_close=no_close,post=post,form=form,put=put,$
           encode=encode,xml=xml,range=range,info=info

arg=self->hget(/file)
server=self->hget(/server)
port=self->hget(/port)

have_delim=stregex(arg,'^/',/bool)
if ~have_delim then arg='/'+arg

scheme=self->hget(/scheme)
secure=stregex(scheme,'^https',/bool)
if self->use_proxy() then begin
 tserver=server+':'+trim(port)
 arg=scheme+'://'+tserver+arg
endif

;-- assume GET request

cmd='GET '
method='get'
if keyword_set(head) then begin cmd='HEAD ' & method='head' & endif
if is_string(post) then begin cmd='POST ' & method='post' & endif
if keyword_set(trace) then begin cmd='TRACE ' & method='trace' & endif
if keyword_set(put) then begin cmd='PUT ' & method='put' & endif

cmd=cmd+arg

;-- set protocol

protocol=self->hget(/protocol)
if protocol eq 0 then protocol=1.1
hprotocol='HTTP/'+trim(protocol,'(f4.1)')
cmd=cmd+' '+hprotocol

;-- send user-agent in header

;header='Accept: */*'
header='Upgrade-Insecure-Requests: 1'
sagent=self->hget(/user_agent)
chk1=getenv('USER_AGENT')
chk2=getenv('user_agent')
if is_string(chk1) then sagent=chk1 else if is_string(chk2) then sagent=chk2
if is_string(sagent) then begin
 user_agent='User-Agent: '+sagent
 header=[header,user_agent]
endif

;-- if using HTTP/1.1, need to send host/port information

port=self->hget(/port)
port=trim(port)
host='Host: '+server+':'+port
header=[header,host]

;-- encode usename/password 

username=self->hget(/username)
password=self->hget(/password)

if is_string(username) then begin
 auth=username
 if is_string(password) then auth=username+':'+password
 bauth=idl_base64(byte(auth))
 bhead='Authorization: Basic '+bauth
 header=[header,bhead]
endif

;if self->use_proxy() then header=[header,'Proxy-Connection: Keep-Alive']

;-- append extra header info if included

if is_string(info) then header=[header,strarrcompress(info)]

cache=self->hget(/cache)
if ~cache then begin
 if protocol eq 1.1 then cache_header='Cache-Control: no-cache' else $
  cache_header='Pragma: no-cache'
 header=[header,cache_header]
endif

;-- if this is a POST request, then we compute content length
;   if this is a FORM then inform server of content type

if method eq 'post' then begin
 if keyword_set(xml) then header=[header,'Content-type: text/xml'] else $
  if keyword_set(form) then header=[header,'Content-type: application/x-www-form-urlencoded']
 length=strlen(post)
 header=[header,'Content-length: '+strtrim(length,2)] 
endif 

;-- check if partial ranges requested

if (method eq 'get') && is_string(range) then header=[header,'Range: bytes='+strtrim(range,2)]

persistent=keyword_set(no_close)
if protocol eq 1.0 && persistent then begin
 if is_number(keep_alive) then header=[header,'Keep-Alive: timeout='+trim(keep_alive)]
 header=[header,'Connection: keep-alive']
endif

if protocol eq 1.1 && ~persistent then header=[header,'Connection: close']

nhead=n_elements(header)

;if method eq 'post' then delim=string(0b) else delim=string(10b)
delim = ''
request=[cmd,header[0:(nhead-1)],delim]

if method eq 'post' then begin
 if keyword_set(encode) then request=[request,url_encode(post)] else $
  request=[request,post]
endif

return
end

;---------------------------------------------------------------------------
;-- set method

pro http::hset,file=file,server=server,connect_timeout=connect_timeout,port=port,$
               buffsize=buffsize,protocol=protocol,user_agent=user_agent,$
               proxy=proxy,read_timeout=read_timeout,scheme=scheme,debug=debug,$
               cache=cache,swap_endian=swap_endian,network_timeout=network_timeout,$
               swap_if_little_endian=swap_if_little_endian,no_proxy=no_proxy,$
               username=username,password=password,_extra=extra

if is_number(network_timeout) then self.network_timeout=network_timeout
if is_number(connect_timeout) then self.connect_timeout=connect_timeout
if is_number(read_timeout) then self.read_timeout=read_timeout
if is_string(file) then self.file=strtrim(file,2)
if is_string(server) then begin
 self->url_parse,server,host
 if is_string(host) then self.server=host
endif

if is_number(buffsize) then self.buffsize=abs(long(buffsize)) > 1l
if is_number(protocol) then self.protocol=float(protocol)
if is_string(user_agent,/blank) then self.user_agent=strtrim(user_agent,2)
if is_number(port) then self.port=long(port)

if is_string(proxy,/blank) then begin
 if strtrim(proxy,2) ne ''  then begin
  self->url_parse,proxy,host,port=port
  if is_string(host) then self.proxy_host=host 
  if is_number(port) then self.proxy_port=long(port)
 endif else begin
  self.proxy_host='' & self.proxy_port=0L
 endelse
endif

if is_string(scheme) then self.scheme=scheme
if is_number(cache) then self.cache= 0b > cache < 1b
if is_number(swap_endian) then self.swap_endian= 0b > swap_endian < 1b
if is_number(swap_if_little_endian) then self.swap_if_little_endian= 0b > swap_if_little_endian < 1b

if is_string(username,/blank) then self.username=username
if is_string(password,/blank) then self.password=password

if is_number(debug) then begin
 self.debug= 0b > byte(debug) < 1b
endif

if is_number(no_proxy) then begin
 self.no_proxy= 0b > byte(no_proxy) < 1b
endif

return & end

;---------------------------------------------------------------------------

pro http::help

mprint,'current server - '+self->hget(/server)
mprint,'current port - '+trim(self->hget(/port))
if self->use_proxy() then begin
 mprint,'proxy server - '+self->hget(/proxy_host)
 mprint,'proxy port - '+trim(self->hget(/proxy_port))
endif

if ~self->is_socket_open() then begin
 mprint,'No socket open'
 return
endif


return & end

;--------------------------------------------------------------------------
;-- set proxy parameters from HTTP_'HTTP_PROXYPROXY environment

pro http::set_proxy

http_proxy1=getenv('http_proxy')
http_proxy2=getenv('HTTP_PROXY')
if is_blank(http_proxy1) && is_blank(http_proxy2) then begin
 self.proxy_host=''
 self.proxy_port=0L
 return
endif

if is_string(http_proxy1) then http_proxy=http_proxy1 else http_proxy=http_proxy2

self->url_parse,http_proxy,host,port=port
if is_string(host) then self.proxy_host=host
if is_number(port) then self.proxy_port=long(port)

return & end

;----------------------------------------------------------------------------
;-- check if proxy server being used

function http::use_proxy,url

if self.no_proxy then return,0b

if is_string(url) then self->url_parse,url,server else $
 server=self->hget(/server)

return,use_proxy(server)

end

;-------------------------------------------------------------------

pro http::url_set,url,err=err

self->url_parse,url,server,file,port=port,scheme=scheme,$
       username=username,password=password,_extra=extra

if is_blank(server) then begin
 err='Missing remote server name.'
 mprint,err
 return
endif

self->hset,port=long(port)
self->hset,server=server
self->hset,scheme=scheme
self->hset,username=username
self->hset,password=password

if is_string(file) then self->hset,file=file else self->hset,file='/'

return & end

;------------------------------------------------------------------------
;-- open URL via HTTP 

pro http::open,url,err=err,_extra=extra,$
               no_open=no_open
err=''
self->url_set,url,err=err
if is_string(err) then return

;-- just parse and return

if keyword_set(no_open) then return
self->close

connect_timeout=self->hget(/connect_timeout)
if connect_timeout ge 0 then tconnect_timeout=connect_timeout

read_timeout=self->hget(/read_timeout)
if read_timeout ge 0 then tread_timeout=read_timeout

swap_endian=self->hget(/swap_endian)
swap_if_little_endian=self->hget(/swap_if_little_endian)

tserver=self->hget(/server)
tport=self->hget(/port)
if self->use_proxy() then begin
 tserver=self->hget(/proxy_host)
 tport=self->hget(/proxy_port)
 if self.debug then begin
  mprint,'PROXY_HOSTNAME: '+tserver
  mprint,'PROXY_PORT: '+trim(tport)
 endif
endif

on_ioerror,bail
socket,lun,tserver,tport,/get_lun,_extra=extra,error=error,$
  read_timeout=tread_timeout,connect_timeout=tconnect_timeout

if error eq 0 then begin
 self.unit=lun
 return
endif

bail: 

on_ioerror,null
;mprint,err_state()
;err='Failed to connect to '+tserver+' on port '+trim(tport)

err=err_state()
mprint,err
self->close

return & end

;-------------------------------------------------------------------------
;-- check if socket is open

function http::is_socket_open

stat=fstat(self.unit)
return,stat.open

end

;-------------------------------------------------------------------------
;-- close socket

pro http::close

if self.unit gt 0 then close_lun,self.unit
self.unit = 0
return & end

;---------------------------------------------------------------------------
;--- send a request to server

pro http::send,request,err=err,_ref_extra=extra


err=''
if is_blank(request) then return

if ~self->is_socket_open() then self->open,err=err,_extra=extra
if is_string(err) then return

if self.debug then begin
 mprint,request
endif

;printf,self.unit,request,format='(a)'
;for i=0,n_elements(request)-1 do printf,self.unit,request[i]

; Header/control structure lines must always (RFC 2616, RFC 1945) be
; delimited by CRLF; header is terminated by empty line, i.e. only CRLF. With
; format='(a)', IDL supplies the LF, with writeu we need to supply both.
CRLF = string([13b,10b])
i = 0
while request[i] ne '' do writeu,self.unit,request[i++]+CRLF
writeu,self.unit,CRLF ; End of hdr, done like this to highlight it
i++

; The following is (or should be - untested!) effectively what the old code
; did for any POST part - separating each request line with only LF. Should
; perhaps be changed so the printing of the entire request could be done with
; a single line - "printf,self.lun,request+CR,format='(a)'". Though the RFC's
; involved mention translation from just CR or just LF to CRLF for textual
; (i.e. encoded?) contents.
num_lines = n_elements(request)
while i le num_lines-1 do printf,self.unit,request[i++]

return & end

;------------------------------------------------------------------------
;-- send a TRACE request

pro http::trace,url,response,_ref_extra=extra,err=err

response=''
self->send_request,url,/trace,_extra=extra,err=err
if is_string(err) then begin
 self->close
 return
endif

self->read_response,response,err=err,_extra=extra

self->close

if is_string(response) && n_params() eq 1  then print,response

return & end

;------------------------------------------------------------------------
;-- check for IDLnetURL redirect

function http::use_network,url,_extra=extra,verbose=verbose

verbose=keyword_set(verbose)
if ~is_url(url,_extra=extra,verbose=verbose) then return,0b
val=try_network()
if val gt 0 then begin
 if val eq 2 then url=url_fix(url,/secure)
 return,1b
endif

;-- use IDLnetURL object if FTP 

use_network=is_ftp(url)  
if use_network && verbose then mprint,'Redirecting to IDLnetURL.'

return,use_network

end
;---------------------------------------------------------------------------
;--- send HEAD request to determine server response

pro http::head,url,response,_ref_extra=extra,err=err

err=''
response=''
if ~self->check_ssl(url,err=err) then return

if self->use_network(url,_extra=extra) then begin
 response=sock_head(url,err=err,_extra=extra)
 return
endif

self->send_request,url,/head,_extra=extra,err=err
if is_string(err) then begin
 self->close
 return
endif

self->read_response,response,err=err,_extra=extra

self->close

if is_string(response) && n_params() eq 1  then print,response

return & end

;----------------------------------------------------------------------------
;-- compare local and remote file sizes

function http::same_size,url,lfile,err=err,rsize=rsize,lsize=lsize,_ref_extra=extra

err=''

rsize=-1 & lsize=-1
if is_blank(url) || is_blank(lfile) then return,0b

lsize=file_size(lfile)
if lsize lt 0 then begin
 err='Local file not found'
 return,0b
endif

if ~self->file_found(url,response,err=err,_extra=extra) then return,0b
sock_content,response,size=rsize

return, lsize eq rsize

end

;----------------------------------------------------------------------------
;-- get URL file type

function http::get_url_type,url,err=err,_ref_extra=extra

err=''
if ~self->file_found(url,response,err=err,_extra=extra) then return,''
sock_content,response,type=type

return,type
end

;--------------------------------------------------------------------------
;-- send POST request to a server

pro http::post,url,content,output,_ref_extra=extra,err=err,$
 response_header=response_header

err='' & response_header=''
if is_blank(content) then begin
 output=''
 return
endif

;-- use IDL network object if requested

if self->use_network(url,_extra=extra) then begin
 output=sock_post(url,content,_extra=extra,err=err,response_header=response_header)
endif else begin
 self->print,url,output,post=content,_extra=extra,/no_check,err=err,response_header=response_header
 sock_content,response_header,code=code
 if code ne 200 then begin
  err=response_header
  mprint,err
  dprint,output
 endif
endelse

return & end

;--------------------------------------------------------------------------
;-- check if SSL

function http::check_ssl,url,err=err
if is_ssl(url) then begin
 err='HTTP socket currently does not support HTTPS/SSL.'
 mprint,err
 return,0b
endif
return,1b & end

;----------------------------------------------------------------------------
pro http::check,url,err=err,_ref_extra=extra

err='' 
if ~self->check_ssl(url,err=err) then return
 
self->head,url,response,err=err,_extra=extra
if is_string(err) then begin
 mprint,err
 return
endif
 
sock_content,response,code=code,_extra=extra
ok=self->status(code,err=err,url=url)

return & end

;--------------------------------------------------------------------------

function http::status,code,err=err,url=url

err=''
if ~is_number(code) then code='404'
scode=strtrim(code,2)
nok=stregex(scode,'^(4|5)',/bool)
if nok then begin
 err='This URL not accessible. Status code = '+trim(code)
 mprint,err
 if is_string(url) then mprint,url
 return,0b
endif

return,1b & end

;---------------------------------------------------------------------------
;--- list HTML file from server

pro http::list,url,output,_ref_extra=extra

output=''
if ~is_url(url,/verbose,_extra=extra) then return
use_network=self->use_network(url,_extra=extra)

if n_params() eq 1 then begin
 if use_network then $
  sock_list,url,_extra=extra else $
   self->print,url,_extra=extra
endif else begin
 if use_network then $
  sock_list,url,output,_extra=extra else $
   self->print,url,output,_extra=extra
endelse

return & end

;--------------------------------------------------------------------------

pro http::print,url,output,err=err,_ref_extra=extra,response_header=header,$
           verbose=verbose,no_check=no_check,buffer=buffer

output=''
if ~is_url(url,/verbose,err=err) then return

verbose=keyword_set(verbose)
err=''
if is_blank(url) || (n_elements(url) ne 1) then url='/'

self->url_parse,url,server,query=query

if is_blank(server) then begin
 err='Missing remote server name.'
 mprint,err
 return
endif

;-- check for redirect

durl=url
if ~keyword_set(no_check) && is_blank(query) then begin
 self->check,durl,err=err,location=location,verbose=verbose,_extra=extra
 if is_string(err) then return
 if is_url(location,/scheme) then begin
  if verbose then mprint,'Redirecting to '+location
  durl=location
  self->check,durl,err=err,_extra=extra,verbose=verbose
  if is_string(err) then return
 endif
endif

self->send_request,durl,err=err,_extra=extra
if is_string(err) then goto,bail

self->read_response,header,err=err,_extra=extra
if is_string(err) then goto,bail

sock_content,header,chunked=chunked,size=rsize,code=code
if chunked && verbose then mprint,'Reading chunked-encoded data...'

sock_readu,self.unit,output,maxsize=rsize,chunked=chunked,ascii=~keyword_set(buffer),err=err,debug=self.debug,_extra=extra

bail: 

self->close
if is_number(code) then scode=strmid(strtrim(code,2),0,1) else scode='2'

if (n_params() eq 1) || is_string(err) || (scode ne '2') then if is_string(output) then print,output

return & end

;--------------------------------------------------------------------------
;-- check if file exists on server by sending a request 
;   and examining response 

function http::file_found,url,response,err=err,_ref_extra=extra,$
               verbose=verbose

err=''
self->send_request,url,err=err,_extra=extra
if is_string(err) then begin
 self->close
 return,0b
endif

;-- examine the response header

self->read_response,response,_extra=extra
sock_content,response,code=code

if code ne 200 then begin
 err='Could not find - '+url 
 if keyword_set(verbose) then mprint,err
 self->close
 return,0b
endif

return,1b & end


;---------------------------------------------------------------------
;-- check HTTP header for tell-tale errors

pro http::check_header,content,err=err,verbose=verbose,url=url
err=''
verbose=keyword_set(verbose)

if is_string(url) then tfile=url else tfile=''

chk=where(stregex(content,'http.+200.*',/bool,/fold),count)
if count eq 1 then return

;u=stregex(content,'http.+ ([0-9]+)(.*)',/sub,/extr,/fold)
mprint,content[0]

chk=where(stregex(content,'http.+400.*',/bool,/fold),count)
if count gt 0 then begin
 err=strcompress('File '+tfile+' bad request')
 if verbose then mprint,err
 return
endif

chk=where(stregex(content,'http.+404.*',/bool,/fold),count)
if count gt 0 then begin
 err=strcompress('File '+tfile+' not found')
 if verbose then mprint,err
 return
endif

chk=where(stregex(content,'http.+403.*',/bool,/fold),count)
if count gt 0 then begin
 err=strcompress('File '+tfile+' access denied')
 if verbose then mprint,err
 return
endif

err=strcompress('File '+tfile+' unknown error')
if verbose then mprint,err

return

end

;---------------------------------------------------------------------------
;-- read ASCII response header

pro http::read_response,header,err=err

network_timeout=self->hget(/network_timeout)
if network_timeout ge 0 then tnetwork_timeout=network_timeout

tries=1
again:
on_ioerror, bail
err='' 
text='xxx'
header=''

while strtrim(text,2) ne '' do begin
 if ~file_poll_input(self.unit,timeout=tnetwork_timeout) then begin
  help,/files
  err='No response from server.'
  mprint,err
  header=''
  return
 endif 
 readf,self.unit,text
; if self.debug then print,text
 header=[header,text]
endwhile

if tries eq 2 then mprint,'Success!'
np=n_elements(header)
if np gt 1 then begin
 header=header[1:np-1]
 return
endif

bail:on_ioerror,null
tries=tries+1
mprint,err_state()
message,/reset
if tries eq 2 then begin
 mprint,'Retrying...'
 goto,again
endif
header=''
err='No response from server.'

return & end

;---------------------------------------------------------------------------
;-- GET binary data from server

pro http::copy,url,new_name,_ref_extra=extra

if ~is_url(url,/verbose,_extra=extra) then return
use_network=self->use_network(url,_extra=extra)

if use_network then $
 sock_get,url,new_name,_extra=extra else $
  self->get,url,new_name,_extra=extra

return & end

;-------------------------------------------------------------------------
pro http::get,url,new_name,err=err,out_dir=out_dir,verbose=verbose,$
                    clobber=clobber,status=status,prompt=prompt,$
                    cancelled=cancelled,_ref_extra=extra,use_content=use_content,$
                    local_file=local_file,no_check=no_check,response=response

status=0
err=''
verbose=keyword_set(verbose)
use_content=keyword_set(use_content)
cancelled=0b
local_file=''
clobber=keyword_set(clobber)

self->url_parse,url,server,file,query=query

if is_blank(server) || is_blank(file) then begin
 err='Missing or invalid URL filename entered.'
 mprint,err
 return
endif

if is_string(out_dir) then tdir=local_name(out_dir) else tdir=curdir()

break_file,local_name(file),dsk,dir,name,ext
out_name=trim(name+ext)

if is_string(new_name) then begin
 break_file,local_name(new_name),dsk,dir,name,ext
 out_name=trim(name+ext)
 if is_string(dsk+dir) then tdir=trim(dsk+dir)
endif

;-- ensure write access to download directory

if ~write_dir(tdir,/verbose,err=err) then return
ofile=concat_dir(tdir,out_name)
rsize=0l
osize=0l

;-- send HEAD request to check for redirect (except for queries)

durl=url
pre_check=~keyword_set(no_check) ; && is_blank(query)

if pre_check then begin
 self->check,durl,err=err,location=location,_extra=extra
 if is_string(err) then return

;-- check for redirect

 if is_url(location,/scheme) then begin
  durl=location
  if verbose then mprint,'Redirecting to '+durl
  self->check,durl,err=err,_extra=extra
  if is_string(err) then return
  ofile=concat_dir(tdir,file_basename(durl)) 
 endif

endif

;-- send get request

self->send_request,durl,_extra=extra,err=err
if is_string(err) then begin
 self->close
 return
endif

self->read_response,response,_extra=extra,err=err
if is_string(err) then begin
 self->close
 return
endif

sock_content,response,code=code,size=rsize,chunked=chunked,$
                     content_location=content_location,$
                     disposition=disposition,type=type,date=rdate

ok=self->status(code,err=err,url=durl)
if ~ok then begin
 self->close
 return
endif

;-- check for file name change

if is_string(disposition) then ofile=concat_dir(tdir,disposition) else $
 if is_string(content_location) && use_content then ofile=concat_dir(tdir,file_basename(content_location))

if stregex(ofile,'\?|\&',/bool) then begin
 err='Could not determine download file name - check query string.'
 mprint,err
 self->close
 return
endif

;-- if file exists, download a new one if /clobber or local size
;   differs from remote or if remote file is newer

chk=file_info(ofile)
have_file=chk.exists
osize=chk.size

;-- check if remote file is newer

newer_file=1b
if valid_time(rdate) && have_file then begin
 local_time=anytim(file_time(ofile))
 remote_time=anytim(rdate)
 dprint,'% Remote file time: ',anytim(remote_time,/vms)
 dprint,'% Local file time: ',anytim(local_time,/vms)
 newer_file=remote_time gt local_time
 if verbose then if newer_file then mprint,'Remote file is newer than local file.'
endif

size_change=1b
if (rsize gt 0) && (osize gt 0) then size_change=(rsize ne osize)
download=~have_file || clobber || size_change || newer_file

if ~download then begin
 if verbose then mprint,'Identical local file '+ofile+' already exists (not downloaded). Use /clobber to re-download.'
 local_file=ofile
 self->close
 status=2
 return
endif

;-- check if FITS

;is_fits=stregex(type,'(fts)|(fits)',/bool)
;if is_fits then begin
; if verbose then mprint,'Downloading FITS image...'
; self->hset,/swap_if_little_endian
;endif
 
;-- prompt before downloading

if keyword_set(prompt) && (rsize gt 0) then begin
 ans=xanswer(["Remote file: "+ofile+" is "+trim(str_format(rsize,'(i10)'))+" bytes.",$
              "Proceed with download?"])
 if ~ans then begin self->close & return & endif
endif

if rsize eq 0 then mess='?' else mess=trim(str_format(rsize,"(i10)"))
cmess=['Please wait. Downloading...','File: '+file_basename(ofile),$
       'Size: '+mess+' bytes',$
       'From: '+server,'To: '+tdir]

if verbose && chunked then mprint,'Reading chunked-encoded data...'

;-- read bytes from socket into temporary file

tfile=ofile+'_t'

t1=systime(/seconds)

sock_readu,self.unit,file=tfile,maxsize=rsize,err=err,counts=counts,omessage=cmess, $
          _extra=extra,cancelled=cancelled,chunked=chunked,debug=self.debug

if ((rsize gt 0) && (counts ne rsize)) || is_string(err) || cancelled then begin
; if ~cancelled && is_string(err) && is_string(ofile) then begin
;  file_delete,ofile,/quiet,/noexpand_path,/allow_nonexistent
; endif
 if is_string(tfile) then file_delete,tfile,/quiet,/noexpand_path,/allow_nonexistent
 return
endif

if verbose then begin
 if rsize eq 0 then rsize=counts
 t2=systime(/seconds)
 tdiff=t2-t1
 m1=trim(string(rsize,'(i10)'))+' bytes of '+file_basename(ofile)
 m2=' copied in '+strtrim(str_format(tdiff,'(f8.2)'),2)+' seconds.'
 mprint,m1+m2
endif

status=1
file_move,tfile,ofile,/overwrite,/allow_same
file_chmod,ofile,/a_write,/a_read

;-- update local time of file to same time as server version

if valid_time(rdate) then file_touch,ofile,rdate

local_file=ofile

bail:on_ioerror,null
self->close
if status eq 0 then begin
 err='Error downloading file.'
 mprint,err
endif

return & end

;--------------------------------------------------------------------------
;-- upload file to server

pro http::put,file,url,err=err,_ref_extra=extra

status=0
err=''

if is_blank(file) then begin
 err='Input file name not entered.'
 mprint,err
 return
endif

if ~file_test(file,/read,/regular) then begin
 err='Input file invalid or unreadable.'
 mprint,err
 return
endif
self->url_parse,url,server,path

if is_blank(server) then begin
 err='Server name not entered.'
 mprint,err
 return
endif

;-- send PUT request

dfile=file_basename(file)
if is_blank(path) then path='/' else path='/'+path

self->hset,file=concat_dir(path,dfile)

self->send_request,url,_extra=extra,err=err,/put,/no_send
if is_string(err) then begin
 self->close
 return
endif

self->close
return

self->read_response,response,_extra=extra,err=err
if is_string(err) then begin
 self->close
 return
endif

sock_content,response,code=code

ok=self->status(code,err=err,url=url)
if ~ok then begin
 self->close
 return
endif

sock_writeu,self.unit,file_stream(file),err=err,_extra=extra

self->close

return & end

;-----------------------------------------------------------------------
pro http__define                 

struct={http,server:'',unit:0l,file:'',connect_timeout:0.,buffsize:0l,$
         user_agent:'',protocol:0.,proxy_host:'',proxy_port:0L,swap_endian:0b,$
         swap_if_little_endian:0b,network_timeout:0.d,username:'',password:'',$
         port:0L,read_timeout:0.,cache:0b,scheme:'',no_proxy:0b,inherits gen}

return & end
