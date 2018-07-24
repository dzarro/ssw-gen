


;+
; :description:
;    Comupte the mean square error for two arrays (images).
;     
; :categories:
;    images,
;
; :params:
;    xx : in, True image double or float
;
;    yy : in, Test image double or float
;
; :keywords:
;
; :returns:
;    The mean square error 
;
; :examples:
;    IDL> orig = dist(100, 100)
;    IDL> noisy = orig + randomu(12345, 100, 100)
;    IDL> mse(orig, orig)
;       1.0000000
;    IDL> mse(orig, noisy)
;       0.33243114
;    IDL> mse(noisy, orig)
;       0.33243114
;
; :history:
;
;-
function mse, x, y
  return, mean((x-y)^2.0)
end

;+
; :description:
;    Comupte the normalised mean square error for two arrays (images).
;
; :categories:
;    images,
;
; :params:
;    xx : in, True image double or float
;
;    yy : in, Test image double or float
;
; :keywords:
;
; :returns:
;    The normalised mean square error
;
; :examples:
;    IDL> orig = dist(100, 100)
;    IDL> noisy = orig + randomu(12345, 100, 100)
;    IDL> nmse(orig, orig)
;       1.0000000
;    IDL> nmse(orig, noisy)
;       0.33243114
;    IDL> nmse(noisy, orig)
;      0.33243114
;
; :history:
;
;-
function nmse, x, y
  denom = sqrt(mean(x*x))
  return, sqrt(mse(x, y)/denom)
end

;+
; :description:
;    Comupte the mean Structural SIMilarity index (SSIM) index for two images.
;    SSIM is a symetric bouded comparisom metric which outperforms other meterics
;    when compared to human ranked image simulartiy
;
;    Wang, Z., Bovik, A. C., Sheikh, H. R., & Simoncelli, E. P. (2004).
;    Image Quality Assessment: From Error Visibility to Structural Similarity.
;    IEEE Transactions on Image Processing, 13, 600–612.
;    http://doi.org/10.1109/TIP.2003.819861
;
; :categories:
;    images,
;
; :params:
;    xx : in, True image double or float
;
;    yy : in, Test image double or float
;
; :keywords:
;
; :returns:
;    The mean SSIM 1 if images are identical, less than one if not
;
; :examples:
;    IDL> orig = dist(100, 100)
;    IDL> noisy = orig + randomu(12345, 100, 100)
;    IDL> ms_ssim(orig, orig)
;       1.0000000
;    IDL> ssim(orig, noisy)
;       0.99644917
;    IDL> ssim(noisy, orig)
;       0.99644917
;
; :history:
; ras, where added, 16-may-2017
;-
function mssim, xx, yy, s=s, cs=cs
  ; Make sure the orignal images are not altered
  x = xx
  y = yy

  ; Check images are of equal size
  if ~array_equal(size(x,/dimensions), size(y, /dimensions)) then begin
    message, "Image dimmensions don't match"
  endif

  ; Normalise between 0 to 1 or -1 to 1
  xpos = where( x ge 0.0d, npos)
  if n_elements(x) eq npos then begin ;ras, where added, 16-may-2017
    x = x/max(x)
    y = y/max(y)
  endif else begin
    x[xpos] = x[xpos]/max(x)
    x[~xpos] = x[~xpos]/min(x)
    y[xpos] = y[xpos]/max(y)
    y[~xpos] = y[~xpos]/min(y)
  endelse

  ; Parameters from paper
  K1 = 0.01
  K2 = 0.03
  data_range = 2
  cov_norm = 1.0
  sigma = 1.5
  width = 11

  ; Compte weighted means
  ux = gauss_smooth(x, sigma)
  uy = gauss_smooth(y, sigma)

  ; Compute weighted variances and covariances
  uxx = gauss_smooth(x*x, sigma)
  uyy = gauss_smooth(y*y, sigma)
  uxy = gauss_smooth(x*y, sigma)

  vx = cov_norm * (uxx - ux * ux)
  vy = cov_norm * (uyy - uy * uy)
  vxy = cov_norm * (uxy - ux * uy)

  R = data_range
  C1 = (K1*R)^2
  C2 = (K2*R)^2

  A1 = 2 * ux * uy + C1
  A2 = 2 * vxy + C2
  B1 = (ux^2.0) + (uy^2.0) + C1
  B2 = vx + vy + C2

  D = B1*B2

  S = (A1*A2)/D

  cs=mean(A2/B2)

  ; To avoid edge effects remove filter radius from edge
  pad = (width-1)/2
  return, mean(S[pad:-pad,pad:-pad])
end


;function psnr, x, y
;  err = mse(x, y)
;  return, 10 * alog10((2 ^ 2.0) / err)
;end
;

;+
; :description:
;    Comupte the mean Multiscale - Structural SIMilarity index (MS-SSIM) index for two images.
;
;    !!! For some reason this seems to always be hight than the 1 scale case need to check !!!
;
;    Wang, Z., Simoncelli, E. P., & Bovik, A. C. (2003).
;    Multiscale structural similarity for image quality assessment (pp. 1398–1402).
;    Conf Proc Signals, Systems and Computers,
;    IEEE. http://doi.org/10.1109/ACSSC.2003.1292216
;
;
; :categories:
;    images,
;
; :params:
;    xx : in, True image double or float
;
;    yy : in, Test image double or float
;
; :keywords:
;
; :returns:
;    The mean MS-SSIM 1 if images are identical, less than one if not
;
; :examples:
;   IDL> orig = dist(100, 100)
;   IDL> noisy = orig + randomu(12345, 100, 100)
;   IDL> ms_ssim(orig, orig)
;       1.0000000000000000
;   IDL> ms_ssim(orig, noisy)
;       0.99936907999575553
;   IDL> ms_ssim(noisy, orig)
;       0.99936907999575553
;
; :history:
;
;-
function ms_ssim, xx, yy
  ; Make sure original imags are not altered
  x = xx
  y = yy

  ; Default weights from the paper
  weights = [0.0448, 0.2856, 0.3001, 0.2363, 0.1333]

  ; Only use levels that image size supports
  xdim = size(x, /dimensions)
  n_levels = floor(alog2(min(xdim)+11.0)/2.0) ;The filter size is 11
  weights = weights[0:n_levels-1]
  levels = n_elements(weights)

  ;
  downsample_filter = [1.0,2.0,2.0, 1.0]/4.0

  ; Output arrays
  msssim = fltarr(levels)
  mcs = fltarr(levels)

  for i=0, levels-1 do begin
    ; Compute SSIM
    msssim[i] = mssim(x, y, cs=csout)
    mcs[i]  = csout
    ; Downsample true and test images
    x = (convol(x, downsample_filter, /edge_mirror))[0:*:2,0:*:2]
    y = (convol(y, downsample_filter, /edge_mirror))[0:*:2,0:*:2]
  endfor

  ; Finally compute the product of the weighted products at each level
  return, product((mcs^weights)*(msssim^weights))
end

