FUNCTION DCT2D_fft, a, INVERSE=inverse
  ;+
  ; NAME: DCT2D_fft
  ;
  ; PURPOSE: 2-D Discrete cosine transform or inverse discrete cosine transform
  ;
  ; EXPLANATION: Compute the 2-D Discrete cosine transform (or the inverse discrete cosine transform
  ; if the keyword INVERSE is setted) using dct1d_fft function.
  ;
  ; CALLING SEQUENCE:
  ;
  ;       dct_a = dct2D_fft(a)
  ;  or:
  ;       idct_a = dct2D_fft(a, /INVERSE)
  ; INPUTS:
  ; a = 2-D array (matrix) to which the 2-D discrete cosine transform (or inverse) is applied
  ;
  ; OPTIONAL INPUT KEYWORDS:
  ; /INVERSE if the 2-D inverse discrete cosine transform has to be computed
  ; 
  ; Written: Oct 2019, Sabrina Guastavino (guastavino@dima.unige.it)
  ; 
  ;-
  
  b = transpose(dct1d_fft(transpose(dct1d_fft(a,INVERSE=inverse)),INVERSE=inverse))    
  
  return, b

end

