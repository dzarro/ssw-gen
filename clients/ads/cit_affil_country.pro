
PRO cit_affil_country, input, first_author=first_author, affil_file=affil_file

;+
; NAME:
;     CIT_AFFIL_COUNTRY
;
; PURPOSE:
;     This routine automatically uses the affiliation tag of the
;     cit_get_ads_entry structure to extract the country to which
;     the insitute belongs.
;
; CATEGORY:
;     ADS; affiliations.
;
; CALLING SEQUENCE:
;     Result = CIT_AFFIL_COUNTRY( Input )
;
; INPUTS:
;     Input:  An IDL structure in the format produced by
;             cit_get_ads_entry. 
;
; OPTIONAL INPUTS:
;     Affil_File:  The name of a file containing the
;             affiliation-country connections. It must be a text
;             file with two columns. The first column contains the
;             country name with format 'a13'. The second column
;             contains the institute name with format 'a60'. If the
;             filename is not given, then the master file at:
;          http://files.pyoung.org/idl/ads/cit_affil_country.txt
;             is read. If the affiliation contains a "*" then this
;             is interpreted as a space, thus "*USA" will not be
;             triggered by "Busan".
;
; KEYWORD PARAMETERS:
;     First_Author: If set, then the affiliation is only checked for
;                   the paper's first author.
;
; OUTPUTS:
;     The input structure is returned, but with the COUNTRY tag
;     updated to contain the authors' country
;     affiliations. Note that the tag will be a list with the same
;     number of elements as the "author" tag of ADS_DATA.
;
; PROGRAMMING NOTES:
;     The routine checks the file at
;     http://files.pyoung.org/idl/ads/cit_affil_country.txt to match
;     institutes with countries.
;
;     The routine assigns a country by searching for a word or phrase
;     that matches the list in the cit_affil_country file. If an
;     author has multiple affiliations then only the first affiliation
;     is searched. Searching only for the country name can be
;     ambiguous (e.g., "New England" and "England") so often a town or
;     institute name might be used instead.
;
;     It's possible that an author's affiliation matches two different
;     countries. This can be due to a problem with the format of ADS
;     affiliation (multiple affiliations should be separated by ";"
;     but another symbol might be used), or due to the affiliation
;     matching. For example, "Canada Street, Boston, USA" could match
;     Canada and USA. A warning is printed in this case but the
;     country will be assigned to the first match.
;
;     If not match is found, then the routine prints out the
;     affiliation so that the author can use it to update the
;     cit_affil_country.txt file).
;
; MODIFICATION HISTORY:
;     Ver.1, 27-Jul-2017, Peter Young
;     Ver.2, 1-Nov-2017, Peter Young
;       added AFFIL_FILE input; removed link to file on my computer.
;     Ver.3, 6-Sep-2019, Peter Young
;       Sometimes the affiliation contains "&amp;" instead of "&",
;       and the semi-colon gets flagged as a separator. I've
;       fixed this now.
;     Ver.4, 13-Sep-2019, Peter Young
;       fixed bug when trying to read afill_file; introduced
;       possibility of specifying an affiliation with "*" to
;       represent a space.
;     Ver.5, 21-Jan-2020, Peter Young
;       now prints bibcode if no. of authors does not match no. of
;       affiliations. 
;-

IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> cit_affil_country, ads_data [, /first_author, affil_file= ]'
  print,'  - the country tag of ads_data will be updated'
  return
ENDIF 

n=n_elements(input)

str={country: '', institute: ''}
affilstr=0

;
;The priorities for the affiliation file are:
;  1. read the specified affil_file
;  2. read the master file over the internet
;  3. read the master file in SSW
;
IF n_elements(affil_file) NE 0 THEN BEGIN
  chck=file_search(affil_file,count=count)
  IF count EQ 0 THEN BEGIN
    print,'% CIT_AFFIL_COUNTRY: the specified AUTHOR_FILE does not exist. Returning...'
  ENDIF
ENDIF ELSE BEGIN
 ;
 ; This is the master file, which should be the most up-to-date version.
 ;
  chck=have_network()
  IF chck EQ 1 THEN BEGIN
    url='http://files.pyoung.org/idl/ads/cit_affil_country.txt'
    sock_list,url,page
  ENDIF
 ;
 ; If there's no internet connection, then pick up the file in SSW.
 ;
  IF chck EQ 0 OR page[0] EQ '' THEN BEGIN
    affil_file=concat_dir(getenv('SSW'),'gen/idl/clients/ads')
    affil_file=concat_dir(affil_file,'cit_affil_country.txt')
  ENDIF
ENDELSE

;
; If the internet option hasn't worked, then we need to read
; affil_file into 'page'.
;
IF n_elements(page) EQ 0 THEN BEGIN
  result=query_ascii(affil_file,info)
  nl=info.lines
  page=strarr(nl)
  openr,lin,affil_file,/get_lun
  readf,lin,page
  free_lun,lin
ENDIF 
    
np=n_elements(page)
FOR i=0,np-1 DO BEGIN
  s1=''
  s2=''
  IF trim(page[i]) NE '' THEN BEGIN 
    reads,page[i],format='(a13,a60)',s1,s2
    s2=trim(s2)
    s2=str_replace(s2,'*',' ')
    str.country=trim(s1)
    str.institute=s2
    IF n_tags(affilstr) EQ 0 THEN affilstr=str ELSE affilstr=[affilstr,str]
  ENDIF 
ENDFOR

nc=n_elements(affilstr)


FOR i=0,n-1 DO BEGIN
 ;
 ; Reset country tag if it has previously been defined
 ;
  input[i].country=list()
  naff=input[i].aff.count()
  nauth=input[i].author.count()
  IF nauth NE naff THEN print,'% CIT_AFFIL_COUNTRY: **WARNING: no. of authors and no. of affiliations are not the same! ('+input[i].bibcode+')'
  IF naff GT 0 THEN BEGIN 
    IF keyword_set(first_author) THEN naff=1
    country=strarr(naff)
    FOR j=0,naff-1 DO BEGIN
      aff=input[i].aff[j]
      aff=str_replace(aff,'&amp;','and')
      IF trim(aff) EQ '-' THEN BEGIN
        country[j]=''
      ENDIF ELSE BEGIN 
        bits=str_sep(aff,';')
        aff=bits[0]   ; take only the 1st affil of author
        FOR k=0,nc-1 DO BEGIN
          chck=strpos(strlowcase(aff),strlowcase(affilstr[k].institute))
          IF chck GE 0 AND country[j] EQ '' THEN country[j]=affilstr[k].country
          IF chck GE 0 AND country[j] NE '' THEN BEGIN
            IF country[j] NE affilstr[k].country THEN print,'% CIT_AFFIL_COUNTRY: **WARNING: multiple countries found for '+aff,' *** ',country[j],', ',affilstr[k].country 
          ENDIF 
        ENDFOR
        IF country[j] EQ '' THEN print,'% CIT_AFFIL_COUNTRY: No entry found for '+aff
      ENDELSE 
      input[i].country.add,country[j]
    ENDFOR
  ENDIF 
ENDFOR 


END
