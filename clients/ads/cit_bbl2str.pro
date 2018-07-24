
FUNCTION cit_bbl2str, file, extra=extra


;+
; NAME:
;     CIT_BBL2STR
;
; PURPOSE:
;     Converts a list of BIBTEX entries into an IDL structure.
;
; INPUTS
;     File:   The name of the file containing the Bibtex entries. Can
;             be array.
;
; OPTIONAL INPUTS:
;     Extra:  Allows the specification of a file that contains extra 
;             citations. This is useful for including citations not found 
;             by my ADS search system. **This input is obsolete (just
;             need to specify the extra file within FILE) but
;             maintained for backwards compatibility.**
;
; OUTPUTS:
;     The IDL structure containing the BIBTEX information. If FILE
;     does not exist, then LIST is returned as -1.
;
; EXAMPLES:
;     IDL> str=cit_bbl2str('publ_list.bbl')
;
; CALLS:
;     CIT_CONV_LATEX_JNL
;
; HISTORY:
;     Ver.1, 11-Jul-2017, Peter Young
;        Copied from make_bib_structure.pro and converted to function.
;     Ver.2, 11-Apr-2018, Peter Young
;        The school entry can sometimes extend over more than one
;        line, so this has been fixed.
;-



IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> str = cit_bbl2str( file )'
  return,-1
ENDIF

result=file_search(file,count=count)
IF count EQ 0 THEN BEGIN
  print,'%CIT_BBL2STR: The input file does not exist. Returning...'
  return,-1
ENDIF ELSE BEGIN
  files=result
ENDELSE 


str={id: '', author: '', title: '', journal: '', booktitle:'', $
     year: '', volume: '', link: '', eprint:'', $
     pages: '', type:'', ncit: -1, flag1: 0, series: '', editor: '', $
     school: ''}
list=replicate(str,2000)
i=-1
str1=''
jnl=''


editor_flag=0b
editor_string=''
school_flag=0b
school_string=''

IF n_elements(extra) NE 0 THEN BEGIN 
  chck=file_search(extra,count=count)
  IF count NE 0 THEN BEGIN 
    files=[file,extra]
  ENDIF ELSE BEGIN
    print,'%CIT_BBL2STR: the extra file does not exist, so ignoring.'
  ENDELSE 
ENDIF 

FOR j=0,n_elements(files)-1 DO BEGIN 

openr,lun,files[j],/get_lun

WHILE eof(lun) NE 1 DO BEGIN
  readf,lun,str1
 ;
  IF editor_flag EQ 1 THEN BEGIN
    chck=strpos(str1,'=')
    IF chck GE 0 THEN editor_flag=2b ELSE editor_string=editor_string+str1
  ENDIF 
 ;
  IF strmid(str1,0,1) EQ '@' THEN BEGIN
    i=i+1
   ;
   ; Reset the editor information
   ;
    editor_flag=0b
    editor_string=''
   ;
   ; extract the bibcode for the citation from the @{ line
   ; 17-Aug-2007, I've now added entry_type since there seems to be several
   ;  different types now: ARTICLE, INBOOK, ...
   ;
    bits=str_sep(str1,'{')
    entry_type=bits[0]
    entry_type=repstr(entry_type,'@','')
   ;
    IF strlowcase(entry_type) EQ 'phdthesis' THEN list[i].type='PhD thesis'
   ;
    IF strlowcase(entry_type) EQ 'inproceedings' THEN list[i].type='Proceedings'
   ;
    IF strlowcase(entry_type) EQ 'book' THEN list[i].type='book'
   ;
    id=bits[1]
    bits=str_sep(id,',')
    id=bits[0]
    list[i].id=id
   ;
   ; it is assumed that the authors are given first in the bibtex format. There are 
   ; two exceptions currently: (i) no author, but an editor; (ii) no author or editor.
   ;
    readf,lun,str1
    str1=strtrim(str1,1)
    bits=str_sep(str1,'author = {')
   ;
   ; need the following for the special case in which there is no author, 
   ; only an editor.
   ;
    IF n_elements(bits) EQ 1 THEN bits=str_sep(str1,'editor = {')
    IF n_elements(bits) EQ 1 THEN BEGIN
      astr=''
      titstr=str_sep(str1,'title = {')
      GOTO,lbl1
    ENDIF ELSE astr=bits[1]
   ;
   ; the full list of authors can be spread over several lines, the following
   ; adds on these extra lines to the list. When a 'title =' is found then
   ; this process is 
   ; stopped.
   ;
    tst1=0
    WHILE tst1 EQ 0 DO BEGIN
      readf,lun,str1
      str1=strtrim(str1,1)
      bits=str_sep(str1,'title = ')
      IF n_elements(bits) LT 2 THEN astr=astr+bits[0] ELSE tst1=1
    ENDWHILE
    titstr=bits[1]
    lbl1: astr=strtrim(astr,0)
;    n=strlen(astr)
;    astr=strmid(astr,0,n-2)
    author=cit_conv_latex_auth(astr)
    list[i].author=author
   ;
   ; add title to list
   ;
    bits=str_sep(titstr,'"')
    IF n_elements(bits) NE 3 THEN BEGIN
      title=bits[1]
      FOR k=2,n_elements(bits)-2 DO BEGIN
        title=title+'"'+bits[k]
      ENDFOR
    ENDIF ELSE BEGIN
      title=bits[1]
    ENDELSE
    title=repstr(title,'{','')
    title=repstr(title,'}','')
    list[i].title=cit_convert_latex(title)
  ENDIF

 ;
 ; add year to list
 ;
  bits=str_sep(str1,'year =')
  IF n_elements(bits) NE 1 THEN BEGIN
    year=strtrim(bits[1],2)
    bits=str_sep(year,',')
    year=bits[0]
    list[i].year=year
  ENDIF
 ;
  bits=str_sep(str1,'volume =')
  IF n_elements(bits) NE 1 THEN BEGIN
    vol=strtrim(bits[1],2)
    bits=str_sep(vol,',')
    vol=bits[0]
    list[i].volume=vol
  ENDIF
 ;
  bits=str_sep(str1,'series =')
  IF n_elements(bits) NE 1 THEN BEGIN
    pos1=strpos(str1,'{')
    pos2=strpos(str1,'}')
    IF pos1 GE 0 AND pos2 GE 0 THEN ser=strmid(str1,pos1+1,pos2-pos1-1)
    list[i].series=ser
  ENDIF
 ;
 ; The following deals with the editor entry (if it exists). Note that
 ; the entry may extend over more than one line (like the author list).
 ; 
  bits=str_sep(str1,'editor =')
  IF n_elements(bits) NE 1 THEN BEGIN
    editor_flag=1b
    editor_string=bits[1]
  ENDIF 
 ;
 ; The editor string is only processed when editor_flag=2
  IF editor_flag EQ 2 THEN BEGIN
    editor_string=strcompress(editor_string)
    editor_string=strtrim(editor_string,2)
    pos1=strpos(editor_string,'{')
    pos2=strpos(editor_string,'}',/reverse_search)
    IF pos1 GE 0 AND pos2 GE 0 THEN ed=strmid(editor_string,pos1+1,pos2-pos1-1)
    ed=cit_conv_latex_auth(ed)
    ed=cit_convert_latex(ed)
    list[i].editor=ed
  ENDIF
 ;
 ;
  bits=str_sep(str1,'journal =')
  IF n_elements(bits) NE 1 THEN BEGIN
    jnl=strtrim(bits[1],2)
    jnl=repstr(jnl,'{','')
    jnl=repstr(jnl,'}','')
    jnl=repstr(jnl,',','')
;    bits=str_sep(jnl,'\')
;    IF n_elements(bits) GT 1 THEN 
    jnl=cit_conv_latex_jnl(jnl)
    list[i].journal=cit_convert_latex(jnl)
  ENDIF
 ;
  bits=str_sep(str1,'eprint =')
  IF n_elements(bits) NE 1 THEN BEGIN
    eprint=strtrim(bits[1],2)
    eprint=repstr(eprint,'{','')
    eprint=repstr(eprint,'}','')
    eprint=repstr(eprint,',','')
    list[i].eprint=eprint
;    list[i].type='eprint'
  ENDIF
 ;
  bits=str_sep(str1,'booktitle =')
  IF n_elements(bits) NE 1 THEN BEGIN
    booktitle=strtrim(bits[1],2)
    pos1=strpos(booktitle,'{')
    pos2=strpos(booktitle,'}',/reverse_search)
    list[i].booktitle=cit_convert_latex(strmid(booktitle,pos1+1,pos2-pos1-1))
    ;; vol=repstr(vol,'{','')
    ;; vol=repstr(vol,'}','')
    ;; list[i].booktitle=tidy_string(vol)
  ENDIF
 ;
  bits=str_sep(str1,'school =')
  IF n_elements(bits) NE 1 THEN BEGIN
    school_flag=1b
    school_string=bits[1]
  ENDIF 
 ;
 ; The school string is only processed when school_flag=2
  IF school_flag EQ 2 THEN BEGIN
    school_string=strcompress(school_string)
    school_string=strtrim(school_string,2)
    pos1=strpos(school_string,'{')
    pos2=strpos(school_string,'}',/reverse_search)
    IF pos1 GE 0 AND pos2 GE 0 THEN sch=strmid(school_string,pos1+1,pos2-pos1-1)
    sch=cit_convert_latex(sch)
    list[i].school=sch
    school_flag=0b
  ENDIF
 ;
  bits=str_sep(str1,'pages =')
  IF n_elements(bits) NE 1 THEN BEGIN
    pages=strtrim(bits[1],2)
    pages=repstr(pages,'{','')
    pages=repstr(pages,'}','')
    pages=repstr(pages,',','')
    pages=repstr(pages,'--','-')
    pages=repstr(pages,'-+','')
    list[i].pages=pages
  ENDIF
 ;
  bits=str_sep(str1,'url =')
  IF n_elements(bits) NE 1 THEN BEGIN
    url=strtrim(bits[1],2)
    url=repstr(url,'{','')
    url=repstr(url,'}','')
    list[i].link=url
  ENDIF
 ;
ENDWHILE

free_lun,lun

ENDFOR

ind=where(list.id EQ '')
i=min(ind)
list=list[0:i-1]

n=n_elements(list)
FOR i=0,n-1 DO BEGIN
 ;
 ; A journal is assumed to have 'journal', 'volume' and 'pages'
 ; populated. 
 ;
  IF (list[i].journal NE '') AND (list[i].volume NE '') AND $
       (list[i].pages NE '') THEN list[i].type='journal'

  ;
  chck=strpos(strlowcase(list[i].booktitle),'abstract')
  IF chck GE 0 THEN list[i].type='Abstract'
 ;
 ; An e-print is assumed to have a journal name that contains 'arxiv'.
 ;
  chck=strpos(strlowcase(list[i].journal),'arxiv')
  IF chck GE 0 THEN list[i].type='eprint'
 ;
  result=strpos(list[i].journal,'AAS')
  IF result NE -1 THEN list[i].type='AAS'
 ;
  result=strpos(list[i].journal,'American Astronomical Society')
  IF result NE -1 THEN list[i].type='AAS'

;  IF list[i].booktitle NE '' THEN list[i].type='book'
 ;
  result=strpos(list[i].booktitle,'AAS/Solar')
  IF result NE -1 THEN list[i].type='AAS'

 ; This is for the TESS meeting
  result=strpos(list[i].booktitle,'AAS/AGU')
  IF result NE -1 THEN list[i].type='AAS'
 ;
 ; Flag AAS/HEAD abstracts
  result=strpos(strlowcase(list[i].booktitle),'aas/high energy')
  IF result NE -1 THEN list[i].type='AAS'
 ;
  result=strpos(list[i].booktitle,'American Astronomical Society')
  IF result NE -1 THEN list[i].type='AAS'

 ;
 ; Here I flag COSPAR abstracts
  result=strpos(strlowcase(list[i].booktitle),'cospar scientific assembly')
  IF result NE -1 THEN list[i].type='COSPAR'

 ;
 ; Here I flag EGU abstracts
  result=strpos(strlowcase(list[i].booktitle),'egu general assembly')
  IF result NE -1 THEN list[i].type='EGU'

  result=strpos(list[i].journal,'IAU General Assembly')
  IF result NE -1 THEN list[i].type='IAU'

  result=strpos(list[i].journal,'AGU')
  IF result NE -1 THEN list[i].type='AGU'
  result=strpos(list[i].journal,'American Geophysical Union')
  IF result NE -1 THEN list[i].type='AGU'
  result=strpos(list[i].booktitle,'American Geophysical Union')
  IF result NE -1 THEN list[i].type='AGU'

  result=strpos(list[i].journal,'European Solar Physics Meeting')
  IF result NE -1 THEN list[i].type='conf'

ENDFOR


;
; Now check to make sure all entries are unique (by looking at
; bibcode). 
;
k=sort(list.id)
list=list[k]
k=uniq(list.id)
list=list[k]

return,list

END
