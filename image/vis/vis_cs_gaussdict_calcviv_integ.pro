;+
; Name        : vis_cs_gaussdict_calcviv_integ
;
; Purpose     : 2D Gaussian method for the VIS_CS algorithm. Defines the "VolumeInView" integral function for the numerical integration.
;
; History     : 29 Aug 2017, Roman Bolzern (FHNW)
;               - initial release
;
; Contact     : simon.felix@fhnw.ch
;-

function vis_cs_gaussdict_calcviv_integ, y
  COMMON SHARECALCVIV, p1, p2, a, w0, b, sqrt_a, w1
  COMMON SHARECALCVIVI, i
  return, p1[i] * Exp(p2[i] * (y * y)) * (-Erf((a[i]*w0[i]-b[i]*y)/sqrt_a[i]) + Erf((a[i]*w1[i]-b[i]*y)/sqrt_a[i]))
end