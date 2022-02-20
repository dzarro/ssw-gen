;+
; PROJECT:
;	SSW
; NAME:
;	ptr_load
;
; PURPOSE:
;	This provides the reverse operation to PTR_CONCAT.  This takes the input array
;	elements of ptr_data and puts them back into the valid pointers PTRS
; CATEGORY:
; 	Structures, Pointers
;
; CALLING SEQUENCE:
;	ptr_load, ptrs, ptr_data, index,  error=error
;
; INPUTS:
;    Ptrs; array of pointers to take elements of ptr_data, if not valid consistent with index will
;       be created
;		ptr_data ; data array of flat data or structures to put into the valid elements
;			of PTRS
; OPTIONAL INPUTS:
;
;		Index ; cumulative sum of elements held by valid elements of PTRS.
;
;
; OPTIONAL OUTPUTS:
;	Error: set to 1 if PTRS cannot be filled from ptr_data
;
; KEYWORDS:
;   valid - indices of valid pointers to fill
;   nptr  - if a pointer array, ptrs isn't passed, then create a ptrarr( nptr)
;   tag_name  - if provide, and Ptrs are passed in, then the input, ptr_data, will be placed in this
;    field on the structure
; COMMON BLOCKS:
;	none
;
; SIDE EFFECTS:
;	none
;
; RESTRICTIONS:
;
;
; PROCEDURE:
;	Pointers are dereferenced, values inserted, arrays put back into pointers
;
; MODIFICATION HISTORY:
;	4-mar-2011, richard.schwartz,
;	30-oct-2017, richard.schwartz, TAG_NAME added
;	20-Feb-2020, Kim. Fixed bug - just checking if total number of valid ptrs matches nvalid_index isn't
;	  enough - need to also check if the ones in 'valid' array are the ones that are valid in ptrs array.
;
;-
pro ptr_load, ptrs, ptr_data, index, $
  valid = valid, nptr = nptr, $
  tag_name = tag_name,  error=error ;

  error = 1

  nvalid_index = n_elements( index ) - 1
  if n_elements( valid ) ne nvalid_index then begin
    message, /info, ' Inconsistent inputs, VALID and Index '
    return
  endif

  ; 20-Feb-2020, Kim - changed test (ftotal( ptr_valid(ptrs)) ) ne ( nvalid_index ) to the one below
  if ~same_data(where(ptr_valid(ptrs)), valid) then begin
    ;build pointers
    nptrs = exist( nptr ) ? nptr : nvalid_index
    ptrs  = ptrarr( nptrs )
    nvalid = n_elements( valid )
    if nvalid gt 0 then for i = 0, nvalid - 1 do ptrs[ valid[i] ] = ptr_new( /alloc )
  endif
  valid_tag = have_tag( *ptrs[valid[0]], tag_name, tag_index, /exact )
  index = keyword_set(index) ? index : ptr_index(ptrs, valid, nvalid)
  if ~keyword_set(index) then return

  ix = where( ptr_valid(ptrs), nix)
  if ~valid_tag then $
    for i=0,nix-1 do *ptrs[ix[i]] = ptr_data[index[i]:index[i+1]-1] $
  else $
    for i=0,nix-1 do begin

    dims = size(  (*ptrs[ix[i]]).(tag_index), /dimension )
    ndims = n_elements( dims )
    if ndims eq 1 then data = ptr_data[index[i]:index[i+1]-1] else begin


      data_dim   =  size( ptr_data, /dimension )
      reform_dim = [ product( dims[ 0:ndims-2 ]), data_dim[ ndims-1 ] ]
      ref_ptr_data = reform( ptr_data, reform_dim )
      data = ref_ptr_data[*, index[i]:index[i+1]-1]
    endelse
    (*ptrs[ix[i]]).(tag_index) = data
  endfor
  error = 0
end