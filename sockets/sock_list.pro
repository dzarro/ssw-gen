;+
; Project     : VSO
;
; Name        : SOCK_LIST
;
; Purpose     : Wrapper around IDLnetURL object to list URL.
;
; Category    : utility system sockets
;
; Syntax      : IDL> sock_list,url,output
;
; Inputs      : URL = URL to list
;
; Outputs     : OUTPUT = string or byte array (if /buffer) 
;
; Keywords    : BUFFER = return output as byte array
;               NO_CHECK = don't check input URL
;               CACHE = cache and return last cache results
;
; History     : 20-July-2011, Zarro (ADNET) - written
;               7-November-2013, Zarro (ADNET) 
;               - renamed from SOCK_CAT to SOCK_LIST
;               31-December-2013, Zarro (ADNET)
;               - added /BUFFER keyword
;               10-Feb-2015, Zarro (ADNET)
;               - pass input URL directly to IDLnetURL2 to parse
;                 PROXY keyword properties in one place
;               15-June-2016, Zarro (ADNET)
;                - added call to SOCK_DIR for FTP listing
;               16-June-2016, Zarro (ADNET)
;               - deprecated /OLD_WAY (caused recursion situations)
;               16-Sep-2016, Zarro (ADNET)
;               - added call to URL_FIX
;               10-Oct-2016, Zarro (ADNET)
;               - added check for URL redirect
;               21-Dec-2016, Zarro (ADNET)
;               - fixed bug with listing FTP sites and added /cache
;               30-January-2017, Zarro (ADNET)
;               - added check for SSL support
;               8-December-2017, Zarro (ADNET)
;               - added more error checking
;-

pro sock_list,url,output,_ref_extra=extra,err=err,buffer=buffer,debug=debug,no_check=no_check,$
              cache=cache,verbose=verbose

err=''
output=''
verbose=keyword_set(verbose)

if ~since_version('6.4') then begin
 err='Requires IDL version 6.4 or greater.'
 output=''
 mprint,err
 return
endif

if ~is_url(url) then begin
 pr_syntax,'sock_list,url,[output]','Invalid or missing input URL.',err=err
 return
endif

if keyword_set(verbose) then mprint,'Listing '+url

;-- cache for list results

cache=keyword_set(cache)
buffer=keyword_set(buffer)
turl=url+trim(buffer)
if cache then dprint,'% SOCK_LIST: using cache.'

if cache then begin
common sock_list,fifo
 if ~obj_valid(fifo) then fifo=obj_new('fifo')
 last=fifo->get(turl,status=status)
 if status then begin
  output=last
  if (n_params() eq 1) then if is_string(output) then print,output
  return
 endif
endif

;-- redirect FTP

if is_ftp(url) then begin
 sock_dir_ftp,url,output,debug=debug,err=err,_extra=extra
 if (n_params() eq 1) then if is_string(output) then print,output
 if cache then if is_blank(err) then fifo->set,turl,output
 return
endif

;-- catch errors

error=0
catch, error
if (error ne 0) then begin  
 catch, /cancel
 if keyword_set(debug) then mprint,err_state()  
 if obj_valid(ourl) then begin
  ourl->getproperty,response_code=rcode,response_header=rheader
  sock_content,rheader,code=code
  sock_error,url,code,response_code=ocode,err=err,verbose=verbose
  obj_destroy,ourl
 endif
 err='Remote listing failed for '+url 
 if verbose then mprint,err
 message,/reset
 return
endif 

durl=url_fix(url,_extra=extra)
stc=url_parse(durl)
query=stc.query

if ~keyword_set(no_check) && is_blank(query) then begin
 for i=0,1 do begin
  ok=sock_check(durl,_extra=extra,code=code,debug=debug,location=location,response_code=ocode)
  if ~ok then begin
   sock_error,durl,code,response_code=ocode,err=err,verbose=verbose
   return
  endif

;-- check if redirecting

  if is_string(location) then begin
   if verbose then mprint,'Redirecting to '+location
   durl=url_fix(location,_extra=extra)
  endif else break
 endfor

endif
  
ourl=obj_new('idlneturl2',durl,_extra=extra,debug=debug)

;-- list URL 

output = oUrl->Get(string_array=~buffer,buffer=buffer)
obj_destroy,oUrl

if (n_params() eq 1) then if is_string(output) then print,output
if cache then fifo->set,turl,output
 
return & end  
