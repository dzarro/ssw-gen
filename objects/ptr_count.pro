;+
; :Description:
;    Counting the number of replicated structures in each valid pointer in the array
;
; :Params:
;    ptr - pointer array, each valid element containing a replicated structure
;
;
;
; :Author: raschwar, 23-may-2017
;-
function ptr_count, ptr

if ~ptr_chk( ptr ) then message, 'Input must be a pointer'
count = lonarr( n_elements( ptr ) )
list  = where( ptr_valid( ptr ), nlist )
for i = 0, nlist -1 do count[ list[i] ] = n_elements( *ptr[ list[i] ] ) 

return, count
end