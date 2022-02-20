pro read_goes_nc, files, data, attributes, _extra=_extra, debug=debug, timerange=timerange, quiet=quiet, count=count
;
;+
;   Name: read_goes_nc
;
;   Purpose: read GOESN/GOESR netcdf files provided by NCEI (formerly known as NGDC)
;
;   Input Parameters:
;      files -local *.nc files or http://*.nc files
;
;   Output Parameters:
;      data - the output data - for now, a vector (like GOES XRS) w/ssw value added tags (anytim/utplot etal ready)
;      attributes - the netcdf attributes (describes DATA.<stuff>) - for first netcdf read, if multiple 'files' input
;
;   Keyword Parameters:
;      _extra - undefined keywords -> lower level stuff, like ssw_noaa_goes2ssw
;      quiet - (switch) - if set, suprress some info messages
;      timerange - desired [t0,t1], utplot-like defintion - apply this filter to DATA prior to return
;               (with current netcdfmethod, all input urls/files read, and optional TIMERANGE applied post read_netcdf  -> return)
;      count (output) - number of Valid DATA returned - 0 if DATA read, but Zero in TIMERANGE 
;
;   Method:
;      For today, using read_netcdf; todo: extend to netcdf methods included in newer IDL versions(?) - keep API ~same
;      SSW valued added via ssw_noaa_goes2ssw.pro (does things like goes.TIME -> ssw/anytim timeas for N/R (diff base times!)
;
;   History:
;      21-may-2020 - S.L.Freeland - wrapper for ~new tools developed for GOES-N update + GOES-R XRS flow ~yesterday
;      25-may-2020 - S.L.Freeland - add TIMERANGE & /QUIET 
;      26-may-2020 - S.F.Freeland - add 2nd positional Output ATTRIBUTES parameter
;      29-may-2020 - Kim Tolbert  - return local names (with path) of files from sock_copy call, so out_dir can be used
;      17-jun-2020 - S.L.Freeland - assure COUNT output reflects reality , including post-timerange filter
;
;   Restriction: Yes
;   For today, if 'files' are urls (from something like ssw_goes{n,r}_time2files.pro, do the ncei->local copy - 
;
;-
;
debug=keyword_set(debug)
quiet=keyword_set(quiet)
loud=1-quiet ; default is LOUD
count=0 

case 1 of
   n_params() lt 2: begin
      box_message,'Need file/url list and an Output DATA to help you out... bailing with no action'
      return ; !!! EARLY EXIT on bum input
   endcase
   ~data_chk(files,/string) : begin
      box_message,'First param must be string, file or url list to help you out... bailing with no action'
      return ;  !!! EARLY EXIT on bum input
   endcase
   else: ; so far so good...
endcase

if strpos(files[0],'http') ne -1 then begin
   if loud then box_message,'urls input
   sock_copy,files,_extra=_extra, local_file=ncfiles
   if debug then stop,'post sock_copy,ncfiles'
endif else begin
   if total(file_exist(files)) ne n_elements(files)  then begin
      box_message,'file list supplied, but one or more not found... bailing with no action
      return ; !!! EARLY EXIT on one or more FILES not found
   endif
   ncfiles=files ; local netcdf (.nc) files found, proceed to read
endelse 

ssnotnc=where(strpos(ncfiles,'.nc') eq -1,bcnt)
if bcnt gt 0 then begin
   box_message,'sorry, only trained to handle netcdf files, w/.nc extension...bailing with no action
   return ;'
endif

nf=n_elements(ncfiles)
epf=lonarr(nf)
read_netcdf,ncfiles[0],data, attributes, status ; read 1st file->DATA
if nf gt 1 then begin ; if only one file, Done, so skip the multi file->DATA step
   ldata=list(data) ; Using LIST instead of per file concatenation for ef
   epf[0]=n_elements(data)  ; in case mixed #elements per file, for tracking #things per file
   for f=1,n_elements(ncfiles)-1 do begin ; already have 1st file/DATA in LIST, do the rest
      read_netcdf,ncfiles[f],datax,attx
      ldata.add,datax
      epf[f]=n_elements(datax);
   endfor
   tdata=[0,totvect(epf)] ; LIST->3D insertion points
   data=replicate(datax[0],total(epf)) ; space for everything in LIST
   for i=0,nf-1 do data[tdata[i]]=ldata[i] ; LIST->3D DATA
endif ; 

sat=fix('1'+strextract(ncfiles[0],'_g1','_d2')) ; doomed to fail for GOES-20 or year=3000, which ever comes 1st
data=ssw_noaa_goes2ssw(data,sat,_extra=_extra) ; do the SSW value-added tags (anytim,utplot etal compat)
count=n_elements(data)
if n_elements(timerange) eq 2 then begin
   if loud then box_message,'Applying TIMERANGE filter via ssw_time2epoch.pro)
   sst=where(ssw_time2epoch(data,timerange[0],timerange[1]) eq 0,tcnt)
   if tcnt gt 0 then data=data[sst] else box_message,'DATA, but not in your TIMERANGE, returning all'
   count=tcnt
endif

if debug then stop,'data,ldata,files'

return
end

