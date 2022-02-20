;+
; Project:
;     SDAC
; Name:
;     GOES_CHIANTI_TEM
;
; Usage:
;     goes_chianti_tem, fl, fs, temperature, emission_meas, satellite=goes
;                       [, /photospheric, date=date_if_GOES_6 ]
;
;Purpose:
;     This procedure computes the temperature and emission measure of the
;     solar soft X-ray plasma measured with the GOES ionization chambers
;     using CHIANTI spectral models with coronal or photospheric abundances
;
;     Intended as a drop-in replacement for GOES_TEM that uses mewe_spec
;
;Category:
;     GOES, SPECTRA
;
;Method:
;     From the ratio of the two channels the temperature is computed
;     from a spline fit from a lookup table for 101 temperatures
;     then the emission measure is derived from the temperature and b8.
;     All the hard work is done in two other routines containing the
;     coefficients for the responses.
;
;Inputs:
;     FL - GOES long  wavelength flux in Watts/meter^2 (corresponds to data[*,0] in GOES object)
;     FS - GOES short wavelength flux in Watts/meter^2 (corresponds to data[*,1] in GOES object)
;
;Keywords:
;     satellite  - GOES satellite number, needed to get the correct response, e.g. sat=5. defaults to 8, but you should
;              definitely pass in the correct sat number to use the correct response.
;     photospheric - use photospheric abundances rather than the default
;              coronal abundances
;     DATE   - ANYTIM format, eg 91/11/5 or 5-Nov-91,
;              used for GOES6 where the constant used to scale the reported
;              long-wavelength channel flux was changed on 28-Jun-1993 from
;              4.43e-6 to 5.32e-6, all the algorithms assume 5.32 so FL prior
;              to that date must be rescaled as FL = FL*(4.43/5.32)
;     SECONDARY - for GOES16+ use the smaller aperture secondary detectors. (Default is 0)
;     NEW_TABLE - Use the newly formulated response tables using Chianti Version 9.0.1 (Recommended. Default is 1)
;
; Required Keyword:
;    REMOVE_SCALING - If set, apply the [.7, .85] unscaling factors to GOES8-15 data.  Previously always unscaled
;              G8-15 data, but new GOES G8-15 data at NOAA does not require unscaling. Also, as of Oct 2020,
;              the GOES object returns data that should not be unscaled (unless orig_scaling is set in obj).
;              This is a required keyword (if sat is G8-15) to make sure you know the source of your data and whether it
;              needs to be unscaled here.
;              This keyword is unncecessary and has no effect for sats other than G8-15.
;              Remove_scaling should be 0 if your G8-15 data is from the GOES object, any archive, and orig_scaling was set to 0.
;              Remove_scaling should be 1 if your G8-15 data is from:
;                the GOES object, sats 8-15 from the SDAC or YOHKOH archives, and orig_scaling was set to 1.
;                outside the GOES object, read from G8-15 operational files (i.e. not the NOAA L2 netcdf files).
;              If you use the GOES object, and call getdata with /quick_struct or /struct, the structure
;                returned contains the tag true_flux. If true_flux is 1, then remove_scaling should be 0.
;
;Outputs:
;     Temperature   - Plasma temperature in units of 1e6 Kelvin
;     Emission_meas - Emission measure in units of 1e49 cm-3
;
;Common Blocks:
;     None.
;
;Needed Files:
;     goes_get_chianti_temp, goes_get_chianti_em contain the coefficients.
;     also calls anytim, fcheck
;
; MODIFICATION HISTORY:
;     Stephen White, 04/03/24
;     Stephen White, 05/08/15: added the scl89 correction for GOES 8-12
;		Based on Chianti
;		(See goes_get_chianti_tem for Version. 5.2 at last revision)
;	  Richard Schwartz, 2010-dec-02, change GOES6 FL conversion date to 28-jun-1983 from
;		  28-jun-1993
;		Kim Tolbert, 2020-Jun-01, added remove_scaling keyword. G8-15 old data (from SDAC or Yohkoh)
;		  archives was scaled to match G1-7 data.  Here we are unscaling it to get back to physical
;		  units before we use transfer functions.  See note in header and warning in code for when to set.
;		Richard Schwartz, 2020-Jul-14, implement new GOES response based on Chianti v9.0.1 and
;		  for the first time including the transfer functions for GOES16 and 17
;		Kim Tolbert, 2020-Oct-14.  Require remove_scaling keyword for G8-15.  If not there, write message and return.
;		  Cleaned up / clarified header doc.
;
; Contact     : Richard.Schwartz@gsfc.nasa.gov
;
;-
;-------------------------------------------------------------------------

pro goes_chianti_tem, fl_in, fs_in, temp, em, satellite=satellite,$
  photospheric=photospheric, date=date, remove_scaling=remove_scaling, new_table = new_table, $
  secondary = secondary

  if keyword_set(satellite) then goes=fix(satellite) else goes=8

  if ~exist(remove_scaling) and (goes ge 8) and (goes lt 16) then begin
    msg = [$
      'ERROR - You must explicitly set the remove_scaling keyword to 0 or 1 for sats G8-15.  Aborting.', $
      '', $
      '  This routine uses "true flux".  Some GOES 8-15 data was scaled artifically; ', $
    '  remove_scaling=1 undoes that scaling to restore the "true flux".', $
      '', $
      'If you used the GOES object to retrieve the data:', $
      '  Use /remove_scaling if:', $
      '     You used the /orig_scaling keyword, AND', $
      '     the satellite is GOES 8 - 15, AND', $
      '     the archive used is SDAC or YOHKOH.', $
      '  Otherwise use remove_scaling=0.', $
      '', $
      'If you did NOT use the GOES object to retrieve the G8-15 data , you need to know whether the', $
      '   data was scaled or not. In general:', $
      '   Use remove_scaling=0 for data from NOAA netcdf files written since mid-2020.', $
      '   Use remove_scaling=1 for G8-15 data from operational data files.', $
      '', $
      'The remove_scaling keyword has no effect for satellites other than G8-15.', $
      '']

    prstr, msg, /nomore

    em = -1
    temp = -1
    return

  endif

  ;--------------------------- PREPARE THE DATA ----------------------------

  ; don't change input arrays
  b8 = fl_in
  fs = fs_in

  ; convert long channel flux if needed - GOES 6 data before 28-Jun-83 (not '93 as in old version)
  datechk = anytim('28-jun-1983',/sec)
  if anytim(fcheck(date, datechk),/sec) lt datechk and goes eq 6 then b8=b8*(4.43/5.32)

  ; GOES 8-15 data released in the operational data files were scaled to be consistent
  ;  with GOES-7: in fact GOES 8-15 fluxes are correct and so we need to
  ;  remove this scaling before proceeding to use transfer functions
  ;     Old scale values from Bornmann et al 1989 used until 2005 July in goes_tem as follows:
  ;        if (goes lt 8) then scl89= fltarr(2)+1. else scl89 = [0.790, 0.920]
  ; New scale values from Rodney Viereck (NOAA) (in e-mail to SWhite) are [.7,.85], 2004 June 09
  ;
  ; Added remove_scaling control 1-jun-2020, Kim, to allow for cases when GOES 8-15 aren't scaled or
  ;  have already been unscaled.


  scl89 =  keyword_set(remove_scaling) and (goes ge 8) and (goes lt 16)? [0.700, 0.850] : [1.0, 1.0]
  b8 = b8 / scl89[0]
  fs = fs / scl89[1]

  ; now calculate ratio where data are good
  index=where((fs lt 1.e-10) or (b8 lt 3.e-8))
  bratio=(fs>1.e-10)/(b8>3.e-8)
  if (index[0] ne -1) then bratio[index]=0.003

  ;--------------------------- EXACT FITS ----------------------------------

  if not keyword_set(photospheric) then photospheric=0
  default, new_table, 1
  if new_table or goes ge 16 then begin
    input = transpose( [[b8[*]>3e-8], [fs[*]>1.e-10]])
    goes_chianti_use_resp_table_manage, input, output, sat=goes, /flux_input, $
      secondary = secondary, photospheric = photospheric
    em = reform( output[0,*])
    temp = reform( output[1,*]) > 4.
  endif else begin
    ; hard work is done in these routines
    goes_get_chianti_temp,bratio,temp,sat=goes,photospheric=photospheric
    goes_get_chianti_em,b8,temp,em,sat=goes,photospheric=photospheric

    ; goes_get_chianti_em returns em in cm^-3, SOLARSOFT expects units of 10^49

    em=em/1.d49
  endelse
  return

end
