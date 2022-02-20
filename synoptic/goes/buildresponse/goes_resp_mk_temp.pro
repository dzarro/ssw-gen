;+
; :Description:
;    This function computes the temperature (MK) used to
;    compute the GOES XRS true fluxes
;
; :Params:
;    An array or a single index. Accepts floating point input for
;    interpolation tables
; :Keywords
;    temp_coef_input - default, [10, 0.2], may also be a structure with the TEMP_COEF field where the values
;    are used, (assumes a 2 element floating vector).
; :Returns:
;  temp_coef[0]^( float( index ) * temp_coef[1] )
;
;
; :Author: Richard Schwartz, rschwartz70@gmail.com
; Derived from make_goes_chianti_response developed by White, Schwartz, Thomas circa 2005
; 3-July-2020
;-
function goes_resp_mk_temp, index, temp_coef_input = temp_coef_infput

  default, temp_coef_input, [10.,0.02]
  default, index, findgen( 101 )
  temp_coef = is_struct( temp_coef_input ) && have_tag( temp_coef_input,'TEMP_COEF' ) ? temp_coef_input.temp_coef : temp_coef_input
  return, temp_coef[0]^( float( index ) * temp_coef[1] )
end