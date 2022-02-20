function matlab_index, im, s
  ;+
  ; NAME:
  ; MATLAB_INDEX
  ; PURPOSE:
  ; convert IDL indexes into MATLAB indexes
  ; EXPLANATION:
  ; given the size of an image convert the IDL indexes into MATLAB indexes.
  ; Remark: in IDL the lexicographic order for the image pixels follows the image rows
  ; (from left to right and from bottom to top) while in MATLAB it follows the image columns
  ; (from top to bottom and from left to right)
  ; CALLING SEQUENCE:
  ; t = matlab_index( im, s )
  ; INPUTS:
  ; im = image
  ; s  = a set of IDL indexes of the image im
  ; OUTPUTS:
  ; t = the converted set of MATLAB indexes
  ; CALLED BY:
  ;   matlab_reordering, idl_Xb, dst_sparse_mtrx, dst_glmnet
  ; CALLS:
  ;
  ; Written: Oct 2019, Sabrina Guastavino (guastavino@dima.unige.it)
  ; -
  siz = size(im, /dimensions)
  n = double(siz[0])
  t = n-floor(s/n)+ (s mod n)*n
  t = t(sort(t))
  return, long(t)
end