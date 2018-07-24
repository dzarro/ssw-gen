;+
; Name        : vis_cs_gaussdict_transform
;
; Purpose     : Transform method for the VIS_CS 2D Gaussian dict.
;               Returns a matrix containing the complex results for the combination of visibilities (columns) and dictionary words (rows),
;               i.e. the coefficients needed for transforming between dictionary and visibility base
;
; History     : 20 Jan 2017, Roman Bolzern (FHNW)
;               - initial release
;
; Contact     : simon.felix@fhnw.ch
;-
;UNTESTED
function vis_cs_gaussdict_transform, $
  gDict, $
  W, $
  H, $
  _vis
  
  n_gDict = n_elements(gDict)
  n_vis = n_elements(_vis)
  cnt = n_gDict * n_vis
  visU = double(reform(replicate(1,n_gDict) ## _vis.U, cnt))
  visV = double(reform(replicate(1,n_gDict) ## _vis.V, cnt))
  a = double(rebin(gDict.a, cnt, /SAMPLE))
  b = double(rebin(gDict.b, cnt, /SAMPLE))
  c = double(rebin(gDict.c, cnt, /SAMPLE))
  Amp = double(rebin(gDict.Amp, cnt, /SAMPLE))
  X = double(rebin(gDict.X, cnt, /SAMPLE))
  Y = double(rebin(gDict.Y, cnt, /SAMPLE))
  pie = complex(0,1, /double)*!PI
  complexRes = Amp * Exp(pie * (pie * (visV * visV * a - 2d * visV * b * visU+ visU * visU * c ) + (-visU * W * a * c + visU * W * b * b $
                + visU * a * c - visU * b * b - visV * H * a * c + visV * H * b * b + visV * a * c - visV * b * b $
                + 2d * a * X * visU * c - 2d * X * visU * b * b + 2d * c * Y * a * visV $
                - 2d * visV * b * b * Y)) / (c * a - b * b)) / Sqrt(a) $
                * !PI / Sqrt((c * a - b * b) / a)
  return, reform(complexRes, n_vis, n_gDict)
end