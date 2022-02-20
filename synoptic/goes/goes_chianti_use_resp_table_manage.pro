;+
; :Description:
;    GOES16 & GOES17 have primary and secondary detectors to extend the dynamic range. During intense
;    flares both the primary and secondary fluxes may be reported and this routine matches the data
;    with the correct response.  This will have no effect on GOES1-15 and where the SECONDARY keyword input
;    is not used. This code MANAGES this difference, otherwise GOES_CHIANTI_USE_RESP_TABLE could be called directly
;
; :Params:
;    input_in - 2 x N or N x 2 array of GOES fluxes (irradiance) or emission measure temperature pairs.
;    if fluxes, B (Long) channel is first and A (Short) second. Units, Watts/meter^2
;    if EM/T pairs - Emission measure first in units of 1e49 cm-3 and Temp in MegaKelvin
;    output
;
; :Keywords:
;    SAT - GOES XRS satellite - 1-17 as of 14-jul-2020
;    FLUX_INPUT - logical, 0 or 1, if set then the input is in true flux in Watts/M^2 and 
;      the output will be emission measure in units
;      of 1e49/cm^3 and temperature in MegaKelvin
;    SECONDARY - logical array of 1's and 0's. The times/indices for the secondary (smaller) detectors have 1's
;    PHOTOSPHERIC - 1 or 0, if set, use response for photospheric abundances
;
; :Author: rschwartz70@gmail.com, 17-jul-2020
;-
pro goes_chianti_use_resp_table_manage, input_in, output, sat=sat, flux_input = flux_input, $
  secondary = secondary, photospheric = photospheric

  default, secondary, 0b
  ninput = n_elements( input_in ) / 2 ; 2 entries per input, long & short or EM & temperature
  nscnd  = n_elements( secondary )
  if ninput ne nscnd and nscnd ne 1 then message,'Secondary must be a single value or one for every input pair '
  secondary =  nscnd eq ninput ? secondary : byte(secondary[0]) + bytarr(ninput)
  qscnd = where( secondary, nqscnd, comp = qprm, ncomp = nqprm )
  ; Here we keep track of the indices that belong to the primary and secondary detectors respectively
  if nqscnd ge 1 then goes_chianti_use_resp_table, input_in[*,qscnd], output_scnd, sat=sat, flux_input = flux_input, $
    /secondary, photospheric = photospheric

  if nqprm ge 1 then goes_chianti_use_resp_table, input_in[*,qprm], output_prm, sat=sat, flux_input = flux_input, $
    secondary = 0, photospheric = photospheric
  case 1 of
    nqprm eq ninput: output = output_prm
    nqscnd eq ninput: output = output_scnd
    else: begin ;mixed primary and secondary
      output = input_in * 0.0
      dim    = size(/dimension, output)
      if dim[0] eq 2 then begin
        output[*,qprm] = output_prm
        output[*,qscnd] = output_scnd
      endif else begin
        output[qprm,*] = output_prm
        output[qscnd,*] = output_scnd

      endelse
    end
  endcase
end
