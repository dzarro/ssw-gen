function ssw_goesn_time2files, t0, t1,$
   level=level, l1b=l1b, l2=l2, paths_only=paths_only, urls=urls, local=local, parent_local=parent_local, $
   top_url=top_url, count=count, parent_url=parent_url,local_paths=local_paths, $
   goes16=goes16, goes17=goes17, $
   goes13=goes13, goes14=goes14, goes15=goes15, $
   irrad=irrad, avg1m=avg1m, bkd1d=bkd1d, fldet=fldet, flsum=flsum, debug=debug, one_minute=one_minute, xrs=xrs, $
   quiet=quiet
;
;+
;   Name: ssw_goesn_time2files
;
;   Purpose: canonical SSW time range -> return derived GOESN files implied by user keyword settings.
;
;   Input Paramters:
;     t0,t1 - UT time range, any SSW standard time (e.g. anytim.pro compatible) 

;   Output:
;     function returns list of file names or paths - default are urls; default NOAA/NCEI
;
;   Keyword:
;      /L1B -or- /L2 - data level desired , default = L2  
;      level - place holder for Future data levels; for now, only one of {'L1B','L2'} so use switch
;      GOES13,GOES14,GOES15 - mutually exclusive switches for satellite selection
;      /paths_only - if set, return implied paths, not files (Mirroring NCEI->local for example -> ssw_<wget/lftp>_mirror.pro)
;      /local - if set, apply logic to Locally stored tree (local mirror); assume NOAA/NVEI organization/naming conventions
;      parent_local - optional path parent to Local GOESR tree - implies /LOCAL which uses default parent='$GOESR_DATA'
;      top_url - parent url for top of remote GOESN , default=NOAA NCEI - assumes remote GOESN tree has that organization/naming
;      parent_url (outout) - name of parent url used; returned - if top_url Not defined this is the NOAA/NCEI assumed by this *pro
;      count - # of things returned
;      irrad,avg1m,bkdid,fidet,flsum - "type" of product - mututally excluive switches (looking for descriptive document...)
;      one_minute (switch) - implies L2 + xrs, 1m averages of the irrad/2s data 
;      xrs (switch) - synonym for /IRRAD in case GOESR/GOESN did not read the doc headers - the two suites (N/R) have quite diff products/organization
;      quiet (switch) - suppress some messages (-> ssw_time2filelist)
;      
;   Restrictions: yes
;
;   History:
;      9-apr-2020 - S.L.Freeland written - /PATHS_ONLY only for today to initiate NOAA/NCEI -> LMSAL via ssw_lftp_mirror.pro
;     12-apr-2020 - S.L.Freeland - use /MONTHLY in call to ssw_time2paths for /MAG & /SEIS (SUVI uses /DAILY)
;     19-may-2020 - S.L.Freeland - from existing ssw_goesr_time2files.pro following NOAA recalibration/organization of GOES-N (13,14,15)
;     23-may-2020 - S.L.Freeland - add /ONE_MINUTE - for some heritage/goesr consistancy...
;     25-may-2020 - S.L.Freeland - date_only on ssw_time2paths call to assure t0 product Id'd
;      4-jun-2020 - S.L.Freeland - add  /quiet (-> ssw_time2filelist)
;      4-jun-2020 - Kim Tolbert  - pass quiet to file2time
;   

quiet=keyword_set(quiet)
count=0 ; as with life, assume failure
debug=keyword_set(debug)
case n_params() of 
   0: begin
         box_message,'Cannot read your mind; gimme a time or time range... bailing'
         return,-1
   endcase
   1: t1=reltime(t0,hours=24) ; only start time supplied, assuming that+24 for stop time
   else: ; t0 & t1 supplie by user
endcase

case 1 of
   data_chk(top_url,/string): parent_url=top_url
;  else: parent_url='https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/' ; def=NOAA/NCEI GOER dat parent
   else: parent_url='https://satdat.ngdc.noaa.gov/sem/goes/data/science/xrs/' ; GOES-N analog for GOES-R
endcase

rsat=15
case 1 of
   keyword_set(goes13): rsat=13
   keyword_set(goes14): rsat=14
   is_number(sat): rsat=str2number(sat) ; not yet supported - for GOES > 17
   else: ; else, take the default=GOES15
endcase

gsat='goes'+strtrim(rsat,2) ; string goesN
dlev='l2' ; GOESN default (GOESR=l1b)
dsub=''
case 1 of
   keyword_set(l1b): dlev='l1b'
   keyword_set(l2): begin
      dlev='l2'
      ;dsub='/data' ; NCEI Level2 is "one level deeper" compared to L1B, for reasons unknown (to me) ; true for GOESR, not GOESN
   endcase
   else:
endcase
instr='xrsf' ; default for "most" products
swaves='avg1m' ; default 

case 1 of
   keyword_set(avg1m) or keyword_set(one_minute): swaves='avg1m'
   keyword_set(irrad) or keyword_set(xrs): begin
     instr='gxrs'
      swaves='irrad'
   endcase
   keyword_set(bkd1d): swaves='bkd1d'
   keyword_set(fldet): swaves='fldet'
   keyword_set(flsum): swaves='flsum'
   else: ; take default=xrsf-avg1m
endcase

swaves=swaves+'_science'
subdirs=instr+'-'+dlev+'-'+swaves
dlev='' & dsub=''
purls=parent_url+gsat+'/'+dlev+dsub+'/'+subdirs
daily=is_member(instr,'suvi')
monthly=is_member(instr,'seis,mag')
monthly=1 ; think for all GOESN
paths=ssw_time2paths(anytim(t0,/date_only,/ecs),reltime(t1,/days,out='ecs') ,parent=purls[0],daily=daily,monthly=monthly)
nparents=n_elements(purls)
for p=1,nparents-1 do paths=[paths,ssw_time2paths(t0,t1,parent=purls[p],daily=daily,monthly=monthly)]
if debug then stop,'purls,paths'

things=''
ldata=get_logenv('$GOESN_DATA')
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
    things=ssw_time2filelist(anytim(t0,/date_only,/ecs) ,reltime(t1,/day_only,/days,out='ecs'),parent=purls,/month,extension='.nc',quiet=quiet,debug=debug)
    sse=ssw_time2epoch(file2time(things,quiet=quiet),anytim(t0,/date_only),t1)
    ss=where(sse eq 0,count)
    if count gt 0 then things=things[ss]
   ; box_message,'/paths_only for today (need tweak to file2time)' ; think this was only SUVI for now, so useless here 
endelse

count=n_elements(things) * (things[0] ne '') ; number returned elements

return,things
end
