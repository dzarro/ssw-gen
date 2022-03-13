;+
; Project     : VSO
;
; Name        : STR_ENV
;
; Purpose     : Expand prefixed environment variable in a string
;
; Category    : utility strings
;
; Syntax      : IDL> output=str_env(input)
;
; Inputs      : INPUT = array of strings to operate on [e.g. $SSW/gen/idl]
;
; Outputs     : OUTPUT = expanded string [e.g. /solarsoft/idl/gen]
;
; Keywords    : None
;
; History     : 21-Feb-2022, Zarro (ADNET)
;-

function str_env,input

;-- input sanity checks

if is_blank(input) then begin
 if n_elements(input) ne 0 then return,input else return,''
endif

;-- search for environment variables

chk=where(stregex(input,'^\$',/bool),count)
if count eq 0 then return,input
chk=stregex(input,'^\$([^\\|\/]+)([\\|//]?.*)',/sub,/extrac)
envs=strtrim(chk[1,*],2)
efound=where(envs ne '',ecount)
if ecount eq 0  then return,input
e1=getenv(envs[efound])
bfound=where( (e1 ne ''),bcount)
if bcount gt 0 then chk[1,efound[bfound]]=e1[bfound] else begin
 e2=getenv('$'+envs[efound])    
 bfound=where( (e2 ne ''),bcount)
 if bcount gt 0 then chk[1,efound[bfound]]=e2[bfound]
endelse

if bcount eq 0 then return,input

;-- assemble output

output=input
sfound=efound[bfound]
output[sfound]=chk[1,sfound]+chk[2,sfound]
if n_elements(output) eq 1 then output=output[0]
return,output

end
