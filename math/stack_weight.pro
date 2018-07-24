 
;+
; :Description:
;    Multiply an array of images by a weighting vector, with or without summing
;    
;
; :Params:
;    imstack, fltarr( nx, ny, nstk), unchanged
;    weight - fltarr(nstk)
; :Keywords:
;     Sum - If set, sum the weighted images
;
; :Author: raschwar
; 2-may-2017
; 24-jul-2017, ras, modified to support 1 image in the stack
;-
function stack_weight, imstack, weight, $
  sum = sum, error = error
  error = 1
  
  default, sum, 0
  sstk = size( /struct, imstack )
  swgt = size( /struct, weight )

  ndimstk = sstk.n_dimensions
  ndimwgt = swgt.n_dimensions
  if ndimstk eq 2 and ndimwgt eq 1 then return, imstack * weight[0] ;nothing else to do, just one image
  if ndimstk ne 3 || ndimwgt ne 1 || sstk.dimensions[2] ne swgt.dimensions[0] then message,'Inconsistent dimensions for imagarr and vec'
  
  result = imstack
  for i = 0, swgt.dimensions[0]-1 do result[*,*,i] *= weight[i]
  ;result = imstack * reform( /overwrite, transpose( vec # (fltarr( product(dimstk[0:1]))+1) ), sstk.dimensions)
  result = sum ? total( result, 3) : result

  error = 0
  return, result
end