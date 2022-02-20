
FUNCTION cit_get_citing_papers, bibcode, year=year, database_all=database_all, $
                                preprints=preprints

;+
; NAME:
;     CIT_GET_CITING_PAPERS
;
; PURPOSE:
;     Return a list of bibcodes that are papers that cite the paper
;     specified by BIBCODE.
;
; CATEGORY:
;     ADS; citations.
;
; CALLING SEQUENCE:
;     Result = CIT_GET_CITING_PAPERS( Bibcode )
;
; INPUTS:
;     Bibcode:  An ADS bibcode (must be a string scalar).
;
; OPTIONAL INPUTS:
;     Year:  A string or integer specifying a year. If given, then
;            only the papers corresponding to this year will be
;            returned.
;
; KEYWORD PARAMETERS:
;     PREPRINTS: By default the routine does not return preprints
;            (doctype='eprint'). This keyword adds preprints to the
;            output. 
;     DATABASE_ALL: By default the routine only searches the astronomy
;            database at ADS. Setting this keyword removes this
;            restriction. 
;
; OUTPUTS:
;     If the input paper has N citations, then a string array of N
;     elements is returned containing the bibcodes of the citing
;     papers. The YEAR optional input can filter the output to only
;     include bibcodes from the specified year.
;
;     If a problem occurs or there are no citing papers, then an empty
;     string is returned.
;
; EXAMPLES:
;     IDL> output=cit_get_citing_papers('2007SoPh..243...19C')
;     IDL> output=cit_get_citing_papers('2007SoPh..243...19C',year=2010)
;
; MODIFICATION HISTORY:
;     Ver.1, 02-Oct-2019, Peter Young
;     Ver.2, 14-Jan-2020, Peter Young
;        Added /database_all and /preprints keywords; removed
;        /refereed keyword.
;-


IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> output=cit_get_citing_papers( bibcode [, year=, /preprints, /database_all ] )'
  return,''
ENDIF 

;
; Get ADS API dev_key
;
ads_key=cit_get_ads_key(status=status,/quiet)
IF status EQ 0 THEN BEGIN
  print,'***The ADS key was not found!  Returning...***'
  return,''
ENDIF 
headers=['Authorization: Bearer '+ads_key, $
         'Content-Type: application/json']


bcode=bibcode.replace('&','%26')

;
; Get the number of citations from ADS for bcode.
;
a=cit_get_ads_entry(bcode)
ncit=a.citation_count
IF ncit EQ 0 THEN return,''

;
; Create the ADS query. Note that I'm returning bibcode and
; year for each entry.
;
url='https://api.adsabs.harvard.edu/v1/search/query'
query_string='citations(bibcode:'+bcode+')'
;IF keyword_set(refereed) THEN query_string=query_string+' AND property:refereed'
IF NOT keyword_set(database_all) THEN extra_text='&fq=database:astronomy' ELSE extra_text=''
query_string=query_string+'&rows='+trim(ncit)+'&fl=bibcode,year,doctype'+extra_text



;
; It's important to replace : and " otherwise the query won't work.
;
query_string=str_replace(query_string,':','%3A')
query_string=str_replace(query_string,'"','%22')

input_url=url+'?q='+query_string

;
; Send query and parse results.
;
sock_list,input_url,json,headers=headers
;
; Sometimes the call fails, so I try again and if this fails exit the routine.
IF json[0] EQ '' THEN BEGIN
  sock_list,input_url,json,headers=headers
  IF json[0] EQ '' THEN BEGIN
      print,'%CIT_GET_CITING_PAPERS: the call to the API failed. Please try again or check your inputs. Returning...'
      return,''
    ENDIF 
ENDIF
;
s=json_parse(json,/tostruct)
s_list=s.response.docs
ns=s_list.count()
IF ns EQ 0 THEN BEGIN
  return,''
ENDIF ELSE BEGIN
  yr=strarr(ns)
  bibcode=strarr(ns)
  doctype=strarr(ns)
  FOR i=0,ns-1 DO BEGIN
    yr[i]=s_list[i].year
    bibcode[i]=s_list[i].bibcode
    doctype[i]=s_list[i].doctype
  ENDFOR 
ENDELSE 


;
; Now filter on year (if necessary).
;
IF n_elements(year) NE 0 THEN BEGIN
  k=where(yr EQ trim(year),nk)
  IF nk NE 0 THEN BEGIN
    bibcode=bibcode[k]
    doctype=doctype[k]
  ENDIF ELSE BEGIN
    bibcode=''
  ENDELSE 
ENDIF
IF bibcode[0] EQ '' THEN return,bibcode


;
; Filter out abstracts and catalogs.
;
k=where(doctype NE 'abstract' AND doctype NE 'catalog' AND doctype NE 'pressrelease' AND doctype NE '',nk)
IF nk NE 0 THEN BEGIN
  bibcode=bibcode[k]
  doctype=doctype[k]
ENDIF ELSE BEGIN
  bibcode=''
ENDELSE 
IF bibcode[0] EQ '' THEN return,bibcode

;
; I get rid of preprints here, unless /preprints is set.
;
IF NOT keyword_set(preprints) THEN BEGIN
  k=where(doctype NE 'eprint',nk)
  IF nk NE 0 THEN bibcode=bibcode[k] ELSE bibcode=''
ENDIF 
return,bibcode

return,output

END
