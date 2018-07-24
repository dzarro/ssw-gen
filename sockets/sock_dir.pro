;+
; Project     : VSO
;
; Name        : SOCK_DIR
;
; Purpose     : Perform directory listing of files at a URL 
;
; Category    : utility system sockets
;
; Syntax      : IDL> sock_dir,url,out_list
;
; Inputs      : URL = remote URL directory to list
;
; Outputs     : OUT_LIST = optional output variable to store list
;
; History     : 27-Dec-2009, Zarro (ADNET) - Written
;               16-Jul-2013, Zarro (ADNET) 
;               - Passed keywords thru to pertinent subroutines
;               6-Oct-2014, Zarro (ADNET) 
;               - ensured that input URL has '/' suffix as some
;                 servers require it for listings.
;               16-Sep-2016, Zarro (ADNET)
;               - added call to URL_FIX
;-

pro sock_dir,url,out_list,_ref_extra=extra

if ~is_url(url) then begin
 pr_syntax,'sock_dir,url,out_list'
 out_list=''
 return
endif

durl=url_fix(url,_extra=extra)
if ~stregex(durl,'/$',/bool) then durl=durl+'/'

if is_ftp(durl) then $
 sock_dir_ftp,durl,out_list,_extra=extra else $
  out_list=sock_find(durl,_extra=extra)

if (n_params() eq 1) then print,out_list
return & end
