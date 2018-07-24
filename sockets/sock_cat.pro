;+
; Project     : HESSI
;
; Name        : SOCK_CAT
;
; Purpose     : list remote WWW page via sockets
;
; Category    : utility system sockets
;
; Syntax      : IDL> sock_cat,url,page
;                  
; Inputs      : URL = URL path to list [e.g. www.cnn.com]
;
; Opt. Outputs: PAGE= captured HTML 
;
; Keywords    : ERR   = string error message
;
; History     : 27-Dec-2001,  D.M. Zarro (EITI/GSFC)  Written
;               26-Dec-2003, Zarro (L-3Com/GSFC) - added FTP capability
;               23-Dec-2005, Zarro (L-3Com/GSFC) - removed COMMON
;               27-Dec-2009, Zarro (ADNET)
;                - piped FTP list thru sock_list2
;               16-Dec-2011, Zarro (ADNET)
;                - use sock_list2 if using a PROXY server
;               13-May-2012, Zarro (ADNET)
;                - added USE_NETWORK
;               13-August-2012, Zarro (ADNET)
;                - added OLD_WAY (for testing purposes only)
;               7-November-2013, Zarro (ADNET)
;                - renamed from SOCK_LIST to SOCK_CAT
;               16-June-2016, Zarro (ADNET)
;               - deprecated /OLD_WAY (caused recursion situations)
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro sock_cat,url,page,_ref_extra=extra

page=''
use_list=0b
if is_blank(url) then begin 
 pr_syntax,'sock_cat,url,[output]'
 return
endif

;-- check if using FTP or PROXY

use_list=since_version('6.4') && (have_proxy() || is_ftp(url))

if use_list then sock_list,url,page,_extra=extra else begin

;-- else use HTTP object

 http=obj_new('http',_extra=extra)
 http->list,url,page,_extra=extra
 obj_destroy,http

endelse

if n_params(0) eq 1 then print,page

return

end


