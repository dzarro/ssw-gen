
FUNCTION cit_process_bibtex, input

;+
; NAME:
;      CIT_PROCESS_BIBTEX
;
; PURPOSE:
;      Certain information for conference proceedings is not returned
;      by the ADS API, but it can be accessed from the Bibtex entry
;      for the article. This routine takes the Bibtex string (obtained
;      by cit_get_ads_bibtex.pro, for example) and extracts
;      the information into a structure.
;
; CATEGORY:
;      ADS; Bibtex.
;
; CALLING SEQUENCE:
;      Result = CIT_PROCESS_BIBTEX( Input )
;
; INPUTS:
;      Input:  A string array containing the Bibtex text. See the
;              routine cit_get_ads_bibtex.pro.
;
; OUTPUTS:
;      A structure containing the following tags:
;        .school
;        .editor
;        .booktitle
;        .series
;     These are all strings, containing the corresponding entries
;     from the Bibtex string.
;
; EXAMPLE:
;     IDL> bib=cit_get_ads_bibtex('2016SoPh..291...29Y')
;     IDL> s=cit_process_bibtex(bib)
;
; MODIFICATION HISTORY:
;     Ver.1, 6-Jul-2017, Peter Young
;     Ver.2, 9-Jul-2017, Peter Young
;       added 'series' to output
;     Ver.3, 12-Jul-2017, Peter Young
;       added 'id' to output
;     Ver.4, 23-Jul-2017, Peter Young
;       replaced cit_process_bibtex_author call to
;       cit_conv_latex_auth.
;     Ver.5, 6-Sep-2019, Peter Young
;       now calls cit_conv_latex_jnl for "booktitle".
;-



search_string=['school','editor','booktitle','series','id']
ns=n_elements(search_string)
entry=strarr(ns)

ni=n_elements(input)


FOR i=0,ns-1 DO BEGIN
  chck=strpos(input,search_string[i]+' =')
  k=where(chck GE 0,nk)
  CASE nk OF
    1: BEGIN
      bits=str_sep(input[k[0]],'=')
      entry[i]=trim(bits[1])
      swtch=0
      j=1
      WHILE swtch EQ 0 DO BEGIN 
        n_open=cit_num_str_match(entry[i],'{')
        n_close=cit_num_str_match(entry[i],'}')
        IF n_open EQ n_close THEN BEGIN
          swtch=1
        ENDIF ELSE BEGIN
          entry[i]=entry[i]+' '+trim(input[k[0]+j])
          j=j+1
        ENDELSE 
      ENDWHILE
     ;
     ; Deals with any funny characters in people's names.
     ;
      IF search_string[i] EQ 'editor' THEN BEGIN
        entry[i]=cit_conv_latex_auth(entry[i])
      ENDIF ELSE BEGIN
        entry[i]=entry[i].replace('{','')
        entry[i]=entry[i].replace('},','')
      ENDELSE 
     ;
     ; I introduced this to deal \procspie entries.
     ;
      IF search_string[i] EQ 'booktitle' THEN entry[i]=cit_conv_latex_jnl(entry[i])
    END
    0:
    ELSE: BEGIN
      print,'%CIT_PROCESS_BIBTEX: the bibtex string contains more than one entry for '+search_string[i]
    END
  ENDCASE 
ENDFOR

output={ school: entry[0], $
         editor: entry[1], $
         booktitle: entry[2], $
         series: entry[3], $
         id: entry[4]}

return,output

END
