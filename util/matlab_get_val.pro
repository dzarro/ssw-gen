function matlab_get_val, im, t
  ;+
  ; NAME:
  ; MATLAB_GET_VAL
  ; PURPOSE:
  ; return the values of the image im in the IDL indexes which have been converted from the given MATLAB indexes t
  ; EXPLANATION:
  ; convert a set of MATLAB indexes t into IDL indexes s and return the values of the image im
  ; in correspondence of the indexes s
  ; CALLING SEQUENCE:
  ; y = matlab_get_val( im, t )
  ; INPUTS:
  ; im = image
  ; t  = a set of MATLAB indexes of the image im
  ; OUTPUTS:
  ; y = the set of values of the image im in correspondence of the converted set of IDL indexes
  ; CALLED BY:
  ;   matlab_reordering, dst_sparse_mtrx
  ; CALLS:
  ;   idl_index
  ;
  ; Written: Oct 2019, Sabrina Guastavino (guastavino@dima.unige.it)
  ;-

  s_converted = idl_index(im, t)
  y = im[s_converted]
  return, y
end