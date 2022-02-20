
;+
; :Description:
;    Calls goes16p_clean_chan to find outliers in GOES data from GOES16 and higher, replace the bad data, 
;    and set their indices in BAD0 and BAD1, set a floor of 1e-9 w/m^2
;
; :Params:
;    ygoes   - input GOES xrs data, fltarr( npts, 2)  Channel B, Channel A
;    yclean  - output cleaned ygoes, outliers are replaced by interpol of the good data
;      For now the procedure is identical for Channels A and B
;    bad0    - output indices of outliers in channel 0, long wavelength  now called channel B
;    bad1    - output indices of outliers in channel 1, short wavelength now called channel A
;
; :Keywords:
;    use_mask - not used yet
;    cln_ymin  - default, 1e-9, sets the floor on the cleaned GOES fluxes, both channels
;
; :Author: RAS, 1-jun-2020
;-
pro goes16p_clean, ygoes, yclean, bad0, bad1, $
  tarray = tarray, use_mask = use_mask, cln_ymin = cln_ymin, $
  _extra = _extra

  default, cln_ymin, 1e-9
  yclean = ygoes
  ngoes  = (size(/dim, ygoes))[0]
  use_mask = n_elements( use_mask ) eq ngoes ? use_mask : 1b + bytarr( ngoes )
  ;find valid intervals where use_mask eq 1
  find_changes, [use_mask,0], ixm, state, count = count
  for jx = 0, count-2 do begin
    nj = ixm[jx+1]-ixm[jx]
    if state[jx] eq 1 and nj gt 7 then begin ;Clean the next NJ elements
      zj = ixm[jx]  + lindgen(nj)
      for ichan = 0, 1 do begin

        goes16p_clean_chan, ygoes[zj,ichan],  bad, $
          yclean = cleaned, _extra = _extra
        yclean[zj, ichan] = cleaned  > cln_ymin
        bad = bad + zj[0]
        case ichan of
          0: bad0 = append_arr( bad0, bad )
          1: bad1 = append_arr( bad1, bad )
        endcase
      endfor
    endif
  endfor
end
