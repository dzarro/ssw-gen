function vis_wv_distance, Omega, n

  if ~(n mod 2) then begin
    xi_x = findgen(n)/n*2*Omega - Omega
    xi_y = reverse(xi_x,1)

    r = dblarr(n, n)
    for i=0, n-1 do begin
      for j = 0, n-1 do begin

        r[i, j] = sqrt(xi_x[i]^2. + xi_y[n-1-j]^2.)

      endfor
    endfor

  endif else begin

    xi_x = findgen(n)/(n-1)*2*Omega - Omega
    xi_y = reverse(xi_x,1)

    r = dblarr(n, n)
    for i=0, n-1 do begin
      for j = 0, n-1 do begin

        r[i, j] = sqrt(xi_x[i]^2. + xi_y[j]^2.)

      endfor
    endfor

  endelse

  return, r
end

function vis_wv_meyeraux, x
  ; meyer wavelet auxiliary function

  y = 35*x^4 - 84*x^5 + 70*x^6 - 20*x^7
  return, y*(x ge 0)*(x le 1) + (x gt 1)

end

function vis_wv_meyer_wavelet, omega
  ; compute the Meyer wavelet mother function

  x = abs(omega)
  int1 = ((x gt !pi/4.) and (x le !pi/2.))
  int2 = ((x gt !pi/2.) and (x le !pi))
  y = int1 * sin(!pi/2.*vis_wv_meyeraux(4.*x/!pi-1))
  y = y + int2 * cos(!pi/2*vis_wv_meyeraux(2.*x/!pi-1))
  return, y

end

function vis_wv_meyer_scaling, omega
  ; scaling function for meyer wavelet

  x = abs(omega)

  ; compute support of Fourier transform of phi.
  int1 = ((x lt !pi/4.))
  int2 = ((x gt !pi/4.) and (x le !pi/2.))

  ; compute Fourier transform of phi.
  y = int1 + int2 * cos(!pi/2.*vis_wv_meyeraux(4.*x/!pi-1))

  return, y

end

;+
;
; NAME:
;   vis_wv_fiwt_spectra
;
; PURPOSE:
;   This function computes the 2D Meyer spectra to be used in the finite isotropic wavelet transform
;
; INPUTS:
;   n: size of the input image (it must be square)
;   nscales: number of scales that will be used in the wavelet decomposition (default set to 3)
;   pixel_size: pixel size in arcsec (default is 1)
;
; RETURNS:
;   A 3D matrix of wavelet values in the frenquency domain of size [nscales+1, n, n]
;
; HISTORY:
;   May-2017 Written by Miguel A. Duval-Poo
;   01-Nov-2017, Kim. Changed FIVE_CS to VIS_WV
;   12-Feb-2019, P. Massa 
;                - replaced the functions 'vis_wv_repmat', 'vis_wv_meshgrid' and 'vis_wv_linspace' with 
;                  'vis_wv_distance' in order to reduce the computational cost;
;                - added the pixel size as input;
;                - rescaled the size of the Fourier domain by the pixel size.
;
; CONTACT:
;   massa.p  [at] dima.unige.it
;   duvalpoo [at] dima.unige.it
;
;-
function vis_wv_fiwt_spectra, n, nscales, pixel_size 

  default, n, 129
  default, nscales, 3
  default, pixel_size, 1

  ; n must be odd
  n_orig = n
  n_new = n + (1-(n mod 2))

  ; largest value where psi_1 is equal to 1
  ; assuming that a = 2^-j
  X = 2.^(nscales-1)/pixel_size
  dist = vis_wv_distance(X, n_new)

  ; init
  psi = replicate(0.,nscales+1,n_new,n_new)

  ; lowpass
  psi[0,*,*] = vis_wv_meyer_scaling(dist)

  ; loop for each scale
  for j = 0,nscales-1 do begin
    a = 2.^(-j)
    psi[j+1,*,*] = vis_wv_meyer_wavelet(a*dist)
  endfor

  ; generate output with size n
  psi = psi[*, 0:n_orig-1, 0:n_orig-1]

  return, psi
end
