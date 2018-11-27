;+
; Name: trange2string
; 
; Purpose: Convert a time or time range to a string, with or without seconds, and without repeating the date (useful, e.g. when
;   constructing a file name from times.
; 
; Input Argument:
;  tr - single time or time range in anytim format (if sec, then since 79/1/1)
;       Note: since the date is not repeated, time range shouldn't span more than a day
;  
; Input Keywords:
;  sec - if set, include seconds in output time string
;  
; Example: 
;   tr = ['21-Jul-2002 00:57:32.000', '21-Jul-2002 01:07:32.000']
;   print,trange2string(tr)
;      20020721_0057_0107
;   print,trange2string(tr,/sec)
;      20020721_005732_010732
;  
; Written: Kim Tolbert, 7-Aug-2018
; Modifications:
;-


function trange2string, tr, sec=sec

ret = ''
if valid_time(tr[0]) then ret = time2file(tr[0], sec=sec)
if n_elements(tr) gt 1 && valid_time(tr[1]) then ret = ret + '_' + strmid(time2file(tr[1], sec=sec),9,6)
return, ret

end