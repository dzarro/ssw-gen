;+
;
; NAME:
;   mem_ge_mean_visib
;
; PURPOSE:
;   This function computes the mean value of the visibilities that correspond to the same 
;   sampling point in the discretization of the (u,v) plane
;
; INPUTS:
;   u1: array containing the u coordinates of the sampling frequencies
;   v1: array containing the v coordinates of the sampling frequencies
;   vis: array containing the values of the visibilities
;   sigma: array containing the standard deviation of the amplitude of the visibilities
;   imsize: number of pixels of a single dimension of the image
;   uvint: size of the pixel in the (u, v)-plane
;
; OUTPUTS
;   structure containing:
;   u: array containing the u coordinates of the of the sampling frequencies (if two original 
;      frequencies correspond to the same sampling point in the discretization of the (u,v) plane,
;      just one u coordinate is kept in the array)
;   v: array containing the v coordinates of the of the sampling frequencies (if two original
;      frequencies correspond to the same sampling point in the discretization of the (u,v) plane,
;      just one v coordinate is kept in the array)
;   obsvis: array containing the mean value of the visibilities that correspond to the same 
;           sampling point in the discretization of the (u,v) plane
;   wgt: array containing the standard deviations related to values saved in 'obsvis' 
;
; HISTORY: May 2018, Massa P. and Benvenuto F. created
;
; CONTACT:
;   massa.p [at] dima.unige.it
;   benvenuto [at] dima.unige.it
;-

function mem_ge_mean_visib, u1, v1, vis, sigma, imsize, uvint

  imsize2 = imsize / 2

  iu = u1 / uvint
  iv = v1 / uvint
  ru = round(iu)
  rv = round(iv)
  
  ;; 'ru': index of the u coordinates of the sampling frequencies in the discretization of the u axis
  ru = ru + imsize2
  ;; 'rv': index of the v coordinates of the sampling frequencies in the discretization of the v axis
  rv = rv + imsize2

  ;; 'iuarr': matrix that represents the discretization of the (u,v)-plane
  iuarr = fltarr(imsize, imsize)

  count = 0
  u = iu*0.
  v = iv*0.
  den = u
  wgtarr = u
  visib = complexarr(n_elements(vis))
  for ip = 0l, n_elements(vis) - 1l do begin
    i = ru[ip]
    j = rv[ip]
    ;(i, j) is the position of the spatial frequency in the discretization of the (u,v)-plane 'iuarr' 
    if iuarr[i,j] eq 0. then begin
      
      u[count] = u1[ip]
      v[count] = v1[ip]
      ;we save in 'u' and 'v' the u and v coordinates of the first frequency that corresponds to the 
      ;position (i, j) of the discretization of the (u,v)-plane 'iuarr'
       
      visib[count] = vis[ip] 
      wgtarr[count] = sigma[ip]^2.
      den[count] = 1.
      iuarr[i, j] = count 
      
      count += 1.
    endif else begin
      
      ;; in 'visib' we save the sum of the visibilities that correspond to the same position (i, j)
      visib[iuarr[i, j]] += vis[ip]
      ;; in 'den' we save the number of the visibilities that correspond to the same position (i, j)
      den[iuarr[i, j]] += 1.
      ;; in 'wgtarr' we save the sum of the variances of the amplitudes of the visibilities that 
      ;; correspond to the same position (i, j)
      wgtarr[iuarr[i, j]] += sigma[ip]^2. 
    endelse
    
  endfor
  
  u = u[0:count-1.]
  v = v[0:count-1.]
  visib = visib[0:count-1]
  den = den[0:count-1.]
  
  ;; computation of the mean value of the visibilities that correspond to the same
  ;; position in the discretization of the (u,v)-plane
  visib = visib/den
  ;; computation of the mean value of the standard deviation of the visibilities that 
  ;; correspond to the same position in the discretization of the (u,v)-plane
  wgtarr = sqrt(wgtarr[0:count-1])/den
    
   return, {u : u, v : v, obsvis : visib, $
      wgt : wgtarr}
end
