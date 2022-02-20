;+
; Project     : VSO
;
; Name        : STR_REP
;
; Purpose     : Replace substrings in a string
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
; Keywords    : NONE
;
; History     : 31-Jan-2020, Zarro (ADNET)
;-

function str_rep_i,input,old,new

olen=strlen(old)
if olen eq 0 then return,input

fpos=strpos(input,old)
if fpos eq -1 then return,input

temp='' & buff=input
repeat begin
 fpos=strpos(buff,old)
 if fpos gt -1 then begin
  piece=strmid(buff,0,fpos)
  temp=(temp eq '')? (piece+new) : (temp+piece+new)
  buff=strmid(buff,fpos+olen,strlen(buff))
 endif
endrep until (fpos eq -1)
if (buff ne '') then temp=(temp eq '')? buff : (temp+buff)

return,temp

end

;---------------------------------------------------------------------

function str_rep,input,old,new,verbose=verbose,err=err

err=''
if ~isa(input,/string) then begin
 if n_elements(input) ne 0 then return,input else return,''
endif

if n_params() ne 3 then return,input
if ~isa(old,/string,/scalar) then return,input
if ~isa(new,/string,/scalar) then return,input


;-- input = 'xxxoldxxxxxoldxxxx'
;-- output= 'xxxnewxxxxxxnewxxxx'

np=n_elements(input)
if np eq 1 then return,str_rep_i(input,old,new)

verbose=keyword_set(verbose)
try_map=1b
error=0
catch, error
try_count=0
if (error ne 0) then begin
 catch, /cancel
 err=err_state()
 message,/reset
 try_count=try_count+1
 if verbose then mprint,err
 if try_count gt 1 then return,input
 try_map=0b
endif

if try_map then return,input->map('str_rep_i',old,new) else begin
 output=input
 for i=0,np-1 do output[i]=str_rep_i(input[i],old,new)
 return,output
endelse

end
