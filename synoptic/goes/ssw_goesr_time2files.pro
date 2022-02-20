function ssw_goesr_time2files, t0, t1,suvi=suvi, mag=mag,exis=exis,seis=seis, waves=waves, $
   level=level, l1b=l1b, l2=l2, paths_only=paths_only, urls=urls, local=local, parent_local=parent_local, $
   top_url=top_url, count=count, parent_url=parent_url,local_paths=local_paths, $
   goes16=goes16, goes17=goes17, xrs=xrs, one_minute=one_minute, quiet=quiet, debug=debug
;
;+
;   Name: ssw_goesr_time2files
;
;   Purpose: canonical SSW time range -> return derived GOESR files implied by user keyword settings.
;
;   Input Paramters:
;     t0,t1 - UT time range, any SSW standard time (e.g. anytim.pro compatible) 

;   Output:
;     function returns list of file names or paths - default are urls; default NOAA/NCEI
;
;   Keyword:
;      /SUVI -or- /MAG -or- /EXIS -or- /SEIS -or- XRS - mutually exclusive GOESR data set to consider, default=/SUVI
;      /ONE_MINUTE - One minute averges (for now , in c
;      /L1B -or- /L2 - data level desired , default = /L1B - except /XRT implies L2, since I think only option
;      level - place holder for Future data levels; for now, only one of {'L1B','L2'} so use switch
;      /GOES16 -or- /GOES17 - which GOESR sat to select, default = '/GOES16'
;      /paths_only - if set, return implied paths, not files (Mirroring NCEI->local for example -> ssw_<wget/lftp>_mirror.pro)
;      /local - if set, apply logic to Locally stored tree (local mirror); assume NOAA/NVEI organization/naming conventions
;      parent_local - optional path parent to Local GOESR tree - implies /LOCAL which uses default parent='$GOESR_DATA'
;      top_url - parent url for top of remote GOESR , default=NOAA NCEI - assumes remote GOESR tree has that organization/naming
;      parent_url (outout) - name of parent url used; returned - if top_url Not defined this is the NOAA/NCEI assumed by this *pro
;      count - # of things returned
;      quiet (switch) - supress some informational messages ( -> ssw_time2filelist)
;      
;   Restrictions: yes
;
;   History:
;      9-apr-2020 - S.L.Freeland written - /PATHS_ONLY only for today to initiate NOAA/NCEI -> LMSAL via ssw_lftp_mirror.pro
;     12-apr-2020 - S.L.Freeland - use /MONTHLY in call to ssw_time2paths for /MAG & /SEIS (SUVI uses /DAILY)
;     20-may-2020 - S.L.Freeland - tweaks for exis, data showing up today!
;     later, that same day... - add /xrs since that's where the EXIS/XRS is popping up toda (not Under EXIS)
;     21-may-2020 - S.L.Freeland - typo fix , dropped the leading 'g' in goes16 keyword def , now restored
;     24-may-2020 - S.L.Freeland - add /one_minute (w/xrs)
;     25-may-2020 - S.L.Freeland - date_only on ssw_time2paths call to assure t0 product Id'd
;      4-jun-2020 - S.L.Freeland - add /quiet (-> ssw_time2filelist at least)
;      4-jun-2020 - Kim Tolbert  - pass quiet to file2time
;   

count=0 ; as with life, assume failure
quiet=keyword_set(quiet)
debug=keyword_set(debug)
case n_params() of 
   0: begin
         box_message,'Cannot read your mind; gimme a time or time range... bailing
         return,-1
   endcase
   1: t1=reltime(t0,hours=24) ; only start time supplied, assuming that+24 for stop time
   else: ; t0 & t1 supplie by user
endcase

case 1 of
   data_chk(top_url,/string): parent_url=top_url
   else: parent_url='https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/' ; def=NOAA/NCEI GOER dat parent
endcase

rsat=16
case 1 of
   keyword_set(goes17): rsat=17
   is_number(sat): rsat=str2number(sat) ; not yet supported - for GOES > 17
   else:
endcase

gsat='goes'+strtrim(rsat,2) ; string goesN
dlev='l1b'
dsub=''
l2=keyword_set(xrs) ; only L2 for this
case 1 of
   keyword_set(l2): begin
      dlev='l2'
      dsub='/data' ; NCEI Level2 is "one level deeper" compared to L1B, for reasons unknown (to me)
   endcase
   else:
endcase

instr='suvi' ; defult instrument=SUVI
dwave='fe171'; default wave(s)
case 1 of 
   keyword_set(mag): begin
      instr='mag'
      dwave='flat'
   endcase
   keyword_set(exis): begin
      instr='exis'
      dwave='sfxr'
   endcase
   keyword_set(seis): begin
      instr='seis'
      dwave='mpsh'
   endcase
   keyword_set(xrs): begin
      instr='xrsf'
      dwave=(['flx1s','avg1m'])(keyword_set(one_minute))
   endcase
   else: ; default=suvi
endcase
if get_logenv('check_xrsf') ne '' then stop,'instr,dwave'
dwave=dwave+'_science'

if n_elements(waves) eq 0 then swaves=strtrim(dwave) else begin
   swaves=str2arr(waves)
   if instr eq 'suvi' then begin
     swaves=(['','0'])(strlen(swaves) eq 2) + swaves
     c1=strmids(swaves,0,1)
     ; allow 'fe<n>',he304', -or' '94,304' -or' -'094,171,304'
     swaves=(['',(['fe','ci'])(dlev eq 'l2')])(is_member(c1,'0,1,2,9')) + swaves 
     swaves=(['',(['he','ci'])(dlev eq 'l2')])(c1 eq '3') + swaves
   endif
endelse

subdirs=instr+'-'+dlev+'-'+swaves
purls=parent_url+gsat+'/'+dlev+dsub+'/'+subdirs
daily=is_member(instr,'suvi')
monthly=is_member(instr,'seis,mag,exis')
paths=ssw_time2paths(anytim(t0,/date_only,/ecs),reltime(t1,/days,out='ecs') ,parent=purls[0],daily=daily,monthly=monthly)
nparents=n_elements(purls)
for p=1,nparents-1 do paths=[paths,ssw_time2paths(t0,t1,parent=purls[p],daily=daily,monthly=monthly)]

things=''
ldata=get_logenv('$GOESR_DATA')
loc=keyword_set(local)
if file_exist(parent_local) then ldata=parent_local
ldata=strtrim(ldata,2)
ldata=ldata+(['/',''])(strlastchar(ldata) eq '/') ; force trailing '/'
parent_url=parent_url + (['/',''])(strlastchar(parent_url) eq '/') ; ditto parent url
local_paths=str_replace(paths,parent_url,ldata) ; 1:1 remote urls : local 

if keyword_set(paths_only) then begin 
   things=paths
   if loc then things=local_paths
   
endif else begin 
;   box_message,'/paths_only for today (need tweak to file2time)'
   things=ssw_time2filelist(anytim(t0,/date_only,/ecs) ,reltime(t1,/day_only,/days,out='ecs'),parent=purls,/month,extension='.nc',quiet=quiet,debug=debug)
   sse=ssw_time2epoch(file2time(things,quiet=quiet),anytim(t0,/date_only),t1)
   ss=where(sse eq 0,count)
   if count gt 0 then things=things[ss]
endelse

count=n_elements(things) * (things[0] ne '') ; number returned elements

return,things
end
