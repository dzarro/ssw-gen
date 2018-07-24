;+
; PROJECT:
;	SSW
; NAME:
;	PTR_INDEX
;
; PURPOSE:
;	This function returns the cumulative sum of like elements over a set of
;	valid pointers in an array of pointers, designed to work with hsi data
;	structures contained in pointers but is not hessi specific
;
; CATEGORY:
; 	Structures, Pointers
;
; CALLING SEQUENCE:
;	index = ptr_index( ptr_array [,valid, nvalid] )
;
; INPUTS:
; 	ptr_array: array of pointers to be dereferenced
;
; Returns:
;      cumulative sum of indices for valid pointers, first element is zero
;
; OUTPUTS:
;	   Valid  - indices of valid pointers
;	   Nvalid - total number of valid pointers
;
; OPTIONAL OUTPUTS:
;	none
;
; KEYWORDS:
; COMMON BLOCKS:
;	none
;
; SIDE EFFECTS:
;	none
;
; RESTRICTIONS:
;	functions only at the top level, nothing recursive
;
; PROCEDURE:
;	IDL> help, c
;	C               POINTER   = Array[9]
;	IDL> print, ptr_valid(c)
;	   0   0   0   1   1   1   1   1   0
;	IDL> for i=0,nvalid-1 do print, n_elements( *c[valid[i]])
;	       67434
;	       33717
;	       16859
;	        8430
;	        8430
;	IDL> print, hsi_ptr_index( c, valid, nvalid)
;	           0       67434      101151      118010      126440      134870
;	IDL> print, valid, nvalid
;	           3           4           5           6           7
;	           5
;
;
; MODIFICATION HISTORY:
;	23-dec-2010,  richard.schwartz@nasa.gov, broken out from ptr_concat()
;
;-
function ptr_index, ptr_array, valid, nvalid, error = error
  ;build an index of elements into an array of valid pointers
  error = 1 ;change to 0 on success

  valid  = ptr_valid(ptr_array)
  valid  = where( valid, nvalid)
  if nvalid eq 0 then begin
    message, /info, 'No valid pointers with elements to count'
    return, 0 ;no valid pointers
  endif
  index = lonarr(nvalid+1)
  for i = 1, nvalid  do index[i] = n_elements( *ptr_array[valid[i-1]])
  index = total(/cum,  /preserve, index)
  error = 0
  return, index
end