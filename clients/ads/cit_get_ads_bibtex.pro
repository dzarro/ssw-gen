
FUNCTION cit_get_ads_bibtex, bibcode, json=json, endnote=endnote, aastex=aastex, $
                             url=url, content=content

;+
; NAME:
;      CIT_GET_ADS_BIBTEX()
;
; PURPOSE:
;      This routine returns a string from ADS containing the BibTex
;      entry for the paper.
;
; CATEGORY:
;      ADS; citations; bibliography.
;
; CALLING SEQUENCE:
;      Result = CIT_GET_ADS_BIBTEX( Bibcode )
;
; INPUTS:
;      Bibcode:   A string or string array containing one or more
;                 bibcode IDs. 
;
; OPTIONAL OUTPUTS:
;      Json:      This is a string containing the JSON format output
;                 from the call to ADS.
;
; KEYWORD PARAMETERS:
;      ENDNOTE:  If set, then the output is returned in endnote
;                format.
;      AASTEX:   If set, then the output is returned in aastex
;                format. 
;
; OUTPUTS:
;      If successful, then the result is a string array containing the
;      bibtex information for the article(s). Otherwise the value -1 is
;      returned. For multiple bibcodes, the string arrays for each
;      bibcode are simply concatenated. If a problem is found, then an
;      empty string is returned.
;
; EXAMPLES:
;      IDL> bib=cit_get_ads_bibtex('2015ApJ...799..218Y')
;      IDL> bib=cit_get_ads_bibtex(['2015ApJ...799..218Y','2009SSRv..149..229T'])
;
; MODIFICATION HISTORY:
;      Ver.1, 24-Nov-2015, Peter Young
;      Ver.2, 12-Oct-2015, Peter Young
;        Expanded header.
;      Ver.3, 12-Oct-2016, Peter Young
;        Added /endnote and /aastex keywords to see what output looks
;        like; now searches for ADS key.
;      Ver.4, 14-Oct-2016, Peter Young
;        Now accepts an array of bibcodes. However, something seems to
;        go wrong  when a lot of bibcodes (>21) are given and then
;        way more bibtex entries are returned than were asked for.
;      Ver.5, 17-Oct-2016, Peter Young
;        There was a bug in str_replace that caused the 21 problem
;        above. I've now switched to using the new replace method.
;      Ver.6, 6-Jul-2017, Peter Young
;        Caught error if query fails (e.g., '2016A&A...596A..15A').
;      Ver.7, 21-Jul-2017, Peter Young
;        No longer replace & with %26; removed square brackets
;        if there's only bibcode.
;      Ver.8, 23-Jul-2017, Peter Young
;        Now check if the sock_post call fails, and then try
;        again. (I'm finding the call sometimes fails.)
;      Ver.9, 11-Apr-2018, Peter Young
;        Added square brackets for the single bibcode query to fix a
;        new error.
;-


IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> bib=cit_get_ads_bibtex( bibcode [, json=])'
  return,''
ENDIF 

;
; 21-Jul-2017
; It seems there's no need to replace & anymore (in fact it
; causes a crash), so I've removed this now.
;
;bcode=bibcode.replace('&','%26')
bcode=bibcode

;
; Get ADS API dev_key
;
ads_key=cit_get_ads_key(status=status,/quiet)
IF status EQ 0 THEN BEGIN
  print,'%CIT_GET_ADS_BIBTEX: the ADS key was not found. Returning...'
  return,''
ENDIF 
headers=['Authorization: Bearer '+ads_key, $
         'Content-Type: application/json']

;
; Create the bibcode string that goes to the query.
; 11-Apr-2018: I added square brackets for the single bibcode as it
; crashed otherwise.
;
nb=n_elements(bcode)
bstr='"'+bcode[0]+'"'
IF nb GT 1 THEN BEGIN
  FOR i=1,nb-1 DO BEGIN
    bstr=bstr+',"'+bcode[i]+'"'
  ENDFOR 
  content='{"bibcode":['+bstr+']}'
ENDIF ELSE BEGIN
  content='{"bibcode":['+bstr+']}'
ENDELSE


output_format='bibtex'
IF keyword_set(endnote) THEN output_format='endnote'
IF keyword_set(aastex) THEN output_format='aastex'


url='https://api.adsabs.harvard.edu/v1/export/'+output_format

json = sock_post(url,content,headers=headers)

;
; This is in case the first post fails. I try again, and if this
; fails then I gracefully exit.
;
IF json[0] EQ '' THEN BEGIN
  help,json
  json = sock_post(url,content,headers=headers)
  IF json[0] EQ '' THEN BEGIN
    help,json
    print,'%CIT_GET_ADS_BIBTEX: the ADS query failed. Please try again or check your inputs. Returning...'
    return,''
  ENDIF
ENDIF

s=json_parse(json,/tostruct)

IF tag_exist(s,'export') THEN  BEGIN 
  s=s.export
 ;
 ; The output 's' is a single string, but it contains 'line feeds' that
 ; separate lines. So below, I used the line feeds to create a string
 ; array. 
 ;
  bits=str_sep(s,string(10b))
  k=where(trim(bits) NE '')
 ;
  output=bits[k]
ENDIF ELSE BEGIN
  IF tag_exist(s,'error') THEN print,'%CIT_GET_ADS_BIBTEX: '+s.error
  output=''
ENDELSE 

return,output


END
