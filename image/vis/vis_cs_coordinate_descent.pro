;+
; Name        : vis_cs_coordinate_descent
;
; Purpose     : Performs a coordinate descent on the optimization problem of the vis_cs image algorithm
;
; History     : 20 Jan 2017, Roman Bolzern (FHNW)
;               - initial release
;               25 Jan 2017, Roman Bolzern & André Csillaghy (FHNW)
;               - speed improvements
;               21 Apr 2017, Roman Bolzern & Simon Felix (FHNW)
;               - removed tf normalization
;               29 Aug 2017, Roman Bolzern (FHNW)
;               - improved photometry by total flux hard constraint
;               - more consistent reconstruction times due to changed thresholding
;               4 Oct 2019, Simon Felix (FHNW)
;               - improved robustness for degenerate cases and added use of abort_numerical_issues param
;
; Contact     : simon.felix@fhnw.ch
;-

function vis_cs_coordinate_descent,$
  W, $
  H, $
  gDict, $
  vis, $
  totalFlux, $
  sparseness, $
  verbose, $
  abort_numerical_issues, $
  internalParams

  sigamp1 = vis.Sigamp ^ 0.5d

  x = dblarr(n_elements(gDict))

  ;rewrite original problem in this form:
  ;minimize: ||x * coeff - vis||^2_2 + lambda*x

  _vis = vis.obsvis / sigamp1
  coeff = vis_cs_gaussdict_transform(gDict, W, H, vis) ;coeff is flipped compared to C# 'cause IDL is column first
  
  ;coeff[where(coeff lt 1e-40)]=0 ;additional clipping for numerical stability
  
  coeff = temporary(coeff) / (replicate(1d, n_elements(_vis))#(gDict.Amp)) ; divide each column by Amp
  coeff = temporary(coeff) / (sigamp1#replicate(1d, n_elements(gDict))); divide each row by sigamp1

  cA = -2d * total((real_part(coeff) * real_part(coeff) + imaginary(coeff) * imaginary(coeff)), 1)
  sumsT = transpose([-real_part(_vis), -imaginary(_vis)])

  coeff_b = [real_part(coeff), imaginary(coeff)]
  ;coeff_b_2CA = coeff_b * 2d / (replicate(1d, n_elements(_vis) * 2)#cA)
  _visdouble = [real_part(_vis), imaginary(_vis)]
  gdA = gDict.Amp
  viv = gDict.VIV

  ; starting value
  ;tfDivT = totalFlux / double(n_elements(gDict))
  ;x = tfDivT * gdA / viv
  x[0] = totalFlux * 0.5d * gdA[0] / viv[0]
  x[1] = totalFlux * 0.5d * gdA[1] / viv[1]

  
  xsums = total(x, /double)
  sumsT += x#transpose(coeff_b)

  tfAV = totalFlux * gdA / viv

  activeI = bytarr(n_elements(gDict))
  activeI[where(x gt 0)] = 1b
  activeI_sum = total(activeI)
  for curSpI=0,7 do begin
    curSp = (curSpI / 7d) * sparseness + (1 - curSpI / 7d) * 0.999d
    lambda = (internalParams.lambda * exp(1./totalFlux)) * curSp / (1d - curSp)

    it = 0L
    innerIt = 0L
    while 1 do begin

      moves = 0b ;boolean
      for i=0,n_elements(gDict)-1 do begin
        xi = x[i]
        atf = tfAV[i]
        coeff_bi = coeff_b[*, i]
        alpha = 1d / (atf - xi)
        epsilon = alpha * (transpose(sumsT) - coeff_bi * xi + _visdouble)
        divisor = cA[i] + transpose(epsilon)#(4*coeff_bi - 2*epsilon)
        if (divisor eq 0d) || ((atf-xi) eq 0d) then begin
          if (abort_numerical_issues eq 1) && (curSpI eq 7) then return, x*0 else newx = 0
        endif else begin
          newx = ((2d * sumsT#(coeff_bi - epsilon) + (-lambda * alpha * (xsums - xi) + lambda)) / (divisor) + xi)[0] > 0d < atf * .999d
        endelse
        delta = newx - xi
        if (newx eq 0d xor xi eq 0d) || abs(delta) gt atf * 0.001  then begin
          if newx eq 0d && xi ne 0d then begin
            if activeI_sum lt 1.5 then continue
            activeI[i] = 0B
            activeI_sum -= 1
          endif else begin
            if newx ne 0d && xi eq 0d then begin
              activeI[i] = 1B
              activeI_sum += 1
            endif
          endelse
          sumsT += delta * transpose(coeff_bi)
          sumsT -= delta * transpose(epsilon)
          x -= delta * alpha * x
          xsums = (1d - delta * alpha) * xsums - x[i] + newx
          x[i] = newx
          moves = 1b
        endif
      endfor

      if (moves ne 1b) then break

      ;active set convergence, see  meier et al [2008] & krishnapuram & hartemink [2005]
      while moves eq 1b do begin
        innerIt++
        moves = 0b
        activeQuery = where(activeI gt 0B)
        foreach i, activeQuery do begin
          xi = x[i]
          atf = tfAV[i]
          coeff_bi = coeff_b[*, i]
          alpha = 1d / (atf - xi)
          epsilon = alpha * (transpose(sumsT) - coeff_bi * xi + _visdouble)
          divisor = cA[i] + transpose(epsilon)#(4*coeff_bi - 2*epsilon)
          if (divisor eq 0d) || ((atf-xi) eq 0d) then begin
            if (abort_numerical_issues eq 1) && (curSpI eq 7) then return, x*0 else newx = 0
          endif else begin
            newx = ((2d * sumsT#(coeff_bi - epsilon) + (-lambda * alpha * (xsums - xi) + lambda)) / (divisor) + xi)[0] > 0d < atf * .999d
          endelse
          delta = newx - xi
          if (newx eq 0d xor xi eq 0d) || abs(delta) gt atf * 0.001  then begin
            if newx eq 0d && xi ne 0d then begin
              if activeI_sum lt 1.5 then continue
              activeI[i] = 0B
              activeI_sum -= 1
            endif else begin
              if newx ne 0d && xi eq 0d then begin
                activeI[i] = 1B
                activeI_sum += 1
              endif
            endelse

            sumsT += delta * transpose(coeff_bi)
            sumsT -= delta * transpose(epsilon)
            x -= delta * alpha * x
            xsums = (1d - delta * alpha) * xsums - x[i] + newx
            x[i] = newx
            moves = 1b
          endif
        endforeach
      endwhile

      it++
    endwhile
    if verbose eq 1 then print, strcompress(string(curSpI))+': '+strcompress(string(it))+' iterations, '+ $
      strcompress(string(innerIt/float(it)))+'x inner, '+strcompress(string(total(activeI_sum)))+' active'
  endfor

  ;if (total(activeI) eq 0.0) then stop ; descent didn't work

  return, x / gDict.Amp
end