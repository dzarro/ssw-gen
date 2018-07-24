;+
; Project     : VSO
;
; Name        : STR_POS
;
; Purpose     : Check if character is first/last element of a string
;
; Category    : utility 
;
; Syntax      : IDL> chk=str_last(input,char)
;
; Inputs      : INPUT = input string to check
;               CHAR = character to look for
;
; Keywords:   : FIRST = check if first [DEF]
;
;               LAST = check if last 
; Outputs     : 1/0 = yes/no
;
; History     : 21-Dec-2016, Zarro (ADNET) - Written
;-

function str_pos,input,char,err=err,first=first,last=last

err=''
if is_blank(input) then dinput='' else dinput=strtrim(input[0],2)

if is_blank(dinput) then begin
; pr_syntax,'chk=str_last(input,char)','Input must be scalar string'
 return,0b
endif

if is_blank(char) then return,0b
if keyword_set(last) then stx=char+'$' else stx='^'+char
len=strlen(dinput)

return,stregex(dinput,stx,/bool)
end
