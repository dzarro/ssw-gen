function matlab_set_val, im, t, values, s
  ;+
  ; NAME:
  ; MATLAB_SET_VAL
  ; PURPOSE:
  ; reorder the values in the array 'values' according to the order of the IDL indexes s
  ; EXPLANATION:
  ; given a set of values of an image, called 'values', in correspondence of the set of MATLAB indexes t
  ; reorder the array values according to the IDL lexicographic ordered indexes s
  ; CALLING SEQUENCE:
  ; values_new = matlab_set_val( im, t, values, s )
  ; INPUTS:
  ; im     = image
  ; t      = a set of MATLAB indexes
  ; values = array to reorder
  ; s      = a set of IDL indexes
  ; OUTPUTS:
  ; values_new = reordered set of values according to the IDL indexes s
  ; CALLED BY:
  ;   idl_Xb, dst_glmnet
  ; CALLS:
  ;   idl_index
  ;
  ; Written: Oct 2019, Sabrina Guastavino (guastavino@dima.unige.it)
  ;
  ;-
  siz = size(im, /dimensions)
  n = double(siz[0])
  ; define the IDL positions of MATLAB indexes
  s_converted = idl_index(im, t)
  ; set an image putting values in converted IDL positions
  im_values = im * 0.
  im_values[s_converted] = values
  ; take values in the order of original IDL indexes
  values_new = im_values[s]
  return, double(values_new)
end
