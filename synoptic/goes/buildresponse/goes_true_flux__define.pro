;+
; :Description:
;    GOES_TRUE_FLUX structure definition
;    To create a container for the GOES computed responses
;    
;   Temp_mk - temperatute in MegaKelvin
;   Fluxes are all in Watts/M^2
;   pho == grevesse photospheric abundance
;   cor == Feldman coronal abundance
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
;
;
;
; :Author: Richard Schwartz, rschwartz70@gmail.com
; Derived from make_goes_chianti_response developed by White, Schwartz, Thomas circa 2005
; 3-July-2020
;-
pro goes_true_flux__define

  dummy = {goes_true_flux, $
    date: '', $ Date computed
    version: '', $ ;Chianti version
    method: '', $ Wavelength using goes_chianti_response or keV using goes_resp_kev
    ;Prior to Version 9.0.1 in July 2020 used make_goes_chianti_response
    sat: 0, $
    secondary: 0b, $
    alog10em: 0.0, $ ;value of EM in cm-3 used for fluxes at each temp_mk
    temp_coef: fltarr(2), $
    temp_mk: fltarr(101), $
    flong_pho: fltarr(101), $ 
    fshort_pho: fltarr(101), $
    flong_cor: fltarr(101), $
    fshort_cor: fltarr(101) }

end