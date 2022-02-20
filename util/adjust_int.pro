;+
; Name: adjust_int
; 
; Purpose: Adjust intervals so that edges lie on prescribed boundaries. 
; 
; Input arguments:
;  bins - prescribed boundaries (2xn). Should be contiguous.
;  newbins - intervals to be adjusted to lie on prescribed boundaries in bins array (2xn)
;  
; Output Keywords:
;   count - number of bins returned
;   
; Output - returns newbins adjusted to line up with bins.  If none, returns -1.
; 
; Method: Rounds to closest bin edges. If start/end of newbins interval both are closest to same edge, 
;   in bins, then that newbin isn't saved.
;   
; Examples:
; bins = [[0,10], [10,20], [20,30]]
; newbins=[[1,8], [8,14], [16,26]]
; print,adjust_int(bins,newbins)
;   0      10
;  20      30
;  Note the newbins bin [8,14] didn't result in an output bin since both are closest to one edge of bins (10.)
;
; Restrictions:  
;   Assumes bins are contiguous. 
;   If newbins overlap, your output bins may overlap.
;   
; Written: Kim Tolbert 25-Feb-2020
; Modifications:
;-

function adjust_int, bins, newbins, count=count

new = newbins

for i=0,n_elements(new) -1 do begin
  q = min (abs(new[i] - bins), index)
  new[i] = bins[index]
endfor
new = get_uniq_range(new)  ; remove duplicates

q = where(new[0,*] ne new[1,*], count)  ; remove bins that have start=end
if count gt 0 then new = new[*,q] else new = -1

return, new
end