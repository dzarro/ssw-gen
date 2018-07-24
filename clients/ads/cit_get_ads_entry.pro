

FUNCTION cit_get_ads_entry, bibcode, big_list=big_list,  $
                            remove_abstracts=remove_abstracts
;+
; NAME:
;      CIT_GET_ADS_ENTRY()
;
; PURPOSE:
;      This routine queries the ADS webpage with a set of bibcodes,
;      returning information about the papers, such as title, author,
;      citation counts, etc. The results are returned in an IDL
;      structure. Unfortunately the query does not return all of the
;      information about the article, for example some parameters
;      related to conference proceedings. So this routine does not
;      replace a bibtex query.
;
;      The user must have an ADS key for the routine to work. 
;
; CATEGORY:
;      Citations; bibliography; ADS.
;
; CALLING_SEQUENCE:
;      Result = CIT_GET_ADS_ENTRY ( Bibcode )
;
; INPUTS:
;      Bibcode:  A string or string array containing bibcode IDs
;                (e.g., "2015ApJ...809...82G").
;
; KEYWORD PARAMETERS:
;      REMOVE_ABSTRACTS: If set, then articles that are abstracts will
;                        be removed from the list.
;
; OUTPUTS:
;      A structure (or structure array) with the following tags:
;
;      PUBDATE         STRING    '2012-01-00'
;      ABSTRACT        STRING    'The velocity pattern of a fan loop structure within a solar active region over the tempe'...
;      YEAR            STRING    '2012'
;      BIBCODE         STRING    '2012ApJ...744...14Y'
;      AFF             OBJREF    <ObjHeapVar18400(LIST)>
;      PUB             STRING    'The Astrophysical Journal'
;      VOLUME          STRING    '744'
;      AUTHOR          OBJREF    <ObjHeapVar18432(LIST)>
;      CITATION_COUNT  LONG                30
;      TITLE           OBJREF    <ObjHeapVar18446(LIST)>
;      PROPERTY        OBJREF    <ObjHeapVar18454(LIST)>
;      KEYWORD         OBJREF    <ObjHeapVar18418(LIST)>
;      DOCTYPE         STRING    'article'
;      PAGE            OBJREF    <ObjHeapVar18470(LIST)>
;      ADS_LINK        STRING    'http://adsabs.harvard.edu/abs/2012ApJ...744...14Y'
;      AUTHOR_STRING  STRING    ''
;      ARTICLE_STRING  STRING    ''
;      COUNTRY         OBJREF    <ObjHeapVar344788(LIST)>
;
;      The 'OBJREF' entries are IDL lists. For example, the individual
;      authors for the paper are identified with output.author[j],
;      which are strings.
;
;      The AUTHOR_STRING and ARTICLE_STRING tags are not populated but 
;      are used for storing information by other routines (e.g.,
;      cit_author_html). 
;
;      If no entries are found, then a value of -1 is returned.
;
; OPTIONAL OUTPUTS:
;      Big_List:   This is the IDL list that results from the API
;                  query after being converted from JSON format. The
;                  output structure is formed from this
;                  list. (Intended for use in bug-checking.)
;
; CALLS:
;      CIT_GET_ADS_KEY, SOCK_PAGE
;
; MODIFICATION HISTORY:
;      Ver.1, 1-Dec-2015, Peter Young
;          Working version, but doesn't use the ADS bigquery facility.
;      Ver.2, 4-Dec-2015, Peter Young
;          Some entries don't have an abstract, so now check for this.
;      Ver.3, 14-Dec-2015, Peter Young
;          Some entries don't have a volume, so now check for this.
;      Ver.4, 11-Jan-2016, Peter Young
;          I've added "keyword" to the output structure.
;      Ver.5, 11-Mar-2016, Peter Young
;          I found a paper that didn't have a year entry, so I've
;          fixed this.
;      Ver.6, 13-Oct-2016, Peter Young
;          I discovered the 'rows' query parameter which by default is
;          10 (i.e., at most 10 rows of data are returned), but it
;          seems it can only take a max value of 38; I've added
;          'doctype' to the output structure.
;      Ver.7, 10-Jul-2017, Peter Young
;          Tidied up abstract.
;      Ver.8, 23-Jul-2017, Peter Young
;          Reduced NN to 32 as I found a query that exceeded character
;          limit; now repeat sock_list call if it fails the first
;          time.
;      Ver.9, 1-Nov-2017, Peter Young
;          Reduced NN to 31 now; added call to cit_affil_country.pro,
;          and added country tag to output.
;      Ver.10, 14-May-2018, Peter YOung
;          Fixed bug when concatenating the query; if 125 bibcodes
;          were given previously then the 125th was being ignored. 
;-


IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> output = cit_get_ads_entry( bibcode [, big_list=, /remove_abstracts] )'
  return,-1
ENDIF 

n=n_elements(bibcode)

;
; Any '&' in a bibcode neads to be replaced with '%26' (an html
; code). The replace string function is fairly new, so I've
; left in the original code in case I have to make the routine
; backwards compatible with old IDL.
;
bcode=bibcode.replace('&','%26')
;; bcode=strarr(n)
;; FOR i=0,n-1 DO bcode[i]=str_replace(bibcode[i],'&','%26')


;**The Code below is commented out but I've left it in case I
;**work out how to use the 'bigquery' method.
;
;
; There are three different ways of creating the ADS query:
;   (1) a single bibcode
;   (2) a "small" multiple bibcode query (uses query)
;   (3) a "large" multiple bibcode query (uses bigquery)
; The ADS team recommend that you used bigquery for queries above 100
; entries. However, I'm finding that query fails above 9 entries
;
;; n=n_elements(bibcode)
;; url='https://api.adsabs.harvard.edu/v1/search/query'
;; CASE 1 OF
;;   n EQ 1: query='bibcode:'+bibcode
;;   n GT 1 AND n LE 9: BEGIN
;;     query='bibcode:('
;;     FOR i=0,n-2 DO query=query+bibcode[i]+' OR '
;;     query=query+bibcode[n-1]+')'
;;   END
;;   n GT 9: BEGIN
;;     m=n/9+1
;;     query=strarr(m)
;;     FOR i=0,m-1 DO BEGIN
;;       query[i]='bibcode:('
;;       FOR i=0,n-2 DO query=query+'"'+bibcode[i]+'" OR '
;;       query=query+bibcode[n-1]+'")'
;;     ENDFOR 
;;     query='bibcode:('
;;     FOR i=0,n-2 DO query=query+bibcode[i]+' OR '
;;     query=query+bibcode[n-1]+')'
;;   END
;; ENDCASE


;
; It turns out the query (i.e., the bit after "q" in the URL) can not
; be more than 1000 characters. Since the query contains the list of
; bibcodes then, for a big query, this limit will eventually be
; exceeded. Note that an individual bibcode is 19 characters in
; length. For this reason I restrict the maximum number of bibcodes in
; a single query to NN, and then require multiple calls to retrieve
; more bibcodes than this.
;
nn=31

;
; Set up the initial part of the query URL by sticking the bibcodes
; together. Note that the query has to be broken in multiple sections
; for large queries (> nn).
; PRY, 14-May-2018: fixed bug in the following bit when concatenating
; the query string.
;
url='https://api.adsabs.harvard.edu/v1/search/query'
IF n EQ 1 THEN BEGIN
  m=1
  query='bibcode:'+bcode
ENDIF ELSE BEGIN
  m=ceil(n/float(nn))
  query=strarr(m)
  FOR i=0,m-1 DO BEGIN
    j0=i*nn
    j1=min([(i+1)*nn-1,n-1])
    IF j0 EQ j1 THEN BEGIN
      query[i]='bibcode:'+bcode[j0]
    ENDIF ELSE BEGIN
      query[i]='bibcode:('
      FOR j=j0,j1-1 DO query[i]=query[i]+bcode[j]+' OR '
      query[i]=query[i]+bcode[j1]+')'
    ENDELSE 
  ENDFOR
ENDELSE 


;
; Get ADS API dev_key
;
ads_key=cit_get_ads_key(status=status,/quiet)
IF status EQ 0 THEN BEGIN
  print,'***The ADS key was not found!  Returning...***'
  return,-1
ENDIF 
headers=['Authorization: Bearer '+ads_key, $
         'Content-Type: application/json']


;
; The following performs the ADS queries and puts the results in the
; IDL list 'big_list'. Note that some of the parameters don't
; return anything (booktitle, series, editor).
;    pub -> series
;
big_list=0
FOR i=0,m-1 DO BEGIN
  chck_str=query[i]+'&rows='+trim(nn)+'&fl=bibcode,title,author,pub,abstract,citation_count,property,aff,volume,page,pubdate,year,issue,keyword,doctype'
  input_url=url+'?q='+chck_str
  IF strlen(input_url) GT 1000 THEN print,'***WARNING: exceeded max query string length of 1000 characters!'
 ;
  sock_list,input_url,json,headers=headers
 ;
 ; Sometimes the call fails, so I try again and if this fails exit the routine.
  IF json[0] EQ '' THEN BEGIN
    sock_list,input_url,json,headers=headers
    IF json[0] EQ '' THEN BEGIN
      print,'%CIT_GET_ADS_ENTRY: the call to the API failed. Please try again or check your inputs. Returning...'
      return,-1
    ENDIF 
  ENDIF
 ;
  s=json_parse(json,/tostruct)
  s_list=s.response.docs
  IF s_list.count() NE 0 THEN BEGIN 
    IF datatype(big_list) NE 'OBJ' THEN BEGIN
      big_list=s_list
    ENDIF ELSE BEGIN
      ns=s_list.count()
      FOR j=0,ns-1 DO big_list.add,s_list[j]
    ENDELSE
  ENDIF
ENDFOR



IF datatype(big_list) NE 'OBJ' THEN BEGIN
  print,'% CIT_GET_ADS_ENTRY: no entries found. Returning...'
  return,-1
ENDIF 


;
; A bibcode may not necessarily have an entry in ADS, so re-define n
; based on size of output.
;
n=big_list.count()


;
; The following isn't pretty, but it's needed to put the output in a
; standard format that can be accessed through a structure array. Note
; that the structures contained in s.response.docs[i] do not
; necessarily have the same format. Although they always seem to have
; the same tags, the tags can be in different orders, which
; corresponds to different structures for IDL.
;
; Note:
;   big_list is an IDL list (or array of lists)
;   big_list[i] is an IDL structure
;   big_list.pubdate gives an error!
;
str= { pubdate: '', $
       abstract: '', $
       year: '', $
       bibcode: '', $
       aff: list(), $
       pub: '', $
       volume: '', $
       author: list(), $
       citation_count: 0l, $
       title: list(), $
       property: list(), $
       keyword: list(), $
       doctype: '', $
       page: list(), $
       ads_link: '', $
       author_string: '', $
       article_string: '', $
       country: list() }
output=replicate(str,n)


;
; Now load up output with the contents of big_list.
;
FOR i=0,n-1 DO BEGIN
  output[i].bibcode=big_list[i].bibcode
  output[i].ads_link='http://adsabs.harvard.edu/abs/'+big_list[i].bibcode
  IF tag_exist(big_list[i],'pubdate') EQ 1 THEN output[i].pubdate=big_list[i].pubdate
  IF tag_exist(big_list[i],'abstract') EQ 1 THEN output[i].abstract=big_list[i].abstract
 ;
 ; I found one example where 'year' didn't exist, so I just get
 ; it from the bibcode.
  IF tag_exist(big_list[i],'year') EQ 1 THEN BEGIN
    output[i].year=big_list[i].year
  ENDIF ELSE BEGIN
    output[i].year=strmid(output[i].bibcode,0,4)
  ENDELSE 
  IF tag_exist(big_list[i],'aff') EQ 1 THEN output[i].aff=big_list[i].aff
  IF tag_exist(big_list[i],'pub') EQ 1 THEN output[i].pub=big_list[i].pub
  IF tag_exist(big_list[i],'volume') EQ 1 THEN output[i].volume=big_list[i].volume
  IF tag_exist(big_list[i],'keyword') EQ 1 THEN output[i].keyword=big_list[i].keyword
  IF tag_exist(big_list[i],'author') EQ 1 THEN output[i].author=big_list[i].author
  IF tag_exist(big_list[i],'doctype') EQ 1 THEN output[i].doctype=big_list[i].doctype
  output[i].citation_count=big_list[i].citation_count
  output[i].title=big_list[i].title
  output[i].property=big_list[i].property
  IF tag_exist(big_list[i],'page') EQ 1 THEN output[i].page=big_list[i].page
ENDFOR 

IF n NE n_elements(bibcode) AND NOT keyword_set(quiet) THEN BEGIN
  n2=n_elements(bibcode)
  print,'% CIT_GET_ADS_ENTRY:  '+trim(n2-n)+' of '+trim(n2)+' bibcodes did not have ADS entries.'
ENDIF 


IF keyword_set(remove_abstracts) THEN BEGIN
  k=where(output.doctype NE 'abstract',nk)
  IF nk NE 0 THEN output=output[k] ELSE output=-1
ENDIF 


return,output

END
