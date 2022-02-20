;
;+
;NAME:
;	where_arr_numeric
;PURPOSE:
;	Return the subscripts where a given set of values equal the values
;	in the input array.  It is basically an expansion of IDL where in
;	which the condition to match can be an array.
;CALLING SEQUENCE:
;	ss = where(full_arr, sub_arr)
;	ss = where(a, b)
;	ss = where(a, b, count)
;       ss = where(a, b, count, /notequal) - invert sense
;	ss = where(a, b, count, /map_ss)
;INPUT:
;	full_arr- The complete array which is to be searched
;	sub_arr	- The subset array of the values to search "full_arr" of
;
;KEYWORD PARAMETERS:
;	notequal - if set, return indices where values are NOTEQUAL
;	map_ss	- If set, then return the index in the "sub_arr" where
;		  first occurance of the element exists in the "full_arr"
;		  The length of the output is the same as "full_arr"
;OUTPUT:
;	returns the subscripts where "sub_arr" occurrs in "full_arr".  If
;	there are no matches, return a -1.
;OPTIONAL OUTPUT:
;	count	- The number of matches
;HISTORY:
;	Written 30-Apr-91 by M.Morrison
;                1-Jul-94 (SLF) - add NOTEQUAL keyword
;		14-Nov-97 (MDM) - Added /MAP_SS keyword
;               09-Mar-98 (JSN) - change loop from integer to long
;		5-Feb-2007, Kim Tolbert.  Changed indgen to lindgen
;		3-oct-2019, rschwartz70@gmail.com, changed to use value_closest for dramatic speedup
;-
;
function where_arr_numeric, full_arr, sub_arr, count, $
  notequal=notequal, map_ss=map_ss

  n = n_elements(full_arr)
  nn = n_elements(sub_arr)
  ;
  ord = bsort( sub_arr )
  sub_arr_ord = sub_arr[ord]
  ix = value_closest( sub_arr_ord, full_arr, v=v)
  out = where( v eq full_arr, count)
  ;

  ; slf - NOTEQUAL condition (recursive - remove matches (EQUAL) from all indices
  ; slf was doing it twice, only do it once as the result is there!!! RAS
  if keyword_set(notequal) then  return, rem_elem(lindgen(n), out,count) 
  if (keyword_set(map_ss)) then begin
    temp = full_arr * 0L -1
    temp[out] = (ord[ix])[out]
    count = 1L ;the same result as the original, meaningless, probably should leave it alone
    return, temp
  endif
  return, out
end
