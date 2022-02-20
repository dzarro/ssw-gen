;+
; Name: xy_dist
;
; Purpose: Calculate distance between points, optionally with uncertainties
;
; Project:  HESSI
;
; Calling Sequence:
;	result = xy_dist (p0, p [, p0_sig=p0_sig, p_sig=p_sig, dist_sig=dist_sig])
;
; Input arguments:
;	p0 - x,y coordinates of starting point
;	p - x, y values of points to find distance from p0.  Can be (2) or (2,n)
;
;	Input Keywords:
;	p0_sig - 1 sigma uncertainties on p0 x,y
;	p_sig  - 1 sigma uncertainties on p x,y. Same dimensions as p.
;
;	Output Keywords:
;	dist_sig - 1 sigma uncertainty on distance returned by function (same dimension as distance)
;
; Output:
;	Result is distance between p0 and p (scalar or vector depending on p)
;
; Written: Kim Tolbert, 19-Mar-2002
; Modifications:
; 30-Apr-2020, Brian Dennis
;   Added uncertainties based on the equation in
;   https://en.wikipedia.org/wiki/Propagation_of_uncertainty#Simplification
;   For f = sqrt(A^2 + B^2)
;   sigm_f^2 = (A/f)^2 sigma_A^2 + (B/f)^2 sigma_B^2 +/- 2 (AB/f^2) sigma_AB
;   Let sigma_AB = 0
;
;---------------------------------------------------------------------------------
function xy_dist, p0, p, p0_sig=p0_sig, p_sig=p_sig, dist_sig=dist_sig

  dist = -1
  dist_sig = -1

  if n_elements(p0) ne 2 or n_elements(p) lt 2 then begin
    message, 'Syntax: distance = xy_dist(p0, p), p0 is 2-element array, p is (2,n)', /cont
    return, dist
  endif

  if keyword_set(p0_sig) then begin
    if ~( same_size(p0,p0_sig) and same_size(p,p_sig) ) then begin
      message, 'Syntax: distance = xy_dist(p0, p, p0_sig=p0_sig, p_sig=p_sig, dist_sig=dist_sig), p0_sig,p_sig must match dimensions of p0,p', /cont
      return, dist
    endif
    do_sig = 1
  endif else do_sig = 0

  dist = sqrt( (p[0,*] - p0[0])^2 + (p[1,*] - p0[1])^2 )

  if do_sig then begin
    dist_sig = sqrt( ((p[0,*] - p0[0])/dist)^2 * (p_sig[0,*]^2 + p0_sig[0]^2) + $
      ((p[1,*] - p0[1])/dist)^2 * (p_sig[1,*]^2 + p0_sig[1]^2) )
    dist_sig = n_elements(dist_sig) eq 1 ? dist_sig[0] : reform(dist_sig)
  endif

  if n_elements(dist) eq 1 then dist=dist[0] else dist=reform(dist)
  return, dist
end