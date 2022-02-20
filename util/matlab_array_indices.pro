function matlab_array_indices, im, s
  ;+
  ; NAME:
  ; matlab_array_indices
  ; PURPOSE:
  ; convert a set of IDL one-dimensional subscripts of a matrix into MATLAB two-dimensional subscripts of a matrix
  ; EXPLANATION
  ; convert the IDL one-dimensional subscripts s of an image im into MATLAB two-dimensional subscripts
  ; CALLING SEQUENCE:
  ; ij_new = matlab_array_indices( im, s )
  ; INPUTS:
  ; im = image
  ; s  = a set of IDL indexes of the image im
  ; OUTPUTS:
  ; ij_new = the converted MATLAB two-dimensional subscripts
  ; CALLED BY:
  ;   dst_sparse_mtrx
  ; CALLS:
  ;
  ; Written: Oct 2019, Sabrina Guastavino (guastavino@dima.unige.it)
  ;
  ;-
  ij = array_indices(im , s)
  row_ind = ij[0,*]
  ; MATLAB indices need + 1 along columns
  col_ind = ij[1,*] + 1
  ij_new = [row_ind, col_ind]
  return, long(ij_new)
end