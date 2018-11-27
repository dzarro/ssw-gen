;+
; Project     : RHESSI
;
; Name        : CHKENV
;
; Purpose     : Wrapper around GETENV that checks substrings
;               separated by delimiter (e.g. $SSW/test')
;
; Category    : system utility string
;
; Inputs      : VAR = string variable to check
;
; Outputs     : OVAR = expanded environment variable
;
; Keywords    : PRESERVE = return input VAR if not expanded (def='']
;               RECURSE = recurse on output (= 1,2,3...)
;               DELIMITER= delimiter to split substrings on (def = /,\)
;               FIX_DELIMITER = convert all delimiters to OS-specific values
;
; History     : 17-Oct-2018 Zarro (ADNET) - written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

   function chkenv,var,_extra=extra,delimiter=delimiter,$
    preserve=preserve,fix_delimiter=fix_delimiter,debug=debug,$
    recurse=recurse 

   preserve=keyword_set(preserve)
 
   if is_blank(var) then begin
    if exist(var) && preserve then return,var else return,''
   endif

   if is_number(recurse) then nrec=fix(recurse) > 0 else nrec=0
   debug=keyword_set(debug)
   if debug then mprint,var
   fix_delimiter=keyword_set(fix_delimiter)
   svar=getenv2(trim(var[0]),/preserve)

;-- expand on delimiters
  
   delim='\\|\/' & regex=1b
   if is_string(delimiter) then begin
    delim=delimiter & regex=0b
   endif

   ovar=str_break(svar,delimiter=delim,count=count,regex=regex)
   if count gt 0 then begin
    for i=0,count-1 do begin
     if debug then help,ovar[i]
     evar=getenv2(ovar[i],/preserve)
     if evar ne ovar[i] then svar=strep2(svar,ovar[i],evar)
    endfor
   endif

;-- recurse on output to expand deeper 

   if nrec gt 0 then begin
    for i=0,nrec-1 do svar=chkenv(svar,/preserve,delimiter=delim,debug=debug)
   endif

   if (svar eq var) then begin
    if preserve then return,var else return,''
   endif

   if fix_delimiter then svar=fix_slash(svar)
   return,svar

   end
        
