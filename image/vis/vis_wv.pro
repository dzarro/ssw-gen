;+
;
; NAME:
;   vis_wv (Finite Isotropic WaVelet transform Compressed Sensing)
;
; PURPOSE:
;   Visibility-based image recostruction by means of compressed sensing and finite isotropic wavelet transform (FIWT)
;
; CALLING SEQUENCE:
;   wv_map = vis_wv(vis, nscales=nscales, imsize=imsize, pixel=pixel, niter=niter,lam=lam, /autolam, /silent, /makemap)
;
; INPUTS:
;   vis: input visibility structure in standard format
;
; KEYWORDS:
;   NSCALES: number of scales that will be used in the wavelet decomposition (default set to 3)
;   IMSIZE:  output image size in pixels (default [129, 129])
;   PIXEL:   pixel size in arcsec (default is [1,1])
;   NITER:   max number of iterations (default is 200)
;   AUTOLAM: if set to 1 automatic estimation of the regularization parameter (default); 
;            if set to 0 regularization parameter fixed 
;   LAM:     fixed value for the regularization parameter if autolam=0 (default is 0.05)
;   SILENT:  if not set, the actual minimum of the objective function at each iteration is printed (default is 1)
;   MAKEMAP: if set, return the map structure, otherwise the 2D matrix (default is 0)
;
; OUTPUTS:
;   wv_map:  if makemap=1 --> map in the structure format provided by the routine make_map.pro
;            if makemap=0 --> 2D image
;
; RESTRICTIONS:
;   -For better symmetry IMSIZE values must be odd
;
; PAPER:
;   Duval-Poo, M. A., M. Piana, and A. M. Massone. "Solar hard X-ray imaging by means of Compressed Sensing and Finite Isotropic Wavelet Transform."
;   Astronomy & Astrophysics , 615, A59, 2018
;
; HISTORY:
;   June-2017 Written by Miguel A. Duval-Poo
;   Oct-2017 M.A. Duval-Poo, Minor bugs fixed
;   01-Nov-2017, Kim. Changed FIVE_CS to VIS_WV, and modified print statements
;   12-Feb-2019, P. Massa:
;                - imsize[0] casted to float; 
;                - added pixel size as input for 'vis_wv_fiwt_spectra';
;                - fixed bugs in the computation of 'dc' and 'WY' variables;
;                - prevented the regularization parameter to be too high in order avoid null solutions;
;                - fixed units for the solution in photons * cm^-2 * arcsec^-2 * s^-1;
;                - added a 'catch' block of instructions for STIX/RHESSI time_range compatibility;
;   01-Mar-2019  - fixed bug in wavelet spectra computation
;
; CONTACT:
;   massa.p  [at] dima.unige.it
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

  ; set the wavelet spectra
  psi = vis_wv_fiwt_spectra(imsize[0], nscales, pixel[0])
  
  ; backprojection map
  vis_bpmap, vis, map=dirty_map, bp_fov=imsize[0]*pixel[0], pixel=pixel[0]

  ; dirty beam
  psf = vis_psf(vis, pixel=pixel[0], image_dim=imsize[0])

  ; start
  B = real_part(dirty_map)
  P = real_part(psf)/total(psf) ; normalized!

  if total(size(B, /DIMENSIONS)) ne total(size(P, /DIMENSIONS)) then message, 'Error: size(dirty_map) must be equal to size(psf).'

  center = fix(imsize/2)
  ; flux constraint 
  u = vis.u
  v = vis.v
  d = sqrt(u^2. + v^2.)
  cidx =  where(d eq min(d))
  dc = max(real_part(vis[cidx].obsvis))

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
    lam = 0 ; i.e., solve the first iteration without regularization 
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
    WY =  signum(WY)*((D gt 0)*D)

    ; the new iterate inverse wavelet transform of WY
    X_iter = real_part(vis_wv_fiwt(WY, psi, /inverse))

    ; flux constraint
    X_iter = X_iter - (total(X_iter)-dc)/float(imsize[0])^2. 
    
    ; updating t and Y
    t_new = (1+sqrt(1.+4*t_old^2))/2.
    Y = X_iter+((t_old-1)/t_new)*(X_iter-X_old)

    ; evaluating
    residual = B - real_part(fft(P*fft(X_iter), /inverse))
    likelyhood = norm(abs(residual[*]))^2
    sparsity = total(abs(vis_wv_fiwt(X_iter, psi)))

    ; lambda estimation
    if i eq 1 and keyword_set(autolam) then begin
      lam = min([likelyhood/sparsity, max(abs(fft(conj(P)*Btrans, /inverse)))])
    endif

    total_val = likelyhood + lam*sparsity

    ; printing the information of the current iteration
    if ~keyword_set(silent) then print, 'iter, total_val, total |image|, likelihood:', i, total_val, total(abs(X_iter)), likelyhood

    ; stopping criteria
    if i gt 9 and old_total_val le total_val then break

    old_total_val = total_val

  endfor

  if ~keyword_set(silent) then print, 'Lambda: ', lam

  X_iter = real_part(X_iter*(X_iter gt 0))/(pixel[0]*pixel[1])
  
  flag=1
  catch, error_status

  if error_status ne 0 then begin
    aux = vis[0].time_range[0].value
    time = anytim(aux.time, mjd = aux.mjd, /ecs)
    flag = 0
    catch, /cancel
    endif

  if flag then time = anytim(vis[0].trange[0], /ecs)
  
  return, makemap ? make_map(X_iter,xcen=vis.xyoffset[0],ycen=vis.xyoffset[1], dx=pixel[0], dy=pixel[0], id = 'VIS_WV', time=time) : X_iter

end
