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
;                8-October-2019, Zarro (ADNET)
;                 -added check for vector input
;                22-November-2020, Zarro (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;-

function is_hash,input

if ~is_object(input) then return,0b

chk=strupcase(obj_class(input)) 
return, (chk eq 'HASH') || (chk eq 'ORDEREDHASH')
end


