
FUNCTION cit_author_papers, name, start_year=start_year, END_year=end_year, all=all


;+
; NAME:
;     CIT_AUTHOR_PAPERS
;
; PURPOSE:
;     Retrieve a list of bibcodes from the ADS for the specified
;     author. Only the Astronomy database is searched, unless /ALL is
;     set. 
;
; CATEGORY:
;     ADS; citations.
;
; CALLING SEQUENCE:
;     Result = CIT_AUTHOR_PAPERS( Name )
;
; INPUTS:
;     Name:   The author's name, given in the format "Young,
;             Peter R.", i.e., "SURNAME, First
;             Middle-Initials". Can also give "Young, P." or
;             just "Young". Can be an array of names, in which case
;             the output will included the bibcodes for each of the
;             names. 
;
; OPTIONAL INPUTS:
;     Start_Year:  The start year for the search. If not specified
;                  then 1900 is used.
;     End_Year:  The end year for the search. If not specified then
;                the current year is used.
;
; KEYWORD PARAMETERS:
;     ALL:  If set, then all ADS databases are searched (not just
;           astronomy). 
;	
; OUTPUTS:
;     A string array containing a list of ADS bibcodes that satisfy
;     the search criteria. 
;
; EXAMPLE:
;     IDL> bcodes=cit_author_papers('Young, Peter R.',start=1994)
;     IDL> cit_author_html,bcodes,html_file='young.html',name='Dr. Peter R. Young'
;
; MODIFICATION HISTORY:
;     Ver.1, 2-Oct-2019, Peter Young
;     Ver.2, 8-Nov-2019, Peter Young
;       NAME is allowed to be an array now; added /ALL keyword.
;-


IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> bcodes=cit_author_papers( "Surname, First M.I." [, start_year=, end_year=, /all ])'
  return,''
ENDIF 

IF n_elements(start_year) EQ 0 THEN start_year=1900
IF n_elements(end_year) EQ 0 THEN BEGIN
  t=systime(/julian,/utc)
  caldat,t,m,d,y
  END_year=y
ENDIF


url='https://api.adsabs.harvard.edu/v1/search/query'

;
; Create the query string.
;
nauth=n_elements(name)
query_string='( author:("'+name[0]+'")'
IF nauth GT 1 THEN BEGIN 
  FOR i=1,nauth-1 DO BEGIN
    query_string=query_string+' OR author:("'+name[i]+'")'
  ENDFOR
ENDIF 
query_string=query_string+') AND pubdate:['+trim(start_year)+'-01 TO '+trim(end_year)+'-12]'


;
; It's important to replace special characters with codes.
;
query_string=str_replace(query_string,':','%3A')
query_string=str_replace(query_string,'"','%22')
query_string=str_replace(query_string,',','%2C')
query_string=str_replace(query_string,'[','%5B')
query_string=str_replace(query_string,']','%5D')

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
; I'm restricting to 1000 results and also just the astronomy
; database (unless /all given).
;
chck_str=query_string+'&rows='+trim(1000)+'&fl=bibcode,doctype'
IF NOT keyword_set(all) THEN chck_str=chck_str+'&fq=database:astronomy'
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
; Here I do a filter on the document type. Note that some abstracts
; get flagged as 'inproceedings' so these need to be manually removed
; later. 
;
k=where(doctype EQ 'article' OR doctype EQ 'inproceedings',nk)
IF nk eq 0 THEN return,-1
bibcode=bibcode[k]

;
; SHINE abstracts seem to be classed as articles, so I remove them here.
;
s=strmid(bibcode,4,9)
k=where(s NE 'shin.conf',nk)
bibcode=bibcode[k]


return,bibcode

END
