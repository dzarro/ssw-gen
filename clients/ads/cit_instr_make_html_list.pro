
PRO cit_instr_make_html_list, ads_data, year, outdir=outdir, data_str=data_str, $
                              conference=conference, preprint=preprint, $
                              bib_flag=bib_flag, link=link, author=author, $
                              affil_file=affil_file

;+
; NAME:
;     CIT_INSTR_MAKE_HTML_LIST
;
; PURPOSE:
;     This routine creates the html file with the list of publications
;     by type for a single year.
;
; CATEGORY:
;     ADS; missions; webpage; publications.
;
; CALLING SEQUENCE:
;     CIT_INSTR_MAKE_HTML_LIST, Ads_Data, Year
;
; INPUTS:
;     Ads_Data:  A structure in the form returned by
;                CIT_GET_ADS_ENTRY.
;     Year:   The year (integer or string) for which publications will
;             be printed.
;     Data_Str: A structure containing the tags:
;                html_dir - directory where html will be written
;                instr_name - the name of the instrument
;
; OPTIONAL INPUTS:
;     Bib_Flag: A byte array of same size as ADS_DATA. Values of 1
;               indicate that the paper is new and the entry in the
;               html file will have a red "NEW!" appended to it.
;     Affil_File: The name of a file that maps affiliations to
;               countries. Normally the routine will fetch this file
;               from the internet or SSW, so this keyword is only if
;               you need a customized file.
;     Author:   If specified, then the routine will append the text to
;               the bottom of the page. It is intended that the author
;               of the page uses this to identify his/herself. For
;               example, AUTHOR='Dr. P.R. Young'.
;     Outdir:   The name of a directory to which the html file will be
;               printed. This is ignored if data_str.html_dir is
;               defined. 
;	
; KEYWORD PARAMETERS:
;     CONFERENCE: By default, the routine prints out only refereed
;                 journal articles from ADS_DATA. This keyword is used
;                 to instead print conference proceeding articles.
;     PREPRINT:   By default, the routine prints out only refereed
;                 journal articles from ADS_DATA. This keyword is used
;                 to instead print preprints.
;
; OUTPUTS:
;     An html file with the name
;        [INSTR]_publications_[TYPE]_[YEAR].html
;     will be written to the current working directory (or
;     OUTDIR). [TYPE] will be one of 'jour', 'conf' or 'prep' for
;     journals, conference proceedings or preprints.
;
; OPTIONAL OUTPUTS:
;     Link:   The name of the file that was output.
;
; EXAMPLE:
;     IDL> s=eis_pub_info()
;     IDL> cit_instr_make_html_list, ads_data, 2019, data_str=s
;
; PROGRAMMING NOTES:
;     Most users will not call this directly, but instead call
;     cit_instr_master_html. 
;
; MODIFICATION HISTORY:
;     Ver.1, 10-Sep-2019, Peter Young
;     Ver.2, 10-Jan-2020, Peter Young
;       Now catches case where a paper has no affiliations. 
;-


IF n_params() LT 2 THEN BEGIN
  print,'Use:  IDL> cit_instr_make_html_list, ads_data, year [, data_str=, bib_flag=, /conference'
  print,'                               /preprint, link=, affil_file=, author=, outdir= ] )'
  print,''
  print,'   Note that DATA_STR is a required input.'
  return
ENDIF 

instrument=data_str.instr_name

suffix='jour'
IF keyword_set(preprint) THEN suffix='prep'
IF keyword_set(conference) THEN suffix='conf'
;
file=strlowcase(instrument)+'_publications_'+suffix+'_'+trim(year)+'.html'

;
; The output directory is taken from data_str (if specified),
; otherwise, outdir is checked. 
;
IF tag_exist(data_str,'html_dir') THEN BEGIN
  file=concat_dir(data_str.html_dir,file)
ENDIF ELSE BEGIN
  IF n_elements(outdir) NE 0 THEN file=concat_dir(outdir,file)
ENDELSE 


CASE 1 OF
  keyword_set(preprint): subtitle='Pre-prints'
  keyword_set(conference): subtitle='Conference Proceedings/Technical Reports'
  ELSE: subtitle='Refereed Journal Articles'
ENDCASE


openw,lout,file,/get_lun

printf,lout,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"> '
;
; The line below makes sure that the characters in the strings are
; printed correctly.
;
printf,lout,'<meta charset="utf-8"/>'
;
printf,lout,'<html>'
printf,lout,'<head>'
printf,lout,'<title>'+strupcase(instrument)+' Publications in '+trim(year)+', '+subtitle+'</title>'
printf,lout,'</head>'
printf,lout,'<body  bgcolor="#FFFFFF" vlink="#CC33CC">'
printf,lout,'<center>'
printf,lout,'<table border=0 cellpadding=0 cellspacing=0 width=700>'
printf,lout,'<tbody>'
printf,lout,'<tr><td height=30></td></tr>'
printf,lout,'<tr><td align=left>'

printf,lout,'<h1>'
printf,lout,strupcase(instrument)+' Publications in '+trim(year)
printf,lout,'</h1>'


printf,lout,'<h2>'
printf,lout,subtitle
printf,lout,'</h2>'

printf,lout,"<p>The number in square brackets after the paper title is the number of citations the paper has received according to the <a href=https://ui.adsabs.harvard.edu/>NASA ADS Abstracts service</a>. The links take you through to the papers' listings at NASA ADS."

printf,lout,'<p><ol>'

n=n_elements(ads_data)
k=sort(ads_data.author_string)
adata=ads_data[k]
IF n_elements(bib_flag) NE 0 THEN bflag=bib_flag[k]
FOR i=0,n-1 DO BEGIN
  IF n_elements(bflag) NE 0 THEN BEGIN
    IF bflag[i] EQ 1 THEN add_str=' <font color=red>NEW!</font>' ELSE add_str=''
  ENDIF ELSE BEGIN
    add_str=''
  ENDELSE 
  printf,lout,'<li><a href="'+adata[i].ads_link+'">'+adata[i].title[0]+ $
         '</a> ['+trim(adata[i].citation_count)+']'+add_str+'<br>'+ $
         adata[i].author_string+', '+adata[i].article_string+'</li><p>'
ENDFOR
printf,lout,'</ol></p>'

;
; Now add table with affiliations for first authors
;
cit_affil_country,adata,/first,affil_file=affil_file
country=strarr(n)
FOR i=0,n-1 DO BEGIN
  IF adata[i].country.count() NE 0 THEN country[i]=adata[i].country[0]
ENDFOR 
k=where(country NE '',nk)
IF nk NE 0 THEN BEGIN 
  country=country[k]
  c=country[uniq(country,sort(country))]
;
  printf,lout,'<h2>Author-country information</h2>'
  printf,lout,'<p>This table shows the location of the first authors of the papers given above. The information is extracted from the affiliations of the authors stored in ADS. Of the '+trim(n)+' papers, '+trim(nk)+' affiliations could be extracted.</p>'
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
; Note that all the instrument html files are written to the same
; directory, so for the link I just need the filename (not the full
; html path).
;
link=file_basename(file)

END
