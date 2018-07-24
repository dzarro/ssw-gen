;+
; Name        : vis_cs_gaussdict_calcviv
;
; Purpose     : 2D Gaussian method for the VIS_CS algorithm. Calculates "VolumeInView", the closed integral of the gaussian within [W, H]
;
; History     : 29 Aug 2017, Roman Bolzern (FHNW)
;               - initial release
;
; Contact     : simon.felix@fhnw.ch
;-

function vis_cs_gaussdict_calcviv, gDict, W, H, pixel_size
  COMMON SHARECALCVIV, p1, p2, a, w0, b, sqrt_a, w1
  w0 = 0 * pixel_size[0] + (-0.5 + 0.5 * pixel_size[0]) - gDict.X;
  w1 = W * pixel_size[0] + (-0.5 + 0.5 * pixel_size[0]) - gDict.X;
  h0 = 0 * pixel_size[1] + (-0.5 + 0.5 * pixel_size[1]) - gDict.Y;
  h1 = H * pixel_size[1] + (-0.5 + 0.5 * pixel_size[1]) - gDict.Y;
  ;Mathematica: Integrate[A* Exp[-(a(x - x0) ^ 2 - 2 b(x - x0)(y - y0) + c(y - y0) ^ 2)], {x, w0, w1}, Assumptions->Element[A | a | x | x0 | y | y0 | b | c | w0 | w1, Reals] && A > 0 && a > 0 && c > 0 && b <= 0 && a * c > b ^ 2 && w0 < w1]
  sqrt_a = sqrt(gDict.a)
  p1 = gDict.Amp * sqrt(!PI) / (2 * sqrt_a)
  p2 = (gDict.b * gDict.b - gDict.a * gDict.c) / gDict.a
  
  ;QSIMP? QROMB? QROMO?
  ;Different numerical integration might yield to fewer calls of expensive function
  viv = dblarr(n_elements(w0),/NOZERO)
  a = gDict.a
  b = gDict.b
  COMMON SHARECALCVIVI, i
  currentExcept = !Except
  !Except = 0
  void = Check_Math()
  FOR i = 0, n_elements(w0)-1 DO BEGIN
    viv[i] = QROMB('vis_cs_gaussdict_calcviv_integ', h0[i], h1[i], /double, EPS=1d-5,JMAX=1000)
  ENDFOR
  void = Check_Math()
  !Except = currentExcept
  gDict.VIV = viv
  return, gDict
end