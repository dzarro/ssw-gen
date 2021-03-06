;+
; Project     : RHESSI
;
; Name        : FILE_SETENV
;
; Purpose     : Read file containing SETENV commands and set 
;               environment within IDL
;
; Category    : system utility 
;
; Inputs      : FILE = ascii file with entries like: setenv AAA BBB
;
; Outputs     : Environment variables: $AAA=BBB
;
; Keywords    : VERBOSE = set for verbose output
;               INFORM = set to inform user that program is running
;
; History     : 21-Feb-2010, Zarro (ADNET) - written
;               6-Feb-2016, Zarro (ADNET) 
;                - added check for commented commands
;               1-May-2017, Zarro (ADNET) 
;               - added check for quoted " " values
;               11-Aug-2017, Zarro (ADNET)
;               - added INFORM keyword
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro file_setenv,file,verbose=verbose,_extra=extra,inform=inform

verbose=keyword_set(verbose)
inform=keyword_set(inform)

if is_blank(file) then return
dfile=local_name(file)
chk=file_test(dfile,/read,/regular)
if ~chk then begin
 if inform then mprint,'File file not found - '+dfile
 message,/reset
 return
endif

if inform then mprint,'Executing - '+dfile

a=strcompress(rd_ascii(dfile))
;d=stregex(a,'(.*)(setenv) +([^ ]+) +([^ ]+)',/extract,/sub,/fold)
d=stregex(a,'(.*)(setenv) +([^ ]+) +\"?([^\"#]+)\"?',/extract,/sub,/fold)
ok=where( (strlowcase(d[2,*]) eq 'setenv') and (strtrim(d[1,*],2) eq ''),count)
if (count eq 0) then begin
 if verbose then mprint,'No SETENV commands found.'
 return
endif



d=d[*,ok]
for i=0,count-1 do begin
 if verbose then mprint,'Setting '+d[3,i]+' to '+d[4,i]
 mklog,d[3,i],d[4,i],/local
endfor

return & end
