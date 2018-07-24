;+
; Project     : VSO
;
; Name        : IS_HASH
;
; Purpose     : check if input is a valid HASH object
;
; Category    : objects, utility
;
; Syntax      : IDL> valid=is_hash(input)
;
; Inputs      : INPUT = variable to check
;
; Outputs     : OUTPUT = 1/0
;
; History     : 11-August-2017 Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function is_hash,input

error=0
catch, error
if (error ne 0) then begin
 catch,/cancel
 message,/reset
 return,0b
endif

stc=input->ToStruct()

return,1b

end
 
