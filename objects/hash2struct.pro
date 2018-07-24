
;+
; Project     : VSO
;
; Name        : HASH2STRUCT
;
; Purpose     : Convert HASH object to structure
;
; Category    : objects, utility
;
; Syntax      : IDL> stc=hash2struct(input)
;
; Inputs      : INPUT = HASH object to convert
;
; Outputs     : STC = structure
;
; History     : 11-August-2017 Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function hash2struct,input,_ref_extra=extra

if ~is_hash(input) then return,null()

stc=input.ToStruct(/recursive,_extra=extra)
if ~is_struct(stc) then return,null()

output=stc
tags=tag_names(stc)

;-- convert any LIST fields to arrays

for i=0,n_elements(tags)-1 do begin
 if is_list(stc.(i)) then begin
  arr=(stc.(i)).ToArray(_extra=extra)
  output=rep_tag_value(output,arr,tags[i])
 endif
endfor 

return,output
end
