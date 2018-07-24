function vis_wv_repmat, M0, nc, nr

  M = M0
  y = 1
  n = max([nc,nr])
  sm = size(M)

  if sm[0] eq 0 then begin
    mx = 1
    my = 1
  endif else begin
    if sm[0] eq 1 then begin
      mx = sm[1]
      my = 1
    endif else begin
      mx = sm[1]
      my = sm[2]
    endelse
  endelse

  while y lt n do begin
    y = y*2
    sm = size(M)
    if sm[0] eq 0 then begin
      smx = 1
      smy = 1
    endif else begin
      if sm[0] eq 1 then begin
        smx = sm[1]
        smy = 1
      endif else begin
        smx = sm[1]
        smy = sm[2]
      endelse
    endelse
    M2 = make_array(2*smx,2*smy)
    M2[0:smx-1,0:smy-1] = M
    M2[smx:2*smx-1,0:smy-1] = M
    M2[0:smx-1,smy:2*smy-1] = M
    M2[smx:2*smx-1,smy:2*smy-1] = M
    M = M2
  endwhile

  M = M[0:nc*mx-1,0:nr*my-1]
  return, M

end


pro vis_wv_meshgrid, x, y, x2, y2
  lx = n_elements(x)
  ly = n_elements(y)
  x2 = vis_wv_repmat(x,1,ly)
  y2 = vis_wv_repmat(transpose(y),lx,1)
end

function vis_wv_linspace, base, limit, n
  ; Provides a row vector V with N linearly spaced elements between BASE and LIMIT;
  ; V = linspace(BASE, LIMIT, N)

  v = base + findgen(n)*(limit-base)/(n-1)
  return,  v

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
;   This calculates the 2D Meyer spectra to be used in the finite isotropic wavelet transform
;
; INPUTS:
;   n: size of the input image (must be square)
;   nscales: number of scales that will be used in the wavelet decomposition, Default set to 3
;
; RETURNS:
;   A 3D matrix of wavelet values in the frenquency domain of size [nscales+1, n, n]
;
; HISTORY:
;   May-2017 Written by Miguel A. Duval-Poo
;   01-Nov-2017, Kim. Changed FIVE_CS to VIS_WV
;
; CONTACT:
;   duvalpoo [at] dima.unige.it
;
;-
function vis_wv_fiwt_spectra, n, nscales

  default, n, 128
  default, nscales, 3

  ; for better symmetrie each n should be odd
  n_orig = n
  n_new = n + (1-(n mod 2))

  ; create meshgrid
  ; largest value where psi_1 is equal to 1
  ; assuming that a = 2^-j
  X = 2.^(nscales-1)
  xi_x_init = vis_wv_linspace(0,X,(n_new+1)/2)
  xi_x_init = [-reverse(xi_x_init[1:n_elements(xi_x_init)-1],1), xi_x_init]
  vis_wv_meshgrid, xi_x_init, reverse(xi_x_init,1), xi_x, xi_y

  ; init
  psi = replicate(0.,nscales+1,n_new,n_new)

  ; lowpass
  psi[0,*,*] = vis_wv_meyer_scaling(sqrt(xi_x^2+xi_y^2))

  ; loop for each scale
  for j = 0,nscales-1 do begin
    a = 2.^(-j)
    ax = a*sqrt((xi_x)^2 + (xi_y)^2)
    psi[j+1,*,*] = vis_wv_meyer_wavelet(ax)
  endfor

  ; generate output with size n
  psi = psi[*, 0:n_orig-1, 0:n_orig-1]

  return, psi
end
