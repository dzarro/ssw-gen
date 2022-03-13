;+
; Project     : HESSI
;                  
; Name        : HAVE_NETWORK
;               
; Purpose     : check if network connection is available
;                             
; Category    : system utility sockets
;               
; Syntax      : IDL> a=have_network()
;
; Optional    : URL = URL to test [def eq 'www.google.com']
; Inputs      :
;                                        
; Outputs     : 1/0 if yes/no
;
; Keywords    : INTERVAL = seconds between rechecking
;                          (otherwise use result of last check) 
;               RESET = set to force check without waiting INTERVAL
;               (same as INTERVAL=0)
;               USE_NETWORK = set to use IDL network object (def)
;               RESPONSE_CODE = IDL network object response code
;               CODE = HTTP status code
;               FULL_PATH = check full URL path if included (def is
;               not to)
;                   
; History     : 8 Mar 2002, Zarro (L-3Com/GSFC)
;               22 Apr 2005, Zarro (L-3Com/GSFC) - return error mprint
;               when network is down.
;               1 Dec 2005, Zarro (L-3Com/GSFC) - removed http object
;               from common because of unwanted side effects.
;               13 Jan 2007, Zarro (ADNET/GSFC) - added support for
;               checking multiple urls
;               18 Feb 2012, Zarro (ADNET/GSFC) 
;               - passed connect_timeout=15 to HTTP object to return
;                 if host is down
;               20 Feb 2012, Zarro (ADNET) 
;               -use sock_response for proxy URL's
;               25 Mar 2012, Zarro (ADNET)
;               - added check for URL redirects
;               25-Dec-2012, Zarro (ADNET)
;               - added USE_NETWORK
;               12-Nov-2013, Zarro (ADNET)
;               - made USE_NETWORK the default (for PROXY servers)
;               1-Jan-2014, Zarro (ADNET)
;               - added support for arbitrary ports
;               13-Oct-14, Zarro (ADNET)
;               - check for more error codes
;               3-Nov-14, Zarro (ADNET)
;               - relaxed error code checks
;               19-Sep-16, Zarro (ADNET)
;               - add call to URL_FIX to support HTTPS
;               26-Sep-16, Zarro (ADNET)
;               - added call to IS_HTTPS
;               10-Oct-16, Zarro (ADNET)
;               - really made USE_NETWORK the default
;               31-Jan-17, Zarro (ADNET)
;               - added RESPONSE_CODE
;               7-Mar-2019, Zarro (ADNET)
;               - deprecated old SOCK_RESPONSE
;               4-October-2019, Zarro (ADNET)
;               - improved error propagation via keyword inheritance
;               27-November-2019, Zarro (ADNET)
;               - added LOCATION keyword
;               15-February-2022, Zarro (ADNET)
;               - added FULL_PATH
;
; Contact     : dzarro@solar.stanford.edu
;-    

function have_network,url,verbose=verbose,err=err,_ref_extra=extra,$
         interval=interval,reset=reset,code=code,$
         response_code=response_code,location=location,full_path=full_path

common have_network,urls

err=''
reset=keyword_set(reset)
verbose=keyword_set(verbose)

if reset then delvarx,urls
if is_string(url) then test_url=strtrim(url,2) else test_url='www.google.com'

full_path=keyword_set(full_path)
test_url=url_fix(test_url,_extra=extra)
purl=url_parse(test_url)
test_host=purl.host
test_port=purl.port
test_path=purl.path
test_scheme=purl.scheme
test_url=test_scheme+'://'+test_host+':'+test_port
if full_path && is_string(test_path) then test_url=test_url+'/'+test_path
if ~is_number(interval) then interval=30.
now=systime(/seconds)

;-- check if this url was checked recently

count=0
if is_struct(urls) then begin
 chk=where(test_url eq urls.url,count)
 j=chk[0]
 if count eq 1 then begin
  state=urls[j].state
  time=urls[j].time
  err=urls[j].err
  code=urls[j].code
  response_code=urls[j].response_code
  location=urls[j].location

;-- return last state if last time less than interval

  if (now-time) lt interval then begin
   if ~state then begin
    if verbose && is_string(err) then mprint,err,/info
   endif
   return,state
  endif
 endif
endif

;-- try to connect to url

state=0b
state=sock_check(test_url,_extra=extra,err=err,code=code,location=location,$
                   verbose=verbose,response_code=response_code)

;-- if location is returned in header, then most likely a redirect

;-- update this url

if count eq 1 then begin
 urls[j].state=state
 urls[j].time=systime(/seconds)
 urls[j].err=err
 urls[j].code=code
 urls[j].response_code=response_code
 urls[j].location=location
endif else begin
 now=systime(/seconds)
 new_url={url:test_url,location:location,state:state,time:now,err:err,code:code,response_code:response_code}
 urls=merge_struct(urls,new_url)
endelse

return,state

end
