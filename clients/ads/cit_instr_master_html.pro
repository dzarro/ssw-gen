
PRO cit_instr_master_html, data_str, author=author, affil_file=affil_file, all_pubs=all_pubs, $
                           link_author=link_author


;+
; NAME:
;     CIT_INSTR_MASTER_HTML
;
; PURPOSE:
;     Creates html files containing publication information for a
;     mission or instrument.
;
; CATEGORY:
;     ADS; citations.
;
; CALLING SEQUENCE:
;     CIT_INSTR_MASTER_HTML
;
; INPUTS:
;     Data_Str:  A structure containing information related to the
;                mission/instrument. See the routine eis_pub_info.pro
;                for an example. 
;
; OPTIONAL INPUTS:
;     Author:    A string identifying the "author" of the html
;                files. The name will be appended to the bottom of the
;                html files.
;     Link_Author: A string specifying a URL that is used to provide a
;                  link associated with the author's name.
;     Affil_File: The name of a text file that maps affiliation
;                 sub-strings to countries. If not specified, then the
;                 routine will use the file at
;                 http://files.pyoung.org/idl/ads/cit_affil_country.txt.
;     
; OUTPUTS:
;     The routine will write a number of html files to the directory
;     data_str.html_dir. The main file is
;     [INSTRUMENT]_publications_summary.html, where [INSTRUMENT] is
;     data_str.instr_name. 
;
; OPTIONAL OUTPUTS:
;     All_Pubs:  A structure in the format returned by
;                cit_get_ads_entry containing all the publications
;                that were printed to the html files.
;
; EXAMPLE:
;     See the webpage
;     https://pyoung.org/quick_guides/mission_pub_lists.html for how
;     to use this routine.
;
; MODIFICATION HISTORY:
;     Ver.1, 2-Oct-2019, Peter Young
;     Ver.2, 1-Nov-2019, Peter Young
;        Modified how htmlfile is input to cit_instr_most_cited and
;        cit_instr_all_papers.
;     Ver.3, 10-Jan-2020, Peter Young
;        Now saves the ADS data structure in html_dir/ads_data/; added
;        extra section on webpage giving results of abstract keyword
;        searches; switched "preprint" to "other" and now include
;        "inbook" in the conference proceedings.
;        
;-

IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> cit_instr_master_html, data_str [, author=, link_author=, affil_file= ]'
  print,''
  print,'  Please check the routine eis_pub_info.pro for how to format DATA_STR.'
  return
ENDIF 


instr=data_str.instr_name
outdir=data_str.html_dir
bib_save_dir=data_str.bib_save_dir

;
; Get a list of the bibcode list files (that should have been
; previously created with cit_instr_check_year.pro.
;
list=file_search(concat_dir(bib_save_dir,'bibcode_list_*.txt'),count=n)

;
; This is the name of the master file that summarizes the publication
; information. 
;
outfile=instr+'_publications_summary.html'
IF n_elements(outdir) NE 0 THEN outfile=concat_dir(outdir,outfile)
openw,lout,outfile,/get_lun

;
; Make a directory to store the ADS data structures.
;
data_dir=concat_dir(bib_save_dir,'ads_data')
chck=file_info(data_dir)
IF chck.exists EQ 0 THEN BEGIN
  file_mkdir,data_dir
  print,'% CIT_INSTR_MASTER_HTML: created directory '+data_dir
ENDIF 
chck=file_search(data_dir,'*.save',count=count)
IF count NE 0 THEN file_delete,chck


printf,lout,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"> '
;
; The line below makes sure that the characters in the strings are
; printed correctly.
;
printf,lout,'<meta charset="utf-8"/>'
;
printf,lout,'<html>'
printf,lout,'<head>'
printf,lout,'<title>'+strupcase(instr)+' publications summary</title>'
printf,lout,'</head>'
printf,lout,'<body  bgcolor="#FFFFFF" vlink="#CC33CC">'
printf,lout,'<center>'
printf,lout,'<table border=0 cellpadding=0 cellspacing=0 width=700>'
printf,lout,'<tbody>'
printf,lout,'<tr><td height=30></td></tr>'
printf,lout,'<tr><td align=left>'



printf,lout,'<h1>'+strupcase(instr)+' publications summary</h1>'
printf,lout,'<p>The table below gives the number of '+strupcase(instr)+'-related publications separated into publication type (refereed journal articles, conference proceedings/technical reports, and preprints) and year. Clicking on the links will give the list of publications for that publication type and year. Also given are the numbers of citations for the '+strupcase(instr)+' papers.'

printf,lout,'<p align=center><table border=1 cellpadding=3>'
printf,lout,'<tr>'
printf,lout,'<td rowspan=2><b>YEAR</b>'
printf,lout,'<td colspan=4 align=center><b>No. of publications</b>'
printf,lout,'<td rowspan=2><b>Citations</b>'
printf,lout,'</tr>'
printf,lout,'<tr>'
printf,lout,'<td><b>Total</b>'
printf,lout,'<td><b>Journals</b>'
printf,lout,'<td><b>Conf. Proc.</b>'
printf,lout,'<td><b>Other</b>'

ncit=intarr(n)
ntot=intarr(n)
njour=intarr(n)
nconf=intarr(n)
nprep=intarr(n)
junk=temporary(all_pubs)
junk=temporary(all_flags)

;
; This is a loop over the bibcode list files.
;
FOR i=0,n-1 DO BEGIN
  openr,lin,list[i],/get_lun
  year=strmid(file_basename(list[i]),13,4)
  str1=''
  flag=''
  biblist=''
  bib_flag=-1
  WHILE eof(lin) NE 1 DO BEGIN
    readf,lin,str1,flag,format='(a19,a1)'
    IF trim(str1) NE '' THEN BEGIN
      biblist=[biblist,trim(str1)]
      IF flag EQ '*' THEN bib_flag=[bib_flag,1] ELSE bib_flag=[bib_flag,0]
    ENDIF 
  ENDWHILE 
  free_lun,lin
  biblist=biblist[1:*]
  bib_flag=bib_flag[1:*]
 ;
 ; Here I fetch the publication information from the bibcode list.
 ; I catch any bad bibcodes (i.e., bibcodes that don't have
 ; entries at ADS) and print them out so the user can check them.
 ;
  a=cit_get_ads_entry(biblist,bad_bibcodes=bad_bibcodes,/quiet)
  IF n_tags(a) EQ 0 THEN continue
 ;
  IF n_elements(bad_bibcodes) NE 0 THEN BEGIN
    print,'**Bad bibcodes for '+trim(year)
    FOR j=0,n_elements(bad_bibcodes)-1 DO print,bad_bibcodes[j]
  ENDIF 
  cit_fill_strings,a
 ;
  ntot[i]=n_elements(a)
  printf,lout,'<tr>'
  printf,lout,'<td><b>'+trim(year)+'</b>'
  printf,lout,'<td align=right><b>'+trim(ntot[i])+'</b>'
 ;
 ; Process refereed articles (doctype='article')
 ;
  k=where(a.doctype EQ 'article',nk)
  njour[i]=nk
  IF nk NE 0 THEN BEGIN
    cit_instr_make_html_list,a[k],year,bib_flag=bib_flag,outdir=outdir, link=link, $
                             data_str=data_str, affil_file=affil_file
    printf,lout,'<td align=right><a href="'+link+'"</a>'+trim(n_elements(a[k]))+'</a>'
  ENDIF ELSE BEGIN
    printf,lout,'<td align=right>'+trim(0)
  ENDELSE
 ;
 ; Process conference proceedings (doctype='inproceedings')
 ;
  k=where(a.doctype EQ 'inproceedings' OR a.doctype EQ 'inbook',nk)
  nconf[i]=nk
  IF nk NE 0 THEN BEGIN
    cit_instr_make_html_list,a[k],year,bib_flag=bib_flag,outdir=outdir, link=link,  $
                             data_str=data_str, /conference, affil_file=affil_file
    printf,lout,'<td align=right><a href="'+link+'"</a>'+trim(n_elements(a[k]))+'</a>'
  ENDIF ELSE BEGIN
    printf,lout,'<td align=right>'+trim(0)
  ENDELSE
 ;
 ; I've switched this from preprint to other, so everything
 ; except for the above two types. I'm printing the doctype in
 ; case there are any surprises.
 ;
  k=where(a.doctype NE 'article' AND a.doctype NE 'inproceedings' AND a.doctype NE 'inbook',nk)
;  k=where(a.doctype EQ 'eprint',nk)
  nprep[i]=nk
  IF nk NE 0 THEN BEGIN
    print,'  - note: "Other" article doctype: ',a[k].doctype
    cit_instr_make_html_list,a[k],year,bib_flag=bib_flag,outdir=outdir, link=link,  $
                             data_str=data_str, /preprint, affil_file=affil_file
    printf,lout,'<td align=right><a href="'+link+'"</a>'+trim(n_elements(a[k]))+'</a>'
  ENDIF ELSE BEGIN
    printf,lout,'<td align=right>'+trim(0)
  ENDELSE
 ;
 ; Write the total citations in the final column.
 ;
  ncit[i]=total(a.citation_count)
  printf,lout,'<td align=right>'+trim(ncit[i])+'</td>'
  printf,lout,'</tr>'
 ;
  print,'% CIT_INSTR_MASTER_HTML: completed results for '+trim(year)+'.'
 ;
  IF n_elements(all_pubs) EQ 0 THEN all_pubs=a ELSE all_pubs=[all_pubs,a]
  IF n_elements(all_flags) EQ 0 THEN all_flags=bib_flag ELSE all_flags=[all_flags,bib_flag]
ENDFOR

;
; Complete the table by adding the sums of papers and citations. 
;
printf,lout,'<tr>'
printf,lout,'<td><b>TOTAL</b>'
printf,lout,'<td align=right><b>'+trim(total(ntot))+'</b>'
printf,lout,'<td align=right>'+trim(total(njour))
printf,lout,'<td align=right>'+trim(total(nconf))
printf,lout,'<td align=right>'+trim(total(nprep))
printf,lout,'<td align=right>'+trim(total(ncit))
printf,lout,'</tr>'
printf,lout,'</table>'

;
; Create the page containing every EIS paper, sorted by year
;
biglist_file=strlowcase(instr)+'_big_list.html'
cit_instr_all_papers,all_pubs,data_str=data_str,bib_flag=all_flags,htmlfile=biglist_file

cite_file=strlowcase(instr)+'_citations_list.html'
cit_instr_most_cited, all_pubs,npapers,data_str=data_str,htmlfile=cite_file

printf,lout,'<p>Additional '+strupcase(instr)+' publication information:'
printf,lout,'<ul>'
printf,lout,'<li><a href="'+file_basename(biglist_file)+'">Complete list of '+strupcase(instr)+' publications sorted by year.</a></p>'
printf,lout,'<li><a href="'+file_basename(cite_file)+'">The '+trim(npapers)+' most highly-cited '+strupcase(instr)+' papers.</a></p>'
printf,lout,'</ul>'


;
; Now add table with affiliations for first authors
;
n=n_elements(all_pubs)
cit_affil_country,all_pubs,/first
country=strarr(n)
FOR i=0,n-1 DO BEGIN
  IF all_pubs[i].country.count() NE 0 THEN country[i]=all_pubs[i].country[0]
ENDFOR 
k=where(country NE '',nk)
IF nk NE 0 THEN BEGIN 
  country=country[k]
  c=country[uniq(country,sort(country))]
;
  printf,lout,'<h2>Author-country information</h2>'
  printf,lout,'<p>This table shows the location of the first authors of the papers. The information is extracted from the affiliations of the authors stored in ADS. Of the '+trim(n)+' papers, '+trim(nk)+' affiliations could be extracted.</p>'
  printf,lout,'<p align=center><table border=1 cellpadding=3>'
  printf,lout,'<tr><td><b>Country</td><td><b>First author papers</td></tr>'
  nc=n_elements(c)
  c_num=intarr(nc)
  FOR i=0,nc-1 DO BEGIN
    k=where(country EQ c[i],nk)
    c_num[i]=nk
  ENDFOR
  i=reverse(sort(c_num))
  c=c[i]
  c_num=c_num[i]
  FOR i=0,nc-1 DO BEGIN 
    printf,lout,'<tr><td>'+c[i]+'</td><td align=center>'+trim(c_num[i])+'</td></tr>'
  ENDFOR 
  printf,lout,'</table></p>'
ENDIF 

;
; This section adds links to keywords to the publication page.
;
IF tag_exist(data_str,'keywords') THEN BEGIN
  keyword_exist=data_str.keywords.count()
  IF keyword_exist THEN BEGIN
    printf,lout,'<h2>Abstract keyword search</h2>'
    printf,lout,'<p>The following links give lists of papers that have the listed keywords in their abstracts. This can be a useful way for finding papers on a specific topic. Only refereed papers are listed.</p>'
    printf,lout,'<p><ul>'
   ;
    keywords=data_str.keywords[0]
    nkey=n_elements(keywords)
    k=where(all_pubs.doctype EQ 'article')
    all_pubs_ref=all_pubs[k]
    FOR i=0,nkey-1 DO BEGIN
      chck=strpos(strlowcase(all_pubs_ref.abstract),strlowcase(keywords[i]))
      j=where(chck GE 0,nj)
      outfile=strlowcase(instr)+'_'+strcompress(strlowcase(keywords[i]),/rem)+'.html'
      IF nj NE 0 THEN BEGIN
        cit_instr_all_papers,all_pubs_ref[j],data_str=data_str,htmlfile=outfile,keyword_text=keywords[i]
      ENDIF
      printf,lout,'<li><a href="'+file_basename(outfile)+'">'+keywords[i]+'</a></li>'
    ENDFOR
    printf,lout,'</ul></p>'
  ENDIF 
ENDIF 

;
; Save ADS data to the data_dir directory.
;
ads_data_file='ads_data.save'
ads_data_file=concat_dir(data_dir,ads_data_file)
ads_data=all_pubs
save,file=ads_data_file,ads_data
junk=temporary(ads_data)


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



END
