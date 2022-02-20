;+
;
; NAME:
;   mem_ge
;
; PURPOSE:
;   Maximum Entropy Method for visibility based image reconstruction
;   
; CALLING SEQUENCE: 
;   map = mem_ge(vis, imsize=imsize, pixel = pixel, /makemap)
;
; INPUTS:
;   vis: visibility structure
;   total_flux: 
;   
; OUTPUTS:
;   image map in the structure format provided by the routine make_map.pro
;
; KEYWORDS:
;
;   percent_lambda: value used to compute the regularization parameter as a percentage of a maximum 
;                value automatically overestimated by the algorithm. 
;                Must be in the range [0.0001,0.2] (default, 0.02)
;   imsize: array containing the size (number of pixels) of the image to reconstruct
;           (default, [129, 129])
;   pixel: array containing the pixel size (in arcsec) of the image to reconstruct
;          (default, [1., 1.])
;   maxiter: maximum number of iterations of the optimization loop
;           (default, 1000)
;   makemap: if set, returns the map structure. Otherwise returns the 2D matrix
;           (default, 0)
;   silent: if not set, plots the values of the objective function at each iteration
;           (default, 0)
;   tol: tolerance value used in the stopping rule ( || x - x_old || <= tol || x_old ||)
;         (default, 10^(-8))
;
;
; HISTORY: May 2019, Massa P. and Benvenuto F. created
;          September 2019, Massa P. added input total_flux, set tol to 1.e-3 (was 1.e-8), call vis_map2vis_matrix instead of mem_ge_buildhv,
;            and remove old code that calculated total flux
; 
; CONTACT:
;   massa.p [at] dima.unige.it
;   benvenuto [at] dima.unige.it
;-

function mem_ge, vis, total_flux, percent_lambda = percent_lambda, $
  imsize=imsize, pixel = pixel, maxiter = maxiter, makemap=makemap, silent=silent, $
  tol=tol

  default, percent_lambda, 0.02
  default, imsize, [129, 129]
  default, pixel, [1., 1.]
  default, maxiter, 1000
  default, makemap, 0
  default, silent, 0.
  default, tol, 1e-3

  if  ( percent_lambda lt 0.0001) or (percent_lambda gt 0.2) then message, 'Percent_lambda value must be in the range [0.0001,0.2]'


;;;;;;;;;;; CREATION OF THE MATRIX 'Hv' THAT MAPS AN IMAGE INTO THE SET OF VISIBILITIES AND 
;;;;;;;;;;; CREATION OF THE DATA 'Visib'

  ;; 'uvint': size of the pixel in the (u, v)-plane (just used in the function 'mem_ge_mean_visib')
  uvint = 1./(imsize[0]*pixel[0])
  
  ;; 'mem_ge_mean_visib': computes the mean value and the standard deviation of the amplitude of the visibilities 
  ;; that correspond to the same sampling point in the discretization of the (u,v)-plane 
  vis1 = mem_ge_mean_visib( vis.u, vis.v, vis.obsvis, vis.sigamp, long(imsize[0]), double(uvint) )
  
  ;; mem_ge_buildhv: routine for creating the complex Fourier matrix 'Hv' used to compute the value of the 
  ;; visibilities (i.e. if x is the vectorialized image, then v = Hv # x is the vector containing the complex 
  ;; values of the visiblities)
  Hv = vis_map2vis_matrix(vis1.u, vis1.v, imsize, pixel)
  ;; Division of real and imaginary part of the matrix 'Hv'
  ReHv = real_part(Hv)
  ImHv = imaginary(Hv)
  ;; 'Hv' is composed by the union of its real and imaginary part
  Hv = [ReHv, ImHv]
  
  ;; Division of real and imaginary part of the visibilities
  ReV = real_part(vis1.obsvis)
  ImV = imaginary(vis1.obsvis)
  ;; 'Visib' is composed by the real and imaginary part of the visibilities
  Visib = [ReV, ImV]

;;;;;;;;;;; RESCALING OF 'Hv' AND 'Visib' (NEEDED FOR COMPUTING THE VALUE OF THE \chi^2 FUNCTION)

  ;; Standard deviation of the real and imaginary part of the visibilities
  sigma_Re = vis1.wgt
  sigma_Im = vis1.wgt
  ;; 'sigma': standard deviation of the data contained in 'Visib'
  sigma = [sigma_Re, sigma_Im]
  
  ;; The vector 'Visib' and every column of 'Hv' are divided by 'sigma'
  Visib = Visib / sigma
  ones = fltarr(float(imsize[0])*float(imsize[1])) + 1.
  sigma1 = ones ## sigma
  Hv = Hv / sigma1

;;;;;;;;;;; COMPUTATION OF THE LIPSCHITZ CONSTANT 'Lip' OF THE GRADIENT OF THE \chi^2 FUNCTION 
;;;;;;;;;;; (NEEDED TO GUARANTEE THE CONVERGENCE OF THE ALGORITHM)
  
  HvHvT = Hv # transpose(Hv)
  Lip = 2.1*norm(HvHvT, lnorm=2)
  
;;;;;;;;;;; COMPUTATION OF THE REGULARIZATION PARAMETER 'lambda'  
  
  
  tmp = fltarr(imsize[0], imsize[1])
  tmp = tmp[*] + total_flux/(float(imsize[0])*float(imsize[1])*pixel[0]*pixel[1])
  tmp = Hv # tmp
  ;; 'lambda' is computed as a percentage of an overestimated value
  lambda = 2.*max(abs(reform(Hv##(tmp - Visib))))*percent_lambda 
  
  
;;;;;;;;;;; MEM OPTIMIZATION ALGORITHM 'mem_ge_fb' BASED ON A FORWARD-BACKWARD METHOD

  im = mem_ge_fb(Hv, Visib, Lip, total_flux, lambda, imsize, pixel, maxiter, silent, tol)
 
;;;;;;;;;;; MAKE MAP (IF SET) 
 
  flag=1
  catch, error_status

  if error_status ne 0 then begin
    aux = vis[0].time_range[0].value
    time = anytim(aux.time, mjd = aux.mjd, /ecs)
    flag = 0
    catch, /cancel
  endif

  if flag then time = anytim(vis[0].trange[0], /ecs)

  return, makemap ? make_map(im,xcen=vis.xyoffset[0],ycen=vis.xyoffset[1], dx=pixel[0], dy=pixel[0], id = 'MEM_GE', time=time) : im

end
