;+
; :Description:
;    Use the values extracted computed using MAKE_GOES_CHIANTI_RESPONSE
;    to write the true_flux structure using CHIANTI vers 7.1 in 2013
;  IDL> help, {goes_true_flux}
;  % Compiled module: GOES_TRUE_FLUX__DEFINE.
;  ** Structure GOES_TRUE_FLUX, 11 tags, length=2096, data length=2090:
;  DATE            STRING    ''
;  VERSION         STRING    ''
;  METHOD          STRING    ''
;  SAT             INT              0
;  ALOG10EM        FLOAT          0.000000
;  TEMP_PROD       STRING    ''
;  TEMP_MK         FLOAT     Array[101]
;  FLONG_PHO       FLOAT     Array[101]
;  FSHORT_PHO      FLOAT     Array[101]
;  FLONG_COR       FLOAT     Array[101]
;  FSHORT_COR      FLOAT     Array[101]
;
; :Author: 05-Jul-2020, rschwartz70@gmail.com
;-
function goes_write_true_flux_7p1

  
  true_flux =  goes_true_flux()
  true_flux.temp_mk = goes_resp_mk_temp( temp_coef_input = true_flux )
  true_flux.version = '7.1'
  true_flux.date = '27-feb-2013'
  true_flux.method  ='make_goes_chianti_resp'
  
  true_flux = replicate( true_flux, 15 )
  true_flux.sat = indgen(15)+1

  for ipho = 0, 1 do begin
    long = transpose( goes_long_chianti(photospheric = ipho))
    short = long * transpose( goes_shortlong_ratio_chianti(photospheric = ipho))
    if ipho eq 0 then begin
      true_flux.flong_cor = long
      true_flux.fshort_cor = short
    endif else begin
      true_flux.flong_pho = long
      true_flux.fshort_pho = short

    endelse
  endfor
  return, true_flux
end