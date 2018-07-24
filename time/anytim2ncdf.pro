;+
; Project     : STEREO - SSC
;                   
; Name        : ANYTIM2NCDF()
;               
; Purpose     : Convert CDS time values to NCDF time values
;               
; Explanation : This procedure calls ANYTIM2UTC and UTC2TAI to convert CDS time
;               values to the number of milliseconds since 1970-01-01 as used
;               in netCDF files.
;
; Use         : TIME = ANYTIM2NCDF(DATE)
;    
; Inputs      : DATE = Array of date values.
;               
; Opt. Inputs : None
;               
; Outputs     : Function returns the dates converted into netCDF format.
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
;				RESULT = ANYTIM2NCDF( DATE, ERRMSG=ERRMSG )
;				IF ERRMSG NE '' THEN ...
;
;               Also accepts any keywords for ANYTIM2UTC
;
; Calls       : ANYTIM2UTC, UTC2TAI
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
; Prev. Hist. : Partially based on anytim2cdf.pro
;
; History     :	Version 1, 29-Jul-2016, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-            
;
function anytim2ncdf, date, errmsg=errmsg, _extra=_extra
on_error, 2
;
;  Check the input parameter.
;
if n_params() eq 0 then begin
    message = 'Syntax: TIME = ANYTIM2NCDF(DATE)'
    goto, handle_error
endif
n_times = n_elements(date)
sz = size(date)
;
;  Convert to TAI format.
;
message = ''
tai = utc2tai(anytim2utc(date, errmsg=message), /nocorrect)
if message ne '' then goto, handle_error
;
;  Convert into the number of non-leap milliseconds since 1-Jan-1970.
;
time = 1000.d0 * (tai - 378691209.d0)
return, time
;
;  Error handling point.
;
handle_error:
    if n_elements(errmsg) eq 0 then message, message else $
      errmsg = 'ANYTIM2NCDF: ' +message
    return, -1
;
end
