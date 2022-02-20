function ssw_get_goesdata, t0, t1, g16=g16, g17=g17, $
  xrays=xrays,protons=protons,electrons=electrons, magnetometers=magnetometers, $
  ndays=ndays, nhours=nhours, primary=primary, secondary=secondary, debug=debug, $
  file_only=file_only, url_only=url_only, differential=differential, integral=integral, fluence=fluence, $
  gxd=gxd, heritage=heritage, structure=structure, json_info=json_info, $
  flares=flares,latest=latest
;
;+
;   Name: ssw_get_goesdata
;
;  Purpose: read/return GOES xray flux (and p+, e-, mag..) from SWPC json https://services.swpc.noaa.gov/json/goes/{primary/secondary}
;
;  Input Parameters:
;    t0,t1 - desired timerange
;
;  Keyword Parameters:
;     xray (switch) - if set, xray flux (default)
;     protons,electrons,magnetometers -mutually exclusive switches for one of Those things instead of xray default
;     differential/integral - mutually exclusive swithes (apply to protns/electrons only
;     ndays - optional swpc file to use (default derived from t0)
;     nhours - kind of ndays analog (like nhours=6 uses  <thing>-6-hours.json
;              nhours=24 ~ ndays=1 
;     gxd - (switch) - if set, add heritage gxd-like tags (time, .LO, .HI) backward compatible (plot_goes etal)
;     heritage_tags - kind of like gxd and synonym if /XRAYS for other things (p+,e-,mag), add some value-added tags, utplot & existing apps
;     structure (switch) - if set, convert default LIST output to structure (implied for /GXD or /HERITAGE)
;     file_only - return implied SWPC json file name, not data
;     url_only  - return implied SWPC json url, not data
;     json_info (output) - optional output structure including as-run .SWPC_JSON_URL, .SWPC_JSON
;     flares (switch) - xray-flare 
;     
;
;  Calling Examples:
;     IDL> xr16=ssw_get_goesdata(reltime(days=-2),reltime(/now),/g16,/xray,/gxd) ; most recent GOES16 XRS, SSW/valued added tags
;               (/gxd option adds some heritage-like tags for apputplot,plot_goes etc compatibility)
;     IDL> g16p=ssw_get_goesdata(reltime(hours=-4),reltime(/now),/primary,/protons,/struct) ; last 4h integral-protons
;     IDL> g16e_url=ssw_get_goesdata(reltime(days=-6),reltime(/now),/primary,/electrons,/differential,/url_only)
;     IDL> g16e=ssw_get_goesdata(t0,t1,/mag,JSON_INFO=JSON_INFO,/secondary,/heritage) ; optional JSON_INFO output
;
;  History:
;     28-jan-2020 - S.L.Freeland - rd_goesx_ascci analog for GOES-R series 16&17 since heritage 14&15 retiring Jan 31 2020
;                   For GOESn status & differences (like G16 XRS sensitivity improvments) see:
;                   https://www.swpc.noaa.gov/news/goes-1415-outage-planned-22-23-january-2020-and-then-will-cease-permanently-31-january-2020
;     29-jan-2020 - S.L.Freeland - oops, added the t0->t1 time trim (via ssw_time2epoch.pro)
;                   Added /heritage, and expanded /protons,/heritage combo - utplot and plot_goesp.pro compatible
;     31-jan-2020 - S.L.Freeland - expand /electrons & /magnetomaters w/heritage tags (utplot, plot_goesp (does e-)
;      2-feb-2020 - S.L.Freeland - some xtra protection against "illegal" keyword combinations - assure all boolean (switches) defined
;      3-feb-2020 - add .DATE_RUN and .JSON_URL to output structures; add JSON_INFO optional Output structure
;     20-feb-2020 - for /electrons & /protons,protect against .FLUX mixed json_parse data types (long->double)
;     14-oct-2020 - add /FLARES keyword & function
;     15-oct-2020 - force datatype match for .toarray method (MAX_RATIO for now,"!NULL" -> -1.d
;     19-oct-2020 - add /LATEST - in conjunction with /FLARES use latest nrt vs last 7 day json (includes flare in progress) 
;     11-dec-2020 - temporarily inhibiting the +500 MeV in /protons call due to a TBD json:struture mis-match - we are dead anyway if this matters...
;
;   Restrictions:
;      For now, limited to most recent 7 days (e.g. nrt/space-weather/"latest events" like  fine)
;      as of today (29-jan-2020) - /primary=GOES16 , /secondary=GOES15 (assume GOES17 circa 1-feb-2020)
;      todo - value added e-,mag tags for heritage app - probably later today.. ; did the p+ /heritage so plot_goesp.pro compat
;
;-
debug=keyword_set(debug)

json_parent='https://services.swpc.noaa.gov/json/goes/'
secondary=keyword_set(secondary) or keyword_set(g17) ; default is primary/g16(?)
parent_url=json_parent+(['primary','secondary'])(secondary) + '/'

; use t0 to select "best" swpc/json file - default is smallest including t0
now=reltime(/now)
count=0 ; as with life, assume failure
loud=keyword_set(loud) or keyword_set(verbose)

now=reltime(/now)

if n_elements(t0) eq 0 then t0=reltime(days=-7)
if n_elements(t1) eq 0 then t1=now

t0x=t0
t1x=t1

dtm=ssw_deltat(t0,now,/minutes)
dth=dtm/60.
dtd=dth/24.
dtt1=ssw_deltat(t1, reltime(days=-7), /hours)

file_only=keyword_set(file_only)
url_only=keyword_set(url_only)
fluence=keyword_set(fluence)
sfluence=(['','fluence-'])(fluence)
flares=keyword_set(flares)
latest=keyword_set(latest) ; only /flares for now

case 1 of
   flares: tunit=(['7-day','latest'])(latest) ; default for flares since file size in the noise... latest=last_nelem(of return)
   fluence: tunit='7-day' ; only T choice for fluence
   dth le 6.05: tunit='6-hour'
   dtd le 1.05: tunit='1-day'
   dtd le 3.05: tunit='3-day'
   dtd le 7.05: tunit='7-day'
   else: begin
      box_message,'Sorry, as of Now, this only applies to <= 7 most recent day window
      return,-1 ; Early exit on request for data older then swpc 7 day window
   endcase
endcase
;
; define switch keyords "for later"
protons=keyword_set(protons)
electrons=keyword_set(electrons)
magnetometers=keyword_set(magnetometers)
xrays=keyword_set(xrays) or total([protons,electrons,magnetometers]) eq 0 ; xrays/xrs is default
differential=keyword_set(differential)
gxd=keyword_set(gxd)
heritage=keyword_set(heritage) ; add heritage tags for existing apps (utplot, plot_goesp...etc ; /gxd synonym for Thing=/xrays

petype=(['integral','differential'])(differential) + '-'
plural=(['s-','-'])(fluence)
case 1 of 
   flares:        thing='xray-flares-'+ tunit
   protons:       thing=petype+'proton'   + plural + sfluence + tunit
   electrons:     thing=petype+'electron' + plural + sfluence + tunit
   magnetometers: thing='magnetometers-'  + tunit
   else:          thing='xrays-'            + tunit
endcase

jname=thing+'.json'
jurl=parent_url+jname

case 1 of
   keyword_set(file_only): retval=jname
   keyword_set(url_only):  retval=jurl
   else: begin
     sock_list,jurl,json
     jstr=json_parse(json,/tostruct)
     retval=jstr
   endcase
endcase

if ~data_chk(retval,/string) then begin
;   trim full json contents -> user range
   if debug then stop,'retval, before time trim'
   ; -e and +p protect against mixed data types for .FLUX prior to .toarray() method
   if (protons or electrons) and ~differential then $
      for t=0,n_elements(retval)-1 do $
        retval[t]=rep_tag_value(retval[t],double(retval[t].flux),'flux')
   if flares then $
      for t=0,n_elements(retval)-1 do $
         if data_chk(retval[t].max_ratio,/string) then $
            retval[t]=rep_tag_value(retval[t],-1.d,'max_ratio')
   jstruct=retval.toarray()
   sse=ssw_time2epoch(jstruct.TIME_TAG,t0,t1)
   need=where(sse eq 0,count)
   if count gt 0 then begin
      retval=retval[need]
   endif else begin
      box_message,'No records in your time range(?), returning'
      return,-1 ; !! EARLY EXIT on no such record error (tbd)
   endelse
   if debug then stop,'retval,jname
   structure=keyword_set(structure) or gxd or heritage
   if structure then   retval=retval.toarray() ; LIST -> ARRAY
endif

if gxd or heritage and data_chk(retval,/struct) then begin
   retval=join_struct(retval,anytim(retval.time_tag,out=(['mjd','int'])(gxd)))
   retval=add_tag(retval,reltime(/now),'DATE_RUN')
   json_info={swpc_json_url:jurl,swpc_json:json}
   
   case 1 of
      flares: ; done
      xrays: begin
         sslo = where(retval.energy eq '0.1-0.8nm')
         sshi = where(retval.energy eq '0.05-0.4nm')
         loflux=retval[sslo].flux
         hiflux=retval[sshi].flux
         retval=retval[sslo] ; assumes 1:1 lo:hi (duplicate .TIME_TAG)
         retval=add_tag(retval,loflux,'lo')
         retval=add_tag(retval,hiflux,'hi')
         retval[*].energy='0.1-0.8nm,0.05-0.4nm'
       endcase
       protons and ~fluence: begin 
          alle=all_vals(retval.energy)
          alle=alle(sort(str2number(alle)))
          tnames=str_replace(str_replace(alle,'>=','GE_'),' MeV','_MeV')
          nebands=n_elements(alle)
          ss1mev=where(retval.energy eq alle[0],me1cnt)
          parr=dblarr(nebands,me1cnt) 
          temp=retval[ss1mev]
          temp=add_tag(temp,parr,'p') ; heritage tag .P
          temp=add_tag(temp,retval[ss1mev].flux,tnames[0])
          temp.p[0,0]=retval[ss1mev].flux
          tmax=me1cnt ; limit #ntags to 1 MeV matches (some wierdness in 500 MeV matches?)
          for b = 1,nebands-2 do begin ; SLF, 11-dec-2020 - inhibiting +=500 MeV, hence the -2 FOR end
             ssx=where(retval.energy eq alle[b],mecnt)
             if debug then help,b,alle[b],mecnt
             flux=last_nelem(retval[ssx].flux,tmax)
             temp.p[b,ssx]=flux
             temp=add_tag(temp,flux,tnames[b])
          endfor
          retval=temp
          retval[*].energy=arr2str(alle)
       endcase
       electrons and ~fluence: begin
          alle=all_vals(retval.energy)
          alle=alle(sort(str2number(alle)))
          tnames=str_replace(str_replace(alle,'>=','GE_'),' MeV','_MeV')
          if differential then tnames=str_replace('kev_'+ssw_strsplit(alle,' keV',/head),'-','_')
          nebands=n_elements(alle)
          ss1mev=where(retval.energy eq alle[0],me1cnt)
          if nebands eq 1 then earr=dblarr(me1cnt) else earr=dblarr(nebands,me1cnt)
          temp=retval[ss1mev]
          temp=add_tag(temp,earr,'e') ; heritage tag .E
          temp.e[0,0]=retval[ss1mev].flux
          for b=1,nebands-1 do begin
             ssx=where(retval.energy eq alle[b],mecnt)
             temp.e[b,ssx]=retval[ssx].flux
             temp=add_tag(temp,retval[ssx].flux,tnames[b])
          endfor
          temp=add_tag(temp,retval[ss1mev].flux,tnames[0])
          temp.e[0]=retval[ss1mev].flux
          retval=temp
       endcase

       else: box_message,'heritage type not yet supported
   endcase
endif
if debug then stop,'before return, retval

return,retval
end




