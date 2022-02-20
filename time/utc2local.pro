;+
; Project     : VSO
;
; Name        : UTC2LOCAL
;
; Purpose     : Convert UTC to local time 
;
; Category    : time utility
;
; Syntax      : IDL> local=utc2local(utc)
;
; Inputs      : UTC = UTC time to convert
;
; Outputs     : LOCAL = local time
;
; Keywords    : None
;
; History     : 13-Mar-2019, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function utc2local,time,_extra=extra

if ~valid_time(time) then return,''

utc=secs70(time)
;ltc=systim(elapsed=utc)
ltc=systim(0,utc,elapsed=utc)
tai=anytim2tai(time)
hrs=3600.d

;-- correct for round off errors

diff=hrs*round((tai-anytim2tai(ltc))/hrs)
lc=tai2utc(tai-diff,/vms)

return,lc

end
