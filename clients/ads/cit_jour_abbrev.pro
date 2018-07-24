

FUNCTION cit_jour_abbrev, input

;+
; NAME:
;      CIT_JOUR_ABBREV
;
; CATEGORY:
;      ADS; citations; bibtex.
;
; PURPOSE:
;      The new ADS service gives the full journal name, so this
;      routine replaces this with the standard abbreviation for
;      selected articles.
;
; INPUTS:
;      Input:   A string giving the name of a journal.
;
; OUTPUTS:
;      If available, the journal abbreviation is returned. Otherwise
;      INPUT is returned.
;
; EXAMPLES:
;      IDL> print,cit_jour_abbrev('The Astrophysical Journal')
;          ApJ
;
; MODIFICATION HISTORY:
;      Ver.1, 2-Nov-2016, Peter Young
;      Ver.2, 25-Apr-2017, Peter Young
;         Added 3 journals.
;-

IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> output=cit_jour_abbrev(input)'
  return,''
ENDIF 

CASE strlowcase(input) OF
  'the astrophysical journal': output='ApJ'
  'the astrophysical journal supplement series': output='ApJS'
  'astronomy and astrophysics': output='A&A'
  'monthly notices of the royal astronomical society': output='MNRAS'
  'journal of quantitative spectroscopy and radiative transfer': output='JQSRT'
  ELSE: output=input
ENDCASE

return,output

END
