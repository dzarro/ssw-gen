;+
; Project     : VSO
;
; Name        : STR_LOG
;
; Purpose     : Update a string log array
;
; Category    : utility help string
;
; Syntax      : IDL> str_log,log,input
;
; Inputs      : LOG = string log to update
;               INPUT = input string to append to log
;               LEVEL = level of detail to print
;
; Outputs     : None
;
; Keywords    : VERBOSE = print input
;               QUIET = override VERBOSE
;               INIT = set to initialize log
;               NO_REPEAT = don't repeat same input
;               DETAILS = set to match level 
;               (e.g. if LEVEL=1, the set DETAIL=1 to echo INPUT)
;
; History     : 16 January 2019, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

pro str_log,log,input,level,verbose=verbose,_ref_extra=extra,init=init,no_repeat=no_repeat,$
                      quiet=quiet,details=details

loud=keyword_set(verbose) && ~keyword_set(quiet)

if keyword_set(init) then delvarx,log
if ~is_string(input,/blank) then return

if keyword_set(no_repeat) then begin
 item=input[uniq(input)]
 item=str_remove(item,log)
 if is_blank(item) then delvarx,item
endif else item=input

iloud=1b
if is_number(level) then begin
 if level gt 0 then begin
  if is_number(details) then begin
   if (details lt level) then iloud=0b 
  endif else iloud=0b
 endif
endif

if loud && iloud then begin
 mprint,item,/noname,/allow_blank,_extra=extra
endif

if (n_elements(log) eq 1) then begin
 if is_blank(log) then begin
  log=item
  return
 endif
endif 

log=append_arr(log,item,/no_copy)

return
end
