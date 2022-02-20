;+
; :Description:
;    This procedures sets and retrieves the response tables for all of the
;    GOES XRS satellites and detectors. The tables are computed using
;    goes_chianti_response and stored in goes_chianti_resp.fits
;    found in the ssw/gen/idl/synoptic/goes directory. The tables are loaded
;    into common goes_chianti_resp_com for rapid access
;
; :Params:
;    aa - response table see below
;    IDL> help, aa
;    AA              STRUCT    = -> GOES_TRUE_FLUX Array[17]
;    IDL> help, aa,/st
;    ** Structure GOES_TRUE_FLUX, 11 tags, length=2088, data length=2082:
;    DATE            STRING    '10-Jul-20'
;    VERSION         STRING    '9.0.1'
;    METHOD          STRING    'goes_chianti_response'
;    SAT             INT              0
;    ALOG10EM        FLOAT           55.0000
;    TEMP_COEF       FLOAT     Array[2]
;    TEMP_MK         FLOAT     Array[101]
;    FLONG_PHO       FLOAT     Array[101]
;    FSHORT_PHO      FLOAT     Array[101]
;    FLONG_COR       FLOAT     Array[101]
;    FSHORT_COR      FLOAT     Array[101]
;
;
;
; :Author: rschwartz70@gmail.com, 22-jul-2020
; :History: RAS, added path2 for testing, normally not there
;-
pro goes_chianti_resp_new_table_set, aa_out
  common goes_chianti_resp_com, aa, slr
  ;    IDL> help, aa
  ;    AA              STRUCT    = -> GOES_TRUE_FLUX Array[17]
  ;    IDL> help, aa,/st
  ;    ** Structure GOES_TRUE_FLUX, 11 tags, length=2088, data length=2082:
  ;    DATE            STRING    '10-Jul-20'
  ;    VERSION         STRING    '9.0.1'
  ;    METHOD          STRING    'goes_chianti_response'
  ;    SAT             INT              0
  ;    ALOG10EM        FLOAT           55.0000
  ;    TEMP_COEF       FLOAT     Array[2]
  ;    TEMP_MK         FLOAT     Array[101]
  ;    FLONG_PHO       FLOAT     Array[101]
  ;    FSHORT_PHO      FLOAT     Array[101]
  ;    FLONG_COR       FLOAT     Array[101]
  ;    FSHORT_COR      FLOAT     Array[101]
  ;
  ;Check to see if the precomputed response tables have been loaded
  ;If not load the data file and compute the ratio table, SLR SHORT LONG RATIO
  if ~is_struct( aa ) then begin
    resp_file_name = 'goes_chianti_resp_20200812.fits'
    path = concat_dir( getenv('SSW'),'gen/idl/synoptic/goes')
    filnam = file_search( concat_dir( getenv('SSW'),'gen/idl/atest'), resp_file_name, count = nfil)
    if nfil eq 0 then filnam = loc_file( path=['.',path], resp_file_name, count = nfil)
    if nfil ge 1 then aa = mrdfits(filnam[0], 1)
    rcor = f_div( aa.fshort_cor, aa.flong_cor)
    rpho = f_div( aa.fshort_pho, aa.flong_pho)
    slr = reproduce( rcor, 2)
    slr[0,0,1] = rpho
  endif
  aa_out = aa
end