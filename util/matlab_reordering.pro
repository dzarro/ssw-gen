function matlab_reordering, im, s, values
  ;+
  ; NAME:
  ; MATLAB_REORDERING
  ; PURPOSE:
  ; reorder the values in the array 'values' according to the converted MATLAB indexes from the IDL indexes s
  ; EXPLANATION:
  ; given a set of values called 'values' of an image in correspondence of the set of IDL indexes s,
  ; reorder the array values according to the MATLAB lexicographic order
  ; CALLING SEQUENCE:
  ; values_new = matlab_reordering( im, s, values )
  ; INPUTS:
  ; im     = image
  ; s      = a set of IDL indexes
  ; values = array to reorder
  ; OUTPUTS:
  ; values_new = reordered set of values  according to the MATLAB lexicographic order
  ; CALLED BY:
  ;   dst_glmnet
  ; CALLS:
  ;   matlab_index, matlab_get_val
  ;
  ; Written: Oct 2019, Sabrina Guastavino (guastavino@dima.unige.it)
  ;
  ;-

  t = matlab_index(im, s)
  ; set an image putting values in converted IDL positions
  im_values = im * 0.
  im_values[s] = values
  ; take values in the order of original IDL indexes
  values_new = matlab_get_val(im_values, t)
  return, double(values_new)
end