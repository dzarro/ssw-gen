;+
;   Name: fix_slash
;
;   Purpose: return string with slashes corrected for OS
;
;   Input Parameters:
;      source - source string
;
; Category    :
;	Utilities, Strings
;
;   History: Kim Tolbert, 26-Jul-2001 
;            Zarro (ADNET), 25-Jan-2020 
;            - added check for URL 
;            - vectorized
;-

function fix_slash, source

if is_blank(source) then return,''

nt=n_elements(source)
local_delim = get_delim()
out=source

for i=0,nt-1 do begin
 temp=out[i]
 surl=stregex(temp,'://',/bool)
 if surl then begin
  if strpos(temp,'\') gt -1 then out[i]=str_replace(temp,'\','/')
  continue
 endif
 if (strpos(temp,'/') gt -1) && local_delim ne '/' then temp = str_replace (temp, '/', local_delim)
 if (strpos(temp,'\') gt -1) && local_delim ne '\' then temp = str_replace (temp, '\', local_delim)
 out[i] = temp
endfor
if nt eq 1 then out=out[0]
return, out
end
