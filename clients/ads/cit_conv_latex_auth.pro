
FUNCTION cit_conv_latex_auth, in_string

;+
; NAME:
;	CIT_CONV_LATEX_AUTH
;
; PURPOSE:
;       Converts a bibtex format author string to something that can
;       be recognised in html.
;
; CATEGORY:
;	ADS; citations; html.
;
; CALLING SEQUENCE:
;	Result = CIT_CONV_LATEX_AUTH( In_String )
;
; INPUTS:
;       In_String: An input string containing a Bibtex format author
;                  list. 
;
; OUTPUTS:
;       A string containing the list of authors in html format
;       (including special characters).
;
; EXAMPLE:
;       IDL> bib=cit_get_ads_bibtex('2008ApJ...689L..77B')
;       IDL> auth=cit_conv_latex_auth(bib[1])
;
; MODIFICATION HISTORY:
;       Ver.1, 23-Jul-2017, Peter Young
;       Ver.2, 10-Sep-2019, Peter Young
;         Fixed problem when checking for "author = {". 
;-


IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> auth=cit_conv_latex_auth( in_string )'
  return,''
ENDIF 

outstring=''

astr=trim(in_string)

;
; The string should have had "author = {" removed before it has been
; input, but the following removes it, just in case. 
; 
chck=strpos(astr,'author = {')
IF chck GE 0 THEN BEGIN 
  astr=str_replace(astr,'author = {')
 ;
 ; Remove the end bracket.
 ;
  n=strlen(astr)
  astr=strmid(astr,0,n-2)
ENDIF 


bits=str_sep(astr,' and ')
n=n_elements(bits)

FOR i=0,n-1 DO BEGIN
  author=repstr(bits[i],'{','')
  author=repstr(author,'}','')
  author=cit_convert_latex(author)
  IF n EQ 1 THEN outstring=author
  CASE 1 OF 
    n EQ 1: outstring=author
    i EQ n-2: outstring=outstring+author+' & '
    i EQ n-1: outstring=outstring+author
    ELSE: outstring=outstring+author+', '
  ENDCASE
ENDFOR

return,outstring

END
