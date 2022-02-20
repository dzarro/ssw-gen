
PRO cit_instr_all_papers, all_pubs, data_str=data_str, bib_flag=bib_flag, $
                          htmlfile=htmlfile, add_year=add_year, instr_name=instr_name, $
                          keyword_text=keyword_text

;+
; NAME:
;     CIT_INSTR_ALL_PAPERS
;
; PURPOSE:
;     Creates a html page containing all of the publications listed in
;     ALL_PUBS, sorted by year and alphabetically (first author).
;
; CATEGORY:
;     ADS; citations; webpage.
;
; CALLING SEQUENCE:
;     CIT_INSTR_ALL_PAPERS, All_Pubs.
;
; INPUTS:
;     All_Pubs:  A Structure in the format produced by
;                cit_get_ads_entry containing all of the papers to be
;                written to the html file. Note that the structure
;                needs to have been processed with cit_fill_strings
;                prior to calling.
;
; OPTIONAL INPUTS:
;     Data_Str:  A structure containing information about the
;                mission/instrument. See the routine eis_pub_info.pro
;                for an example of the format. The only tag used here
;                is 'instr_name'.
;     Instr_Name: The name of the instrument to be used in the html
;                 output file. This is an alternative to specifying
;                 the name with DATA_STR.
;     Bib_Flag:  A byte array of same size as ALL_PUBS. If an entry is
;                set to 1 then the corresponding paper in ALL_PUBS
;                will have "NEW!" in red letters printed next to it.
;     HtmlFile:  The name of the output html file. If not specified,
;                then it is set to [INSTR_NAME]_big_list.html. If
;                data_str.html_dir exists, then the file will be sent
;                to this directory.
;     Keyword_Text: If the data_str.keywords tag exists, then
;                sub-lists of publications corresponding to the
;                keywords will be generated. By using the input
;                keyword_text, the keyword will be added to the html
;                page title.
;	
; KEYWORD PARAMETERS:
;     ADD_YEAR:  By default the routine doesn't print the year
;                for each paper, so this keyword adds it to each
;                entry. 
;
; OUTPUTS:
;     The file HTMLFILE is written either to the current working
;     directory, or to DATA_STR.HTML_DIR (if specified).
;
; EXAMPLE:
;     The following takes the papers that cite the Hinode/EIS
;     instrument paper and creates a html file from them. The file
;     will have the name 'eis_big_list.html'.
;
;     IDL> bcodes=cit_get_citing_papers('2007SoPh..243...19C')
;     IDL> s=cit_get_ads_entry(bcodes)
;     IDL> cit_fill_strings,s
;     IDL> cit_instr_all_papers,s,instr_name='EIS'
;
; MODIFICATION HISTORY:
;     Ver.1, 2-Oct-2019, Peter Young
;     Ver.2, 14-Jan-2020, Peter Young
;        Added keyword_text optional input.
;-

IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> cit_instr_all_papers, ads_data [, instr_name=, data_str=, bib_flag=, htmlfile='
  print,'                                 /add_year, keyword_text= ]'
  return
ENDIF 

IF n_tags(data_str) NE 0 THEN instr=data_str.instr_name
IF n_elements(instr_name) NE 0 THEN instr=instr_name
IF n_elements(instr) EQ 0 THEN BEGIN
  print,'% CIT_INSTR_ALL_PAPERS: please specify the instrument name either with INSTR_NAME= or the DATA_STR= structure. Returning...'
  return
ENDIF 


;
; If htmlfile not specified, then create it.
;
IF n_elements(htmlfile) EQ 0 THEN htmlfile=strlowcase(instr)+'_big_list.html'
IF n_tags(data_str) NE 0 THEN BEGIN
  IF tag_exist(data_str,'html_dir') THEN htmlfile=concat_dir(data_str.html_dir,htmlfile)
ENDIF 

IF n_elements(keyword_text) NE 0 THEN add_text='(keyword: '+keyword_text+')' ELSE add_text=''


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
printf,lout,'<title>List of all '+strupcase(instr)+' publications '+add_text+'</title>'
printf,lout,'</head>'
printf,lout,'<body  bgcolor="#FFFFFF" vlink="#CC33CC">'
printf,lout,'<center>'
printf,lout,'<table border=0 cellpadding=0 cellspacing=0 width=800>'
printf,lout,'<tbody>'
printf,lout,'<tr><td height=30></td></tr>'
printf,lout,'<tr><td align=left>'

printf,lout,'<h1>Full list of '+instr+' publicatons '+add_text+'</h1>'

printf,lout,'<p>Compiled from information held in the <a href="https://ui.adsabs.harvard.edu/">ADS abstracts service</a>.</p>'

printf,lout,'Total number of papers: <b>'+trim(n_elements(all_pubs))+'</b>'

yr=float(all_pubs.year)
yrmin=min(yr)
yrmax=max(yr)

FOR yr=yrmax,yrmin,-1 DO BEGIN
  k=where(all_pubs.year EQ trim(yr),nk)
  IF nk NE 0 THEN BEGIN
    printf,lout,'<p><b>'+trim(yr)+'</b></p>'
    printf,lout,'<ol>'
    adata=all_pubs[k]
    i=sort(adata.author_string)
    adata=adata[i]
    IF n_elements(bib_flag) NE 0 THEN BEGIN
      bflag=bib_flag[k]
      bflag=bflag[i]
    ENDIF
   ;
    FOR i=0,nk-1 DO BEGIN
      add_str=''
      IF n_elements(bflag) NE 0 THEN BEGIN
        IF bflag[i] EQ 1 THEN add_str=' <font color=red>NEW!</font>' 
      ENDIF
      IF keyword_set(add_year) THEN yr_str=' '+trim(yr) ELSE yr_str=''
      printf,lout,'<li><a href="'+adata[i].ads_link+'">'+adata[i].title[0]+ $
             '</a> ['+trim(adata[i].citation_count)+']'+add_str+'<br>'+ $
             adata[i].author_string+yr_str+', '+adata[i].article_string+'</li><p>'
    ENDFOR
    printf,lout,'</ol>'
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

END
