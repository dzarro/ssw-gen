;+
; NAME:
;	sswhere_close
; CALLING SEQUENCE:
;	ss=sswhere_close(arr1, arr2, close_par)
; PURPOSE:
;	gives the subscripts in the array arr1 that are for elements
;	close to arr2.
; INPUT:
;	arr1, arr2 = two arrays
;       close_par = if abs(arr2-arr1) < close par, then yes
; OUTPUT:
;	ss = the subscripts of arr1 that are close to arr2
; KEYWORD:
;       notclose = if set, return the array elements of arr1 that are
;                  not close to  arr2
; HISTORY
;	Spring '92 JMcT
;       Hacked from sswhere_arr, 2017-12-16, jmm
;       No error checking, don't use if arr1 or arr2 aren't numbers, 
;-
FUNCTION sswhere_close, arr1, arr2, close_par, notclose = notclose, _extra = _extra
   
   otp = -1
   n1 = n_elements(arr1)
   n2 = n_elements(arr2)
   If(n1 Eq 0 Or n2 Eq 0) Then Return, otp

   in_arr2 = bytarr(n1)
   not_in_arr2 = in_arr2+1

   FOR j = 0l, n1-1 DO BEGIN
      ok = where(abs(arr2-arr1[j]) Lt close_par)
      IF(ok(0) NE -1) THEN BEGIN
         in_arr2[j] = 1b
         not_in_arr2[j] = 0b
      ENDIF
   ENDFOR
   
   IF(keyword_set(notclose)) THEN BEGIN
      otp = where(not_in_arr2 Eq 1)
   ENDIF ELSE BEGIN
      otp = where(in_arr2 Eq 1)
   ENDELSE
   RETURN, otp
END
