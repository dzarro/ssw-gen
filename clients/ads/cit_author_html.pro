
PRO cit_author_html, bibcodes, bib_file=bib_file, html_file=html_file, $
                     name=name, ads_library=ads_library, $
                     author=author, ads_data=ads_data, remove_file=remove_file, $
                     link_author=link_author, surname=surname

;+
; NAME:
;     CIT_AUTHOR_HTML
;
; PURPOSE:
;     This routine takes a list of bibcodes and constructs a
;     publication list in html format. An additional file is also
;     created containing the list sorted according to the number of
;     citations. 
;
; CATEGORY:
;     Citations; ADS; publication list.
;
; CALLING SEQUENCE:
;     CIT_AUTHOR_HTML, Bibcodes
;
; INPUTS:
;     Bibcodes:  A string or string array containing Bibcodes. The
;                Bibcodes can also be specified through BIB_FILE=.
;
; OPTIONAL INPUTS:
;     Bib_File:  A text file containing a list of Bibcodes. Can be
;                specified instead of BIBCODES.
;     Html_File: The name of the html file to be created. If not
;                specified, then the file "author.html" is
;                written to the user's working directory.
;     Name:      The name of the person to which the publication list
;                belongs. This is placed in the title of the output
;                html file. 
;     Author:    The name of the person who created the file, which is
;                placed in the footer of the html file.
;     Link_Author: This is used to assign a link to the
;                author's name in the footer.
;     Surname:   The surname of the person to which the publication
;                list belongs. This is used to check how many first
;                author papers belong to the person (this information
;                is printed to the IDL screen).
;     Ads_Library: This should be set to a URL pointing to an ADS
;                library containing the same publication list as the
;                html file. A link will be inserted in the html
;                pointing to this page.
;     Remove_file: This is the name of a file containing a list of
;                Bibcodes to be *removed* from the list contained in
;                Bibcodes. This can be useful if you have a common
;                name and want to keep a permanent list of wrong
;                matches. 
;
; OPTIONAL OUTPUTS:
;     Ads_Data:  This is a structure containing the ADS data for each
;                Bibcode. The format is the same as that returned by
;                CIT_GET_ADS_ENTRY. 
;
; OUTPUTS:
;     Creates a html file containing a publication list. The name of
;     the file is set by HTML_FILE and by default is "author.html". A
;     second file is also created, with "_cit" appended (e.g.,
;     "author_cit.html") which contains the publications sorted by the
;     numbers of citations.
;
; CALLS:
;     CIT_GET_ADS_ENTRY, CIT_GET_ADS_KEY, CIT_JOUR_ABBREV,
;     CIT_GET_ADS_BIBTEX, CIT_PROCESS_BIBTEX
;
; EXAMPLE:
;      Search for an author in ADS, and save the output as bibtex. If
;      the file is called 'parker.bbl', then do:
;
;      IDL> str=cit_bib2str('parker.bbl')
;      IDL> cit_author_html,str.id,html_file='parker.html',name='Dr. E.N. Parker'      
;
; MODIFICATION HISTORY:
;      Ver.1, 12-Jul-2017, Peter Young
;      Ver.2, 26-Mar-2018, Peter Young
;        Now checks if the html file already exists and deletes it.
;-



IF n_elements(bibcodes) EQ 0 AND n_elements(bib_file) EQ 0 THEN BEGIN
  print,'Use:  IDL> cit_author_html, bibcodes, [html_file=, bib_file=, name=, ads_library=, author='
  print,'                              ads_data=, remove_file='
  return
ENDIF 

IF n_elements(name) EQ 0 THEN BEGIN
  name='the Author'
  print,"%MAKE_AUTHOR_HTML: use the keyword NAME= to specify the author's name"
ENDIF

;
; Check if the user has an ADS key.
;
chck=cit_get_ads_key(status=status,/quiet)
IF status EQ 0 THEN BEGIN
  print,'%CIT_AUTHOR_HTML: You do not have an ADS key. Please check the webpage'
  print,'    http://pyoung.org/quick_guides/ads_idl_query.html'
  print,'for how to get one.'
  return
ENDIF 

IF n_elements(bib_file) NE 0 THEN BEGIN
  chck=file_search(bib_file,count=count)
  IF count EQ 0 THEN BEGIN
    print,'%CIT_AUTHOR_HTML: The specified bib_file does not exist. Returning...'
    return
  ENDIF
  openr,lin,bib_file,/get_lun
  str1=''
  bibcodes=''
  WHILE eof(lin) EQ 0 DO BEGIN
    readf,lin,str1
    bibcodes=[bibcodes,trim(str1)]
  ENDWHILE
  free_lun,lin
  bibcodes=bibcodes[1:*]
ENDIF 

IF n_elements(html_file) EQ 0 THEN html_file='author.html'

;
; Here I check if the html file already exists. If yes, then I delete
; it. For some reason if I don't do this, then sometimes an
; empty file gets written.
;
chck=file_search(html_file,count=count)
IF count NE 0 THEN file_delete,html_file

;
; Create name of file containing list ordered by citations.
;
basename=file_basename(html_file,'.html')
out_file=basename+'_cit.html'
chck=file_search(out_file,count=count)
IF count NE 0 THEN file_delete,out_file


;
; This calls the ADS to retrieve information about the articles. Note
; that ads_data may contain less entries than bibcodes.
;
ads_data=cit_get_ads_entry(bibcodes,/remove_abstracts)


;
; Do some custom filtering of non-standard entries
;
chck=strpos(ads_data.bibcode,'EGUGA')
k=where(chck LT 0,nk)
IF nk NE 0 THEN ads_data=ads_data[k]
;
chck=strpos(ads_data.bibcode,'TESS')
k=where(chck LT 0,nk)
IF nk NE 0 THEN ads_data=ads_data[k]
;
chck=strpos(ads_data.bibcode,'cosp')
k=where(chck LT 0,nk)
IF nk NE 0 THEN ads_data=ads_data[k]
;
k=where(ads_data.doctype NE 'catalog',nk)
IF nk NE 0 THEN ads_data=ads_data[k]
;
k=where(ads_data.doctype NE 'software',nk)
IF nk NE 0 THEN ads_data=ads_data[k]
;
k=where(ads_data.doctype NE 'proposal',nk)
IF nk NE 0 THEN ads_data=ads_data[k]

;
; Remove any entries that are flagged in the remove_file
;
IF n_elements(remove_file) NE 0 THEN BEGIN
  str1=''
  openr,lrem,remove_file,/get_lun
  WHILE eof(lrem) NE 1 DO BEGIN
    readf,lrem,str1
    i=where(ads_data.bibcode NE trim(str1),ni)
    IF ni NE 0 THEN ads_data=ads_data[i]
  ENDWHILE
  free_lun,lrem
ENDIF


;
; Total number of papers
;
npapers=n_elements(ads_data)

;
; Get total citations
;
tot_cit=fix(total(ads_data.citation_count))

;
; Compute "h-index"
;
cit_list=fix(ads_data.citation_count)
j=reverse(sort(cit_list))
cit_list=cit_list[j]
nj=n_elements(j)
h_index=-1
i=0
WHILE h_index LT 0 AND i LT nj-1 DO BEGIN
  IF i+1 GT cit_list[i] THEN h_index=i
  i=i+1
ENDWHILE
IF h_index EQ -1 THEN h_index=nj   ; in case min(citations) > nj


;
; Get bibtex entries for all papers
;
; ***PRY getting bibtex entries for individual entries seems to be
; slow, so I thought to get them all in one call, but I need to work
; on this (use cit_bbl2str?)
;
;; bibtex=cit_get_ads_bibtex(ads_data.bibcode)
;; nb=n_elements(bibtex)
;; IF nb NE npapers THEN print,'***WARNING: bibtex size mismatch***'

;
; Check number of refereed articles.
;
refereed=bytarr(npapers)
FOR i=0,npapers-1 DO BEGIN
  np=n_elements(ads_data[i].property)
  swtch=0
  j=0
  WHILE swtch EQ 0 DO BEGIN
    IF trim(ads_data[i].property[j]) EQ 'REFEREED' THEN BEGIN
      refereed[i]=1b
      swtch=1
    ENDIF 
    j=j+1
    IF j EQ np THEN swtch=1
  ENDWHILE 
ENDFOR 
nref=total(refereed)


;
; Open the html file and write out the introduction text.
;
openw,lout,html_file,/get_lun
printf,lout,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"> '
;
; The line below makes sure that the characters in the strings are
; printed correctly.
;
printf,lout,'<meta charset="utf-8"/>'
;
printf,lout,'<html>'
printf,lout,'<head>'
printf,lout,'<title>Publications, '+name+'</title>'
printf,lout,'</head>'
printf,lout,'<body  bgcolor="#FFFFFF" vlink="#CC33CC">'
printf,lout,'<center>'
printf,lout,'<table border=0 cellpadding=0 cellspacing=0 width=700>'
printf,lout,'<tbody>'
printf,lout,'<tr><td height=30></td></tr>'
printf,lout,'<tr><td align=left>'
printf,lout,'<h1>Publications of '+name+'</h1>'
printf,lout,'<p>A list of publications authored or co-authored by '+name+', derived from the ADS Abstracts Service. The number in brackets after each title indicates the number of citations that the paper has received.</p>'
IF n_elements(ads_library) NE 0 THEN BEGIN
  printf,lout,'<p>This publication list is also maintained as an <a href="'+ads_library+'">ADS library</a>.</p>'
ENDIF 
printf,lout,'<p><a href="'+out_file+'">List of publications ordered by citations</a><br>'
printf,lout,'Number of papers: '+trim(npapers)+' (refereed: '+trim(nref)+')<br>'
printf,lout,'No. of citations: '+trim(tot_cit)+'<br>'
printf,lout,'<a href=http://en.wikipedia.org/wiki/H-index>h-index</a>: '+trim(h_index)


;
; Now go through each year and print out the entries for that year.
;
minyr=min(fix(ads_data.year))
maxyr=max(fix(ads_data.year))
;
FOR i=maxyr,minyr,-1 DO BEGIN
  k=where(fix(ads_data.year) EQ i,nk)
  IF nk GT 0 THEN BEGIN
    printf,lout,'<p><b>'+trim(i)+'</b></p>'
    printf,lout,'<ol>'
    auth=strarr(nk)
    FOR ia=0,nk-1 DO auth[ia]=ads_data[k[ia]].author[0]
    isort=sort(auth)
    FOR j=0,nk-1 DO BEGIN
      ii=k[isort[j]]
     ;
      IF ads_data[ii].page.count() EQ 0 THEN page_str='' ELSE page_str=ads_data[ii].page[0]
     ;
      swtch=0
     ;
     ; Based on the 'doctype' entry, I customize the output for
     ; articles, proceedings, etc.
     ;
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
          bibtex=cit_get_ads_bibtex(ads_data[ii].bibcode)
          info=cit_process_bibtex(bibtex)
          IF page_str EQ '' THEN page_str2='' ELSE page_str2=', p. '+page_str
          IF info.editor EQ '' THEN ed_str='' ELSE ed_str=' (Editors: '+info.editor+')'
          IF ads_data[ii].volume EQ '' THEN vol_str='' ELSE vol_str=', '+ads_data[ii].volume
          IF info.series EQ '' THEN ser_str='' ELSE ser_str=', '+info.series
         ;
          article_string=info.booktitle+ed_str+ser_str+vol_str+page_str2
        END 
       ;
        'phdthesis': BEGIN
          bibtex=cit_get_ads_bibtex(ads_data[ii].bibcode)
          info=cit_process_bibtex(bibtex)
          IF info.school NE '' THEN extra_str=' ('+info.school+')' ELSE extra_str=''
          article_string=ads_data[ii].pub+extra_str
        END
       ;
        'abstract': BEGIN
          swtch=1   ; this means these will get ignored.
        END
       ;
        'inbook': BEGIN
          article_string=ads_data[ii].pub
          bibtex=cit_get_ads_bibtex(ads_data[ii].bibcode)
          info=cit_process_bibtex(bibtex)
          IF info.editor NE '' THEN article_string=article_string+' (Editors: '+trim(info.editor)+')'
          article_string=article_string+', p.'+ads_data[ii].page[0]
        END 
       ;
        'book': BEGIN
          bibtex=cit_get_ads_bibtex(ads_data[ii].bibcode)
          info=cit_process_bibtex(bibtex)
          article_string=info.booktitle
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
     ;
      IF swtch NE 1 THEN BEGIN
        web_link='http://adsabs.harvard.edu/abs/'+ads_data[ii].bibcode
        citstr=' ['+trim(ads_data[ii].citation_count)+']'
       ;
       ; Note the title= entry creates "hover" text that displays if
       ; you leave the mouse hovering over the link. I set the hover
       ; text to be the abstract. I had to remove this as it caused a
       ; problem if the abstract contained html code.
       ;
        printf,lout,'<li><a href='+web_link+'>'+ads_data[ii].title[0]+'</a>'+citstr+'<br>'
     ;
        author_string=ads_data[ii].author[0]
        nauth=n_elements(ads_data[ii].author)
        IF nauth GT 1 THEN BEGIN 
          FOR ia=1,nauth-1 DO BEGIN
            IF ia EQ nauth-1 THEN sep_string=' & ' ELSE sep_string=', '
            author_string=author_string+sep_string+ads_data[ii].author[ia]
          ENDFOR
        ENDIF
     ;
        ads_data[ii].author_string=author_string
        ads_data[ii].article_string=article_string
        printf,lout,author_string+', '+article_string
        printf,lout,'</li>'
      ENDIF 
    ENDFOR
    printf,lout,'</ol></p>'
  ENDIF 
ENDFOR 



IF n_elements(author) NE 0 THEN BEGIN
  foot_text='<p><i>This page mantained by '
  IF keyword_set(link_author) THEN BEGIN
    foot_text=foot_text+ $
         '<a href='+link_author+'>'+author+'</a>'
  ENDIF ELSE BEGIN
    foot_text=foot_text+author
  ENDELSE
  foot_text=foot_text+', l'
ENDIF ELSE BEGIN
  foot_text='<p><i>L'
ENDELSE
foot_text=foot_text+'ast revised on '+systime()+'</i>'

printf,lout,'<p><hr>'
printf,lout,foot_text
printf,lout,'</p></td></tr></tbody></table></center></body></html>'

free_lun,lout


;
; Now print some information to the IDL window
;
print,html_file+' has been written.'
;
; Print
;
print,''
cit_list=ads_data.citation_count
i=where(cit_list GE 20,ni)
print,'Papers with 20 or more citations: '+trim(ni)
i=where(cit_list GE 30,ni)
print,'Papers with 30 or more citations: '+trim(ni)
i=where(cit_list GE 40,ni)
print,'Papers with 40 or more citations: '+trim(ni)
i=where(cit_list GE 50,ni)
print,'Papers with 50 or more citations: '+trim(ni)
;
;
; Print numbers of each publication type
;
noth=0
print,''
print,'Publication type:'
k=where(ads_data.doctype EQ 'article',nk)
print,'Journal: ',trim(nk)
noth=npapers-nk
k=where(ads_data.doctype EQ 'inbook',nk)
print,'Books: ',trim(nk)
noth=noth-nk
k=where(ads_data.doctype EQ 'inproceedings',nk)
print,'Proceedings: ',trim(nk)
noth=noth-nk
k=where(ads_data.doctype EQ 'eprint',nk)
print,'Preprints: ',trim(nk)
noth=noth-nk
print,'Other: ',trim(noth)
;
;
; Now get stats for first author papers. This requires the routine to
; the author's surname, hence the keyword 'surname'
;
IF n_elements(surname) NE 0 THEN BEGIN
  n_first=0
  n_first_ref=0
  FOR i=0,npapers-1 DO BEGIN
    chck=strpos(strlowcase(ads_data[i].author[0]),strlowcase(surname))
    IF chck GE 0 THEN BEGIN
      n_first=n_first+1
      IF refereed[i] EQ 1 THEN n_first_ref=n_first_ref+1
    ENDIF 
  ENDFOR
  print,''
  print,'No. of first author papers: ',trim(n_first)+'/'+trim(npapers)
  print,'No. of refereed articles: ',trim(nref)+'/'+trim(npapers)
  print,'No. of first author, refereed papers: ',trim(n_first_ref)+'/'+trim(nref)
ENDIF 


;
; Print out the second html file containing the most-cited papers.
;
i=reverse(sort(ads_data.citation_count))
;
; Open the html file and write out the introduction text.
;
outdir=file_dirname(html_file)
out_file=concat_dir(outdir,out_file)
openw,lout,out_file,/get_lun
printf,lout,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"> '
;
; The line below makes sure that the characters in the strings are
; printed correctly.
;
printf,lout,'<meta charset="utf-8"/>'
;
printf,lout,'<html>'
printf,lout,'<head>'
printf,lout,'<title>Publications ordered by citations, '+name+'</title>'
printf,lout,'</head>'
printf,lout,'<body  bgcolor="#FFFFFF" vlink="#CC33CC">'
printf,lout,'<center>'
printf,lout,'<table border=0 cellpadding=0 cellspacing=0 width=700>'
printf,lout,'<tbody>'
printf,lout,'<tr><td height=30></td></tr>'
printf,lout,'<tr><td align=left>'
printf,lout,'<h1>Publications of '+name+' ordered by citations</h1>'
printf,lout,'<p>A list of publications authored or co-authored by '+name+', derived from the ADS Abstracts Service and sorted by the numbers of citations.</p>'

printf,lout,'<p><table>'
FOR j=0,npapers-1 DO BEGIN
  k=i[j]
  cit_count=ads_data[k].citation_count
  IF cit_count GE h_index THEN BEGIN 
    printf,lout,'<tr>'
    printf,lout,'<td valign=top cellpadding=4><b>'+trim(cit_count)+'</b>'
    printf,lout,'<td><a href='+ads_data[k].ads_link+'>'+ads_data[k].title[0]+'</a><br>'
    printf,lout,ads_data[k].author_string+', '+ads_data[k].year+', '+ads_data[k].article_string
    printf,lout,'</tr>'
  ENDIF 
ENDFOR
printf,lout,'</table></p>'
printf,lout,'<p><hr>'
printf,lout,foot_text
printf,lout,'</p></td></tr></tbody></table></center></body></html>'

free_lun,lout

END
