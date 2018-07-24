;+
; Name: rd_geuv
; 
; Purpose: Read GOES EUV 10-sec raw data from daily files on hesperia and convert counts to watts/m^2. For
;  EUVE data returns corrected flux (and uncorrected in channel 1). 
;  Called by read method in goes__define. Calls geuv_read_files to read the data files.
;
; Input Keywords:
;  stime, etime - start, end time of requested data in anytim format
;  sat - number of preferred GOES satellite (e.g. 15)
;  euv - EUV channel requested: 0,1,2,3. 0=not selected, 1=EUVA, 2=EUVB, 3=EUVE
;  no_cycle - if set, only return data for requested satellite. Otherwise loops through sats to find data.
;  verbose - 0,1 for less/more output. Default is 0.
; 
; Output Keywords:
;  tarray - time at center of integration interval
;  yarray - for euve, returns irradiance in Ly-alpha band, degradation-corrected in yarray[*,0], and uncorrected irradiance in yarray[*,1] 
;           for euva and euvb, just returns yarray[*]
;  numstat - number of times with non-zero flags
;  tstat - times of non-zero flags
;  stat - flags at tstat times
;  err_msg - Text of error message.  '' means no error.
;  error - 0/1 means an error was encountered reading file.  Text of error message in err_msg        
;          
; Written: 3/1/2016 Kim Tolbert
; Modifications:
; 7-Dec-2016, Kim. Clean up comments
;
;-

pro rd_geuv, stime=stime, etime=etime, sat=sat, euv=euv, no_cycle=no_cycle, $
  tarray=tarray, yarray=yarray, numstat=numstat, tstat=tstat, stat=stat, $  
  err_msg=err_msg, error=error, verbose=verbose, $
  _extra=extra

checkvar, euv, 3
if euv eq 0 then return

; get list of sats to search, with preferred first
sat_search = goes_sat_list(sat, /euv, count=count, no_cycle=no_cycle)
if count eq 0 then begin
  error=1
  return
endif

; Loop through satellites until we find some data
for isat = 0,count-1 do begin
  geuv_read_files, stime=stime, etime=etime, sat=sat_search[isat], euv=euv, $
    tarray=tarray, counts=counts, flags=flags, numstat=numstat, tstat=tstat, stat=stat, chan=chan_name, $
    err_msg=err_msg, error=error, verbose=verbose, $
    _extra=extra
  if error eq 0 then begin
    sat = sat_search[isat]
    goto, found_data
  endif
endfor 

err_msg = 'No GOES ' + chan_name + ' files found for requested times for any satellite.'
return


found_data:

checkvar, verbose, 0

err_msg = ''
error = 0

; Get conversion parameters

gtable = geuv_tables(sat)
chan = ([0,0,1,4])[euv]  ; chan is index into table = 0,1,4 for EUVA, EUVB, EUVE
g = gtable.table[chan]

; If times are within solar max times, use 'max' parameters, otherwise 'min' paraemters
max_times = anytim(gtable.time_solar_max)
this_time = anytim(stime)
use_max = (this_time gt max_times[0] and this_time lt max_times[1])
if use_max then begin
  convf = g.max_convf
  scale = g.max_scale
endif else begin
  convf = g.min_convf
  scale = g.min_scale
endelse

; Convert from counts to watts/m^2
yarr = ( (counts - g.background) * g.gain - g.contamination ) / convf

;utplot,anytim(tarray,/ext), yarray, yran=[.009,.011], /yst, charsize=1.5, psym=3

; For EUVE,  correct data for degradation and scaled to SOLSTICE, store in index 0 in yarray. Also return uncorrected
; EUVE data in the index 1 in yarray.

if chan eq 4 then begin
  a = gtable.efit
  jd2ymd, a.t0, y, m, d
  t0 = anytim([0,0,0,0,d,m,y])
  tm = (tarray - t0) / 86400.
  f = a.a0 * exp(a.a1*tm) + a.a2*tm + a.a3
  yarr_corrected = scale * yarr / f
endif

yarray = chan eq 4 ? [[yarr_corrected],[yarr]] : yarr
    
end