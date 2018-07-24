;+
;
; NAME:
;   vis_wv_fiwt
;
; PURPOSE:
;   This code implements the 2D finite isotropic wavelet transform
;
; CALLING SEQUENCE:
;   image = ...
;   image_size =  size(image, /DIMENSIONS) ; must be square image_size[0]==image_size[1]!
;   psi = vis_wv_fiwt_spectra(image_size[0], number_scales)
;   wavelet_coeff = vis_wv_fiwt(image, psi)
;   new_image = vis_wv_fiwt(wavelet_coeff, psi, /inverse)
;
; INPUTS:
;   x:  input matrix. A 2D image matrix if inverse=0 or a 3D matrix of wavelet coefficients if inverse=1
;   psi: pre-calculated wavelet spectra
;
; KEYWORDS:
;   INVERSE: default set to 0 to calculate the forward wavelet transform. If inverse=1, calculates the inverse transform
;
; RETURNS:
;   A 3D matrix of wavelet coefficients os size [#scales+1, x_size[0], x_size[1]] if inverse=0. A 2D image matrix if inverse=1
;
; RESTRICTIONS:
;   the input image x must be square
;   The size of the spectra matrix must be compatible with the inpit matrix x
;
; HISTORY:
;   May-2017 Written by Miguel A. Duval-Poo
;   01-Nov-2017, Kim. Changed FIVE_CS to VIS_WV
;
; CONTACT:
;   duvalpoo [at] dima.unige.it
;
;-
function vis_wv_fiwt, x, psi, INVERSE=inverse

  default, inverse, 0

  if ~arg_present(psi) or size(psi, /N_DIMENSIONS) ne 3 then message, 'Error: Invalid PSI matrix.'

  psi_size =  size(psi, /DIMENSIONS)
  nscales = psi_size[0]

  if ~keyword_set(inverse) then begin
    ; foward transform
    if size(x, /N_DIMENSIONS) ne 2 then message, 'Error: X is not a 2D image.'

    xft = fft(x, /center)
    xft3 = replicate(complex(0.,0.),nscales, psi_size[1], psi_size[2])
    for j = 0,nscales-1 do begin
      xft3[j,*,*] = fft(reform(psi[j,*,*])*xft, /inverse, /center)
    endfor

    return, xft3
  endif else begin
    ; inverse transform
    if size(x, /N_DIMENSIONS) ne 3 then message, 'Error: X is not valid 3D wavelet coeficients matrix.'

    r = replicate(complex(0.,0.),nscales, psi_size[1], psi_size[2])

    for j = 0,nscales-1 do begin
      r[j,*,*] = fft(reform(x[j,*,*]), /center)*reform(psi[j,*,*])
    endfor

    return, fft(total(r, 1), /inverse, /center)
  endelse
end
