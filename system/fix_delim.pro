;+
; Project     : VSO
;
; Name        : FIX_DELIM
;
; Purpose     : Fix directory/file names that have wrong delimiter for OS
;
; Category    : utility strings
;
; Syntax      : IDL> output=fix_delim(input))
;
; Inputs      : INPUT = vector string [e.g. 'dir/file']
;
; Outputs     : OUTPUT = vector string with corrected delimiters [e.g. 'dir\file' if Windows]
;
; Keywords    : None
;
; History     : 21-Feb-2022, Zarro (ADNET)
;-

function fix_delim,input
 
if is_blank(input) then begin
 if n_elements(input) ne 0 then return,input else return,''
endif

os=os_family(/lower)
if os eq 'unix' then return,str_repc(input,'\','/') else return,str_repc(input,'/','\')

end
