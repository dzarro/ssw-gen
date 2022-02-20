;+
;---------------------------------------------------------------------------
; Document name: carr2xy.pro
; Created by:    Wei Liu, Jan 14, 2020
;
;---------------------------------------------------------------------------
;
; PROJECT:
;       IRIS
; NAME:
;       carr2xy.pro
; PURPOSE: 
;       Convert Carrington (lon,lat) coordinates to heliocentric (x,y) in arcsec for a given date.
;
; CATEGORY: Utility/Solar Coordinate Conversion
;
; CALLING SEQUENCE: 
;   xy= carr2xy(lonlat, date='2020-01-14T00:00')  ; for Carrington lonlat (= [lon,lat]) =[200,5]
;     or lonlat=[ [200,5], [100,20], [150, 30] ]  ; for mulitple points
;
; INPUTS:
;   lonlat: fltarr(2, n)= [ [lon0,lat0], [lon1,lat1], ... ]
;   date: anytim() format, e.g., '2020-01-14T14:54:30'; default: today
;   /loud: more runtime info
;
;   algorithm: approach for calculation (case sensitive), valid inputs are:
;     'SunSPICE' (default): using SunSPICE and actual ephemeris data (most accurate; recommended)
;     'WCS': using WCS,
;     'kludge': using the original kludgy way, with old routines (e.g., lonlat2xy.pro)
;               - (least accurate; not recommended, but keep it here for backward compatibility)
;
; OUTPUTS:
;   xy: function return or as optional output keyword, 
;       fltarr(2, n)= [ [x0,y0], [x1,y1], ... ] (if /loud, prints [x,y] on the screen)
;
;   Optional:
;     lonCM: central meridian's Carrington longitude
;
; Notes:
;  2020/01/23: if algorithm='WCS', per today's email from William Thompson, author of WCS, 
;         NaN will be returned for far-side points (beyond the solar limb), e.g., 
;    IDL> lonlat=[ [200,5], [100,20], [150, 30] ]
;    IDL> date='2020-01-14T00:00'
;    IDL> xy= carr2xy(lonlat, date=date, /loud, algorithm='WCS')
;        xy (arcsec):
;         -840.59720       122.43517
;           NaN             NaN
;           NaN             NaN
;   TBD: far-side points will be allowed in future WCS updates, as is the case for algorithm='SunSPICE' or 'kludge'
; 
;
; History:
;   2020/01/14, Tue: written for PSP-IRIS coordination, which has coordination given in Carrington (lon,lat)
;    see https://whpi.hao.ucar.edu/whpi_campaign-cr2226.php
;   2020/01/22, Wed: major revision, included Bill Thompson's SunSPICE (now default, most accurate) and WCS approaches;
;     Downgrade the old approach (approximate) to "kludge" algorithm.
;   2020/01/23, Thu: added Notes above about NaN returned for back-side points if using algorithm='WCS'
;-
;===========================================================================

function carr2xy, lonlat, date=date, algorithm=algorithm, xy=xy   $
   , loud=loud, lonCM=lonCM, _extra=_extra

;--- (1) read parameters ------------------------

checkvar, algorithm, 'SunSPICE'

if ~exist(lonlat) then begin
  print, 'Calling Sequence: xy= carr2xy([100, 200], date=date)'
  read, lon, lat, PROMPT='input lonlat (in Carrington [longitude,latitude]): '  
  lonlat=[lon, lat]
endif

npt= N_elements(lonlat[0,*])	; number of locations to be converted
xy= fltarr(2,npt)

if ~keyword_set(date) then begin
  date=systim(0)
  print, 'Please provide date in anytim() format; otherwise use today"s date: ' + date
endif

if keyword_set(loud) then help,lonlat,date

;--- (2) convert Carrington to Stonyhurst Coordination in heliographic (lon, lat), then to heliocentric (x,y) in arcsec----
lonCM= tim2carr(date)	;central meridian's Carrington longitude
if keyword_set(loud) then print, lonCM, ' = Carrington longitude of the Central Meridian'
case algorithm of

  'SunSPICE': begin		;--- using SunSPICE ------
    if keyword_set(loud) then print,'Using SunSPICE and actual ephemeris data (most accurate, recommended)'
    rsun = wcs_rsun(unit='au')
    for i=0, npt-1 do begin
      coord = [rsun, lonlat[0,i], lonlat[1,i]]
      convert_sunspice_lonlat, date, coord, 'carr', 'hpc', /deg, /au, sp='Earth'
      xy[*,i]=coord[1:2]*3600.
    endfor
  end

  'WCS': begin		;--- using WCS --------
    if keyword_set(loud) then print,'Using WCS ...'
    wcs = wcs_2d_simulate(1024, date_obs=date)
    wcs_convert_to_coord, wcs, xy, 'hg', reform(lonlat[0,*]), reform(lonlat[1,*]), /carrington
  end

  'kludge': begin	;--- using the original kludgy way ------
    if keyword_set(loud) then print,'Warning: Using a kludgy algorithm, least accurate, not recommended'
    lonlat1= lonlat*1.0		; upgrade to float, in case lonlat is passed in as integer
    for i=0, npt-1 do lonlat1[0,i] -= lonCM 	;convert to Stonyhurst Coord. (lon, lat)
    ;--- convert from Stonyhurst (lon,lat) to helioprojective (x,y) in arcsec ----
    xy= lonlat2xy(lonlat1, date, _extra=_extra)
    if keyword_set(loud) then begin
      print,' [lon,lat] (deg, Stonyhurst coord):'
      print, lonlat1
    endif
  end

  else: print, 'Algorithm provided is not recognized. Valid inputs (case sensitive) are: SunSPICE, WCS, or kludge'
endcase

if keyword_set(loud) then begin
  print,' xy (arcsec):'
  print, xy
endif

return, xy
end

