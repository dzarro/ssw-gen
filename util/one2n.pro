;+
;
; NAME:
; one2n
;
; PURPOSE:
; Convenient wrapper for array_indices. Given one-dimensional indices and size of array, 
; calculates the set of indices for each array dimension
;
; CALLING SEQUENCE:
; one2n,index,array,ind0,ind1,ind2....[,minmax=minmax,dimensions=dimensions]
;
; INPUTS:
;   index = one-dimensional index
;   array = either array from which the index has been subscribed, or a vector giving the size of each dimensions, in which case
;           the /dimensions keyword should be set
;
;
; OUTPUTS:
;   ind0,ind1,ind2....up to possible ind8 = returns one-dimensional indices up to the number of dimensions of array
;
; OPTIONAL KEYWORD
;   minmax = if set, the output indices are each two-element arrays giving the minimum and maximum index at that dimension
;   dimensions = keyword passed directly to array_indices, see example below or the IDL help for array_indices.pro 
;   
; PROCEDURE:
;   This procedure calls array_indices, which returns an array of size [Ndimensions,N] where
;   N is the number of elements in the input index. The output of array_indices is then 
;   split into Ndimensions separate vectors, each of length N. This is for convenience only, 
;   there is no numerical change to the output of array_indices. The minmax keyword extracts
;   the minimum and maximum value of each dimension's indices, see example below.
;   
; EXAMPLE:
;   ;First a simple example
;   array=lindgen(5,4)
;   index=where(array ge 6 and array lt 8)
;   one2n,index,array,ix,iy
;   print,'Values of array gt 5 and lt 8 are at x subscripts = ',ix
;   print,'Values of array gt 5 and lt 8 are at y subscripts = ',iy
;   ;Alternatively, the call to one2n in the above example can be
;   one2n,index,[5,4],ix,iy,/dimensions
;   
;   ;An example using the minmax keyword
;   mask=dist(300) gt 180
;   index=where(mask)
;   one2n,index,mask,ix,iy,/minmax
;   print,'Mask is non-zero in region x=',ix[0],' to ',ix[1],' and y=',iy[0],' to ',iy[1] 
;
; USE & PERMISSIONS
;  If you reuse in your own code, please include acknowledgment to Huw Morgan (see below)
;
; ACKNOWLEDGMENTS:
;  This code was developed with the financial support of:
;  STFC Consolidated grant to Aberystwyth University (Morgan)
;
; MODIFICATION HISTORY:
; Created at Aberystwyth University 07/2019 - Huw Morgan hmorgan@aber.ac.uk
;
;
;-

pro one2n,index,array,i0,i1,i2,i3,i4,i5,i6,i7,i8,minmax=minmax,dimensions=dimensions

ia=array_indices(array,index,dimensions=dimensions)
s=keyword_set(dimensions)?[n_elements(array)]:size(array)
for i=0,s[0]-1 do begin
  com='inow=reform(ia[i,*])'
  r=execute(com)
  com1='i'+strcompress(string(i),/remove_all)
  if n_elements(inow) gt 1 then $
  com=com1+'=reform(ia[i,*])' else $
  com=com1+'=ia[i]'
  r=execute(com)
  if keyword_set(minmax) then begin
    com=com1+'=minmax('+com1+')'
    r=execute(com)
  endif
endfor

end