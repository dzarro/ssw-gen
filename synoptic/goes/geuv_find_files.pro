;+
; Name: geuv_find_files
; 
; Purpose: This function finds the GOES EUV files for the time interval, satellite, and 
;  channel (EUVA, EUVB, or EUVE) specified and copies them to the temp dir on the user's computer.
;  
; Explanation: This function is called by geuv_read_files in the GOES object when GOES EUV data is selected. 
;  The temp dir is whatever the goes_temp_dir function returns; if dir doesn't exist, we create it.
;  The archive is on http://gs671-hesperia.ndc.nasa.gov/goes_euv/ organized by channel and year, and
;  contains the raw 10-sec data and flags in daily ASCII text files. They were written by the
;  geuv_write_daily_files.pro routine.  The original data is on
;  http://satdat.ngdc.noaa.gov/sem/goes/data/new_avg/yyyy/new_euv_temp/raw/ in yearly files
;  (separate data and flags files).
;  
; Input Keywords:
;  stime, etime - start, end time of data we want in anytim format
;  sat - number of satellite we want (13, 14, or 15). Default is 15.
;  chan - channel we want (EUVA, EUVB, or EUVE).  Default is EUVE.
;  
; Output Keywords:
;  nfiles - number of files found/copied
;  
; Output:  The function returns the names of the files on the local computer
; 
; Written:  Kim Tolbert 1-Mar-2016
; 
; Modifications:
; 25-Jul-2016 Kim, gs671-hesperia.ndc.nasa.gov didn't work, changed to hesperia.gsfc.nasa.gov
; 11-Oct-2016, Kim. Call sock_get instead of sock_copy, remove use_network from call, and add /quiet
; 04-Dec-2017, Kim. Changed url to use https - allows socket routines to catch error with older versions of IDL 
;   that can't handle the secure sites instead of just hanging and timing out
; 
;-

function geuv_find_files, stime=stime, etime=etime, sat=sat, chan=chan, nfiles=nfiles

checkvar, sat, 15
checkvar, chan, 'EUVE'

nfiles = 0
;url = 'http://gs671-hesperia.ndc.nasa.gov/goes_euv/'
url = 'https://hesperia.gsfc.nasa.gov/goes_euv/'
endtime = anytim(etime) - 1.  ; if end time is on day boundary, don't need that day's file
days = timegrid(anytim(stime, /date), endtime, /days, /strings, /quiet)
ymd = time2file(days, /date)
files = strlowcase(chan) + '/' + strmid(ymd,0,4) + '/' + 'g' + trim(sat) + '_' + strlowcase(chan) + '_' + ymd + '.txt

goes_dir=goes_temp_dir()
mk_dir,goes_dir,/a_write

;local_files = files
sock_get, url + files, out_dir=goes_dir,local_file=local_files,/no_check, /quiet
q = where(file_exist(local_files), nfiles)
if nfiles eq 0 then return, ' '

return,local_files[q]

end