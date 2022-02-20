;+
; Routine: GOES_FLUX49, now deprecated in favor of GOES_FLUXES
;
; Purpose: 
;  This is the old routine used to compute the expected Long (B) and Short (A) channel fluxes
;  (irradiances) given the temperaure and emission measure. The units of irradiance are
;  Watts/M^2 and the inputs are in units of MegaKelvin and Solar Emission Measure in 1e49cm^(-3).
;  It was used with GOES1-15 and uses computations based on CHIANTI 7.1. 
;  It's been supplanted by GOES_FLUXES which uses
;  CHIANTI 9.0.1. Goes_flux49 will not be modified going forward. 
;
; Inputs:
;		TMK - temperature - vector or scalar in MegaKelvin
;			valid range 4-100 MegaKelvin
;			where TMK is out of range, FL and FS are returned as if for 4 and 100 respectively
; 	EM49 - solar emission measure in units of 1e49cm^(-3)

; Outputs:
;		FL - Long wavelength GOES XRS flux in Watts/meter^2
;		FS - Short wavelength GOES XRS flux in Watts/meter^2
;
; KEYWORD;
;	SAT - Number of GOES satellite - 1-15 valid, 16 and greater throws an error
;	DATE - DATE in anytim readable format, fully referenced.
;		GOES8 fudge factor is date dependent
;	PHOTOSPHERIC - if set use photospheric abundance
;		in GOES_GET_CHIANTI_[TEMP,EM] routines, otherwise coronal is default
; TRUE_FLUX - if set, scaling factors are not applied. Only the given transfer function 
;  has been used.  New, July 2020. Scaling factors applied by NOAA to the observed irradiances 
;  are being removed by NOAA although it hasn't been completed in the NOAA archives
;  Please see the NOAA websites for a discussion of GOES XRS scaling factors for GOES 8-15
;	ERROR - if set then input is problematic
;
; HISTORY: 4-apr-2008, richard.schwartz@nasa.gov,
;	22-apr-2011, richard.schwartz@nasa.gov, changed goes6 date to 28-jun-1983
;	 This routine calls goes_get_chianti_temp and goes_get_chianti_em which were
;	 upated 02/26/13 to use  CHIANTI version 7.1
;	3-jul-2020, RAS, TRUE_FLUX keyword implemented
;	6-OCT-2020, RAS, documentation edited
;
;-
pro goes_flux49, tmk, em49, fl, fs, $
  sat=sat, date=date, photospheric=photospheric,$
  true_flux = true_flux, $
  error=error

  error = 1
  default, tmk ,[ 9.1, 9.33, 10.4]
  default, em49, 1.0
  default, photospheric, 0 ;default is coronal abundance
  ntmk = n_elements(tmk)
  nem  = n_elements(em49)
  fl   = -1
  fs   = -1

  case 1 of
    ntmk eq nem :
    ntmk eq 1 : tmk = tmk[0] + em49*0.0
    nem  eq 1 : em49= em49[0] + tmk*0.0
    else: Message,/continue,'Number of Tmk and Em49 must be the same or 1'
  endcase

  default, sat, 8
  if sat ge 16 then message,'Cannot be used with sat ge 16. Uses CHIANTI 5.2 response tables from 2005'
  ;f keyword_set(sat) then goes=fix(sat) else goes=8
  valid_temp = tmk > 1. < 100.
;Get the ratio tables for coronal and photospheric abundance
;Ratio is for all the satellites for all 101 temperatures
  goes_get_chianti_temp,  0.1, t01,  r_cor=rt, r_pho=rt_pho
;  IDL> help, rt, rt_pho
;  RT              FLOAT     = Array[15, 101]
;  RT_PHO          FLOAT     = Array[15, 101]
  if photospheric eq 1 then rt = rt_pho
  rt=reform(rt[sat-1,*])

  logtemp=findgen(101)*.02d0 ;Tables were computed for these temperatures
  temp=10^logtemp ;Temp ranges from 1.0 to 100 Million Kelvin (MK)

  fl6 =1e-6+rt*0.0
  ;Now using the same tables which gave the ratio, we supply a flux in the Long channel
  ;of 1e-6 Watts/m^2, ie a C flare for each temperature. This returns the emission measure in
  ;units of 1e49/cm^3 at all 101 temps in the table
  goes_get_chianti_em, fl6, temp, em6, sat=sat, photospheric=photospheric


  ;em6[i] is the emission measure necessary to obtain fl of 1e-6 at temp[i]

  ord = sort(valid_temp) ; spline requires a monotonic input
  fl  = valid_temp
  fs  = valid_temp
  al10_em_tmk = spline(logtemp, alog10(em6), alog10(valid_temp[ord]), .01)
  fl[ord]     = 10^(-6 + 49-al10_em_tmk) * em49[ord]
  fs[ord]     = spline(logtemp, rt, alog10(valid_temp[ord])) * fl[ord]


  ;--------------------------- Takeout any fudge factors ----------------------------

  ; convert long channel flux if needed - GOES 6 data before 28-Jun-83, from 93, ras 22-apr-2011
  ; not sure about the use of TRUE_FLUX here, need guidance from NOAA
  if anytim(fcheck(date, 1.4160960e+008),/sec) lt 1.4160960e+008 $
    and sat eq 6 then fl = fl / (4.43/5.32)

  ; Recent fluxes released to the public are scaled to be consistent
  ; with GOES-7: in fact recent fluxes are correct and so we need to
  ; remove this correction before proceeding to use transfer functions
  ; old version from Bornmann et al 1989 used until 2005 July in goes_tem
  ; if (goes lt 8) then scl89= fltarr(2)+1. else scl89 = [0.790, 0.920]
  ; new version from Rodney Viereck (NOAA), e-mail to SW, 2004 June 09
  ;if (goes lt 8) then scl89= fltarr(2)+1. else scl89 = [0.700, 0.850]
  scl89 = (sat lt 8) or keyword_set( true_flux ) ? fltarr(2)+1.0 : [0.700, 0.850]
  fl = fl * scl89[0]
  ; don't change input arrays
  fs = fs * scl89[1]

  error = 0
end