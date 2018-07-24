;+
; Name: PLOTMAN_CLICK_DIFF  
; 
; Purpose: Print the difference in x, y, and z of the most recent two plotman right clicks
; 
; Calling Sequence:  print, plotman_click_diff()
; 
; Written, Kim Tolbert 21-Feb-2017
; 
;-

function plotman_click_diff

common plotman_click_common, lastclick, last20click

nc = n_elements(last20click)
if nc eq 1 then return, null()

ut1 = strpos(last20click[nc-1].x, '/') ne -1  ; it it's a time, will have a slash in string
ut2 = strpos(last20click[nc-2].x, '/') ne -1

; have to both be times, or neither
if ut1 ne ut2 then return, null()

xdiff = ut1 ? anytim(last20click[nc-1].x) - anytim(last20click[nc-2].x) : float(last20click[nc-1].x) - float(last20click[nc-2].x)
ydiff = float(last20click[nc-1].y) - float(last20click[nc-2].y)
zdiff = float(last20click[nc-1].z) - float(last20click[nc-2].z)

return, [xdiff, ydiff, zdiff]
end