;+
; Project     : VSO
;
; Name        : STR_ESCAPE
;
; Purpose     : Escape regular expression meta characters (*, . )
;
; Category    : utility string
;
; Syntax      : IDL> out=str_escape(in)
;
; Inputs      : IN = input string to escape (e.g. 'test.gif')_
;
; Outputs     : OUT = output escaped string (e.g. 'test\.gif')
;
; Keywords    : None
;
; History     : 16 June 2016, Zarro (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;-


function str_escape,input

if n_elements(input) ne 1 then return,''
if is_blank(input) then return,''

bar=byte(input)
ast=(byte('*'))[0]
per=(byte('.'))[0]
del=(byte('\'))[0]

chk=where( (bar eq ast) or (bar eq per), count)
if count eq 0 then return,input

new=str_replace(input,'*','\*')
new=str_replace(new,'\\*','\*')
new=str_replace(new,'.','\.')
new=str_replace(new,'\\.','\.')

return,new
end 
