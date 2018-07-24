;+
; Name        : vis_cs_gaussdict_createvariation
;
; Purpose     : 2D Gaussian Class for the VIS_CS algorithm. Returns an instance of the vis_cs_gauss
;
; History     : 20 Jan 2017, Roman Bolzern (FHNW)
;               - initial release
;
; Contact     : simon.felix@fhnw.ch
;-

function vis_cs_gaussdict_createvariation,$
  words,$
  W, $
  H, $
  SIZE_MIN, $
  SIZE_MAX, $
  MAX_ANISOTROPIC, $
  ELEMENTSEACH, $
  PIXEL_SIZE, $
  Seed
  
  nw = n_elements(words)
  cnt = ELEMENTSEACH * nw
  
  w_X = reform(replicate(1,ELEMENTSEACH) ## words.X, cnt)
  w_Y = reform(replicate(1,ELEMENTSEACH) ## words.Y, cnt)
  w_SX = reform(replicate(1,ELEMENTSEACH) ## words.SX, cnt)
  w_SY = reform(replicate(1,ELEMENTSEACH) ## words.SY, cnt)
  w_PHI = reform(replicate(1,ELEMENTSEACH) ## words.PHI, cnt)
  
  gaussianRandoms = RANDOMN(Seed+1337, cnt, 5)
  gDict = REPLICATE({vis_cs_gaussian, X:0d, Y:0d, SX:0d, SY: 0d, PHI: 0d, $
           Amp: 1d, a: 0d, b: 0d, c: 0d, VIV: 0d }, cnt)
  gDict.X = w_X + gaussianRandoms[*,0] * 2d * PIXEL_SIZE[0]
  gDict.Y = w_Y + gaussianRandoms[*,1] * 2d * PIXEL_SIZE[1]
  gDict.SX = w_SX + gaussianRandoms[*,2] * w_SX * 0.4d > w_SY / MAX_ANISOTROPIC < w_SY * MAX_ANISOTROPIC > SIZE_MIN < SIZE_MAX
  gDict.SY = w_SY + gaussianRandoms[*,3] * w_SY * 0.4d > w_SX / MAX_ANISOTROPIC < w_SX * MAX_ANISOTROPIC > SIZE_MIN < SIZE_MAX
  gDict.PHI = w_PHI + gaussianRandoms[*,4] * !PI / 8d
  gDict = vis_cs_gaussdict_updateabc(gDict)
  gDict = vis_cs_gaussdict_normalize(gDict)
  gDict = vis_cs_gaussdict_calcviv(gDict, W, H, PIXEL_SIZE)
  return, gDict
end