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
;                8-October-2019, Zarro (ADNET) 
;                 -added check for vector input
;               11-November-2020, Zarro (ADNET)
;                 - switched to checking OBJ_CLASS
;
; Contact     : dzarro@solar.stanford.edu
;-

function is_list,input

if ~is_object(input) then return,0b

return,strupcase(obj_class(input)) eq 'LIST'

end
 
