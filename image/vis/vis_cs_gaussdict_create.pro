;+
; Name        : vis_cs_gaussdict_create
;
; Purpose     : 2D Gaussian Class for the VIS_CS algorithm. Returns an instance of the vis_cs_gauss
;
; History     : 20 Jan 2017, Roman Bolzern (FHNW)
;               - initial release
;
; Contact     : simon.felix@fhnw.ch
;-

function vis_cs_gaussdict_create,$
  W, $
  H, $
  SIZE_MIN, $
  SIZE_MAX, $
  MAX_ANISOTROPIC, $
  ELEMENTS, $
  PIXEL_SIZE, $
  Seed
  
  gaussianRandoms = RANDOMN(Seed, ELEMENTS, 1)
  randoms = RANDOMU(Seed+42, ELEMENTS, 4)
  gDict = REPLICATE({vis_cs_gaussian, X:0d, Y:0d, SX:0d, SY: 0d, PHI: 0d, $
           Amp: 1d, a: 0d, b: 0d, c: 0d, VIV: 0d }, ELEMENTS)
  gDict.X = randoms[*,0] * W * PIXEL_SIZE[0]
  gDict.Y = randoms[*,1] * H * PIXEL_SIZE[1]
  gDict.SX = SIZE_MIN + randoms[*,2]^2d * (SIZE_MAX-SIZE_MIN) > SIZE_MIN < SIZE_MAX
  gDict.SY = (gDict.SX + gaussianRandoms[*,0] * gDict.SX * 0.25d > gDict.SX / MAX_ANISOTROPIC < gDict.SX * MAX_ANISOTROPIC) > SIZE_MIN < SIZE_MAX
  gDict.PHI = randoms[*,3] * !PI / 2d
  gDict = vis_cs_gaussdict_updateabc(gDict)
  gDict = vis_cs_gaussdict_normalize(gDict)
  gDict = vis_cs_gaussdict_calcviv(gDict, W, H, PIXEL_SIZE)
  return, gDict
end