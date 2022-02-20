
PRO cit_fill_strings, ads_data

;+
; NAME:
;     CIT_FILL_STRINGS
;
; PURPOSE:
;     Fills the author_string and article_string tags of ADS_DATA. 
;
; CATEGORY:
;     ADS; citations; string processing.
;
; CALLING SEQUENCE:
;     CIT_FILL_STRINGS, Ads_Data
;
; INPUTS:
;     Ads_Data:  A structure in the format returned by
;                cit_get_ads_entry.pro. 
;
; OUTPUTS:
;     The input structure is returned, but with the author_string and
;     article_string tags filled. The format of these strings is
;     suitable for printing to a html file.
;
; CALLS:
;     CIT_GET_ADS_BIBTEX, CIT_BBL2STR
;
; EXAMPLE:
;     IDL> a=cit_get_ads_entry('2015ApJ...799..218Y')
;     IDL> cit_fill_strings,a
;     IDL> print,a.author_string
;     Young, Peter R., Tian, Hui & Jaeggli, Sarah
;     IDL> print,a.article_string
;     ApJ, 799, 218
;
; MODIFICATION HISTORY:
;     Ver.1, 2-Oct-2019, Peter Young
;-

IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> cit_fill_strings, ads_data'
  print,'  - the article_string and author_string tags of ads_data will be updated'
  return
ENDIF 

IF n_tags(ads_data) EQ 0 THEN return

n=n_elements(ads_data)

bib=cit_get_ads_bibtex(ads_data.bibcode)
bibstr=cit_bbl2str(bib_strarr=bib)

FOR ii=0,n-1 DO BEGIN
  bcode=ads_data[ii].bibcode
  ib=where(bcode EQ bibstr.id,nib)
  ed_str=''
  ser_str=''
  bt_str=''
  sch_str=''
  IF nib NE 0 THEN BEGIN
    info=bibstr[ib]
    IF info.editor NE '' THEN ed_str=' (Editors: '+info.editor+')'
    IF info.series NE '' THEN ser_str=', '+info.series
    IF info.booktitle NE '' THEN bt_str=info.booktitle
    IF info.school NE '' THEN sch_str=' ('+info.school+')' 
  ENDIF 
    
 ;
  IF ads_data[ii].page.count() EQ 0 THEN page_str='' ELSE page_str=ads_data[ii].page[0]

  CASE ads_data[ii].doctype OF
    'article': BEGIN
      article_string=cit_jour_abbrev(ads_data[ii].pub)+ $
                     ', '+ads_data[ii].volume+', '+page_str
    END
       ;
    'erratum': BEGIN
      article_string=ads_data[ii].pub+', '+ads_data[ii].volume+', '+page_str+' (Erratum)'
    END
        ;
    'inproceedings': BEGIN
      IF page_str EQ '' THEN page_str2='' ELSE page_str2=', p. '+page_str
      IF ads_data[ii].volume EQ '' THEN vol_str='' ELSE vol_str=', '+ads_data[ii].volume
     ;
      article_string=bt_str+ed_str+ser_str+vol_str+page_str2
    END 
       ;
    'phdthesis': BEGIN
      article_string=ads_data[ii].pub+sch_str
    END
       ;
    'abstract': BEGIN
      swtch=1   ; this means these will get ignored.
    END
       ;
    'inbook': BEGIN
      article_string=ads_data[ii].pub+ed_str+', p.'+ads_data[ii].page[0]
    END 
       ;
    'book': BEGIN
      article_string=bt_str
    END
       ;
    'eprint': BEGIN
      article_string=ads_data[ii].page[0]
    END
       ;
    'intechreport': BEGIN
      article_string=ads_data[ii].title[0]+' (Report)'
    END
       ;
    'techreport': BEGIN
      article_string=ads_data[ii].title[0]+' (Report)'
    END
       ;
    ELSE: BEGIN
      print,'%CIT_AUTHOR_HTML: ***WARNING I have not encountered this doctype before***'
      print,'   '+ads_data[ii].bibcode+'   doctype: ',ads_data[ii].doctype
      article_string=''
    END
  ENDCASE

  IF ads_data[ii].author.count() NE 0 THEN BEGIN 
    author_string=ads_data[ii].author[0]
    nauth=n_elements(ads_data[ii].author)
    IF nauth GT 1 THEN BEGIN 
      FOR ia=1,nauth-1 DO BEGIN
        IF ia EQ nauth-1 THEN sep_string=' & ' ELSE sep_string=', '
        author_string=author_string+sep_string+ads_data[ii].author[ia]
      ENDFOR
    ENDIF
  ENDIF 
 ;
  ads_data[ii].author_string=author_string
  ads_data[ii].article_string=article_string
  
ENDFOR



END
      
