;+
; Project     : VSO
;
; Name        : SOCK_ENCODE
;
; Purpose     : Encode special characters in URL QUERY
;
; Category    : utility sockets
;
; Inputs      : INPUT = URL to encode
;               TOKEN = string character to encode 
;               (scalar, array, or comma-delimited string)
;
; Outputs     : OUTPUT = encoded result
;
; Keywords    : QUERY_ONLY = encode query part of URL only
;
; History     : 22-October-2018, Zarro (ADNET) - written
;               11-September-2020, Zarro (ADNET) - added QUERY_ONLY
;               22-December-2020, Zarro (ADNET) - fixed bug with continue
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function sock_encode,input,token,query_only=query_only

query_only=keyword_set(query_only)

if is_blank(input) then return,''
if is_blank(token) then return,input
if n_elements(token) eq 1 then tokens=str2arr(token) else tokens=token

count=n_elements(input)
nt=n_elements(tokens)
for i=0,count-1 do begin
 svar=input[i]
 qvar=svar
 url_in=0b
 if query_only then begin
  if is_url(svar,/scheme) then begin
   bvar=url_parse(svar)
   qvar=bvar.query
   url_in=1b
  endif
 endif 
 if is_string(qvar) then begin
  for j=0,nt-1 do begin
   tvar=tokens[j]
   if strlen(tvar) eq 1 then begin
    tpos=strpos(qvar,tvar)
    if tpos ne -1 then begin
     stoken=strupcase(string(byte(tvar),format='(z2.2)'))
     qvar=str_replace(qvar,tvar,'%'+stoken)
     if url_in then begin
      bvar.query=qvar
      svar=url_join(bvar)
     endif else svar=qvar 
    endif
   endif
  endfor
 endif
 nvar=append_arr(nvar,svar,/no_copy)
endfor

output=nvar
if n_elements(output) eq 1 then output=output[0] 
return,output

end
