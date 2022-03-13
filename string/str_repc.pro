;+
; Project     : VSO
;
; Name        : STR_REPC
;
; Purpose     : Replace single character substrings in a string
;
; Category    : utility strings
;
; Syntax      : IDL> output=str_repc(input,old,new)
;
; Inputs      : INPUT = vector string to operate on
;             : OLD = substring to replace [must be single character]
;             : NEW = replacement substring [must be single character]
;
; Outputs     : OUTPUT = INPUT string with all occurrences of OLD
;                         replaced by NEW
;
; Keywords    : None
;
; History     : 21-Feb-2022, Zarro (ADNET)
;-

function str_repc,input,old,new

;-- input sanity checks

if is_blank(input) then begin
 if n_elements(input) ne 0 then return,input else return,''
endif

if n_params() ne 3 then return,input

if ~is_string(old,/scalar) || ~is_string(new,/scalar) then return,input
if (strlen(old) ne 1) || (strlen(new) ne 1) then begin
 pr_syntax,'Old and New strings must be single character.'
 return,input
endif

if old eq new then return,input

;-- search for character to replace

chk=where(strpos(input,old) gt -1,count)
if count eq 0 then return,input

;-- do a fast vector replace by byte value

output=input
temp=byte(input[chk])
bold=(byte(old))[0]
bnew=(byte(new))[0]
dchk=where(temp eq bold,dcount)
if dcount eq 0 then return,input
temp[dchk]=bnew
rinput=string(temp)
output[chk]=rinput

return,output

end
