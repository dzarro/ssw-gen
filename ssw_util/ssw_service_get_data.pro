pro ssw_service_get_data, jobid, job_path, out_dir=out_dir, loud=loud, progress=progress, $
   path_only=path_only, url_only=url_only, name_only=name_only, name_path=name_path, $
   waves=waves, time_range=time_range, minutes_cadence=minutes_cadence, $
   no_confirm=no_confirm, temp=temp, debug=debug, clobber=clobber, curl=curl
;
;+
;   Name: ssw_service_get_data
;
;   Purpose: get data from some ssw service -> ssw session 
;
;   Input Parameters:
;      jobid - ssw service JobID 
;
;   Output Parameters:
;      job_path - fully qualified data path or url implied by JobID
;
;   Keyword Paramters:
;      out_dir - optional output directory for data transfers
;      loud - (switch) - if set, show some diagnostics
;      path_only/url_only - (switches) if set, return path or url in <job_path> w/no Transfers
;      name_only - (switch) - if set, return full names of files to get in name_path keyword w/no transfers
;      name_path - if name_only is set, return full names of files to get in name_path
;      waves - optionally, only this subset of WAVES (comma delimited list)
;      time_range - optionally, restrict to this time_range
;      minutes_cadence - optionally, limit cadence to this #minutes
;      no_confirm - set this if you Know that you've asked for a rediculous amount of data
;                   Default will warn and offer calling suggestions for throttling
;      curl - if set, replace sock_list/sock_copy with curl_copy ; https/SSL support in the cURL - (default for IDL version < 8.4 when https support > DMZarro suite enabled)
;
;   History:
;      21-oct-2009  - S.L.Freeland - ssw web services helper routine
;      12-may-2011 - S.L.Freeland - add optional throttles including:
;                       WAVES, TIME_RANGE, MINUTES_CADENCE
;      23-jan-2012 - S.L.Freeland - paren->brackets for subscripting (avoid list.pro collision)
;       9-aug-2013 - S.L.Freeland - tweak parent url due to sdowww.lmsal.com reconfiguration
;       24-Mar-2015, Kim Tolbert - add name_only, name_path keywords. Added [0] when setting ssw[w] for
;                    freaky case where two items returned by where.
;       24-oct-2016 - S.L.Freeland - add /TEMP & /DEBUG and server transitional logic; backwardly compatible I hope
;        7-nov-2016 - S.L.Freeland - tweaked 24-oct-2016 mod a bit, pass clobber->sock_list
;       17-nov-2016 - S.L.Freeland - tweaked 7-nov-2016 mod; Thanks to Dominic! 
;       19-mar-2020 - S.L.Freeland - default parent (@lmsal) http->https due to global lmsal.com domain->https:
;        9-aug-2020 - S.L.Freeland - use curl_copy in place of sock_list/sock_copy for IDL Version < 8.4 (or if /CURL keyword set for testing etc)
;
;-

loud=keyword_set(loud)
progress=keyword_set(progress)
debug=keyword_set(debug)
use_curl=keyword_set(curl) or ~since_version('8.4')  ; curl in place of IDL/sockect suite for https/SSL supoort

if n_elements(jobid) eq 0 then begin 
    box_message,'Need ssw service jobid..., returing'
    return
endif

parent=get_logenv('ssw_service_data')
if parent eq '' then $
   parent='https://sdowww.lmsal.com/sdomedia/ssw/media/ssw/ssw_client/data/'

dataurl=parent+jobid +'/'

temp=keyword_set(temp) or ~sock_check(dataurl)
if temp then dataurl=str_replace(dataurl,'/data/','/data_temp/') ; ugly, albeit transitional
job_path=dataurl
cdir=curdir() ; save current , in case I have to move around a bit (don't clobber local "index.html"s for example!)

path_only=keyword_set(path_only)
url_only=keyword_set(url_only)
if debug then stop,'jobpath,temp,dataurl,parent
if path_only or url_only and n_params() eq 2 then begin 
   if path_only then job_path=str_replace(job_path,'http://sdowww.lmsal.com/sdomedia',(['/archive/sdo/media','/oberon'])(temp))
   return ; !!!! EARLY (unstructured) exit
endif 
if use_curl then begin 
  rindex=dataurl+'index.html'
  curl_copy,rindex,OUT_DIR=get_temp_dir(), local_file=sindex ; remote jobid index.html -> local vi cURL (don't  clobber local index.html in PWD!, important safety tip)
  idata=rd_tfile(sindex) ; starr of jobid index.html (includes pointers to per-wave .list urls, since no sock_list <8.4 or cURL equivilent(?)
  if debug then stop,"curl .list listing,pwd,idata,ssl=where([strmatch(idata,'*href*.list*',/fold_case]))"
  ssm=strmatch(idata,'*href*.list*',/fold_case)
  ssl=where(ssm,lcnt)
  if lcnt eq 0 then begin 
     box_message,'No per-Wave files found(?) at >> ' +dataurl[0] + ' so bailing...'
     return
   endif 
   xlist=idata[ssl]
   ;xlist=strextract(idata[ssl],'"') ; this is done in common sock/curl method below so commented this out 
endif else begin
   sock_list,dataurl,xlist
   xlist=web_dechunk(xlist)
endelse

ss=where(strpos(xlist,'.list') ne -1,lcnt)
if lcnt eq 0 then ss=where(strpos(xlist,'.dat') ne -1, lcnt)
if lcnt eq 0 then xlist='' else xlist=xlist[ss]

allwaves=str2arr('94,131,171,211,193,195,284,304,335,1600,1700,4500,mag,blos,cont')

case n_elements(waves) of
   1: nwaves=strtrim(str2arr(waves),2)
   0: nwaves=allwaves
   else: nwaves=strtrim(waves,2)
endcase


nw=n_elements(nwaves)
ssw=intarr(nw)
for w=0,n_elements(nwaves)-1 do begin
   ssw[w]=(where(strpos(xlist,'_'+nwaves(w)+'_') ne -1 or strpos(xlist,'_'+nwaves(w)+'.') ne -1))[0]
endfor
wlist=where(ssw ne -1, lcnt)

; special cases
preops=strpos(job_path,'preops') ne -1

no_confirm=keyword_set(no_confirm)

if preops and 1-no_confirm then begin 
   if keyword_set(time_range) or keyword_set(minutes_cadence) or keyword_set(waves) then begin 
      box_message,'preops'
   endif else begin 
      box_message,['Warning: Preops Data','May be LARGE', $
        'See TIME_RANGE, WAVES, and MINUTES_CADENCE keywords to throttle', $
        '-or- use /NO_CONFIRM if you really want/need the whole shebang...']
      lcnt=0 ; inhibit this request
   endelse
endif

name_path = ''

if lcnt gt 0 then begin
   lfiles=strextract(xlist[ssw[wlist]],'href="','"') 
   lurls=dataurl+lfiles
   for i=0,lcnt-1 do begin 
      if loud then box_message,'Listing>> ' + lfiles(i) 
      if use_curl then begin 
         curl_copy,lurls[i],local_file=local_file
         sswfiles=rd_tfile(local_file)
if debug then stop,'sswfiles,local_file'
      endif else begin
         sock_list,lurls[i],sswfiles
      endelse
      fcnt=n_elements(sswfiles) ; init to ALL
      ftimes=anytim(file2time(sswfiles,out='ecs'))
      if n_elements(time_range) eq 2 then begin
         ssf=where(ftimes ge anytim(time_range(0))  and ftimes le anytim(time_range(1)),fcnt)
      endif else ssf=lindgen(fcnt)
      if fcnt gt 0 then begin 
         sswfiles=sswfiles(ssf)
         ftimes=ftimes(ssf)
         if keyword_set(minutes_cadence) then begin 
            ssf=grid_data(ftimes,minutes=minutes_cadence)
            sswfiles=sswfiles[ssf]
            fcnt=n_elements(sswfiles)
         endif
         if loud then box_message,'Copying ' + strtrim(fcnt,2) +' files..'
         if preops then cfiles=str_replace(sswfiles,'/net/solarsan/Volumes/venus/sdo','http://sdowww.lmsal.com') else $
            cfiles=dataurl+ssw_strsplit(sswfiles,'/',/tail)
         if keyword_set(name_only) then name_path = append_arr(name_path, cfiles) else begin
           if use_curl then begin 
              curl_copy,cfiles,out_dir=out_dir
           endif else begin
              sock_copy,cfiles, progress=progress, out_dir=out_dir, clobber=clobber
           endelse
         endelse
       endif else box_message,'No files for this wave within your TIME_RANGE
   endfor
   
endif else box_message,'No list files?' ; tbd - transfer all?

if n_elements(name_path) gt 1 then name_path = name_path[1:*]

return
end
