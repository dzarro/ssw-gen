;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_GET_NAR
;
; Purpose     :	Get NOAA active region listings
;
; Category    :	Object graphics, 3D, Planning, Widget
;
; Explanation : Retrieves the Carrington locations of NOAA active regions for
;               the 15 day period leading up to the requested date.  This
;               period was selected to cover both the front and back sides of
;               the Sun.
;
; Syntax      :	SUNGLOBE_GET_NAR, DATE, NOAA, LON, LAT
;
; Examples    :	
;
; Inputs      :	TARGET_DATE = The target date/time currently being used within
;                             SunGlobe.
;
; Opt. Inputs :	None
;
; Outputs     :	NOAA    = A list of NOAA active region numbers.
;               LON     = Array of Carrington longitudes
;               LAT     = Array of Carrington latitudes
;
; Opt. Outputs:	None
;
; Keywords    :	None
;
; Calls       :	ANYTIM2UTC, UTC2TAI, GET_NAR, ARCMIN2HEL, GET_SUNSPICE_LONLAT,
;               DIFF_ROT, TIM2CARR
;
; Common      :	None
;
; Restrictions:	None
;
; Side effects:	None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 01-Apr-2019, William Thompson, GSFC
;               Version 2, 02-Apr-2019, WTT, change XACK to PRINT
;               Version 3, 03-Mar-2020, WTT, default to TIM2CARR if SunSPICE
;                                            not loaded
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_get_nar, target_date, noaa, lon, lat
;
;  Convert the target date to UTC (and TAI), and form the date for 15 days
;  earlier.
;
utc1 = anytim2utc(target_date)
utc0 = utc1  &  utc0.mjd = utc1.mjd - 15
tai1 = utc2tai(utc1)
;
;  Call GET_NAR to return the NOAA active region data.
;
errmsg = ''
delvarx, noaa, lon, lat
nar = get_nar(utc0, utc1, /quiet, err=errmsg)
if errmsg ne '' then print, errmsg
if datatype(nar) ne 'STC' then return
;
;  Extract the dates from the NAR structure, and calculate the number of days
;  for each entry relative to the target date.
;
utc = anytim2utc(nar,/ccsds)
tai = utc2tai(utc)
ndays = (tai1 - tai) / 86400
;
;  Extract the NOAA active region numbers.
;
noaa = nar.noaa
;
;  Calculate the Carrington longitudes and latitudes, taking differential
;  rotation into account.
;
n = n_elements(utc)
lon = fltarr(n)
lat = fltarr(n)
;
;  Determine whether or not the SunSPICE package has been loaded.
;
which, 'get_sunspice_lonlat', /quiet, outfile=temp
sunspice_loaded = temp ne ''
;
for i=0,n-1 do begin
    coord = arcmin2hel(nar[i].x/60., nar[i].y/60., date=utc[i])
    if sunspice_loaded then begin
        lonlat = call_function('get_sunspice_lonlat', utc[i], 'Earth', $
                               system='Carrington', /degrees)
        carr0 = lonlat[1]
    end else carr0 = tim2carr(utc[i])
;
    lat[i] = coord[0]
    drot = diff_rot(ndays[i], lat[i], /carrington)
    lon[i] = (coord[1] + carr0 + drot) mod 360
    if lon[i] lt 0 then lon[i] = lon[i] + 360
endfor
;
end
