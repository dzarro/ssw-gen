;+
; Project     : HESSI
;
; Name        : LIST_MONTHS
;
; Purpose     : list month names
;
; Category    : utility date time 
;
; Syntax      : months=list_months()
;
; Inputs      : INDEX = month index (optional)
;
; Outputs     : MONTHS = string array of month names
;
; Keywords    : LOWER = convert to lower case
;               UPPER = convert to upper case
;             : TRUNCATE = truncate to three letters
;
; History     : Written 28 March 2002, D. Zarro (L-3Com/GSFC)
;               31-Aug-2018, Zarro (ADNET)
;               - added UPPER, INDEX
;
; Contact     : dzarro@solar.stanford.edu
;-

function list_months,index,lower=lower,truncate=truncate,upper=upper

months=['January','February','March','April','May','June','July','August',$
         'September','October','November','December']

if keyword_set(truncate) then months=strmid(months,0,3)
if keyword_set(lower) then months=strlowcase(months)
if keyword_set(upper) then months=strupcase(months)

if is_number(index) then begin
 index = 0 > index < 12
 return, months[index]
endif else return,months

end
