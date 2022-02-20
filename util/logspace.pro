FUNCTION logspace, s0, s1, n
  ;+
  ; NAME: LOGSPACE
  ;
  ; PURPOSE: Logaritmically spaced vector
  ;
  ; EXPLANATION: Generate n logarithmically equally spaced points between
  ; 10^s0 and 10^s1
  ;
  ; CALLING SEQUENCE:
  ; s = logspace(s0,s1,n)
  ; INPUTS:
  ; s0 = exponent of the lower bound
  ; s1 = exponent of the upper bound
  ; n  = number of points
  ; OUPUTS:
  ; s  = array of the n logarithmically equally spaced points from 10^s0 to 10^s1
  ;
  ; Written: Oct 2019, Sabrina Guastavino (guastavino@dima.unige.it)
  ;
  ;-

  t = s0 + findgen(n)*(s1-s0)/(n-1)
  t[0] = s0
  t[n_elements(t)-1] = s1
  s = 10.^t


  RETURN, s

end





