;+
; :Description:
;    GOES_TRUE_FLUX structure defaults
;    To create a container for the GOES computed responses
;    This function fills in some likely defaults
;
;   Temp_mk - temperatute in MegaKelvin
;   Fluxes are all in Watts/M^2
;   pho == grevesse photospheric abundance
;   cor == Feldman coronal abundance
;
; :Keywords:
;    version - CHIANTI version used
;    method  - string 'goes_resp_kev' or 'goes_chianti_response' - procedure used
;    date    - date response was computed
;    temp_coef - parameters used to generate temperatures for table
;
;
;
; :Author: Richard Schwartz, rschwartz70@gmail.com
; Derived from make_goes_chianti_response developed by White, Schwartz, Thomas circa 2005
; 3-July-2020
;-
function goes_true_flux, version = version, method = method, date = date, temp_coef = temp_coef
  chianti_version, current
  default, version, current
  default, date, anytim(/yoh,/date,fid='sys',systime(/sec))
  default, method, 'goes_resp_kev'
  default, temp_coef, [10.0, 0.02]
  gtf = {goes_true_flux}
  gtf.version = version
  gtf.date = date
  gtf.method = method
  gtf.temp_coef = temp_coef
  gtf.alog10em = 55.0
  gtf.temp_mk = goes_resp_mk_temp( findgen(101), temp_coef = temp_coef )
  return, gtf
end