;+
; Project:
;     SDAC
; Name:
;     GOES_GET_CHIANTI_VERSION
;
; Usage:
;     print, goes_get_chianti_version()
;
;Purpose:
;     Return chianti version used in goes_get_chianti_temp and goes_get_chianti_em
;
;Category:
;     GOES, SPECTRA
;Keywords:
;     Set_New - set the environment variable, GOES_CHIANTI_NEW_TABLE, to force the new response tables
;     Set_Old - set the environment variable to force the old response method from White 
;     new_table - output, returns the value of the environment variable as an integer
;Method:
;     Anyone who updates goes_get_chianti_temp and goes_get_chianti_em to use a newer
;     version of chianti should modify this appropriately.

; MODIFICATION HISTORY:
;     Kim Tolbert, 13-Dec-2005
;     Kim, 30-Nov-2006.  Changed to 5.2 after onlining new tables from S. White
;     Kim, 02-Dec-2009.  Changed to 6.0.1 after onlining new tables from S. White
;	  7-jun-2012, richard.schwartz@nasa.gov - read the value from goes_get_chianti_temp.pro
;	  10-Sep-2012, Kim. Call chkarg with /quiet
;	  11-aug-2020, rschwartz70@gmail.com, integrate new method to get chianti version used to
;	  make the NEW_TABLE
;
;-
;-------------------------------------------------------------------------

function goes_get_chianti_version, set_new = set_new, set_old = set_old, new_table = new_table

  ;temporary fix for transition to new_table from chianti version 9.0.1
  ;permanent once we disable older table or change reference methodology for old table
  default, set_new, 0
  default, set_old, 0
  if set_new then setenv,'GOES_CHIANTI_NEW_TABLE=1'
  if set_old then setenv,'GOES_CHIANTI_NEW_TABLE=0'
  new_table = getenv('GOES_CHIANTI_NEW_TABLE')
  case 1 of
    new_table eq '': begin
       setenv,'GOES_CHIANTI_NEW_TABLE=1'
       new_table = 1
       end
    else: new_table = fix(getenv('GOES_CHIANTI_NEW_TABLE'))
    endcase
  if new_table then begin
    goes_chianti_resp_new_table_set, aa

    return, aa[15].version

  endif

  chkarg,'goes_get_chianti_temp',proc,loc,/quiet
  line = proc[where(stregex(proc[0:99],/boo,/fold,'This routine .* using chianti version'))]
  version = ssw_strsplit( line,/tail, 'version ')
  return, version

end