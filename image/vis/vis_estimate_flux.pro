;+
;
; NAME:
;   vis_estimate_flux
;
; PURPOSE:
;   This function estimates the total flux of an event by solving the problem
;   
;     argmin \chi2(f) = total( ( (real_vis(f) - real_vis_obs)^2 + (imag_vis_(f) - imag_vis_obs)^2 ) / sigamp^2 )
;     
;     subject to f >=0,
;   
;   i.e. the algorithm finds a positive image 'f' that minimizes the chi square function. The estimation 
;   of the total flux is then obtained by computing the total fux of 'f'. The method implemented
;   for the minimization is projected Landweber.   
;
;  INPUTS:
;   vis: visibility bag (the fields used are u, v, obsvis and sigamp) 
;   fov: field of view of the event
;  
;  KEYWORDS:
;   imsize: number of pixels of the recostruced image (default [64, 64])
;   maxiter: maximum number of iteration (default 1000)
;   silent: if not set, plots the values of the \chi2 function at each iteration
;   tol: tolerance value used in the stopping rule ( || x - x_old || <= tol || x_old ||)
;
; OUTPUTS:
;   estimated total flux
;
; HISTORY: September 2019, Massa P. created
;
; CONTACT:
;   massa.p [at] dima.unige.it
;-

function vis_estimate_flux, vis, fov, imsize=imsize, maxiter=maxiter, silent=silent, tol=tol

  default, imsize, [64, 64]
  default, maxiter, 1000
  default, silent, 0.
  default, tol, 1e-3

  pix = fov/imsize[0]
  pixel = [pix, pix]
  
  
  Hv = vis_map2vis_matrix(vis.u, vis.v, imsize, pixel)
  ;; Division of real and imaginary part of the matrix 'Hv'
  ReHv = real_part(Hv)
  ImHv = imaginary(Hv)
  ;; 'Hv' is composed by the union of its real and imaginary part
  Hv = [ReHv, ImHv]

  ;; Division of real and imaginary part of the visibilities
  ReV = real_part(vis.obsvis)
  ImV = imaginary(vis.obsvis)
  ;; 'Visib' is composed by the real and imaginary part of the visibilities
  Visib = [ReV, ImV]

  ;; Standard deviation of the real and imaginary part of the visibilities
  sigma_Re = vis.sigamp
  sigma_Im = vis.sigamp
  ;; 'sigma': standard deviation of the data contained in 'Visib'
  sigma = [sigma_Re, sigma_Im]

;;;;;;;;;;; RESCALING OF 'Hv' AND 'Visib' (NEEDED FOR COMPUTING THE VALUE OF THE \chi^2 FUNCTION)

  ;; The vector 'Visib' and every column of 'Hv' are divided by 'sigma'
  Visib = Visib / sigma
  ones = fltarr(float(imsize[0])*float(imsize[1])) + 1.
  sigma1 = ones ## sigma
  Hv = Hv / sigma1

;;;;;;;;;;; COMPUTATION OF THE LIPSCHITZ CONSTANT 'Lip' OF THE GRADIENT OF THE \chi^2 FUNCTION
;;;;;;;;;;; (NEEDED TO GUARANTEE THE CONVERGENCE OF THE ALGORITHM)

  HvHvT = Hv # transpose(Hv)
  Lip = 2.1*norm(HvHvT, lnorm=2)
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; PROJECTED LANDWEBER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  x = fltarr(imsize[0], imsize[1])
  
;;;;;;;;;;; COMPUTATION OF THE OBJECTIVE FUNCTION 'chi2'

  tmp = x[*]
  Hvx = Hv # tmp

  diff_V = Hvx - Visib
  chi2 = total(diff_V^2.)
  

  for iter = 1, maxiter do begin
    

    x_old = x
    ;;;;;;;;;;; GRADIENT STEP
    
    grad = 2.*reform(Hv ## (Hv # x[*] - Visib), imsize[0], imsize[1] )
    y = x - 1./Lip* grad
    
    ;;;;;;;;;;; PROJECTION ON THE POSITIVE ORTHANT
    
    x = y > 0.
    
    
    tmp = x[*]
    Hvx = Hv # tmp
    
    diff_V = Hvx - Visib
    chi2 = total(diff_V^2.)
    
    if ~keyword_set(silent) then print, 'Iter: ', iter, ' Chi2: ', chi2
    if sqrt(total((x - x_old)^2.)) lt tol*sqrt(total(x_old^2.)) then break
    
  endfor
 
  
  return, total(x)*pixel[0]*pixel[1]

end