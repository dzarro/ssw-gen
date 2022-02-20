;+
; :Description:
;    This procedure identifies the outliers in a single channel of GOES data from GOES16 and higher,
;    and replaces the outliers with interpolation of the good data.
;
; :Params:
;    y    - input GOES xrs data, fltarr( npts)  Channel B or Channel A
;    bad  - output indices of outliers
;
; :Keywords:
;    yclean  - Output cleaned version of y, outliers are replaced by interpol of the good data
;      For now the procedure is identical for Channels A and B
;    cln_cutoff - cut argument in resistant_mean, find outliers above cutoff*sigma, default=15
;    cln_group  - use resistant_mean with this many datum, default=200
;    cln_ymin   - unused for now. it may be needed down the road, RAS, 1-jun-2020
;
; :Author: RAS, 1-jun-2020
; 3-jun-2020, RAS, added a final validation for marking bad points and replacing y with the
; interpolated.  If the clean is within 5% original, use the original, remove bad
;-
pro goes16p_clean_chan, y,  bad, yclean = yclean, $
  cln_cutoff = cutoff,  cln_group = group, cln_ymin = ymin

  default, ymin, 5e-8 ;unused for now. it may be needed down the road, RAS, 1-jun-2020
  default, cutoff, 15
  ny = n_elements( y )
  bad = -1 ;start with no bad points
  default, group, 200
  ngroup = floor( ny / group )
  iy = 0L

  for ig = 0, ngroup-1 do begin

    ilast = (iy + group - 1) < (ny-1)
    if ig eq (ngroup-1) then ilast = ny-1 ;add the remaining fraction to the last group
    nzg   = ilast - iy + 1
    zg    = lindgen( nzg ) + iy
    yzg   = y[zg]

    data0 = iy eq 0? y[0] : y[iy-1]
    datae =  ilast lt ( ny - 1) ? y[ ilast + 1] : y[ilast]
    data  = [ data0, yzg, datae ]
    dd    = data[1:*] - data
    num_dd = dd * dd[1:*]

    pdata  = f_div( num_dd, yzg  )
    dtest = (0.0 - pdata )>0.0
    resistant_mean, dtest, cutoff, rmean, sigma, nrej, good = gd
    clnmean = avg( yzg[gd] )
    pdata  = f_div( num_dd, clnmean  )
    dtest = (0.0 - pdata )>0.0
    resistant_mean, dtest, cutoff, rmean, sigma, nrej, good = gd
    dmask = byte( dtest * 0)
    dmask[gd] = 1b


    bdg = where( dmask eq 0 , nbdg)
    ;bdgm = where( dmask eq 0 and yzg lt clnmean, nbdgm)
    if nbdg ge 1 then bad = append_arr( bad, bdg + iy )

    iy = ilast + 1

  endfor
  if n_elements( bad ) gt 1 then bad = bad[1:*]
  agd = bytarr( ny ) + 1b
  agd[ bad ] = 0b
  z   = where( agd, nz)
  yclean = y
  if nz ge 1 then begin
    yclean[ bad ] = interpol( yclean[ z ], z, bad )
    ;Validate- 3-jun-2020, RAS
    qtst = where(abs( f_div((y[bad]-yclean[bad]),yclean[bad])) lt .05, nqtst)
    if nqtst ge 1 then begin
      yclean[bad[qtst]] = y[bad[qtst]]
      if nqtst eq n_elements(bad) then bad = -1 else remove, qtst, bad
    endif
  endif

end

