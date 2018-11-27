;+
; Project     : RHESSI
;
; Name        : STR_BREAK
;
; Purpose     : Wrapper around STRSPLIT that breaks string
;               on delimiters that can be regular expressions
;
; Category    : system utility string
;
; Inputs      : VAR = scalar string variable to break
;
; Outputs     : OVAR = array of strings split based on delimiter
;
; Keywords    : DELIMITER = delimiter (def=','). Can be regex
;               COUNT = # of elements in OVAR
;               REGEX = delimiter is a regex
;
; History     : 17-Oct-2018 Zarro (ADNET) - written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function str_break,var,delimiter=delimiter,count=count,_extra=extra

count=0l
if is_blank(var) then return,''
if is_blank(delimiter) then re=',' else re=delimiter
d=strsplit(var[0],re,_extra=extra,/extract)

count=n_elements(d)
if n_elements(d) eq 1 then d=d[0]
if is_blank(d) then count=0

return,d

end
