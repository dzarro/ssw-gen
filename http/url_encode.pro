function url_encode, unencstr, include=include, exclude=exclude
;+
;   Name: url_encode
;
;   Purpose: urlencode a string
;
;   Input Parameters:
;      unencstr - string or string array to encode
;
;   Keyword Parameters:
;      include - optional list of one or more chacters to force
;      exclude - optional list of one or more characters to Exclude
;
;   History:
;      5-Dec-2001 - S.L.Freeland for generating valid url-encoded POST Query string 
;                   (see post_query.pro)
;      1-sep-2012 -  S.L.Freeland add '#' to list 
;     24-sep-2012 -  S.L.Freland add INCLUDE
;     27-mar-2014 -  S.L.Freeland add EXCLUDE keyword & function and
;                   $url_encode_exclude option
;     8-Oct-2018  - Zarro (ADNET) 
;                   - allow INCLUDE & EXCLUDE to be array or
;                     comma-delimited string
;   Restrictions:
;      written to get something online and going - needs some
;      fleshing out to cover additional url-encdoding rules
;-

if ~data_chk(unencstr,/string) then begin 
   box_message,'Requires string(s) input'
   return,''
endif else retval=unencstr

retval[0]='%'+retval[0]                ; for str_replace TODO...

echars=str2arr("/,\,;,:,=, ,),#,(")
if is_string(include) then begin ; user optional additions
   if n_elements(include) eq 1 then ix=str2arr(include) else ix=include
   echars=[echars,ix]
   echars=all_vals(echars)
endif

exenv=get_logenv('url_encode_exclude')
if exenv ne '' || is_string(exclude) then begin 
   if is_blank(exclude) then exclude=exenv
   if n_elements(exclude) eq 1 then ex=str2arr(exclude) else ex=exclude
   ss=rem_elem(echars,ex,count)
   if count gt 0 then echars=echars[ss] else echars=''
endif

for i=0,n_elements(echars)-1 do begin 
  anyc=total(strpos(retval,echars[i]))
  if anyc ge 0 then $
     retval=str_replace(retval,echars[i],'%'+ $
       strupcase(string(byte(echars[i]),format='(z2.2)')))
endfor

retval=str_replace(retval,' ','+')
retval[0]=strmids(retval[0],1)
if n_elements(retval) gt 1 then retval=arr2str(retval,'&')

return, retval
end
