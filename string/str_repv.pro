;+
; Project     : VSO
;
; Name        : STR_REPV
;
; Purpose     : Replace substrings in a string.
;               Fully vectorized version of STR_REPLACE (still experimental)
;
; Category    : utility strings
;
; Syntax      : IDL> output=str_rep(input,old,new)
;
; Inputs      : INPUT = scalar or vector string to operate on
;             : OLD = substring to replace
;             : NEW = replacement substring
;
; Outputs     : OUTPUT = INPUT string with all occurrences of OLD
;                         replaced by NEW
;
; Keywords    : COUNT = number of matches
;               NO_COPY = set to not make internal copy (INPUT is destroyed]
;
; History     : 23-Feb-2022, Zarro (ADNET)
;-

function str_repv,input,old,new,verbose=verbose,count=count,no_copy=no_copy,rest=rest

rest=''
err=''
count=0
no_copy=keyword_set(no_copy)
verbose=keyword_set(verbose)
if ~isa(input,/string) then begin
 if n_elements(input) ne 0 then return,input else return,''
endif

if n_params() ne 3 then return,input
if ~isa(old,/string,/scalar) then return,input
if ~isa(new,/string,/scalar) then return,input
if old eq new then return,input

;-- input = 'xxxoldxxxxxoldxxxx'
;-- output= 'xxxnewxxxxxxnewxxxx'

;-- escape REGEX characters in OLD

eold=str_escape(old)
chk=where(stregex(input,eold,/bool),count)
if count eq 0 then return,input

;-- find first match

reg='(.*)('+eold+')(.*)'
chk=stregex(input,reg,/extract,/sub)
found=where(chk[2,*] ne '',fcount)
if fcount eq 0 then return,input
if no_copy then output=temporary(input) else output=input

rest1=reform(chk[1,found],fcount)
rest2=reform(chk[3,found],fcount)
chk1=where(stregex(rest1,eold,/bool),count1)

;-- recurse until all matches found and replaced

if arg_present(rest) then rest=rest1
if (count1 gt 0) then begin
 repeat begin
  if verbose then mprint,'recursing..r1...'
  rest1=str_repv(rest1,eold,new,verbose=verbose,/no_copy,rest=rest)
  chk1=where(stregex(rest,eold,/bool),count1)
 endrep until (count1 eq 0)
endif

;-- assemble output

output[found]=temporary(rest1)+new+temporary(rest2)

return,output

end
