;+
; Name: plotman_get_click
; Purpose: Retrieve the coordinates from the last plotman click (or the last 20 if all is set)
; Input Keywords:
;   all - if set, retrieve last 20 plotman clicks, otherwise just most recent. Default=0
;   
; ;Written: 8/26/2019 RAS
;-
function plotman_get_click, all = all

common plotman_click_common, lastclick, last20click

default, all, 0
return, all? last20click : lastclick
end