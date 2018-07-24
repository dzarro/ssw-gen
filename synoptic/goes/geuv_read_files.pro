;+
; Name: geuv_read_files
;
; Purpose: This procedure reads the GOES EUV files requested and returns
;  arrays containing the time, data, and flags from the files.
;
; Explanation: This routine calls geuv_find_files to find and copy the GOES EUV files for the 
;  requested time, satellite and channel to the local computer.  It loops through the file(s), 
;  concatenating the times, counts, and flags from each.  Then it reduces the arrays to the subset 
;  that falls within the user's requested times. It calls geuv_flags to extend the flags indicating
;  bad values (the flags from the raw files are not sufficient - before and after each type of 
;  condition there are additional bad values that should be eliminated).  
;  This routine is called by rd_geuv in the GOES object when GOES 
;  EUV data is selected. Calls geuv_find_files to retrieve the data files from
;  the hesperia archive.
;
; Input Keywords:
;
;  stime, etime - start, end time of data we want in anytim format
;  sat - number of satellite we want (13, 14, or 15). Default is 15.
;  euv - 0,1,2, or 3 - euv channel we want (0=none, 1=EUVA, 2=EUVB, or 3=EUVE).  Default is 3.
;  verbose - 0,1 for less/more output. Default is 0.
;  
; Output Keywords:
;  tarray - array of times at center of accumulation interval in seconds since 1-jan-1979
;    NOTE: these are corrected as noted in code below.
;  counts - array of counts (directly from file, so counts in ~10s bin)
;  flags - array of flags (extended by geuv_flags)
;  numstat - number of times with non-zero flags
;  tstat - times of non-zero flags
;  stat - flags at tstat times
;  chan - name of EUV channel data (EUVA, EUVB, or EUVE)
;  err_msg - Text of error message.  '' means no error.
;  error - 0/1 means an error was encountered reading file.  Text of
;               error message in err_msg
;
; Written:  Kim Tolbert 1-Mar-2016
;
; Modifications:
; 07-Dec-2016, Kim. EUVE flags are better now and don't need to be extended
;
;-

pro geuv_read_files, stime=stime_in, etime=etime_in, sat=sat, euv=euv, $
  tarray=tarray, counts=counts, flags=flags, numstat=numstat, tstat=tstat, stat=stat, chan=chan, $
  err_msg=err_msg, error=error, verbose=verbose, $
  _extra=extra

checkvar, sat, 15
checkvar, verbose, 0

checkvar, euv, 3
if euv eq 0 then return

chan = (['NONE', 'EUVA','EUVB','EUVE'])[euv]

checkvar, verbose, 0

err_msg = ''
error = 0

stime = anytim(stime_in)
etime = anytim(etime_in)

; geuv_find_files will locate and download to temp dir the files we need
if verbose then message,'Searching for ' + chan + '...', /info
files = geuv_find_files(stime=stime, etime=etime, sat=sat, chan=chan, nfiles=nfiles)

if nfiles eq 0 then begin
  err_msg = 'No GOES ' + chan + ' files found for requested times for sat GOES' + trim(sat) + '.'
  message, /info, err_msg
  error = 1
  return
endif

; We want time at center of accumulation.  Accumulation time is 10.24 seconds, and time reported is s_after after end of 
; accumulation, where s_after = 1.024 s for EUVA and EUVB, and s_after = 2.048 s for EUVE.
; toffset will be number of seconds to subtract from reported time to get to center of accumulation interval.
s_after = [0., 1.024, 1.024, 2.048]
toffset = 10.24 / 2. + s_after[euv]

;Loop through files saving corrected times, counts, and flags
for ifile=0,nfiles-1 do begin
  lines = rd_tfile(files[ifile], /hskip, /auto)
  times = reform(anytim(lines[0,*] + ' ' + lines[1,*]) - toffset)
  cnts = reform(float(lines[2,*]))
  fl = reform(float(lines[3,*]))
  tarray = ifile eq 0 ? times : [tarray, times]
  counts = ifile eq 0 ? cnts : [counts, cnts]
  flags = ifile eq 0 ? fl : [flags, fl]  
endfor

; Now reduce the arrays to just the elements that fall in the requested times.
q = where(tarray ge stime and tarray lt etime, count)
if count gt 0 then begin
  tarray = tarray[q]
  counts = counts[q]
  flags = flags[q]
endif else begin
  err_msg = 'No GOES ' + chan + ' data in times requested. Aborting.'
  message, /info, err_msg
  error = 1
endelse

; Extend the bad-data flags by some number of seconds on either side (since the points with flags set don't 
; cover all the points with bad data)
if euv ne 3 then geuv_flags, tarray, flags ; EUVE has better flags, so they don't need to be extended

; Save number of flags indicating bad data (flag is non-zero), and times and flag values where flag is non-zero
qbad = where(flags ne 0, numstat)
if numstat gt 0 then begin
  stat = flags[qbad]
  tstat = tarray[qbad]
endif else begin
  stat = 0.
  tstat = 0.
endelse

end