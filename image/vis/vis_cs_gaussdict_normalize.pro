;+
; Name        : vis_cs_gaussdict_normalize
;
; Purpose     : 2D Gaussian Class for the VIS_CS algorithm
;
; History     : 20 Jan 2017, Roman Bolzern (FHNW)
;               - initial release
;
; Contact     : simon.felix@fhnw.ch
;-

function vis_cs_gaussdict_normalize, gDict
  gDict.Amp = 0.5d / gDict.SX / gDict.SY / !PI
  return, gDict
end