
FUNCTION cit_json_check, json

;+
; NAME:
;     CIT_JSON_CHECK
;
; PURPOSE:
;     This checks the result of a SOCK_POST call to see if there is a
;     problem with it. 
;
; CATEGORY:
;     Sockets.
;
; CALLING SEQUENCE:
;     Result = CIT_JSON_CHECK( Json )
;
; INPUTS:
;     Json:   The output string for a call to SOCK_POST.
;
; OUTPUTS:
;     An integer with the value:
;       0 - input is OK
;       1 - post failed (empty output)
;       2 - 'bad gateway' problem.
;       3 - 'internal server error'
;
; MODIFICATION HISTORY:
;     Ver.1, 5-Sep-2019, Peter Young
;     Ver.2, 16-Sep-2019, Peter Young
;       added internal server error check
;-


status=0
IF json[0] EQ '' THEN status=1
IF n_elements(json) GE 2 THEN BEGIN
  chck=strpos(json[1],'Bad Gateway')
  IF chck GE 0 THEN status=2
  chck=strpos(json[1],'Internal Server Error')
  IF chck GE 0 THEN status=3
ENDIF

return,status

END
