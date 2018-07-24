;+
; NAME:
;   hist_varbin
;
; PURPOSE:
;   Return the density function (histogram) of two variables.
;
; CATEGORY:
;   Image processing, statistics, probability.
;
; CALLING SEQUENCE:
;   Result = hist_varbin(V, Bins)
; INPUTS:
;   V  = array containing the variable to histogram.  May be any non-complex
;       numeric type.
;   Bins =    1-d or 2-d specfication of continous bin edges, must be ascending
;
; Keyword Inputs:
;   None
; Keyword Outputs
;   REVERSE_INDICES - Set this keyword to a named variable in which the list of reverse indices is returned. When possible,
;   this list is returned as a 32-bit integer vector whose number of elements is the sum of the number of elements
;   in the histogram, N, and the number of array elements included in the histogram, plus one. If the number of elements is
;   too large to be contained in a 32-bit integer, or if the L64 keyword is set, REVERSE_INDICES is returned as a 64-bit integer.
;
;   The subscripts of the original array elements falling in the ith bin, 0 = i < N, are given by the expression: R(R[i] : R[i+1]-1),
;   where R is the reverse index list. If R[i] is equal to R[i+1], no elements are present in the ith bin.
; OUTPUTS:
;   The one dimensional density function as in histogram(), just with arbitrary bin edges
;   Any values of V, that fall exactly on a bin edge are counted in the higher bin
;
; RESTRICTIONS:
;   Not usable with complex or string data.
;
; PROCEDURE:
;   The HISTOGRAM function computes the density function of Array. In the simplest case,
;   the density function, at subscript i, is the number of Array elements in the argument with a value of i.
;
; EXAMPLE:
;   IDL> print, hist_varbin( indgen(20), [1,2,6.6] )
;        1           5
;
; MODIFICATION HISTORY:
;   Written by:
;   Richard Schwartz, 22 aug 2016
;-
function hist_varbin, data, bin_edges, reverse_indices = reverse_indices

  COMPILE_OPT idl2
  ON_ERROR, 2
  edg_1d = get_edges( bin_edges, /edges_1 )
  edg_1d = [edg_1d, last_item( edg_1d ) + 1]
  n1d    = n_elements( edg_1d ) - 3
  data_bin = value_locate( edg_1d, data )


  h = HISTOGRAM( data_bin, min = 0, max = n1d,  reverse_indices = reverse_indices)  ;Get the 1D histogram
  return, h
end
