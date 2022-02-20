;+
;
; NAME:
;   mem_ge_entropy
;
; PURPOSE:
;   This function computes the value of the entropy of an image, i.e.
;
;                    H(x) = sum_i x_i * log(x_i/(m e))
;
;   where 'x' is an image and 'm' is the total flux divided by the number of pixels of the image
;
; INPUTS:
;   x: image
;   m: total flux divided by the number of pixels of the image
;
; OUTPUTS:
;   value of the entropy of the image
;
; HISTORY: May 2018, Massa P. and Benvenuto F. created
;
; CONTACT:
;   massa.p [at] dima.unige.it
;   benvenuto [at] dima.unige.it
;-
function mem_ge_entropy, x, m

  return, total( x*alog( x/(m*exp(1.) ) ) )

end

;+
;
; NAME:
;   mem_ge_prox_entropy
;
; PURPOSE:
;   This function computes the value of the proximity operator of the entropy function subject to
;   positivity constraint, i.e. it solves the problem
;
;                 argmin_x 1/2*|| y-x ||^2 + \lambda/Lip * H(x)
;                 subject to x >= 0
;
;   Actually, this problem can be reduced to finding the zero of the gradient of the objective
;   function and it is therefore solved by means of a bisection method.
;
;  INPUTS:
;   y: image
;   m: total flux divided by the number of pixels of the image
;   lambda: regularization parameter
;   Lip: Lipschitz constant of the gradient of the \chi^2 function
;
; OUTPUTS:
;   value of the proximity operator of the entropy subject to positivity constraint
;
; HISTORY: May 2018, Massa P. and Benvenuto F. created
;
; CONTACT:
;   massa.p [at] dima.unige.it
;   benvenuto [at] dima.unige.it
;-

function mem_ge_prox_entropy, y, m, lambda, Lip

  ;;;;;;;;;;; INITIALIZATION OF THE BISECTION METHOD

  a = y*0. + 10.^(-24.)
  b = y > m

  a = double(a)
  b = double(b)

  ;;;;;;;;;;; BISECTION LOOP

  while(max(b-a) gt 10.^(-10.)) do begin
    c = (a+b)/2.
    f_c = c - y + lambda/Lip*alog(c/m)

    tmp1 = where(f_c le 0.)
    tmp2 = where(f_c ge 0.)

    a[tmp1] = c[tmp1]
    b[tmp2] = c[tmp2]

  endwhile

  c = (a+b)/2.
  return, c

end

;+
;
; NAME:
;   mem_ge_prox_operator
;
; PURPOSE:
;   This function computes the value of the proximity operator of the entropy function subject to
;   positivity constraint and flux constraint by means of a Dykstra-like proximal algorithm
;   (see Combettes, Pesquet, "Proximal Splitting Methods in Signal Processing", (2011)).
;   The problem to solve is:
;
;                       argmin_x 1/2*|| x - y ||^2 + \lambda/Lip * H(x)
;
;   subject to positivity constraint and flux constraint.
;
;  INPUTS:
;   y: image
;   f: total flux of the image
;   m: total flux divided by the number of pixels of the image
;   lambda: regularization parameter
;   Lip: Lipschitz constant of the gradient of the \chi^2 function
;
; OUTPUTS:
;  returns a structure that contains: 
;  - prox: value of the proximity operator of the entropy function subject to positivity constraint and
;          flux constraint
;  - iter: number of iterations computed for the Dykstra-like splitting
; HISTORY: May 2019, Massa P. and Benvenuto F. created
;          Sep 2019, Massa P., reduced 'niter' from 1000 to 250 and modified the output of the function
; 
;
; CONTACT:
;   massa.p [at] dima.unige.it
;   benvenuto [at] dima.unige.it
;-

function mem_ge_prox_operator, z, f, m, lambda, Lip

  niter = 250.
  
  ;;;;;;;;;;; INITIALIZATION OF THE DYKSTRA-LIKE SPLITTING
  x = z
  p = x*0.
  q = p

  for iter=1, niter do begin

    tmp = x + p
    ;; Projection on the hyperplane that represents the flux constraint
    y = tmp  + (f-total(tmp))/n_elements(tmp)
    p = x + p - y

    x = mem_ge_prox_entropy(y+q, m, lambda, Lip)

    if abs(total(x)-f) le 0.01*f then break
    
    q = y + q - x

  endfor
  
  return, {prox: x, iter:iter}

end

;+
;
; NAME:
;   mem_ge_fb
;
; PURPOSE:
;   This function solves the optimization problem
;
;                         argmin_x \chi^2(x) + \lambda * H(x)
;
;   subject to positivity constraint and flux constraint (x is the image to reconstruct,
;   \lambda is the regularization parameter and H(x) is the entropy of the image).
;   The algorithm implemented is a forward-backward splitting algorithm
;   (see Combettes,  Pesquet, "Proximal Splitting Methods in Signal Processing" (2011) and
;   Beck, Teboulle, "Fast Gradient-Based Algorithms for Constrained Total Variation Image Denoising
;   and Deblurring Problems" (2009)).
;
;  INPUTS:
;   Hv: Fourier matrix used to calculate the visibilities of the photon flux
;       (actually, Hv = [Re(F); Im(F)] where F is the complex Fourier matrix)
;   Visib: array containing the values of the visibilities (actually, Visib=[Re(vis), Im(vis)] where
;          'vis' is the complex array containing values of the visibilities)
;   Lip: Lipschitz constant of the gradient of the \chi^2 function
;   flux: total flux of the image
;   lambda: regularization parameter
;   imsize: array containing the size (number of pixels) of the image to reconstruct
;   pixel: array containing the pixel size (in arcsec) of the image to reconstruct
;   maxiter: maximum number of iterations
;   silent: if not set, plots the values of the objective function at each iteration
;   tol: tolerance value used in the stopping rule ( || x - x_old || <= tol || x_old ||)
;
; OUTPUTS:
;   x: reconstructed image
;
; HISTORY: May 2019, Massa P. and Benvenuto F. created
;          September 2019, Massa P. and Benvenuto F., added break when the number of iterations done
;                          to update the minimizer is too big.
;          September 2019, Kim, fixed bug in check for whether to break
;
; CONTACT:
;   massa.p [at] dima.unige.it
;   benvenuto [at] dima.unige.it
;-

function mem_ge_fb, Hv, Visib, Lip, flux, lambda, imsize, pixel, maxiter, silent, tol

  ;; 'f': value of the total flux of the image (taking into account the area of the pixel)
  f = flux/(pixel[0]*pixel[1])
  ;; 'm': total flux divided by the number of pixels of the image
  m = f/(float(imsize[0])*float(imsize[1]))

  ;;;;;;;;;;; INITIALIZATION

  ;; 'x': constant image with total flux equal to 'f'
  x = fltarr(imsize[0], imsize[1]) + 1.
  x = x/total(x)*f
  z=x
  t=1.

  ;;;;;;;;;;; COMPUTATION OF THE OBJECTIVE FUNCTION 'J'

  tmp = x[*]
  Hvx = Hv # tmp
  f_R = mem_ge_entropy(x, m)

  diff_V = Hvx - Visib
  f_0 = total(diff_V^2.)
  J = f_0 + lambda*f_R

  n_iterations = 0 ;; number of iterations done in the proximal steps to update the minimizer
  for iter = 1, maxiter do begin

    J_old = J
    x_old = x
    t_old = t

    ;;;;;;;;;;; GRADIENT STEP

    grad = 2.*reform(Hv ## (Hv # z[*] - Visib), imsize[0], imsize[1] )
    y = z - 1./Lip* grad

    ;;;;;;;;;;; PROXIMAL STEP
    proximal =  mem_ge_prox_operator(y, f, m, lambda, Lip)
    p=proximal.prox
    
    ;;;;;;;;;;; COMPUTATION OF THE OBJECTIVE FUNCTION 'Jp' IN 'p'

    tmp = p[*]
    Hvp = Hv # tmp
    f_Rp = mem_ge_entropy(p, m)

    diff_Vp = Hvp - Visib
    f_0 = total(diff_Vp^2.)
    Jp = f_0 + lambda*f_Rp

    ;;;;;;;;;;; CHEK OF THE MONOTONICITY

    ;; we update 'x' only if 'Jp' is less than or equal to 'J_old'
    check = 1.
    if Jp gt J_old then begin

      x = x_old
      J = J_old
      check = 0.
      n_iterations += proximal.iter
    
    endif else begin

      x = p
      J = Jp
      n_iterations = 0

    endelse
    
    if n_iterations ge 500. then break ;; if the number of iterations done to update 'x' is too big, then break
    
    ;;;;;;;;;;; ACCELERATION

    t = (1+sqrt(1.+4.*t_old^2.))/2.
    tau = (t_old-1.)/t
    z = x + tau*(x - x_old) + (t_old/t)*(p - x)


    if ~keyword_set(silent) then print, 'Iter: ', iter, ' Obj function: ', J
    
    if (check and (  sqrt(total((x - x_old)^2.)) lt tol*sqrt(total(x_old^2.))  ) ) then break

  endfor


  return, x_old


end
