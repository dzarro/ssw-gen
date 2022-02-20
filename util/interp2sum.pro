;+
; PROJECT:
;   SSW
;
; NAME:
;	INTERP2SUM
;
; PURPOSE:
;	This function sums over the limits on an interpolated array.
;
; CATEGORY:
;	GEN, MATH, UTILITY, NUMERICAL
;
; CALLING SEQUENCE:
;	Integral = INTERP2SUM( Xlims, Xdata, Ydata)
;
; CALLS:
;	INTERPOL, EDGE_PRODUCTS, VALUE_LOCATE
;
; INPUTS:help,uselog
;       Xlims - The limits to integrate over. May be an array of 2 x n sets of limits where
;	the intervals are contiguous and ordered, i.e. xlims(1,i) equals xlims(0,i+1)
;	Xlims may also be an ordered set of values in a 1-d vector defining contiguous intervals.
;	Xdata, Ydata - Define the tabulated function to integrate over. Xdata may be a 2xN array
;	and will take the arithmetic average to obtain a 1-d array.
;	Ydata - the integrand, a smooth function. Not integrated over the xdata bins. For an x-ray photon
;		spectrum xdata could be the energy in keV and ydata could be the flux in photons/keV.
;
; OPTIONAL INPUTS:
;
;
; OUTPUTS:
;       none explicit, only through commons;
;
; OPTIONAL OUTPUTS:
;	none
;
; KEYWORD INPUTS:
;
;	LOG    - If set, use log/log interpolation.
;	THRESH - If set, interpolate only on the values > thresh and fill in gaps in interpolated
;	         array with NaN before summing. Then at end set any values < (.2*average good y values) to 0. 
;	         The .2 value is arbitraty.
;
; COMMON BLOCKS:
;	none
;
; SIDE EFFECTS:
;	none
;
; RESTRICTIONS:
;	Complex data types not permitted and not checked.
;	Xlims in 2xN form are assumed contiguous and not checked.
;
; PROCEDURE:
;	The data are interpolated into the interval defined by Xlims and then integrated.
;
; MODIFICATION HISTORY:
;	RAS, 2-apr-1996
;	Version 2, richard.schwartz@gsfc.nasa.gov, 7-sep-1997, more documentation
;	Version 3, richard.schwartz@gsfc.nasa.gov, 16-apr-1998, converted to multiple intervals.
;	10-may-2011, converted to square brackets for array indices, replace find_ix with value_locate
;	18-aug-2011, ras, updated the documentation
;	01-Mar-2021, Kim.  Added thresh keyword. Tried to protect routine from being any different from before this, so
;	  changes are only made if thresh is passed in (except I did add /nan to call to total for both cases.)
;	 01-Apr-2021, jmm, don't allow yn to be negative (causes problems in extrapolation)
;-
function interp2sum, Xlims, Xdata, Ydata, log=log, thresh=thresh

  on_error,2			;Return to caller

  use_thresh = n_elements(thresh) gt 0
  xlims_use = xlims
  edge_products,xlims_use, edges_1 = xlims_use
  uselog = keyword_set(log)


  xs  = xdata
  ys  = ydata
  ;
  ; xdata may be 2-d, if so average to 1-d
  if total( abs((size(xs))[0:1]-[2,2])) eq 0 then xs = avg(xs,0)
  ;ord = sort(xs)
  ;xs  = xs[ord]
  ;ys  = ydata[ord]
  wzero = where( xs le 0.0, xzero)
  wzero = where( ys le 0.0, yzero)
  wzero = where( xlims_use le 0.0, lzero)
  if (xzero + yzero + lzero) ge 1 then uselog = 0

  ;xn will be all x values in original x array combined with x array to interpolate to
  ;Find the interpolated Y value on every X point, then construct the y avg on each interval
  ;y avg has one value fewer
  xn = get_uniq( [xs, xlims_use] )

  if ~use_thresh then begin

    case 1 of
      uselog : yn = exp( interpol(alog(ys), alog(xs), alog(xn)))
      else: yn = interpol( ys, xs, xn ) ;1 ylims for every xlims (2xn) interval
    endcase

  endif else begin

    ; Only interpolate over good (> thresh) values if thresh was passed in.  xn values that we're
    ; interpolating to has all the xs values in it, so will interpolate across gap of bad values.
    ; Then we'll replace points in those gaps with 0.
    gt0 = where( ydata gt thresh, ncomplement=n_le_thresh, ngt0)
    if n_le_thresh gt 0 then begin
      xsuse  = xs[gt0]
      ysuse  = ys[gt0]
    endif else begin
      xsuse = xs
      ysuse = ys
    endelse

    case 1 of
      uselog : yn = exp( interpol(alog(ysuse), alog(xsuse), alog(xn)))
      else: yn = interpol( ysuse, xsuse, xn ) ;1 ylims for every xlims (2xn) interval
    endcase
    ; Don't allow yn to be negative, for possible extrapolation issues, jmm, 2021-04-01
    yn = yn > 0
    ; Now we have yn on the xn intervals.  Set yn to NaN at the x values
    ; that correspond to where the original y values were <= thresh    
    if n_le_thresh gt 0 then begin
      hsi_ql_st_en, ys gt thresh, st_ss, en_ss, ok = okgt0
      if okgt0[0] ne -1 then begin
        sgt0 = xs[st_ss]
        egt0 = xs[en_ss]
        for j=0,n_elements(sgt0)-2 do begin
          q = where(xn ge egt0[j] and xn lt sgt0[j+1], ninzero)
          if ninzero gt 0 then yn[q] = !values.f_nan
        endfor
      endif
    endif

  endelse

  edge_products, value_locate(xn, xlims_use), edges_2=ilims ;these are exact 1d edges at ilims

  ;Construct the average value in each sub bin and then do a weighted avg over the
  ; sub-bins to get the average of ydata on the interval specified by ilims
  yavg = get_edges( yn, /mean )
  xwid = xn[ilims[1,*]] - xn[ilims[0,*]]
  yx   = yavg * get_edges( /width, xn )
  yxtot = total( /cum, [0,yx], /double, /nan )
  yxsum = reform( yxtot[ ilims[1,*] ] ) - reform( yxtot[ ilims[0,*] ] )
  out   = f_div( yxsum, xwid )

  ;After integrating bins to xlims_use intervals, set any outliers (< .2*average value of y values used) to 0.
  ;Only do this when thresh was passed in because we don't want to change output of this routine for the general case
  if use_thresh then begin
    ygood_ave = avg(ysuse)
    q = where(out lt .2*ygood_ave, nq)
    if nq gt 0 then begin
;      print,'interpsum: number of elements of out setting to 0 = ', nq
      out[q] = 0.
    endif
  endif

  return, out

end

