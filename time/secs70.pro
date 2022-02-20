;+
; Project     : VSO
;
; Name        : SECS70
;
; Purpose     : Return seconds since 00:00 1-Jan-1970
;
; Category    : time utility
;
; Syntax      : IDL> secs=secs70(time)
;
; Inputs      : TIME = time to convert
;
; Outputs     : SECS = seconds since 00:00 1-Jan-1970
;
; Keywords    : None
;
; History     : 13-Mar-2019, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function secs70,time

if ~valid_time(time) then return,0.d

tai=anytim2tai(time)

tbase=anytim2tai('1-Jan-1970')

return, (tai-tbase > 0.d)

end
