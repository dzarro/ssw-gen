

FUNCTION cit_get_ads_entry, bibcode, big_list=big_list,  $
                            remove_abstracts=remove_abstracts, $
                            bad_bibcodes=bad_bibcodes, quiet=quiet
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
;      QUIET:  If set, then information messages are not printed to
;              screen. 
;
; OUTPUTS:
;      A structure (or structure array) with the following tags:
;
;      PUBDATE         STRING    '2012-01-00'
;      ABSTRACT        STRING    'The velocity pattern of a fan loop structure within a solar active region '...
;      YEAR            STRING    '2012'
;      BIBCODE         STRING    '2012ApJ...744...14Y'
;      AFF             OBJREF    <ObjHeapVar5151(LIST)>
;      PUB             STRING    'The Astrophysical Journal'
;      VOLUME          STRING    '744'
;      AUTHOR          OBJREF    <ObjHeapVar5139(LIST)>
;      CITATION_COUNT  LONG                47
;      TITLE           OBJREF    <ObjHeapVar5208(LIST)>
;      PROPERTY        OBJREF    <ObjHeapVar5108(LIST)>
;      KEYWORD         OBJREF    <ObjHeapVar5188(LIST)>
;      DOCTYPE         STRING    'article'
;      PAGE            OBJREF    <ObjHeapVar5123(LIST)>
;      ADS_LINK        STRING    'https://ui.adsabs.harvard.edu/abs/2012ApJ...744...14Y'
;      AUTHOR_STRING   STRING    ''
;      ARTICLE_STRING  STRING    ''
;      COUNTRY         OBJREF    <ObjHeapVar5251(LIST)>
;      REFEREED        BYTE         1
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
;      Bad_Bibcodes: Contains a list of input bibcodes that did not
;                    have entries in the ADS system.
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
;      Ver.11, 4-Sep-2018, Peter Young
;          The routine has started crashing when "citation_count" and
;          "property" are not returned by the ADS query. I've
;          fixed these now.
;      Ver.12, 21-Aug-2019, Peter Young
;          Updated the ADS link to the new website.
;      Ver.13, 5-Sep-2019, Peter Young
;          Added BAD_BIBCODES optional output; added /QUIET keyword.
;      Ver.14, 4-Dec-2019, Peter Young
;          ADS modified their output formats for text to include html
;          codes. json_parse messes up these codes when outputting to
;          a structure, so I've switched to using the "hash" output.
;      Ver.15, 14-Jan-2020, Peter Young
;          sock_list was resetting headers to an empty string,
;          so I've done a fix for this.
;      Ver.16, 06-Mar-2020, Peter Young
;          added the tag 'refereed' to output.
;-


IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> output = cit_get_ads_entry( bibcode [, big_list=, /remove_abstracts '
  print,'                                       bad_bibcodes=, /quiet ] )'
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
; IDL list 'big_list'.
;
big_list=0
FOR i=0,m-1 DO BEGIN
  chck_str=query[i]+'&rows='+trim(nn)+'&fl=bibcode,title,author,pub,abstract,citation_count,property,aff,volume,page,pubdate,year,issue,keyword,doctype'
  input_url=url+'?q='+chck_str
  IF strlen(input_url) GT 1000 THEN print,'***WARNING: exceeded max query string length of 1000 characters!'
 ;
  headers_input=headers
  sock_list,input_url,json,headers=headers_input
 ;
 ; Sometimes the call fails, so I try again and if this fails exit the routine.
  IF json[0] EQ '' THEN BEGIN
    headers_input=headers
    sock_list,input_url,json,headers=headers_input
    IF json[0] EQ '' THEN BEGIN
      print,'%CIT_GET_ADS_ENTRY: the call to the API failed. Please try again or check your inputs. Returning...'
      return,-1
    ENDIF 
  ENDIF
 ;
  s=json_parse(json)  ; this is an orderedhash
  response=s['response']
  docs=response['docs']  ; this is a list of orderedhashes

  IF docs.count() NE 0 THEN BEGIN 
    IF datatype(big_list) NE 'OBJ' THEN BEGIN
      big_list=docs
    ENDIF ELSE BEGIN
      nd=docs.count()
      FOR j=0,nd-1 DO big_list.add,docs[j]
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
;   big_list[i] is an orderedhash
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
       country: list(), $
       refereed: 0b}
output=replicate(str,n)


; PRY, 4-Dec-2019
; The code below now assumes big_list is a list array of orderedhashes.
;
FOR i=0,n-1 DO BEGIN
  bib_hash=big_list[i]
 ;
  output[i].bibcode=bib_hash['bibcode']
  output[i].ads_link='https://ui.adsabs.harvard.edu/abs/'+bib_hash['bibcode']
  IF bib_hash.haskey('pubdate') THEN output[i].pubdate=bib_hash['pubdate']
  IF bib_hash.haskey('abstract') THEN output[i].abstract=bib_hash['abstract']
  IF bib_hash.haskey('year') THEN BEGIN
    output[i].year=bib_hash['year']
  ENDIF ELSE BEGIN
    output[i].year=strmid(output[i].bibcode,0,4)
  ENDELSE 
  IF bib_hash.haskey('aff') THEN output[i].aff=bib_hash['aff']
  IF bib_hash.haskey('pub') THEN output[i].pub=bib_hash['pub']
  IF bib_hash.haskey('volume') THEN output[i].volume=bib_hash['volume']
  IF bib_hash.haskey('keyword') THEN output[i].keyword=bib_hash['keyword']
  IF bib_hash.haskey('author') THEN output[i].author=bib_hash['author']
  IF bib_hash.haskey('doctype') THEN output[i].doctype=bib_hash['doctype']
  IF bib_hash.haskey('citation_count') THEN output[i].citation_count=bib_hash['citation_count']
  IF bib_hash.haskey('property') THEN BEGIN
    output[i].property=bib_hash['property']
    np=output[i].property.count()
    swtch=0
    FOR j=0,np-1 DO BEGIN
      IF trim(output[i].property[j]) EQ 'REFEREED' AND swtch EQ 0 THEN BEGIN
        output[i].refereed=1b
        swtch=1
      ENDIF 
    ENDFOR 
  ENDIF 
  IF bib_hash.haskey('title') THEN output[i].title=bib_hash['title']
  IF bib_hash.haskey('page') THEN output[i].page=bib_hash['page']
 ;
  junk=temporary(bib_hash)
ENDFOR

  
;
; PRY, 4-Dec-2019
;  This was the code for when I was dealing with big_list being a
;  structure.
;
; Now load up output with the contents of big_list.
;
;; FOR i=0,n-1 DO BEGIN
;;   output[i].bibcode=big_list[i].bibcode
;;   output[i].ads_link='https://ui.adsabs.harvard.edu/abs/'+big_list[i].bibcode
;;   IF tag_exist(big_list[i],'pubdate') EQ 1 THEN output[i].pubdate=big_list[i].pubdate
;;   IF tag_exist(big_list[i],'abstract') EQ 1 THEN output[i].abstract=big_list[i].abstract
;;  ;
;;  ; I found one example where 'year' didn't exist, so I just get
;;  ; it from the bibcode.
;;   IF tag_exist(big_list[i],'year') EQ 1 THEN BEGIN
;;     output[i].year=big_list[i].year
;;   ENDIF ELSE BEGIN
;;     output[i].year=strmid(output[i].bibcode,0,4)
;;   ENDELSE 
;;   IF tag_exist(big_list[i],'aff') EQ 1 THEN output[i].aff=big_list[i].aff
;;   IF tag_exist(big_list[i],'pub') EQ 1 THEN output[i].pub=big_list[i].pub
;;   IF tag_exist(big_list[i],'volume') EQ 1 THEN output[i].volume=big_list[i].volume
;;   IF tag_exist(big_list[i],'keyword') EQ 1 THEN output[i].keyword=big_list[i].keyword
;;   IF tag_exist(big_list[i],'author') EQ 1 THEN output[i].author=big_list[i].author
;;   IF tag_exist(big_list[i],'doctype') EQ 1 THEN output[i].doctype=big_list[i].doctype
;;   IF tag_exist(big_list[i],'citation_count') EQ 1 THEN output[i].citation_count=big_list[i].citation_count
;;   output[i].title=big_list[i].title
;;   IF tag_exist(big_list[i],'property') EQ 1 THEN output[i].property=big_list[i].property
;;   IF tag_exist(big_list[i],'page') EQ 1 THEN output[i].page=big_list[i].page
;; ENDFOR 

junk=temporary(bad_bibcodes)   ; in case it exists from a previous call
IF n NE n_elements(bibcode) THEN BEGIN
  n2=n_elements(bibcode)
  IF NOT keyword_set(quiet) THEN print,'% CIT_GET_ADS_ENTRY:  '+trim(n2-n)+' of '+trim(n2)+' bibcodes did not have ADS entries.'
  bad_bibcodes=''
  FOR i=0,n2-1 DO BEGIN
    k=where(trim(bibcode[i]) EQ output.bibcode,nk)
    IF nk EQ 0 THEN bad_bibcodes=[bad_bibcodes,bibcode[i]]
  ENDFOR
  bad_bibcodes=bad_bibcodes[1:*]
ENDIF 


IF keyword_set(remove_abstracts) THEN BEGIN
  k=where(output.doctype NE 'abstract',nk)
  IF nk NE 0 THEN output=output[k] ELSE output=-1
ENDIF 


return,output

END
