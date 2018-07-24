;+
; Project     : VSO
;
; Name        : IS_LIST
;
; Purpose     : check if input is a valid LIST object
;
; Category    : objects, utility
;
; Syntax      : IDL> valid=is_list(input)
;
; Inputs      : INPUT = variable to check
;
; Outputs     : OUTPUT = 1/0
;
; History     : 11-August-2017 Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function is_list,input

error=0
catch, error
if (error ne 0) then begin
 catch,/cancel
 message,/reset
 return,0b
endif

arr=input->ToArray()

return,1b

end
 
