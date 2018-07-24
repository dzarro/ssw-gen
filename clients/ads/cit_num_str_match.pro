

FUNCTION cit_num_str_match, input_string, search_string

;+
; NAME:
;      CIT_NUM_STR_MATCH
;
; PURPOSE:
;      This very simple routine routines the number of instances that
;      a substring (search_string) occurs within a string
;      (input_string). 
;
; CATEGORY:
;      Strings.
;
; CALLING SEQUENCE:
;      Result = CIT_NUM_STR_MATCH( Input_String, Search_String )
;
; INPUTS:
;      Input_String:  A string.
;      Search_String: A string to be searched for in Input_String.
;
; OUTPUTS:
;      A integer containing the number of instances of Search_String
;      within Input_String.
;
; EXAMPLE:
;      IDL> print,cit_num_str_match('Hello','l')
;                2
;
; MODIFICATION HISTORY:
;      Ver.1, 19-Oct-2016, Peter Young
;-

n=strlen(search_string)

swtch=0
str1=input_string
count=0
WHILE swtch EQ 0 DO BEGIN
  chck=strpos(str1,search_string)
  IF chck LT 0 THEN BEGIN
    swtch=1
  ENDIF ELSE BEGIN
    count=count+1
    str1=strmid(str1,chck+n)
  ENDELSE 
ENDWHILE 


return,count

END
