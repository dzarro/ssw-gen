;+
; :Description:
;    Just the difference between successive elements of an array.
;    difference =  v[1:*]-v
;
; :Params:
;    v - input array, should be 2 elements or more
;    returns 0 if only 1 or 0 elements
;
;
;
; :Author: rschwartz70@gmail.com
; :History: 
; Initial, November 2018
;-
function arr_diff, v
  if n_elements( v ) le 1 then  return, 0
  difference =  v[1:*]-v
  difference = n_elements( difference ) eq 1 ? difference[0] : difference
  return, difference
end