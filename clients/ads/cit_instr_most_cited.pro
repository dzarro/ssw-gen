
PRO cit_instr_most_cited, all_pubs, npapers, data_str=data_str, htmlfile=htmlfile, $
                          instr_name=instr_name, author=author, link_author=link_author 

;+
; NAME:
;     CIT_INSTR_MOST_CITED
;
; PURPOSE:
;     Produce a html file containing a list of the most-cited papers
;     in the list stored in ALL_PUBS.
;
; CATEGORY:
;     ADS; output; html
;
; CALLING SEQUENCE:
;     CIT_INSTR_MOST_CITED, All_Pubs
;
; INPUTS:
;     All_Pubs:  A structure in the format returned by
;                CIT_GET_ADS_ENTRY, containing the full list of
;                publications from which the most cited will be
;                taken. 
;
; OPTIONAL INPUTS:
;     Npapers:   The number of papers to include in the list. The
;                default is 10% of the size of ALL_PUBS.
;     Data_Str:  A structure that must contain the tag
;                INSTR_NAME. This is the name of the instrument
;                associated with the group of papers.
;     HtmlFile:  The name of the output html file. The default is
;                'most_cited.html'. 
;     Author:    The name of the person who created the file, which is
;                placed in the footer of the html file.
;     Link_Author: This is used to assign a link to the
;                  author's name in the footer.
;	
; OUTPUTS:
;     Creates an html file containing an ordered list of the most
;     cited papers from those contained in ALL_PUBS.
;
; EXAMPLE:
;     IDL> b=cit_get_citing_papers('2007SoPh..243...19C')
;     IDL> s=cit_get_ads_entry(b)
;     IDL> cit_fill_strings,s
;     IDL> cit_instr_most_cited,s,instr_name='EIS'
;
; MODIFICATION HISTORY:
;     Ver.1, 17-Sep-2019, Peter Young
;     Ver.2, 1-Nov-2019, Peter Young
;       Modified how htmlfile input is handled.
;-


IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> cit_instr_most_cited, ads_data [, npapers=, data_str=, htmlfile=, author= '
  print,'                                 link_author= ]'
  return
ENDIF 

IF n_elements(instr_name) THEN BEGIN
  instr=instr_name
ENDIF ELSE BEGIN
  IF n_tags(data_str) NE 0 THEN instr=data_str.instr_name
ENDELSE
;
IF n_elements(instr) EQ 0 THEN BEGIN
  print,'% CIT_INSTR_MOST_CITED: please specify an instrument name with INSTR_NAME= or DATA_STR=. Returning...'
  return
ENDIF 


;
; If htmlfile not specified, then create it.
;
IF n_elements(htmlfile) EQ 0 THEN htmlfile=strlowcase(instr)+'_most_cited.html'
IF n_tags(data_str) NE 0 THEN BEGIN
  IF tag_exist(data_str,'html_dir') THEN htmlfile=concat_dir(data_str.html_dir,htmlfile)
ENDIF 


;
; This works out how many papers to show if NPAPERS not specified. 
;
IF n_elements(npapers) EQ 0 THEN BEGIN 
  npapers=(n_elements(all_pubs)/100)*10
  IF npapers LT 20 THEN npapers=min([20,n_elements(all_pubs)])
ENDIF 

IF n_elements(npapers) EQ 0 THEN npapers=min([20,n_elements(all_pubs)])

openw,lout,htmlfile,/get_lun

printf,lout,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"> '
;
; The line below makes sure that the characters in the strings are
; printed correctly.
;
printf,lout,'<meta charset="utf-8"/>'
;
printf,lout,'<html>'
printf,lout,'<head>'
printf,lout,'<title>List of all '+strupcase(instr)+' publications</title>'
printf,lout,'</head>'
printf,lout,'<body  bgcolor="#FFFFFF" vlink="#CC33CC">'
printf,lout,'<center>'
printf,lout,'<table border=0 cellpadding=0 cellspacing=0 width=700>'
printf,lout,'<tbody>'
printf,lout,'<tr><td height=30></td></tr>'
printf,lout,'<tr><td align=left>'

printf,lout,'<h1>Most cited '+instr+' papers</h1>'

printf,lout,"<p>This page gives a list of the "+trim(npapers)+" most highly-cited "+instr+" papers. The citation information comes from the NASA ADS Abstracts service. The links take you through to the papers' listings at NASA ADS.</p>"

i=reverse(sort(all_pubs.citation_count))
adata=all_pubs[i]
adata=adata[0:npapers-1]

printf,lout,'<p><table>'
FOR i=0,npapers-1 DO BEGIN
  printf,lout,'<tr>'
  printf,lout,'<td valign=top cellpadding=4><b>'+trim(adata[i].citation_count)+'</b>'
  printf,lout,'<td><a href='+adata[i].ads_link+'>'+adata[i].title[0]+'</a><br>'
  printf,lout,adata[i].author_string+', '+adata[i].year+', '+adata[i].article_string
  printf,lout,'</tr>'
ENDFOR 
printf,lout,'</table></p>'

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

print,'% CIT_INSTR_MOST_CITED: the most-cited papers have been written to the file'
print,'                        '+htmlfile

END
