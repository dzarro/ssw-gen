function idl_index, im, t
  ;+
  ; NAME:
  ; IDL_INDEX
  ; PURPOSE:
  ; convert MATLAB indexes into IDL indexes
  ; EXPLANATION:
  ; given the size of an image convert a set of MATLAB indexes t into IDL indexes.
  ; Remark: in IDL the lexicographic order for the image pixels follows the image rows
  ; (from left to right and from bottom to top) while in MATLAB it follows the image columns
  ; (from top to bottom and from left to right)
  ; CALLING SEQUENCE:
  ; s = idl_index( im, t )
  ; INPUTS:
  ; im = image
  ; t  = a set of MATLAB indexes of the image im
  ; OUTPUTS:
  ; s = the converted set of IDL indexes
  ; CALLED BY:
  ;   matlab_get_val, matlab_set_val
  ; CALLS:
  ;
  ; Written: Oct 2019, Sabrina Guastavino (guastavino@dima.unige.it)
  ;
  ;-

  siz = size(im, /dimensions)
  n = double(siz[0])
  s = (n - ((t-1.) mod n) -1.)*n + floor((t-1)/n)
  return, long(s)
end