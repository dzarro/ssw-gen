;+
; Project     :	SOHO - CDS
;
; Name        :	LONGHEX()
;
; Purpose     :	Converts an array of short int values into a fixed hex string format.
;
; Explanation :	Converts an array of short integer values into a single string of
;               values in 0xnnnnnnnn format separated by spaces.
;               NB On some machines INTs are 64 bit so z8.8 does not work.
;
; Use         : <str = longhex(array)>
;
; Inputs      : array = long integer array.
;
; Opt. Inputs : None.
;
; Outputs     : Character string containing hex values.
;
; Opt. Outputs:	None.
;
; Keywords    : None.
;
; Calls       :	None.
;                
; Common      :	None.
;
; Restrictions:	There is a limit on how large a formatted string can be of 1024 lines.
;
; Side effects:	None.
;
; Category    :	Command preparation.
;
; Prev. Hist. :	Adapted from shorthex.
;
; Written     :	Version 0.00, Martin Carter, RAL, 9/1/96
;
; Modified    :	None
;
; Version     :	Version 0.0, 9/1/96
;
;**********************************************************

FUNCTION longhex, array

  ; get array of hex strings truncated from the right 

  str = STRING ( FORMAT='(Z0)', array)

  ; get length of each string

  lstr = STRLEN(str)

  ; place hex strings into format '0x00000000'

  output_str = ''

  FOR k = 0, N_ELEMENTS(str)-1 DO BEGIN
    
    ostr = ' 0x00000000'

    ; only use bottom 8 nibbles of string
    ; so deal correctly with -ve numbers

    IF lstr(k) LE 8 THEN $
      STRPUT, ostr, str(k), 11-lstr(k) $
    ELSE $
      STRPUT, ostr, STRMID(str(k),lstr(k)-8,8), 3

    output_str = output_str + ostr

  ENDFOR

  ; chop off leading blank

  RETURN, STRMID ( output_str, 1, STRLEN(output_str)-1 )

END
