;+
; Project     : HESSI     
;                   
; Name        : UT_DIFF
;               
; Purpose     : compute difference between local and UT time
;               
; Category    : time utility
;               
; Syntax      : IDL> print,ut_diff()
;
; Inputs      : DATE/TIME to check (def = current)
;               
; Outputs     : hours difference between local and UT time
;               
; Keywords    : SECONDS = output in seconds
;               
; History     : 11-Nov-2002, Zarro (EER/GSFC)- Written
;               18-Nov-2014, Zarro (ADNET) - Modified to use ANYTIM
;               12-Dec-2018, Zarro (ADNET) - Added DATE argument
;               28-Jan-2019, Zarro (ADNET) - Added common block
;     
; Contact     : dzarro@solar.stanford.edu
;-

function ut_diff,date,seconds=seconds,debug=debug

common ut_diff,last_diff

;-- compute hours difference between local and UT. If negative, we must be
;   east of Greenwich

if ~exist(date) then begin
 if exist(last_diff) then diff=last_diff else begin
  diff=float(round(anytim(systim())-anytim(systim(/utc))))
  last_diff=diff
 endelse
endif else begin
 if ~valid_time(date) then return,0.
 time=anytim(date,fid='sys')+24.*3600.d
 dst=0.d
 if os_family(/lower) eq 'windows' then dst=3600.d
 mdate=systim(0,time+dst)
 mtime=anytim(mdate,fid='sys')
 diff=float(round(mtime-time))
 if keyword_set(debug) then stop,1
endelse

if ~keyword_set(seconds) then diff=diff/3600.

return, diff
end
