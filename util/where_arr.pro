function where_arr, full_arr, sub_arr, count, notequal=notequal, map_ss=map_ss
  ;
  ;+
  ;NAME:
  ;	where_arr
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
  ;   3-oct-2019, rschwartz70@gmail.com, calls where_arr_numeric() for numeric types to
  ;     use speed enhanced search because it uses sorting instead of repeated scanning
  ;   2-Aug-2021, Kim Tolbert. Changed is_number test to isa test. is_number returns 1 for any
  ;     string that *starts* with a number, so input like['1f','2f'] crashes in where_arr_numeric.
  ;   3-Aug-2021, Kim Tolbert. isa(...,/number) isn't available in IDL < 8.1, so reverted 2-Aug-2021 change
  ;     back to using is_number, but put extra check in for string input before checking is_number (since
  ;     is_number returns 1 for a string that starts with a number)
  ;-
  
  ; Need type check since is_number returns 1 for strings that start with a number Kim 3-Aug-2021
  if (size(full_arr,/type) ne 7) && (size(sub_arr,/type) ne 7) && is_number(full_arr[0]) && is_number(sub_arr[0]) then $
;  if isa(full_arr[0], /number) && isa(sub_arr[0],/number) then $
    ;   3-oct-2019, rschwartz70@gmail.com, changed to use value_closest for dramatic speedup in where_arr_numeric
    return, where_arr_numeric( full_arr, sub_arr, count, notequal=notequal, map_ss=map_ss )
  n = n_elements(full_arr)
  nn = n_elements(sub_arr)
  ;
  b = lonarr(n)-1
  for i=0l,nn-1 do begin
    ss = where(full_arr eq sub_arr(i), count)
    if (count ne 0) then b(ss) = i
  end
  ;
  if (keyword_set(map_ss)) then out = b $
  else out = where(b ge 0,count)

  ; slf - NOTEQUAL condition (recursive - remove matches (EQUAL) from all indices
  if keyword_set(notequal) then $
    return, rem_elem(lindgen(n),where_arr(full_arr,sub_arr),count) else return,out

end
