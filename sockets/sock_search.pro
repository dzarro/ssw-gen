;+
; Project     : VSO
;
; Name        : SOCK_SEARCH
;
; Purpose     : Search for files or directories at a URL 
;
; Category    : utility system sockets
;
; Syntax      : IDL> sock_search,url,results
;
; Inputs      : URL = remote URL directory to search
;
; Outputs     : RESULTS = remote file or directory names
;
; Keywords    : ERR = error string
;               COUNT = # of results
;               DIRECTORY = search for directories
;               DATES = file/directory timestamps
;               LISTING = file listing on server
;
; History     : 20-Dec-2018, Zarro (ADNET)
;               21-Mar-2019, Zarro (ADNET)
;               - added DATES
;               4-October-2019, Zarro (ADNET)
;               - improved error propagation via keyword inheritance
;               24-Jan-2021, Zarro (ADNET)
;               - fixed bug with returned LISTING
;-

pro sock_search,url,results,_ref_extra=extra,err=err,count=count,directory=directory,dates=dates,$
                listing=listing

results='' & count=0 & dates='' & listing=''
err=''

sock_list_new,url,out,_extra=extra,/scheme,err=err,location=location,short=0

if is_string(err) then return

;if is_ftp(url) then stop,1

;-- parse out file or directory names

directory=keyword_set(directory)

spec='[^\/\?\:\=\;\,\\]+'
delim=''
if directory then delim='\/'
sdate='> *([0-9]{4}-[0-9]{2}-[0-9]{2} *[0-9]{2}:[0-9]{2}) *<'
chk1=stregex(out,'<a href="('+spec+')'+delim+'">'+spec+delim+'</a>.+'+sdate+'.+',/ext,/sub)
chk1=strtrim(chk1,2)
names=trim(comdim2(chk1[1,*]))
dates=trim(comdim2(chk1[2,*])) 
chk2=where(names ne '' and dates ne '',count)
if count gt 0 then begin
 listing=out[chk2]
 if is_string(location) then durl=location else durl=url
 if stregex(durl,'/$',/bool) then alim='' else alim='/'
 anames=names[chk2]
 if ~directory then anames=ascii_decode(anames)
 results=durl+alim+anames
 dates=dates[chk2]
endif else begin
 results=''
 dates=''
 listing=out
endelse

if count eq 1 then begin
 results=results[0] & dates=dates[0] & listing=listing[0]
endif

if (n_params() eq 1) then print,results
return & end
