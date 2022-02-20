FUNCTION DCT1D_fft, a, INVERSE=inverse
 ;+
 ; NAME: DCT1D_fft
 ;
 ; PURPOSE: Discrete cosine transform or inverse discrete cosine transform
 ;
 ; EXPLANATION: Compute the Discrete cosine transform (or the inverse discrete cosine transform
 ; if the keyword INVERSE is setted) using the fft function (or inverse fft)
 ;
 ; CALLING SEQUENCE:
 ;
 ;       dct_a = dct1D_fft(a)
 ;  or:
 ;       idct_a = dct1D_fft(a, /INVERSE)
 ; INPUTS:
 ; a = 2-D array (matrix) to which the discrete cosine transform (or inverse) is computed along each row
 ; 
 ; OPTIONAL INPUT KEYWORDS:  
 ; /INVERSE if the inverse discrete cosine transform has to be computed
 ; 
 ; Written: Oct 2019, Sabrina Guastavino (guastavino@dima.unige.it)
 ;
 ;-
 
  siz = size(a, /dimensions)
  n = siz[1] ; number of rows
  m = siz[0] ; number of columns

  aa = a[*,0:n-1]
  
  
  IF ( KEYWORD_SET( INVERSE ) ) THEN BEGIN
  ; Inverse discrete cosine transform
    aa = complex(aa,/DOUBLE)
    ww = exp(complex(0,1)*[0:n-1]*!pi/(2*n)) * sqrt(2*n)
    ww = transpose(ww)
    
    if (n mod 2) eq 0 then begin ; even case
      ww[0] = ww[0]/sqrt(2.);
      ww_replicate = ww ## (make_array(m,1,/DOUBLE)+1.0)
      yy = ww_replicate * aa

      y = fft(yy, dimension = 2, /INVERSE);
      y = y / n
      out = make_array(m,n,/DCOMPLEX)
      out[*,0:n-1:2] = y[*, 0: n/2 - 1];
      out[*,1:n-1:2] = y[*, n-1:n/2:-1];
      
    endif else begin ; odd case
      
      ww[0] = ww[0] * sqrt(2)
      ww_replicate = ww ## (make_array(m,1,/DOUBLE)+1.0)

      y = make_array(m,2*n,/DCOMPLEX)
      y[*, 0:n-1] = ww_replicate * aa
      y[*, n+1:2*n-1] = complex(0,-1,/DOUBLE) * ww_replicate(*,1:n-1) * reverse(aa(*,1:n-1),2)

      yy = fft(y, dimension = 2, /INVERSE)
      yy = yy / (2.*n)
      out = yy[*,0:n-1]
    endelse
    



  ENDIF ELSE BEGIN
    ; Discrete cosine transform
    ww = exp(complex(0,-1)*[0:n-1]*!pi/(2*n)) / sqrt(2*n)
    ww = transpose(ww)
    ww[0] = ww[0] / sqrt(2)
    
     if (n mod 2) eq 0 then begin  ; even case
      y = [ [aa[*,0:n-1:2]], [aa[*, n-1:1:-2]] ]
      yy = fft(y, dimension = 2);
      yy = n*yy
      ww = 2.*ww;
    endif else begin ; odd case

      y = make_array(m,2*n,/DOUBLE)
      y[*, 0:n-1] = aa
      y[*, n:2*n-1] = reverse(aa,2)

      yy = fft(y, dimension = 2)
      yy = 2*n*yy
      yy = yy[*,0:n-1]
    
    endelse 
    ww_replicate = ww ## (make_array(m,1,/DOUBLE)+1.0)

    out = ww_replicate * yy


  ENDELSE

  RETURN, real_part(out)

end





