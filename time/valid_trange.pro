;+
; Project     : HESSI
;
; Name        : VALID_TRANGE
;
; Purpose     : determine if input time range is valid and before current time
;
; Category    : utility
;
; Syntax      : IDL> valid=valid_trange(range)
;
; Inputs      : RANGE: 2-element time vector 
;
; Keywords    : LOCAL = input time range is in local units [def = UTC]
;               ERR = error message
;               TRANGE = output validated time range [def = seconds since 1-jan-1979]
;               ASCII = return output TRANGE in ASCII format
;
; Outputs     : VALID = 1/0 if valid/invalid
;
; History     : 7-Dec-2017, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function valid_trange,range,err=err,local=local,trange=vrange,ascii=ascii

err=''
vrange=[null(),null()]

if n_elements(range) ne 2 then begin
 err='Need at least two input times.'
 return,0b
endif

if ~valid_time(range[0]) || ~valid_time(range[1]) then begin
 err='Invalid or missing input time range values.'
 return,0b
endif

trange=anytim(range)
tstart=min(trange)
tend=max(trange)

if (tstart eq tend) then begin
 err='Input time range values cannot be equal.'
 return,0b
endif

if keyword_set(local) then stime=!stime else get_utc,stime 
ctime=anytim(stime)

if (tstart gt ctime) && (tend gt ctime) then begin
 err='Input time range cannot be in future.'
 return,0b
endif

tstart = tstart < ctime
tend= tend < ctime
vrange=[tstart,tend]

if keyword_set(ascii) then vrange=anytim(vrange,/vms)

return,1b

end
