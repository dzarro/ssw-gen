;+
; Project     : STEREO - SSC
;                   
; Name        : NCDF2TAI()
;               
; Purpose     : Convert netCDF time values to CDS TAI time format
;               
; Explanation : This procedure converts netCDF milliseconds since 1970-01-01
;               into TAI seconds.
;
; Use         : TAI = NCDF2TAI(TIME)
;    
; Inputs      : TIME = Array of double precision values given as the number of
;                      milliseconds since the start of Unix time on 1970-01-01.
;                      Leap seconds are not counted.  This is the way TIME is
;                      stored in netCDF files from the DSCOVR mision as
;                      distributed by NOAA.
;               
; Opt. Inputs : None
;               
; Outputs     : Function returns CDS TAI time variable.
;               
; Opt. Outputs: None
;               
; Keywords    : ERRMSG	 = If defined and passed, then any error messages 
;			   will be returned to the user in this parameter 
;			   rather than being handled by the IDL MESSAGE 
;			   utility.  If no errors are encountered, then a null 
;			   string is returned.  In order to use this feature, 
;			   the string ERRMSG must be defined first, e.g.,
;
;				ERRMSG = ''
;				RESULT = NCDF2TAI( TIME, ERRMSG=ERRMSG )
;				IF ERRMSG NE '' THEN ...
;
;               Also accepts any keywords for UTC2TAI
;
; Calls       : GET_TAI, TAI2TAI
;
; Common      : None
;               
; Restrictions: None
;               
; Side effects: If an error condition is encountered, and the ERRMSG keyword is
;               used, then the single value -1 is returned.
;               
; Category    : netCDF, Time
;               
; Prev. Hist. : Based partially on cdf2tai.pro
;
; History     :	Version 1, 29-Jul-2016, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-            
;
function ncdf2tai, time, errmsg=errmsg, _extra=_extra
on_error, 2
;
;  Check the input parameter.
;
if n_params() eq 0 then begin
    message = 'Syntax: TAI = NCDF2TAI(TIME)'
    goto, handle_error
endif
n_times = n_elements(time)
if n_times eq 0 then begin
    message = 'TIME undefined'
    goto, handle_error
endif
sz = size(time)
if sz[sz[0]+1] ne 5 then begin
    message = 'TIME must be double precision'
    goto, handle_error
endif
;
;  Convert from milliseconds since 1970-01-01 into TAI (without leapseconds),
;  and then convert back-and-forth between UTC to take leap seconds into account.
;
tai = 378691209.d0 + (time / 1000.d0)
return, utc2tai(tai2utc(tai,/nocorrect), _extra=_extra)
;
;  Error handling point.
;
handle_error:
    if n_elements(errmsg) eq 0 then message, message else $
      errmsg = 'NCDF2TAI: ' +message
    return, -1
;
end
