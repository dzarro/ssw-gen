;+
;
; NAME:
;   vis_map2vis_matrix
;
; PURPOSE:
;   This function creates the complex Fourier matrix 'Hv' that is used to compute the value of the 
;   visibilities. If x is the vectorialized image, then v = Hv # x is the vector containing the 
;   complex values of the visiblities
;
; INPUTS:
;   u: array containing the u coordinates of the sampling frequencies
;   v: array containing the v coordinates of the sampling frequencies
;   imsize: array containing the size (number of pixels) of the image to reconstruct
;   pixel: array containing the pixel size (in arcsec) of the image to reconstruct
;
; OUTPUTS:
;   a complex Fourier matrix that is used to calculate the value of the visibilities.
;
; HISTORY: May 2019, Massa P. and Benvenuto F. created
;          September 2019, Massa P., renamed MEM_GE_BUILDHV to VIS_MAP2VIS_MATRIX
;
; CONTACT:
;   massa.p [at] dima.unige.it
;   benvenuto [at] dima.unige.it
;-
function vis_map2vis_matrix, u, v, imsize, pixel

n_vis = n_elements(u)
npx2  = long(imsize[0])*long(imsize[1])
Hv = complexarr(n_vis, npx2)


xypi = Reform( ( Pixel_coord( [imsize[0], imsize[1]] ) ), 2, imsize[0], imsize[1] ) * (2.0 * !pi * pixel[0])
ic = complex(0.0, 1.0)

for j = 0, n_vis-1 do begin
  phase = u[j] * reform( xypi[0,*,*], npx2) + v[j] * reform( xypi[1,*,*], npx2)
  Hv[j, *] = exp( ic * phase )
endfor

return, Hv * pixel[0] * pixel[1]

end
