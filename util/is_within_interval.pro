;+
; Name: Is_Within_Interval
; 
; Description:
;    Given a set of intervals (here called Xinterval (2xN)) found along a 1D axis, 
;    Return a 1 for each Xvalue that falls within (GE lower limit, LT Upper limit) of any Xinterval and 0 otherwise
;    Xinterval and Xvalue may be unsorted. The routine does sort an internal copy of Xinterval but the inputs
;    remain unchanged
;    
;    
; Method:
;    The Xinterval are copied into a new variable which is sorted according to the first index. Then the Xvalue are located on the
;    set of first index boundaries. If the Xvalue is located before the upper boundary of the corresponding interval its corresponding
;    output values is set to 1 from its original value of 0. That array is returned. Any elements before the first boundary have their 
;    output value set to 0   
;
; Params:
;    Xinterval - array of intervals [2,n]. Xinterval[0,i] must be less than Xinterval[1,i] but the intervals
;    can be in any order and intervals can overlap.
;    Xvalue - vector of values with any shape to test whether they are within any Xinterval
;
;
; :Author: raschwar, 6-dec-2018
;-
function is_within_interval, Xinterval, Xvalue, error = error


  ;order sub_range by first elements
  dim_interval = size( xinterval, /dim ) ;must be 2 element or 2 x N or N x 2
  dim_test = dim_interval[0] eq 2 && n_elements( dim_interval ) le 2  && n_elements(xvalue) ge 1
  error = 1
  if ~dim_test then begin
    help, Xinterval, Xvalue 
    message, 'Bad Xinterval or Xvalue, should be 2xN for Xinterval and 1 or more Xvalue'
  endif
     
  ord = sort( xinterval[0,*] )
  xint = xinterval[*, ord]
  ixl = value_locate( xint[0,*], xvalue)
  q = where( ixl ge 0, nq)
  within = intarr( n_elements( xvalue ) )
  if nq ge 1 then within[q] = xvalue[q] lt xint[1, ixl[q]]
  ;values is contained if values is lt sub[1,ixl]
  return, within
end
