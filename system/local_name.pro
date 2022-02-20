;+
; Project     : HESSI
;
; Name        : LOCAL_NAME
;
; Purpose     : convert input file name into local OS
;
; Category    : system string
;                   
; Inputs      : INFIL = filename to convert
;                       [e.g. /ydb/ys_dbase]
;
; Outputs     : OUTFIL = filename with local OS delimiters 
;                        [e.g. \ydb\yd_dbase - if Windows]
;
; Keyword     : NO_EXPAND = don't expand environment variable
;
; History     : 29-Dec-2001,  D.M. Zarro (EITI/GSFC) - Written
;               9-Feb-2004, Zarro (L-3Com/GSFC) - added /NO_EXPAND
;               15-Jan-2015, Zarro (ADNET) 
;               - added check for scalar input
;               25-Jan-2020, Zarro (ADNET)
;               - added calls to FIX_SLASH and CHKLOG
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function local_name,infil,_extra=extra,no_expand=no_expand

out=fix_slash(infil)
if keyword_set(no_expand) then return,out

return,chklog(out,/pre,_extra=extra)
end
