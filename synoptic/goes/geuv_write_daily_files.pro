;+
; Name: geuv_write_daily_files
;
; Purpose: Write GOES EUV files in hesperia archive.  Original files are yearly, we want daily, just to make them 
;   quicker to copy and read. Also original files have separate counts and flags files.  We're combining them to have
;   one daily file for each satellite for each EUV type.  Hesperia archive top directory is /data/goes_euv and is organized by
;   type (euva, euvb, or euve) and year, so data from all satellites for euva for 2011 will be in directory /data/goes_euv/euva/2011.
;   Files names are, e.g.   g13_euva_20110209.txt for GOES 13 EUVA data for 9-feb-2011.
; 
; Notes:  
;  If times for data and times for flags (from 2 separate files) don't match for a day, skip day
;  If all data for a day have < n_thresh unique values, skip day
;  For EUVA if uncorrected counts are <=0. and flag is 0, set flag to -99999.
; 
; Keyword Arguments: 
;  year - 4-digit year of data to make files for
;  sat  - 2-digit number of GOES satellite to make files for
;  type - 0,1,2 for EUVA, EUVB, EUVE
;  
; Written: Kim Tolbert, 26-Jan-2016
; Modifications:
; 21-Nov-2016, Kim.  Modified for new data set at NOAA (after writing new archive on hesperia):
;   Janet Machol made these changes at NOAA:
;     Data now through June 2016 (was Oct 2014)
;     URL changed to http://satdat.ngdc.noaa.gov/sem/goes/data/euvs/raw_10s/
;     Files are organized by satellite number now, previously had year directories.  Now, e.g. all years for sat G15
;       are under http://satdat.ngdc.noaa.gov/sem/goes/data/euvs/raw_10s/G15/
;     Better flags for bad data for EUVE
;     New EUVE flags are in files called Gss_EUVE_Flags_yyyy.dat, but unimproved EUVA and EUVB flags are now in files
;       that start with 'orig_', i.e. orig_Gss_EUVA_Flags_yyyy.dat and orig_Gss_EUVB_yyyy.dat
;     EUVE data is now scaled to SORCE SOLSTICE v15 (was v12)
;   Changed top_out_dir to write in a new dir /data/goes_euv/new_2016 to preserve old files while rewriting archive.
; 
;-
pro geuv_write_daily_files, year=year_in, sat=sat_in, type=type, top_out_dir=top_out_dir

year = trim(year_in)
sat = trim(sat_in) 
itype = type   ; 0,1,2 for EUVA, EUVB, EUVE
checkvar, top_out_dir, '/data/goes_euv/new/'

n_thresh = 5

;url = 'http://satdat.ngdc.noaa.gov/sem/goes/data/new_avg/yyyy/new_euv_temp/raw/' 
url = str_replace('http://satdat.ngdc.noaa.gov/sem/goes/data/euvs/raw_10s/Gss/', 'ss', sat)

afiles = ['Gss_EUVxxx_Cnts_yyyy.dat', 'Gss_EUVxxx_Flags_yyyy.dat']
if itype lt 2 then afiles[1] = 'orig_' + afiles[1]  ; flag files for euva and euvb now start with orig_, 21-nov-2016

types = ['A_Corrected', 'B', 'E']
types_short = ['euva', 'euvb', 'euve']

terror = trim([1.024, 1.024, 2.048])
time_error = ['; Listed times are the end of the 10.24s data integration period + terrors', $
              ';   so time at center of integ. period is listed time - (10.24 / 2. + terror)s']

print,''
print,'Current time = ' + !stime
print,'WRITING GOES EUV FILES FOR ' + trim(year_in) + ', GOES' + sat + ', ' + types_short[itype]
print,''
              
;for itype=0,0 do begin
  
  ; construct yearly file names from satellite, euv type, year (for EUVA, cnts file has _Corrected added too)
  do_files = str_replace(afiles, 'ss', sat)
  do_files = str_replace(do_files, 'xxx', types[itype])
  if itype eq 0 then do_files[1] = str_replace(do_files[1], '_Corrected','')  ; flag file name doesn't have '_Corrected' in it
  do_files = str_replace(do_files, 'yyyy', year)
;  do_url = str_replace(url, 'yyyy', year) + do_files
  do_url = url + do_files
  print, 'Getting file(s):'
  print, do_url
  sock_copy, do_url, /use_network, /no_check
  if total(file_exist(do_files)) ne 2 then begin
    print,'Files not found. Skipping.'
    goto, done
  endif
  
  out_dir = top_out_dir + types_short[itype] + '/' + year + '/'
  if ~is_dir(out_dir) then mk_dir, out_dir
  
  ; Now we have cnts and flags files in local directory in dofiles[0] and [1]. Read them into variables
  ; times, cnts, (and cntsorig for EUVA) and ftimes, flags
  lines = rd_tfile( do_files[0], 1, 2, /auto)
  times = reform(anytim(lines[0,*] + ' ' + lines[1,*]))
  ; For A_corrected, corrected counts are in column 3 and uncorrected counts are in column 2. Except for some later 
  ;   years (G15, 2015 so far) that only have 3 columns total - for those I set cnts and cntsorig to column 2.
  ;   Get the uncorrected counts (cntsorig) and convert to float since we'll be checking value, so we can set flag when they're 
  ;   clearly bad (<=0).
  ;   Also there are some -Infinity and Infinity values in the cnts column, so set those to -99999.
  ; For B and E, counts are in column 2
  if itype eq 0 then begin
    if (size(lines,/dim))[0] eq 3 then begin 
      cnts = reform(lines[2,*])
      cntsorig = float(cnts)      
    endif else begin  ; this is the case for most of the files, so far just G15 for 2015 only has 3 columns
      cnts = reform(lines[3,*])
      cntsorig = float(reform(lines[2,*]))
    endelse
    qinf = where(strpos(cnts, 'Infinity') ne -1, ninf)
    if ninf gt 0 then begin
      cnts[qinf] = '-99999.0'
      cntsorig[qinf] = -99999.0
    endif
  endif else cnts = reform(lines[2,*])
  
  flines = rd_tfile( do_files[1], 1, 2, /auto)
  ftimes = reform(anytim(flines[0,*] + ' ' + flines[1,*]))
  flags = reform(flines[2,*])
  
  time_error_lines = str_replace(time_error, 'terror', terror[itype])
  head = ['; Daily raw GOES EUV' + types[itype] + ' counts and flags from files ' + do_files[0] + ' and ' + do_files[1], $
          ';   from http://satdat.ngdc.noaa.gov/sem/goes/data/euvs/raw_10s/', $
;          ';   from http://satdat.ngdc.noaa.gov/sem/goes/data/new_avg/yyyy/new_euv_temp/raw/', $
          '; Refer to http://www.ngdc.noaa.gov/stp/satellite/goes/doc/GOES_NOP_EUV_readme.pdf for explanation of data and flags.', $          
          '; -----', $
          '; Four columns are Date, Time, Counts, Flag', $
          time_error_lines, $
          '; -----', $
          '; Written by Kim Tolbert, current_time', $
          '; -----']
    
  ; Loop over days until we reach last time in input file
  ts = times[0]
  te = last_item(times)
  tt = anytim(times[0],/date)
  repeat begin
    
    bad_day = 0
    ; t1,t2 are start end of current day
    t1 = tt
    t2 = t1 + 86400.d0
    day = time2file(t1, /date)
    
    ; find elements that are within current day
    qc = where(times ge t1 and times lt t2, count)
    qf = where(ftimes ge t1 and ftimes lt t2, countf)
    if count eq 0 or countf eq 0 then begin 
      bad_day = 1
      goto, nextday
    endif
    
    ; Check that data times and flag times match.  
    good_flags = same_data(times[qc], ftimes[qf])
    if ~good_flags then begin
      ; If they didn't, try to find a subset that matches. If none, then skip.
      ; (Sometimes beginning or end of day is missing so look for matches in overlapping times)
      mint = min(times[qc]) > min(ftimes[qf])  ; smallest time for cnts or flags
      maxt = max(times[qc]) < max(ftimes[qf])  ; largest time for cnts for flags
      qc = where(times  ge mint and times  lt maxt, count)
      qf = where(ftimes ge mint and ftimes lt maxt, countf)      
      if count eq 0 or countf eq 0 then begin
        bad_day = 1      
        goto, nextday
      endif
      good_flags = same_data(times[qc], ftimes[qf])
    endif
    
    if good_flags then begin
      ; If there are < n_thresh unique values on a day, skip it.
      z = get_uniq(cnts[qc])
      if n_elements(z) lt n_thresh then begin
        print, 'Data on ' + day + ' has < ' + trim(n_thresh) + ' unique values. Skipping.'
        print,z
      endif else begin
        
        if itype eq 0 then begin ; for A, if original cnts were <= 0, but flag was 0, set flag to -99999.
          qbad = where(cntsorig[qc] le 0 and float(flags[qf]) eq 0, kbad)
          if kbad gt 0 then flags[qf[qbad]] = '-99999.000000'  ; silly, but just to match original flags of -99999
        endif
        
        ; Construct string array with header and data and write in out_file
        out_lines = anytim(times[qc],/vms) + ' ' + cnts[qc] + ' ' + flags[qf]                
        out_file = out_dir + 'g' + sat + '_' + types_short[itype] + '_' + day + '.txt'
        out_head = str_replace(head, 'current_time', !stime)
        prstr, [out_head, out_lines], file=out_file
        print, 'Wrote file ' + out_file
        
      endelse
    endif else bad_day = 1 
    
    nextday:
    if bad_day then print, "No data, or data and flag times didn't match for " + day + '. Skipping.'
    
    tt = t2
    
  endrep until tt gt te
  done:
;endfor

end