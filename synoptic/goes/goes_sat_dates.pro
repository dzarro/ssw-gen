;+
; Name: goes_sat_dates
;
; Purpose:  Function to return the dates that the various GOES satellites were in operation
; 
; Method: Reads a text file $SSW/gen/idl/synoptic/goes/goes_sat_times.txt containing start/end dates, comment, and 
;   additional time range (if any) that each satellite was in operation for XRS and EUV detectors. Stores the info in common. 
;
; Calling sequence:  str = goes_sat_dates()
;
; Input Keywords:
;   det - detector to get dates for, options are 'XRS' or 'EUV'
;   sat - string or numeric satellite number, e.g. sat=6. Only used if det passed in.
;   range - if set, return range of dates. Only used if det and sat are passed in.
;   refresh - if set, read text file again and store in common. Otherwise uses what's in common.
;
; Output: Either a structure containing these tags:
;   str = {det: '', sat: '', tstart: '', tend: '', comment: '', tsmore: '', temore: ''}
;   Or a range of times (if det, sat, and range keywords are set)
;   
; Calling Example:
;
;   help, goes_sat_dates()
;      <No name>       STRUCT    = -> <Anonymous> Array[21]
;
;   ptim,goes_sat_dates(det='xrs', sat=8, /range)
;      21-Mar-1996 00:00:00.000 18-Jun-2003 00:00:00.000
;     
; Written: 24-Sep-2020, Kim Tolbert
; Modifications:
;
;-

function goes_sat_dates, det=det, sat=sat, range=range, refresh=refresh

  common goes_sat_dates_common, goes_dates_str

  if ~is_struct(goes_dates_str) || keyword_set(refresh) then begin
    sat_times_file = concat_dir(local_name('$SSW/gen/idl/synoptic/goes'), 'goes_sat_times.txt')
    if ~file_exist(sat_times_file) then begin
      message, /cont, 'Aborting. File containing GOES satellite time ranges does not exist:  ' + sat_times_file
      return, -1
    endif
    z = rd_tfile(sat_times_file, 8, delim=';', nocomment=';', /first_char_comm)

    str = {det: '', sat: '', tstart: '', tend: '', comment: '', tsmore: '', temore: ''}

    nstr = n_elements(z[0,*])
    str = replicate(str, nstr)
    str.det = reform(z[0,*])
    str.sat = reform(z[1,*])
    str.tstart = reform(z[2,*])
    str.tend = reform(z[3,*])
    str.comment = reform(z[4,*])
    str.tsmore = reform(z[5,*])
    str.temore = reform(z[6,*])
    
    q = where(str.comment eq 'none', nq)
    str[q].comment = ''

    goes_dates_str = str
  endif

  if keyword_set(det) then begin
    qdet = where(strlowcase(goes_dates_str.det) eq strlowcase(det), ndet)
    if ndet gt 0 then begin
      if keyword_set(sat) then begin
        qsat = where(goes_dates_str[qdet].sat eq trim(sat), nsat)
        if nsat gt 0 then begin
          ds = goes_dates_str[qdet[qsat]]
          if keyword_set(range) then begin
            dates = [ds.tstart, ds.tend]
            if ds.tsmore ne '' then dates = [dates, ds.tsmore, ds.temore]
            q = where(dates eq 'present', nq)
            if nq gt 0 then dates[q] = !stime
            return, minmax(anytim(dates))
          endif else return, ds          
        endif else return, -1
      endif
      return, goes_dates_str[qdet]
    endif else return, -1
  endif

  return, goes_dates_str

end
