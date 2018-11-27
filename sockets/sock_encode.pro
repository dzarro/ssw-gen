;+
; Project     : VSO
;
; Name        : SOCK_ENCODE
;
; Purpose     : Encode special characters in URL
;
; Category    : utility sockets
;
; Inputs      : INPUT = URL or QUERY to encode
;               TOKEN = string character to encode 
;               (scalar, array, or comma-delimited string)
;
; Outputs     : OUTPUT = encoded result
;
; Keywords    : NONE
;
; History     : 22-October-2018, Zarro (ADNET) - written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function sock_encode,input,token

if is_blank(input) then return,''
if is_blank(token) then return,input
if n_elements(token) eq 1 then tokens=str2arr(token) else tokens=token

count=n_elements(input)
nt=n_elements(tokens)
for i=0,count-1 do begin
 svar=input[i]
 for j=0,nt-1 do begin
  tvar=tokens[j]
  if strlen(tvar) ne 1 then continue
  tpos=strpos(svar,tvar)
  if tpos eq -1 then continue
  stoken=strupcase(string(byte(tvar),format='(z2.2)'))
  svar=str_replace(svar,tvar,'%'+stoken)
 endfor
 nvar=append_arr(nvar,svar,/no_copy)
endfor

output=nvar
if n_elements(output) eq 1 then output=output[0] 
return,output

end
