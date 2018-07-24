;+
; Name        : vis_cs_gaussdict_updateabc
;
; Purpose     : Update a, b, c for vis_cs gaussian dictionary
;
; History     : 20 Jan 2017, Roman Bolzern (FHNW)
;               - initial release
;
; Contact     : simon.felix@fhnw.ch
;-

FUNCTION vis_cs_gaussdict_updateabc, $
  gDict
  
  gDict.a = Cos(gDict.Phi) * Cos(gDict.Phi) / (2d * gDict.SX * gDict.SX) + Sin(gDict.Phi) * Sin(gDict.Phi) / (2d * gDict.SY * gDict.SY)
  gDict.b = -Sin(2d * gDict.Phi) / (4d * gDict.SX * gDict.SX) + Sin(2d * gDict.Phi) / (4d * gDict.SY * gDict.SY)
  gDict.c = Sin(gDict.Phi) * Sin(gDict.Phi) / (2d * gDict.SX * gDict.SX) + Cos(gDict.Phi) * Cos(gDict.Phi) / (2d * gDict.SY * gDict.SY)
  return, gDict
END