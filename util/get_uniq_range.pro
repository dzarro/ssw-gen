;+
; Project     : HESSI
;
; Name        : get_uniq_range
;
; Purpose     : return unique pairs of a 2xn array
;
; Category    : utility
;
; Syntax      : IDL> out=get_uniq_range(in)
;
; Inputs      : IN = 2xn array to search
;
; Outputs     : OUT = unique pairs (dimensioned 2xm) sorted by value in first column
;
; Optional Out: SORDER = sorting index
;
; Keywords    : COUNT: # of uniq values
;
; History     : Extended from get_uniq by Kim Tolbert, 12-Jan-2005
;               Originally written 20 Sept 1999, D. Zarro, SM&A/GSFC
;
; Modifications
; 14-Dec-2018, Kim. Didn't handle the case of just two elements in array correctly. Now just returns array.
;-

function get_uniq_range,array,sorder,count=count

count=0
sorder=-1
if not exist(array) then return,-1
if n_elements(array) eq 2 then return, array ; if just one range, that's the unique range
if (size(array))[0] ne 2 then return, -1
sorder=0
if n_elements(array[0,*]) eq 1 then begin
 count=1
 return,array
endif

sorder=uniq_range(array,rowsort(array,0,1))

count=n_elements(sorder)
if count eq 1 then sorder=sorder[0]

return,array[*,sorder]
end
