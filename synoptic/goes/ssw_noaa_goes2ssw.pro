function ssw_noaa_goes2ssw, goesdata, satnum, gxd=gxd 
;
;+
;   Name: ssw_goes2ssw
;
;   Purpose: NOAA/NGDC goes data array -> ssw times, added tags, for utplot, anytim, ; 
;
;   Input Parameters:
;      goesdata - data from GOES/NGDC/NCEI netcdf files (ssw_goesn_time2files.pro retrieval for example)
;      satnum - goes sat# - (not actually In the GOESDATA) - useful for adding .satellite 
;
;   Output:
;      function returns vector with SSW times (anytim/utplot) - optionally, if goes irrad + /gxd, add gxd-like tags (plot_goes...)
;
;   Keyword Parameters:
;      gxd - (switch) - if set, and goesdata looks like irradience, add gxd-like tags (.lo, .hi, yohkoh/int times(
;
;   Calling Example:
;      IDL> read_netcdf,'noaa_goes.nc',data [,attributes,status]
;      IDL> goesssw=ssw_noaa_goes2ssw(data,15) ; returns input data + SSW times - default=mjd_int
;      IDL> goesssw=ssw_noaa_goes2ssw(data,/gxd) ; above + gxd-like tags IF gpesdata has expected irradience A/B count tags (.high,.lo)
;
;   History:
;      19-may-2020 - for GOES-N (13,14,15) reproc + imminent release of GOES-R (16,17) 2s product
;      20-may-2020 - GOES-R .TIME uses different base time; use that offset if input GOESR 
;      23-may-2020 - for GOES-N one minute XRS, same tags as GOES-R - so use those for GXD value added
;   
;   PRELIMINARY/BETA - not for publication yet!!
;
;-
if ~required_tags(goesdata,'time') then begin 
   box_message,'Expect NOAA/NCEI DATA; bailing'
   return,-1
endif
case 1 of 
   n_params() eq 2: ; satnum supplied
   else: begin
      help,/recall,out=out
      ss=where(strpos(out,'read_netcdf') ne -1, rcnt)
      if rcnt gt 0 then begin
         rline=out[ss[0]]
         rline=str_replace(rline,"'","")
         rline=str_replace(rline,'"','')
         satnum=strextract(rline,'_g1','_d2')
         satnum=fix('1'+satnum)
      endif else satnum=99
   endcase
endcase

goesr=required_tags(goesdata,'XRSA_FLUX,XRSB_FLUX') or satnum ge 16 ; 
; 
retval=goesdata ; 
goes2anytim=([-2.8399680e+08,6.6273120e+08])(goesr) ; slf, goesn v.  goesr offsets for anytim rationalize
ssw_times=anytim(retval.time + goes2anytim, /mjd)
retval=join_struct(retval,ssw_times)
retval=add_tag(retval,satnum,'satellite') ; for historical purposes, where GOESDATA camefrom

; optional, user wants gxd-like tags (at least the plot_goes subset)
if keyword_set(gxd) then begin 
   case 1 of 
      required_tags(retval,'a_flux,b_flux'): begin
         retval=add_tag(retval,retval.a_flux,'hi')
         retval=add_tag(retval,retval.b_flux,'lo')
         retval=join_struct(retval,anytim(ssw_times,/int))
      endcase
      required_tags(retval,'xrsa_flux,xrsb_flux'): begin ; GOES-R -and- GOES-N one minute(! but Not GOES-N 2s?)
         retval=add_tag(retval,retval.xrsa_flux,'hi')
         retval=add_tag(retval,retval.xrsb_flux,'lo')
         retval=join_struct(retval,anytim(ssw_times,/int))
      endcase
      else: begin
         box_message,'/GXD requested , but this does not look like GOES irradience data input'
      endcase
   endcase
endif

return,retval
end

