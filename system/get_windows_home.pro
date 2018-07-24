;+
; Project     : RHESSI
;
; Name        : GET_WINDOWS_HOME
;
; Purpose     : Return Windows equivalent of $HOME or ~
;
; Category    : OS utility 
;
; Syntax      : IDL> home=get_windows_home()
;
; Inputs      : None
;
; Outputs     : Expanded equivalent of %userprofile%
;
; Keywords    : None
;
; History     : 10-Feb-2018 Zarro (ADNET) - written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function get_windows_home,_ref_extra=extra

windows=os_family(/lower) eq 'windows'
if ~windows then return,''

;-- expand %userprofile% (lower- and upper-case)

espawn,'echo %userprofile%',out,_extra=extra
if is_blank(out) then espawn,'echo %USERPROFILE%',out,_extra=extra

return,out
end
