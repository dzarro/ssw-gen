;+
;
; NAME:
;   vis_wv (Finite Isotropic waVElet transform Compressed Sensing: 5-CS)
;
; PURPOSE:
;   Visibility based image recostructions by means by means of compressed sensing and finite isotropic wavelet transform (FIWT)
;   Solves the the following minimization problem: min_x {||B-Hx||^2_2 + \lambda||Wx||_1}
;
; CALLING SEQUENCE:
;   vis = ...
;   imsize = 129
;   nscales = 3
;   map = vis_wv(vis, nscales=nscales, imsize=imsize, /autolam, /silent, /makemap)
;
; INPUTS:
;   vis: input visibility structure in standard format
;
; KEYWORDS:
;   NSCALES: number of scales that will be used in the wavelet decomposition (default set to 3)
;   IMSIZE: output map size in pixels (odd number)
;   PIXEL: pixel size in asec (default is 1)
;   NITER: max number of iterations (default is 200)
;   AUTOLAM: automatically estimate the regularization parameter \lambda
;   LAM: set the regularization parameter if autolam=0 (default is 0.05)
;   SILENT: if not set, plots the min func values at each iteration (default is 1)
;   MAKEMAP: if set, returns the map structure. Otherwise returns the 2D matrix
;
; RETURNS:
;   map: image map in the structure format provided by the routine make_map.pro
;
; RESTRICTIONS:
;   -For better symmetrie IMSIZE should be odd
;
; PAPER:
;   Duval-Poo, M. A., M. Piana, and A. M. Massone. "Solar hard X-ray imaging by means of Compressed Sensing and Finite Isotropic Wavelet Transform." (2017).
;   https://arxiv.org/abs/1708.03877
;
; HISTORY:
;   June-2017 Written by Miguel A. Duval-Poo
;   Oct-2017 M.A. Duval-Poo, Minor bugs fixed
;   01-Nov-2017, Kim. Changed FIVE_CS to VIS_WV, and modified print statements
;
; CONTACT:
;   duvalpoo [at] dima.unige.it
;
;-
function vis_wv, vis, NSCALES=nscales, IMSIZE=imsize, PIXEL=pixel, NITER=niter, LAM=lam, SILENT=silent, AUTOLAM=autolam, MAKEMAP=makemap

  default, imsize, [129, 129]
  default, pixel, [1.0, 1.0]
  default, nscales, 3
  default, lam, 0.05
  default, niter, 200
  default, silent, 1
  default, autolam, 1
  default, makemap, 0

  ; input parameters control
  if imsize[0] ne imsize[1] then message, 'Error: imsize must be square.'

  if pixel[0] ne pixel[1] then message, 'Error: pixel size per dimension must be equal.'

  if ~(imsize[0] mod 2) then message, 'Error: imsize must be an odd number.'

  ; set the wavelt spectra (if exists with the same dimensions then reuse it, if not, build a new one)
  common wspectra, psi
  psi_size = size(psi, /DIMENSIONS)
  if n_elements(psi_size) ne 3  || psi_size[0] ne nscales+1 || psi_size[1] ne imsize[0] || psi_size[2] ne imsize[0] then begin
    psi = vis_wv_fiwt_spectra(imsize[0], nscales)
  endif

  ; backprojection map
  vis_bpmap, vis, map=dirty_map, bp_fov=imsize[0]*pixel[0], pixel=pixel[0]

  ; dirty beam
  psf = vis_psf(vis, pixel=pixel[0], image_dim=imsize[0])

  ; start
  B = real_part(dirty_map)
  P = real_part(psf)/total(psf) ; normalized!

  if total(size(B, /DIMENSIONS)) ne total(size(P, /DIMENSIONS)) then message, 'Error: size(dirty_map) must be equal to size(psf).'

  center = fix(imsize/2)
  cidx =  where(vis.isc eq max(vis.isc), dcount)
  dc = max(real_part(vis.obsvis[cidx]))

  P = fft(shift(P, 1-center))*n_elements(P)

  ; flux constraint initial scaling
  B = B*(dc/total(B))

  ; computing the two dimensional transform of B
  Btrans = fft(B)

  ; the Lipschitz constant
  L = 2*max(abs(P)^2)

  ; initialization
  old_total_val = 0
  X_iter = B
  Y = X_iter
  t_new = 1

  if keyword_set(autolam) then begin
    lam = 0 ; that is, solve the first iteration without regularization and based on the solution estimate lambda
  endif
  
  if ~keyword_set(silent) then print, 'VIS_WV iterations: '

  for i = 1,niter do begin
    ; store the old value of the iterate and the t-constant
    X_old = X_iter
    t_old = t_new

    ; gradient step
    D = P*fft(Y)-Btrans
    Y = Y-2./L*fft(conj(P)*D, /inverse)

    ; wavelet transform
    WY = vis_wv_fiwt(real_part(Y), psi)

    ; soft thresholding
    D = abs(WY)-lam/L
    WY =  signum(abs(WY))*((D gt 0)*D)

    ; the new iterate inverse wavelet transform of WY
    X_iter = real_part(vis_wv_fiwt(WY, psi, /inverse))

    ; flux constraint
    X_iter = X_iter - (total(X_iter)-dc)/(imsize[0]*imsize[0])

    ; updating t and Y
    t_new = (1+sqrt(1.+4*t_old^2))/2.
    Y = X_iter+((t_old-1)/t_new)*(X_iter-X_old)

    ; evaluating
    residual = B - real_part(fft(P*fft(X_iter), /inverse))
    likelyhood = norm(abs(residual[*]))^2
    sparsity = total(abs(vis_wv_fiwt(X_iter, psi)))

    ; lambda estimation
    if i eq 1 and keyword_set(autolam) then begin
      lam = likelyhood/sparsity
    endif

    total_val = likelyhood + lam*sparsity

    ; printing the information of the current iteration
    if ~keyword_set(silent) then print, 'iter, total_val, total |image|, likelihood:', i, total_val, total(abs(X_iter)), likelyhood

    ; stopping criteria
    if i gt 9 and old_total_val le total_val then break

    old_total_val = total_val

  endfor

  if ~keyword_set(silent) then print, 'Lambda: ', lam

  X_iter = real_part(X_iter*(X_iter gt 0))

  return, makemap ? make_map(X_iter,xcen=vis.xyoffset[0],ycen=vis.xyoffset[1], dx=pixel[0], dy=pixel[0], id = 'VIS_WV', time=anytim(vis[0].trange[0],/ecs)) : X_iter

end
