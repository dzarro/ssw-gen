
PRO cit_author_html, bibcodes, bib_file=bib_file, html_file=html_file, $
                     name=name, ads_library=ads_library, $
                     author=author, ads_data=ads_data, remove_file=remove_file, $
                     link_author=link_author, surname=surname, $
                     self_cite_name=self_cite_name, $
                     out_data=out_data, quiet=quiet

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
;                is printed to the IDL screen). For authors with
;                multiple surnames (for example, a woman who changes
;                her name after getting married), SURNAME should be
;                given as a string array.
;     Ads_Library: This should be set to a URL pointing to an ADS
;                library containing the same publication list as the
;                html file. A link will be inserted in the html
;                pointing to this page.
;     Remove_file: This is the name of a file containing a list of
;                Bibcodes to be *removed* from the list contained in
;                Bibcodes. This can be useful if you have a common
;                name and want to keep a permanent list of wrong
;                matches.
;     Self_Cite_Name: This should be set to the surname of the
;                author. The routine will count the number of
;                self-citations and print the average self-citations
;                per paper to the html file. A self-citation is when a
;                paper in the author's publication list cites a
;                first-author paper of the author. WARNING: this slows
;                the routine down a lot!
;
; KEYWORD PARAMETERS:
;     QUIET:     If set, then no information is printed to IDL
;                window. 
;
; OPTIONAL OUTPUTS:
;     Ads_Data:  This is a structure containing the ADS data for each
;                Bibcode. The format is the same as that returned by
;                CIT_GET_ADS_ENTRY. 
;     Out_Data:  A structure containing the numbers that are printed
;                to the html file. The tags are:
;                 h_index: h-index
;                 n_first: no. of 1st author papers
;                 n_first_ref: no. of 1st author refereed papers
;                 n_papers: no. of papers
;                 n_cit: total citations
;                 start_year: year of first paper
;                 yr_last_paper: the year of the author's last
;                                first-author, refereed paper
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
;     CIT_GET_ADS_BIBTEX, CIT_FILL_STRINGS, CIT_BBL2STR
;
; EXAMPLE:
;      Search for an author in ADS, and save the output as bibtex. If
;      the file is called 'parker.bbl', then do:
;
;      IDL> str=cit_bib2str('parker.bbl')
;      IDL> cit_author_html,str.id,html_file='parker.html',name='Dr. E.N. Parker'
;
;      If you store the bibcodes in a text file called
;      'parker_bcodes.txt' in the working directory, then you can call
;      the routine as:
;
;      IDL> cit_author_html, surname='Parker'
;
;      The routine will automatically set bib_file='parker_bcodes.txt'
;      and it will also check if remove_file='parker_remove.txt'
;      exists. The author's name (NAME=) will be set to 'Dr. Parker'. 
;
; MODIFICATION HISTORY:
;      Ver.1, 12-Jul-2017, Peter Young
;      Ver.2, 26-Mar-2018, Peter Young
;        Now checks if the html file already exists and deletes it.
;      Ver.3, 6-Sep-2019, Peter Young
;        Updated web link to point to new ADS website.
;      Ver.4, 10-Sep-2019, Peter Young
;        Now calls cit_bbl2str to access bibtex information;
;        cit_fill_strings is now used to fill in the author and
;        article strings.
;      Ver.5, 16-Sep-2019, Peter Young
;        Added self_cite_name= optional input.
;      Ver.6, 19-Sep-2019, Peter Young
;        Number of first author papers is now printed to html file (if
;        surname is specified); added OUT_DATA optional output;
;        reduced information printed to IDL window; added /QUIET
;        keyword.
;      Ver.7, 28-Oct-2019, Peter Young
;        Fixed minor problem when counting refereed papers if
;        'property' is empty.
;      Ver.8, 12-Nov-2019, Peter Young
;        Fixed minor problem with h-index calculation.
;      Ver.9, 04-Mar-2020, Peter Young
;        SURNAME can be an array now.
;-



IF n_elements(bibcodes) EQ 0 AND n_elements(bib_file) EQ 0 AND n_elements(surname) EQ 0 THEN BEGIN
  print,'Use:  IDL> cit_author_html, bibcodes, [html_file=, bib_file=, name=, ads_library=, author='
  print,'                              ads_data=, remove_file=, surname=, self_cite_name=, out_data= ]'
  return
ENDIF 

;
; The following allows the inputs to cit_author_html to be simplified,
; but it requires the bib_file to exist.
;
; Note:
;  - a surname can have spaces (e.g., "Smith Jones"), so I removed the
;    spaces when creating the filenames below.
;  - surname can be an array, for example, if a woman gets married and
;    takes her partner's name. I use the first element of the
;    array (SNAME) for creating the filenames in this case.
;
IF n_elements(surname) NE 0 THEN BEGIN
  ns=n_elements(surname)
  sname=surname[0]
  IF n_elements(bib_file) EQ 0 AND n_elements(bibcodes) EQ 0 THEN bib_file=strlowcase(strcompress(sname,/remove_all))+'_bcodes.txt'
  IF n_elements(remove_file) EQ 0 THEN remove_file=strlowcase(strcompress(sname,/remove_all))+'_remove.txt'
  IF n_elements(html_file) EQ 0 THEN html_file=strlowcase(strcompress(sname,/remove_all))+'.html'
  IF n_elements(name) EQ 0 THEN name='Dr. '+sname
ENDIF 

IF n_elements(name) EQ 0 THEN BEGIN
  name='the Author'
  print,"% CIT_AUTHOR_HTML: use the keyword NAME= to specify the author's name"
ENDIF


;
; Check if the user has an ADS key.
;
chck=cit_get_ads_key(status=status,/quiet)
IF status EQ 0 THEN BEGIN
  print,'% CIT_AUTHOR_HTML: You do not have an ADS key. Please check the webpage'
  print,'    https://pyoung.org/quick_guides/ads_idl_query.html'
  print,'for how to get one.'
  return
ENDIF 

IF n_elements(bib_file) NE 0 THEN BEGIN
  chck=file_search(bib_file,count=count)
  IF count EQ 0 THEN BEGIN
    print,'% CIT_AUTHOR_HTML: The specified bib_file does not exist. Returning...'
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
; The cit_fill_strings routine fills the "author_string" and
; "article_string" tags, which are used when writing out the html
; entries. 
;
ads_data=cit_get_ads_entry(bibcodes,/remove_abstracts)
cit_fill_strings,ads_data


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
  chck=file_info(remove_file)
  IF chck.exists EQ 1 THEN BEGIN 
    str1=''
    openr,lrem,remove_file,/get_lun
    WHILE eof(lrem) NE 1 DO BEGIN
      readf,lrem,str1
      i=where(ads_data.bibcode NE trim(str1),ni)
      IF ni NE 0 THEN ads_data=ads_data[i]
    ENDWHILE
    free_lun,lrem
  ENDIF 
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
WHILE h_index LT 0 AND i LE nj-1 DO BEGIN
  IF i+1 GT cit_list[i] THEN h_index=i
  i=i+1
ENDWHILE
IF h_index EQ -1 THEN h_index=nj   ; in case min(citations) > nj


;
; Some information related to conference proceedings is not obtained
; with cit_get_ads_entry, so I need to access it from the bibtex
; entries. It's quicker to get all the bibtex in one go rather
; than for individual entries, so I get them here and convert to a
; structure. 
;
bibtex=cit_get_ads_bibtex(ads_data.bibcode)
bibstr=cit_bbl2str(bib_strarr=bibtex)

;
; Check number of refereed articles.
;
refereed=bytarr(npapers)
FOR i=0,npapers-1 DO BEGIN
  np=ads_data[i].property.count()
  swtch=0
  j=0
  IF np NE 0 THEN BEGIN 
    WHILE swtch EQ 0 DO BEGIN
      IF trim(ads_data[i].property[j]) EQ 'REFEREED' THEN BEGIN
        refereed[i]=1b
        swtch=1
      ENDIF 
      j=j+1
      IF j EQ np THEN swtch=1
    ENDWHILE
  ENDIF 
ENDFOR 
nref=total(refereed)

;
;
; Now get stats for first author papers. This requires the routine to
; know the author's surname, hence the keyword 'surname'
;
IF n_elements(surname) NE 0 THEN BEGIN
  yr_last_paper=1900
  n_first=0
  n_first_ref=0
  ns=n_elements(surname)
  FOR i=0,npapers-1 DO BEGIN
    swtch=0b
    FOR j=0,ns-1 DO BEGIN
      chck=strpos(strlowcase(ads_data[i].author[0]),strlowcase(surname[j]))
      IF chck GE 0 AND swtch EQ 0 THEN BEGIN
        n_first=n_first+1
        IF refereed[i] EQ 1 THEN BEGIN
          n_first_ref=n_first_ref+1
          IF fix(ads_data[i].year) GT yr_last_paper THEN yr_last_paper=fix(ads_data[i].year)
        ENDIF
        swtch=1b
      ENDIF
    ENDFOR 
  ENDFOR
ENDIF 


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
IF n_elements(n_first) NE 0 THEN BEGIN
  printf,lout,'First author papers: '+trim(n_first)+' (refereed: '+trim(n_first_ref)+')<br>'
ENDIF 
printf,lout,'No. of citations: '+trim(tot_cit)+'<br>'
printf,lout,'<a href=http://en.wikipedia.org/wiki/H-index>h-index</a>: '+trim(h_index)+'<br>'
;
; The following does a check on self-citation. For each publication in
; the author's list, the routine downloads the citing papers
; and checks if the first author matches the surname given by
; SELF_CITE_NAME. The author's "self-citation index" is the
; number of self-citations per paper. I only include refereed journal
; articles (doctype='article').
;
IF n_elements(self_cite_name) THEN BEGIN
  k=where(ads_data.doctype EQ 'article',nk)
  ad=ads_data[k]
  self_cite=intarr(nk)
  npap=nk
  FOR i=0,nk-1 DO BEGIN
    bibs=cit_get_citing_papers(ad[i].bibcode)
    s=cit_get_ads_entry(bibs)
    IF n_tags(s) NE 0 THEN BEGIN 
      ns=n_elements(s)
      count=0
      FOR j=0,ns-1 DO BEGIN
        IF s[j].author.count() GT 0 THEN BEGIN
          chck=strpos(strlowcase(s[j].author[0]),strlowcase(self_cite_name))
          IF chck GE 0 THEN count=count+1
        ENDIF 
      ENDFOR
    ENDIF ELSE BEGIN
      npap=npap-1   ; removed bad paper
    ENDELSE 
    self_cite[i]=count
  ENDFOR
  nsc=float(total(self_cite))/float(npap)
  printf,lout,'Self-citations: '+trim(string(format='(f7.2)',nsc))+' per paper'
ENDIF 

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
      web_link='https://ui.adsabs.harvard.edu/abs/'+ads_data[ii].bibcode
      citstr=' ['+trim(ads_data[ii].citation_count)+']'
      printf,lout,'<li><a href='+web_link+'>'+ads_data[ii].title[0]+'</a>'+citstr+'<br>'
     ;
      printf,lout,ads_data[ii].author_string+', '+ads_data[ii].article_string
      printf,lout,'</li>'
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
IF NOT keyword_set(quiet) THEN print,html_file+' has been written.'


;
;
; Now get stats for first author papers. This requires the routine to
; the author's surname, hence the keyword 'surname'
;
;; IF n_elements(surname) NE 0 THEN BEGIN
;;   n_first=0
;;   n_first_ref=0
;;   FOR i=0,npapers-1 DO BEGIN
;;     FOR j=0,ns-1
;;     chck=strpos(strlowcase(ads_data[i].author[0]),strlowcase(surname))
;;     IF chck GE 0 THEN BEGIN
;;       n_first=n_first+1
;;       IF refereed[i] EQ 1 THEN n_first_ref=n_first_ref+1
;;     ENDIF 
;;   ENDFOR
;; ENDIF 


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

;
; Create the output data structure.
;
IF n_elements(n_first) EQ 0 THEN n_first=-1
IF n_elements(n_first_ref) EQ 0 THEN n_first_ref=-1
IF n_elements(yr_last_paper) EQ 0 THEN yr_last_paper=-1
out_data={ h_index: h_index, $
           n_first: n_first, $
           n_first_ref: n_first_ref, $
           n_papers: npapers, $
           n_papers_ref: nref, $
           n_cit: tot_cit, $
           start_year: min(fix(ads_data.year)), $
           yr_last_paper: yr_last_paper}
           

END
