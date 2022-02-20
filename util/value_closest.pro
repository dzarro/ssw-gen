;+
; :Description:
;    Value_Closest is the generalization of value_locate to find the index of the elementy in ARRAY
;    for each element of ARG. ARRAY must be sorted low to hi but not ARG . They should be type numerical
;
; :Params:
;    array - array to be searched for closest value, must be monotonic, interpreted as a 1D
;     array. May be increasing or decreasing
;    arg - find the indices of array with values closest to the ones in arg
;
; :Keywords:
;    value - set to the closest value in array of arg
;    diff  - difference between value and arg
;
; :Author: 22-may-2018, rschwartz70@gmail.com
; :History: 3-oct-2019, rschwartz70@gmail.com
;   added check for 1 value in array, 
;   23-Jul-2021, Kim.  Ensure ixhi is within limits of sarr array
;-
function value_closest, array, arg, value = value, diff = diff

  on_error, 2
  ;Find the closest neighbor in the sorted array and then use the index of the original
  ;add dummy values on both ends to sarr
  ;Is array monotonic and numeric?
  arr = array[*]
  if ~is_number( arr[0] ) then message,'Array must be of numeric type'
  
  if n_elements( arr ) gt 1 then begin
    mm = minmax( arr[1:*]-arr )
    mtest = product( mm )
    if mtest lt 0 then message,'Array must be monotonic'
    if mm[0] lt 0 then arr = reverse( arr )
  endif
  
  sarr = [arr[0] - 1.0, arr, last_item( arr ) + 1.]
  ;Get the value_locate lower index, ixlo
  ixlo = value_locate( sarr, arg )
  ;23-Jul-2021. Kim. Make sure ixhi is within limits of sarr array (added < ...)
  ixhi = (ixlo + 1) < (n_elements(sarr)-1)
  dlo  = arg - sarr[ixlo]
  dhi  = sarr[ixhi] - arg
  qhilo = where( dhi lt dlo, nhi) ;true means ixhi is closer
  ix   = ixlo
  if nhi ge 1 then ix[ qhilo ] = ixhi[ qhilo ]
  ix = ( ix - 1) > 0 < (n_elements( arr )-1)
  diff = dlo < dhi
  ndiff = n_elements( diff )
  ;

  value = arr[ix]
  ;if we reversed arr we have to adjust the indices
  if exist( mm ) then if mm[0] lt 0 then ix = n_elements(arr) - 1 - ix
  return, ix
end
