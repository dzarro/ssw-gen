;+
; Name        : vis_cs_gaussdict_render
;
; Purpose     : Renders a gaussian dictionary onto an image
;
; History     : 20 Jan 2017, Roman Bolzern (FHNW)
;               - initial release
;
; Contact     : simon.felix@fhnw.ch
;-

function vis_cs_gaussdict_render, $
  gDict, $
  W, $
  H, $
  weights, $
  pixel_size
  
  
  res = fltarr(W, H)
  y_positions = (lindgen(H * W) / W) * pixel_size[1] -0.5 + 0.5 * pixel_size[1]
  x_indexes = lindgen(W)*pixel_size[0] -0.5 + 0.5 * pixel_size[0]
  for i=0,n_elements(gDict)-1 do begin
    word = gDict[i]
    yd_v = y_positions - word.Y
    xd_v = reform([x_indexes-word.X] # transpose(replicate(1, H)),1,W*H)
    res += word.Amp*Exp(-(word.a * xd_v * xd_v + 2d * word.b * xd_v * yd_v + word.c * yd_v * yd_v)) * weights[i]
  endfor
  
  ;k = 0
  ;for y = 0, H DO BEGIN
  ;    for x = 0, W DO BEGIN
  ;        xd = x * pixel_size - self.X
  ;        yd = y * pixel_size - self.Y
  ;        res[k++] = self.A*Exp(-(self.a * xd * xd + 2 * self.b * xd * yd + self.c * yd * yd))
  ;    endfor
  ;endfor
  
  ; and in parent code:
  ;res = new float[W, H];
  ;if (words.Any())
  ;    res += words.Sum(e => ((Vector)dict[e.idx].Render(W, H)).Slice(W) * e.weight);

  return, res;
end