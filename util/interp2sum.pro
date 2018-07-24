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
;-
function interp2sum, Xlims, Xdata, Ydata, log=log

on_error,2			;Return to caller
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
;Find the interpolated Y value on every X point, then construct the y avg on each interval
;y avg has one value fewer
xn = get_uniq( [xs, xlims_use] )
 
case 1 of
	uselog : yn = exp( interpol(alog(ys), alog(xs), alog(xn)))
	else: yn = interpol( ys, xs, xn ) ;1 ylims for every xlims (2xn) interval
	endcase



edge_products, value_locate(xn, xlims_use), edges_2=ilims ;these are exact 1d edges at ilims
;Construct the average value in each sub bin and then do a weighted avg over the sub-bins to get the average of ydata on
;the interval specified by ilims
yavg = get_edges( yn, /mean )
xwid = xn[ilims[1,*]] - xn[ilims[0,*]]
yx   = yavg * get_edges( /width, xn )
yxtot = total( /cum, [0,yx], /double )
yxsum = reform( yxtot[ ilims[1,*] ] ) - reform( yxtot[ ilims[0,*] ] )
out   = f_div( yxsum, xwid )


return, out


end

