;+
; Project     : RHESSI
;
; Name        : HOME_DIR
;
; Purpose     : Return OS-dependent HOME directory
;
; Category    : OS utility 
;
; Syntax      : IDL> home=home_dir()
;
; Inputs      : None
;
; Outputs     : Expanded equivalent of users directory
;
; Keywords    : None
;
; History     : 10-Feb-2018 Zarro (ADNET) - written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function home_dir,_ref_extra=extra

common home_dir,home_save

;-- return last saved value

if is_string(home_save,/blank) then return,home_save

windows=os_family(/lower) eq 'windows'
if windows then $
 out=get_windows_home(_extra=extra) else $
  out=(file_info('~')).name

home_save=out
return,out

end
