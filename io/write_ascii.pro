
FUNCTION write_ascii, file, array, error=error,update=update
;+
; PROJECT:
;       SOHO - CDS/SUMER
;
; NAME:
;       WRITE_ASCII()
;
; PURPOSE: 
;       Write a given string array as an ASCII file
;
; CATEGORY:
;       Utility
; 
; SYNTAX: 
;       Result = write_ascii(file, array)
;
; INPUTS:
;       FILE - String scalar, name of the file to be written
;       ARRAY - String array to be writtten out
;
; KEYWORDS: 
;       ERROR - String scalar containing error message; if no error occurs,
;               the null string is returned
;       UPDATE - update file if it exists
;
; HISTORY:
;       Version 1, September 23, 1996, Liyun Wang, NASA/GSFC. Written
;       28-Jul-2020, Zarro (ADNET) - added UPDATE keyword.
;
; CONTACT:
;       Liyun Wang, NASA/GSFC (Liyun.Wang.1@gsfc.nasa.gov)
;-
;
   ON_ERROR, 2
   IF N_PARAMS() NE 2 THEN BEGIN
      error = 'Syntax: a = write_ascii(file_name, str_array)'
      MESSAGE, error, /cont
      RETURN, 0
   ENDIF
   
   ON_IOERROR, wrong

;   if keyword_set(update) then openu, unit,file,/get_lun,/append else OPENW, unit, file, /GET_LUN
   OPENW, unit, file, /GET_LUN,append=keyword_set(update)

   FOR i=0, N_ELEMENTS(array)-1 DO BEGIN
      PRINTF, unit, array(i)
   ENDFOR
   FREE_LUN, unit
   RETURN, 1
   
wrong:
   error = !err_string
   MESSAGE, error, /cont

   RETURN, 0
END


;---------------------------------------------------------------------------
; End of 'WRITE_ASCII.PRO'.
;---------------------------------------------------------------------------
