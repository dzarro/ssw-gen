;+
; :Description:
;    Use the newly formulated response tables using Chianti Version 9.0.1 including the responses
;    for GOES1-17 to interpolate for temperature or emission measure from the measured true fluxes or conversely
;    to predict the net true fluxes based upon input temperatures and emission measures
; :Params:
;    input - a 2xN or Nx2 arrary of long and short channel fluxes (true fluxes) in Watts/M^2
;    or (if FLUX_INPUT is set to 0) a 2xN or Nx2 array of Emission Measure (1e49 cm-3) and Temperature(TEMP)
;    in MegaKelvin
;    output - for FLUX_INPUT of 1 (default) returns EM and TEMP in units described for input
;    and for FLUX_INPUT of 0 returns the long and short channels in Watts / M^2 in the same shape as
;    the input
;
; :Keywords:
;    SAT - GOES XRS satellite - 1-17 as of 14-jul-2020
;    FLUX_INPUT - logical, 0 or 1, if set then the input is in true flux in Watts/M^2 and 
;      the output will be emission measure in units
;      of 1e49/cm^3 and temperature in MegaKelvin
;    SECONDARY - logical array of 1's and 0's. The times/indices for the secondary (smaller) detectors have 1's
;    PHOTOSPHERIC - 1 or 0, if set, use response for photospheric abundances
;    SCALE16 - default is 1.32 as of 8-sep-2020 (RAS) Corrects GOESR A channel to match temperatures
;    seen with GOES15- A channels. By setting SCALE16 to 1, or setting the environment variable
;    setenv,'GOES_SCALE16_DISABLE=1' the action of SCALE16 is disabled.  The action of SCALE16 has
;    been taken in consultation with S White, A Caspi, and H Hudson. We hope this becomes unnecessary
;    in the future should NOAA take action on their part in reporting the flux from the GOESR instruments
;    
; :Example:
;    IDL> help, input & goes_chianti_use_resp_table, input, out, sat=15, flux_input = 1
;    INPUT           FLOAT     = Array[1, 2]
;    IDL> print, input
;    1.00000e-006
;    3.00000e-007
;    IDL> print, out
;    0.0299670
;    21.2304
;    IDL> input = reform( reproduce( [1.e-6,3e-7],3))
;    IDL> help, input
;    INPUT           FLOAT     = Array[2, 3]
;    IDL> help, input & goes_chianti_use_resp_table, input, out, sat=15, flux_input = 1
;    INPUT           FLOAT     = Array[2, 3]
;    IDL> out
;    0.029967025       21.230410
;    0.029967025       21.230410
;    0.029967025       21.230410
;    IDL> help, input & goes_chianti_use_resp_table, transpose(input), out, sat=15, flux_input = 1
;    INPUT           FLOAT     = Array[2, 3]
;    IDL> out
;    0.029967025     0.029967025     0.029967025
;    21.230410       21.230410       21.230410
;    
;    Now take the output in Em(*1e49) and Temp in MK and use that as the input
;    by setting FLUX_INPUT to 0
;    IDL> help, out & goes_chianti_use_resp_table, out, input_recovered, sat=15, flux_input = 0
;    OUT             FLOAT     = Array[2, 3]
;    IDL> print, input
;    1.00000e-006 3.00000e-007
;    1.00000e-006 3.00000e-007
;    1.00000e-006 3.00000e-007
;    IDL> print, input_recovered
;    1.00000e-006 2.99972e-007
;    1.00000e-006 2.99972e-007
;    1.00000e-006 2.99972e-007
;    
; :Hidden_file: Requires goes_chianti_resp.fits produced by goes_chianti_respons.pro
;  This file contains the pregenerated responses for default coronal and photospheric ion abundances
;  using Chianti version 9.0.1 This file is in either the working directory or in ssw/gen/idl/synoptic/goes
;  accessed through GOES_CHIANTI_RESP_NEW_TABLE_SET
; :Author: 14-jul-2020, rschwartz70@gmail.com
; 5-sep-2020, added goesr fudge of 1.32 for scale16 and observed keyword
; 8-sep-2020, expanded documentation and environment variable control of SCALE16
; 21-sep-2020, changed fudge to 1.4 as it's believed from the ratio 3.5/2.5
;-
pro goes_chianti_use_resp_table, input_in, output, sat=sat, flux_input = flux_input, $
  secondary = secondary, photospheric = photospheric, $
  scale16 = scale16

  default, photospheric, 0
  default, flux_input, 1 ; goes fluxes, 2xN are input values, or detected N x 2 if N gt 2
  default, sat, 15
  default, secondary, 0
  default, scale16, 1.40 ;21-sep-2020, correction for observed A(short)channel flux
  warning = ["The default action for GOES 16 and 17 when finding the temperature is to multiply the reported ", $
    "Short wavelength A channel flux by an empirical correction factor that is called SCALE16. ", $
    "By comparison with temperatures measured with GOES15 the factor is set to 1.40 by default. ", $
    "The origin of the factor is believed to be from the difference in the gbar divisor actually ", $
    "used and the value claimed. While 3.5A is claimed we believe 2.5A was used as for GOES13-15.",$
    "This factor has been determined jointly by Richard Schwartz, Stephen White, Amir Caspi, and Hugh Hudson.", $
    "This factor is applied by default when determining the temperature/emission measure pairs as well as when ", $
    "computing the expected A channel irradiance from a supplied T/EM pair. In this case the A(short) irradiance is ", $
    "divided by SCALE16 so input irrandiance pairs will match the derived irradiance from the solution to the ",$
    "input irradiance pairs.", $
    "To disable this action; setenv,'GOES_SCALE16_DISABLE=1' and then to re-enable setenv,'GOES_SCALE16_DISABLE=0'",$
    "You should only see this message one time per IDL session as it will set a system variable indicating ", $
    "that it has been displayed.  The system variable is called !SCALE16_MESSAGE. Once displayed its value is 0.",$
    "Setting !SCALE16_MESSAGE to 1 will re-enable the message one time."]
  defsysv,'!SCALE16_MESSAGE',exist=exist
  defsysv,'!SCALE16_VALUE',1.0 ;by default, does nothing unless env set and sat ge 16
  do_message = 1 
  if exist eq 1 then do_message = !scale16_message else defsysv,'!SCALE16_MESSAGE',1
  
  
  if getenv('GOES_SCALE16_DISABLE') eq 1 then scale16 = 1.0
  
  if do_message and scale16 ne 1.0 and sat ge 16 then begin
    print, '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
    print, warning, form='("    ",a)'
    print, '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
    !scale16_message =0
  endif
  if sat ge 16 then !scale16_value = scale16
  input = input_in
  siz_in = size(/str, input )
  flip   = siz_in.dimensions[0] gt 2
  n2   = siz_in.n_elements eq 2
  input  = flip ? transpose( input ) : input
  ;Put the input into the expected form
  if flux_input then begin
    ratio = n2 ? f_div( input[1], input[0] ) : f_div( input[1,*], input[0,*] )
    long  = reform( input[0,*] )
    if sat ge 16 then ratio = ratio * scale16

  endif else begin

    em_in   = n2 ? input[0] :input[0,*]
    temp = n2 ? input[1] : input[1,*]
    

  endelse
  common goes_chianti_resp_com, aa, slr
;    IDL> help, aa
;    AA              STRUCT    = -> GOES_TRUE_FLUX Array[17]
;    IDL> help, aa,/st
;  ** Structure GOES_TRUE_FLUX, 12 tags, length=2088, data length=2083:
;     DATE            STRING    '27-Jul-20'
;     VERSION         STRING    '9.0.1'
;     METHOD          STRING    'goes_chianti_response'
;     SAT             INT             16
;     SECONDARY       BYTE         0
;     ALOG10EM        FLOAT           55.0000
;     TEMP_COEF       FLOAT     Array[2]
;     TEMP_MK         FLOAT     Array[101]
;     FLONG_PHO       FLOAT     Array[101]
;     FSHORT_PHO      FLOAT     Array[101]
;     FLONG_COR       FLOAT     Array[101]
;     FSHORT_COR      FLOAT     Array[101]  result = goes_true_flux( method =  'goes_chianti_response')
;    
  ;Check to see if the precomputed response tables have been loaded
  ;If not load the data file and compute the ratio table, SLR SHORT LONG RATIO
  goes_chianti_resp_new_table_set, aa
  ;convert the satellite number into an index
  isat  = (where( aa.sat eq sat and aa.secondary eq secondary, nisat))[0]
  if nisat eq 0 then message,'Satellite and Secondary condition not found in table Sat:'+strtrim(sat,2)+' '+ $
    'Secondary: '+strtrim(secondary,2)

  ;FLUXES IN WATTS/M^2 are the input
  if flux_input then begin
    dim   = size(/dim, slr )
    tbl   = aa[isat]
    table_to_response_em = 10.0^(49.-tbl.alog10em)
; Interpolate the ratio to get the table index
    index = interpol(/spl, findgen( dim[0]), slr[*,isat, photospheric], ratio )
; Interpolate the index to get the temperature
    temp  = interpol(/spl, tbl.temp_mk, findgen( dim[0]), index)
    ;Now that we have the temp, find the em and scale to 1e49 cm-3
; Interpolate the index to get the emission measure
    em_table = ( photospheric ? tbl.flong_pho : tbl.flong_cor ) * table_to_response_em
; Use the input long channel data to scale the interpolated EM_table values
    em    = long / interpol( /spl, em_table, findgen(101), index)
    output = float( input*0.0 )
; Shape and load the output array
    if n2 then output = reform( [em,temp], size( input_in,/dim)) else begin
      output[ 0, *] = em
      output[ 1, *] = temp
    endelse
    output = flip ? transpose( output ) : output
  endif else begin ; em and temp entered to return expected fluxes
    dim   = size(/dim, slr )
    tbl   = aa[isat]
    table_to_response_em = 10.0^(49.-tbl.alog10em)
    emscl = em_in * table_to_response_em ;(expect 1e-6)
    ;Get the precomputed long and short channel True fluxes for 
    longtbl  = photospheric ? tbl.flong_pho : tbl.flong_cor
    shorttbl = photospheric ? tbl.fshort_pho : tbl.fshort_cor
    ;Interpolate the long and short response tables to find the values
    ;for the temperature input
    ;Then scale the values based on the input emission measure which is in units
    ;of 1e49cm-3 and then tables in units of 1e55cm-3
    long  = emscl * interpol( /spl, longtbl, tbl.temp_mk, temp )
    short = emscl * interpol( /spl, shorttbl, tbl.temp_mk, temp)
    if sat ge 16  then short = short / scale16 
    output = float( input*0.0 )

    if n2 then output = reform( [long, short], size( input_in,/dim)) else begin
      output[ 0, *] = long
      output[ 1, *] = short
    endelse
    output = flip ? transpose( output ) : output


  endelse
end