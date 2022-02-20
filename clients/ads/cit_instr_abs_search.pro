
FUNCTION cit_instr_abs_search, year, abs_search_string, preprints=preprints, $
                               database_all=database_all

;+
; NAME:
;     CIT_INSTR_ABS_SEARCH
;
; PURPOSE:
;     Performs an abstract search for publications in ADS for a
;     specific year.
;
; CATEGORY:
;     Citations; ADS; search.
;
; CALLING SEQUENCE:
;     Result = CIT_INSTR_ABS_SEARCH( Year, Abs_Search_String )
;
; INPUTS:
;     Year:  The year for which the search should be performed. Can be
;            an integer or string.
;     Abs_Search_String: A string giving the ADS search term. See
;                        below for examples.
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
;     A list of bibcodes satsifying the search criteria. If there are
;     no results or a problem is found then an empty string is
;     returned.
;
; RESTRICTIONS:
;     I'm only searching the astronomy database.
;
; EXAMPLE:
;     IDL> abs_search_string='abs:"Hubble Space Telescope"'
;     IDL> bcodes=cit_instr_abs_search(2019,abs_search_string)
;
;     IDL> abs_search_string='abs:(("EUV Imaging Spectrometer") or ("EIS" and "Hinode"))'
;     IDL> bcodes=cit_instr_abs_search(2018,abs_search_string)
;
; MODIFICATION HISTORY:
;     Ver.1, 2-Oct-2019, Peter Young
;     Ver.2, 14-Jan-2020, Peter Young
;        Added /database_all and /preprints keywords and modified
;        default behavior to return all papers except preprints. 
;-

IF n_params() LT 2 THEN BEGIN
  print,'Use:  IDL> bcodes=cit_instr_abs_search( year, abs_search_string )'
  return,''
ENDIF 


year_str=trim(year)

url='https://api.adsabs.harvard.edu/v1/search/query'

;
; Add the year to the query, and make sure only refereed articles are
; returned. 
;
query_string='pubdate:'+year_str

;
; Now add ABS_SEARCH_STRING. This string is of the form:
;   'abs:(("Interface Region Imaging Spectrograph"))'
; Note that Boolean operators can be used to create a more complex
; search. For example:
;   'abs:(("Interface Region Imaging Spectrograph") or ("IRIS" and "solar"))'
;
query_string=query_string+' AND '+abs_search_string


;
; It's important to replace : and " otherwise the query won't work.
;
query_string=str_replace(query_string,':','%3A')
query_string=str_replace(query_string,'"','%22')


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


;
; Set the output to be bibcodes only, restrict to at most 500 entries,
; and only search in the astronomy database. Note that since
; we're only searching for a specific year, then 500 should
; never be reached. 
;
IF NOT keyword_set(database_all) THEN extra_text='&fq=database:astronomy' ELSE extra_text=''
chck_str=query_string+'&rows='+trim(500)+'&fl=bibcode,doctype'+extra_text
input_url=url+'?q='+chck_str


sock_list,input_url,json,headers=headers
;
; Sometimes the call fails, so I try again and if this fails exit the routine.
IF json[0] EQ '' THEN BEGIN
  sock_list,input_url,json,headers=headers
  IF json[0] EQ '' THEN BEGIN
      print,'%CIT_GET_ADS_ENTRY: the call to the API failed. Please try again or check your inputs. Returning...'
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
  doctype=strarr(ns)
  bibcode=strarr(ns)
  FOR i=0,ns-1 DO BEGIN
    doctype[i]=s_list[i].doctype
    bibcode[i]=s_list[i].bibcode
  ENDFOR 
ENDELSE 

;
; Remove non-paper entries. 
;
k=where(doctype NE 'abstract' AND doctype NE 'catalog'  AND doctype NE 'pressrelease' AND doctype NE '',nk)
IF nk NE 0 THEN BEGIN
  bibcode=bibcode[k]
  doctype=doctype[k]
ENDIF ELSE BEGIN
  bibcode=''
ENDELSE 

;
; I get rid of preprints here, unless /preprintsl is set.
;
IF NOT keyword_set(preprints) AND bibcode[0] NE '' THEN BEGIN
  k=where(doctype NE 'eprint',nk)
  IF nk NE 0 THEN bibcode=bibcode[k] ELSE bibcode=''
ENDIF 
return,bibcode


END
